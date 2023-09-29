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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/groups/GroupPostReportAbuse.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

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
  List<Member>? _allMembersAllowedToPost;
  //Reply - Edit/Create/Show
  GroupPost? _focusedReply; //Focused on Reply {Replies Thread Presentation} // User when Refresh post thread
  String? _selectedReplyId; // Thread Id target for New Reply {Data Create}
  GroupPost? _editingReply; //Edit Mode for Reply {Data Edit}
  PostDataModel? _replyEditData = PostDataModel(); //used for Reply Create / Edit; Empty data for new Reply

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
    NotificationService().subscribe(this, [Groups.notifyGroupPostsUpdated, Groups.notifyGroupPostReactionsUpdated]);
    _loadMembersAllowedToPost();
    _post = widget.post ?? GroupPost(); //If no post then prepare data for post creation
    _focusedReply = widget.focusedReply;
    _sortReplies(_post?.replies);
    _sortReplies(_focusedReply?.replies);

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
              Localization().getStringEx('panel.group.detail.post.header.title', 'Post'),
              style:  Styles().textStyles?.getTextStyle("widget.heading.regular.extra_fat"),),
            centerTitle: false),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar(),
        body: _buildContent(),
      );
  }

  Widget _buildContent(){
    return Stack(children: [
      Stack(alignment: Alignment.topCenter, children: [
        SingleChildScrollView(key: _scrollContainerKey, controller: _scrollController, child:
        Column(children: [
          Container(height: _sliverHeaderHeight ?? 0,),
          _isEditMainPost || StringUtils.isNotEmpty(_post?.imageUrl)
            ? ImageChooserWidget(key: _postImageHolderKey, imageUrl: _post?.imageUrl, buttonVisible: _isEditMainPost, onImageChanged: (url) => _mainPostUpdateData?.imageUrl = url,)
            : Container(),
          _buildPostContent(),
          _buildRepliesSection(),
          _buildPostEdit(),
          ],)),
          Container(key: _sliverHeaderKey, color: Styles().colors!.background, padding: EdgeInsets.only(left: _outerPadding, bottom: 3), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child:
                  Semantics(sortKey: OrdinalSortKey(1), container: true, child:
                    Text(StringUtils.ensureNotEmpty(_post?.subject), maxLines: 5, overflow: TextOverflow.ellipsis,
                        style: Styles().textStyles?.getTextStyle("widget.detail.extra_large.fat"),
                    )
                  )
                ),

                Visibility(
                  visible: Config().showGroupPostReactions && (widget.group?.currentUserHasPermissionToSendReactions == true),
                  child: Padding(
                    padding: EdgeInsets.only(left: 8, top: 22, bottom: 10, right: 8),
                    child: GroupPostReaction(
                      groupID: widget.group?.id,
                      post: _post,
                      reaction: thumbsUpReaction,
                      accountIDs: _post?.reactions[thumbsUpReaction],
                      selectedIconKey: 'thumbs-up-filled',
                      deselectedIconKey: 'thumbs-up-outline-gray',
                      // onTapEnabled: _canSendReaction,
                    ),
                  ),
                ),

                Visibility(visible: _isEditPostVisible && !widget.hidePostOptions, child:
                  Semantics(container: true, sortKey: OrdinalSortKey(5), child:
                    Container(child:
                      Semantics(label: Localization().getStringEx('panel.group.detail.post.reply.edit.label', "Edit"), button: true, child:
                        GestureDetector(onTap: _onTapEditMainPost, child:
                          Padding(padding: EdgeInsets.only(left: 8, top: 22, bottom: 10, right: 8), child:
                            Styles().images?.getImage('edit', excludeFromSemantics: true))))))),

                Visibility(visible: _isDeletePostVisible && !widget.hidePostOptions, child:
                  Semantics(container: true, sortKey: OrdinalSortKey(5), child:
                    Container(child:
                      Semantics(label: Localization().getStringEx('panel.group.detail.post.reply.delete.label', "Delete"), button: true, child:
                        GestureDetector(onTap: _onTapDeletePost, child:
                            Padding(padding: EdgeInsets.only(left: 8, top: 22, bottom: 10, right: 8), child:
                              Styles().images?.getImage('trash', excludeFromSemantics: true))))))),

                Visibility(visible: _isReportAbuseVisible && !widget.hidePostOptions, child:
                  Semantics(label: Localization().getStringEx('panel.group.detail.post.button.report.label', "Report"), button: true, child:
                    GestureDetector( onTap: () => _onTapReportAbusePostOptions(), child:
                        Padding(padding: EdgeInsets.only(left: 8, top: 22, bottom: 10, right: 8), child:
                          Styles().images?.getImage('feedback', excludeFromSemantics: true))))),

                Visibility(visible: _isReplyVisible && !widget.hidePostOptions, child:
                  Semantics(label: Localization().getStringEx('panel.group.detail.post.reply.reply.label', "Reply"), button: true, child:
                    GestureDetector(onTap: _onTapHeaderReply, child:
                        Padding(padding: EdgeInsets.only(left: 8, top: 22, bottom: 10, right: 16), child:
                          Styles().images?.getImage('reply', excludeFromSemantics: true))))),

              ]),
            ])
          )
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
                              child:
                              HtmlWidget(
                                  StringUtils.ensureNotEmpty(_post?.body),
                                  onTapUrl : (url) {_onTapPostLink(url); return true;},
                                  textStyle:  Styles().textStyles?.getTextStyle("widget.detail.large"),
                              )
                          )),
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
                                            hintText: Localization().getStringEx("panel.group.detail.post.edit.hint", "Edit the post"),
                                            border: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Styles().colors!.mediumGray!,
                                                    width: 0.0))),
                                        style: Styles().textStyles?.getTextStyle("widget.input_field.text.regular"),
                                       )),
                                Row(children: [
                                  Flexible(
                                      flex: 1,
                                      child: RoundedButton(
                                          label: Localization().getStringEx('panel.group.detail.post.update.button.update.title', 'Update'),
                                          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                                          borderColor: Styles().colors!.fillColorSecondary,
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
                                  style: Styles().textStyles?.getTextStyle("widget.detail.large.thin"),
                                  ))),
                      Semantics(
                          sortKey: OrdinalSortKey(3),
                          container: true,
                          child: Padding(
                              padding: EdgeInsets.only(top: 3, right: _outerPadding),
                              child: Text(
                                  StringUtils.ensureNotEmpty(
                                      _post?.displayDateTime),
                                  semanticsLabel:  sprintf(Localization().getStringEx("panel.group.detail.post.updated.ago.format", "Updated %s ago"),[widget.post?.displayDateTime ?? ""]),
                                  style: Styles().textStyles?.getTextStyle("widget.detail.medium"),))),
                      Container(height: 6,),
                      GroupMembersSelectionWidget(
                        selectedMembers: GroupMembersSelectionWidget.constructUpdatedMembersList(selection:(_isEditMainPost ? _mainPostUpdateData?.members : _post?.members), upToDateMembers: _allMembersAllowedToPost),
                        allMembers: _allMembersAllowedToPost,
                        enabled: _isEditMainPost,
                        groupId: widget.group?.id,
                        groupPrivacy: widget.group?.privacy,
                        onSelectionChanged: (members){
                          setStateIfMounted(() {
                            _mainPostUpdateData?.members = members;
                          });
                        },)
                    ],
                  )),

            ]));
  }

  void _loadMembersAllowedToPost() {
    _setLoading(true);
    Groups().loadMembersAllowedToPost(groupId: widget.group!.id).then((members) {
      _allMembersAllowedToPost = members;
      _setLoading(false);
    });
  }

  _buildRepliesSection(){
    List<GroupPost>? replies;
    if (_focusedReply != null) {
      replies = _generateFocusedThreadList();
    }
    else if (_editingReply != null) {
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
    return Visibility(
        key: _postEditKey,
        visible: widget.group?.currentUserHasPermissionToSendReply == true,
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
                          Localization().getStringEx('panel.group.detail.post.update.button.update.title', 'Update') :
                          Localization().getStringEx('panel.group.detail.post.create.button.send.title', 'Send'),
                        textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                        borderColor: Styles().colors!.fillColorSecondary,
                        backgroundColor: Styles().colors!.white,
                        onTap: _onTapSend)),
                Container(width: 20),
                Flexible(
                    flex: 1,
                    child: RoundedButton(
                        label: Localization().getStringEx(
                            'panel.group.detail.post.create.button.cancel.title',
                            'Cancel'),
                        textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                        borderColor: Styles().colors!.textSurface,
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
          imageSemanticsLabel: Localization().getStringEx('panel.group.detail.post.reply.reply.label', "Reply"),
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
        optionsIconPath = 'more';
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
                    style: Styles().textStyles?.getTextStyle("widget.heading.medium"),
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
    if((reply != null) &&
        ((reply == _focusedReply) || (widget.replyThread!= null && widget.replyThread!.contains(reply)))){
      //Already focused reply.
      // Disabled listener for the focused reply. Prevent duplication. Fix for #2374
      return;
    }
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
            'Are you sure that you want to delete this post?')),
        actions: <Widget>[
          TextButton(
              child:
                  Text(Localization().getStringEx('dialog.yes.title', 'Yes')),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost();
              }),
          TextButton(
              child: Text(Localization().getStringEx('dialog.no.title', 'No')),
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

  void _onTapReportAbusePostOptions() {
    Analytics().logSelect(target: 'Post Options');
    showModalBottomSheet(
      context: context,
      backgroundColor: Styles().colors!.white,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)),),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Visibility(visible: _isReportAbuseVisible, child: RibbonButton(
                leftIconKey: "feedback",
                label: Localization().getStringEx("panel.group.detail.post.button.report.students_dean.labe", "Report to Dean of Students"),
                onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToDeanOfStudents : true), post: widget.post),
              )),
              Visibility(visible: _isReportAbuseVisible, child: RibbonButton(
                leftIconKey: "feedback",
                label: Localization().getStringEx("panel.group.detail.post.button.report.group_admins.labe", "Report to Group Administrator(s)"),
                onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToGroupAdmins: true), post: widget.post),
              )),
            ],
          ),
        );
      });
  }

  void _onTapReplyOptions(GroupPost? reply) {
    Analytics().logSelect(target: 'Reply Options');
    showModalBottomSheet(
      context: context,
      backgroundColor: Styles().colors!.white,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)),),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Visibility(visible: _isReplyVisible, child: RibbonButton(
                leftIconKey: "reply",
                label: Localization().getStringEx("panel.group.detail.post.reply.reply.label", "Reply"),
                onTap: () {
                  Navigator.of(context).pop();
                  _onTapPostReply(reply: reply);
                },
              )),
              Visibility(visible: _isEditVisible(reply), child: RibbonButton(
                leftIconKey: "edit",
                label: Localization().getStringEx("panel.group.detail.post.reply.edit.label", "Edit"),
                onTap: () {
                  Navigator.of(context).pop();
                  _onTapEditPost(reply: reply);
                },
              )),
              Visibility(visible: _isDeleteReplyVisible(reply), child: RibbonButton(
                leftIconKey: "trash",
                label: Localization().getStringEx("panel.group.detail.post.reply.delete.label", "Delete"),
                onTap: () {
                Navigator.of(context).pop();
                _onTapDeleteReply(reply);
              },
              )),
              Visibility(visible: _isReportAbuseVisible, child: RibbonButton(
                leftIconKey: "feedback",
                label: Localization().getStringEx("panel.group.detail.post.button.report.students_dean.labe", "Report to Dean of Students"),
                onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToDeanOfStudents: true), post: reply),
              )),
              Visibility(visible: _isReportAbuseVisible, child: RibbonButton(
                leftIconKey: "feedback",
                label: Localization().getStringEx("panel.group.detail.post.button.report.group_admins.labe", "Report to Group Administrator(s)"),
                onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToGroupAdmins: true), post: reply),
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
            'Are you sure that you want to delete this reply?')),
        actions: <Widget>[
          TextButton(
              child:
                  Text(Localization().getStringEx('dialog.yes.title', 'Yes')),
              onPressed: () {
                Analytics().logAlert(text: 'Are you sure that you want to delete this reply?', selection: 'Yes');
                Navigator.of(context).pop();
                _deleteReply(reply);
              }),
          TextButton(
              child: Text(Localization().getStringEx('dialog.no.title', 'No')),
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
    setStateIfMounted(() {
      _selectedReplyId = reply?.id;
    });
    _clearBodyControllerContent();
    _scrollToPostEdit();
  }

  void _onTapReportAbuse({required GroupPostReportAbuseOptions options, GroupPost? post}) {
    String? analyticsTarget;
    if (options.reportToDeanOfStudents && !options.reportToGroupAdmins) {
      analyticsTarget = Localization().getStringEx('panel.group.detail.post.report_abuse.students_dean.description.text', 'Report violation of Student Code to Dean of Students');
    }
    else if (!options.reportToDeanOfStudents && options.reportToGroupAdmins) {
      analyticsTarget = Localization().getStringEx('panel.group.detail.post.report_abuse.group_admins.description.text', 'Report obscene, threatening, or harassing content to Group Administrators');
    }
    else if (options.reportToDeanOfStudents && options.reportToGroupAdmins) {
      analyticsTarget = Localization().getStringEx('panel.group.detail.post.report_abuse.both.description.text', 'Report violation of Student Code to Dean of Students and obscene, threatening, or harassing content to Group Administrators');
    }
    Analytics().logSelect(target: analyticsTarget);

    Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => GroupPostReportAbuse(options: options, groupId: widget.group?.id, postId: (post ?? widget.post)?.id)));
  }

  void _onTapEditMainPost(){
    _mainPostUpdateData = PostDataModel(body:_post?.body, imageUrl: _post?.imageUrl, members: GroupMembersSelectionWidget.constructUpdatedMembersList(selection:_post?.members, upToDateMembers: _allMembersAllowedToPost));
    setStateIfMounted(() { });
  }

  void _onTapUpdateMainPost(){
    String? body = _mainPostUpdateData?.body;
    String? imageUrl = _mainPostUpdateData?.imageUrl ?? _post?.imageUrl;
    List<Member>? toMembers = _mainPostUpdateData?.members;
    if (StringUtils.isEmpty(body)) {
      String? validationMsg = Localization().getStringEx('panel.group.detail.post.create.validation.body.msg', "Post message required");
      AppAlert.showDialogResult(context, validationMsg);
      return;
    }
    String htmlModifiedBody = HtmlUtils.replaceNewLineSymbols(body);

    _setLoading(true);
    GroupPost postToUpdate = GroupPost(id: _post?.id, subject: _post?.subject, body: htmlModifiedBody, imageUrl: imageUrl, members: toMembers, private: true);
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
    UrlUtils.launchExternal(url);
  }

  void _reloadPost() {
    //TODO: Can we optimize this to only load data for the relevant updated post(s)?
    _setLoading(true);
    Groups().loadGroupPosts(widget.group?.id).then((posts) {
      if (CollectionUtils.isNotEmpty(posts)) {
        try {
          // GroupPost? post = (posts as List<GroupPost?>).firstWhere((post) => (post?.id == _post?.id), orElse: ()=> null); //Remove to fix reload Error: type '() => Null' is not a subtype of type '(() => GroupPost)?' of 'orElse'
          List<GroupPost?> nullablePosts = List.of(posts!);
          _post = nullablePosts.firstWhere((post) => (post?.id == _post?.id), orElse: ()=> null);
        } catch (e) {
          print(e);
        }
        _sortReplies(_post?.replies);
        GroupPost? updatedReply = deepFindPost(posts, _focusedReply?.id);
        if(updatedReply!=null){
          setStateIfMounted(() {
            _focusedReply = updatedReply;
            _sortReplies(_focusedReply?.replies);
          });
        } else {
          setStateIfMounted(() {}); // Refresh MainPost
        }
      } else {
        _post = null;
      }
      _setLoading(false);
    });
  }

  void _setLoading(bool loading) {
    setStateIfMounted(() {
      _loading = loading;
    });
  }

  void _onTapCancel() {
    Analytics().logSelect(target: 'Cancel');
    if (_editingReply != null) {
      setStateIfMounted(() {
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
          ? Localization().getStringEx('panel.group.detail.post.create.validation.body.msg', "Post message required")
          : Localization().getStringEx('panel.group.detail.post.create.reply.validation.body.msg', "Reply message required");
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

    setStateIfMounted(() {
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
            post2.dateCreatedUtc!.compareTo(post1.dateCreatedUtc!));
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
    String? currentMemberEmail = widget.group?.currentMember?.userId;
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
    return widget.group?.currentUserHasPermissionToSendReply == true;
  }

  bool get _isReportAbuseVisible {
    return widget.group?.currentUserIsMemberOrAdmin ?? false;
  }

  bool get _isEditMainPost {
    return _mainPostUpdateData!=null;
  }

  // Notifications Listener
  @override
  void onNotification(String name, param) {
    if (name == Groups.notifyGroupPostsUpdated) {
      _reloadPost();
    } else if (name == Groups.notifyGroupPostReactionsUpdated) {
      setStateIfMounted(() { });
    }
  }
}

