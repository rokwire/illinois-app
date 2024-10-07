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
import 'package:neom/model/Analytics.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:neom/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:neom/ui/events2/Event2CreatePanel.dart';
import 'package:neom/ui/events2/Event2DetailPanel.dart';
import 'package:neom/ui/events2/Event2HomePanel.dart';
import 'package:neom/ui/events2/Event2Widgets.dart';
import 'package:neom/ui/groups/GroupMemberNotificationsPanel.dart';
import 'package:neom/ui/groups/GroupPostDetailPanel.dart';
import 'package:neom/ui/groups/GroupPostReportAbuse.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/ui/widgets/InfoPopup.dart';
import 'package:neom/ui/widgets/QrCodePanel.dart';
import 'package:neom/ui/widgets/TextTabBar.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:neom/ext/Group.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:neom/ext/Event2.dart';
import 'package:neom/ui/groups/GroupAllEventsPanel.dart';
import 'package:neom/ui/groups/GroupMembershipRequestPanel.dart';
import 'package:neom/ui/groups/GroupPollListPanel.dart';
import 'package:neom/ui/groups/GroupPostCreatePanel.dart';
import 'package:neom/ui/groups/GroupWidgets.dart';
import 'package:neom/ui/polls/CreatePollPanel.dart';
import 'package:neom/ui/widgets/ExpandableText.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

import 'GroupMembersPanel.dart';
import 'GroupSettingsPanel.dart';

enum _DetailTab { Events, Posts, Messages, Polls, About }

class GroupDetailPanel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'group_detail_content_panel';

  final Group? group;
  final String? groupIdentifier;
  final String? groupPostId;

  GroupDetailPanel({this.group, this.groupIdentifier, this.groupPostId});

  @override
 _GroupDetailPanelState createState() => _GroupDetailPanelState();

  @override
  AnalyticsFeature? get analyticsFeature => (group?.researchProject == true) ? AnalyticsFeature.ResearchProject : AnalyticsFeature.Groups;

  @override
  Map<String, dynamic>? get analyticsPageAttributes {
    return group?.analyticsAttributes;
  }

  String? get groupId => group?.id ?? groupIdentifier;
}

class _GroupDetailPanelState extends State<GroupDetailPanel> with TickerProviderStateMixin implements NotificationsListener {

  final int          _postsPageSize = 8;

  Group?             _group;
  GroupStats?        _groupStats;
  List<Member>?      _groupAdmins;

  final GlobalKey _headerKey = GlobalKey();
  double? _headerHeight;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  _DetailTab         _currentTab = _DetailTab.Events;

  int                _progress = 0;
  bool               _confirmationLoading = false;

  List<Event2>?      _groupEvents;
  bool               _updatingEvents = false;
  int                _allEventsCount = 0;

  List<GroupPost>    _posts = <GroupPost>[];
  GlobalKey          _lastPostKey = GlobalKey();
  bool?              _refreshingPosts;
  bool?              _loadingPostsPage;
  bool?              _hasMorePosts;
  bool?              _scrollToLastPostAfterRefresh;

  List<GroupPost>    _scheduledPosts = <GroupPost>[];
  GlobalKey          _lastScheduledPostKey = GlobalKey();
  bool?              _refreshingScheduledPosts;
  bool?              _loadingScheduledPostsPage;
  bool?              _hasMoreScheduledPosts;
  bool?              _scrollToLastScheduledPostsAfterRefresh;

  List<GroupPost>    _messages = <GroupPost>[];
  GlobalKey          _lastMessageKey = GlobalKey();
  bool?              _refreshingMessages;
  bool?              _loadingMessagesPage;
  bool?              _hasMoreMessages;
  bool?              _scrollToLastMessageAfterRefresh;

  DateTime?          _pausedDateTime;

  GlobalKey          _pollsKey = GlobalKey();
  List<Poll>?        _groupPolls;
  bool               _pollsLoading = false;

//bool               _memberAttendLoading = false;
  bool               _researchProjectConsent = false;

  String?            _postId;

  bool get _isMember {
    return _group?.currentMember?.isMember ?? false;
  }

  bool get _isAdmin {
    return _group?.currentMember?.isAdmin ?? false;
  }

  bool get _isMemberOrAdmin {
    return _group?.currentMember?.isMemberOrAdmin ?? false;
  }

  bool get _isPending{
    return _group?.currentMember?.isPendingMember ?? false;
  }

  bool get _isPublic {
    return _group?.privacy == GroupPrivacy.public;
  }

  bool get isFavorite {
    return false;
  }

  bool get _canLeaveGroup {
    if (_group?.authManEnabled ?? false) {
      return false;
    }

    Member? currentMemberUser = _group?.currentMember;
    if (currentMemberUser?.isAdmin ?? false) {
      return ((_groupStats?.adminsCount ?? 0) > 1); // Do not allow an admin to leave group if he/she is the only one admin.
    } else {
      return currentMemberUser?.isMember ?? false;
    }
  }

  bool get _canEditGroup {
    return _isAdmin;
  }

  bool get _canReportAbuse => true;  //Even non members car report the group


  bool get _canDeleteGroup {
    if (_isAdmin) {
      if (_group?.authManEnabled ?? false) {
        return Auth2().isManagedGroupAdmin;
      } else {
        return true;
      }
    } else {
      return false;
    }
  }

  bool get _canAddEvent {
    return _isAdmin;
  }

  bool get _canCreatePost {
    return _isAdmin || (_isMember && _group?.isMemberAllowedToCreatePost == true && FlexUI().isSharingAvailable);
  }

  bool get _canCreateMessage =>
      _isAdmin || (_isMember && _group?.isMemberAllowedToPostToSpecificMembers == true && FlexUI().isSharingAvailable);

  bool get _canCreatePoll {
    return _isAdmin || ((_group?.canMemberCreatePoll ?? false) && _isMember && FlexUI().isSharingAvailable);
  }

  bool get _isResearchProject {
    return (_group?.researchProject == true);
  }

  /*bool get _isAttendanceGroup {
    return (_group?.attendanceGroup == true);
  }*/

  bool get _canViewMembers {
    return _isAdmin || (_isMember && (_group?.isMemberAllowedToViewMembersInfo == true));
  }

  bool get _hasOptions => _canLeaveGroup || _canDeleteGroup || _canCreatePost|| _canCreateMessage || _canReportAbuse;

