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
import 'package:flutter/semantics.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';

class GroupPostDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final GroupPost? post;
  final GroupPost? focusedReply;
  final List<GroupPost?>? replyThread;
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

  GroupPost? _post;
  GroupPost? _focusedReply;
  TextEditingController _subjectController = TextEditingController();
  TextEditingController _bodyController = TextEditingController();
  TextEditingController _linkTextController = TextEditingController();
  TextEditingController _linkUrlController = TextEditingController();
  TextEditingController _mainPostController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  String? _selectedReplyId;
  GroupPost? _editingPost;

  bool _editMainPost = false;

  bool _loading = false;

  final GlobalKey _sliverHeaderKey = GlobalKey();
  final GlobalKey _postEditKey = GlobalKey();
  final GlobalKey _scrollContainerKey = GlobalKey();
  double? _sliverHeaderHeight;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, Groups.notifyGroupPostsUpdated);
    _post = widget.post;
    _focusedReply = widget.focusedReply;
    _sortReplies(_post?.replies);
    _sortReplies(_focusedReply?.replies);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
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
    _subjectController.dispose();
    _bodyController.dispose();
    _linkTextController.dispose();
    _linkUrlController.dispose();
    _mainPostController.dispose();
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
        body: Stack(children: [
          Stack(alignment: Alignment.topCenter, children: [
            SingleChildScrollView(key: _scrollContainerKey, controller: _scrollController, child:
              Column(children: [
                _buildPostContent(),
                _buildPostEdit(),
            ],)),
            Visibility(
                visible: !_isCreatePost,
                child: Container(
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
                                            AppString.getDefaultEmptyString(
                                                value: _post?.subject)!,
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
                                                        onTap: _onTapEdit,
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
                        ])))
          ]),
          Visibility(
              visible: _loading,
              child: Center(child: CircularProgressIndicator()))
        ]));
  }

  Widget _buildPostContent() {
    List<GroupPost?>? replies;
    if (_focusedReply != null) {
      replies = _generateFocusedThreadList();
    }
    else if (_editingPost != null) {
      replies = [_editingPost];
    }
    else {
      replies = _post?.replies;
    }

    return Semantics(
        sortKey: OrdinalSortKey(4),
        container: true,
        child: Visibility(
            visible: !_isCreatePost,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsets.only(
                      left: _outerPadding,
                      top: _sliverHeaderHeight ?? 0,
                      right: _outerPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                          sortKey: OrdinalSortKey(2),
                          container: true,
                          child: Padding(
                              padding: EdgeInsets.only(top: 4, right: _outerPadding),
                              child: Text(
                                  AppString.getDefaultEmptyString(
                                      value: _post?.member?.name )!,
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
                                  AppString.getDefaultEmptyString(
                                      value: _post?.displayDateTime)!,
                                  semanticsLabel: "Updated ${widget.post?.getDisplayDateTime() ?? ""} ago",
                                  style: TextStyle(
                                      fontFamily:
                                      Styles().fontFamilies!.medium,
                                      fontSize: 16,
                                      color: Styles()
                                          .colors!
                                          .fillColorPrimary)))),
                      Visibility(visible: !_editMainPost,
                        child: Semantics(
                          container: true,
                          child: Html(
                            data: AppString.getDefaultEmptyString(value: _post?.body),
                            style: {
                              "body": Style(
                                  color: Styles().colors!.fillColorPrimary,
                                  fontFamily: Styles().fontFamilies!.regular,
                                  fontSize: FontSize(20))
                            },
                            onLinkTap: (url, context, attributes, element) =>
                              _onTapPostLink(url)))),
                      Visibility(
                          visible: _editMainPost,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    padding: EdgeInsets.only(top: 8, bottom: _outerPadding),
                                    child: TextField(
                                        controller: _mainPostController,
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
                                          Localization().getStringEx('panel.group.detail.post.update.button.update.title', 'Update'),
                                          borderColor: Styles().colors!.fillColorSecondary,
                                          textColor: Styles().colors!.fillColorPrimary,
                                          backgroundColor: Styles().colors!.white,
                                          onTap: _onTapSave)),
                                  ])


                              ])),
                    ],
                  )),
              Padding(
                  padding: EdgeInsets.only(
                      bottom: _outerPadding),
                  child: _buildRepliesWidget(replies: replies, focusedReplyId: _focusedReply?.id, showRepliesCount: _focusedReply == null))
            ])));
  }
  
  List<GroupPost?> _generateFocusedThreadList(){
    List<GroupPost?> result = [];
    if(AppCollection.isCollectionNotEmpty(widget.replyThread)){
      result.addAll(widget.replyThread!);
    }
    if(_focusedReply!=null){
      result.add(_focusedReply);
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Visibility(
                  visible: _isCreatePost,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            Localization().getStringEx(
                                'panel.group.detail.post.create.subject.label',
                                'Subject')!,
                            style: TextStyle(
                                fontSize: 18,
                                fontFamily: Styles().fontFamilies!.bold,
                                color: Styles().colors!.fillColorPrimary)),
                        Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: TextField(
                                controller: _subjectController,
                                maxLines: 1,
                                decoration: InputDecoration(
                                    hintText: Localization().getStringEx(
                                        'panel.group.detail.post.create.subject.field.hint',
                                        'Write a Subject'),
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Styles().colors!.mediumGray!,
                                            width: 0.0))),
                                style: TextStyle(
                                    color: Styles().colors!.textBackground,
                                    fontSize: 16,
                                    fontFamily: Styles().fontFamilies!.regular)))
                      ])),
              Padding(
                  padding: EdgeInsets.only(top: _isCreatePost ? 16 : 0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _FontIcon(
                            onTap: _onTapBold,
                            buttonLabel: "Bold",
                            iconPath: 'images/icon-bold.png'),
                        Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: _FontIcon(
                                onTap: _onTapItalic,
                                buttonLabel: "Italic",
                                iconPath: 'images/icon-italic.png')),
                        Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: _FontIcon(
                                onTap: _onTapUnderline,
                                buttonLabel: "Underline",
                                iconPath: 'images/icon-underline.png')),
                        Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: Semantics(button: true, child:
                              GestureDetector(
                                onTap: _onTapEditLink,
                                child: Text(
                                    Localization().getStringEx(
                                        'panel.group.detail.post.create.link.label',
                                        'Link')!,
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.black,
                                        fontFamily:
                                            Styles().fontFamilies!.medium)))))
                      ])),
              Padding(
                  padding: EdgeInsets.only(top: 8, bottom: _outerPadding),
                  child: TextField(
                      controller: _bodyController,
                      maxLines: 15,
                      decoration: InputDecoration(
                          hintText: (_isCreatePost ? Localization().getStringEx(
                              "panel.group.detail.post.create.body.field.hint",
                              "Write a Post ...") : Localization().getStringEx(
                              "panel.group.detail.post.reply.create.body.field.hint",
                              "Write a Reply ...")),
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
                        label: (_editingPost != null) ?
                          Localization().getStringEx('panel.group.detail.post.update.button.update.title', 'Update') :
                          Localization().getStringEx('panel.group.detail.post.create.button.send.title', 'Send'),
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
                            'Cancel'),
                        borderColor: Styles().colors!.textSurface,
                        textColor: Styles().colors!.fillColorPrimary,
                        backgroundColor: Styles().colors!.white,
                        onTap: _onTapCancel))
              ])
            ])));
  }

  Widget _buildRepliesWidget(
      {List<GroupPost?>? replies,
      double leftPaddingOffset = 0,
      bool nestedReply = false,
      bool showRepliesCount = true,
      String? focusedReplyId,
      }) {
    List<GroupPost?>? visibleReplies = _getVisibleReplies(replies);
    if (AppCollection.isCollectionEmpty(visibleReplies)) {
      return Container();
    }
    List<Widget> replyWidgetList = [];
    if(AppString.isStringEmpty(focusedReplyId) && AppCollection.isCollectionNotEmpty(visibleReplies) ){
      replyWidgetList.add(_buildRepliesHeader());
      replyWidgetList.add(Container(height: 8,));
    }

    for (int i = 0; i < visibleReplies!.length; i++) {
      if (i > 0 || nestedReply) {
        replyWidgetList.add(Container(height: 10));
      }
      GroupPost? reply = visibleReplies[i];
      String? optionsIconPath;
      Function? optionsFunctionTap;
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
                onCardTap: (){_onTapReplyCard(reply);},
            ))));
      if(reply?.id == focusedReplyId) {
        if(AppCollection.isCollectionNotEmpty(reply?.replies)){
          replyWidgetList.add(Container(height: 8,));
          replyWidgetList.add(_buildRepliesHeader());
        }
        replyWidgetList.add(_buildRepliesWidget(
            replies: reply?.replies,
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

  void _sortReplies(List<GroupPost?>? replies){
    if(AppCollection.isCollectionNotEmpty(replies)) {
      try {
        replies!.sort((post1, post2) =>
            post1?.dateCreatedUtc?.compareTo(post2?.dateCreatedUtc!));
      } catch (e) {}
    }
  }

  void _onTapReplyCard(GroupPost? reply){
    Analytics().logSelect(target: 'Reply Card');
    List<GroupPost?> thread = [];
    if(AppCollection.isCollectionNotEmpty(widget.replyThread)){
      thread.addAll(widget.replyThread!);
    }
    if(_focusedReply!=null) {
      thread.add(_focusedReply);
    }
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostDetailPanel(post: widget.post, group: widget.group, focusedReply: reply, hidePostOptions: true, replyThread: thread,)));
  }

  List<GroupPost?>? _getVisibleReplies(List<GroupPost?>? replies) {
    if (AppCollection.isCollectionEmpty(replies)) {
      return null;
    }
    List<GroupPost?> visibleReplies = [];
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

  void _evalSliverHeaderHeight() {
    double? sliverHeaderHeight;
    try {
      final RenderObject? renderBox = _sliverHeaderKey?.currentContext?.findRenderObject();
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

  void _onTapEdit(){
    if(mounted){
      _mainPostController.text = _post!.body!;
      setState(() {
        _editMainPost = true;
      });
    }
  }

  void _onTapSave(){
    String body = _mainPostController.text;
    if (AppString.isStringEmpty(body)) {
      String? validationMsg = Localization().getStringEx('panel.group.detail.post.create.validation.body.msg', "Post message required");
      AppAlert.showDialogResult(context, validationMsg);
      return;
    }
    String htmlModifiedBody = _replaceNewLineSymbols(body);

    _setLoading(true);
    GroupPost postToUpdate = GroupPost(id: _post!.id, subject: _post!.subject, body: htmlModifiedBody, private: true);
    Groups().updatePost(widget.group?.id, postToUpdate).then((succeeded) {
      _editMainPost = false;
      _setLoading(false);
    });

  }

  void _onTapEditPost({GroupPost? reply}) {
    Analytics().logSelect(target: 'Edit Reply');
    if (mounted) {
      setState(() {
        _editingPost = reply;
      });
      _bodyController.text = (reply ?? _post)?.body!;
      _scrollToPostEdit();
    }
  }

  void _onTapPostLink(String? url) {
    Analytics.instance.logSelect(target: 'link');
    if (AppString.isStringNotEmpty(url)) {
      Navigator.push(context,
          CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
    }
  }

  void _reloadPost() {
    _setLoading(true);
    Groups().loadGroupPosts(widget.group?.id).then((posts) {
      if (AppCollection.isCollectionNotEmpty(posts)) {
        _post = posts!.firstWhere((post) => (post!.id == _post?.id), orElse: (){ return null; });
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

  GroupPost? deepFindPost(List<GroupPost?>? posts, String? id){
    if(AppCollection.isCollectionEmpty(posts) || AppString.isStringEmpty(id)){
      return null;
    }

    GroupPost? result;
    for(GroupPost? post in posts!){
      if(post?.id == id){
        result = post;
        break;
      } else {
        result = deepFindPost(post!.replies, id);
        if(result!=null){
          break;
        }
      }
    }

    return result;
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
    if (_editingPost != null) {
      setState(() {
        _editingPost = null;
        _bodyController.text = '';
      });
    }
    else {
      Navigator.of(context).pop();
    }
  }

  void _onTapSend() {
    Analytics().logSelect(target: 'Send');
    FocusScope.of(context).unfocus();
    
    String? subject;
    if (_isCreatePost) {
      subject = _subjectController.text;
      if (AppString.isStringEmpty(subject)) {
        AppAlert.showDialogResult(
            context,
            Localization().getStringEx(
                'panel.group.detail.post.create.validation.subject.msg',
                "Post subject required"));
        return;
      }
    }
    
    String body = _bodyController.text;
    if (AppString.isStringEmpty(body)) {
      String? validationMsg = (_isCreatePost || (_editingPost != null))
          ? Localization().getStringEx('panel.group.detail.post.create.validation.body.msg', "Post message required")
          : Localization().getStringEx('panel.group.detail.post.create.reply.validation.body.msg', "Reply message required");
      AppAlert.showDialogResult(context, validationMsg);
      return;
    }
    String htmlModifiedBody = _replaceNewLineSymbols(body);
    
    _setLoading(true);
    if (_editingPost != null) {
      GroupPost postToUpdate = GroupPost(id: _editingPost!.id, subject: _editingPost!.subject, body: body, private: true);
      Groups().updatePost(widget.group?.id, postToUpdate).then((succeeded) {
        _onUpdateFinished(succeeded);
      });
    } else {
      String? parentId;
      if (_selectedReplyId != null) {
        parentId = _selectedReplyId;
      }
      else if (_focusedReply != null) {
        parentId = _focusedReply!.id;
      }
      else if (_post != null) {
        parentId = _post!.id;
      }
      
      GroupPost post = GroupPost(parentId: parentId, subject: subject, body: htmlModifiedBody, private: true);
      Groups().createPost(widget.group?.id, post).then((succeeded) {
        _onCreateFinished(succeeded);
      });
    }
  }

  void _onCreateFinished(bool succeeded) {
    _setLoading(false);
    if (succeeded) {
      _clearSelectedReplyId();
      _clearBodyControllerContent();
      Navigator.of(context).pop(true);
    } else {
      AppAlert.showDialogResult(
          context,
          _isCreatePost
              ? Localization().getStringEx(
                  'panel.group.detail.post.create.post.failed.msg',
                  'Failed to create new post.')
              : Localization().getStringEx(
                  'panel.group.detail.post.create.reply.failed.msg',
                  'Failed to create new reply.'));
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

  void _onTapBold() {
    Analytics().logSelect(target: 'Bold');
    _wrapBodySelection('<b>', '</b>');
  }

  void _onTapItalic() {
    Analytics().logSelect(target: 'Italic');
    _wrapBodySelection('<i>', '</i>');
  }

  void _onTapUnderline() {
    Analytics().logSelect(target: 'Underline');
    _wrapBodySelection('<u>', '</u>');
  }

  void _onTapEditLink() {
    Analytics().logSelect(target: 'Edit Link');
    int linkStartPosition = _bodyController.selection.start;
    int linkEndPosition = _bodyController.selection.end;
    _linkTextController.text = AppString.getDefaultEmptyString(
        value: _bodyController.selection?.textInside(_bodyController.text))!;
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: _buildLinkDialog(),
        actions: [
          TextButton(
              onPressed: () {
                Analytics().logSelect(target: 'Set Link Url');
                _onTapOkLink(linkStartPosition, linkEndPosition);
              },
              child: Text(Localization().getStringEx('dialog.ok.title', 'OK')!)),
          TextButton(
              onPressed: () {
                Analytics().logSelect(target: 'Cancel');
                Navigator.of(context).pop();
              },
              child: Text(
                  Localization().getStringEx('dialog.cancel.title', 'Cancel')!))
        ]);
  }

  Widget _buildLinkDialog() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              Localization().getStringEx(
                  'panel.group.detail.post.create.dialog.link.edit.header',
                  'Edit Link')!,
              style: TextStyle(
                  fontSize: 20,
                  color: Styles().colors!.fillColorPrimary,
                  fontFamily: Styles().fontFamilies!.medium)),
          Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                  Localization().getStringEx(
                      'panel.group.detail.post.create.dialog.link.text.label',
                      'Link Text:')!,
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies!.regular,
                      color: Styles().colors!.fillColorPrimary))),
          Padding(
              padding: EdgeInsets.only(top: 6),
              child: TextField(
                  controller: _linkTextController,
                  maxLines: 1,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Styles().colors!.mediumGray!, width: 0.0))),
                  style: TextStyle(
                      color: Styles().colors!.textBackground,
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies!.regular))),
          Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                  Localization().getStringEx(
                      'panel.group.detail.post.create.dialog.link.url.label',
                      'Link URL:')!,
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies!.regular,
                      color: Styles().colors!.fillColorPrimary))),
          Padding(
              padding: EdgeInsets.only(top: 6),
              child: TextField(
                  controller: _linkUrlController,
                  maxLines: 1,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Styles().colors!.mediumGray!, width: 0.0))),
                  style: TextStyle(
                      color: Styles().colors!.textBackground,
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies!.regular)))
        ]);
  }

  void _onTapOkLink(int startPosition, int endPosition) {
    Navigator.of(context).pop();
    if ((startPosition < 0) || (endPosition < 0)) {
      return;
    }
    String linkText = _linkTextController.text;
    _linkTextController.text = '';
    String linkUrl = _linkUrlController.text;
    _linkUrlController.text = '';
    String currentText = _bodyController.text;
    currentText =
        currentText.replaceRange(startPosition, endPosition, linkText);
    _bodyController.text = currentText;
    endPosition = startPosition + linkText.length;
    _wrapBody('<a href="$linkUrl">', '</a>', startPosition, endPosition);
  }

  void _wrapBodySelection(String firstValue, String secondValue) {
    int startPosition = _bodyController.selection.start;
    int endPosition = _bodyController.selection.end;
    if ((startPosition < 0) || (endPosition < 0)) {
      return;
    }
    _wrapBody(firstValue, secondValue, startPosition, endPosition);
  }

  void _wrapBody(String firstValue, String secondValue, int startPosition,
      int endPosition) {
    String currentText = _bodyController.text;
    String result = AppString.wrapRange(
        currentText, firstValue, secondValue, startPosition, endPosition);
    _bodyController.text = result;
    _bodyController.selection = TextSelection.fromPosition(
        TextPosition(offset: (endPosition + firstValue.length)));
  }

  void _scrollToPostEdit() {

    BuildContext? postEditContext = _postEditKey?.currentContext;
    //Scrollable.ensureVisible(postEditContext, duration: Duration(milliseconds: 10));
    RenderObject renderObject = postEditContext?.findRenderObject()!;
    RenderAbstractViewport? viewport = (renderObject != null) ? RenderAbstractViewport.of(renderObject) : null;
    double? postEditTop = viewport?.getOffsetToReveal(renderObject, 0.0)?.offset;

    BuildContext? scrollContainerContext = _scrollContainerKey?.currentContext;
    RenderObject? scrollContainerRenderBox = scrollContainerContext?.findRenderObject();
    double? scrollContainerHeight = (scrollContainerRenderBox is RenderBox) ? scrollContainerRenderBox.size?.height : null;

    if ((scrollContainerHeight != null) && (postEditTop != null)) {
      double offset = postEditTop - scrollContainerHeight + 120;
      offset = max(offset, _scrollController.position.minScrollExtent);
      offset = min(offset, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(offset, duration: Duration(milliseconds: 1), curve: Curves.easeIn);
    }

  }

  void _clearSelectedReplyId() {
    _selectedReplyId = null;
  }

  void _clearBodyControllerContent() {
    _bodyController.text = '';
  }

  String _replaceNewLineSymbols(String value) {
    if (AppString.isStringEmpty(value)) {
      return value;
    }
    value = value.replaceAll('\r\n', '</br>');
    value = value.replaceAll('\n', '</br>');
    return value;
  }

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
    return AppString.isStringNotEmpty(currentMemberEmail) &&
        AppString.isStringNotEmpty(itemMemberUserId) &&
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

  bool get _isCreatePost {
    return (_post == null);
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Groups.notifyGroupPostsUpdated) {
      _reloadPost();
    }
  }
}

class _FontIcon extends StatelessWidget {
  final Function onTap;
  final String iconPath;
  final String? buttonLabel;
  _FontIcon({required this.onTap, required this.iconPath, this.buttonLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(button: true, label: buttonLabel,
      child:GestureDetector(
        onTap: onTap as void Function()?, child: Image.asset(iconPath, width: 18, height: 18, excludeFromSemantics: true,)));
  }
}
