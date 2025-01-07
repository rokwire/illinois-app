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

import 'dart:async';
import 'dart:typed_data';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/groups/GroupMemberNotificationsPanel.dart';
import 'package:illinois/ui/groups/GroupPostDetailPanel.dart';
import 'package:illinois/ui/groups/GroupPostReportAbuse.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';
import 'package:illinois/ui/widgets/QrCodePanel.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/ext/Social.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ui/groups/GroupAllEventsPanel.dart';
import 'package:illinois/ui/groups/GroupMembershipRequestPanel.dart';
import 'package:illinois/ui/groups/GroupPollListPanel.dart';
import 'package:illinois/ui/groups/GroupPostCreatePanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/polls/CreatePollPanel.dart';
import 'package:illinois/ui/widgets/ExpandableText.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

import 'GroupMembersPanel.dart';
import 'GroupSettingsPanel.dart';

enum _DetailTab {Events, Posts, Scheduled, Messages, Polls, About }

class GroupDetailPanel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'group_detail_content_panel';

  static const String notifyRefresh  = "edu.illinois.rokwire.group_detail.refresh";

  final Group? group;
  final String? groupIdentifier;
  final String? groupPostId;
  final AnalyticsFeature? _analyticsFeature;

  GroupDetailPanel({this.group, this.groupIdentifier, this.groupPostId, AnalyticsFeature? analyticsFeature}) :
    _analyticsFeature = analyticsFeature;

  @override
 _GroupDetailPanelState createState() => _GroupDetailPanelState();

  @override
  AnalyticsFeature? get analyticsFeature => _analyticsFeature ?? _defaultAnalyticsFeature;

  @override
  Map<String, dynamic>? get analyticsPageAttributes =>
    group?.analyticsAttributes;

  String? get groupId => group?.id ?? groupIdentifier;

  AnalyticsFeature? get _defaultAnalyticsFeature => (group?.researchProject == true) ? AnalyticsFeature.ResearchProject : AnalyticsFeature.Groups;

  static List<_DetailTab> get defaultTabs => [_DetailTab.Events, _DetailTab.Posts,  _DetailTab.Scheduled, _DetailTab.Messages, _DetailTab.Polls]; //TBD extract from Groups BB
}

class _GroupDetailPanelState extends State<GroupDetailPanel> with TickerProviderStateMixin implements NotificationsListener {
  static final int          _postsPageSize = 8;
  static final int          _animationDurationInMilliSeconds = 200;

  Group?                _group;
  GroupStats?        _groupStats;
  List<Member>?   _groupMembers;
  String?                 _postId;

  List<_DetailTab>? _tabs;
  PageController? _pageController;
  TabController?  _tabController;
  StreamController _updateController = StreamController.broadcast();

  _DetailTab         _currentTab = _DetailTab.Events;

  bool               _confirmationLoading = false;
  bool               _researchProjectConsent = false;

  int                _progress = 0;
  DateTime?         _pausedDateTime;

  String? get _groupId => _group?.id;

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

  bool get _isManaged => _group?.authManEnabled ?? false;

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

  bool get _canAboutSettings => _isMemberOrAdmin;

  bool get _canNotificationSettings => _isMemberOrAdmin;

  bool get _canShareSettings =>StringUtils.isNotEmpty(_groupId);  // Even non members can share the group.

  bool get _canReportAbuse => StringUtils.isNotEmpty(_groupId);  // Even non members car report the group. Allow reporting abuse only to existing groups

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

  bool get _canManageMembers => _isAdmin;

  bool get _isResearchProject {
    return (_group?.researchProject == true);
  }

  bool get _canViewMembers {
    return _isAdmin || (_isMember && (_group?.isMemberAllowedToViewMembersInfo == true));
  }

  bool get _hasOptions =>
      _canReportAbuse || _canNotificationSettings || _canShareSettings || _canAboutSettings ||
          _canLeaveGroup || _canDeleteGroup || _canEditGroup;

  bool get _hasCreateOptions => _canCreatePost || _canCreateMessage || _canAddEvent || _canCreatePoll;

  bool get _hasIconOptionButtons => _hasOptions || _hasCreateOptions || _showPolicyIcon;

  bool get _isLoading {
    return _progress > 0;
  }

  bool get _showMembershipBadge {
    return _isMemberOrAdmin || _isPending;
  }

  bool get _showPolicyIcon {
    return _isResearchProject != true;
  }

