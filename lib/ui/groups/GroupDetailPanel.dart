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
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/groups/GroupPostDetailPanel.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/groups/GroupAllEventsPanel.dart';
import 'package:illinois/ui/groups/GroupMembershipRequestPanel.dart';
import 'package:illinois/ui/groups/GroupPollListPanel.dart';
import 'package:illinois/ui/groups/GroupPostCreatePanel.dart';
import 'package:illinois/ui/groups/GroupQrCodePanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/polls/CreatePollPanel.dart';
import 'package:illinois/ui/widgets/ExpandableText.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';

import 'GroupMembersPanel.dart';
import 'GroupSettingsPanel.dart';

enum _DetailTab { Events, Posts, Polls, About }

class GroupDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {

  final Group? group;
  final String? groupIdentifier;
  final String? groupPostId;

  GroupDetailPanel({this.group, this.groupIdentifier, this.groupPostId});

  @override
 _GroupDetailPanelState createState() => _GroupDetailPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes {
    return group?.analyticsAttributes;
  }

  String? get groupId => group?.id ?? groupIdentifier;
}

class _GroupDetailPanelState extends State<GroupDetailPanel> implements NotificationsListener {

  final int          _postsPageSize = 8;

  Group?             _group;
  GroupStats?        _groupStats;
  int                _progress = 0;
  bool               _confirmationLoading = false;
  bool               _updatingEvents = false;
  int                _allEventsCount = 0;
  List<Event>?       _groupEvents;
  List<GroupPost>    _visibleGroupPosts = <GroupPost>[];
  List<Member>?      _groupAdmins;

  _DetailTab         _currentTab = _DetailTab.Events;

  GlobalKey          _lastPostKey = GlobalKey();
  bool?               _refreshingPosts;
  bool?               _loadingPostsPage;
  bool?               _hasMorePosts;
  bool?               _shouldScrollToLastAfterRefresh;

  DateTime?           _pausedDateTime;

  GlobalKey          _pollsKey = GlobalKey();
  List<Poll>?        _groupPolls;
  bool               _pollsLoading = false;

  bool               _memberAttendLoading = false;

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

  bool get _canDeleteGroup {
    return _isAdmin;
  }

  bool get _canAddEvent {
    return _isAdmin;
  }

  bool get _canCreatePost {
    return _isAdmin || (_isMember && FlexUI().isSharingAvailable);
  }

