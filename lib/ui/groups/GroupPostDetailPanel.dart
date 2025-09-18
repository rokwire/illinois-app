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
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/groups/GroupPostReportAbuse.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ext/Social.dart';
import 'package:rokwire_plugin/service/Log.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';

class GroupPostDetailPanel extends StatefulWidget with AnalyticsInfo {
  final Post? post;
  final String? visibleCommentId;
  final Comment? focusedReply; //TBD remove as we do not support nested replies anymore. We can simplify this panel logic
  final Group group;
  final bool hidePostOptions;
  final AnalyticsFeature? _analyticsFeature;

  GroupPostDetailPanel({required this.group, this.post, this.focusedReply, this.hidePostOptions = false, AnalyticsFeature? analyticsFeature, this.visibleCommentId}) :
    _analyticsFeature = analyticsFeature;

  @override
  _GroupPostDetailPanelState createState() => _GroupPostDetailPanelState();

  @override
  AnalyticsFeature? get analyticsFeature => _analyticsFeature ?? _defaultAnalyticsFeature;

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group.analyticsAttributes;

  AnalyticsFeature? get _defaultAnalyticsFeature => (group.researchProject == true) ? AnalyticsFeature.ResearchProject : AnalyticsFeature.Groups;
}

class _GroupPostDetailPanelState extends State<GroupPostDetailPanel> with NotificationsListener {
  static final double _outerPadding = 16;
  //Main Post - Edit/Show
  Post? _post; //Main post {Data Presentation}
  List<Comment>? _replies; //Main post comments
  PostUpdateData? _mainPostUpdateData;//Main Post Edit
  List<Member>? _allMembersAllowedToPost;
  //Reply - Edit/Create/Show
  Comment? _focusedReply; //Focused on Reply {Replies Thread Presentation} // User when Refresh post thread
  String? _selectedReplyId; // Thread Id target for New Reply {Data Create}
  Comment? _editingReply; //Edit Mode for Reply {Data Edit}
  PostDataModel? _replyEditData = PostDataModel(); //used for Reply Create / Edit; Empty data for new Reply

  String? _ensureVisibleCommentId; //If we have comment that needs to be scrolled to when content is loaded

  bool _loading = false;

