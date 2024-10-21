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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:neom/model/Analytics.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/ui/groups/GroupPostCreatePanel.dart';
import 'package:neom/ui/groups/GroupPostEditPanel.dart';
import 'package:neom/ui/groups/GroupPostReportAbuse.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:neom/ext/Group.dart';
import 'package:neom/service/Analytics.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:neom/ui/groups/GroupWidgets.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';

class GroupPostDetailPanel extends StatefulWidget with AnalyticsInfo {
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
  AnalyticsFeature? get analyticsFeature => (group?.researchProject == true) ? AnalyticsFeature.ResearchProject : AnalyticsFeature.Groups;

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
  GlobalKey _repliesKey = GlobalKey();
  double? _repliesHeight;

  bool _loading = false;

  //Scroll and focus utils
  ScrollController _scrollController = ScrollController();
  final GlobalKey _sliverHeaderKey = GlobalKey();
  final GlobalKey _scrollContainerKey = GlobalKey();
  double? _sliverHeaderHeight;
  //Refresh
  GlobalKey _postImageHolderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Groups.notifyGroupPostsUpdated, Groups.notifyGroupPostReactionsUpdated]);
    _loadMembersAllowedToPost();
    _post = widget.post ?? GroupPost(); //If no post then prepare data for post creation
    _sortReplies(_post?.replies);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evalSliverHeaderHeight();
      _evalRepliesHeight();
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
              style:  Styles().textStyles.getTextStyle("widget.heading.regular.extra_fat.light"),),
            titleSpacing: 0,
            centerTitle: false),
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: uiuc.TabBar(),
        body: _buildContent(),
      );
  }

  Widget _buildContent(){
    return Stack(children: [
      Stack(alignment: Alignment.topCenter, children: [
        SingleChildScrollView(key: _scrollContainerKey, controller: _scrollController, child:
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(children: [
              Container(height: _sliverHeaderHeight ?? 0,),
              _isEditMainPost || StringUtils.isNotEmpty(_post?.imageUrl)
                ? ImageChooserWidget(key: _postImageHolderKey, buttonVisible: _isEditMainPost,
                  imageUrl:_isEditMainPost ?  _mainPostUpdateData?.imageUrl : _post?.imageUrl,
                  onImageChanged: (url) => _mainPostUpdateData?.imageUrl = url,)
                : Container(),
              GroupPostCard(post: _post, group: widget.group, allMembersAllowedToPost: _allMembersAllowedToPost, showImage: false, allowTap: false),
              _buildRepliesSection(),
            ],),
          )),
          Container(key: _sliverHeaderKey, color: Styles().colors.background, padding: EdgeInsets.only(left: _outerPadding), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Spacer(),
                Visibility(
                  visible: Config().showGroupPostReactions && (widget.group?.currentUserHasPermissionToSendReactions == true),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: GroupPostReaction(
                      groupID: widget.group?.id,
                      post: _post,
                      reaction: thumbsUpReaction,
                      accountIDs: _post?.reactions[thumbsUpReaction],
                      selectedIconKey: 'thumbs-up',
                      deselectedIconKey: 'thumbs-up-gray',
                      textStyle: Styles().textStyles.getTextStyle("widget.card.detail.light.tiny.medium_fat")
                      // onTapEnabled: _canSendReaction,
                    ),
                  ),
                ),

                Visibility(visible: _isEditPostVisible && !widget.hidePostOptions, child:
                  Semantics(container: true, sortKey: OrdinalSortKey(5), child:
                    Container(child:
                      Semantics(label: Localization().getStringEx('panel.group.detail.post.reply.edit.label', "Edit"), button: true, child:
                        GestureDetector(onTap: _onTapEditMainPost, child:
                          Padding(padding: EdgeInsets.all(8.0), child:
                            Styles().images.getImage('edit', excludeFromSemantics: true))))))),

                Visibility(visible: _isDeletePostVisible && !widget.hidePostOptions, child:
                  Semantics(container: true, sortKey: OrdinalSortKey(5), child:
                    Container(child:
                      Semantics(label: Localization().getStringEx('panel.group.detail.post.reply.delete.label', "Delete"), button: true, child:
                        GestureDetector(onTap: _onTapDeletePost, child:
                            Padding(padding: EdgeInsets.all(8.0), child:
                              Styles().images.getImage('trash', excludeFromSemantics: true))))))),

                Visibility(visible: _isReportAbuseVisible && !widget.hidePostOptions, child:
                  Semantics(label: Localization().getStringEx('panel.group.detail.post.button.report.label', "Report"), button: true, child:
                    GestureDetector( onTap: () => _onTapReportAbusePostOptions(), child:
                        Padding(padding: EdgeInsets.all(8.0), child:
                          Styles().images.getImage('report', excludeFromSemantics: true))))),

                Visibility(visible: _isReplyVisible && !widget.hidePostOptions, child:
                  Semantics(label: Localization().getStringEx('panel.group.detail.post.reply.reply.label', "Reply"), button: true, child:
                    GestureDetector(onTap: _onTapHeaderReply, child:
                        Padding(padding: EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 16), child:
                          Styles().images.getImage('reply', excludeFromSemantics: true))))),

              ]),
            ])
          )
      ]),
      Visibility(
          visible: _loading,
          child: Center(child: CircularProgressIndicator())),
    ]);
  }

  void _loadMembersAllowedToPost() {
    _setLoading(true);
    Groups().loadMembersAllowedToPost(groupId: widget.group!.id).then((members) {
      _allMembersAllowedToPost = members;
      _setLoading(false);
    });
  }

  Widget _buildRepliesSection(){
    return Padding(
        padding: EdgeInsets.only(
            bottom: _outerPadding),
        child: _buildRepliesWidget(replies: _post?.replies));
  }

  Widget _buildRepliesWidget(
      {List<GroupPost>? replies,
      double leftPaddingOffset = 24.0,
      bool nestedReply = false,
      }) {
    List<GroupPost>? visibleReplies = _getVisibleReplies(replies);
    if (CollectionUtils.isEmpty(visibleReplies)) {
      return Container();
    }
    List<Widget> replyWidgetList = [];

    for (int i = 0; i < visibleReplies!.length; i++) {
      if (i > 0 || nestedReply) {
        replyWidgetList.add(Container(height: 10));
      }
      GroupPost? reply = visibleReplies[i];
      // String? optionsIconPath;
      // void Function()? optionsFunctionTap;
      // if (_isReplyVisible) {
      //   optionsIconPath = 'more';
      //   optionsFunctionTap = () => _onTapReplyOptions(reply);
      // }
      replyWidgetList.add(
          GroupPostCard(
            post: reply,
            group: widget.group,
            isReply: true,
            allMembersAllowedToPost: _allMembersAllowedToPost,
          )
      );
    }
    return Padding(
        padding: EdgeInsets.only(top: nestedReply ? 0 : 24),
        child: Row(
          children: [
            Container(height: _repliesHeight, width: 1, color: Styles().colors.surfaceAccent),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: leftPaddingOffset),
                child: Column(
                  key: _repliesKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: replyWidgetList),
              ),
            ),
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
      backgroundColor: Styles().colors.surface,
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
                leftIconKey: "comment",
                label: Localization().getStringEx("panel.group.detail.post.button.report.students_dean.labe", "Report to Dean of Students"),
                onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToDeanOfStudents : true), post: widget.post),
              )),
              Visibility(visible: _isReportAbuseVisible, child: RibbonButton(
                leftIconKey: "comment",
                label: Localization().getStringEx("panel.group.detail.post.button.report.group_admins.labe", "Report to Group Administrator(s)"),
                onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToGroupAdmins: true), post: widget.post),
              )),
            ],
          ),
        );
      });
  }

  void _onTapHeaderReply() {
    Analytics().logSelect(target: 'Reply');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostCreatePanel(group: widget.group!, inReplyTo: widget.post?.id)));
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
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostEditPanel(post: widget.post, group: widget.group,)));
  }

  void _reloadPost() {
    //TODO: Can we optimize this to only load data for the relevant updated post(s)?
    _setLoading(true);
    Groups().loadGroupPosts(widget.group?.id, type: GroupPostType.post, order: GroupSortOrder.desc).then((posts) {
      if (CollectionUtils.isNotEmpty(posts)) {
        try {
          // GroupPost? post = (posts as List<GroupPost?>).firstWhere((post) => (post?.id == _post?.id), orElse: ()=> null); //Remove to fix reload Error: type '() => Null' is not a subtype of type '(() => GroupPost)?' of 'orElse'
          List<GroupPost?> nullablePosts = List.of(posts!);
          _post = nullablePosts.firstWhere((post) => (post?.id == _post?.id), orElse: ()=> null);
        } catch (e) {
          print(e);
        }
        _sortReplies(_post?.replies);
        setStateIfMounted(() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _evalRepliesHeight();
          });
        }); // Refresh MainPost
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

  void _evalRepliesHeight() {
    double? repliesHeight;
    try {
      final RenderObject? renderBox = _repliesKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize) {
        repliesHeight = renderBox.size.height;
      }
    } on Exception catch (e) {
      print(e.toString());
    }

    setStateIfMounted(() {
      _repliesHeight = repliesHeight;
    });
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