  bool get _canCreatePoll {
    return _isAdmin || ((_group?.canMemberCreatePoll ?? false) && _isMember && FlexUI().isSharingAvailable);
  }

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Groups.notifyUserMembershipUpdated,
      Groups.notifyGroupCreated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupEventsUpdated,
      Groups.notifyGroupPostsUpdated,
      Polls.notifyCreated,
      Polls.notifyStatusChanged,
      Polls.notifyVoteChanged,
      Polls.notifyResultsChanged,
      Polls.notifyLifecycleDelete,
      FlexUI.notifyChanged,
      Connectivity.notifyStatusChanged,
    ]);

    _postId = widget.groupPostId;
    _loadGroup(loadEvents: true);
  }

  @override
  void dispose() {
    super.dispose();

    NotificationService().unsubscribe(this);
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
        _redirectToPostIfExists();
        _loadGroupAdmins();
        _loadInitialPosts();
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
        _refreshPolls();
      }
    });
  }

  void _loadEvents() {
    setState(() {
      _updatingEvents = true;
    });
    Groups().loadEvents(_group, limit: 3).then((Map<int, List<Event>>? eventsMap) {
      if (mounted) {
        setState(() {
          bool hasEventsMap = CollectionUtils.isNotEmpty(eventsMap?.values);
          _allEventsCount = hasEventsMap ? eventsMap!.keys.first : 0;
          _groupEvents = hasEventsMap ? eventsMap!.values.first : null;
          _updatingEvents = false;
        });
      }
    });
  }

  void _refreshEvents() {
    Groups().loadEvents(_group, limit: 3).then((Map<int, List<Event>>? eventsMap) {
      if (mounted) {
        setState(() {
          bool hasEventsMap = CollectionUtils.isNotEmpty(eventsMap?.values);
          _allEventsCount = hasEventsMap ? eventsMap!.keys.first : 0;
          _groupEvents = hasEventsMap ? eventsMap!.values.first : null;
        });
      }
    });
  }

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

  ///
  /// Loads group post by id (if exists) and redirects to Post detail panel
  ///
  void _redirectToPostIfExists() {
    if ((_group?.id != null) && (_postId != null)) {
      _increaseProgress();
      Groups().loadGroupPost(groupId: _group!.id, postId: _postId!).then((post) {
        // Clear _postId in order not to redirect on the next group load.
        _postId = null;
        if (post != null) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostDetailPanel(group: _group, post: post)));
        }
        _decreaseProgress();
      });
    }
  }

  void _refreshCurrentPosts({int? delta}) {
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin && (_refreshingPosts != true)) {
      int limit = _visibleGroupPosts.length + (delta ?? 0);
      _refreshingPosts = true;
      Groups().loadGroupPosts(widget.groupId, offset: 0, limit: limit, order: GroupSortOrder.desc).then((List<GroupPost>? posts) {
        _refreshingPosts = false;
        if (mounted && (posts != null)) {
          setState(() {
            _visibleGroupPosts = posts;
            if (posts.length < limit) {
              _hasMorePosts = false;
            }
          });
          if (_shouldScrollToLastAfterRefresh == true) {
            _scheduleLastPostScroll();
          }
        }
        _shouldScrollToLastAfterRefresh = null;
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
    List<GroupPost>? postsPage = await Groups().loadGroupPosts(widget.groupId, offset: _visibleGroupPosts.length, limit: _postsPageSize, order: GroupSortOrder.desc);
    if (postsPage != null) {
      _visibleGroupPosts.addAll(postsPage);
      if (postsPage.length < _postsPageSize) {
        _hasMorePosts = false;
      }
    }
  }

  Future<void> _loadPolls() async {
    String? groupId = _group?.id;
    if (StringUtils.isNotEmpty(groupId) && _group!.currentUserIsMemberOrAdmin) {
      _setPollsLoading(true);
      Polls().getGroupPolls(groupIds: {groupId!})!.then((result) {
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
    return Groups().deleteGroup(_group?.id).whenComplete(() {
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
    Widget content;
    if (_isLoading) {
      content = _buildLoadingContent();
    }
    else if (_group != null) {
      content = _buildGroupContent();
    }
    else {
      content = _buildErrorContent();
    }

    bool optionsMenuVisible = _canLeaveGroup || _canDeleteGroup || _canCreatePost;
    return Scaffold(
        appBar: AppBar(leading: HeaderBackButton(), actions: [
          Visibility(
              visible: optionsMenuVisible,
              child: Semantics(
                  label: Localization().getStringEx("panel.group_detail.label.options", 'Options'),
                  button: true,
                  excludeSemantics: true,
                  child: IconButton(
                    icon: Image.asset(
                      'images/groups-more-inactive.png',
                    ),
                    onPressed: _onGroupOptionsTap,
                  )))
        ]),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar(),
        body: RefreshIndicator(
          onRefresh: _onPullToRefresh,
          child: content,
        ),);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Groups.notifyUserMembershipUpdated) {
      setStateIfMounted(() {});
    }
    else if (name == Groups.notifyGroupEventsUpdated) {
      _loadEvents();
    }
    else if (param == widget.groupId && (name == Groups.notifyGroupCreated || name == Groups.notifyGroupUpdated)) {
      _loadGroup(loadEvents: true);
    } 
    else if (name == Groups.notifyGroupPostsUpdated) {
      _refreshCurrentPosts(delta: param is int ? param : null);
    } 
    else if ((name == Polls.notifyCreated)
             || (name == Polls.notifyLifecycleDelete)) {
      _refreshPolls();
    } 
    else if (name == Polls.notifyVoteChanged
            || name == Polls.notifyResultsChanged 
            || name == Polls.notifyStatusChanged) {
      _onPollUpdated(param); // Deep collection update single element (do not reload whole list)
    } 
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
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

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
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
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), ),
          ),
        ),
      ]),
      SafeArea(
        child: HeaderBackButton()
      ),
    ],);
  }

  Widget _buildErrorContent() {
    return Stack(children: <Widget>[
      Column(children: <Widget>[
        Expanded(
          child: Center(
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(Localization().getStringEx("panel.group_detail.label.error_message", 'Failed to load group data.'),  style:  Styles().getTextStyle('widget.message.large'),)
            ),
          ),
        ),
      ]),
      SafeArea(
        child: HeaderBackButton()
      ),
    ],);
  }

  Widget _buildGroupContent() {
    List<Widget> content = [
      _buildImageHeader(),
      _buildGroupInfo()
    ];
    if (_isMemberOrAdmin) {
      content.add(_buildTabs());
      if (_currentTab != _DetailTab.About) {
        content.add(_buildEvents());
        content.add(_buildPosts());
        content.add(_buildPolls());
      }
      else if (_currentTab == _DetailTab.About) {
        content.add(_buildAbout());
        content.add(_buildPrivacyDescription());
        content.add(_buildAdmins());
      }
    }
    else {
      content.add(_buildAbout());
      content.add(_buildPrivacyDescription());
      content.add(_buildAdmins());
      if (_isPublic) {
        content.add(_buildEvents());
      }
    }

    return
        Column(children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: content,
              ),
            ),
          ),
          _buildMembershipRequest(),
          _buildCancelMembershipRequest(),
        ],
      );
  }

  Widget _buildImageHeader(){
    return Container(height: 200, color: Styles().colors?.background, child:
      Stack(alignment: Alignment.bottomCenter, children: <Widget>[
          StringUtils.isNotEmpty(_group?.imageURL) ?  Positioned.fill(child: Image.network(_group!.imageURL!, excludeFromSemantics: true, fit: BoxFit.cover, headers: Config().networkAuthHeaders)) : Container(),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors?.fillColorSecondaryTransparent05, horzDir: TriangleHorzDirection.leftToRight), child:
            Container(height: 53,),
          ),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors?.white), child:
            Container(height: 30,),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfo() {
    List<Widget> commands = [];

    String members;
    int membersCount = _groupStats?.activeMembersCount ?? 0;
    if (membersCount == 0) {
      members = Localization().getStringEx("panel.group_detail.members.count.empty", "No Current Members");
    }
    else if (membersCount == 1) {
      members = Localization().getStringEx("panel.group_detail.members.count.one", "1 Current Member");
    }
    else {
      members = sprintf(Localization().getStringEx("panel.group_detail.members.count.format", "%s Current Members"),[membersCount]);
    }

    int pendingCount = _groupStats?.pendingCount ?? 0;
    String pendingMembers;
    if (_group!.currentUserIsAdmin && pendingCount > 0) {
      pendingMembers = pendingCount > 1 ?
        sprintf(Localization().getStringEx("panel.group_detail.pending_members.count.format", "%s Pending Members"), [pendingCount]) :
        Localization().getStringEx("panel.group_detail.pending_members.count.one", "1 Pending Member");
    }
    else {
      pendingMembers = "";
    }

    int attendedCount = _groupStats?.attendedCount ?? 0;
    String? attendedMembers;
    if (_group!.currentUserIsAdmin && (_group!.attendanceGroup == true)) {
      if (attendedCount == 0) {
        attendedMembers = Localization().getStringEx("panel.group_detail.attended_members.count.empty", "No Members Attended");
      } else if (attendedCount == 1) {
        attendedMembers = Localization().getStringEx("panel.group_detail.attended_members.count.one", "1 Member Attended");
      } else {
        attendedMembers =
            sprintf(Localization().getStringEx("panel.group_detail.attended_members.count.format", "%s Members Attended"), [attendedCount]);
      }
    }

    if (_isMemberOrAdmin) {
      if(_isAdmin) {
        commands.add(RibbonButton(
          label: Localization().getStringEx("panel.group_detail.button.manage_members.title", "Manage Members"),
          hint: Localization().getStringEx("panel.group_detail.button.manage_members.hint", ""),
          leftIconAsset: 'images/icon-member.png',
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
          onTap: _onTapMembers,
        ));
        commands.add(Container(height: 1, color: Styles().colors!.surfaceAccent,));
        commands.add(RibbonButton(
          label: Localization().getStringEx("panel.group_detail.button.group_settings.title", "Group Settings"),
          hint: Localization().getStringEx("panel.group_detail.button.group_settings.hint", ""),
          leftIconAsset: 'images/icon-gear.png',
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
          onTap: _onTapSettings,
        ));
        commands.add(Container(height: 1, color: Styles().colors!.surfaceAccent));
        commands.add(RibbonButton(
          label: Localization().getStringEx("panel.group_detail.button.group_promote.title", "Promote this group"),
          hint: Localization().getStringEx("panel.group_detail.button.group_promote.hint", ""),
          leftIconAsset: 'images/icon-qr-code.png',
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
          onTap: _onTapPromote,
        ));
        if (_group?.attendanceGroup == true) {
          commands.add(Container(height: 1, color: Styles().colors!.surfaceAccent));
          commands.add(Stack(alignment: Alignment.center, children: [
            RibbonButton(
            label: Localization().getStringEx("panel.group_detail.button.take_attendance.title", "Take Attendance"),
            hint: Localization().getStringEx("panel.group_detail.button.take_attendance.hint", ""),
            leftIconAsset: 'images/icon-qr-code.png',
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
            onTap: _onTapTakeAttendance,
          ),
          Visibility(
                visible: _memberAttendLoading, child: CircularProgressIndicator(color: Styles().colors!.fillColorSecondary, strokeWidth: 2))
          ]));
        }
      }
      if (StringUtils.isNotEmpty(_group?.webURL)) {
        commands.add(Container(height: 1, color: Styles().colors!.surfaceAccent));
        commands.add(_buildWebsiteLink());
      }
    }
    else {
      if (StringUtils.isNotEmpty(_group?.webURL)) {
        commands.add(_buildWebsiteLink());
      }

      String? tags = _group?.displayTags;
      if (StringUtils.isNotEmpty(tags)) {
        if (commands.isNotEmpty) {
          commands.add(Container(height: 12,));
        }
        commands.add(_buildTags(tags));
      }
    }

    return Container(color: Colors.white, child:
      Stack(children: <Widget>[
        Padding(padding: EdgeInsets.only(top: 12), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: EdgeInsets.only(left: 16) /* the Policy button takes vertical and right space */, child:
                _buildBadgeOrCategoryWidget(),
              ),

              Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
                Text(_group?.title ?? '',  style:  Styles().getTextStyle('panel.group.title.lage'),),
              ),
              
              GestureDetector(onTap: () => { if (_isMember) {_onTapMembers()} }, child:
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
                  Container(decoration: (_isMember ? BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors!.fillColorSecondary!, width: 2))) : null), child:
                    Text(members, style:  Styles().getTextStyle('panel.group.detail.fat'))
                  ),
                ),
              ),
              
              Visibility(visible: StringUtils.isNotEmpty(pendingMembers), child:
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
                  Text(pendingMembers,  style: Styles().getTextStyle('panel.group.detail.fat') ,)
                ),
              ),

              Visibility(visible: StringUtils.isNotEmpty(attendedMembers), child:
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
                  Text(StringUtils.ensureNotEmpty(attendedMembers), style: Styles().getTextStyle('panel.group.detail.fat'),)
                ),
              ),
              
              Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
                Column(children: commands,),),
            ],),
          ),
        ],),
      );
  }

  Widget _buildTabs() {
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
        case _DetailTab.Polls:
          title = Localization().getStringEx("panel.group_detail.button.polls.title", 'Polls');
          break;
        case _DetailTab.About:
          title = Localization().getStringEx("panel.group_detail.button.about.title", 'About');
          break;
      }
      bool isSelected = (_currentTab == tab);

      if (0 < tabs.length) {
        tabs.add(Padding(
          padding: EdgeInsets.only(left: 6),
          child: Container(),
        ));
      }

      Widget tabWidget = RoundedButton(
          label: title,
          backgroundColor: isSelected ? Styles().colors!.fillColorPrimary : Styles().colors!.background,
          textColor: (isSelected ? Colors.white : Styles().colors!.fillColorPrimary),
          fontFamily: isSelected ? Styles().fontFamilies!.bold : Styles().fontFamilies!.regular,
          fontSize: 16,
          contentWeight: 0.0,
          borderColor: isSelected ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,
          borderWidth: 1,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          onTap: () => _onTab(tab));

      tabs.add(tabWidget);
    }

    Widget leaveButton = GestureDetector(
        onTap: _onTapLeave,
        child: Padding(
            padding: EdgeInsets.only(left: 24, top: 10, bottom: 10),
            child: Text(Localization().getStringEx("panel.group_detail.button.leave.title", 'Leave'),
                style: Styles().getTextStyle('panel.group.button.leave.title')
            )));

    return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: tabs)),
      Visibility(visible: _canLeaveGroup, child: Padding(padding: EdgeInsets.only(top: 5), child: Row(children: [Expanded(child: Container()), leaveButton])))
    ]));
  }

  Widget _buildEvents() {
    List<Widget> content = [];

//    if (_isAdmin) {
//      content.add(_buildAdminEventOptions());
//    }

    if (CollectionUtils.isNotEmpty(_groupEvents)) {
      for (Event? groupEvent in _groupEvents!) {
        content.add(GroupEventCard(groupEvent: groupEvent, group: _group));
      }

      content.add(Padding(padding: EdgeInsets.only(top: 16), child:
        RoundedButton(
          label: Localization().getStringEx("panel.group_detail.button.all_events.title", 'See all events'),
          backgroundColor: Styles().colors!.white,
          textColor: Styles().colors!.fillColorPrimary,
          fontFamily: Styles().fontFamilies!.bold,
          fontSize: 16,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          borderColor: Styles().colors!.fillColorSecondary,
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
            titleIconAsset: 'images/icon-calendar.png',
            rightIconAsset: _canAddEvent ? "images/icon-add-20x18.png" : null,
            rightIconAction: _canAddEvent ? _onTapEventOptions : null,
            rightIconLabel: _canAddEvent ? Localization().getStringEx("panel.group_detail.button.create_event.title", "Create Event") : null,
            children: content)
      ]),
      _updatingEvents
          ? Center(child:
              Container(padding: EdgeInsets.symmetric(vertical: 50), child:
                CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary)),
              ),
            )
          : Container()
    ]);
  }

  Widget _buildPosts() {
    List<Widget> postsContent = [];

    if (CollectionUtils.isEmpty(_visibleGroupPosts)) {
      if (_isMemberOrAdmin) {
        Column(children: <Widget>[
          SectionSlantHeader(
              title: Localization().getStringEx("panel.group_detail.label.posts", 'Posts'),
              titleIconAsset: 'images/icon-calendar.png',
              rightIconAsset: _canCreatePost ? "images/icon-add-20x18.png" : null,
              rightIconAction: _canCreatePost ? _onTapCreatePost : null,
              rightIconLabel: _canCreatePost ? Localization().getStringEx("panel.group_detail.button.create_post.title", "Create Post") : null,
              children: postsContent)
        ]);
      } else {
        return Container();
      }
    }

    for (int i = 0; i <_visibleGroupPosts.length ; i++) {
      GroupPost? post = _visibleGroupPosts[i];
      if (i > 0) {
        postsContent.add(Container(height: 16));
      }
      postsContent.add(GroupPostCard(key: (i == 0) ? _lastPostKey : null, post: post, group: _group, onImageTap: (){_showModalImage(post.imageUrl);}));
    }

    if ((_group != null) && _group!.currentUserIsMemberOrAdmin && (_hasMorePosts != false) && (0 < _visibleGroupPosts.length)) {
      String title = Localization().getStringEx('panel.group_detail.button.show_older.title', 'Show older');
      postsContent.add(Container(padding: EdgeInsets.only(top: 16),
        child: Semantics(label: title, button: true, excludeSemantics: true,
          child: InkWell(onTap: _loadNextPostsPage,
              child: Container(height: 36,
                child: Align(alignment: Alignment.topCenter,
                  child: (_loadingPostsPage == true) ?
                  SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorPrimary), )) :
                  Text(title, style: Styles().getTextStyle('panel.group.button.show_older.title'),),
                ),
              )
          )
      ))
      );
    }

    return Column(children: <Widget>[
      SectionSlantHeader(
          title: Localization().getStringEx("panel.group_detail.label.posts", 'Posts'),
          titleIconAsset: 'images/icon-calendar.png',
          rightIconAsset: _canCreatePost ? "images/icon-add-20x18.png" : null,
          rightIconAction: _canCreatePost ? _onTapCreatePost : null,
          rightIconLabel: _canCreatePost ? Localization().getStringEx("panel.group_detail.button.create_post.title", "Create Post") : null,
          children: postsContent)
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
                backgroundColor: Styles().colors!.white,
                textColor: Styles().colors!.fillColorPrimary,
                fontFamily: Styles().fontFamilies!.bold,
                fontSize: 16,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                borderColor: Styles().colors!.fillColorSecondary,
                borderWidth: 2,
                contentWeight: 0.5,
                onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPollListPanel(group: _group!))))));
      }
    }

    return Stack(key: _pollsKey, children: [
      Column(children: <Widget>[
        SectionSlantHeader(
            title: Localization().getStringEx('panel.group_detail.label.polls', 'Polls'),
            titleIconAsset: 'images/icon-calendar.png',
            rightIconAsset: _canCreatePoll? 'images/icon-add-20x18.png' : null,
            rightIconAction: _canCreatePoll? _onTapCreatePoll : null,
            rightIconLabel: _canCreatePoll? Localization().getStringEx('panel.group_detail.button.create_poll.title', 'Create Poll') : null,
            children: pollsContentList)
      ]),
      _pollsLoading
          ? Center(
              child: Container(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary))))
          : Container()
    ]);
  }

  Widget _buildAbout() {
    String description = _group?.description ?? '';
    return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(padding: EdgeInsets.only(bottom: 4), child:
          Text( Localization().getStringEx("panel.group_detail.label.about_us",  'About us'), style: Styles().getTextStyle('panel.group.detail.fat'), ),),
        ExpandableText(description,
          textStyle: Styles().getTextStyle('panel.group.detail.regular'),
          trimLinesCount: 4,
          readMoreIcon: Image.asset('images/icon-down-orange.png', color: Styles().colors!.fillColorPrimary, excludeFromSemantics: true),),
      ],),);
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
    
    return (StringUtils.isNotEmpty(title) && StringUtils.isNotEmpty(description)) ?
      Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: EdgeInsets.only(bottom: 4), child:
            Text(title!, style:  Styles().getTextStyle('panel.group.detail.fat'), ),),
          Text(description!, style: Styles().getTextStyle('panel.group.detail.regular'), ),
        ],),) :
      Container(width: 0, height: 0);
  }

  Widget _buildWebsiteLink() {
    return RibbonButton(
      label: Localization().getStringEx("panel.group_detail.button.website.title", 'Website'),
      rightIconAsset: 'images/external-link.png',
      leftIconAsset: 'images/globe.png',
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
      onTap: _onWebsite
    );
  }

  Widget _buildTags(String? tags) {
    return Padding(padding: EdgeInsets.symmetric(vertical: 4), child:
      Row(children: [
        Expanded(child:
          RichText(text:
            TextSpan(style: Styles().getTextStyle('panel.group.detail.tag.heading'), children: <TextSpan>[
              TextSpan(text: Localization().getStringEx("panel.group_detail.label.tags", "Group Tags: ")),
              TextSpan(text: tags ?? '', style: Styles().getTextStyle('anel.group.detail.tag.title')),
            ],),
          )
        )
      ],),
    );
  }

  Widget _buildBadgeOrCategoryWidget() {
    return _showMembershipBadge ?
      Row(children: <Widget>[
        Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _group!.currentUserStatusColor, borderRadius: BorderRadius.all(Radius.circular(2)),), child:
          Center(child:
            Semantics(label: _group?.currentUserStatusText?.toLowerCase(), excludeSemantics: true, child:
              Text(_group!.currentUserStatusText!.toUpperCase(), style:  Styles().getTextStyle('widget.heading.small'),)
            ),
          ),
        ),
        Expanded(child: Container(),),
        _buildPolicyButton(),
      ],) :
    
      Row(children: <Widget>[
        Expanded(child:
          Text(_group?.category?.toUpperCase() ?? '', style:  Styles().getTextStyle('widget.title.small'),),
        ),
        _buildPolicyButton(),
      ],);
  }

  Widget _buildPolicyButton() {
    return Semantics(button: true, excludeSemantics: true,
      label: Localization().getStringEx('panel.group_detail.button.policy.label', 'Policy'),
      hint: Localization().getStringEx('panel.group_detail.button.policy.hint', 'Tap to ready policy statement'),
      child: InkWell(onTap: _onPolicy, child:
        Padding(padding: EdgeInsets.all(16), child:
          Image.asset('images/icon-info-orange.png')
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
    return Stack(children: [
      Container(
          height: 112,
          color: Styles().colors!.backgroundVariant,
          child: Column(children: [
            Container(height: 80),
            Container(height: 32, child: CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.background), child: Container()))
          ])),
      Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(Localization().getStringEx("panel.group_detail.label.admins", 'Admins'),
                    style:   Styles().getTextStyle('widget.title.large'))),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: content))
          ]))
    ]);
  }

  Widget _buildMembershipRequest() {
    return
      Auth2().isOidcLoggedIn && _group!.currentUserCanJoin
          ? Container(color: Colors.white,
              child: Padding(padding: EdgeInsets.all(16),
                  child: RoundedButton(label: Localization().getStringEx("panel.group_detail.button.request_to_join.title",  'Request to join'),
                    backgroundColor: Styles().colors!.white,
                    textColor: Styles().colors!.fillColorPrimary,
                    fontFamily: Styles().fontFamilies!.bold,
                    fontSize: 16,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    borderColor: Styles().colors!.fillColorSecondary,
                    borderWidth: 2,
                    onTap:() { _onMembershipRequest();  }
                  ),
              ),
            )
          : Container();
  }

  Widget _buildCancelMembershipRequest() {
    return
      Auth2().isOidcLoggedIn && _group!.currentUserIsPendingMember
          ? Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.white,
                  child: Padding(padding: EdgeInsets.all(16),
                    child: RoundedButton(label: Localization().getStringEx("panel.group_detail.button.cancel_request.title",  'Cancel Request'),
                        backgroundColor: Styles().colors!.white,
                        textColor: Styles().colors!.fillColorPrimary,
                        fontFamily: Styles().fontFamilies!.bold,
                        fontSize: 16,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        borderColor: Styles().colors!.fillColorSecondary,
                        borderWidth: 2,
                        onTap:() { _onCancelMembershipRequest();  }
                    ),
                  )),
              _confirmationLoading ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), ) : Container(),
            ],
          )
          : Container();
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
        backgroundColor: Styles().colors!.fillColorPrimary,
        child: StatefulBuilder(builder: (context, setStateEx) {
          return Padding(
              padding: EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Text(confirmationTextMsg!,
                        textAlign: TextAlign.left, style:  Styles().getTextStyle('widget.dialog.message.medium'))),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                  Expanded(flex: leftAreaFlex, child: Container()),
                  Expanded(flex: negativeButtonFlex, child: RoundedButton(
                      label: StringUtils.ensureNotEmpty(negativeButtonLabel, defaultValue: Localization().getStringEx("panel.group_detail.button.back.title", "Back")),
                      fontFamily: "ProximaNovaRegular",
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.white,
                      backgroundColor: Styles().colors!.white,
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      onTap: () {
                        Analytics().logAlert(text: confirmationTextMsg, selection: negativeButtonLabel);
                        Navigator.pop(context);
                      }),),
                  Container(width: 16),
                  Expanded(flex: positiveButtonFlex, child: RoundedButton(
                    label: positiveButtonLabel ?? '',
                    fontFamily: "ProximaNovaBold",
                    textColor: Styles().colors!.fillColorPrimary,
                    borderColor: Styles().colors!.white,
                    backgroundColor: Styles().colors!.white,
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

  void _showModalImage(String? url){
    Analytics().logSelect(target: "Image", attributes: _group?.analyticsAttributes);
    if (url != null) {
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => ModalImagePanel(imageUrl: url, onCloseAnalytics: () => Analytics().logSelect(target: "Close Image", attributes: _group?.analyticsAttributes))));
    }
  }

  void _onGroupOptionsTap() {
    Analytics().logSelect(target: 'Group Options', attributes: _group?.analyticsAttributes);
    int membersCount = _groupStats?.activeMembersCount ?? 0;
    String? confirmMsg = (membersCount > 1)
        ? sprintf(
            Localization().getStringEx(
                "panel.group_detail.members_count.group.delete.confirm.msg", "This group has %d members. Are you sure you want to delete this group?"),
            [membersCount])
        : Localization().getStringEx("panel.group_detail.group.delete.confirm.msg", "Are you sure you want to delete this group?");

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
                    visible: _canCreatePost,
                    child: RibbonButton(
                        leftIconAsset: "images/icon-add-20x18.png",
                        label: Localization().getStringEx("panel.group_detail.button.create_post.title", "Create Post"),
                        onTap: () {
                          Navigator.of(context).pop();
                          _onTapCreatePost();
                        })),
                Visibility(
                    visible: _canLeaveGroup,
                    child: RibbonButton(
                        leftIconAsset: "images/icon-leave-group.png",
                        label: Localization().getStringEx("panel.group_detail.button.leave_group.title", "Leave group"),
                        onTap: () {
                          Analytics().logSelect(target: "Leave group", attributes: _group?.analyticsAttributes);
                          showDialog(
                              context: context,
                              builder: (context) => _buildConfirmationDialog(
                                  confirmationTextMsg:
                                      Localization().getStringEx("panel.group_detail.label.confirm.leave", "Are you sure you want to leave this group?"),
                                  positiveButtonLabel: Localization().getStringEx("panel.group_detail.button.leave.title", "Leave"),
                                  onPositiveTap: _onTapLeaveDialog)).then((value) => Navigator.pop(context));
                        })),
                Visibility(
                    visible: _canEditGroup,
                    child: RibbonButton(
                        leftIconAsset: "images/icon-gear.png",
                        label: Localization().getStringEx("panel.group_detail.button.group.edit.title", "Group Settings"),
                        onTap: () {
                          Navigator.pop(context);
                          _onTapSettings();
                        })),
                Visibility(
                    visible: _canDeleteGroup,
                    child: RibbonButton(
                        leftIconAsset: "images/icon-delete-group.png",
                        label: Localization().getStringEx("panel.group_detail.button.group.delete.title", "Delete group"),
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
                Visibility(
                    visible: _canAddEvent,
                    child: RibbonButton(
                        leftIconAsset: "images/icon-edit.png",
                        label: Localization().getStringEx("panel.group_detail.button.group.add_event.title", "Add existing event"),
                        onTap: (){
                          Navigator.pop(context);
                          _onTapBrowseEvents();
                        })),
                Visibility(
                    visible: _canAddEvent,
                    child: RibbonButton(
                        leftIconAsset: "images/icon-edit.png",
                        label: Localization().getStringEx("panel.group_detail.button.group.create_event.title", "Create new event"),
                        onTap: (){
                          Navigator.pop(context);
                          _onTapCreateEvent();
                        })),
              ]));
        });
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
                        leftIconAsset: "images/icon-edit.png",
                        label: Localization().getStringEx("panel.group_detail.button.group.add_event.title", "Add existing event"),
                        onTap: (){
                          Navigator.pop(context);
                          _onTapBrowseEvents();
                        })),
                Visibility(
                    visible: _canAddEvent,
                    child: RibbonButton(
                        leftIconAsset: "images/icon-edit.png",
                        label: Localization().getStringEx("panel.group_detail.button.group.create_event.title", "Create new event"),
                        onTap: (){
                          Navigator.pop(context);
                          _onTapCreateEvent();
                        })),
              ]));
        });
  }

  void _onTab(_DetailTab tab) {
    Analytics().logSelect(target: "Tab: $tab", attributes: _group?.analyticsAttributes);
    if (_currentTab != tab) {
      setState(() {
        _currentTab = tab;
      });

      switch (_currentTab) {
        case _DetailTab.Posts:
          if (CollectionUtils.isNotEmpty(_visibleGroupPosts)) {
            _scheduleLastPostScroll();
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
            confirmationTextMsg: Localization().getStringEx("panel.group_detail.label.confirm.leave", "Are you sure you want to leave this group?"),
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
        AppAlert.showDialogResult(context, Localization().getStringEx('panel.group_detail.group.delete.failed.msg', 'Failed to delete group.'));
      }
    });
  }

  void _onWebsite() {
    Analytics().logSelect(target: 'Group url', attributes: _group?.analyticsAttributes);
    String? url = _group?.webURL;
    if (StringUtils.isNotEmpty(url)) {
      Uri? uri = Uri.tryParse(url!);
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }

  void _onPolicy () {
    Analytics().logSelect(target: 'Policy');
    showDialog(context: context, builder: (_) =>  InfoPopup(
      backColor: Color(0xfffffcdf), //Styles().colors?.surface ?? Colors.white,
      padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 24),
      border: Border.all(color: Styles().colors!.textSurface!, width: 1),
      alignment: Alignment.center,
      infoText: Localization().getStringEx('panel.group.detail.policy.text', 'The {{app_university}} takes pride in its efforts to support free speech and to foster inclusion and mutual respect. Users may submit a report to group administrators about obscene, threatening, or harassing content. Users may also choose to report content in violation of Student Code to the Office of the Dean of Students.').replaceAll('{{app_university}}', Localization().getStringEx('app.univerity_name', 'University of Illinois')),
      infoTextStyle: Styles().getTextStyle('widget.description.regular"'),
      closeIcon: Image.asset('images/close-orange-small.png'),
    ),);
  }

  void _onTapMembers(){
    Analytics().logSelect(target: "Group Members", attributes: _group?.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembersPanel(group: _group)));
  }

  void _onTapSettings(){
    Analytics().logSelect(target: "Group Settings", attributes: _group?.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupSettingsPanel(group: _group,)));
  }

  void _onTapPromote() {
    Analytics().logSelect(target: "Promote Group", attributes: _group?.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupQrCodePanel(group: _group)));
  }

  void _onTapTakeAttendance() {
    if (_memberAttendLoading) {
      return;
    }
    Analytics().logSelect(target: "Take Attendance", attributes: _group?.analyticsAttributes);
    FlutterBarcodeScanner.scanBarcode(UiColors.toHex(Styles().colors!.fillColorSecondary!)!,
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
  }

  ///
  /// Returns UIN number from string (uin or megTrack2), null - otherwise
  ///
  String? _extractUin(String? stringToCheck) {
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
        AppAlert.showDialogResult(
            context,
            sprintf(
                Localization().getStringEx('panel.group_detail.attendance.authman.uin.not_member.msg',
                    'Student with UIN "%s" is not a member of this group and is not allowed to attend.'),
                [uin]));
      }
      // Create new member and attend to non-authman group
      else {
        member = Member();
        member.status = GroupMemberStatus.member;
        member.externalId = uin;
        _attendMember(member: member);
      }
    }
  }

  ///
  /// Returns true if member has already attended, false - otherwise
  ///
  bool _checkMemberAttended({required Member member}) {
    return (member.dateAttendedUtc != null);
  }

  void _setMemberAttendLoading(bool loading) {
    _memberAttendLoading = loading;
    if (mounted) {
      setState(() {});
    }
  }

  void _onMembershipRequest() {
    Analytics().logSelect(target: "Request to join", attributes: _group?.analyticsAttributes);
    if (CollectionUtils.isNotEmpty(_group?.questions)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembershipRequestPanel(group: _group)));
    } else {
      _requestMembership();
    }
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
            confirmationTextMsg:
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEventPanel(group: _group,)));
  }

  void _onTapBrowseEvents(){
    Analytics().logSelect(target: "Browse Events", attributes: _group?.analyticsAttributes);
    Navigator.push(context, MaterialPageRoute(builder: (context) => ExplorePanel(browseGroupId: _group?.id, initialFilter: ExploreFilter(type: ExploreFilterType.event_time, selectedIndexes: {0/*Upcoming*/} ),)));
  }

  void _onTapCreatePost() {
    Analytics().logSelect(target: "Create Post", attributes: _group?.analyticsAttributes);
    if (_group != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostCreatePanel(group: _group!))).then((result) {
        if (_refreshingPosts != true) {
          _refreshCurrentPosts();
        }
        if (result == true) {
          _shouldScrollToLastAfterRefresh = true;
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Container(height: 144, width: 128, child: GroupMemberProfileImage(userId: groupMember?.userId)),
        Padding(padding: EdgeInsets.only(top: 4),
          child: Text(groupMember?.name ?? "", style: Styles().getTextStyle('widget.card.title.small'),),),
        Text(groupMember?.officerTitle ?? "", style:  Styles().getTextStyle('widget.card.detail.regular')),
      ],),
    );
  }
}