  //Scroll and focus utils
  ScrollController _scrollController = ScrollController();
  final GlobalKey _sliverHeaderKey = GlobalKey();
  final GlobalKey _postEditKey = GlobalKey();
  final GlobalKey _scrollContainerKey = GlobalKey();
  GlobalKey? _visibleCommentKey;
  double? _sliverHeaderHeight;
  //Refresh
  GlobalKey _postInputKey = GlobalKey();
  GlobalKey _postImageHolderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Social.notifyPostsUpdated]);
    _post = widget.post ?? Post(); //If no post then prepare data for post creation
    _loadMembersAllowedToPost();
    _loadComments();
    _focusedReply = widget.focusedReply;
    _ensureVisibleCommentId = widget.visibleCommentId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evalSliverHeaderHeight();
      if (_focusedReply != null) {
        _scrollToPostEdit();
      }
      else if(_visibleCommentKey != null){
        _scrollToEnsuredVisibleComment();
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
            title: Text(_panelTitle ?? "",
                style: Styles().textStyles.getTextStyle('widget.heading.regular.extra_fat')),
            centerTitle: false),
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: uiuc.TabBar(),
        body: _buildContent());
  }

  Widget _buildContent() {
    List<String>? updatedMemberIds = _isEditMainPost ? MemberExt.extractUserIds(_mainPostUpdateData?.members) : _post?.getMemberAccountIds(
        groupId: _groupId);
    if (CollectionUtils.isNotEmpty(updatedMemberIds) && updatedMemberIds!.contains(Auth2().accountId)) {
      updatedMemberIds.remove(Auth2().accountId);
    }
    return Stack(children: [
      Stack(alignment: Alignment.topCenter, children: [
        SingleChildScrollView(
            key: _scrollContainerKey,
            controller: _scrollController,
            child: Column(children: [
              Container(height: _sliverHeaderHeight ?? 0),
              _isEditMainPost /*|| StringUtils.isNotEmpty(_post?.imageUrl)*/
                  ? ImageChooserWidget(
                      key: _postImageHolderKey,
                      buttonVisible: _isEditMainPost,
                      imageUrl: _isEditMainPost ? _mainPostUpdateData?.imageUrl : _post?.imageUrl,
                      onImageChanged: (url) => _mainPostUpdateData?.imageUrl = url)
                  : Container(),
              Visibility(visible: _post?.isMessage == true,
                  child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6), child:
                    GroupMembersSelectionWidget(
                      selectedMembers: GroupMembersSelectionWidget.constructUpdatedMembersList(
                          selectedAccountIds: updatedMemberIds,
                          upToDateMembers: _allMembersAllowedToPost),
                      allMembers: _allMembersAllowedToPost,
                      enabled: _isEditMainPost,
                      groupId: _groupId,
                      groupPrivacy: widget.group.privacy,
                      onSelectionChanged: (members) {
                        setStateIfMounted(() {
                          _mainPostUpdateData?.members = members;
                        });
                      }))),
              Visibility(visible: widget.post?.isScheduled == true, child:
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6), child:
                  GroupScheduleTimeWidget(
                    timeZone: null,//TBD pass timezone
                    scheduleTime: widget.post?.dateActivatedUtc,
                    enabled: false, //_isEditMainPost, Disable editing since the BB do not support editing of the create notification
                    onDateChanged: (DateTime? dateTimeUtc){
                      setStateIfMounted(() {
                        Log.d(groupUtcDateTimeToString(dateTimeUtc)??"");
                        _mainPostUpdateData?.dateScheduled = dateTimeUtc;
                      });
                    },
                  )
                )
              ),
              _buildPostContent(),
              _buildRepliesSection(),
              _buildPostInputSection(),
            ])),
          Container(key: _sliverHeaderKey, color: Styles().colors.background, padding: EdgeInsets.only(left: _outerPadding, right: 8, bottom: 3), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Expanded( child:
                    // Container(),
                    Visibility(visible: _post?.isPost == true,
                      child: Semantics(sortKey: OrdinalSortKey(1), container: true, child:
                        Text(StringUtils.ensureNotEmpty(_post?.subject), maxLines: 5, overflow: TextOverflow.ellipsis,
                            style: Styles().textStyles.getTextStyle("widget.detail.extra_large.fat"),
                        )
                      )
                    )
                  ),
                  // Visibility(
                  //   visible: Config().showGroupPostReactions && (widget.group.currentUserHasPermissionToSendReactions == true),
                  //   child: Padding(
                  //     padding: EdgeInsets.only(left: 8, top: 22, bottom: 10, right: 8),
                  //     child: GroupReaction(
                  //       groupId: _groupId,
                  //       entityId: _post?.id,
                  //       reactionSource: SocialEntityType.post
                  //     ),
                  //   ),
                  // ),

                  Visibility(visible: _isEditPostVisible && !widget.hidePostOptions, child:
                    Semantics(container: true, sortKey: OrdinalSortKey(5), child:
                      Container(child:
                        Semantics(label: Localization().getStringEx('panel.group.detail.post.reply.edit.label', "Edit"), button: true, child:
                          GestureDetector(onTap: _onTapEditMainPost, child:
                            Padding(padding: EdgeInsets.only(left: 8, top: 22, bottom: 10, right: 8), child:
                              Styles().images.getImage('edit', excludeFromSemantics: true))))))),

                  Visibility(visible: _isDeletePostVisible && !widget.hidePostOptions, child:
                    Semantics(container: true, sortKey: OrdinalSortKey(5), child:
                      Container(child:
                        Semantics(label: Localization().getStringEx('panel.group.detail.post.reply.delete.label', "Delete"), button: true, child:
                          GestureDetector(onTap: _onTapDeletePost, child:
                              Padding(padding: EdgeInsets.only(left: 8, top: 22, bottom: 10, right: 8), child:
                                Styles().images.getImage('trash', excludeFromSemantics: true))))))),

                  Visibility(visible: _isReportAbuseVisible && !widget.hidePostOptions, child:
                    Semantics(label: Localization().getStringEx('panel.group.detail.post.button.report.label', "Report"), button: true, child:
                      GestureDetector( onTap: () => _onTapReportAbusePostOptions(), child:
                          Padding(padding: EdgeInsets.only(left: 8, top: 22, bottom: 10, right: 8), child:
                            Styles().images.getImage('report', excludeFromSemantics: true))))),
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
                      Visibility(visible: !_isEditMainPost, child:
                              // Semantics(
                          //     container: true,
                          //     child:
                          //     HtmlWidget(
                          //         StringUtils.ensureNotEmpty(_post?.body),
                          //         onTapUrl : (url) {_onTapPostLink(url); return true;},
                          //         textStyle:  Styles().textStyles.getTextStyle("widget.detail.large"),
                          //     )
                            GroupPostCard(
                                post: _post,
                                group: widget.group,
                                isClickable: false,
                                displayMode: GroupPostCardDisplayMode.page,
                                isAdmin: _post?.creator?.findAsMember(groupMembers: _allMembersAllowedToPost)?.isAdmin)
                          ),
                      Visibility(
                          visible: _isEditMainPost,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    padding: EdgeInsets.only(top: 8, bottom: _outerPadding),
                                    color: Styles().colors.surface,
                                    child: PostInputField(
                                      onBodyChanged: (txt) => _mainPostUpdateData?.body = txt,
                                      text:  _mainPostUpdateData?.body ?? '',
                                      minLines: 1,
                                      maxLines: null,
                                      autofocus: true,
                                      style: Styles().textStyles.getTextStyle("widget.input_field.text.regular"),
                                      boxDecoration: BoxDecoration(color: Styles().colors.surface),
                                      inputDecoration: InputDecoration(
                                          hintText: Localization().getStringEx("panel.group.detail.post.edit.hint", "Edit the post"),
                                          border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Styles().colors.mediumGray,
                                                  width: 0.0))),
                                    )
                                ),
                                Visibility(visible: _isPost && _canPinPost,
                                    child: Container(
                                      padding: EdgeInsets.only(top: 8, bottom: _outerPadding),
                                      child: EnabledToggleButton(
                                          label: "Pin post to top of all posts (Only one pinned post per group is allowed. Pinning this post will automatically unpin any past admin posts.)",
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                                          toggled: _mainPostUpdateData?.pinned == true,
                                          textStyle: Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled"),
                                          enabled: true,
                                          onTap: () {
                                            if(mounted){
                                              setState(() {
                                                _mainPostUpdateData?.pinned  = !(_mainPostUpdateData?.pinned ?? false);
                                              });
                                            }
                                          }
                                      ),
                                    )
                                ),
                                Row(children: [
                                  Flexible(
                                      flex: 1,
                                      child: RoundedButton(
                                          label: Localization().getStringEx('panel.group.detail.post.update.button.update.title', 'Update'),
                                          textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                                          borderColor: Styles().colors.fillColorSecondary,
                                          backgroundColor: Styles().colors.white,
                                          onTap: _onTapUpdateMainPost)),
                                ]),

                                // Semantics(
                                //     sortKey: OrdinalSortKey(2),
                                //     container: true,
                                //     child: Padding(
                                //         padding: EdgeInsets.only(top: 4, right: _outerPadding),
                                //         child: Text(StringUtils.ensureNotEmpty(_post?.creatorName),
                                //             style: Styles().textStyles.getTextStyle("widget.detail.large.thin")))),
                                // Semantics(
                                //     sortKey: OrdinalSortKey(3),
                                //     container: true,
                                //     child: Padding(
                                //         padding: EdgeInsets.only(top: 3, right: _outerPadding),
                                //         child: Text(
                                //           StringUtils.ensureNotEmpty(
                                //               _post?.displayDateTime),
                                //           semanticsLabel:  sprintf(Localization().getStringEx("panel.group.detail.post.updated.ago.format", "Updated %s ago"),[widget.post?.displayDateTime ?? ""]),
                                //           style: Styles().textStyles.getTextStyle("widget.detail.medium"),))),

                              ])),
                      Container(height: 6,),
                    ],
                  )),

            ]));
  }

  void _loadMembersAllowedToPost() {
    _setLoading(true);
    Groups().loadMembersAllowedToPost(groupId: _groupId).then((members) {
      _allMembersAllowedToPost = members;
      _setLoading(false);
    });
  }

  void _loadComments() {
    String? postId = _post?.id;
    if (StringUtils.isNotEmpty(postId)) {
      _setLoading(true);
      Social().loadComments(postId: postId!).then((comments) {
        _replies = comments;
        _sortReplies(_replies);
        _setLoading(false);
        Future.delayed(Duration(milliseconds: 20), () =>
         _scrollToEnsuredVisibleComment());
      });
    }
  }

  void _refreshPostData() {
    if (_post?.id != null) {
      _setLoading(true);
      Social().loadSinglePost(groupId: _groupId, postId: _post!.id!).then((updatedPost) {
        _setLoading(false);
        if (updatedPost != null) {
          _loadComments();
          setStateIfMounted(() {
            _post = updatedPost;
          });
        }
      });
    }
  }

  Widget _buildRepliesSection(){
    List<Comment>? replies;
    if (_focusedReply != null) {
      replies = [_focusedReply!];
    }
    else if (_editingReply != null) {
      replies = [_editingReply!];
    }
    else {
      replies = _replies;
    }

    return Padding(
        padding: EdgeInsets.only(
            bottom: _outerPadding),
        child: _buildRepliesWidget(replies: replies, focusedReplyId: _focusedReply?.id, showRepliesCount: _focusedReply == null));
  }

  Widget _buildPostInputSection() {
    return Visibility(
        key: _postEditKey,
        visible: widget.group.currentUserHasPermissionToSendReply == true,
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
                        textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                        borderColor: Styles().colors.fillColorSecondary,
                        backgroundColor: Styles().colors.white,
                        onTap: _onTapSendReply)),
                Container(width: 20),
                Flexible(
                    flex: 1,
                    child: RoundedButton(
                        label: Localization().getStringEx(
                            'panel.group.detail.post.create.button.cancel.title',
                            'Cancel'),
                        textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                        borderColor: Styles().colors.textSurface,
                        backgroundColor: Styles().colors.white,
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
          onImageChanged: (String? imageUrl) => _replyEditData?.imageUrl = imageUrl,
          imageSemanticsLabel: Localization().getStringEx('panel.group.detail.post.reply.reply.label', "Reply"),
        )
     );
  }

  Widget _buildReplyTextField(){
    return PostInputField(
      key: _postInputKey,
      title:  Localization().getStringEx('panel.group.detail.post.reply.reply.label.capitalized', "REPLY"),// tbd localize
      text: _replyEditData?.body,
      onBodyChanged: (text) => _replyEditData?.body = text,
    );
  }

  Widget _buildRepliesWidget(
      {List<Comment>? replies,
      double leftPaddingOffset = 0,
      bool nestedReply = false,
      bool showRepliesCount = true,
      String? focusedReplyId,
      }) {
    if (CollectionUtils.isEmpty(replies)) {
      return Container();
    }
    List<Widget> replyWidgetList = [];

    if(_post?.isPost == true) {
      if (StringUtils.isEmpty(focusedReplyId) &&
          CollectionUtils.isNotEmpty(replies)) {
        replyWidgetList.add(_buildRepliesHeader());
        replyWidgetList.add(Container(height: 8,));
      }
    }

    for (int i = 0; i < replies!.length; i++) {
      if (i > 0 || nestedReply) {
        replyWidgetList.add(Container(height: 10));
      }
      Comment? reply = replies[i];
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
                key: _ensureVisibleCommentId != null && _ensureVisibleCommentId == reply.id ? _visibleCommentKey = GlobalKey() : GlobalKey(),
                onCardTap: () => {}, // Do not allow nested comments
                reply: reply,
                post: widget.post,
                group: widget.group,
                creator: reply.creator?.findAsMember(groupMembers: _allMembersAllowedToPost),
                iconPath: optionsIconPath,
                semanticsLabel: "options",
                showRepliesCount: showRepliesCount,
                analyticsFeature: widget.analyticsFeature,
                onIconTap: optionsFunctionTap
            ))));
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
                color: Styles().colors.fillColorPrimary,
                child: Text("Replies",
                    style: Styles().textStyles.getTextStyle("widget.heading.medium"),
                ),
              )
        )
      ],
    ));
  }

  void _onTapDeletePost() {
    Analytics().logSelect(target: 'Delete Post');
    String deleteMsg = (_post?.isLinkedToMoreThanOneGroup ?? false)
        ? Localization().getStringEx('panel.group.detail.post.delete.many_groups.confirm.msg',
            'This post is visible in more than one group. Are you sure that you want to delete it?')
        : Localization().getStringEx('panel.group.detail.post.delete.confirm.msg', 'Are you sure that you want to delete this post?');
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: Text(deleteMsg),
        actions: <Widget>[
          PointerInterceptor(child: TextButton(
              child:
              Text(Localization().getStringEx('dialog.yes.title', 'Yes')),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost();
              })),
          PointerInterceptor(child: TextButton(
              child: Text(Localization().getStringEx('dialog.no.title', 'No')),
              onPressed: () => Navigator.of(context).pop()))
        ]);
  }

  void _deletePost() {
    _setLoading(true);
    Social().deletePost(post: _post!).then((succeeded) {
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
      backgroundColor: Styles().colors.white,
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
                leftIconKey: "report",
                label: Localization().getStringEx("panel.group.detail.post.button.report.students_dean.labe", "Report to Dean of Students"),
                onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToDeanOfStudents : true), entityId: widget.post!.id!, entityType: SocialEntityType.post),
              )),
              Visibility(visible: _isReportAbuseVisible, child: RibbonButton(
                leftIconKey: "report",
                label: Localization().getStringEx("panel.group.detail.post.button.report.group_admins.labe", "Report to Group Administrator(s)"),
                onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToGroupAdmins: true), entityId: widget.post!.id!, entityType: SocialEntityType.post),
              )),
            ],
          ),
        );
      });
  }

  void _onTapReplyOptions(Comment reply) {
    Analytics().logSelect(target: 'Reply Options');
    showModalBottomSheet(
      context: context,
      backgroundColor: Styles().colors.white,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)),),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Do not reply to reply
              Visibility(visible: false, child: RibbonButton(
                leftIconKey: 'reply',
                label: Localization().getStringEx("panel.group.detail.post.reply.reply.label", "Reply"),
                onTap: () {
                  Navigator.of(context).pop();
                  _onTapPostReply(reply: reply);
                },
              )),
              Visibility(visible: _isEditVisible(reply.creatorId), child: RibbonButton(
                leftIconKey: "edit",
                label: Localization().getStringEx("panel.group.detail.post.reply.edit.label", "Edit"),
                onTap: () {
                  Navigator.of(context).pop();
                  _onTapEditReply(reply: reply);
                },
              )),
              Visibility(visible: _isDeleteReplyVisible(reply.creatorId), child: RibbonButton(
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
                onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToDeanOfStudents: true), entityId: reply.id!, entityType: SocialEntityType.comment),
              )),
              Visibility(visible: _isReportAbuseVisible, child: RibbonButton(
                leftIconKey: "feedback",
                label: Localization().getStringEx("panel.group.detail.post.button.report.group_admins.labe", "Report to Group Administrator(s)"),
                onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToGroupAdmins: true), entityId: reply.id!, entityType: SocialEntityType.comment),
              )),
            ],
          ),
        );
      });
  }

  void _onTapDeleteReply(Comment? reply) {
    Analytics().logSelect(target: 'Delete Reply');
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: Text(Localization().getStringEx(
            'panel.group.detail.post.reply.delete.confirm.msg',
            'Are you sure that you want to delete this reply?')),
        actions: <Widget>[
          PointerInterceptor(child: TextButton(
              child:
              Text(Localization().getStringEx('dialog.yes.title', 'Yes')),
              onPressed: () {
                Analytics().logAlert(text: 'Are you sure that you want to delete this reply?', selection: 'Yes');
                Navigator.of(context).pop();
                _deleteReply(reply);
              })),
          PointerInterceptor(child: TextButton(
              child: Text(Localization().getStringEx('dialog.no.title', 'No')),
              onPressed: () {
                Analytics().logAlert(text: 'Are you sure that you want to delete this reply?', selection: 'No');
                Navigator.of(context).pop();
              }))
        ]);
  }

  void _deleteReply(Comment? reply) {
    _setLoading(true);
    _clearSelectedReplyId();
    Social().deleteComment(comment: reply!).then((succeeded) {
      _setLoading(false);
      if (succeeded) {
        _loadComments();
      } else {
        AppAlert.showDialogResult(
            context, Localization().getStringEx('panel.group.detail.post.reply.delete.failed.msg', 'Failed to delete reply.'));
      }
    });
  }

  void _onTapPostReply({Comment? reply}) {
    Analytics().logSelect(target: 'Post Reply');
    //Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostDetailPanel(post: widget.post, group: widget.group, focusedReply: reply, hidePostOptions: true,)));
    setStateIfMounted(() {
      _selectedReplyId = reply?.id;
    });
    _clearBodyControllerContent();
    _scrollToPostEdit();
  }

  void _onTapReportAbuse({required GroupPostReportAbuseOptions options, required String entityId, required SocialEntityType entityType}) {
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

    Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => GroupPostReportAbusePanel(options: options, groupId: _groupId, socialEntityId: entityId, socialEntityType: entityType)));
  }

  void _onTapEditMainPost() {
    List<String>? selectedAccountIds = _post?.getMemberAccountIds(groupId: _groupId);
    if (CollectionUtils.isNotEmpty(selectedAccountIds) && selectedAccountIds!.contains(Auth2().accountId)) {
      selectedAccountIds.remove(Auth2().accountId);
    }
    _mainPostUpdateData = PostUpdateData.fromPost(_post,
        members: GroupMembersSelectionWidget.constructUpdatedMembersList(
          selectedAccountIds: selectedAccountIds,
          upToDateMembers: _allMembersAllowedToPost),
    );
    setStateIfMounted(() {});
  }

  void _onTapUpdateMainPost() {
    String? body = _mainPostUpdateData?.body;
    String? imageUrl = _mainPostUpdateData?.imageUrl ?? _post?.imageUrl;
    List<Member>? toMembers = _mainPostUpdateData?.members;
    if (StringUtils.isEmpty(body)) {
      String? validationMsg = Localization().getStringEx('panel.group.detail.post.create.validation.body.msg', 'Post message required');
      AppAlert.showDialogResult(context, validationMsg);
      return;
    }

    String htmlModifiedBody = HtmlUtils.replaceNewLineSymbols(body);
    _setLoading(true);
    _post!.body = htmlModifiedBody;
    _post!.imageUrl = imageUrl;
    _post!.dateActivatedUtc = _mainPostUpdateData?.dateScheduled?.toUtc();
    List<String>? memberAccountIds = MemberExt.extractUserIds(toMembers);
    if (CollectionUtils.isNotEmpty(memberAccountIds) && !memberAccountIds!.contains(Auth2().accountId)) {
      memberAccountIds.add(Auth2().accountId!);
    }
    _post!.setMemberAccountIds(groupId: _groupId, accountIds: memberAccountIds);
    Social().updatePost(post: _post!).then((succeeded) {
      if(_mainPostUpdateData?.pinned != _post?.pinned){
        Social().pinPost(postId: _post?.id ?? "", pinned: _mainPostUpdateData?.pinned == true).whenComplete((){
          _mainPostUpdateData = null;
          _setLoading(false);
        });
      } else {
        _mainPostUpdateData = null;
        _setLoading(false);
      }
    });
  }

  void _onTapEditReply({Comment? reply}) {
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

  // void _onTapPostLink(String? url) {
  //   Analytics().logSelect(target: 'link');
  //   UrlUtils.launchExternal(url);
  // }

  void _setLoading(bool loading) {
    setStateIfMounted(() {
      _loading = loading;
    });
  }

  void _onTapCancel() {
    Analytics().logSelect(target: 'Cancel');
    if (_editingReply != null) {
      setStateIfMounted(() {
        _clearEditingReply();
        _clearImageSelection();
        _clearBodyControllerContent();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onTapSendReply() {
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

    _setLoading(true);
    String htmlModifiedBody = HtmlUtils.replaceNewLineSymbols(body);
    if (_editingReply != null) {
      imageUrl = StringUtils.isNotEmpty(_replyEditData?.imageUrl) ? _replyEditData?.imageUrl : _editingReply?.imageUrl;
      _editingReply!.body = htmlModifiedBody;
      _editingReply!.imageUrl = imageUrl;
      Social().updateComment(comment: _editingReply!).then((succeeded) {
        _setLoading(false);
        if (succeeded) {
          _onSendFinished(succeeded);
        } else {
          AppAlert.showDialogResult(
              context, Localization().getStringEx('panel.group.detail.post.update.reply.failed.msg', 'Failed to edit reply.'));
        }
      });
    } else {
      imageUrl = _replyEditData?.imageUrl ?? imageUrl; // if _preparedReplyData then this is new Reply if we already have image then this is create new post for group
      String? parentId;
      if (_selectedReplyId != null) {
        parentId = _selectedReplyId;
      } else if (_focusedReply != null) {
        parentId = _focusedReply!.id;
      } else if (_post != null) {
        parentId = _post!.id;
      }
      Comment comment = Comment(parentId: parentId, body: htmlModifiedBody, imageUrl: imageUrl);
      Social().createComment(comment: comment).then((succeeded) {
        _onSendFinished(succeeded);
      });
    }
  }

  void _onSendFinished(bool succeeded) {
    _setLoading(false);
    if (succeeded) {
      setStateIfMounted(() {
        _clearEditingReply();
        _clearSelectedReplyId();
        _clearBodyControllerContent();
        _clearImageSelection();
      });
      // Navigator.of(context).pop(true);
      _loadComments();
    } else {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.detail.post.create.reply.failed.msg', 'Failed to create new reply.'));
    }
  }

  void _clearSelectedReplyId() {
    _selectedReplyId = null;
  }

  void _clearBodyControllerContent() {
    _replyEditData?.body = '';
  }

  void _clearImageSelection(){
    _replyEditData?.imageUrl = null;
  }

  void _clearEditingReply() {
    _editingReply = null;
  }

  //Scroll
  void _evalSliverHeaderHeight() {
    double? sliverHeaderHeight;
    try {
      final RenderObject? renderBox = _sliverHeaderKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize) {
        sliverHeaderHeight = renderBox.size.height;
      }
    } on Exception catch (e) {
      print(e.toString());
    }

    setStateIfMounted(() {
      _sliverHeaderHeight = sliverHeaderHeight;
    });
  }

  void _scrollToEnsuredVisibleComment(){
    if(_ensureVisibleCommentId != null && _visibleCommentKey != null && mounted){
      Scrollable.ensureVisible(
          _visibleCommentKey!.currentContext!, duration: Duration(milliseconds: 300)).then(
              (_) => _ensureVisibleCommentId = null); // Do it only once then forget about this comments visibility
    }
  }

  void _scrollToPostEdit() {
    BuildContext? postEditContext = _postEditKey.currentContext;
    //Scrollable.ensureVisible(postEditContext, duration: Duration(milliseconds: 10));
    RenderObject? renderObject = postEditContext?.findRenderObject();
    RenderAbstractViewport? viewport = (renderObject != null) ? RenderAbstractViewport.of(renderObject) : null;
    double? postEditTop = (viewport != null) ? viewport.getOffsetToReveal(renderObject!, 0.0).offset : null;

    BuildContext? scrollContainerContext = _scrollContainerKey.currentContext;
    RenderObject? scrollContainerRenderBox = scrollContainerContext?.findRenderObject();
    double? scrollContainerHeight = ((scrollContainerRenderBox is RenderBox) && scrollContainerRenderBox.hasSize) ? scrollContainerRenderBox.size.height : null;

    if ((scrollContainerHeight != null) && (postEditTop != null)) {
      double offset = postEditTop - scrollContainerHeight + 120;
      offset = max(offset, _scrollController.position.minScrollExtent);
      offset = min(offset, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(offset, duration: Duration(milliseconds: 1), curve: Curves.easeIn);
    }

  }

  //Utils
  void _sortReplies(List<Comment>? replies) {
    if (CollectionUtils.isNotEmpty(replies)) {
      try {
        replies!.sort((c1, c2) => c1.dateCreatedUtc!.compareTo(c2.dateCreatedUtc!));
      } catch (e) {
        Log.e('Failed to sort comments. Exception: ${e.toString()}');
      }
    }
  }

  //Getters
  bool _isEditVisible(String? creatorId) => _isCurrentUserCreator(creatorId);

  bool _isDeleteVisible(String? creatorId) {
    if (widget.group.currentUserIsAdmin) {
      return true;
    } else if (widget.group.currentUserIsMember) {
      return _isCurrentUserCreator(creatorId);
    } else {
      return false;
    }
  }

  bool _isDeleteReplyVisible(String? creatorId) => _isDeleteVisible(creatorId);

  bool _isCurrentUserCreator(String? creatorId) {
    String? currentMemberId = widget.group.currentMember?.userId;
    return StringUtils.isNotEmpty(currentMemberId) && StringUtils.isNotEmpty(creatorId) && (currentMemberId == creatorId);
  }

  String? get _panelTitle => _post?.isMessage == true ?
      Localization().getStringEx('panel.group.detail.post.header.title.message', 'Message'):
      Localization().getStringEx('panel.group.detail.post.header.title', 'Post');

  bool get _isEditPostVisible => _isEditVisible(_post?.creatorId);

  bool get _isDeletePostVisible => _isDeleteVisible(_post?.creatorId);

  bool get _isReplyVisible => (widget.group.currentUserHasPermissionToSendReply == true);

  bool get _isReportAbuseVisible => widget.group.currentUserIsMemberOrAdmin;

  bool get _isPost => _post?.type ==  PostType.post;

  bool get _canPinPost => _isAdmin;

  bool get _isAdmin => widget.group.currentUserIsAdmin;

  bool get _isEditMainPost => _mainPostUpdateData != null;

  String get _groupId => widget.group.id!;

  // Notifications Listener
  @override
  void onNotification(String name, param) {
    if (name == Social.notifyPostsUpdated) {
      _refreshPostData();
    }
  }
}

class PostUpdateData extends PostDataModel {
  bool? pinned;

  PostUpdateData({String? body, String? subject, String? imageUrl, List<Member>? members, DateTime? dateScheduled, this.pinned}) : 
        super(body: body, subject: subject, imageUrl: imageUrl, members: members, dateScheduled: dateScheduled);
  
  factory PostUpdateData.fromPost(Post? post, {List<Member>? members}) =>
      PostUpdateData(
          body: post?.body,
          imageUrl: post?.imageUrl,
          dateScheduled: post?.dateActivatedLocal,
          pinned: post?.pinned,
          members: members
      );
}

