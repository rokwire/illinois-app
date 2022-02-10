/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GroupPostDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final GroupPost? post;
  final GroupPost? focusedReply;
  final List<GroupPost>? replyThread;
  final Group? group;
  final bool hidePostOptions;

  GroupPostDetailPanel(
      {required this.group, this.post, this.focusedReply, this.hidePostOptions = false, this.replyThread});

  @override
  _GroupPostDetailPanelState createState() => _GroupPostDetailPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group?.analyticsAttributes;
}

class _GroupPostDetailPanelState extends State<GroupPostDetailPanel> implements NotificationsListener {
  static final double _outerPadding = 16;
  //Main Post - Edit/Show
  GroupPost? _post; //Main post {Data Presentation}
  PostDataModel? _mainPostUpdateData;//Main Post Edit

  //Reply - Edit/Create/Show
  GroupPost? _focusedReply; //Focused on Reply {Replies Thread Presentation} // User when Refresh post thread
  String? _selectedReplyId; // Thread Id target for New Reply {Data Create}
  GroupPost? _editingReply; //Edit Mode for Reply {Data Edit}
  PostDataModel? _replyEditData = PostDataModel(); //used for Reply Create / Edit; Empty data for new Reply

  String? _modalImageUrl; // ModalImageDial presentation
  bool _loading = false;