  bool get _canShowScheduled => _isAdmin;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Connectivity.notifyStatusChanged,
      FlexUI.notifyChanged,
      Groups.notifyUserMembershipUpdated,
      Groups.notifyGroupCreated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupStatsUpdated,
    ]);
    _postId = widget.groupPostId;
    _tabs = GroupDetailPanel.defaultTabs;

    _loadGroup(loadEvents: true);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _updateController.close();
    _pageController?.dispose();
    _tabController?.dispose();
    super.dispose();
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

    String? barTitle = (_isResearchProject && !_isMemberOrAdmin) ? 'Your Invitation To Participate' : null;

    return Scaffold(
      appBar: HeaderBar(
          title: barTitle,
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
      content,
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Stack(children: <Widget>[
      Column(children: <Widget>[
        Expanded(
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary), ),
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
                child: Text(_isResearchProject ? 'Failed to load project data.' : Localization().getStringEx("panel.group_detail.label.error_message", 'Failed to load group data.'),  style:  Styles().textStyles.getTextStyle('widget.message.large.fat'),)
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
    if(_isMemberOrAdmin) {
      content.add(_buildTabs());
      content.add(_buildViewPager());
    } else {
      content.addAll(_buildNonMemberContent());
    }

    return Column(children: <Widget>[
      Expanded(child:
        SingleChildScrollView(scrollDirection: Axis.vertical, child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: content,),
        ),
      ),
      _buildMembershipRequest(),
      _buildCancelMembershipRequest(),
    ],);
  }

  List<Widget> _buildNonMemberContent(){
    List<Widget> content = [];
    content.add(_buildAbout());
    content.add(_buildPrivacyDescription());
    content.add(_buildAdmins());
    if (_isPublic /*&& CollectionUtils.isNotEmpty(_groupEvents)*/ ) { //TBD
      content.add(_GroupEventsContent(group: _group, updateController: _updateController));
    }
    content.add(_buildResearchProjectMembershipRequest());

    return content;
  }

  //Group
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
          _currentTab = _DetailTab.About; //TBD
        }
        _trimForbiddenTabs();
        _redirectToGroupPostIfExists();
        _loadGroupMembers();
        _updateController.add(GroupDetailPanel.notifyRefresh);
      }
      if (loadEvents) {
        _updateController.add(_GroupEventsContent.notifyEventsRefresh);
      }
      _decreaseProgress();
    }
  }

  void _refreshGroup({bool refreshEvents = false}) {
    Groups().loadGroup(widget.groupId).then((Group? group) {
      if (mounted && (group != null)) {
        setState(() {
          _group = group;
          _refreshGroupAdmins();
          _trimForbiddenTabs();
        });
        _updateController.add(GroupDetailPanel.notifyRefresh);
        if(refreshEvents)
          _updateController.add(_GroupEventsContent.notifyEventsRefresh);
      }
    });
  }

  void _trimForbiddenTabs(){
    if(CollectionUtils.isNotEmpty(_tabs)){ //Remove Tabs which are forbidden
      _tabs?.removeWhere((_DetailTab tab) =>
          (tab == _DetailTab.Scheduled && _canShowScheduled == false));
    }
  }

  ///
  /// Loads group post by id (if exists) and redirects to Post detail panel
  ///
  void _redirectToGroupPostIfExists() {
    if ((_groupId != null) && (_postId != null)) {
      _increaseProgress();
      Social().loadSinglePost(groupId: _group!.id, postId: _postId!).then((post) {
        _postId = null; // Clear _postId in order not to redirect on the next group load.
        _decreaseProgress();
        if (post != null) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostDetailPanel(group: _group!, post: post)));
        }
      });
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

  void _loadGroupMembers() {
    _increaseProgress();
    Groups().loadMembers(groupId: widget.groupId,).then((members) {
      _groupMembers = members;
      _decreaseProgress();
    });
  }

  void _refreshGroupAdmins() {
    Groups().loadMembers(groupId: widget.groupId).then((members) {
      _groupMembers = members;
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

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == Groups.notifyUserMembershipUpdated) {
      setStateIfMounted(() {});
    }
    else if (name == Groups.notifyGroupStatsUpdated) {
      _updateGroupStats();
    }
    else if (param == widget.groupId && (name == Groups.notifyGroupCreated || name == Groups.notifyGroupUpdated)) {
      _loadGroup(loadEvents: true);
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

  // UI elements
  Widget _buildImageHeader(){
    return StringUtils.isNotEmpty(_group?.imageURL) ? Semantics(label: "group image", hint: "Double tap to zoom", child:
      Container(height: 200, color: Styles().colors.background, child:
        Stack(alignment: Alignment.bottomCenter, children: <Widget>[
            Positioned.fill(child: ModalImageHolder(child: Image.network(_group!.imageURL!, excludeFromSemantics: true, fit: BoxFit.cover, headers: Config().networkAuthHeaders))),
            CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.fillColorSecondaryTransparent05, horzDir: TriangleHorzDirection.leftToRight), child:
              Container(height: 53,),
            ),
            CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.white), child:
              Container(height: 30,),
            ),
          ],
        ),
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
      if (CollectionUtils.isNotEmpty(commands)) {
        commands.add(Container(height: 1, color: Styles().colors.surfaceAccent));
      }
      if (StringUtils.isNotEmpty(_group?.webURL) && !_isResearchProject) {
        commands.add(Container(height: 1, color: Styles().colors.surfaceAccent));
        commands.add(_buildWebsiteLinkCommand());
      }
      commands.add(_buildPrivacyInfoWidget);
    }
    else {
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
        Padding(padding: EdgeInsets.only(left: 16, right: _hasIconOptionButtons ? 0 : 16), child:
          _buildBadgeWidget(),
        ),

        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
          _buildTitleWidget()
        ),
      ]);
    }
    else {
      contentList.addAll(<Widget>[
        Padding(padding: EdgeInsets.only(left: 16, right: _hasIconOptionButtons ? 0 : 16), child:
          _buildTitleWidget(showButtons: true),
        ),
      ]);
    }

    if (StringUtils.isNotEmpty(members)) {
      contentList.add(GestureDetector(onTap: () => { if (_canViewMembers) {_onTapMembers()} }, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
          Container(decoration: (_canViewMembers ? BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors.fillColorSecondary, width: 2))) : null), child:
            Text(members, style:  Styles().textStyles.getTextStyle('widget.title.small'))
          ),
        ),
      ));
    }

    if (StringUtils.isNotEmpty(pendingMembers)) {
      contentList.add(Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
        Text(pendingMembers,  style: Styles().textStyles.getTextStyle('widget.title.small') ,)
      ));
    }

    if (StringUtils.isNotEmpty(attendedMembers)) {
      contentList.add(Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
        Text(StringUtils.ensureNotEmpty(attendedMembers), style: Styles().textStyles.getTextStyle('widget.title.small'),)
      ));
    }

    contentList.add(Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
      Column(children: commands,),
    ));

    return Container(color: Colors.white, child:
        Padding(padding: EdgeInsets.only(top: 12), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList),
        ),
      );
  }

  Widget _buildTabs() {
    if(CollectionUtils.isEmpty(_tabs))
      return Container();

    List<Widget> tabs = [];
    for (_DetailTab tab in _tabs!) {
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
        case _DetailTab.Scheduled:
          title = Localization().getStringEx("", 'Scheduled'); //localize
          break;
      }

      Tab tabWidget = Tab(
          text: title,
          height: 35,
      );
      tabs.add(tabWidget);
    }

    if(_tabController == null || _tabController!.length != tabs.length){
      _tabController = TabController(length: tabs.length, vsync: this);
    }

    return Container(color: Colors.white, child:
      TabBar(
        tabs: tabs,
        indicatorColor: Styles().colors.fillColorSecondary,
        controller: _tabController,
        onTap:(index) => _onTab(_tabAtIndex(index)),
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 0.0),
        labelStyle: Styles().textStyles.getTextStyle("widget.title.small.fat"),
        unselectedLabelStyle: Styles().textStyles.getTextStyle("widget.title.small"),
        indicatorWeight: 4,
        tabAlignment: TabAlignment.fill,
    ));
  }

  Widget _buildViewPager(){
    List<Widget> pages = [];
    if(CollectionUtils.isNotEmpty(_tabs)){
      for (_DetailTab tab in _tabs!){
        pages.add(_buildPageFromTab(tab));
      }
    }

    if (_pageController == null) {
      _pageController = PageController(viewportFraction: 1, initialPage: _indexOfTab(_currentTab), keepPage: true, );
    }

    return
      Padding(padding: EdgeInsets.only(top: 10, bottom: 20), child:
        Container(child:
          ExpandablePageView(
            children: pages,
            controller: _pageController,
            onPageChanged: (int index){
              _tabController?.animateTo(index, duration: Duration(milliseconds: _animationDurationInMilliSeconds));
              _currentTab = _tabAtIndex(index) ?? _currentTab;
            }
          )
        )
      );
  }

  int _indexOfTab(_DetailTab tab) => _tabs?.indexOf(tab) ?? 0;
  
  _DetailTab? _tabAtIndex(int index) {
    try {
      return _tabs?.elementAt(index);
    } catch (e) {
      Log.d(e.toString());
    }
    
    return _DetailTab.Events; //TBD consider default
  }

  Widget _buildPageFromTab(_DetailTab data){
    switch(data){
      case _DetailTab.Events:
        return _GroupEventsContent(group: _group, updateController: _updateController);
      case _DetailTab.Posts:
        return _GroupPostsContent(group: _group, updateController: _updateController, groupMembers: _groupMembers);
      case _DetailTab.Messages:
        return _GroupMessagesContent(group: _group, updateController: _updateController);
      case _DetailTab.Polls:
        return _GroupPollsContent(group: _group,  updateController: _updateController);
      case _DetailTab.Scheduled:
        return _GroupScheduledPostsContent(group: _group,  updateController: _updateController);

      default: Container();
    }
    return Container();
  }

  Widget _buildAbout() {
    List<Widget> contentList = <Widget>[];

    if (!_isResearchProject) {
      contentList.add(Padding(padding: EdgeInsets.only(bottom: 4), child:
      Text(Localization().getStringEx("panel.group_detail.label.about_us",  'About us'), style: Styles().textStyles.getTextStyle('panel.group.detail.fat'), ),),
      );
    }

    if (StringUtils.isNotEmpty(_group?.description)) {
      contentList.add(ExpandableText(_group?.description ?? '',
        textStyle: Styles().textStyles.getTextStyle('panel.group.detail.regular'),
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
        Text(title!, style:  Styles().textStyles.getTextStyle('panel.group.detail.fat'), ),),
        Text(description!, style: Styles().textStyles.getTextStyle('panel.group.detail.regular'), ),
      ],),) :
    Container(width: 0, height: 0);
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
  }

  Widget _buildBadgeWidget() {
    Widget badgeWidget = Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _group!.currentUserStatusColor, borderRadius: BorderRadius.all(Radius.circular(2)),), child:
      Semantics(label: _group?.currentUserStatusText?.toLowerCase(), excludeSemantics: true, child:
        Text(_group!.currentUserStatusText!.toUpperCase(), style:  Styles().textStyles.getTextStyle('widget.heading.extra_small'),)
      ),
    );
    return _hasIconOptionButtons ? Row(children: <Widget>[
      badgeWidget,
      Expanded(child: Container(),),
      _buildTitleIconButtons
    ]) : badgeWidget;
  }

  Widget _buildTitleWidget({bool showButtons = false}) {
    return
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Expanded(child:
          RichText(textScaler: MediaQuery.of(context).textScaler,
            text: TextSpan(text: _group?.title ?? '',  style:  Styles().textStyles.getTextStyle('widget.title.medium.fat'),
              children: [
                WidgetSpan(alignment: PlaceholderAlignment.middle,
                    child: _buildManagedBadge),],))
        ),
        showButtons ? _buildTitleIconButtons : Container()
      ]);
  }

  Widget get _buildTitleIconButtons =>
      Row(crossAxisAlignment: CrossAxisAlignment.start,  mainAxisSize: MainAxisSize.min, children: [
        ...?_buildPolicyIconButton(),
        ...?_buildCreateIconButton(),
        ...?_buildSettingsIconButton()
      ]);

  Widget get _buildManagedBadge => _isManaged ?
  InkWell(onTap: _onTapManagedGroupBadge,
    child: Padding(padding: EdgeInsets.symmetric(horizontal: 6),
          child: Styles().images.getImage('group-managed-badge', excludeFromSemantics: true))):
      Container();


  Widget get _buildPrivacyInfoWidget => Padding(padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: RichText(textScaler: MediaQuery.of(context).textScaler,
            text: TextSpan(text: Localization().getStringEx("","Your activity in the app is private. Please review the "), style:  Styles().textStyles.getTextStyle("widget.title.tiny"),
            children: [
              TextSpan(text: Localization().getStringEx("", "Student Code."), style: Styles().textStyles.getTextStyle("widget.title.tiny.underline.variant"),  recognizer: TapGestureRecognizer()..onTap = () => _onPrivacy()),
              WidgetSpan(
                  child: Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: Styles().images.getImage('external-link', excludeFromSemantics: true)),
              )
            ],),
          ),
        )
      ],
    )
  );

  List<Widget>? _buildPolicyIconButton() => _showPolicyIcon ? <Widget>[
    Semantics(button: true, excludeSemantics: true,
      label: Localization().getStringEx('panel.group_detail.button.policy.label', 'Policy'),
      hint: Localization().getStringEx('panel.group_detail.button.policy.hint', 'Tap to ready policy statement'),
      child: InkWell(onTap: _onPolicy, child:
      Padding(padding: EdgeInsets.all(8), child:
      Styles().images.getImage('info', excludeFromSemantics: true)
      ),
      ),
    )] : null;

  List<Widget>? _buildSettingsIconButton() => _hasOptions ? <Widget>[
    Semantics(button: true, excludeSemantics: true,
      label: Localization().getStringEx('', 'Settings'),
      hint: Localization().getStringEx('', ''),
      child: InkWell(onTap: _onGroupOptionsTap, child:
        Padding(padding: EdgeInsets.all(8), child:
        Styles().images.getImage('more', excludeFromSemantics: true)
        ),
      ),
    )] : null;

  List<Widget>? _buildCreateIconButton() => _hasCreateOptions ? <Widget>[
    Semantics(button: true, excludeSemantics: true,
      label: Localization().getStringEx('', 'Create'),
      hint: Localization().getStringEx('', ''),
      child: InkWell(onTap: _onCreateOptionsTap, child:
      Padding(padding: EdgeInsets.all(8), child:
      Styles().images.getImage('plus-circle', excludeFromSemantics: true)
      ),
      ),
    )] : null;

  Widget _buildAdmins() {
    List<Member>? _groupAdmins = _groupMembers?.where((member) => member.isAdmin).toList();
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
                    style:   Styles().textStyles.getTextStyle('widget.title.large.extra_fat'))),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: content))
          ]))
    ]);
  }

  Widget _buildMembershipRequest() {
    if (Auth2().isOidcLoggedIn && _group!.currentUserCanJoin && (_group?.researchProject != true)) {
      return Container(decoration: BoxDecoration(color: Styles().colors.white, border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1))), child:
      Padding(padding: EdgeInsets.all(16), child:
      RoundedButton(label: Localization().getStringEx("panel.group_detail.button.request_to_join.title",  'Request to join'),
          textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
          backgroundColor: Styles().colors.white,
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
                    backgroundColor: Styles().colors.white,
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
      return Container(decoration: BoxDecoration(color: Styles().colors.white, border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1))), child:
      Padding(padding: EdgeInsets.all(16), child:
      RoundedButton(label: Localization().getStringEx("panel.group_detail.button.cancel_request.title",  'Cancel Request'),
          textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
          backgroundColor: Styles().colors.white,
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
                      borderColor: Styles().colors.white,
                      backgroundColor: Styles().colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      onTap: () {
                        Analytics().logAlert(text: confirmationTextMsg, selection: negativeButtonLabel);
                        Navigator.pop(context);
                      }),),
                  Container(width: 16),
                  Expanded(flex: positiveButtonFlex, child: RoundedButton(
                    label: positiveButtonLabel ?? '',
                    textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                    borderColor: Styles().colors.white,
                    backgroundColor: Styles().colors.white,
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


//OnTap
  void _onGroupOptionsTap() {
    Analytics().logSelect(target: 'Group Options', attributes: _group?.analyticsAttributes);
    int membersCount = _groupStats?.activeMembersCount ?? 0;
    String? confirmMsg = (membersCount > 1)
        ? sprintf(Localization().getStringEx("panel.group_detail.members_count.group.delete.confirm.msg", "This group has %d members. Are you sure you want to delete this group?"), [membersCount])
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
                    visible: _canAboutSettings,
                    child: RibbonButton(
                        leftIconKey: "info",
                        label: Localization().getStringEx("panel.group_detail.button.group.about.title", "About this group"),//TBD localize
                        onTap: () {
                          Navigator.pop(context);
                          setStateIfMounted(()=> _currentTab = _DetailTab.About);
                        })),
                Visibility(
                    visible: _canEditGroup,
                    child: RibbonButton(
                        leftIconKey: "settings",
                        label: _isResearchProject ? 'Research project settings' : Localization().getStringEx("_panel.group_detail.button.group.edit.title", "Group admin settings"),//TBD localize
                        onTap: () {
                          Navigator.pop(context);
                          _onTapSettings();
                        })),
                Visibility(
                    visible: _canManageMembers,
                    child: RibbonButton(
                        leftIconKey: "person-circle",
                        label: _isResearchProject ? 'Manage participants' : Localization().getStringEx("", "Manage members"),
                        onTap: _onTapMembers)),
                Visibility(
                    visible: _canNotificationSettings,
                    child: RibbonButton(
                        leftIconKey: "reminder",
                        label: Localization().getStringEx("panel.group_detail.button.group.notifications.title", "Notification Preferences"),//TBD localize
                        onTap: () {
                          Navigator.pop(context);
                          _onTapNotifications();
                        })),
                Visibility(
                    visible: _canShareSettings, //TBD do we restrict sharing?
                    child: RibbonButton(
                        leftIconKey: "share-nodes",
                        label: Localization().getStringEx("panel.group_detail.button.group.share.title", "Share group"),//TBD localize
                        onTap: () {
                          Navigator.pop(context);
                          _onTapShare();
                        })),
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
                Visibility(visible: _canReportAbuse, child: RibbonButton(
                  leftIconKey: "report",
                  label: Localization().getStringEx("panel.group.detail.post.button.report.students_dean.labe", "Report to Dean of Students"),
                  onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToDeanOfStudents : true)   ),
                )),
              ]));
        });
  }

  void _onCreateOptionsTap() {
    Analytics().logSelect(target: 'Group Create Options', attributes: _group?.analyticsAttributes);

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
                        leftIconKey: "plus-circle",
                        label: Localization().getStringEx("panel.group_detail.button.create_post.title", "Post"),
                        onTap: () {
                          Navigator.of(context).pop();
                          _onTapCreatePost();
                        })),
                Visibility(
                    visible: _canCreateMessage,
                    child: RibbonButton(
                        leftIconKey: "plus-circle",
                        label: Localization().getStringEx("panel.group_detail.button.create_message.title", "Message"),//localize tbd
                        onTap: () {
                          Navigator.of(context).pop();
                          _onTapCreatePost();
                        })),
                Visibility(
                    visible: _canAddEvent,
                    child: RibbonButton(
                        leftIconKey: "plus-circle",
                        label: Localization().getStringEx("_panel.group_detail.button.group.create_event.title", "New event"),
                        onTap: (){
                          Navigator.pop(context);
                          _onTapCreateEvent();
                        })),
                Visibility(
                    visible: _canAddEvent,
                    child: RibbonButton(
                        leftIconKey: "plus-circle",
                        label: Localization().getStringEx("_panel.group_detail.button.group.add_event.title", "Existing event"),//localize
                        onTap: (){
                          Navigator.pop(context);
                          _onTapBrowseEvents();
                        })),
                Visibility(
                    visible: _canCreatePoll,
                    child: RibbonButton(
                        leftIconKey: "plus-circle",
                        label: Localization().getStringEx("panel.group_detail.button.group.create_poll.title", "Poll"), //tbd localize
                        onTap: (){
                          Navigator.pop(context);
                          _onTapCreatePoll();
                        })),
              ]));
        });
  }

  void _onTab(_DetailTab? tab) {
    Analytics().logSelect(target: "Tab: $tab", attributes: _group?.analyticsAttributes);
    if (tab != null /*&& _currentTab != tab*/) {
        _currentTab = tab;

      _pageController?.animateToPage(_indexOfTab(tab), duration: Duration(milliseconds: _animationDurationInMilliSeconds), curve: Curves.linear);
    }
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
      border: Border.all(color: Styles().colors.textSurface, width: 1),
      alignment: Alignment.center,
      infoText: Localization().getStringEx('panel.group.detail.policy.text', 'The {{app_university}} takes pride in its efforts to support free speech and to foster inclusion and mutual respect. Users may submit a report to group administrators about obscene, threatening, or harassing content. Users may also choose to report content in violation of Student Code to the Office of the Dean of Students.').replaceAll('{{app_university}}', Localization().getStringEx('app.univerity_name', 'University of Illinois')),
      infoTextStyle: Styles().textStyles.getTextStyle('widget.description.regular.thin"'),
      closeIcon: Styles().images.getImage('close-circle', excludeFromSemantics: true),
    ),);
  }

  void _onPrivacy () {
    Analytics().logSelect(target: 'Privacy');
    UrlUtils.launchExternal("https://studentcode.illinois.edu");
  }

  void _onTapManagedGroupBadge(){ //TBD
    Analytics().logSelect(target: 'Managed Group Badge');
    // showDialog(context: context, builder: (_) =>  InfoPopup(
    //   backColor: Color(0xfffffcdf), //Styles().colors.surface ?? Colors.white,
    //   padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 24),
    //   border: Border.all(color: Styles().colors.textSurface, width: 1),
    //   alignment: Alignment.center,
    //   infoText: Localization().getStringEx('', 'This group is an official University of Illinois managed group. Membership is automatically populated based on various criteria.'),
    //   infoTextStyle: Styles().textStyles.getTextStyle('widget.description.regular.thin"'),
    //   closeIcon: Styles().images.getImage('close-circle', excludeFromSemantics: true),
    // ),);
    showDialog(context: context, builder: (_) =>  AlertDialog(contentPadding: EdgeInsets.zero, content:
        Container(decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.circular(10.0)), child:
          Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
            Padding(padding: EdgeInsets.all(30), child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                Styles().images.getImage('university-logo') ?? Container(),
                Padding(padding: EdgeInsets.only(top: 20), child:
                  Text(Localization().getStringEx('', 'This group is an official University of Illinois managed group. Membership is automatically populated based on various criteria.'), textAlign: TextAlign.center, style:
                    Styles().textStyles.getTextStyle("widget.detail.small")
                  )
                )
              ])
            ),
            Positioned.fill(child:
              Align(alignment: Alignment.topRight, child:
                InkWell(onTap: () => Navigator.of(context).pop(),
                  child: Padding(padding: EdgeInsets.all(16), child:
                    Styles().images.getImage("close-circle")
                  )
                )
              )
            )
          ])
        )
      )
    );
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

  void _onTapShare() {
    Analytics().logSelect(target: "Promote Group", attributes: _group?.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => QrCodePanel.fromGroup(_group)));
  }

  void _onTapNotifications() {
    Analytics().logSelect(target: "Notifications", attributes: _group?.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMemberNotificationsPanel(groupId: _groupId, memberId: _group?.currentMember?.id)));
  }

  void _onTapReportAbuse({required GroupPostReportAbuseOptions options}) {
    if (!_canReportAbuse) {
      debugPrint('Missing group id - user is not allowed to report abuse.');
      return;
    }
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

    Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => GroupPostReportAbusePanel(options: options, groupId: _groupId!)));
  }

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
      Event2HomePanel.present(context, eventSelector: GroupEventSelector2(_group!), analyticsFeature: widget.analyticsFeature);
    }
  }

  void _onTapCreatePost() {
    Analytics().logSelect(target: "Create Post", attributes: _group?.analyticsAttributes);
    if (_group != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostCreatePanel(group: _group!))).then((result) {
        if (result is Post) {
          if(result.isScheduled){
            _updateController.add(_GroupScheduledPostsContent.notifyPostsRefreshWithScrollToLast);
          }
          else if (result.isPost) {
            _updateController.add(_GroupPostsContent.notifyPostRefreshWithScrollToLast);
          }
          else if (result.isMessage) {
            _updateController.add(_GroupMessagesContent.notifyMessagesRefreshWithScrollToLast);
          }
        }
      });
    }
  }

  void _onTapCreatePoll() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CreatePollPanel(group: _group)));
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
      _trimForbiddenTabs();
      _refreshGroupAdmins();
      _refreshGroupStats();
      _updateController.add(GroupDetailPanel.notifyRefresh);
      _updateController.add(_GroupEventsContent.notifyEventsRefresh);
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
          child: Text(groupMember?.name ?? "", style: Styles().textStyles.getTextStyle('widget.card.title.small.fat'),),),
        Text(groupMember?.officerTitle ?? "", style:  Styles().textStyles.getTextStyle('widget.card.detail.regular')),
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