  String? get _groupId => _group?.id;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLifecycle.notifyStateChanged,
      Groups.notifyUserMembershipUpdated,
      Groups.notifyGroupCreated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupEventsUpdated,
      Groups.notifyGroupStatsUpdated,
      Groups.notifyGroupPostCreated,
      Groups.notifyGroupPostUpdated,
      Groups.notifyGroupPostDeleted,
      Polls.notifyCreated,
      Polls.notifyDeleted,
      Polls.notifyStatusChanged,
      Polls.notifyVoteChanged,
      Polls.notifyResultsChanged,
      Events2.notifyUpdated,
      FlexUI.notifyChanged,
      Connectivity.notifyStatusChanged,
    ]);

    _tabController = TabController(length: _DetailTab.values.length, initialIndex: _currentTab.index, vsync: this);
    // _tabController.addListener(_onTabChanged);

    _postId = widget.groupPostId;
    _loadGroup(loadEvents: true);

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    // _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _loadGroup({bool loadEvents = false}) {
    _loadGroupStats();
    _increaseProgress();
    // Load group if the device is online, otherwise - use widget's argument
    if (Connectivity().isOnline) {
      Groups().loadGroup(widget.groupId).then((Group? group) {
        _onGroupLoaded(group, loadEvents: loadEvents);
      });
    } else {
      _onGroupLoaded(widget.group, loadEvents: loadEvents);
    }
  }

  void _onGroupLoaded(Group? group, {bool loadEvents = false}) {
    if (mounted) {
      if (group != null) {
        _group = group;
        if (_isResearchProject && _isMember) {
          _currentTab = _DetailTab.About;
        }
        _redirectToGroupPostIfExists();
        _loadGroupAdmins();
        _loadInitialPosts();
        _loadInitialScheduledPosts();
        _loadInitialMessages();
        _loadPolls();
      }
      if (loadEvents) {
        _loadEvents();
      }
      _decreaseProgress();
    }
  }

  void _refreshGroup({bool refreshEvents = false}) {
    Groups().loadGroup(widget.groupId).then((Group? group) {
      if (mounted && (group != null)) {
        setState(() {
          _group = group;
          if (refreshEvents) {
            _refreshEvents();
          }
          _refreshGroupAdmins();
        });
        _refreshCurrentPosts();
        _refreshCurrentScheduledPosts();
        _refreshCurrentMessages();
        _refreshPolls();
      }
    });
  }

  void _loadEvents() {
    setStateIfMounted(() {
      _updatingEvents = true;
    });
    Events2().loadGroupEvents(groupId: _groupId, limit: 3).then((Events2ListResult? eventsResult) {
      setStateIfMounted(() {
        _allEventsCount = eventsResult?.totalCount ?? 0;
        _groupEvents = eventsResult?.events;
        _updatingEvents = false;
      });
    });
  }

  void _refreshEvents() {
    Events2().loadGroupEvents(groupId: _groupId, limit: 3).then((Events2ListResult? eventsResult) {
      if (eventsResult != null) {
        setStateIfMounted(() {
          _allEventsCount = eventsResult.totalCount ?? 0;
          _groupEvents = eventsResult.events;
        });
      }
    });
  }

  void _clearEvents() {
    _allEventsCount = 0;
    _groupEvents = null;
  }

  // Posts & Direct Messages

  ///
  /// Loads group post by id (if exists) and redirects to Post detail panel
  ///
  void _redirectToGroupPostIfExists() {
    if ((_groupId != null) && (_postId != null)) {
      _increaseProgress();
      Groups().loadGroupPost(groupId: _group!.id, postId: _postId!).then((post) {
        _postId = null; // Clear _postId in order not to redirect on the next group load.
        if (post != null) {
          if(StringUtils.isNotEmpty(post.topParentId)){ // This is reply
            Groups().loadGroupPost(groupId: _group!.id, postId: post.topParentId).then((mainPost) {
              _decreaseProgress();
              Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostDetailPanel(group: _group, post: mainPost)));
            });
          } else { //this is the main Post
            _decreaseProgress();
            Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostDetailPanel(group: _group, post: post)));
          }
        } else {
          _decreaseProgress();
        }
      });
    }
  }

  void _onGroupPostCreated(GroupPost? post) {
      if (post?.isPost == true) {
        _refreshCurrentPosts(delta: (post?.parentId == null) ? 1 : null);
      }
      else if (post?.isMessage == true) {
        _refreshCurrentMessages(delta: (post?.parentId == null) ? 1 : null);
      }
      //For both post and messages
      if(post?.isScheduled == true){
        _refreshCurrentScheduledPosts(delta: (post?.parentId == null) ? 1 : null);
      }
  }

  void _onGroupPostUpdated(GroupPost? post) {
      if (post?.isPost == true) {
        _refreshCurrentPosts();
      }
      else if (post?.isMessage == true) {
        _refreshCurrentMessages();
      }
      //For both post and messages
      if(post?.isScheduled == true){
        _refreshCurrentScheduledPosts();
      }
  }

  void _onGroupPostDeleted(GroupPost? post) {
      if (post?.isPost == true) {
        _refreshCurrentPosts(delta: (post?.parentId == null) ? -1 : null);
      }
      else if (post?.isMessage == true) {
        _refreshCurrentMessages(delta: (post?.parentId == null) ? -1 : null);
      }
      //For both post and messages
      if(post?.isScheduled == true){
        _refreshCurrentScheduledPosts();
      }
  }

  // Posts

  void _loadInitialPosts() {
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin) {
      setState(() {
        _progress++;
        _loadingPostsPage = true;
      });
      _loadPostsPage().then((_) {
        if (mounted) {
          setState(() {
            _progress--;
            _loadingPostsPage = false;
          });
        }
      });
    }
  }

  void _refreshCurrentPosts({int? delta}) {
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin && (_refreshingPosts != true)) {
      int limit = _posts.length + (delta ?? 0);
      _refreshingPosts = true;
      Groups().loadGroupPosts(widget.groupId, type: GroupPostType.post, offset: 0, limit: limit, order: GroupSortOrder.desc).then((List<GroupPost>? posts) {
        _refreshingPosts = false;
        if (mounted && (posts != null)) {
          setState(() {
            _posts = posts;
            if (posts.length < limit) {
              _hasMorePosts = false;
            }
          });
          if (_scrollToLastPostAfterRefresh == true) {
            _scheduleLastPostScroll();
          }
        }
        _scrollToLastPostAfterRefresh = null;
      });
    }
  }

  void _loadNextPostsPage() {
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin && (_loadingPostsPage != true)) {
      setState(() {
        _loadingPostsPage = true;
      });
      _loadPostsPage().then((_) {
        if (mounted) {
          setState(() {
            _loadingPostsPage = false;
          });
        }
      });
    }
  }

  Future<void> _loadPostsPage() async {
    List<GroupPost>? postsPage = await Groups().loadGroupPosts(widget.groupId, type: GroupPostType.post , offset: _posts.length, limit: _postsPageSize, order: GroupSortOrder.desc);
    if (postsPage != null) {
      _posts.addAll(postsPage);
      if (postsPage.length < _postsPageSize) {
        _hasMorePosts = false;
      }
    }
  }

  // Scheduled Posts

  void _loadInitialScheduledPosts() {
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin) {
      setState(() {
        _progress++;
        _loadingScheduledPostsPage = true;
      });
      _loadScheduledPostsPage().then((_) {
        if (mounted) {
          setState(() {
            _progress--;
            _loadingScheduledPostsPage = false;
          });
        }
      });
    }
  }

  void _refreshCurrentScheduledPosts({int? delta}) {
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin && (_refreshingScheduledPosts != true)) {
      int limit = _scheduledPosts.length + (delta ?? 0);
      _refreshingScheduledPosts = true;
      Groups().loadGroupPosts(widget.groupId, type: GroupPostType.post, offset: 0, limit: limit, order: GroupSortOrder.desc, scheduledOnly: true).then((List<GroupPost>? scheduledPost) {
        _refreshingScheduledPosts = false;
        if (mounted && (scheduledPost != null)) {
          setState(() {
            _scheduledPosts = scheduledPost;
            if (scheduledPost.length < limit) {
              _hasMoreScheduledPosts = false;
            }
          });
          if (_scrollToLastScheduledPostsAfterRefresh == true) {
            _scheduleLastScheduledPostScroll();
          }
        }
        _scrollToLastScheduledPostsAfterRefresh = null;
      });
    }
  }

  void _loadNextScheduledPostsPage() {
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin && (_loadingScheduledPostsPage != true)) {
      setState(() {
        _loadingScheduledPostsPage = true;
      });
      _loadScheduledPostsPage().then((_) {
        if (mounted) {
          setState(() {
            _loadingScheduledPostsPage = false;
          });
        }
      });
    }
  }

  Future<void> _loadScheduledPostsPage() async {
    List<GroupPost>? scheduledPostsPage = await Groups().loadGroupPosts(widget.groupId, type: GroupPostType.post , offset: _scheduledPosts.length, limit: _postsPageSize, order: GroupSortOrder.desc, scheduledOnly: true);
    if (scheduledPostsPage != null) {
      _scheduledPosts.addAll(scheduledPostsPage);
      if (scheduledPostsPage.length < _postsPageSize) {
        _hasMoreScheduledPosts = false;
      }
    }
  }

  // Direct Messages

  void _loadInitialMessages() {
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin) {
      setState(() {
        _progress++;
        _loadingMessagesPage = true;
      });
      _loadMessagesPage().then((_) {
        if (mounted) {
          setState(() {
            _progress--;
            _loadingMessagesPage = false;
          });
        }
      });
    }
  }

  void _refreshCurrentMessages({int? delta}) {
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin && (_refreshingMessages != true)) {
      int limit = _messages.length + (delta ?? 0);
      _refreshingMessages = true;
      Groups().loadGroupPosts(widget.groupId, type: GroupPostType.message, offset: 0, limit: limit, order: GroupSortOrder.desc).then((List<GroupPost>? messages) {
        _refreshingMessages = false;
        if (mounted && (messages != null)) {
          setState(() {
            _messages = messages;
            if (messages.length < limit) {
              _hasMoreMessages = false;
            }
          });
          if (_scrollToLastMessageAfterRefresh == true) {
            _scheduleLastMessageScroll();
          }
        }
        _scrollToLastMessageAfterRefresh = null;
      });
    }
  }

  void _loadNextMessagesPage() {
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin && (_loadingMessagesPage != true)) {
      setState(() {
        _loadingMessagesPage = true;
      });
      _loadMessagesPage().then((_) {
        if (mounted) {
          setState(() {
            _loadingMessagesPage = false;
          });
        }
      });
    }
  }

  Future<void> _loadMessagesPage() async {
    List<GroupPost>? messagesPage = await Groups().loadGroupPosts(widget.groupId, type: GroupPostType.message , offset: _messages.length, limit: _postsPageSize, order: GroupSortOrder.desc);
    if (messagesPage != null) {
      _messages.addAll(messagesPage);
      if (messagesPage.length < _postsPageSize) {
        _hasMoreMessages = false;
      }
    }
  }

  Future<void> _loadPolls() async {
    if (StringUtils.isNotEmpty(_groupId) && _group!.currentUserIsMemberOrAdmin) {
      _setPollsLoading(true);
      Polls().getGroupPolls(groupIds: {_groupId!})!.then((result) {
        _groupPolls = (result != null) ? result.polls : null;
        _setPollsLoading(false);
      });
    }
  }

  void _refreshPolls() {
    _loadPolls();
  }

  void _setPollsLoading(bool loading) {
    _pollsLoading = loading;
    if (mounted) {
      setState(() {});
    }
  }

  void _loadGroupStats() {
    _increaseProgress();
    Groups().loadGroupStats(widget.groupId).then((stats) {
      _groupStats = stats;
      _decreaseProgress();
    });
  }

  void _refreshGroupStats() {
    Groups().loadGroupStats(widget.groupId).then((stats) {
      _groupStats = stats;
    });
  }

  void _updateGroupStats() {
    GroupStats? cachedGroupStats = Groups().cachedGroupStats(widget.groupId);
    if ((cachedGroupStats != null) && (_groupStats != cachedGroupStats) && mounted) {
      setState(() {
        _groupStats = cachedGroupStats;
      });
    }
  }

  void _loadGroupAdmins() {
    _increaseProgress();
    Groups().loadMembers(groupId: widget.groupId, statuses: [GroupMemberStatus.admin]).then((admins) {
      _groupAdmins = admins;
      _decreaseProgress();
    });
  }

  void _refreshGroupAdmins() {
    Groups().loadMembers(groupId: widget.groupId, statuses: [GroupMemberStatus.admin]).then((admins) {
      _groupAdmins = admins;
    });
  }

  void _cancelMembershipRequest() {
    _setConfirmationLoading(true);
    Groups().cancelRequestMembership(_group).whenComplete(() {
      if (mounted) {
        _setConfirmationLoading(false);
        _loadGroup();
      }
    });
  }

  Future<void> _leaveGroup() {
    _setConfirmationLoading(true);
    return Groups().leaveGroup(_group).whenComplete(() {
      if (mounted) {
        _setConfirmationLoading(false);
        _loadGroup(loadEvents: true);
      }
    });
  }

  Future<bool> _deleteGroup() {
    _setConfirmationLoading(true);
    return Groups().deleteGroup(_groupId).whenComplete(() {
      _setConfirmationLoading(false);
    });
  }

  void _setConfirmationLoading(bool loading) {
    if (mounted) {
      setState(() {
        _confirmationLoading = loading;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? barTitle = (_isResearchProject && !_isMemberOrAdmin) ? 'Your Invitation To Participate' : null;
    List<Widget>? barActions = (_hasOptions) ? <Widget>[
      Semantics(label: Localization().getStringEx("panel.group_detail.label.options", 'Options'), button: true, excludeSemantics: true, child:
        IconButton(icon: Styles().images.getImage('more-white',) ?? Container(), onPressed: _onGroupOptionsTap,)
      )
    ] : null;

    Widget content;
    if (_isLoading) {
      content = _buildLoadingContent();
    }
    else if (_group != null) {
      content = _buildGroupContent(barActions);
      _scheduleEvalHeaderHeight();
    }
    else {
      content = _buildErrorContent();
    }

    return SafeArea(
      child: Scaffold(
        appBar: _group == null ? HeaderBar(
          title: barTitle,
          actions: barActions
        ) : null,
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: uiuc.TabBar(),
        body: SafeArea(
          child: RefreshIndicator(onRefresh: _onPullToRefresh, child:
            content,
          ),
        ),
      ),
    );
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Groups.notifyUserMembershipUpdated) {
      setStateIfMounted(() {});
    }
    else if (name == Groups.notifyGroupEventsUpdated) {
      _clearEvents();
      _loadEvents();
    }
    else if (name == Groups.notifyGroupStatsUpdated) {
      _updateGroupStats();
    }
    else if (param == widget.groupId && (name == Groups.notifyGroupCreated || name == Groups.notifyGroupUpdated)) {
      _loadGroup(loadEvents: true);
    } 
    else if (name == Groups.notifyGroupPostCreated) {
      _onGroupPostCreated(param is GroupPost ? param : null);
    }
    else if (name == Groups.notifyGroupPostUpdated) {
      _onGroupPostUpdated(param is GroupPost ? param : null);
    }
    else if (name == Groups.notifyGroupPostDeleted) {
      _onGroupPostDeleted(param is GroupPost ? param : null);
    }
    else if ((name == Polls.notifyCreated) || (name == Polls.notifyDeleted)) {
      _refreshPolls();
    } 
    else if (name == Polls.notifyVoteChanged
            || name == Polls.notifyResultsChanged 
            || name == Polls.notifyStatusChanged) {
      _onPollUpdated(param); // Deep collection update single element (do not reload whole list)
    } 
    else if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
    }
    else if (name == Events2.notifyUpdated) {
      _updateEventIfNeeded(param);
    }
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
    } 
    else if (name == Connectivity.notifyStatusChanged) {
      if (Connectivity().isOnline && mounted) {
        _loadGroup(loadEvents: true);
      }
    }
  }

  void _onAppLifecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      // Refresh group if the device is online
      if ((_pausedDateTime != null) && Connectivity().isOnline) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refreshGroup(refreshEvents: true);
          _refreshGroupStats();
        }
      }
    }
  }

  // Content Builder

  Widget _buildLoadingContent() {
    return Stack(children: <Widget>[
      Column(children: <Widget>[
        Expanded(
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary), ),
          ),
        ),
      ]),
      HeaderBackButton(),
    ],);
  }

  Widget _buildErrorContent() {
    return Stack(children: <Widget>[
      Column(children: <Widget>[
        Expanded(
          child: Center(
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(_isResearchProject ? 'Failed to load project data.' : Localization().getStringEx("panel.group_detail.label.error_message", 'Failed to load group data.'),  style:  Styles().textStyles.getTextStyle('widget.message.light.large.fat'),)
            ),
          ),
        ),
      ]),
      HeaderBackButton(),
    ],);
  }

  Widget _buildGroupContent(List<Widget>? actions) {
    Widget content;
    if (_isMemberOrAdmin) {
      content = TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          SingleChildScrollView(scrollDirection: Axis.vertical, child: _buildEvents()),
          SingleChildScrollView(scrollDirection: Axis.vertical, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildPosts(), _buildScheduledPosts()],)),
          SingleChildScrollView(scrollDirection: Axis.vertical, child: _buildMessages()),
          SingleChildScrollView(scrollDirection: Axis.vertical, child: _buildPolls()),
          SingleChildScrollView(scrollDirection: Axis.vertical, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildAbout(), _buildPrivacyDescription(), _buildAdmins()],)),
        ],
      );
    }
    else {
      content = SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildAbout(),
          _buildPrivacyDescription(),
          _buildAdmins(),
          if (_isPublic && CollectionUtils.isNotEmpty(_groupEvents))
            _buildEvents(),
          _buildResearchProjectMembershipRequest(),
        ]),
      );
    }

    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          SliverHeaderBar(
            pinned: true,
            floating: true,
            actions: actions,
            title: _group?.title ?? '',
            leadingIconKey: 'caret-left',
            expandedHeight: (_headerHeight ?? 0) + (_isMemberOrAdmin ? kToolbarHeight : 0) + kToolbarHeight,
            flexibleSpace: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(top: kToolbarHeight),
                child: Stack(key: _headerKey, children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 200.0),
                    child: _buildImageHeader(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: 152.0),
                    child: _buildGroupInfo(),
                  )
                ]),
              ),
            ),
            bottom: _isMemberOrAdmin ? TextTabBar(tabs: _buildTabs(), labelStyle: Styles().textStyles.getTextStyle('widget.heading.medium_small'),
                labelPadding: const EdgeInsets.symmetric(horizontal: 6.0,), controller: _tabController,
                backgroundColor: Styles().colors.fillColorPrimary, isScrollable: false, onTap: _onTabChanged) : null,
          ),
        ];
      },
      body: content,
    );
  }

  Widget _buildImageHeader(){
    return StringUtils.isNotEmpty(_group?.imageURL) ? Semantics(label: "group image", hint: "Double tap to zoom", child:
      Container(height: 200.0, width: MediaQuery.of(context).size.width, color: Styles().colors.background, child:
        ModalImageHolder(child: Image.network(_group!.imageURL!, excludeFromSemantics: true, fit: BoxFit.cover, headers: Config().networkAuthHeaders)),
      )
    ): Container();
  }

  Widget _buildGroupInfo() {
    String members;
    int membersCount = _groupStats?.activeMembersCount ?? 0;
    if (!_isResearchProject) {
      if (membersCount == 0) {
        members = Localization().getStringEx("panel.group_detail.members.count.empty", "No Current Members");
      }
      else if (membersCount == 1) {
        members = Localization().getStringEx("panel.group_detail.members.count.one", "1 Current Member");
      }
      else {
        members = sprintf(Localization().getStringEx("panel.group_detail.members.count.format", "%s Current Members"), [membersCount]);
      }
    }
    else if (_isAdmin) {
      if (membersCount == 0) {
        members = "No Current Participants";
      }
      else if (membersCount == 1) {
        members = "1 Current Participant";
      }
      else {
        members = sprintf("%s Current Participants", [membersCount]);
      }
    }
    else {
      members = "";
    }

    int pendingCount = _groupStats?.pendingCount ?? 0;
    String pendingMembers;
    if (_isAdmin && (pendingCount > 0)) {
      if (pendingCount > 1) {
        pendingMembers = sprintf(_isResearchProject ? "%s Pending Participants" : Localization().getStringEx("panel.group_detail.pending_members.count.format", "%s Pending Members"), [pendingCount]);
      }
      else {
        pendingMembers = _isResearchProject ? "1 Pending Participant" : Localization().getStringEx("panel.group_detail.pending_members.count.one", "1 Pending Member");
      }
    }
    else {
      pendingMembers = "";
    }

    int attendedCount = _groupStats?.attendedCount ?? 0;
    String? attendedMembers;
    if (_isAdmin && (_group!.attendanceGroup == true)) {
      if (attendedCount == 0) {
        attendedMembers = Localization().getStringEx("panel.group_detail.attended_members.count.empty", "No Members Attended");
      } else if (attendedCount == 1) {
        attendedMembers = Localization().getStringEx("panel.group_detail.attended_members.count.one", "1 Member Attended");
      } else {
        attendedMembers =
            sprintf(Localization().getStringEx("panel.group_detail.attended_members.count.format", "%s Members Attended"), [attendedCount]);
      }
    }

    List<Widget> commands = [];
    if (_isMemberOrAdmin) {
      if (_isAdmin) {
        commands.add(RibbonButton(
          label: _isResearchProject ? 'Manage Participants' : Localization().getStringEx("panel.group_detail.button.manage_members.title", "Manage Members"),
          hint: _isResearchProject ? '' : Localization().getStringEx("panel.group_detail.button.manage_members.hint", ""),
          leftIconKey: 'person-circle',
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
          onTap: _onTapMembers,
        ));
        commands.add(Container(height: 1, color: Styles().colors.surfaceAccent,));
        commands.add(RibbonButton(
          label: _isResearchProject ? 'Research Project Settings' : Localization().getStringEx("panel.group_detail.button.group_settings.title", "Group Settings"),
          hint: _isResearchProject ? '' : Localization().getStringEx("panel.group_detail.button.group_settings.hint", ""),
          leftIconKey: 'settings',
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
          onTap: _onTapSettings,
        ));
        //#2685 [USABILITY] Hide group setting "Enable attendance checking" for 4.2
        /*if (_isAttendanceGroup && !_isResearchProject) {
          commands.add(Container(height: 1, color: Styles().colors.surfaceAccent));
          commands.add(Stack(alignment: Alignment.center, children: [
            RibbonButton(
            label: Localization().getStringEx("panel.group_detail.button.take_attendance.title", "Take Attendance"),
            hint: Localization().getStringEx("panel.group_detail.button.take_attendance.hint", ""),
            leftIconKey: 'share',
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
            onTap: _onTapTakeAttendance,
          ),
          Visibility(visible: _memberAttendLoading, child: CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 2))
          ]));
        }*/
      }
      if (CollectionUtils.isNotEmpty(commands)) {
        commands.add(Container(height: 1, color: Styles().colors.surfaceAccent));
      }
      commands.add(RibbonButton(
        label: Localization().getStringEx("panel.group_detail.button.notifications.title", "Notification Preferences"),
        hint: Localization().getStringEx("panel.group_detail.button.notifications.hint", ""),
        leftIconKey: 'reminder',
        //leftIconPadding: EdgeInsets.only(right: 8, left: 2),
        padding: EdgeInsets.symmetric(vertical: 14),
        onTap: _onTapNotifications,
      ));
      if (!_isResearchProject) {
        commands.add(Container(height: 1, color: Styles().colors.surfaceAccent));
        commands.add(_buildPromoteCommand());
      }
      if (StringUtils.isNotEmpty(_group?.webURL) && !_isResearchProject) {
        commands.add(Container(height: 1, color: Styles().colors.surfaceAccent));
        commands.add(_buildWebsiteLinkCommand());
      }
    }
    else {
      if (!_isResearchProject) {
        if (CollectionUtils.isNotEmpty(commands)) {
          commands.add(Container(height: 1, color: Styles().colors.surfaceAccent));
        }
        commands.add(_buildPromoteCommand());
      }
      if (StringUtils.isNotEmpty(_group?.webURL) && !_isResearchProject) {
        if (CollectionUtils.isNotEmpty(commands)) {
          commands.add(Container(height: 1, color: Styles().colors.surfaceAccent));
        }
        commands.add(_buildWebsiteLinkCommand());
      }

      List<Widget> attributesList = _buildAttributes();
      if (attributesList.isNotEmpty) {
        if (commands.isNotEmpty) {
          commands.add(Container(height: 1, color: Styles().colors.surfaceAccent));
          commands.add(Container(height: 12,));
        }
        commands.addAll(attributesList);
        commands.add(Container(height: 4,));
      }
    }

    List<Widget> contentList = <Widget>[];
    if (_showMembershipBadge) {
      contentList.addAll(<Widget>[
        Padding(padding: EdgeInsets.only(left: 16, right: _showPolicyButton ? 0 : 16, top: 8), child:
          _buildBadgeWidget(),
        ),

        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
          Text(_group?.title?.toUpperCase() ?? '',  style:  Styles().textStyles.getTextStyle('widget.group.card.title.medium.fat'),),
        ),
      ]);
    }
    else {
      contentList.addAll(<Widget>[
        Padding(padding: EdgeInsets.only(left: 16, right: _showPolicyButton ? 0 : 16), child:
          _buildTitleWidget(),
        ),
      ]);
    }

    if (StringUtils.isNotEmpty(members)) {
      contentList.add(GestureDetector(onTap: () => { if (_isMember  && _canViewMembers) {_onTapMembers()} }, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
          Container(decoration: (_isMember && _canViewMembers ? BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors.fillColorSecondary, width: 2))) : null), child:
            Text(members, style:  Styles().textStyles.getTextStyle('panel.group.detail.fat'))
          ),
        ),
      ));
    }

    if (StringUtils.isNotEmpty(pendingMembers)) {
      contentList.add(Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
        Text(pendingMembers,  style: Styles().textStyles.getTextStyle('panel.group.detail.fat') ,)
      ));
    }

    if (StringUtils.isNotEmpty(attendedMembers)) {
      contentList.add(Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
        Text(StringUtils.ensureNotEmpty(attendedMembers), style: Styles().textStyles.getTextStyle('panel.group.detail.fat'),)
      ));
    }

    contentList.add(Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
      Column(children: commands,),
    ));

    return Container(color: Styles().colors.surface, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList),
      );
  }

  List<Widget> _buildTabs() {
    List<Widget> tabs = [];
    for (_DetailTab tab in _DetailTab.values) {
      String title;
      switch (tab) {
        case _DetailTab.Events:
          title = Localization().getStringEx("panel.group_detail.button.events.title", 'Events');
          break;
        case _DetailTab.Posts:
          title = Localization().getStringEx("panel.group_detail.button.posts.title", 'Posts');
          break;
        case _DetailTab.Messages:
          title = Localization().getStringEx("panel.group_detail.button.messages.title", 'Messages');
          break;
        case _DetailTab.Polls:
          title = Localization().getStringEx("panel.group_detail.button.polls.title", 'Polls');
          break;
        case _DetailTab.About:
          title = Localization().getStringEx("panel.group_detail.button.about.title", 'About');
          break;
      }

      tabs.add(TextTabButton(title: title));
    }

    return tabs;

    // Widget leaveButton = GestureDetector(
    //     onTap: _onTapLeave,
    //     child: Padding(
    //         padding: EdgeInsets.only(left: 24, top: 10, bottom: 10),
    //         child: Text(Localization().getStringEx("panel.group_detail.button.leave.title", 'Leave'),
    //             style: Styles().textStyles.getTextStyle('panel.group.button.leave.title')
    //         )));
    //
    // return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    //   SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: tabs)),
    //   Visibility(visible: _canLeaveGroup, child: Padding(padding: EdgeInsets.only(top: 5), child: Row(children: [Expanded(child: Container()), leaveButton])))
    // ]));
  }

  Widget _buildEvents() {
    List<Widget> content = [];

//    if (_isAdmin) {
//      content.add(_buildAdminEventOptions());
//    }

    if (CollectionUtils.isNotEmpty(_groupEvents)) {
      for (Event2 groupEvent in _groupEvents!) {
        content.add(Padding(padding: EdgeInsets.only(bottom: 16), child: Event2Card(groupEvent, group: _group, onTap: () => _onTapEvent(groupEvent))));
      }

      content.add(Padding(padding: EdgeInsets.only(top: 16), child:
        RoundedButton(
          label: Localization().getStringEx("panel.group_detail.button.all_events.title", 'See all events'),
          textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.dark"),
          backgroundColor: Styles().colors.surface,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          borderColor: Styles().colors.fillColorSecondary,
          borderWidth: 2,
          contentWeight: 0.5,
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupAllEventsPanel(group: _group)));
          })
        )
      );
    }

    return Stack(children: [
      Column(children: <Widget>[
        SectionSlantHeader(
            title: Localization().getStringEx("panel.group_detail.label.upcoming_events", 'Upcoming Events') + ' ($_allEventsCount)',
            titleIconKey: 'calendar',
            rightIconKey: _canAddEvent ? "plus-circle" : null,
            rightIconAction: _canAddEvent ? _onTapEventOptions : null,
            rightIconLabel: _canAddEvent ? Localization().getStringEx("panel.group_detail.button.create_event.title", "Create Event") : null,
            children: content)
      ]),
      _updatingEvents
          ? Center(child:
              Container(padding: EdgeInsets.symmetric(vertical: 50), child:
                CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary)),
              ),
            )
          : Container()
    ]);
  }

  Widget _buildPosts() {
    List<Widget> postsContent = [];

    if (CollectionUtils.isEmpty(_posts)) {
      if (_isMemberOrAdmin) {
        Column(children: <Widget>[
          SectionSlantHeader(
              title: Localization().getStringEx("panel.group_detail.label.posts", 'Posts'),
              titleIconKey: 'posts',
              rightIconKey: _canCreatePost ? "plus-circle" : null,
              rightIconAction: _canCreatePost ? _onTapCreatePost : null,
              rightIconLabel: _canCreatePost ? Localization().getStringEx("panel.group_detail.button.create_post.title", "Create Post") : null,
              children: postsContent)
        ]);
      } else {
        return Container();
      }
    }

    for (int i = 0; i <_posts.length ; i++) {
      GroupPost? post = _posts[i];
      if (i > 0) {
        postsContent.add(Container(height: 16));
      }
      postsContent.add(GroupPostCard(key: (i == 0) ? _lastPostKey : null, post: post, group: _group));
    }

    if ((_group != null) && _group!.currentUserIsMemberOrAdmin && (_hasMorePosts != false) && (0 < _posts.length)) {
      String title = Localization().getStringEx('panel.group_detail.button.show_older.title', 'Show older');
      postsContent.add(Container(padding: EdgeInsets.only(top: 16),
        child: Semantics(label: title, button: true, excludeSemantics: true,
          child: InkWell(onTap: _loadNextPostsPage,
              child: Container(height: 36,
                child: Align(alignment: Alignment.topCenter,
                  child: (_loadingPostsPage == true) ?
                  SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorPrimary), )) :
                  Text(title, style: Styles().textStyles.getTextStyle('panel.group.button.show_older.title'),),
                ),
              )
          )
      ))
      );
    }

    return Column(children: <Widget>[
      SectionSlantHeader(
          title: Localization().getStringEx("panel.group_detail.label.posts", 'Posts'),
          titleIconKey: 'posts',
          rightIconKey: _canCreatePost ? "plus-circle" : null,
          rightIconAction: _canCreatePost ? _onTapCreatePost : null,
          rightIconLabel: _canCreatePost ? Localization().getStringEx("panel.group_detail.button.create_post.title", "Create Post") : null,
          children: postsContent)
    ]);
  }

  Widget _buildScheduledPosts() {
    List<Widget> scheduledPostsContent = [];

    if (CollectionUtils.isEmpty(_scheduledPosts)) {
      return Container();
    }

    for (int i = 0; i <_scheduledPosts.length ; i++) {
      GroupPost? post = _scheduledPosts[i];
      if (i > 0) {
        scheduledPostsContent.add(Container(height: 16));
      }
      scheduledPostsContent.add(GroupPostCard(key: (i == 0) ? _lastScheduledPostKey : null, post: post, group: _group));
    }

    if ((_group != null) && _group!.currentUserIsMemberOrAdmin && (_hasMoreScheduledPosts != false) && (0 < _scheduledPosts.length)) {
      String title = Localization().getStringEx('panel.group_detail.button.show_older.title', 'Show older');
      scheduledPostsContent.add(Container(padding: EdgeInsets.only(top: 16),
          child: Semantics(label: title, button: true, excludeSemantics: true,
              child: InkWell(onTap: _loadNextScheduledPostsPage,
                  child: Container(height: 36,
                    child: Align(alignment: Alignment.topCenter,
                      child: (_loadingScheduledPostsPage == true) ?
                      SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorPrimary), )) :
                      Text(title, style: Styles().textStyles.getTextStyle('panel.group.button.show_older.title'),),
                    ),
                  )
              )
          ))
      );
    }

    return Column(children: <Widget>[
      SectionSlantHeader(
          title: Localization().getStringEx("panel.group_detail.label.scheduled_posts", 'Scheduled Posts'),
          titleIconKey: 'posts',
          children: scheduledPostsContent)
    ]);
  }

  Widget _buildMessages() {
    List<Widget> messagesContent = [];

    if (CollectionUtils.isEmpty(_messages)) {
      if (_isMemberOrAdmin) {
        Column(children: <Widget>[
          SectionSlantHeader(
              title: Localization().getStringEx("panel.group_detail.label.messages", 'Direct Messages'),
              titleIconKey: 'posts',
              rightIconKey: _canCreateMessage ? "plus-circle" : null,
              rightIconAction: _canCreateMessage ? _onTapCreatePost : null,
              rightIconLabel: _canCreateMessage ? Localization().getStringEx("panel.group_detail.button.create_message.title", "Create Direct Message") : null,
              children: messagesContent)
        ]);
      } else {
        return Container();
      }
    }

    for (int i = 0; i <_messages.length ; i++) {
      GroupPost? message = _messages[i];
      if (i > 0) {
        messagesContent.add(Container(height: 16));
      }
      messagesContent.add(GroupPostCard(key: (i == 0) ? _lastMessageKey : null, post: message, group: _group));
    }

    if ((_group != null) && _group!.currentUserIsMemberOrAdmin && (_hasMoreMessages != false) && (0 < _messages.length)) {
      String title = Localization().getStringEx('panel.group_detail.button.show_older.title', 'Show older');
      messagesContent.add(Container(padding: EdgeInsets.only(top: 16),
        child: Semantics(label: title, button: true, excludeSemantics: true,
          child: InkWell(onTap: _loadNextMessagesPage,
              child: Container(height: 36,
                child: Align(alignment: Alignment.topCenter,
                  child: (_loadingPostsPage == true) ?
                  SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorPrimary), )) :
                  Text(title, style: Styles().textStyles.getTextStyle('panel.group.button.show_older.title'),),
                ),
              )
          )
      ))
      );
    }

    return Column(children: <Widget>[
      SectionSlantHeader(
          title: Localization().getStringEx("panel.group_detail.label.messages", 'Direct Messages'),
          titleIconKey: 'posts',
          rightIconKey: _canCreateMessage ? "plus-circle" : null,
          rightIconAction: _canCreateMessage ? _onTapCreatePost : null,
          rightIconLabel: _canCreateMessage ? Localization().getStringEx("panel.group_detail.button.create_message.title", "Create Direct Message") : null,
          children: messagesContent)
    ]);
  }

  Widget _buildPolls() {
    List<Widget> pollsContentList = [];

    if (CollectionUtils.isNotEmpty(_groupPolls)) {
      for (Poll? groupPoll in _groupPolls!) {
        if (groupPoll != null) {
          pollsContentList.add(Container(height: 10));
          pollsContentList.add(GroupPollCard(poll: groupPoll, group: _group));
        }
      }

      if (_groupPolls!.length >= 5) {
        pollsContentList.add(Padding(
            padding: EdgeInsets.only(top: 16),
            child: RoundedButton(
                label: Localization().getStringEx('panel.group_detail.button.all_polls.title', 'See all polls'),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                backgroundColor: Styles().colors.surface,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                borderColor: Styles().colors.fillColorSecondary,
                borderWidth: 2,
                contentWeight: 0.5,
                onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPollListPanel(group: _group!))))));
      }
    }

    return Stack(key: _pollsKey, children: [
      Column(children: <Widget>[
        SectionSlantHeader(
            title: Localization().getStringEx('panel.group_detail.label.polls', 'Polls'),
            titleIconKey: 'polls',
            rightIconKey: _canCreatePoll? 'plus-circle' : null,
            rightIconAction: _canCreatePoll? _onTapCreatePoll : null,
            rightIconLabel: _canCreatePoll? Localization().getStringEx('panel.group_detail.button.create_poll.title', 'Create Poll') : null,
            children: pollsContentList)
      ]),
      _pollsLoading
          ? Center(
              child: Container(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary))))
          : Container()
    ]);
  }

  Widget _buildAbout() {
    List<Widget> contentList = <Widget>[];

    if (!_isResearchProject) {
      contentList.add(Padding(padding: EdgeInsets.only(bottom: 4), child:
        Text(Localization().getStringEx("panel.group_detail.label.about_us", 'About us'), style: Styles().textStyles.getTextStyle('panel.group.detail.light.fat'), ),),
      );
    }

    if (StringUtils.isNotEmpty(_group?.description)) {
      contentList.add(ExpandableText(_group?.description ?? '',
        textStyle: Styles().textStyles.getTextStyle('panel.group.detail.light.regular'),
        trimLinesCount: 4,
        readMoreIcon: Styles().images.getImage('chevron-down', excludeFromSemantics: true),),
      );
    }

    if (StringUtils.isNotEmpty(_group?.researchConsentDetails)) {
      contentList.add(Padding(padding: EdgeInsets.only(top: 8), child:
        ExpandableText(_group?.researchConsentDetails ?? '',
          textStyle: Styles().textStyles.getTextStyle('panel.group.detail.regular'),
          trimLinesCount: 12,
          readMoreIcon: Styles().images.getImage('chevron-down', excludeFromSemantics: true),
          footerWidget: (_isResearchProject && StringUtils.isNotEmpty(_group?.webURL)) ? Padding(padding: EdgeInsets.only(top: _group?.researchConsentDetails?.endsWith('\n') ?? false ? 0 : 8), child: _buildWebsiteLinkButton())  : null,
        ),
      ),);
    }

    return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList,),
    );
  }

  Widget _buildPrivacyDescription() {
    String? title, description;
    if (_group?.privacy == GroupPrivacy.private) {
      title = Localization().getStringEx("panel.group_detail.label.title.private", 'This is a Private Group');
      description = Localization().getStringEx("panel.group_detail.label.description.private", '\u2022 This group is only visible to members.\n\u2022 Anyone can search for the group with the exact name.\n\u2022 Only admins can see members.\n\u2022 Only members can see posts and group events.\n\u2022 All users can see group events if they are marked public.\n\u2022 All users can see admins.');
    }
    else if (_group?.privacy == GroupPrivacy.public) {
      title = Localization().getStringEx("panel.group_detail.label.title.public", 'This is a Public Group');
      description = Localization().getStringEx("panel.group_detail.label.description.public", '\u2022 Only admins can see members.\n\u2022 Only members can see posts.\n\u2022 All users can see group events, unless they are marked private.\n\u2022 All users can see admins.');
    }
    
    return (StringUtils.isNotEmpty(title) && StringUtils.isNotEmpty(description) && !_isResearchProject) ?
      Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: EdgeInsets.only(bottom: 4), child:
            Text(title!, style:  Styles().textStyles.getTextStyle('panel.group.detail.light.fat'), ),),
          Text(description!, style: Styles().textStyles.getTextStyle('panel.group.detail.light.regular'), ),
        ],),) :
      Container(width: 0, height: 0);
  }

  Widget _buildPromoteCommand() {
    return RibbonButton(
      label: Localization().getStringEx("panel.group_detail.button.group_promote.title", "Share this group"),
      hint: Localization().getStringEx("panel.group_detail.button.group_promote.hint", ""),
      leftIconKey: 'share',
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
      onTap: _onTapPromote,
    );
  }

  Widget _buildWebsiteLinkCommand() {
    return RibbonButton(
      label: Localization().getStringEx("panel.group_detail.button.website.title", 'Website'),
      rightIconKey: 'external-link',
      leftIconKey: 'web',
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
      onTap: _onWebsite
    );
  }

  List<Widget> _buildAttributes() {
    List<Widget> attributesList = <Widget>[];
    Map<String, dynamic>? groupAttributes = widget.group?.attributes;
    ContentAttributes? contentAttributes = Groups().contentAttributes;
    List<ContentAttribute>? attributes = contentAttributes?.attributes;
    if ((groupAttributes != null) && (contentAttributes != null) && (attributes != null)) {
      for (ContentAttribute attribute in attributes) {
        if (Groups().isContentAttributeEnabled(attribute)) {
          List<String>? displayAttributeValues = attribute.displaySelectedLabelsFromSelection(groupAttributes, complete: true);
          if ((displayAttributeValues != null) && displayAttributeValues.isNotEmpty) {
            attributesList.add(Row(children: [
              Text("${attribute.displayTitle}: ", overflow: TextOverflow.ellipsis, maxLines: 1, style:
                Styles().textStyles.getTextStyle("widget.card.detail.small.fat")
              ),
              Expanded(child:
                Text(displayAttributeValues.join(', '), maxLines: 1, style:
                  Styles().textStyles.getTextStyle("widget.card.detail.small.regular")
                ),
              ),
            ],),);
          }
        }
      }
    }
    return attributesList;
  }

  Widget _buildWebsiteLinkButton() {
    return RibbonButton(
      label: Localization().getStringEx("panel.group_detail.button.more_info.title", 'More Info'),
      textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
      rightIconKey: 'external-link',
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
      onTap: _onWebsite
    );
    /*return RoundedButton(
      label: Localization().getStringEx('panel.groups_event_detail.button.visit_website.title', 'Visit website'),
      hint: Localization().getStringEx('panel.groups_event_detail.button.visit_website.hint', ''),
      backgroundColor: Colors.white,
      borderColor: Styles().colors.fillColorSecondary,
      rightIcon: Image.asset('images/external-link.png'),
      textColor: Styles().colors.fillColorPrimary,
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      fontFamily: Styles().fontFamilies.bold,
      fontSize: 16,
      onTap: _onWebsite
    );*/
  }

  Widget _buildBadgeWidget() {
    Widget badgeWidget = Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _group!.currentUserStatusColor, borderRadius: BorderRadius.all(Radius.circular(2)),), child:
      Semantics(label: _group?.currentUserStatusText?.toLowerCase(), excludeSemantics: true, child:
        Text(_group!.currentUserStatusText!.toUpperCase(), style:  Styles().textStyles.getTextStyle('widget.heading.dark.extra_small'),)
      ),
    );
    return _showPolicyButton ? Row(children: <Widget>[
      badgeWidget,
      Expanded(child: Container(),),
      _buildPolicyButton()
    ]) : badgeWidget;
  }

  Widget _buildTitleWidget() {
    Widget titleWidget = Text(_group?.title ?? '',  style:  Styles().textStyles.getTextStyle('panel.group.title.large'),);
    return _showPolicyButton ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Expanded(child:
        Padding(padding: EdgeInsets.only(top: 8), child:
          titleWidget
        )
      ),
      _buildPolicyButton()
    ]) : titleWidget;
  }

  Widget _buildPolicyButton() {
    return Semantics(button: true, excludeSemantics: true,
      label: Localization().getStringEx('panel.group_detail.button.policy.label', 'Policy'),
      hint: Localization().getStringEx('panel.group_detail.button.policy.hint', 'Tap to ready policy statement'),
      child: InkWell(onTap: _onPolicy, child:
        Padding(padding: EdgeInsets.all(16), child:
          Styles().images.getImage('info', excludeFromSemantics: true)
        ),
      ),
    );
  }

  Widget _buildAdmins() {
    if (CollectionUtils.isEmpty(_groupAdmins)) {
      return Container();
    }
    
    List<Widget> content = [];
    content.add(Padding(padding: EdgeInsets.only(left: 16), child: Container()));
    for (Member? officer in _groupAdmins!) {
      if (1 < content.length) {
        content.add(Padding(padding: EdgeInsets.only(left: 8), child: Container()));
      }
      content.add(_OfficerCard(groupMember: officer));
    }
    content.add(Padding(padding: EdgeInsets.only(left: 16), child: Container()));

    String headingText = _isResearchProject ? Localization().getStringEx('panel.group_detail.label.project.admins', 'Principal Investigator(s)') : Localization().getStringEx("panel.group_detail.label.admins", 'Admins');

    return Stack(children: [
      Container(
          height: 112,
          color: Styles().colors.backgroundVariant,
          child: Column(children: [
            Container(height: 80),
            Container(height: 32, child: CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background), child: Container()))
          ])),
      Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(headingText,
                    style:   Styles().textStyles.getTextStyle('widget.title.dark.large.extra_fat'))),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: content))
          ]))
    ]);
  }

  Widget _buildMembershipRequest() {
    if (Auth2().isLoggedIn && _group!.currentUserCanJoin && (_group?.researchProject != true)) {
      return Container(decoration: BoxDecoration(color: Styles().colors.surface, border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1))), child:
        Padding(padding: EdgeInsets.all(16), child:
          RoundedButton(label: Localization().getStringEx("panel.group_detail.button.request_to_join.title",  'Request to join'),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.dark"),
            backgroundColor: Styles().colors.surface,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            borderColor: Styles().colors.fillColorSecondary,
            borderWidth: 2,
            onTap:() { _onMembershipRequest();  }
          ),
        ),
      );
    }
    else {
      return Container();
    }
  }

  Widget _buildResearchProjectMembershipRequest() {
    if (Auth2().isOidcLoggedIn && _group!.currentUserCanJoin && (_group?.researchProject == true)) {
      bool showConsent = StringUtils.isNotEmpty(_group?.researchConsentStatement) && CollectionUtils.isEmpty(_group?.questions);
      bool requestToJoinEnabled = CollectionUtils.isNotEmpty(_group?.questions) || StringUtils.isEmpty(_group?.researchConsentStatement) || _researchProjectConsent;
      return Padding(padding: EdgeInsets.only(top: 16), child:
        Container(decoration: BoxDecoration(border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: showConsent ? 1 : 0))), child:
          Column(children: [
            Visibility(visible: showConsent, child:
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                InkWell(onTap: _onResearchProjectConsent, child:
                  Padding(padding: EdgeInsets.all(16), child:
                    Styles().images.getImage(_researchProjectConsent ? "check-box-filled" : "box-outline-gray", excludeFromSemantics: true)
                  ),
                ),
                Expanded(child:
                  Padding(padding: EdgeInsets.only(right: 16, top: 12, bottom: 12), child:
                    Text(_group?.researchConsentStatement ?? '', style: Styles().textStyles.getTextStyle("widget.detail.regular"), textAlign: TextAlign.left,)
                  ),
                ),
              ]),
            ),
            Padding(padding: EdgeInsets.only(left: 16, right: 16, top: showConsent ? 0 : 16, bottom: 16), child:
              RoundedButton(label: CollectionUtils.isEmpty(_group?.questions) ? "Request to participate" : "Continue",
                textStyle: requestToJoinEnabled ?  Styles().textStyles.getTextStyle("widget.button.title.enabled") : Styles().textStyles.getTextStyle("widget.button.title.disabled"),
                backgroundColor: Styles().colors.surface,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                borderColor: requestToJoinEnabled ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
                borderWidth: 2,
                onTap:() { _onMembershipRequest();  }
              ),
            ),
          ],),
        ),
      );
    }
    else {
      return Container();
    }
  }

  void _onResearchProjectConsent() {
    setState(() {
      _researchProjectConsent = !_researchProjectConsent;
    });
  }

  Widget _buildCancelMembershipRequest() {
    if (Auth2().isOidcLoggedIn && _group!.currentUserIsPendingMember) {
      return Container(decoration: BoxDecoration(color: Styles().colors.surface, border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1))), child:
        Padding(padding: EdgeInsets.all(16), child:
          RoundedButton(label: Localization().getStringEx("panel.group_detail.button.cancel_request.title",  'Cancel Request'),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
            backgroundColor: Styles().colors.surface,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            borderColor: Styles().colors.fillColorSecondary,
            borderWidth: 2,
            progress: _confirmationLoading,
            onTap:() { _onCancelMembershipRequest();  }
          ),
        )
      );
    }
    else {
      return Container();
    }
      
  }

  Widget _buildConfirmationDialog({String? confirmationTextMsg,
    
    String? positiveButtonLabel,
    int positiveButtonFlex = 1,
    Function? onPositiveTap,
    
    String? negativeButtonLabel,
    int negativeButtonFlex = 1,
    
    int leftAreaFlex = 0,
  }) {
    return Dialog(
        backgroundColor: Styles().colors.fillColorPrimary,
        child: StatefulBuilder(builder: (context, setStateEx) {
          return Padding(
              padding: EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Text(confirmationTextMsg!,
                        textAlign: TextAlign.left, style:  Styles().textStyles.getTextStyle('widget.dialog.message.medium'))),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                  Expanded(flex: leftAreaFlex, child: Container()),
                  Expanded(flex: negativeButtonFlex, child: RoundedButton(
                      label: StringUtils.ensureNotEmpty(negativeButtonLabel, defaultValue: Localization().getStringEx("panel.group_detail.button.back.title", "Back")),
                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.large"),
                      borderColor: Styles().colors.surface,
                      backgroundColor: Styles().colors.surface,
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      onTap: () {
                        Analytics().logAlert(text: confirmationTextMsg, selection: negativeButtonLabel);
                        Navigator.pop(context);
                      }),),
                  Container(width: 16),
                  Expanded(flex: positiveButtonFlex, child: RoundedButton(
                    label: positiveButtonLabel ?? '',
                    textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                    borderColor: Styles().colors.surface,
                    backgroundColor: Styles().colors.surface,
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    progress: _confirmationLoading,
                    onTap: () {
                      Analytics().logAlert(text: confirmationTextMsg, selection: positiveButtonLabel);
                      onPositiveTap!();
                    },
                  ),),
                ])
              ]));
        }));
  }

  void _onGroupOptionsTap() {
    Analytics().logSelect(target: 'Group Options', attributes: _group?.analyticsAttributes);
    int membersCount = _groupStats?.activeMembersCount ?? 0;
    String? confirmMsg = (membersCount > 1)
        ? sprintf(Localization().getStringEx("panel.group_detail.members_count.group.delete.confirm.msg", "This group has %d members. Are you sure you want to delete this group?"), [membersCount])
        : Localization().getStringEx("panel.group_detail.group.delete.confirm.msg", "Are you sure you want to delete this group?");

    showModalBottomSheet(
        context: context,
        backgroundColor: Styles().colors.surface,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Container(
                  height: 24,
                ),
                Visibility(
                    visible: _canCreatePost,
                    child: RibbonButton(
                        leftIconKey: "plus-circle",
                        label: Localization().getStringEx("panel.group_detail.button.create_post.title", "Create Post"),
                        onTap: () {
                          Navigator.of(context).pop();
                          _onTapCreatePost();
                        })),
                Visibility(
                    visible: _canCreateMessage,
                    child: RibbonButton(
                        leftIconKey: "plus-circle",
                        label: Localization().getStringEx("panel.group_detail.button.create_message.title", "Create Direct Message"),
                        onTap: () {
                          Navigator.of(context).pop();
                          _onTapCreatePost();
                        })),
                Visibility(visible: _canReportAbuse, child: RibbonButton(
                  leftIconKey: "report",
                  label: Localization().getStringEx("panel.group.detail.post.button.report.students_dean.labe", "Report to Dean of Students"),
                  onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToDeanOfStudents : true)   ),
                )),
                Visibility(
                    visible: _canLeaveGroup,
                    child: RibbonButton(
                        leftIconKey: "trash",
                        label: _isResearchProject ? 'Leave project' : Localization().getStringEx("panel.group_detail.button.leave_group.title", "Leave group"),
                        onTap: () {
                          Analytics().logSelect(target: "Leave group", attributes: _group?.analyticsAttributes);
                          showDialog(
                              context: context,
                              builder: (context) => _buildConfirmationDialog(
                                  confirmationTextMsg: _isResearchProject ?
                                    "Are you sure you want to leave this project?" :
                                    Localization().getStringEx("panel.group_detail.label.confirm.leave", "Are you sure you want to leave this group?"),
                                  positiveButtonLabel: Localization().getStringEx("panel.group_detail.button.leave.title", "Leave"),
                                  onPositiveTap: _onTapLeaveDialog)).then((value) => Navigator.pop(context));
                        })),
                Visibility(
                    visible: _canAddEvent,
                    child: RibbonButton(
                        leftIconKey: "edit",
                        label: Localization().getStringEx("panel.group_detail.button.group.add_event.title", "Add existing event"),
                        onTap: (){
                          Navigator.pop(context);
                          _onTapBrowseEvents();
                        })),
                Visibility(
                    visible: _canAddEvent,
                    child: RibbonButton(
                        leftIconKey: "edit",
                        label: Localization().getStringEx("panel.group_detail.button.group.create_event.title", "Create new event"),
                        onTap: (){
                          Navigator.pop(context);
                          _onTapCreateEvent();
                        })),
                Visibility(
                    visible: _canEditGroup,
                    child: RibbonButton(
                        leftIconKey: "settings",
                        label: _isResearchProject ? 'Research project settings' : Localization().getStringEx("panel.group_detail.button.group.edit.title", "Group Settings"),
                        onTap: () {
                          Navigator.pop(context);
                          _onTapSettings();
                        })),
                Visibility(
                    visible: _canDeleteGroup,
                    child: RibbonButton(
                        leftIconKey: "trash",
                        label: _isResearchProject ? 'Delete research project' : Localization().getStringEx("panel.group_detail.button.group.delete.title", "Delete group"),
                        onTap: () {
                          Analytics().logSelect(target: "Delete group", attributes: _group?.analyticsAttributes);
                          showDialog(
                              context: context,
                              builder: (context) => _buildConfirmationDialog(
                                  confirmationTextMsg: confirmMsg,
                                  positiveButtonLabel: Localization().getStringEx('dialog.yes.title', 'Yes'),
                                  negativeButtonLabel: Localization().getStringEx('dialog.no.title', 'No'),
                                  onPositiveTap: _onTapDeleteDialog)).then((value) => Navigator.pop(context));
                        })),
              ]));
        });
  }

  void _onTapEvent(Event2 event) {
    Analytics().logSelect(target: 'Group Event: ${event.name}');
    Navigator.push(context, CupertinoPageRoute( builder: (context) => (event.hasGame == true) ?
      AthleticsGameDetailPanel(game: event.game, event: event, group: _group) :
      Event2DetailPanel(event: event, group: _group)));
  }

  void _onTapEventOptions() {
    Analytics().logSelect(target: "Event options", attributes: _group?.analyticsAttributes);
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Container(
                  height: 24,
                ),
                Visibility(
                    visible: _canAddEvent,
                    child: RibbonButton(
                        leftIconKey: "edit",
                        label: Localization().getStringEx("panel.group_detail.button.group.add_event.title", "Add existing event"),
                        onTap: (){
                          Navigator.pop(context);
                          _onTapBrowseEvents();
                        })),
                Visibility(
                    visible: _canAddEvent,
                    child: RibbonButton(
                        leftIconKey: "edit",
                        label: Localization().getStringEx("panel.group_detail.button.group.create_event.title", "Create new event"),
                        onTap: (){
                          Navigator.pop(context);
                          _onTapCreateEvent();
                        })),
              ]));
        });
  }

  void _onTabChanged(int index) {
    _DetailTab tab = _DetailTab.values[_tabController.index];
    Analytics().logSelect(target: "Tab: $tab", attributes: _group?.analyticsAttributes);
    if (!_tabController.indexIsChanging && _currentTab.index != _tabController.index) {
      setState(() {
        _currentTab = tab;
      });

      switch (_currentTab) {
        case _DetailTab.Posts:
          if (CollectionUtils.isNotEmpty(_posts)) {
            _scheduleLastPostScroll();
          }
          break;
        case _DetailTab.Messages:
          if (CollectionUtils.isNotEmpty(_messages)) {
            _scheduleLastMessageScroll();
          }
          break;
        case _DetailTab.Polls:
          _schedulePollsScroll();
          break;
        default:
          break;
      }
    }
  }

  void _onTapLeave() {
    Analytics().logSelect(target: "Leave Group", attributes: _group?.analyticsAttributes);
    showDialog(
        context: context,
        builder: (context) => _buildConfirmationDialog(
            confirmationTextMsg: _isResearchProject ? "Are you sure you want to leave this project?" : Localization().getStringEx("panel.group_detail.label.confirm.leave", "Are you sure you want to leave this group?"),
            positiveButtonLabel: Localization().getStringEx("panel.group_detail.button.leave.title", "Leave"),
            onPositiveTap: _onTapLeaveDialog));
  }

  void _onTapLeaveDialog() {
    _leaveGroup().then((value) => Navigator.pop(context));
  }

  void _onTapDeleteDialog() {
    _deleteGroup().then((succeeded) {
      Navigator.of(context).pop(); // Pop dialog
      if ((succeeded == true)) {
        Navigator.of(context).pop(); // Pop to previous panel
      } else {
        AppAlert.showDialogResult(context, _isResearchProject ? 'Failed to delete project.' : Localization().getStringEx('panel.group_detail.group.delete.failed.msg', 'Failed to delete group.'));
      }
    });
  }

  void _onWebsite() {
    Analytics().logSelect(target: 'Group url', attributes: _group?.analyticsAttributes);
    UrlUtils.launchExternal(_group?.webURL);
  }

  void _onPolicy () {
    Analytics().logSelect(target: 'Policy');
    showDialog(context: context, builder: (_) =>  InfoPopup(
      backColor: Color(0xfffffcdf), //Styles().colors.surface ?? Colors.white,
      padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 24),
      border: Border.all(color: Styles().colors.textDark, width: 1),
      alignment: Alignment.center,
      infoText: Localization().getStringEx('panel.group.detail.policy.text', 'The {{app_university}} takes pride in its efforts to support free speech and to foster inclusion and mutual respect. Users may submit a report to group administrators about obscene, threatening, or harassing content. Users may also choose to report content in violation of Student Code to the Office of the Dean of Students.').replaceAll('{{app_university}}', Localization().getStringEx('app.univerity_name', 'University of Illinois')),
      infoTextStyle: Styles().textStyles.getTextStyle('widget.description.regular.thin'),
      closeIcon: Styles().images.getImage('close-circle', excludeFromSemantics: true),
    ),);
  }

  void _onTapMembers(){
    Analytics().logSelect(target: "Group Members", attributes: _group?.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembersPanel(group: _group)));
  }

  void _onTapSettings(){
    Analytics().logSelect(target: "Group Settings", attributes: _group?.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupSettingsPanel(group: _group,))).then((exit){
      if(exit == true){
        Navigator.of(context).pop();
      }
    }
    );
  }

  void _onTapPromote() {
    Analytics().logSelect(target: "Promote Group", attributes: _group?.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => QrCodePanel.fromGroup(_group)));
  }

  void _onTapNotifications() {
    Analytics().logSelect(target: "Notifications", attributes: _group?.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMemberNotificationsPanel(groupId: _groupId, memberId: _group?.currentMember?.id)));
  }

  void _onTapReportAbuse({required GroupPostReportAbuseOptions options}) {
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

    Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => GroupPostReportAbuse(options: options, groupId: widget.group?.id)));
  }

  /*void _onTapTakeAttendance() {
    if (_memberAttendLoading) {
      return;
    }
    Analytics().logSelect(target: "Take Attendance", attributes: _group?.analyticsAttributes);
    FlutterBarcodeScanner.scanBarcode(UiColors.toHex(Styles().colors.fillColorSecondary)!,
            Localization().getStringEx('panel.group_detail.attendance.scan.cancel.button.title', 'Cancel'), true, ScanMode.QR)
        .then((scanResult) {
      _onAttendanceScanFinished(scanResult);
    });
  }

  void _onAttendanceScanFinished(String? scanResult) {
    if (scanResult == '-1') {
      // The user hit "Cancel button"
      return;
    }
    String? uin = _extractUin(scanResult);
    // There is no uin in the scanned QRcode
    if (uin == null) {
      AppAlert.showDialogResult(
          context,
          Localization()
              .getStringEx('panel.group_detail.attendance.qr_code.uin.not_valid.msg', 'This QR code does not contain valid UIN number.'));
      return;
    }
    _loadAttendedMemberByUin(uin: uin);
  }

  void _attendMember({required Member member}) {
    _setMemberAttendLoading(true);
    Groups().memberAttended(group: _group!, member: member).then((success) {
      _setMemberAttendLoading(false);
      String msg = success
          ? Localization().getStringEx('panel.group_detail.attendance.member.succeeded.msg', 'Successfully tagged member as attended.')
          : Localization()
              .getStringEx('panel.group_detail.attendance.member.failed.msg', 'Failed to tag member as attended. Please try again.');
      AppAlert.showDialogResult(context, msg);
    });
  }

  String? _getAttendedDateTimeFormatted({required Member member}) {
    DateTime? attendedUniTime = AppDateTime().getUniLocalTimeFromUtcTime(member.dateAttendedUtc);
    String? dateTimeFormatted = AppDateTime().formatDateTime(attendedUniTime, format: 'yyyy/MM/dd h:mm');
    return dateTimeFormatted;
  }*/

  ///
  /// Returns UIN number from string (uin or megTrack2), null - otherwise
  ///
  /*String? _extractUin(String? stringToCheck) {
    if (StringUtils.isEmpty(stringToCheck)) {
      return stringToCheck;
    }
    int stringSymbolsCount = stringToCheck!.length;
    final int uinNumbersCount = 9;
    final int megTrack2SymbolsCount = 28;
    // Validate UIN in format 'XXXXXXXXX'
    if (stringSymbolsCount == uinNumbersCount) {
      RegExp uinRegEx = RegExp('[0-9]{$uinNumbersCount}');
      bool uinMatch = uinRegEx.hasMatch(stringToCheck);
      return uinMatch ? stringToCheck : null;
    }
    // Validate megTrack2 in format 'AAAAXXXXXXXXXAAA=AAAAAAAAAAA' where 'XXXXXXXXX' is the UIN
    else if (stringSymbolsCount == megTrack2SymbolsCount) {
      RegExp megTrack2RegEx = RegExp('[0-9]{4}[0-9]{$uinNumbersCount}[0-9]{3}=[0-9]{11}');
      bool megTrackMatch = megTrack2RegEx.hasMatch(stringToCheck);
      if (megTrackMatch) {
        String uin = stringToCheck.substring(4, 13);
        return uin;
      } else {
        return null;
      }
    }
    return null;
  }

  void _loadAttendedMemberByUin({required String uin}) {
    Groups().loadMembers(groupId: widget.groupId).then((members) {
      Member? member;
      if (CollectionUtils.isNotEmpty(members)) {
        for (Member groupMember in members!) {
          if (groupMember.isMemberOrAdmin && (groupMember.externalId == uin)) {
            member = groupMember;
            break;
          }
        }
      }
      _onAttendedMemberLoaded(uin: uin, member: member);
    });
  }

  void _onAttendedMemberLoaded({required String uin, Member? member}) {
    if (member != null) {
      // The member already attended.
      if (_checkMemberAttended(member: member)) {
        AppAlert.showDialogResult(
            context,
            sprintf(
                Localization()
                    .getStringEx('panel.group_detail.attendance.member.attended.msg.format', 'Student with UIN "%s" already attended on "%s"'),
                [uin, _getAttendedDateTimeFormatted(member: member)]));
      }
      // Attend the member to the group
      else {
        _attendMember(member: member);
      }
    } else {
      // Do not allow a student to attend to authman group which one is not member of.
      if (_group?.authManEnabled == true) {
        AppAlert.showDialogResult(context,
          sprintf(Localization().getStringEx('panel.group_detail.attendance.authman.uin.not_member.msg', 'Student with UIN "%s" is not a member of this group and is not allowed to attend.'), [uin]));
      }
      // Create new member and attend to non-authman group
      else {
        member = Member();
        member.status = GroupMemberStatus.member;
        member.externalId = uin;
        _attendMember(member: member);
      }
    }
  }*/

  ///
  /// Returns true if member has already attended, false - otherwise
  ///
  /*bool _checkMemberAttended({required Member member}) {
    return (member.dateAttendedUtc != null);
  }

  void _setMemberAttendLoading(bool loading) {
    _memberAttendLoading = loading;
    if (mounted) {
      setState(() {});
    }
  }*/

  void _onMembershipRequest() {
    String target;
    if (_group?.researchProject != true) {
      target = "Request to join";
    }
    else if (CollectionUtils.isEmpty(_group?.questions)) {
      target = "Request to participate";
    }
    else {
      target = "Continue";
    }
    Analytics().logSelect(target: target, attributes: _group?.analyticsAttributes);
    
    if (CollectionUtils.isNotEmpty(_group?.questions)) {
      _loadMembershipRequestPanel();
    } else {
      _requestMembership();
    }
  }

  void _loadMembershipRequestPanel() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembershipRequestPanel(group: _group)));
  }

  void _requestMembership() {
      _increaseProgress();
      Groups().requestMembership(_group, null).then((succeeded) {
        _decreaseProgress();
        if (!succeeded) {
          AppAlert.showDialogResult(context, Localization().getStringEx("panel.group_detail.alert.request_failed.msg", 'Failed to send request.'));
        }
      });
  }

  void _onCancelMembershipRequest() {
    Analytics().logSelect(target: "Cancel membership request", attributes: _group?.analyticsAttributes);
    showDialog(
        context: context,
        builder: (context) => _buildConfirmationDialog(
            confirmationTextMsg: _isResearchProject ?
                "Are you sure you want to cancel your request to join this project?" :
                Localization().getStringEx("panel.group_detail.label.confirm.cancel", "Are you sure you want to cancel your request to join this group?"),
            positiveButtonLabel: Localization().getStringEx("panel.group_detail.button.dialog.cancel_request.title", "Cancel request"),
            positiveButtonFlex: 2,
            onPositiveTap: _onTapCancelMembershipDialog));
  }

  void _onTapCancelMembershipDialog() {
    _cancelMembershipRequest();
    Navigator.pop(context);
  }

  void _onTapCreateEvent(){
    Analytics().logSelect(target: "Create Event", attributes: _group?.analyticsAttributes);
    if (_group != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => Event2CreatePanel(targetGroups: [_group!],)));
    }
  }

  void _onTapBrowseEvents(){
    Analytics().logSelect(target: "Browse Events", attributes: _group?.analyticsAttributes);
    if (_group != null) {
      Event2HomePanel.present(context, eventSelector: GroupEventSelector2(_group!));
    }
  }

  void _onTapCreatePost() {
    Analytics().logSelect(target: "Create Post", attributes: _group?.analyticsAttributes);
    if (_group != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostCreatePanel(group: _group!))).then((result) {
        if (result is GroupPost) {
          if(result.isScheduled){ //Post and messages can be both scheduled, so check for scheduled first
            _scrollToLastScheduledPostsAfterRefresh = true;
            if (_refreshingScheduledPosts != true) {
              _refreshCurrentScheduledPosts();
            }
          }
          else if (result.isPost) {
            _scrollToLastPostAfterRefresh = true;
            if (_refreshingPosts != true) {
              _refreshCurrentPosts();
            }
          }
          else if (result.isMessage) {
            _scrollToLastMessageAfterRefresh = true;
            if (_refreshingMessages != true) {
              _refreshCurrentMessages();
            }
          }
        }
      });
    }
  }

  void _onTapCreatePoll() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CreatePollPanel(group: _group)));
  }

  void _onPollUpdated(String? pollId) {
    if(pollId!= null && _groupPolls!=null
        && _groupPolls?.firstWhere((element) => pollId == element.pollId) != null) { //This is Group poll

      Poll? poll = Polls().getPoll(pollId: pollId);
      if (poll != null) {
        setState(() {
          _updatePollInList(poll);
        });
      }
    }
  }

  void _updateEventIfNeeded(dynamic event) {
    if ((event is Event2) && (event.id != null) && mounted) {
      int? index = Event2.indexInList(_groupEvents, id: event.id);
      if (index != null) {
        setState(() {
          _groupEvents?[index] = event;
        });
      }
    }
  }

  Future<void> _onPullToRefresh() async {
    if (Connectivity().isOffline) {
      // Do not try to refresh group if the device is offline
      return;
    }
    if ((_group?.syncAuthmanAllowed == true) && (_group?.attendanceGroup == true)) {
      await Groups().syncAuthmanGroup(group: _group!);
    }
    Group? group = await Groups().loadGroup(widget.groupId); // The same as _refreshGroup(refreshEvents: true) but use await to show the pull to refresh progress indicator properly
    if ((group != null)) {
      if(mounted) {
        setState(() {
          _group = group;
        });
      }
      _refreshGroupAdmins();
      _refreshGroupStats();
      _refreshEvents();
      _refreshCurrentPosts();
      _refreshCurrentScheduledPosts();
      _refreshCurrentMessages();
    }
  }

  void _scheduleLastPostScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastPost();
    });
  }

  void _scrollToLastPost() {
    _scrollTo(_lastPostKey);
  }

  void _scheduleLastScheduledPostScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastScheduledPost();
    });
  }

  void _scrollToLastScheduledPost() {
    _scrollTo(_lastScheduledPostKey);
  }

  void _scheduleLastMessageScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastMessage();
    });
  }

  void _scrollToLastMessage() {
    _scrollTo(_lastMessageKey);
  }

  void _schedulePollsScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToPolls();
    });
  }

  void _scrollToPolls() {
    _scrollTo(_pollsKey);
  }

  void _scrollTo(GlobalKey? key) {
    if(key != null) {
      BuildContext? currentContext = key.currentContext;
      if (currentContext != null) {
        Scrollable.ensureVisible(currentContext, duration: Duration(milliseconds: 10));
      }
    }
  }

  void _scheduleEvalHeaderHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evalHeaderHeight();
    });
  }

  void _evalHeaderHeight() {
    RenderObject? renderBox = _headerKey.currentContext?.findRenderObject();
    Size? size = (renderBox is RenderBox) ? renderBox.size : null;
    if ((size?.height != _headerHeight) && mounted) {
      setStateIfMounted(() {
        _headerHeight = size?.height;
      });
    }
  }

  void _increaseProgress() {
    _progress++;
    if (mounted) {
      setState(() {});
    }
  }

  void _decreaseProgress() {
    _progress--;
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isLoading {
    return _progress > 0;
  }

  bool get _showMembershipBadge {
    return _isMemberOrAdmin || _isPending;
  }

  bool get _showPolicyButton {
    return _isResearchProject != true;
  }

  //Util
  void _updatePollInList(Poll? poll) {
    if ((poll != null) && (_groupPolls != null)) {
      for (int index = 0; index < _groupPolls!.length; index++) {
        if (_groupPolls![index].pollId == poll.pollId) {
          _groupPolls![index] = poll;
        }
      }
    }
  }
}

