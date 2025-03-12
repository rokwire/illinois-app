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
import 'package:neom/model/Analytics.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/DeepLink.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:neom/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:neom/ui/events2/Event2CreatePanel.dart';
import 'package:neom/ui/events2/Event2DetailPanel.dart';
import 'package:neom/ui/events2/Event2HomePanel.dart';
import 'package:neom/ui/events2/Event2Widgets.dart';
import 'package:neom/ui/groups/GroupAboutContentWidget.dart';
import 'package:neom/ui/groups/GroupMemberNotificationsPanel.dart';
import 'package:neom/ui/groups/GroupMembersPanel.dart';
import 'package:neom/ui/groups/GroupPostDetailPanel.dart';
import 'package:neom/ui/groups/GroupPostReportAbuse.dart';
import 'package:neom/ui/groups/GroupSettingsPanel.dart';
import 'package:neom/ui/polls/PollWidgets.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/ui/widgets/InfoPopup.dart';
import 'package:neom/ui/widgets/QrCodePanel.dart';
import 'package:neom/ui/widgets/TextTabBar.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:neom/ext/Group.dart';
import 'package:neom/ext/Social.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:neom/ext/Event2.dart';
import 'package:neom/ui/groups/GroupAllEventsPanel.dart';
import 'package:neom/ui/groups/GroupMembershipRequestPanel.dart';
import 'package:neom/ui/groups/GroupPollListPanel.dart';
import 'package:neom/ui/groups/GroupPostCreatePanel.dart';
import 'package:neom/ui/groups/GroupWidgets.dart';
import 'package:neom/ui/polls/CreatePollPanel.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_io/io.dart';

enum DetailTab {Events, Posts, Scheduled, Messages, Polls }

class GroupDetailPanel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'group_detail_content_panel';

  static const String notifyRefresh  = "edu.illinois.rokwire.group_detail.refresh";
  static const String notifyLoadMemberImage  = "edu.illinois.rokwire.group_detail.load.image";
  static const String notifyMemberImageLoaded  = "edu.illinois.rokwire.group_detail.image.loaded";

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
}

class _GroupDetailPanelState extends State<GroupDetailPanel> with TickerProviderStateMixin implements NotificationsListener {
  static final int          _postsPageSize = 8;
  static final int          _animationDurationInMilliSeconds = 200;
  static final List<DetailTab> _permanentTabs = [DetailTab.Scheduled];

  Group?                _group;
  GroupStats?        _groupStats;
  List<Member>?   _groupAdmins;
  Map<String, Uint8List?> _groupMembersImages = {};
  String?                 _postId;

  List<DetailTab?>? _tabs;
  PageController? _pageController;
  TabController?  _tabController;
  GestureRecognizer? _studentCodeLaunchRecognizer;
  StreamController _updateController = StreamController.broadcast();
  final ScrollController _scrollController = ScrollController();

  DetailTab?         _currentTab;

  bool               _confirmationLoading = false;
  bool               _researchProjectConsent = false;

  int                _progress = 0;

  GlobalKey          _groupHeaderKey = GlobalKey();
  double?            _groupHeaderHeight;

  DateTime?          _pausedDateTime;

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