class _GroupEventsContent extends StatefulWidget{
  static const String notifyEventsRefresh  = "edu.illinois.rokwire.group_detail.events.refresh";

  final Group? group;
  final StreamController<dynamic>? updateController;

  const _GroupEventsContent({this.updateController, this.group});

  String get _emptyText => Localization().getStringEx("", "No group events");

  String? get groupId => group?.id;

  @override
  State<StatefulWidget> createState() => _GroupEventsState();
}

class _GroupEventsState extends State<_GroupEventsContent> with AutomaticKeepAliveClientMixin<_GroupEventsContent> implements NotificationsListener {

  List<Event2>? _groupEvents;
  bool _updatingEvents = false;

  @override
  void initState() {
    Log.d("_GroupDetailEventsState.initState");
    _initUpdateListener();
    NotificationService().subscribe(this, [
      Groups.notifyGroupEventsUpdated,
      Events2.notifyUpdated
    ]);
    _loadEvents(showProgress: true);
    super.initState();
  }

  @override
  void dispose() {
    Log.d("_GroupDetailEventsState.dispose");
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    Log.d("_GroupDetailEventsState.build");
    super.build(context);
    return _buildEvents();
  }

  //UI
  Widget _buildEvents() {
    List<Widget> content = [];

    if (CollectionUtils.isNotEmpty(_groupEvents)) {
      for (Event2 groupEvent in _groupEvents!) {
        content.add(Padding(padding: EdgeInsets.only(bottom: 16),
            child: Event2Card(groupEvent, group: widget.group,
                onTap: () => _onTapEvent(groupEvent))));
      }

      content.add(Padding(padding: EdgeInsets.only(top: 16), child:
        RoundedButton(
            label: Localization().getStringEx(
                "panel.group_detail.button.all_events.title", 'See all events'),
            textStyle: Styles().textStyles.getTextStyle(
                "widget.button.title.medium.fat"),
            backgroundColor: Styles().colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderColor: Styles().colors.fillColorSecondary,
            borderWidth: 2,
            contentWeight: 0.5,
            onTap: () {
              Navigator.push(context, CupertinoPageRoute(
                  builder: (context) => GroupAllEventsPanel(group: widget.group)));
            })
        )
      );
    }

    return Stack(children: [
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
        Column(children: <Widget>[
          Visibility(visible: CollectionUtils.isEmpty(_groupEvents) && _updatingEvents == false,
              child: _buildEmptyContent()),
          ...content
        ])),
      _updatingEvents
          ? Center(
        child: Container(padding: EdgeInsets.symmetric(vertical: 50), child:
        CircularProgressIndicator(strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color?>(
                Styles().colors.fillColorSecondary)),),)
          : Container()
    ]);
  }

  Widget _buildEmptyContent() => Container(height: 100,
      child: Center(
        child: Text(widget._emptyText),));

  //Tap
  void _onTapEvent(Event2 event) {
    Analytics().logSelect(target: 'Group Event: ${event.name}');
    Navigator.push(context, CupertinoPageRoute( builder: (context) => (event.hasGame == true) ?
    AthleticsGameDetailPanel(game: event.game, event: event, group: widget.group) :
    Event2DetailPanel(event: event, group: widget.group)));
  }

  //Logic
  void _loadEvents({bool showProgress = false}) {
    if (showProgress)
      setStateIfMounted(() => _updatingEvents = true);

    Events2().loadGroupEvents(groupId: widget.groupId, limit: 3)
        .then((Events2ListResult? eventsResult) {
          setStateIfMounted(() {
            // _allEventsCount = eventsResult?.totalCount ?? 0;
            _groupEvents = eventsResult?.events;
            if (showProgress)
              _updatingEvents = false;
          });
        });
  }

  void _clearEvents() {
    _groupEvents = null;
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

  void _initUpdateListener() => widget.updateController?.stream.listen((command) {
    if (command is String && command == _GroupEventsContent.notifyEventsRefresh) {
      _loadEvents();
    }
  });


  @override
  void onNotification(String name, dynamic param) {
    if (name == Groups.notifyGroupEventsUpdated) {
      _clearEvents();
      _loadEvents();
    } else if (name == Events2.notifyUpdated) {
      _updateEventIfNeeded(param);
    }
  }
}