class _OfficerCard extends StatelessWidget {
  final Member? groupMember;
  
  _OfficerCard({this.groupMember});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      child: Column(children: <Widget>[
        Container(height: 144, width: 128, child: GroupMemberProfileImage(userId: groupMember?.userId)),
        Padding(padding: EdgeInsets.only(top: 4),
          child: Text(groupMember?.name ?? "", style: Styles().textStyles.getTextStyle('panel.group.detail.light.small'),),),
        Text(groupMember?.officerTitle ?? "", style:  Styles().textStyles.getTextStyle('panel.group.detail.light.regular')),
      ],),
    );
  }
}

extension GroupEvent2Selector2State on Event2Selector2State {
  bool get bindingInProgress => selectorData['binding'] == true;
  set bindingInProgress(bool value) => selectorData['binding'] = value;
}

class GroupEventSelector2 extends Event2Selector2 {
  final Group group;

  GroupEventSelector2(this.group);

  @override
  Widget? buildUI(Event2Selector2State state, { required Event2 event }) => Padding(padding: const EdgeInsets.symmetric(vertical: 16), child:
    Column(children: [
      RoundedButton(
        label: (group.researchProject == true) ?
        Localization().getStringEx('panel.explore_detail.button.add_to_project.title', 'Add Event To Project') :
        Localization().getStringEx('panel.explore_detail.button.add_to_group.title', 'Add Event To Group'),
        hint: (group.researchProject == true) ?
        Localization().getStringEx('panel.explore_detail.button.add_to_project.hint', '') :
        Localization().getStringEx('panel.explore_detail.button.add_to_group.hint', ''),
        textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
        backgroundColor: Colors.white,
        borderColor: Styles().colors.fillColorPrimary,
        progress: state.bindingInProgress,
        onTap: () => _onAddEventToGroup(state, event),
      ),
    ],)
  );

  void _onAddEventToGroup(Event2Selector2State state, Event2 event) {
    if (state.mounted) {
      state.setSelectorState((){
        state.bindingInProgress = true;
      });
      Events2().linkEventToGroup(event: event, groupId: group.id!, link: true).then((bool result) {
        if (state.mounted) {
          state.setSelectorState((){
            state.bindingInProgress = false;
          });
          if (result) {
            _finish(state);
          }
          else {
            String message = Localization().getStringEx('panel.create_event.groups.failed.msg', 'There was an error binding this event to the following groups: ') + (group.title ?? '');
            AppAlert.showDialogResult(state.context, message).then((_) {
              _finish(state);
            });
          }
        }
      });
    }
  }

  void _finish(Event2Selector2State state) {
    Navigator.of(state.context).popUntil((Route route) {
      return route.settings.name == GroupDetailPanel.routeName;
    });
  }
}