  //ignore: unused_element
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
      AppLifecycle.notifyStateChanged,
      Connectivity.notifyStatusChanged,
      FlexUI.notifyChanged,
      Groups.notifyUserMembershipUpdated,
      Groups.notifyGroupCreated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupStatsUpdated,
    ]);
    _initUpdateController();
    _initTabs();
    _postId = widget.groupPostId;
    _studentCodeLaunchRecognizer = TapGestureRecognizer()..onTap = _onLaunchStudentCode;

    _loadGroup(loadEvents: true);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _updateController.close();
    _pageController?.dispose();
    _tabController?.dispose();
    _scrollController.dispose();
    _studentCodeLaunchRecognizer?.dispose();
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _evalGroupHeaderHeight();
      });
    }
    else {
      content = _buildErrorContent();
    }

    String? barTitle = (_isResearchProject && !_isMemberOrAdmin) ? 'Your Invitation To Participate' : null;

    return Scaffold(
      appBar: HeaderBar(title: barTitle,),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child: content,),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildLoadingContent() {
    return Column(children: <Widget>[
      Expanded(
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary), ),
        ),
      ),
    ]);
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
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverSafeArea(
                  sliver: SliverHeaderBar(
                    toolbarHeight: 0,
                    leadingWidget: Container(),
                    floating: false,
                    pinned: true,
                    expandedHeight: _groupHeaderHeight,
                    flexibleSpace: _groupHeader,
                    bottom: _isMemberOrAdmin ? _buildTabs() : null,
                  )
              )
          ),
        ];
      },
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: _isMemberOrAdmin ? _buildViewPager() : Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildNonMemberContent(),),
      ),
    );
  }

  List<Widget> _buildNonMemberContent(){
    List<Widget> content = [];
    content.add(GroupAboutContentWidget(group: _group, admins: _groupAdmins,));
    // content.add(_buildAbout());
    // content.add(_buildPrivacyDescription());
    // content.add(_buildAdmins());
    // if (_isPublic /*&& CollectionUtils.isNotEmpty(_groupEvents)*/ ) { //TBD do we want to show events for non members when specific settings are applied?
    //   content.add(_GroupEventsContent(group: _group, updateController: _updateController));
    // }
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
        // if (_isResearchProject && _isMember) {
        //   _currentTab = DetailTab.About; //TBD
        // }
        _initTabs();
        _redirectToGroupPostIfExists();
        _loadGroupAdmins();

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
          _initTabs();
        });
        _updateController.add(GroupDetailPanel.notifyRefresh);
        if(refreshEvents)
          _updateController.add(_GroupEventsContent.notifyEventsRefresh);
      }
    });
  }

  void _trimForbiddenTabs(){
    if(CollectionUtils.isNotEmpty(_tabs)){ //Remove Tabs which are forbidden
      _tabs?.removeWhere((DetailTab? tab) => tab == null ||
          (tab == DetailTab.Scheduled &&
              ( _canShowScheduled == false || _tabs?.contains(DetailTab.Posts) != true)
          ));
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

  void _loadGroupAdmins() {
    _increaseProgress();
    Groups().loadMembers(groupId: widget.groupId, statuses: [GroupMemberStatus.admin] ).then((admins) {
      _groupAdmins = admins;
      _decreaseProgress();
    });
  }

  void _refreshGroupAdmins() {
    Groups().loadMembers(groupId: widget.groupId, statuses: [GroupMemberStatus.admin]).then((admins) {
      _groupAdmins = admins;
    });
  }

  void _loadMemberImage(String id) async {
    if(_groupMembersImages.containsKey(id) == true) {
      if(_groupMembersImages[id] != null)
        _updateController.add({GroupDetailPanel.notifyMemberImageLoaded: {"id": id, "image_bytes": _groupMembersImages[id]}});
      return; //Do not load the image many times
    }

    _groupMembersImages[id] = null; //prepare the pair and disable multiple loading
    Content().loadUserPhoto(accountId: id, type: UserProfileImageType.small).then((ImagesResult? imageResult) {
      if(imageResult?.succeeded == true)
        setStateIfMounted(() =>
        _groupMembersImages[id] = imageResult?.imageData
        );
      _updateController.add({GroupDetailPanel.notifyMemberImageLoaded: {"id": id, "image_bytes": _groupMembersImages[id]}});
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
    else if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
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

  void _initUpdateController() => _updateController.stream.listen((command) {
    if (command is Map) {
        if(command.containsKey(GroupDetailPanel.notifyLoadMemberImage)) {
          _loadMemberImage(command[GroupDetailPanel.notifyLoadMemberImage]);
        }
    }
  });

  void _initTabs() {
    _tabs = _group?.settings?.contentDetailTabs ?? GroupSettingsExt.getDefaultDetailTabs();
    _tabs?.addAll(_permanentTabs);
    _tabs = _tabs?.toSet().toList();// exclude duplicated
    _trimForbiddenTabs();
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

  Widget get _groupHeader {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      reverse: true,
      child: Stack(key: _groupHeaderKey, children: [
        Visibility(
          visible: _hasGroupImage,
          child: _buildImageHeader(),
        ),
        Padding(
          padding: EdgeInsets.only(left: 24.0, right: 24.0, bottom: 56.0, top: _hasGroupImage ? 152.0 : 24.0),
          child: _buildGroupDetailsHeader(),
        )
      ]),
    );
  }

  bool get _hasGroupImage => StringUtils.isNotEmpty(_group?.imageURL);

  Widget _buildImageHeader(){
    return _hasGroupImage ? Semantics(label: "group image", hint: "Double tap to zoom", child:
      Container(height: 200.0, width: MediaQuery.of(context).size.width, color: Styles().colors.background, child:
        ModalImageHolder(child: Image.network(_group!.imageURL!, excludeFromSemantics: true, fit: BoxFit.cover, headers: Config().networkAuthHeaders)),
      )
    ): Container();
  }

  Widget _buildGroupDetailsHeader() {
    return Container(
      color: Styles().colors.surface,
      child: Column(
        children: [
          _buildGroupInfo(),
          _buildMembershipRequest(),
          _buildCancelMembershipRequest(),
          _buildLeaveGroupWidget(),
        ],
      ),
    );
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
        attendedMembers = sprintf(Localization().getStringEx("panel.group_detail.attended_members.count.format", "%s Members Attended"), [attendedCount]);
      }
    }

    List<Widget> commands = [];
    if (StringUtils.isNotEmpty(_group?.webURL) && !_isResearchProject) {
      commands.add(_infoSplitter);
      commands.add(_buildWebsiteLinkCommand());
    }
    if (!_isMemberOrAdmin) {
      List<Widget> attributesList = _buildAttributes();
      if (attributesList.isNotEmpty) {
        commands.add(_infoSplitter);
        commands.add(Padding(padding: EdgeInsets.symmetric(vertical: 6), child:
          Column(children: attributesList,),
        ));
      }
    }
    if (commands.isNotEmpty) {
      commands.add(_infoSplitter);
    }

    List<Widget> contentList = <Widget>[];
    if (_showMembershipBadge) {
      contentList.addAll(<Widget>[
        Padding(padding: EdgeInsets.only(left: 16, right: _hasIconOptionButtons ? 0 : 16, top: 8), child:
          _buildBadgeWidget(),
        ),

        Padding(padding: EdgeInsets.only(left: 16, right: 16), child:
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
      contentList.add(GestureDetector(onTap: _canViewMembers ? _onTapMembers : null, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
          Text(members, style: _canViewMembers ? Styles().textStyles.getTextStyle('widget.title.dark.small.underline') : Styles().textStyles.getTextStyle('widget.title.dark.small'))
        ),
      ));
    }

    if (StringUtils.isNotEmpty(pendingMembers)) {
      contentList.add(Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
        Text(pendingMembers,  style: Styles().textStyles.getTextStyle('widget.title.dark.small') ,)
      ));
    }

    if (StringUtils.isNotEmpty(attendedMembers)) {
      contentList.add(Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
        Text(StringUtils.ensureNotEmpty(attendedMembers), style: Styles().textStyles.getTextStyle('widget.title.dark.small'),)
      ));
    }

    contentList.add(Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(children: commands,),
    ));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  PreferredSizeWidget? _buildTabs() {
    if(CollectionUtils.isEmpty(_tabs) || _tabs?.length == 1)
      return null;

    List<Widget> tabs = [];
    for (DetailTab? tab in _tabs! ) {
      String title;
      switch (tab) {
        case DetailTab.Events:
          title = Localization().getStringEx("panel.group_detail.button.events.title", 'Events');
          break;
        case DetailTab.Posts:
          title = Localization().getStringEx("panel.group_detail.button.posts.title", 'Posts');
          break;
        // case DetailTab.Messages:
        //   title = Localization().getStringEx("panel.group_detail.button.messages.title", 'Messages');
        //   break;
        case DetailTab.Polls:
          title = Localization().getStringEx("panel.group_detail.button.polls.title", 'Polls');
          break;
        // case DetailTab.About:
        //   title = Localization().getStringEx("panel.group_detail.button.about.title", 'About');
        //   break;
        case DetailTab.Scheduled:
          title = Localization().getStringEx("panel.group_detail.button.scheduled.title", 'Scheduled'); //localize
          break;
        default: title = "Unknown";
      }

      tabs.add(TextTabButton(title: title));
    }

    if(_tabController == null || _tabController!.length != tabs.length){
      _tabController = TabController(length: tabs.length, vsync: this);
    }

    return TextTabBar(
      tabs: tabs,
      labelStyle: Styles().textStyles.getTextStyle('widget.heading.medium_small'),
      labelPadding: const EdgeInsets.symmetric(horizontal: 6.0,),
      controller: _tabController,
      backgroundColor: Styles().colors.fillColorPrimary,
      isScrollable: false,
      onTap: (index) => _onTab(_tabAtIndex(index)),
    );
  }

  Widget _buildViewPager(){
    List<Widget> pages = [];

    if(CollectionUtils.isEmpty(_tabs))
      return Container();

      for (DetailTab? tab in _tabs!){
        pages.add(_buildPageFromTab(tab));
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
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (int index){
              _tabController?.animateTo(index, duration: Duration(milliseconds: _animationDurationInMilliSeconds));
              _currentTab = _tabAtIndex(index) ?? _currentTab;
            }
          )
        )
      );
  }

  int _indexOfTab(DetailTab? tab) => _tabs?.indexOf(tab) ?? 0;
  
  DetailTab? _tabAtIndex(int index) {
    try {
      return _tabs?.elementAt(index);
    } catch (e) {
      Log.d(e.toString());
    }
    
    return null; //TBD consider default
  }

  Widget _buildPageFromTab(DetailTab? data){
    switch(data){
      case DetailTab.Events:
        return _GroupEventsContent(group: _group, updateController: _updateController);
      case DetailTab.Posts:
        return _GroupPostsContent(group: _group, updateController: _updateController, groupAdmins: _groupAdmins);
      // case DetailTab.Messages:
      //   return _GroupMessagesContent(group: _group, updateController: _updateController, groupAdmins:  _groupAdmins);
      case DetailTab.Polls:
        return _GroupPollsContent(group: _group,  updateController: _updateController,  groupAdmins:  _groupAdmins);
      case DetailTab.Scheduled:
        return _GroupScheduledPostsContent(group: _group,  updateController: _updateController, groupAdmins:  _groupAdmins);

      default: Container();
    }
    return Container();
  }

  Widget _buildWebsiteLinkCommand() {
    return RibbonButton(
        label: Localization().getStringEx("panel.group_detail.button.website.title", 'Website'),
        rightIconKey: 'external-link',
        leftIconKey: 'web',
        padding: EdgeInsets.symmetric(vertical: 12),
        onTap: _onWebsite
    );
  }

  Widget get _infoSplitter =>
      Container(height: 1, color: Styles().colors.surfaceAccent);

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

  Widget _buildBadgeWidget() {
    Widget badgeWidget = Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _group!.currentUserStatusColor, borderRadius: BorderRadius.all(Radius.circular(2)),), child:
      Semantics(label: _group?.currentUserStatusText?.toLowerCase(), excludeSemantics: true, child:
        Text(_group!.currentUserStatusText!.toUpperCase(), style: _group?.currentUserStatusTextStyle,)
      ),
    );
    return _hasIconOptionButtons ? Row(children: <Widget>[
      badgeWidget,
      Expanded(child: Container(),),
      _buildTitleIconButtons
    ]) : badgeWidget;
  }

  Widget _buildTitleWidget({bool showButtons = false}) =>
    Row(children: <Widget>[
      Expanded(child:
        Padding(
          padding: EdgeInsets.only(top: showButtons ? 8.0 : 0.0),
          child:
          RichText(textScaler: MediaQuery.of(context).textScaler, text:
            TextSpan(text: _group?.title?.toUpperCase() ?? '',  style:  Styles().textStyles.getTextStyle('widget.group.card.title.medium.fat'), children: [
              if (_isManaged)
                WidgetSpan(alignment: PlaceholderAlignment.middle, child: _buildManagedBadge),
            ],)
          )
        )
      ),
      showButtons ? _buildTitleIconButtons : Container()
    ]);

  Widget get _buildTitleIconButtons =>
    Row(crossAxisAlignment: CrossAxisAlignment.start,  mainAxisSize: MainAxisSize.min, children: [
      if (_showPolicyIcon)
        _buildPolicyIconButton(),
      if (_hasCreateOptions)
        _buildCreateIconButton(),
      if (_hasOptions)
        _buildSettingsIconButton(),
    ]);

  Widget get _buildManagedBadge => InkWell(onTap: _onTapManagedGroupBadge, child:
    Padding(padding: EdgeInsets.symmetric(horizontal: 6), child:
      Styles().images.getImage('group-managed-badge', excludeFromSemantics: true)
    )
  );

  Widget _buildPolicyIconButton() =>
    Semantics(button: true, excludeSemantics: true,
      label: Localization().getStringEx('panel.group_detail.button.policy.label', 'Policy'),
      hint: Localization().getStringEx('panel.group_detail.button.policy.hint', 'Tap to ready policy statement'),
      child: InkWell(onTap: _onPolicy,
        child: Padding(padding: EdgeInsets.all(8),
            child: Styles().images.getImage('info', excludeFromSemantics: true)
        ),
      ),
    );

  Widget _buildSettingsIconButton() =>
    Semantics(button: true, excludeSemantics: true,
      label: Localization().getStringEx('', 'Settings'),
      hint: Localization().getStringEx('', ''),
      child: InkWell(onTap: _onGroupOptionsTap, child:
        Padding(padding: EdgeInsets.all(8), child:
          Styles().images.getImage('more', excludeFromSemantics: true)
        ),
      ),
    );

  Widget _buildCreateIconButton() =>
    Semantics(button: true, excludeSemantics: true,
      label: Localization().getStringEx('', 'Create'),
      hint: Localization().getStringEx('', ''),
      child: InkWell(onTap: _onCreateOptionsTap, child:
        Padding(padding: EdgeInsets.all(8), child:
          Styles().images.getImage('plus-circle', excludeFromSemantics: true)
        ),
      ),
    );

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
          textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.dark"),
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

  Widget _buildLeaveGroupWidget() {
    return Visibility(
      visible: _canLeaveGroup,
      child: Padding(padding: EdgeInsets.all(16), child:
        RoundedButton(label: Localization().getStringEx("panel.group_detail.button.leave.title", 'Leave'),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.dark"),
            backgroundColor: Styles().colors.surface,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            borderColor: Styles().colors.fillColorSecondary,
            borderWidth: 2,
            onTap: _onTapLeave
        ),
      ),
    );
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
        backgroundColor: Styles().colors.background,
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
                      textStyle: Styles().textStyles.getTextStyle("widget.button.light.title.large.fat"),
                      borderColor: Styles().colors.fillColorSecondary,
                      backgroundColor: Styles().colors.background,
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      onTap: () {
                        Analytics().logAlert(text: confirmationTextMsg, selection: negativeButtonLabel);
                        Navigator.pop(context);
                      }),),
                  Container(width: 16),
                  Expanded(flex: positiveButtonFlex, child: RoundedButton(
                    label: positiveButtonLabel ?? '',
                    textStyle: Styles().textStyles.getTextStyle("widget.button.light.title.large.fat"),
                    borderColor: Styles().colors.fillColorSecondary,
                    backgroundColor: Styles().colors.background,
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
                    visible: _canAboutSettings,
                    child: RibbonButton(
                        leftIconKey: "info",
                        label: Localization().getStringEx("panel.group_detail.button.group.about.title", "About this group"),//TBD localize
                        onTap: () {
                          Analytics().logSelect(target: "Group About", attributes: _group?.analyticsAttributes);
                          GroupAboutContentWidget.showPanel(context: context, group: _group, admins: _groupAdmins);
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
                  label: Localization().getStringEx("panel.group.detail.post.button.report.students_dean.label", "Report to Dean of Students"),
                  onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToDeanOfStudents : true)   ),
                )),
              ]));
        });
  }

  void _onCreateOptionsTap() {
    Analytics().logSelect(target: 'Group Create Options', attributes: _group?.analyticsAttributes);

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
                          _onTapCreatePost(type: PostType.direct_message);
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

  void _onTab(DetailTab? tab) {
    Analytics().logSelect(target: "Tab: $tab", attributes: _group?.analyticsAttributes);
    if (tab != null /*&& _currentTab != tab*/) {
        _currentTab = tab;

      _pageController?.animateToPage(_indexOfTab(tab), duration: Duration(milliseconds: _animationDurationInMilliSeconds), curve: Curves.linear);
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
    showDialog(context: context, builder: (_) => InfoPopup(
      backColor: Color(0xfffffcdf), //Styles().colors.surface ?? Colors.white,
      padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 24),
      border: Border.all(color: Styles().colors.textDark, width: 1),
      alignment: Alignment.center,
      //infoText: Localization().getStringEx('panel.group.detail.policy.text', 'The {{app_university}} takes pride in its efforts to support free speech and to foster inclusion and mutual respect. Users may submit a report to group administrators about obscene, threatening, or harassing content. Users may also choose to report content in violation of Student Code to the Office of the Dean of Students.').replaceAll('{{app_university}}', Localization().getStringEx('app.university_name', 'University of Illinois')),
      //infoTextStyle: Styles().textStyles.getTextStyle('widget.description.regular.thin'),
      infoTextWidget: _policyInfoTextWidget,
      closeIcon: Styles().images.getImage('close-circle', excludeFromSemantics: true),
      closeIconMargin: EdgeInsets.only(left: 24, right: 8, top: 8, bottom: 24),
    ),);
  }

  Widget get _policyInfoTextWidget {
    final String universityMacro = '{{app_university}}';
    final String studentCodeMacro = '{{student_code}}';
    final String externalLinkMacro = '{{external_link_icon}}';
    TextStyle? regularTextStyle = Styles().textStyles.getTextStyle('widget.description.regular.thin');
    TextStyle? linkTextStyle = Styles().textStyles.getTextStyle('widget.description.regular.thin.link');

    String infoText = Localization().getStringEx('panel.group.detail.policy.text', 'The $universityMacro takes pride in its efforts to support free speech and to foster inclusion and mutual respect. Users may submit a report to group administrators about obscene, threatening, or harassing content. Users may also choose to report content in violation of $studentCodeMacro $externalLinkMacro to the Office of the Dean of Students.\n\nYour activity in this group is not viewable outside of the group.').
      replaceAll(universityMacro, Localization().getStringEx('app.university_name', 'University of Illinois'));

    String studentCodeText = Localization().getStringEx('panel.group.detail.policy.text.student_code', 'Student Code');

    List<InlineSpan> spanList = StringUtils.split<InlineSpan>(infoText, macros: [studentCodeMacro, externalLinkMacro], builder: (String entry){
      bool hasStudentCode = StringUtils.isNotEmpty(Config().studentCodeUrl);
      if (entry == studentCodeMacro) {
        if (hasStudentCode) {
          return TextSpan(text: studentCodeText, style : linkTextStyle, recognizer: _studentCodeLaunchRecognizer,);
        }
        return TextSpan(text: studentCodeText);
      }
      else if (entry == externalLinkMacro) {
        if (hasStudentCode) {
          return WidgetSpan(alignment: PlaceholderAlignment.middle, child: Styles().images.getImage('external-link', size: 14) ?? Container());
        }
        return TextSpan(text: '');
      }
      else {
        return TextSpan(text: entry);
      }
    });
    return RichText(textAlign: TextAlign.left, text:
      TextSpan(style: regularTextStyle, children: spanList)
    );
  }

  void _onLaunchStudentCode() {
    Analytics().logSelect(target: 'Student Code');
    //TODO: implement student code
    _launchUrl(Config().studentCodeUrl);
  }

  static void _launchUrl(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri, mode: (Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault));
        }
      }
    }
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
        Container(decoration: BoxDecoration(color: Styles().colors.surface, borderRadius: BorderRadius.circular(10.0)), child:
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
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupSettingsPanel(group: _group, groupStats: _groupStats,))).then((exit){
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

  void _onTapCreatePost({PostType type =  PostType.post}) {
    Analytics().logSelect(target: "Create Post", attributes: _group?.analyticsAttributes);
    if (_group != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostCreatePanel(group: _group!, type: type))).then((result) {
        if (result is Post) {
          if(result.isScheduled){
            _updateController.add(_GroupScheduledPostsContent.notifyPostsRefreshWithScrollToLast);
          }
          else if (result.isPost) {
            _updateController.add(_GroupPostsContent.notifyPostRefreshWithScrollToLast);
          }
          // else if (result.isMessage) {
          //   _updateController.add(_GroupMessagesContent.notifyMessagesRefreshWithScrollToLast);
          // }
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
      _initTabs();
      _refreshGroupAdmins();
      _refreshGroupStats();
      _updateController.add(GroupDetailPanel.notifyRefresh);
      _updateController.add(_GroupEventsContent.notifyEventsRefresh);
    }
  }

  void _evalGroupHeaderHeight() {
    final RenderObject? renderBox = _groupHeaderKey.currentContext?.findRenderObject();
    Size? size = (renderBox is RenderBox) ? renderBox.size : null;
    if ((size?.height != _groupHeaderHeight) && mounted) {
      setStateIfMounted(() {
        _groupHeaderHeight = size?.height;
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
                "widget.button.title.medium.fat.dark"),
            backgroundColor: Styles().colors.surface,
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
  final List<Member>? groupAdmins;
  final StreamController<dynamic>? updateController;

  const _GroupPostsContent({this.group, this.updateController, this.groupAdmins});

  @override
  State<StatefulWidget> createState() => _GroupPostsState();

  String get _emptyText => Localization().getStringEx("", "No group posts");
}

class _GroupPostsState extends State<_GroupPostsContent> with AutomaticKeepAliveClientMixin<_GroupPostsContent>
    implements NotificationsListener {
  List<Post>         _posts = <Post>[];
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
    // _loadPinnedPosts();
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
    List<Widget> postsContent = _buildPostCardsContent(posts: _posts);

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

  List<Widget> _buildPostCardsContent({required List<Post> posts, List<Post>? exclude, GlobalKey? lastPostKey,}){
    Iterable<String?>? excludeIds = exclude?.map((post) => post.id);
    List<Widget> content = [];
    for (int i = 0; i <posts.length ; i++) {
      Post? post = posts[i];
      if(excludeIds?.contains(post.id)== true){
        continue;
      } else {
      if (i > 0) {
        content.add(Container(height: 16));
      }

      content.add(GroupPostCard(
        key: (i == 0) ? lastPostKey : null,
        post: post,
        group: _group!,
        isAdmin: post.creator?.findAsMember(groupMembers: widget.groupAdmins)?.isAdmin
      ));
      }
    }

    return content;
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
      Social().loadPosts(groupId: _groupId, type: PostType.post, showCommentsCount: true, offset: 0, limit: limit, order: SocialSortOrder.desc).then((List<Post>? posts) {
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
        showCommentsCount: true,
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

  // Future<void> _loadPinnedPosts() async =>
  //     Social().loadPosts(
  //         groupId: _groupId,
  //         type: PostType.post,
  //         status: PostStatus.active,
  //         sortBy: SocialSortBy.date_created).
  //           then((List<Post>? posts) {
  //               List<Post> allPinnedPosts = posts?.where(
  //                       (post) => post.isPinned == true
  //               ).toList() ?? [];
  //               setStateIfMounted(() {
  //                 _pinedPosts = CollectionUtils.isNotEmpty(allPinnedPosts) ? allPinnedPosts.take(1).toList() : [];
  //               });
  //             });

  // Member?  _getPostCreatorAsMember(Post? post) {
  //   Iterable<Member>? creatorProfiles = widget.groupMembers?.where((member) => member.userId == post?.creatorId);
  //   return CollectionUtils.isNotEmpty(creatorProfiles) ? creatorProfiles?.first : null;
  // }

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
      // _loadPinnedPosts();
    // } else if(command is String && command == _GroupDetailPostsContent.notifyPostRefresh) {
    //   _refreshCurrentPosts();
    }  else if(command is String && command == _GroupPostsContent.notifyPostRefreshWithScrollToLast) {
      _scrollToLastPostAfterRefresh = true;
      if (_refreshingPosts != true) {
        _refreshCurrentPosts(/*delta: 1*/);
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
        // if(post?.isPinned == true)
        //   _loadPinnedPosts();
      }
    }
    else if (name == Social.notifyPostUpdated) {
      Post? post = param is Post ? param : null;
      if(post?.isPost == true){
        _refreshCurrentPosts(/*delta: post?.pinned == true ? 1 : 0*/);
        // _loadPinnedPosts();
      }
    }
    else if (name == Social.notifyPostDeleted) {
      Post? post = param is Post ? param : null;
      if(post?.isPost == true) {
        _refreshCurrentPosts(delta: -1);
        // if(post?.isPinned == true)
        //   _loadPinnedPosts();
      }
    }
  }
}

class _GroupPollsContent extends StatefulWidget {
  final Group? group;
  final List<Member>? groupAdmins;
  final StreamController<dynamic>? updateController;

  const _GroupPollsContent({this.group, this.updateController, this.groupAdmins});

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
          pollsContentList.add(PollCard(poll: groupPoll, group: _group, isAdmin: widget.groupAdmins?.map((Member admin) => admin.userId == groupPoll.creatorUserUuid).isNotEmpty,));
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
  final List<Member>? groupAdmins;
  final StreamController<dynamic>? updateController;

  const _GroupMessagesContent({this.group, this.updateController, this.groupAdmins});

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
            group: _group!,
            isAdmin: widget.groupAdmins?.map((Member admin) => admin.userId == message.creatorId).isNotEmpty,
            // creator: _getMessageCreatorAsMember(message),
            // updateController: widget.updateController,
        ));
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
      Social().loadPosts(groupId: _group?.id, type: PostType.direct_message, showCommentsCount: true, offset: 0, limit: limit, order: SocialSortOrder.desc).then((List<Post>? messages) {
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
    List<Post>? messagesPage = await Social().loadPosts(groupId: _group?.id, type: PostType.direct_message, showCommentsCount: true, offset: _messages.length, limit: _GroupDetailPanelState._postsPageSize, order: SocialSortOrder.desc);
    if (messagesPage != null) {
      _messages.addAll(messagesPage);
      if (messagesPage.length < _GroupDetailPanelState._postsPageSize) {
        _hasMoreMessages = false;
      }
    }
  }

  // Member?  _getMessageCreatorAsMember(Post? message) {
  //   Iterable<Member>? creatorProfiles = widget.groupMembers?.where((member) => member.userId == message?.creatorId);
  //   return CollectionUtils.isNotEmpty(creatorProfiles) ? creatorProfiles?.first : null;
  // }

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
  final List<Member>? groupAdmins;
  final StreamController<dynamic>? updateController;

  const _GroupScheduledPostsContent({this.group, this.updateController, this.groupAdmins});

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
          group: _group!,
          isAdmin: widget.groupAdmins?.map((Member admin) => admin.userId == post.creatorId).isNotEmpty,
          // updateController: widget.updateController,
          // creator: _getPostCreatorAsMember(post),
      ));
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
          showCommentsCount: true,
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
        showCommentsCount: true,
        sortBy: SocialSortBy.activation_date);
    if (scheduledPostsPage != null) {
      _scheduledPosts.addAll(scheduledPostsPage);
      if (scheduledPostsPage.length < _GroupDetailPanelState._postsPageSize) {
        _hasMoreScheduledPosts = false;
      }
    }
  }

  // Member?  _getPostCreatorAsMember(Post? post) {
  //   Iterable<Member>? creatorProfiles = widget.groupMembers?.where((member) => member.userId == post?.creatorId);
  //   return CollectionUtils.isNotEmpty(creatorProfiles) ? creatorProfiles?.first : null;
  // }

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