  //Scroll and focus utils
  ScrollController _scrollController = ScrollController();
  final GlobalKey _sliverHeaderKey = GlobalKey();
  final GlobalKey _postEditKey = GlobalKey();
  final GlobalKey _scrollContainerKey = GlobalKey();
  double? _sliverHeaderHeight;
  //Refresh
  GlobalKey _postInputKey = GlobalKey();
  GlobalKey _postImageHolderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, Groups.notifyGroupPostsUpdated);
    _post = widget.post ?? GroupPost(); //If no post then prepare data for post creation
    _focusedReply = widget.focusedReply;
    _sortReplies(_post?.replies);
    _sortReplies(_focusedReply?.replies);

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _evalSliverHeaderHeight();
      if (_focusedReply != null) {
        _scrollToPostEdit();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: HeaderBackButton(),
            title: Text(
              Localization()
                  .getStringEx('panel.group.detail.post.header.title', 'Post')!,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: Styles().fontFamilies!.extraBold,
                  letterSpacing: 1),
            ),
            centerTitle: true),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: TabBarWidget(),
        body: ModalImageDialog.modalDialogContainer(
          content: _buildContent(),
          imageUrl: _modalImageUrl,
          onClose: () {
            Analytics().logSelect(target: "Close");
            _modalImageUrl = null;
            setState(() {});
          }
        ));
  }

  Widget _buildContent(){
    return Stack(children: [
      Stack(alignment: Alignment.topCenter, children: [
        SingleChildScrollView(key: _scrollContainerKey, controller: _scrollController, child:
        Column(children: [
          Container(height: _sliverHeaderHeight ?? 0,),
          _isEditMainPost || StringUtils.isNotEmpty(_post?.imageUrl) //TBD remove if statement
            ? ImageChooserWidget(key: _postImageHolderKey, imageUrl: _post?.imageUrl, buttonVisible: _isEditMainPost, onImageChanged: (url) => _mainPostUpdateData?.imageUrl = url,)
            : Container(),
          _buildPostContent(),
          _buildRepliesSection(),
          _buildPostEdit(),
          ],)),
       Container(
                key: _sliverHeaderKey,
                color: Styles().colors!.background,
                padding: EdgeInsets.only(left: _outerPadding, bottom: 3),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                                child: Semantics(
                                    sortKey: OrdinalSortKey(1),
                                    container: true,
                                    child: Text(
                                        StringUtils.ensureNotEmpty(_post?.subject),
                                        maxLines: 5,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontFamily:
                                            Styles().fontFamilies!.bold,
                                            fontSize: 24,
                                            color: Styles()
                                                .colors!
                                                .fillColorPrimary)))),
                            Visibility(
                                visible: _isEditPostVisible && !widget.hidePostOptions,
                                child: Semantics(
                                    container: true,
                                    sortKey: OrdinalSortKey(5),
                                    child: Container(
                                        child: Semantics(
                                            label: Localization()
                                                .getStringEx(
                                                'panel.group.detail.post.reply.edit.label',
                                                "Edit"),
                                            button: true,
                                            child: GestureDetector(
                                                onTap: _onTapEditMainPost,
                                                child: Container(
                                                    color: Colors
                                                        .transparent,
                                                    child: Padding(
                                                        padding: EdgeInsets.only(
                                                            left: 16,
                                                            top: 22,
                                                            bottom: 10,
                                                            right: (_isReplyVisible
                                                                ? (_outerPadding /
                                                                2)
                                                                : _outerPadding)),
                                                        child:
                                                        Image.asset(
                                                          'images/icon-edit.png',
                                                          width: 20,
                                                          height: 20,
                                                          excludeFromSemantics:
                                                          true,
                                                        )))))))),
                            Visibility(
                                visible: _isDeletePostVisible && !widget.hidePostOptions,
                                child: Semantics(
                                    container: true,
                                    sortKey: OrdinalSortKey(5),
                                    child: Container(
                                        child: Semantics(
                                            label: Localization()
                                                .getStringEx(
                                                'panel.group.detail.post.reply.delete.label',
                                                "Delete"),
                                            button: true,
                                            child: GestureDetector(
                                                onTap: _onTapDeletePost,
                                                child: Container(
                                                    color: Colors
                                                        .transparent,
                                                    child: Padding(
                                                        padding: EdgeInsets.only(
                                                            left: 16,
                                                            top: 22,
                                                            bottom: 10,
                                                            right: (_isReplyVisible
                                                                ? (_outerPadding /
                                                                2)
                                                                : _outerPadding)),
                                                        child:
                                                        Image.asset(
                                                          'images/trash.png',
                                                          width: 20,
                                                          height: 20,
                                                          excludeFromSemantics:
                                                          true,
                                                        )))))))),
                            Visibility(
                                visible: _isReplyVisible && !widget.hidePostOptions,
                                child: Semantics(
                                    label: Localization().getStringEx(
                                        'panel.group.detail.post.reply.reply.label',
                                        "Reply"),
                                    button: true,
                                    child: GestureDetector(
                                        onTap: _onTapHeaderReply,
                                        child: Container(
                                            color: Colors.transparent,
                                            child: Padding(
                                                padding: EdgeInsets.only(
                                                    left:
                                                    (_isDeletePostVisible
                                                        ? 8
                                                        : 16),
                                                    top: 22,
                                                    bottom: 10,
                                                    right:
                                                    _outerPadding),
                                                child: Image.asset(
                                                  'images/icon-group-post-reply.png',
                                                  width: 20,
                                                  height: 20,
                                                  fit: BoxFit.fill,
                                                  excludeFromSemantics:
                                                  true,
                                                ))))))
                          ]),
                    ]))
      ]),
      Visibility(
          visible: _loading,
          child: Center(child: CircularProgressIndicator())),
    ]);
  }

  Widget _buildPostContent() {
    TextEditingController bodyController = TextEditingController();
    bodyController.text = _mainPostUpdateData?.body ?? '';
    return Semantics(
        sortKey: OrdinalSortKey(4),
        container: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsets.only(
                      left: _outerPadding,
                      top: 0,
                      right: _outerPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Visibility(visible: !_isEditMainPost,
                          child: Semantics(
                              container: true,
                              child: Html(
                                  data: StringUtils.ensureNotEmpty(_post?.body),
                                  style: {
                                    "body": Style(
                                        color: Styles().colors!.fillColorPrimary,
                                        fontFamily: Styles().fontFamilies!.regular,
                                        fontSize: FontSize(20),
                                        margin: EdgeInsets.zero,
                                    ),
                                  },
                                  onLinkTap: (url, context, attributes, element) =>
                                      _onTapPostLink(url)))),
                      Visibility(
                          visible: _isEditMainPost,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    padding: EdgeInsets.only(top: 8, bottom: _outerPadding),
                                    child: TextField(
                                        onChanged: (txt) => _mainPostUpdateData?.body = txt,
                                        controller: bodyController,
                                        maxLines: null,
                                        autofocus: true,
                                        decoration: InputDecoration(
                                            hintText: "Edit the post",
                                            border: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Styles().colors!.mediumGray!,
                                                    width: 0.0))),
                                        style: TextStyle(
                                            color: Styles().colors!.textBackground,
                                            fontSize: 16,
                                            fontFamily: Styles().fontFamilies!.regular))),
                                Row(children: [
                                  Flexible(
                                      flex: 1,
                                      child: RoundedButton(
                                          label:
                                          Localization().getStringEx('panel.group.detail.post.update.button.update.title', 'Update')!,
                                          borderColor: Styles().colors!.fillColorSecondary,
                                          textColor: Styles().colors!.fillColorPrimary,
                                          backgroundColor: Styles().colors!.white,
                                          onTap: _onTapUpdateMainPost)),
                                ])


                              ])),
                      Semantics(
                          sortKey: OrdinalSortKey(2),
                          container: true,
                          child: Padding(
                              padding: EdgeInsets.only(top: 4, right: _outerPadding),
                              child: Text(
                                  StringUtils.ensureNotEmpty(
                                      _post?.member?.displayShortName ),
                                  style: TextStyle(
                                      fontFamily:
                                      Styles().fontFamilies!.medium,
                                      fontSize: 20,
                                      color: Styles()
                                          .colors!
                                          .fillColorPrimary)))),
                      Semantics(
                          sortKey: OrdinalSortKey(3),
                          container: true,
                          child: Padding(
                              padding: EdgeInsets.only(top: 3, right: _outerPadding),
                              child: Text(
                                  StringUtils.ensureNotEmpty(
                                      _post?.displayDateTime),
                                  semanticsLabel: "Updated ${widget.post?.displayDateTime ?? ""} ago",
                                  style: TextStyle(
                                      fontFamily:
                                      Styles().fontFamilies!.medium,
                                      fontSize: 16,
                                      color: Styles()
                                          .colors!
                                          .fillColorPrimary)))),

                    ],
                  )),

            ]));
  }

  _buildRepliesSection(){
    List<GroupPost>? replies;
    if (_focusedReply != null) {
      replies = _generateFocusedThreadList();
    }
    else if (_editingReply != null) { //TBD check this
      replies = [_editingReply!];
    }
    else {
      replies = _post?.replies;
    }

    return Padding(
        padding: EdgeInsets.only(
            bottom: _outerPadding),
        child: _buildRepliesWidget(replies: replies, focusedReplyId: _focusedReply?.id, showRepliesCount: _focusedReply == null));
  }
  
  List<GroupPost> _generateFocusedThreadList(){
    List<GroupPost> result = [];
    if(CollectionUtils.isNotEmpty(widget.replyThread)){
      result.addAll(widget.replyThread!);
    }
    if(_focusedReply!=null){
      result.add(_focusedReply!);
    }
    
    return result;
  }

  Widget _buildPostEdit() {
    bool currentUserIsMemberOrAdmin =
        widget.group?.currentUserIsMemberOrAdmin ?? false;
    return Visibility(
        key: _postEditKey,
        visible: currentUserIsMemberOrAdmin,
        child: Padding(
            padding: EdgeInsets.all(_outerPadding),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildReplyTextField(),
              _buildReplyImageSection(),
              Row(children: [
                Flexible(
                    flex: 1,
                    child: RoundedButton(
                        label: (_editingReply != null) ?
                          Localization().getStringEx('panel.group.detail.post.update.button.update.title', 'Update')! :
                          Localization().getStringEx('panel.group.detail.post.create.button.send.title', 'Send')!,
                        borderColor: Styles().colors!.fillColorSecondary,
                        textColor: Styles().colors!.fillColorPrimary,
                        backgroundColor: Styles().colors!.white,
                        onTap: _onTapSend)),
                Container(width: 20),
                Flexible(
                    flex: 1,
                    child: RoundedButton(
                        label: Localization().getStringEx(
                            'panel.group.detail.post.create.button.cancel.title',
                            'Cancel')!,
                        borderColor: Styles().colors!.textSurface,
                        textColor: Styles().colors!.fillColorPrimary,
                        backgroundColor: Styles().colors!.white,
                        onTap: _onTapCancel))
              ])
            ])));
  }

  Widget _buildReplyImageSection(){
    return
      Container(
        padding: EdgeInsets.only(bottom: 12),
        child: ImageChooserWidget(
          imageUrl: _replyEditData?.imageUrl,
          showSlant: false,
          wrapContent: true,
          buttonVisible: _editingReply!=null,
          onImageChanged: (String imageUrl) => _replyEditData?.imageUrl = imageUrl,
          imageSemanticsLabel: "Reply", //TBD localize
        )
     );
  }

  Widget _buildReplyTextField(){
    return PostInputField(
      key: _postInputKey,
      text: _replyEditData?.body,
      onBodyChanged: (text) => _replyEditData?.body = text,
    );
  }

  Widget _buildRepliesWidget(
      {List<GroupPost>? replies,
      double leftPaddingOffset = 0,
      bool nestedReply = false,
      bool showRepliesCount = true,
      String? focusedReplyId,
      }) {
    List<GroupPost>? visibleReplies = _getVisibleReplies(replies);
    if (CollectionUtils.isEmpty(visibleReplies)) {
      return Container();
    }
    List<Widget> replyWidgetList = [];
    if(StringUtils.isEmpty(focusedReplyId) && CollectionUtils.isNotEmpty(visibleReplies) ){
      replyWidgetList.add(_buildRepliesHeader());
      replyWidgetList.add(Container(height: 8,));
    }

    for (int i = 0; i < visibleReplies!.length; i++) {
      if (i > 0 || nestedReply) {
        replyWidgetList.add(Container(height: 10));
      }
      GroupPost? reply = visibleReplies[i];
      String? optionsIconPath;
      void Function()? optionsFunctionTap;
      if (_isReplyVisible) {
        optionsIconPath = 'images/icon-groups-options-orange.png';
        optionsFunctionTap = () => _onTapReplyOptions(reply);
      }
      replyWidgetList.add(
          Container(
            padding: EdgeInsets.symmetric(horizontal: _outerPadding),
            child: Padding(
              padding: EdgeInsets.only(left: leftPaddingOffset),
              child: GroupReplyCard(
                reply: reply,
                post: widget.post,
                group: widget.group,
                iconPath: optionsIconPath,
                semanticsLabel: "options",
                showRepliesCount: showRepliesCount,
                onIconTap: optionsFunctionTap,
                onImageTap: (){_showModalImage(reply.imageUrl);},
                onCardTap: (){_onTapReplyCard(reply);},
            ))));
      if(reply.id == focusedReplyId) {
        if(CollectionUtils.isNotEmpty(reply.replies)){
          replyWidgetList.add(Container(height: 8,));
          replyWidgetList.add(_buildRepliesHeader());
        }
        replyWidgetList.add(_buildRepliesWidget(
            replies: reply.replies,
            leftPaddingOffset: (leftPaddingOffset /*+ 5*/),
            nestedReply: true,
            focusedReplyId: focusedReplyId
        ));
      }
    }
    return Padding(
        padding: EdgeInsets.only(top: nestedReply ? 0 : 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: replyWidgetList));
  }

  Widget _buildRepliesHeader(){
    return
      Semantics(
        container: true,
        hint: "Heading",
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: _outerPadding),
                color: Styles().colors!.fillColorPrimary,
                child: Text("Replies",
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: Styles().fontFamilies!.medium,
                        color: Styles().colors!.white)
                ),
              )
        )
      ],
    ));
  }

  List<GroupPost>? _getVisibleReplies(List<GroupPost>? replies) {
    if (CollectionUtils.isEmpty(replies)) {
      return null;
    }
    List<GroupPost> visibleReplies = [];
    bool currentUserIsMemberOrAdmin =
        widget.group?.currentUserIsMemberOrAdmin ?? false;
    for (GroupPost? reply in replies!) {
      bool replyVisible = (reply!.private == false) ||
          (reply.private == null) ||
          currentUserIsMemberOrAdmin;
      if (replyVisible) {
        visibleReplies.add(reply);
      }
    }
    return visibleReplies;
  }

  //Tap Actions
  void _onTapReplyCard(GroupPost? reply){
    Analytics().logSelect(target: 'Reply Card');
    List<GroupPost> thread = [];
    if(CollectionUtils.isNotEmpty(widget.replyThread)){
      thread.addAll(widget.replyThread!);
    }
    if(_focusedReply!=null) {
      thread.add(_focusedReply!);
    }
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostDetailPanel(post: widget.post, group: widget.group, focusedReply: reply, hidePostOptions: true, replyThread: thread,)));
  }

  void _onTapDeletePost() {
    Analytics().logSelect(target: 'Delete Post');
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: Text(Localization().getStringEx(
            'panel.group.detail.post.delete.confirm.msg',
            'Are you sure that you want to delete this post?')!),
        actions: <Widget>[
          TextButton(
              child:
                  Text(Localization().getStringEx('dialog.yes.title', 'Yes')!),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost();
              }),
          TextButton(
              child: Text(Localization().getStringEx('dialog.no.title', 'No')!),
              onPressed: () => Navigator.of(context).pop())
        ]);
  }

  void _deletePost() {
    _setLoading(true);
    Groups().deletePost(widget.group?.id, _post).then((succeeded) {
      _setLoading(false);
      if (succeeded) {
        Navigator.of(context).pop();
      } else {
        AppAlert.showDialogResult(
            context,
            Localization().getStringEx(
                'panel.group.detail.post.delete.failed.msg',
                'Failed to delete post.'));
      }
    });
  }

  void _onTapReplyOptions(GroupPost? reply) {
    Analytics().logSelect(target: 'Reply Options');
    showModalBottomSheet(
        context: context,
        backgroundColor: Styles().colors!.white,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Visibility(visible: _isReplyVisible, child: RibbonButton(
                  height: null,
                  leftIcon: "images/icon-group-post-reply.png",
                  label: Localization().getStringEx(
                      "panel.group.detail.post.reply.reply.label", "Reply"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _onTapPostReply(reply: reply);
                  },
                )),
                Visibility(visible: _isEditVisible(reply), child: RibbonButton(
                  height: null,
                  leftIcon: "images/icon-edit.png",
                  label: Localization().getStringEx(
                      "panel.group.detail.post.reply.edit.label", "Edit"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _onTapEditPost(reply: reply);
                  },
                )),
                Visibility(visible: _isDeleteReplyVisible(reply), child: RibbonButton(
                  height: null,
                  leftIcon: "images/trash.png",
                  label: Localization().getStringEx(
                      "panel.group.detail.post.reply.delete.label", "Delete"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _onTapDeleteReply(reply);
                  },
                )),
              ],
            ),
          );
        });
  }

  void _onTapDeleteReply(GroupPost? reply) {
    Analytics().logSelect(target: 'Delete Reply');
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: Text(Localization().getStringEx(
            'panel.group.detail.post.reply.delete.confirm.msg',
            'Are you sure that you want to delete this reply?')!),
        actions: <Widget>[
          TextButton(
              child:
                  Text(Localization().getStringEx('dialog.yes.title', 'Yes')!),
              onPressed: () {
                Analytics().logAlert(text: 'Are you sure that you want to delete this reply?', selection: 'Yes');
                Navigator.of(context).pop();
                _deleteReply(reply);
              }),
          TextButton(
              child: Text(Localization().getStringEx('dialog.no.title', 'No')!),
              onPressed: () {
                Analytics().logAlert(text: 'Are you sure that you want to delete this reply?', selection: 'No');
                Navigator.of(context).pop();
              })
        ]);
  }

  void _deleteReply(GroupPost? reply) {
    _setLoading(true);
    _clearSelectedReplyId();
    Groups().deletePost(widget.group?.id, reply).then((succeeded) {
      _setLoading(false);
      if (!succeeded) {
        AppAlert.showDialogResult(
            context,
            Localization().getStringEx(
                'panel.group.detail.post.reply.delete.failed.msg',
                'Failed to delete reply.'));
      }
    });
  }

  void _onTapHeaderReply() {
    Analytics().logSelect(target: 'Reply');
    _clearBodyControllerContent();
    _scrollToPostEdit();
  }

  void _onTapPostReply({GroupPost? reply}) {
    Analytics().logSelect(target: 'Post Reply');
    //Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostDetailPanel(post: widget.post, group: widget.group, focusedReply: reply, hidePostOptions: true,)));
    if (mounted) {
      setState(() {
        _selectedReplyId = reply?.id;
      });
    }
    _clearBodyControllerContent();
    _scrollToPostEdit();
  }

  void _onTapEditMainPost(){
    _mainPostUpdateData = PostDataModel(body:_post?.body, imageUrl: _post?.imageUrl);
    if(mounted){
      setState(() {
      });
    }
  }

  void _onTapUpdateMainPost(){
    String? body = _mainPostUpdateData?.body;
    String? imageUrl = _mainPostUpdateData?.imageUrl ?? _post?.imageUrl;
    if (StringUtils.isEmpty(body)) {
      String? validationMsg = Localization().getStringEx('panel.group.detail.post.create.validation.body.msg', "Post message required");
      AppAlert.showDialogResult(context, validationMsg);
      return;
    }
    String htmlModifiedBody = HtmlUtils.replaceNewLineSymbols(body);

    _setLoading(true);
    GroupPost postToUpdate = GroupPost(id: _post?.id, subject: _post?.subject, body: htmlModifiedBody, imageUrl: imageUrl, private: true);
    Groups().updatePost(widget.group?.id, postToUpdate).then((succeeded) {
      _mainPostUpdateData = null;
      _setLoading(false);
    });

  }

  void _onTapEditPost({GroupPost? reply}) {
    Analytics().logSelect(target: 'Edit Reply');
    if (mounted) {
      setState(() {
        _editingReply = reply;
        _replyEditData?.imageUrl = reply?.imageUrl;
        _replyEditData?.body = reply?.body;
      });
      _postInputKey = GlobalKey(); //Refresh InputField to hook new data //Edit Reply
      _postImageHolderKey = GlobalKey(); //Refresh ImageHolder to hook new data // Edit Reply
      _scrollToPostEdit();
    }
  }

  void _onTapPostLink(String? url) {
    Analytics().logSelect(target: 'link');
    if (StringUtils.isNotEmpty(url)) {
      Navigator.push(context,
          CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
    }
  }

  void _reloadPost() {
    _setLoading(true);
    Groups().loadGroupPosts(widget.group?.id).then((posts) {
      if (CollectionUtils.isNotEmpty(posts)) {
        try { _post = (posts as List<GroupPost?>).firstWhere((post) => (post?.id == _post?.id), orElse: () => null); }
        catch (e) {}
        _sortReplies(_post?.replies);
        GroupPost? updatedReply = deepFindPost(posts, _focusedReply?.id);
        if(updatedReply!=null){
          setState(() {
            _focusedReply = updatedReply;
            _sortReplies(_focusedReply?.replies);
          });
        }
      } else {
        _post = null;
      }
      _setLoading(false);
    });
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _loading = loading;
      });
    }
  }

  void _onTapCancel() {
    Analytics().logSelect(target: 'Cancel');
    if (_editingReply != null) {
      setState(() {
        _editingReply = null;
        _replyEditData?.imageUrl = null;
        _replyEditData?.body = '';
      });
    }
    else {
      Navigator.of(context).pop();
    }
  }

  void _onTapSend() {
    Analytics().logSelect(target: 'Send');
    FocusScope.of(context).unfocus();
    
    String? body = _replyEditData?.body;
    String? imageUrl;

    if (StringUtils.isEmpty(body)) {
      String validationMsg = ((_editingReply != null))
          ? Localization().getStringEx('panel.group.detail.post.create.validation.body.msg', "Post message required")!
          : Localization().getStringEx('panel.group.detail.post.create.reply.validation.body.msg', "Reply message required")!;
      AppAlert.showDialogResult(context, validationMsg);
      return;
    }
    String htmlModifiedBody = HtmlUtils.replaceNewLineSymbols(body);
    
    _setLoading(true);
    if (_editingReply != null) {
      imageUrl = StringUtils.isNotEmpty(_replyEditData?.imageUrl) ? _replyEditData?.imageUrl : _editingReply?.imageUrl;
      GroupPost postToUpdate = GroupPost(id: _editingReply?.id, subject: _editingReply?.subject, imageUrl: imageUrl , body: body, private: true);
      Groups().updatePost(widget.group?.id, postToUpdate).then((succeeded) {
        _onUpdateFinished(succeeded);
      });
    } else {
      String? parentId;

      imageUrl =  _replyEditData?.imageUrl ?? imageUrl; // if _preparedReplyData then this is new Reply if we already have image then this is create new post for group
      if (_selectedReplyId != null) {
        parentId = _selectedReplyId;
      }
      else if (_focusedReply != null) {
        parentId = _focusedReply!.id;
      }
      else if (_post != null) {
        parentId = _post!.id;
      }
      
      GroupPost post = GroupPost(parentId: parentId, body: htmlModifiedBody, private: true, imageUrl: imageUrl); // if no parentId then this is a new post for the group.
      Groups().createPost(widget.group?.id, post).then((succeeded) {
        _onSendFinished(succeeded);
      });
    }
  }

  void _onSendFinished(bool succeeded) {
    _setLoading(false);
    if (succeeded) {
      _clearSelectedReplyId();
      _clearBodyControllerContent();
      Navigator.of(context).pop(true);
    } else {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.detail.post.create.reply.failed.msg', 'Failed to create new reply.'));
    }
  }

  void _onUpdateFinished(bool succeeded) {
    _setLoading(false);
    if (succeeded) {
      Navigator.of(context).pop(true);
    } else {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.detail.post.update.reply.failed.msg', 'Failed to edit reply.'));
    }
  }

  void _clearSelectedReplyId() {
    _selectedReplyId = null;
  }

  void _clearBodyControllerContent() {
    _replyEditData?.body = '';
  }

  //Modal Image Dialog
  void _showModalImage(String? url){
    if(url != null) {
      setState(() {
        _modalImageUrl = url;
      });
    }
  }

  //Scroll
  void _evalSliverHeaderHeight() {
    double? sliverHeaderHeight;
    try {
      final RenderObject? renderBox = _sliverHeaderKey.currentContext?.findRenderObject();
      if (renderBox is RenderBox) {
        sliverHeaderHeight = renderBox.size.height;
      }
    } on Exception catch (e) {
      print(e.toString());
    }

    setState(() {
      _sliverHeaderHeight = sliverHeaderHeight;
    });
  }

  void _scrollToPostEdit() {
    BuildContext? postEditContext = _postEditKey.currentContext;
    //Scrollable.ensureVisible(postEditContext, duration: Duration(milliseconds: 10));
    RenderObject? renderObject = postEditContext?.findRenderObject();
    RenderAbstractViewport? viewport = (renderObject != null) ? RenderAbstractViewport.of(renderObject) : null;
    double? postEditTop = (viewport != null) ? viewport.getOffsetToReveal(renderObject!, 0.0).offset : null;

    BuildContext? scrollContainerContext = _scrollContainerKey.currentContext;
    RenderObject? scrollContainerRenderBox = scrollContainerContext?.findRenderObject();
    double? scrollContainerHeight = (scrollContainerRenderBox is RenderBox) ? scrollContainerRenderBox.size.height : null;

    if ((scrollContainerHeight != null) && (postEditTop != null)) {
      double offset = postEditTop - scrollContainerHeight + 120;
      offset = max(offset, _scrollController.position.minScrollExtent);
      offset = min(offset, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(offset, duration: Duration(milliseconds: 1), curve: Curves.easeIn);
    }

  }

  //Utils
  GroupPost? deepFindPost(List<GroupPost>? posts, String? id){
    if(CollectionUtils.isEmpty(posts) || StringUtils.isEmpty(id)){
      return null;
    }

    GroupPost? result;
    for(GroupPost post in posts!){
      if(post.id == id){
        result = post;
        break;
      } else {
        result = deepFindPost(post.replies, id);
        if(result!=null){
          break;
        }
      }
    }

    return result;
  }

  void _sortReplies(List<GroupPost>? replies){
    if(CollectionUtils.isNotEmpty(replies)) {
      try {
        replies!.sort((post1, post2) =>
            post1.dateCreatedUtc!.compareTo(post2.dateCreatedUtc!));
      } catch (e) {}
    }
  }

  //Getters
  bool _isEditVisible(GroupPost? post) {
    return _isCurrentUserCreator(post);
  }

  bool _isDeleteVisible(GroupPost? item) {
    if (widget.group?.currentUserIsAdmin ?? false) {
      return true;
    } else if (widget.group?.currentUserIsMember ?? false) {
      return _isCurrentUserCreator(item);
    } else {
      return false;
    }
  }

  bool _isDeleteReplyVisible(GroupPost? reply) {
    return _isDeleteVisible(reply);
  }

  bool _isCurrentUserCreator(GroupPost? item) {
    String? currentMemberEmail = widget.group?.currentUserAsMember?.userId;
    String? itemMemberUserId = item?.member?.userId;
    return StringUtils.isNotEmpty(currentMemberEmail) &&
        StringUtils.isNotEmpty(itemMemberUserId) &&
        (currentMemberEmail == itemMemberUserId);
  }

  bool get _isEditPostVisible {
    return _isEditVisible(_post);
  }

  bool get _isDeletePostVisible {
    return _isDeleteVisible(_post);
  }

  bool get _isReplyVisible {
    return widget.group?.currentUserIsMemberOrAdmin ?? false;
  }

  bool get _isEditMainPost{
    return _mainPostUpdateData!=null;
  }

  // Notifications Listener
  @override
  void onNotification(String name, param) {
    if (name == Groups.notifyGroupPostsUpdated) {
      _reloadPost();
    }
  }
}