class _GroupPostsContent extends StatefulWidget{
  static const String notifyPostRefreshWithScrollToLast = "edu.illinois.rokwire.group_detail.posts.refresh.with_scroll_to_last";

  final Group? group;
  final List<Member>? groupMembers;
  final StreamController<dynamic>? updateController;

  const _GroupPostsContent({this.group, this.updateController, this.groupMembers});

  @override
  State<StatefulWidget> createState() => _GroupPostsState();

  String get _emptyText => Localization().getStringEx("", "No group posts");
}

class _GroupPostsState extends State<_GroupPostsContent> with AutomaticKeepAliveClientMixin<_GroupPostsContent>
    implements NotificationsListener {
  List<Post>         _posts = <Post>[];
  Map<String, Uint8List?> _memberImages = {};
  GlobalKey          _lastPostKey = GlobalKey();
  bool?              _refreshingPosts;
  bool?              _loadingPostsPage;
  bool?              _hasMorePosts;
  bool?              _scrollToLastPostAfterRefresh;

  Group? get _group => widget.group;

  String? get _groupId => _group?.id;

  @override
  void initState() {
    _initUpdateListener();
    NotificationService().subscribe(this, [
      Social.notifyPostCreated,
      Social.notifyPostUpdated,
      Social.notifyPostDeleted
    ]);

    _loadInitialPosts();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context){
    super.build(context);
    return _buildPosts();
  }

  Widget _buildPosts() {
    List<Widget> postsContent = [];

    for (int i = 0; i <_posts.length ; i++) {
      Post? post = _posts[i];
      if (i > 0) {
        postsContent.add(Container(height: 16));
      }


      postsContent.add(GroupPostCard(key: (i == 0) ? _lastPostKey : null, post: post, group: _group!, creator: _getPostCreatorAsMember(post), memberImage: _getMemberImage(post.creator?.accountId),));
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

    return Stack(children: [
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
      Column(children: <Widget>[
        Visibility(visible: CollectionUtils.isEmpty(_posts) && _loadingPostsPage == false,
            child: _buildEmptyContent()),
        ...postsContent])),
      _loadingPostsPage == true
        ? Center(
        child: Container(
            padding: EdgeInsets.symmetric(vertical: 50),
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary))))
        : Container()
    ]);
  }

  Widget _buildEmptyContent() => Container(height: 100,
      child: Center(
        child: Text(widget._emptyText),));

  //Logic
  void _loadInitialPosts() {
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin) {
      setState(() {
        // _progress++; //TBD notify if needed
        _loadingPostsPage = true;
      });
      _loadPostsPage().then((_) {
        if (mounted) {
          setState(() {
            // _progress--; //TBD notify if needed
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
      Social().loadPosts(groupId: _groupId, type: PostType.post, offset: 0, limit: limit, order: SocialSortOrder.desc).then((List<Post>? posts) {
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
    List<Post>? postsPage = await Social().loadPosts(
        groupId: _groupId,
        type: PostType.post,
        status: PostStatus.active,
        offset: _posts.length,
        limit: _GroupDetailPanelState._postsPageSize,
        sortBy: SocialSortBy.date_created);
    if (postsPage != null) {
      _posts.addAll(postsPage);
      if (postsPage.length < _GroupDetailPanelState._postsPageSize) {
        _hasMorePosts = false;
      }
    }
  }

  Uint8List? _getMemberImage(String? id){
    if(StringUtils.isEmpty(id))
      return null;

    if(_memberImages.containsKey(id) == true){
      return _memberImages[id];
    } else {
      _loadMemberImage(id!);
      return null;
    }
  }

  void _loadMemberImage(String id) async {
    Content().loadUserPhoto(accountId: id, type: UserProfileImageType.small).then((ImagesResult? imageResult) {
      if(imageResult?.succeeded == true)
      setStateIfMounted(() =>
        _memberImages[id] = imageResult?.imageData
      );
    });
  }

  //Scroll
  void _scheduleLastPostScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastPost();
    });
  }

  void _scrollToLastPost() {
    _scrollTo(_lastPostKey);
  }

  void _scrollTo(GlobalKey? key) {
    if(key != null) {
      BuildContext? currentContext = key.currentContext;
      if (currentContext != null) {
        Scrollable.ensureVisible(currentContext, duration: Duration(milliseconds: 10));
      }
    }
  }

  //Update Listeners
  void _initUpdateListener() => widget.updateController?.stream.listen((command) {
    if (command is String && command == GroupDetailPanel.notifyRefresh) {
      _refreshCurrentPosts();
    // } else if(command is String && command == _GroupDetailPostsContent.notifyPostRefresh) {
    //   _refreshCurrentPosts();
    }  else if(command is String && command == _GroupPostsContent.notifyPostRefreshWithScrollToLast) {
      _scrollToLastPostAfterRefresh = true;
      if (_refreshingPosts != true) {
        _refreshCurrentPosts();
      }
    }
    // else if(command is Map<String, dynamic> && command.containsKey(_GroupDetailPostsContent.notifyPostRefreshWithDelta)){
    //   dynamic data = command[_GroupDetailPostsContent.notifyPostRefreshWithDelta];//consider passing map with named params
    //   int delta = (data is int) ? data : 0;
    //     _refreshCurrentPosts(delta: delta);
    // }
  });

  @override
  void onNotification(String name, dynamic param) {
    if (name == Social.notifyPostCreated) {
      Post? post = param is Post ? param : null;
      if(post?.isPost == true){
        _refreshCurrentPosts(delta: 1);
      }
    }
    else if (name == Social.notifyPostUpdated) {
      Post? post = param is Post ? param : null;
      if(post?.isPost == true){
        _refreshCurrentPosts();
      }
    }
    else if (name == Social.notifyPostDeleted) {
      Post? post = param is Post ? param : null;
      if(post?.isPost == true) {
        _refreshCurrentPosts(delta: -1);
      }
    }
  }

  Member?  _getPostCreatorAsMember(Post? post) {
    Iterable<Member>? creatorProfiles = widget.groupMembers?.where((member) => member.userId == post?.creatorId);
    return CollectionUtils.isNotEmpty(creatorProfiles) ? creatorProfiles?.first : null;
  }
}

class _GroupPollsContent extends StatefulWidget {
  final Group? group;
  final StreamController<dynamic>? updateController;

  const _GroupPollsContent({this.group, this.updateController});

  @override
  _GroupPollsState createState() => _GroupPollsState();

  String get _emptyText => Localization().getStringEx("", "No group polls");
}

class _GroupPollsState extends State<_GroupPollsContent> with AutomaticKeepAliveClientMixin<_GroupPollsContent>
    implements NotificationsListener {
  GlobalKey          _pollsKey = GlobalKey();
  List<Poll>?        _groupPolls;
  bool               _pollsLoading = false;

  Group? get _group => widget.group;

  String? get _groupId => _group?.id;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Polls.notifyCreated,
      Polls.notifyDeleted,
      Polls.notifyStatusChanged,
      Polls.notifyVoteChanged,
      Polls.notifyResultsChanged,
    ]);
    _initUpdateListener();
    _loadPolls();
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  Widget build(BuildContext context) {
    super.build(context);
    return _buildPolls();
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
                backgroundColor: Styles().colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                borderColor: Styles().colors.fillColorSecondary,
                borderWidth: 2,
                contentWeight: 0.5,
                onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPollListPanel(group: _group!))))));
      }
    }

    return Stack(key: _pollsKey, children: [
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
        Column(children: <Widget>[
          Visibility(visible: CollectionUtils.isEmpty(_groupPolls) && _pollsLoading == false,
              child: _buildEmptyContent()),
          ...pollsContentList
        ])),
      _pollsLoading
          ? Center(
          child: Container(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary))))
          : Container()
    ]);
  }

  Widget _buildEmptyContent() => Container(height: 100,
      child: Center(
        child: Text(widget._emptyText),));

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

  void _setPollsLoading(bool loading) {
    _pollsLoading = loading;
    if (mounted) {
      setState(() {});
    }
  }

  //Update Listeners
  void _initUpdateListener() => widget.updateController?.stream.listen((command) {
    if (command is String && command == GroupDetailPanel.notifyRefresh) {
      _refreshPolls();
    }
  });

  @override
  void onNotification(String name, param) {
    if ((name == Polls.notifyCreated) || (name == Polls.notifyDeleted)) {
      _refreshPolls();
    } else if(name == Polls.notifyVoteChanged
        || name == Polls.notifyResultsChanged
        || name == Polls.notifyStatusChanged) {
      _onPollUpdated(param); // Deep collection update single element (do not reload whole list)
    }
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

class _GroupMessagesContent extends StatefulWidget {
  static const String notifyMessagesRefreshWithScrollToLast = "edu.illinois.rokwire.group_detail.messages.refresh.with_scroll_to_last";

  final Group? group;
  final StreamController<dynamic>? updateController;

  const _GroupMessagesContent({this.group, this.updateController});

  String get _emptyText => Localization().getStringEx("", "No messages");

  @override
  State<StatefulWidget> createState() => _GroupMessagesState();
}

class _GroupMessagesState extends State<_GroupMessagesContent> with AutomaticKeepAliveClientMixin<_GroupMessagesContent>
    implements NotificationsListener{
  List<Post>         _messages = <Post>[];
  GlobalKey          _lastMessageKey = GlobalKey();
  bool?              _refreshingMessages;
  bool?              _loadingMessagesPage;
  bool?              _hasMoreMessages;
  bool?              _scrollToLastMessageAfterRefresh;

  Group? get _group => widget.group;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Social.notifyPostCreated,
      Social.notifyPostUpdated,
      Social.notifyPostDeleted
    ]);
    _initUpdateListener();
    _loadInitialMessages();
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildMessages();
  }

  Widget _buildMessages() {
    List<Widget> messagesContent = [];
    
    if(CollectionUtils.isNotEmpty(_messages)) {
      for (int i = 0; i < _messages.length; i++) {
        Post? message = _messages[i];
        if (i > 0) {
          messagesContent.add(Container(height: 16));
        }
        messagesContent.add(GroupPostCard(
            key: (i == 0) ? _lastMessageKey : null,
            post: message,
            group: _group!));
      }
    }

    if ((_group != null) && _group!.currentUserIsMemberOrAdmin && (_hasMoreMessages != false) && (0 < _messages.length)) {
      String title = Localization().getStringEx('panel.group_detail.button.show_older.title', 'Show older');
      messagesContent.add(Container(padding: EdgeInsets.only(top: 16),
          child: Semantics(label: title, button: true, excludeSemantics: true,
              child: InkWell(onTap: _loadNextMessagesPage,
                  child: Container(height: 36,
                    child: Align(alignment: Alignment.topCenter,
                      child: (_loadingMessagesPage == true) ?
                      SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorPrimary), )) :
                      Text(title, style: Styles().textStyles.getTextStyle('panel.group.button.show_older.title'),),
                    ),
                  )
              )
          ))
      );
    }

    return Stack(children: [
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
      Column(children: <Widget>[
        Visibility(visible: CollectionUtils.isEmpty(_messages) && _loadingMessagesPage == false,
            child: _buildEmptyContent()),
        ...messagesContent,
      ])),
      _loadingMessagesPage == true
          ? Center(
          child: Container(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary))))
          : Container()
    ]);
  }
  
  Widget _buildEmptyContent() => Container(height: 100,
      child: Center(
        child: Text(widget._emptyText),));

  void _loadInitialMessages() {
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin) {
      setState(() {
        // _progress++;
        _loadingMessagesPage = true;
      });
      _loadMessagesPage().then((_) {
        if (mounted) {
          setState(() {
            // _progress--;
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
      Social().loadPosts(groupId: _group?.id, type: PostType.direct_message, offset: 0, limit: limit, order: SocialSortOrder.desc).then((List<Post>? messages) {
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
    List<Post>? messagesPage = await Social().loadPosts(groupId: _group?.id, type: PostType.direct_message , offset: _messages.length, limit: _GroupDetailPanelState._postsPageSize, order: SocialSortOrder.desc);
    if (messagesPage != null) {
      _messages.addAll(messagesPage);
      if (messagesPage.length < _GroupDetailPanelState._postsPageSize) {
        _hasMoreMessages = false;
      }
    }
  }

  //Scroll
  void _scheduleLastMessageScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastMessage();
    });
  }

  void _scrollToLastMessage() {
    _scrollTo(_lastMessageKey);
  }

  void _scrollTo(GlobalKey? key) {
    if(key != null) {
      BuildContext? currentContext = key.currentContext;
      if (currentContext != null) {
        Scrollable.ensureVisible(currentContext, duration: Duration(milliseconds: 10));
      }
    }
  }

  //Update Listeners
  void _initUpdateListener() => widget.updateController?.stream.listen((command) {
    if (command is String && command == GroupDetailPanel.notifyRefresh) {
      _refreshCurrentMessages();
    } else if(command is String && command == _GroupMessagesContent.notifyMessagesRefreshWithScrollToLast) {
      _scrollToLastMessageAfterRefresh = true;
      if (_refreshingMessages != true) {
        _refreshCurrentMessages();
      }
    }
  });

  @override
  void onNotification(String name, param) {
    if (name == Social.notifyPostCreated) {
      Post? message = param is Post ? param : null;
      if (message?.isMessage == true) {
        _refreshCurrentMessages(delta: 1);
      }
    }
    else if (name == Social.notifyPostUpdated) {
      Post? message = param is Post ? param : null;
      if (message?.isMessage == true) {
        _refreshCurrentMessages();
      }
    }
    else if (name == Social.notifyPostDeleted) {
      Post? message = param is Post ? param : null;
      if (message?.isMessage == true) {
        _refreshCurrentMessages(delta: -1);
      }
    }
  }
}

class _GroupScheduledPostsContent extends StatefulWidget {
  static const String notifyPostsRefreshWithScrollToLast = "edu.illinois.rokwire.group_detail.scheduled_posts.refresh.with_scroll_to_last";

  final Group? group;
  final StreamController<dynamic>? updateController;

  const _GroupScheduledPostsContent({this.group, this.updateController});

  @override
  State<StatefulWidget> createState() => _GroupScheduledPostsState();

  String get _emptyText => Localization().getStringEx("", "No scheduled posts");
}

class _GroupScheduledPostsState extends State<_GroupScheduledPostsContent> with AutomaticKeepAliveClientMixin<_GroupScheduledPostsContent>
    implements NotificationsListener {
  List<Post> _scheduledPosts = <Post>[];
  GlobalKey _lastScheduledPostKey = GlobalKey();
  bool? _refreshingScheduledPosts;
  bool? _loadingScheduledPostsPage;
  bool? _hasMoreScheduledPosts;
  bool? _scrollToLastScheduledPostsAfterRefresh;

  Group? get _group => widget.group;

  bool get _isEmpty => CollectionUtils.isEmpty(_scheduledPosts);

  @override
  void initState() {
    Log.d("_GroupScheduledPostsState.initState");
    NotificationService().subscribe(this, [
      Social.notifyPostCreated,
      Social.notifyPostUpdated,
      Social.notifyPostDeleted
    ]);
    _initUpdateListener();
    _loadInitialScheduledPosts();
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    Log.d("_GroupScheduledPostsState.build");
    super.build(context);
    return _buildScheduledPosts();
  }

  Widget _buildScheduledPosts() {
    List<Widget> scheduledPostsContent = [];

    for (int i = 0; i < _scheduledPosts.length; i++) {
      Post? post = _scheduledPosts[i];
      if (i > 0) {
        scheduledPostsContent.add(Container(height: 16));
      }
      scheduledPostsContent.add(GroupPostCard(
          key: (i == 0) ? _lastScheduledPostKey : null,
          post: post,
          group: _group!));
    }

    if ((_group != null) && _group!.currentUserIsMemberOrAdmin &&
        (_hasMoreScheduledPosts != false) && (0 < _scheduledPosts.length)) {
      String title = Localization().getStringEx(
          'panel.group_detail.button.show_older.title', 'Show older');
      scheduledPostsContent.add(Container(padding: EdgeInsets.only(top: 16),
          child: Semantics(label: title, button: true, excludeSemantics: true,
              child: InkWell(onTap: _loadNextScheduledPostsPage,
                  child: Container(height: 36,
                    child: Align(alignment: Alignment.topCenter,
                      child: (_loadingScheduledPostsPage == true) ?
                      SizedBox(height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color?>(
                                Styles().colors.fillColorPrimary),)) :
                      Text(title, style: Styles().textStyles.getTextStyle(
                          'panel.group.button.show_older.title'),),
                    ),
                  )
              )
          ))
      );
    }

    return Stack(children: [
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
        Column(children: <Widget>[
          Visibility(visible: _isEmpty && _loadingScheduledPostsPage == false,
              child: _buildEmptyContent()),
           ...scheduledPostsContent,
      ])),
      _loadingScheduledPostsPage == true
          ? Center(
          child: Container(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary))))
          : Container()
    ]);
  }

  Widget _buildEmptyContent() => Container(height: 100, 
      child: Center(
        child: Text(widget._emptyText),));

  void _loadInitialScheduledPosts() {
    Log.d("_GroupScheduledPostsState._loadInitialScheduledPosts");
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin) {
      setState(() {
        // _progress++;
        _loadingScheduledPostsPage = true;
      });
      _loadScheduledPostsPage().then((_) {
        Log.d("_GroupScheduledPostsState._loadInitialScheduledPosts.loaded");
        if (mounted) {
          setState(() {
            // _progress--;
            _loadingScheduledPostsPage = false;
          });
        }
      });
    }
  }

  void _refreshCurrentScheduledPosts({int? delta}) {
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin &&
        (_refreshingScheduledPosts != true)) {
      int limit = _scheduledPosts.length + (delta ?? 0);
      _refreshingScheduledPosts = true;
      Social().loadPosts(groupId: _group?.id,
          type: PostType.post,
          offset: 0,
          limit: limit,
          order: SocialSortOrder.desc,
          status: PostStatus.draft).then((List<Post>? scheduledPost) {
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
    if ((_group != null) && _group!.currentUserIsMemberOrAdmin &&
        (_loadingScheduledPostsPage != true)) {
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
    List<Post>? scheduledPostsPage = await Social().loadPosts(
        groupId: _group?.id,
        type: PostType.post,
        offset: _scheduledPosts.length,
        limit: _GroupDetailPanelState._postsPageSize,
        status: PostStatus.draft,
        sortBy: SocialSortBy.activation_date);
    if (scheduledPostsPage != null) {
      _scheduledPosts.addAll(scheduledPostsPage);
      if (scheduledPostsPage.length < _GroupDetailPanelState._postsPageSize) {
        _hasMoreScheduledPosts = false;
      }
    }
  }

  //Scroll
  void _scheduleLastScheduledPostScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastScheduledPost();
    });
  }

  void _scrollToLastScheduledPost() {
    _scrollTo(_lastScheduledPostKey);
  }

  void _scrollTo(GlobalKey? key) {
    if(key != null) {
      BuildContext? currentContext = key.currentContext;
      if (currentContext != null) {
        Scrollable.ensureVisible(currentContext, duration: Duration(milliseconds: 10));
      }
    }
  }

  //Update Listeners
  void _initUpdateListener() =>
      widget.updateController?.stream.listen((command) {
        if (command is String && command == GroupDetailPanel.notifyRefresh) {
          _refreshCurrentScheduledPosts();
        } else if (command is String && command ==
            _GroupScheduledPostsContent.notifyPostsRefreshWithScrollToLast) {
          _scrollToLastScheduledPostsAfterRefresh = true;
          if (_refreshingScheduledPosts != true) {
            _refreshCurrentScheduledPosts();
          }
        }
      });

  @override
  void onNotification(String name, param) {
    if (name == Social.notifyPostCreated) {
      Post? message = param is Post ? param : null;
      if (message?.isScheduled == true) {
        _refreshCurrentScheduledPosts(delta: 1);
      }
    }
    else if (name == Social.notifyPostUpdated) {
      Post? message = param is Post ? param : null;
      if (message?.isScheduled == true) {
        _refreshCurrentScheduledPosts();
      }
    }
    else if (name == Social.notifyPostDeleted) {
      Post? message = param is Post ? param : null;
      if (message?.isScheduled == true) {
        _refreshCurrentScheduledPosts(delta: -1);
      }
    }
  }
}

