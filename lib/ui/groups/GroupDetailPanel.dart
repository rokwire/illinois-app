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
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/groups/GroupAllEventsPanel.dart';
import 'package:illinois/ui/groups/GroupMembershipRequestPanel.dart';
import 'package:illinois/ui/groups/GroupPostDetailPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/ExpandableText.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';

import 'GroupMembersPanel.dart';
import 'GroupSettingsPanel.dart';

enum _DetailTab { Events, Posts, About }

class GroupDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {

  final Group group;

  GroupDetailPanel({this.group});

  @override
 _GroupDetailPanelState createState() => _GroupDetailPanelState();

  @override
  Map<String, dynamic> get analyticsPageAttributes {
    return group?.analyticsAttributes;
  }

  String get groupId {
    return group?.id;
  }
}

class _GroupDetailPanelState extends State<GroupDetailPanel> implements NotificationsListener {

  final int          _postsPageSize = 8;

  Group              _group;
  int                _progress = 0;
  bool               _confirmationLoading = false;
  bool               _updatingEvents = false;
  int                _allEventsCount = 0;
  List<GroupEvent>   _groupEvents;
  List<GroupPost>    _visibleGroupPosts = <GroupPost>[];
  List<Member>       _groupAdmins;

  _DetailTab         _currentTab = _DetailTab.Events;

  GlobalKey          _lastPostKey = GlobalKey();
  bool               _refreshingPosts;
  bool               _loadingPostsPage;
  bool               _hasMorePosts;
  bool               _shouldScrollToLastAfterRefresh;

  DateTime           _pausedDateTime;

  bool get _isMember {
    return _group?.currentUserAsMember?.isMember ?? false;
  }

  bool get _isAdmin {
    return _group?.currentUserAsMember?.isAdmin ?? false;
  }

  bool get _isMemberOrAdmin {
    return _isMember || _isAdmin;
  }

  bool get _isPublic {
    return _group?.privacy == GroupPrivacy.public;
  }

  bool get isFavorite {
    return false;
  }

  bool get _canLeaveGroup {
    Member currentMemberUser = _group?.currentUserAsMember;
    if (currentMemberUser?.isAdmin ?? false) {
      return ((_group?.adminsCount ?? 0) > 1); // Do not allow an admin to leave group if he/she is the only one admin.
    } else {
      return currentMemberUser?.isMember ?? false;
    }
  }

  bool get _canDeleteGroup {
    return _isAdmin;
  }

  bool get _canAddEvent {
    return _isAdmin;
  }

  bool get _canCreatePost {
    return _isAdmin || _isMember;
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
      Groups.notifyGroupPostsUpdated]);

    _loadGroup(loadEvents: true);
  }

  @override
  void dispose() {
    super.dispose();

    NotificationService().unsubscribe(this);
  }

  void _loadGroup({bool loadEvents = false}) {
    _increaseProgress();
    Groups().loadGroup(widget.groupId).then((Group group) {
      if (mounted) {
        if (group != null) {
          _group = group;
          _groupAdmins = _group.getMembersByStatus(GroupMemberStatus.admin);
          _loadInitialPosts();
        }
        if (loadEvents) {
          _loadEvents();
        }
        _decreaseProgress();
      }
    });
  }

  void _refreshGroup({bool refreshEvents = false}) {
    Groups().loadGroup(widget.groupId).then((Group group) {
      if (mounted && (group != null)) {
        setState(() {
          _group = group;
          if (refreshEvents) {
            _refreshEvents();
          }
          _groupAdmins = _group.getMembersByStatus(GroupMemberStatus.admin);
        });
        _refreshCurrentPosts();
      }
    });
  }

  void _loadEvents() {
    setState(() {
      _updatingEvents = true;
    });
    Groups().loadEvents(_group, limit: 3).then((Map<int, List<GroupEvent>> eventsMap) {
      if (mounted) {
        setState(() {
          bool hasEventsMap = AppCollection.isCollectionNotEmpty(eventsMap?.values);
          _allEventsCount = hasEventsMap ? eventsMap.keys.first : 0;
          _groupEvents = hasEventsMap ? eventsMap.values.first : null;
          _updatingEvents = false;
        });
      }
    });
  }

  void _refreshEvents() {
    Groups().loadEvents(_group, limit: 3).then((Map<int, List<GroupEvent>> eventsMap) {
      if (mounted) {
        setState(() {
          bool hasEventsMap = AppCollection.isCollectionNotEmpty(eventsMap?.values);
          _allEventsCount = hasEventsMap ? eventsMap.keys.first : 0;
          _groupEvents = hasEventsMap ? eventsMap.values.first : null;
        });
      }
    });
  }

  void _loadInitialPosts() {
    if ((_group != null) && _group.currentUserIsMemberOrAdmin) {
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

  void _refreshCurrentPosts({int delta}) {
    if ((_group != null) && _group.currentUserIsMemberOrAdmin && (_refreshingPosts != true)) {
      int limit = _visibleGroupPosts.length + (delta ?? 0);
      _refreshingPosts = true;
      Groups().loadGroupPosts(widget.groupId, offset: 0, limit: limit, order: GroupSortOrder.desc).then((List<GroupPost> posts) {
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
    if ((_group != null) && _group.currentUserIsMemberOrAdmin && (_loadingPostsPage != true)) {
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
    List<GroupPost> postsPage = await Groups().loadGroupPosts(widget.groupId, offset: _visibleGroupPosts.length, limit: _postsPageSize, order: GroupSortOrder.desc);
    if (postsPage != null) {
      _visibleGroupPosts.addAll(postsPage);
      if (postsPage.length < _postsPageSize) {
        _hasMorePosts = false;
      }
    }
  }

  void _cancelMembershipRequest() {
    _setConfirmationLoading(true);
    Groups().cancelRequestMembership(widget.groupId).whenComplete(() {
      if (mounted) {
        _setConfirmationLoading(false);
        _loadGroup();
      }
    });
  }

  Future<void> _leaveGroup() {
    _setConfirmationLoading(true);
    return Groups().leaveGroup(widget.groupId).whenComplete(() {
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
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: TabBarWidget(),
        body: content);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Groups.notifyUserMembershipUpdated) {
      if (mounted) {
        setState(() {});
      }
    }
    else if (name == Groups.notifyGroupEventsUpdated) {
      _loadEvents();
    }
    else if (param == widget.groupId && (name == Groups.notifyGroupCreated || name == Groups.notifyGroupUpdated)) {
      _loadGroup(loadEvents: true);
    } else if (name == Groups.notifyGroupPostsUpdated) {
      _refreshCurrentPosts(delta: param is int ? param : null);
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refreshGroup(refreshEvents: true);
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
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary), ),
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
              child: Text(Localization().getStringEx("panel.group_detail.label.error_message", 'Failed to load group data.'),  style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 20, color: Styles().colors.fillColorPrimary),)
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

    return Column(children: <Widget>[
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
    return Container(
      height: 200,
      color: Styles().colors.background,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          AppString.isStringNotEmpty(_group?.imageURL) ?  Positioned.fill(child:Image.network(_group?.imageURL, fit: BoxFit.cover, headers: Network.appAuthHeaders,)) : Container(),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors.fillColorSecondaryTransparent05, left: false),
            child: Container(
              height: 53,
            ),
          ),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors.white),
            child: Container(
              height: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfo() {
    List<Widget> commands = [];

    String members;
    int membersCount = _group?.membersCount ?? 0;
    if (membersCount == 0) {
      members = Localization().getStringEx("panel.group_detail.members.count.empty", "No Current Members");
    }
    else if (membersCount == 1) {
      members = Localization().getStringEx("panel.group_detail.members.count.one", "1 Current Member");
    }
    else {
      members = sprintf(Localization().getStringEx("panel.group_detail.members.count.format", "%s Current Members"),[membersCount]);
    }

    int pendingCount = _group?.pendingCount ?? 0;
    String pendingMembers;
    if (_group.currentUserIsAdmin && pendingCount > 0) {
      pendingMembers = pendingCount > 1 ?
        sprintf(Localization().getStringEx("panel.group_detail.pending_members.count.format", "%s Pending Members"), [pendingCount]) :
        Localization().getStringEx("panel.group_detail.pending_members.count.one", "1 Pending Member");
    }
    else {
      pendingMembers = "";
    }

    if (_isMemberOrAdmin) {
      if(_isAdmin){
        commands.add(RibbonButton(
          height: null,
          label: Localization().getStringEx("panel.group_detail.button.manage_members.title", "Manage Members"),
          hint: Localization().getStringEx("panel.group_detail.button.manage_members.hint", ""),
          leftIcon: 'images/icon-member.png',
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
          onTap: _onTapMembers,
        ));
        commands.add(Container(height: 1, color: Styles().colors.surfaceAccent,));
        commands.add(RibbonButton(
          height: null,
          label: Localization().getStringEx("panel.group_detail.button.group_settings.title", "Group Settings"),
          hint: Localization().getStringEx("panel.group_detail.button.group_settings.hint", ""),
          leftIcon: 'images/icon-gear.png',
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
          onTap: _onTapSettings,
        ));
      }
      if (AppString.isStringNotEmpty(_group?.webURL)) {
        commands.add(Container(height: 1, color: Styles().colors.surfaceAccent));
        commands.add(_buildWebsiteLink());
      }
    } else {
      if (AppString.isStringNotEmpty(_group?.webURL)) {
        commands.add(_buildWebsiteLink());
      }

      String tags = "";
      if (_group?.tags?.isNotEmpty ?? false) {
        for (String tag in _group.tags) {
          if (0 < (tag?.length ?? 0)) {
            tags+=((tags.isNotEmpty? ", ": "") + tag ?? '');
          }
        }
      }

      if(tags?.isNotEmpty ?? false) {
        commands.add(Container(height: 12,));
        commands.add(
          Padding(padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child:
              RichText(
                text: new TextSpan(
                  style: TextStyle(color: Styles().colors.textSurface,
                      fontFamily: Styles().fontFamilies.bold,
                      fontSize: 12),
                  children: <TextSpan>[
                    new TextSpan(text: Localization().getStringEx("panel.group_detail.label.tags", "Group Tags: ")),
                    new TextSpan(
                        text: tags,
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies.regular)),
                  ],
                ),
              )
              )
            ],),
          ),);
      }
    }

    return Container(color: Colors.white,
      child: Stack(children: <Widget>[
        Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _isMemberOrAdmin ? Container():
                Padding(padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: <Widget>[
                    Expanded(child:
                      Text(_group?.category?.toUpperCase() ?? '', style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 12, color: Styles().colors.fillColorPrimary),),
                    ),
                  ],),),
              (!_isMemberOrAdmin)? Container():
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _group.currentUserStatusColor,
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                        child: Center(
                          child:
                          Semantics(
                            label: _group?.currentUserStatusText?.toLowerCase(),
                            excludeSemantics: true,
                            child: Text(_group.currentUserStatusText.toUpperCase(),
                              style: TextStyle(
                                  fontFamily: Styles().fontFamilies.bold,
                                  fontSize: 12,
                                  color: Styles().colors.white
                              ),
                            )
                          ),
                        ),
                      ),
                      Expanded(child: Container(),),
                    ],
                  ),
                ),
              Padding(padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(_group?.title ?? '',  style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 32, color: Styles().colors.fillColorPrimary),),
              ),
              Padding(padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(members,  style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.textBackground, ),)
              ),
              Visibility(
                visible: AppString.isStringNotEmpty(pendingMembers),
                child: Padding(padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(pendingMembers,  style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.textBackground, ),)
                ),
              ),
              Padding(padding: EdgeInsets.symmetric(vertical: 4),
                child: Column(children: commands,),
              ),
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
        case _DetailTab.About:
          title = Localization().getStringEx("panel.group_detail.button.about.title", 'About');
          break;
      }
      bool isSelected = (_currentTab == tab);

      if (0 < tabs.length) {
        tabs.add(Padding(
          padding: EdgeInsets.only(left: 8),
          child: Container(),
        ));
      }

      Widget tabWidget = RoundedButton(
          label: title,
          backgroundColor: isSelected ? Styles().colors.fillColorPrimary : Styles().colors.background,
          textColor: (isSelected ? Colors.white : Styles().colors.fillColorPrimary),
          fontFamily: isSelected ? Styles().fontFamilies.bold : Styles().fontFamilies.regular,
          fontSize: 16,
          padding: EdgeInsets.symmetric(horizontal: 16),
          borderColor: isSelected ? Styles().colors.fillColorPrimary : Styles().colors.surfaceAccent,
          borderWidth: 1,
          height: 22 + 16 * MediaQuery.of(context).textScaleFactor,
          onTap: () => _onTab(tab));

      tabs.add(tabWidget);
    }

    if (_canLeaveGroup) {
      tabs.add(Expanded(child: Container()));
      Widget leaveButton = GestureDetector(
          onTap: _onTapLeave,
          child: Padding(
              padding: EdgeInsets.only(left: 12, top: 10, bottom: 10),
              child: Text(Localization().getStringEx("panel.group_detail.button.leave.title", 'Leave'),
                  style: TextStyle(
                      fontSize: 14,
                      fontFamily: Styles().fontFamilies.regular,
                      color: Styles().colors.fillColorPrimary,
                      decoration: TextDecoration.underline,
                      decorationColor: Styles().colors.fillColorSecondary,
                      decorationThickness: 1.5))));
      tabs.add(leaveButton);
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Row(children: tabs));
  }

  Widget _buildEvents() {
    List<Widget> content = [];

//    if (_isAdmin) {
//      content.add(_buildAdminEventOptions());
//    }

    if (AppCollection.isCollectionNotEmpty(_groupEvents)) {
      for (GroupEvent groupEvent in _groupEvents) {
        content.add(GroupEventCard(groupEvent: groupEvent, group: _group, isAdmin: _isAdmin));
      }

      content.add(Padding(
          padding: EdgeInsets.only(top: 16),
          child: ScalableSmallRoundedButton(
              label: Localization().getStringEx("panel.group_detail.button.all_events.title", 'See all events'),
              widthCoeficient: 2,
              backgroundColor: Styles().colors.white,
              textColor: Styles().colors.fillColorPrimary,
              fontFamily: Styles().fontFamilies.bold,
              fontSize: 16,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              borderColor: Styles().colors.fillColorSecondary,
              borderWidth: 2,
              onTap: () {
                Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupAllEventsPanel(group: _group)));
              })));
    }

    return Stack(children: [
      Column(children: <Widget>[
        SectionTitlePrimary(
            title: Localization().getStringEx("panel.group_detail.label.upcoming_events", 'Upcoming Events') + ' ($_allEventsCount)',
            iconPath: 'images/icon-calendar.png',
            rightIconPath: _canAddEvent ? "images/icon-add-20x18.png" : null,
            rightIconAction: _canAddEvent ? _onTapEventOptions : null,
            rightIconLabel: _canAddEvent ? Localization().getStringEx("panel.group_detail.button.create_event.title", "Create Event") : null,
            children: content)
      ]),
      _updatingEvents
          ? Center(
              child: Container(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary))))
          : Container()
    ]);
  }

  Widget _buildPosts() {
    List<Widget> postsContent = [];

    EdgeInsetsGeometry listPadding;

    if (AppCollection.isCollectionEmpty(_visibleGroupPosts)) {
      if (_isMemberOrAdmin) {
        Column(children: <Widget>[
          SectionTitlePrimary(
              title: Localization().getStringEx("panel.group_detail.label.posts", 'Posts'),
              iconPath: 'images/icon-calendar.png',
              listPadding: listPadding,
              rightIconPath: _canCreatePost ? "images/icon-add-20x18.png" : null,
              rightIconAction: _canCreatePost ? _onTapCreatePost : null,
              rightIconLabel: _canCreatePost ? Localization().getStringEx("panel.group_detail.button.create_post.title", "Create Post") : null,
              children: postsContent)
        ]);
      } else {
        return Container();
      }
    }
    
    if ((_group != null) && _group.currentUserIsMemberOrAdmin && (_hasMorePosts != false) && (0 < _visibleGroupPosts.length)) {
      String title = Localization().getStringEx('panel.group_detail.button.show_older.title', 'Show older');
      listPadding = EdgeInsets.only(left: 16, right: 16, bottom: 16);
      postsContent.add(Semantics(label: title, button: true, excludeSemantics: true,
        child: InkWell(onTap: _loadNextPostsPage,
          child: Container(height: 36,
            child: Align(alignment: Alignment.topCenter,
              child: (_loadingPostsPage == true) ?
                SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.white), )) :
                Text(title, style: TextStyle(fontFamily: Styles().fontFamilies.bold, color: Styles().colors.textColorPrimary, fontSize: 16, decoration: TextDecoration.underline ),),
            ),
          )
        )
      )
      );
    }
    
    int last = _visibleGroupPosts.length - 1;
    for (int i = last; i >= 0; i--) {
      GroupPost post = _visibleGroupPosts[i];
      if (i < last) {
        postsContent.add(Container(height: 16));
      }
      postsContent.add(GroupPostCard(key: (i == 0) ? _lastPostKey : null, post: post, group: _group));
    }

    return Column(children: <Widget>[
      SectionTitlePrimary(
          title: Localization().getStringEx("panel.group_detail.label.posts", 'Posts'),
          iconPath: 'images/icon-calendar.png',
          listPadding: listPadding,
          rightIconPath: _canCreatePost ? "images/icon-add-20x18.png" : null,
          rightIconAction: _canCreatePost ? _onTapCreatePost : null,
          rightIconLabel: _canCreatePost ? Localization().getStringEx("panel.group_detail.button.create_post.title", "Create Post") : null,
          children: postsContent)
    ]);
  }

  Widget _buildAbout() {
    String description = _group?.description ?? '';
    return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(padding: EdgeInsets.only(bottom: 4), child:
          Text( Localization().getStringEx("panel.group_detail.label.about_us",  'About us'), style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 16, color: Color(0xff494949), ),),
        ),
        ExpandableText(description, style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground, ), trimLines: 4, iconColor: Styles().colors.fillColorPrimary,),
      ],),);
  }

  Widget _buildPrivacyDescription() {
    String title, description;
    if (_group?.privacy == GroupPrivacy.private) {
      title = Localization().getStringEx("panel.group_detail.label.title.private", 'This is a Private Group');
      description = Localization().getStringEx("panel.group_detail.label.description.private", '\u2022 This group is only visible to members.\n\u2022 Anyone can search for the group with the exact name.\n\u2022 Only admins can see members.\n\u2022 Only members can see posts and group events.\n\u2022 All users can see group events if they are marked public.\n\u2022 All users can see admins.');
    }
    else if (_group?.privacy == GroupPrivacy.public) {
      title = Localization().getStringEx("panel.group_detail.label.title.public", 'This is a Public Group');
      description = Localization().getStringEx("panel.group_detail.label.description.public", '\u2022 Only admins can see members.\n\u2022 Only members can see posts.\n\u2022 All users can see group events, unless they are marked private.\n\u2022 All users can see admins.');
    }
    
    return (AppString.isStringNotEmpty(title) && AppString.isStringNotEmpty(description)) ?
      Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: EdgeInsets.only(bottom: 4), child:
            Text(title, style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 16, color: Color(0xff494949), ),),
          ),
          Text(description, style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground, ), ),
        ],),) :
      Container(width: 0, height: 0);
  }

  Widget _buildWebsiteLink() {
    return RibbonButton(
        label: Localization().getStringEx("panel.group_detail.button.website.title", 'Website'),
        icon: 'images/external-link.png',
        leftIcon: 'images/globe.png',
        padding: EdgeInsets.symmetric(horizontal: 0),
        onTap: _onWebsite);
  }

  Widget _buildAdmins() {
    if (AppCollection.isCollectionEmpty(_groupAdmins)) {
      return Container();
    }
    List<Widget> content = [];
    content.add(Padding(padding: EdgeInsets.only(left: 16), child: Container()));
    for (Member officer in _groupAdmins) {
      if (1 < content.length) {
        content.add(Padding(padding: EdgeInsets.only(left: 8), child: Container()));
      }
      content.add(_OfficerCard(groupMember: officer));
    }
    content.add(Padding(padding: EdgeInsets.only(left: 16), child: Container()));
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
                child: Text(Localization().getStringEx("panel.group_detail.label.admins", 'Admins'),
                    style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, color: Styles().colors.fillColorPrimary))),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: content))
          ]))
    ]);
  }

  Widget _buildMembershipRequest() {
    return
      Auth2().isOidcLoggedIn && _group.currentUserCanJoin
          ? Container(color: Colors.white,
              child: Padding(padding: EdgeInsets.all(16),
                  child: ScalableRoundedButton(label: Localization().getStringEx("panel.group_detail.button.request_to_join.title",  'Request to join'),
                    backgroundColor: Styles().colors.white,
                    textColor: Styles().colors.fillColorPrimary,
                    fontFamily: Styles().fontFamilies.bold,
                    fontSize: 16,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    borderColor: Styles().colors.fillColorSecondary,
                    borderWidth: 2,
                    onTap:() { _onMembershipRequest();  }
                  ),
              ),
            )
          : Container();
  }

  Widget _buildCancelMembershipRequest() {
    return
      Auth2().isOidcLoggedIn && _group.currentUserIsPendingMember
          ? Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.white,
                  child: Padding(padding: EdgeInsets.all(16),
                    child: ScalableRoundedButton(label: Localization().getStringEx("panel.group_detail.button.cancel_request.title",  'Cancel Request'),
                        backgroundColor: Styles().colors.white,
                        textColor: Styles().colors.fillColorPrimary,
                        fontFamily: Styles().fontFamilies.bold,
                        fontSize: 16,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        borderColor: Styles().colors.fillColorSecondary,
                        borderWidth: 2,
                        onTap:() { _onCancelMembershipRequest();  }
                    ),
                  )),
              _confirmationLoading ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary), ) : Container(),
            ],
          )
          : Container();
  }

  Widget _buildConfirmationDialog(
      {String confirmationTextMsg, String positiveButtonLabel, String negativeButtonLabel, Function onPositiveTap, double positiveBtnHorizontalPadding = 16}) {
    return Dialog(
        backgroundColor: Styles().colors.fillColorPrimary,
        child: StatefulBuilder(builder: (context, setStateEx) {
          return Padding(
              padding: EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Text(confirmationTextMsg,
                        textAlign: TextAlign.left, style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Styles().colors.white))),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                  RoundedButton(
                      label: AppString.getDefaultEmptyString(
                          value: negativeButtonLabel, defaultValue: Localization().getStringEx("panel.group_detail.button.back.title", "Back")),
                      fontFamily: "ProximaNovaRegular",
                      textColor: Styles().colors.fillColorPrimary,
                      borderColor: Styles().colors.white,
                      backgroundColor: Styles().colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      onTap: () {
                        Analytics().logAlert(text: confirmationTextMsg, selection: negativeButtonLabel);
                        Navigator.pop(context);
                      }),
                  Container(width: 16),
                  Stack(alignment: Alignment.center, children: [
                    RoundedButton(
                      label: positiveButtonLabel,
                      fontFamily: "ProximaNovaBold",
                      textColor: Styles().colors.fillColorPrimary,
                      borderColor: Styles().colors.white,
                      backgroundColor: Styles().colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: positiveBtnHorizontalPadding),
                      onTap: () {
                        Analytics().logAlert(text: confirmationTextMsg, selection: positiveButtonLabel);
                        onPositiveTap();
                      },
                    ),
                    _confirmationLoading
                        ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary))
                        : Container()
                  ])
                ])
              ]));
        }));
  }

  void _onGroupOptionsTap() {
    Analytics().logSelect(target: 'Group Options');
    int membersCount = _group?.membersCount ?? 0;
    String confirmMsg = (membersCount > 1)
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
                        height: null,
                        leftIcon: "images/icon-add-20x18.png",
                        label: Localization().getStringEx("panel.group_detail.button.create_post.title", "Create Post"),
                        onTap: () {
                          Navigator.of(context).pop();
                          _onTapCreatePost();
                        })),
                Visibility(
                    visible: _canLeaveGroup,
                    child: RibbonButton(
                        height: null,
                        leftIcon: "images/icon-leave-group.png",
                        label: Localization().getStringEx("panel.group_detail.button.leave_group.title", "Leave group"),
                        onTap: () {
                          Analytics().logSelect(target: "Leave group");
                          showDialog(
                              context: context,
                              builder: (context) => _buildConfirmationDialog(
                                  confirmationTextMsg:
                                      Localization().getStringEx("panel.group_detail.label.confirm.leave", "Are you sure you want to leave this group?"),
                                  positiveButtonLabel: Localization().getStringEx("panel.group_detail.button.leave.title", "Leave"),
                                  onPositiveTap: _onTapLeaveDialog)).then((value) => Navigator.pop(context));
                        })),
                Visibility(
                    visible: _canDeleteGroup,
                    child: RibbonButton(
                        height: null,
                        leftIcon: "images/icon-delete-group.png",
                        label: Localization().getStringEx("panel.group_detail.button.group.delete.title", "Delete group"),
                        onTap: () {
                          Analytics().logSelect(target: "Delete group");
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
                        height: null,
                        leftIcon: "images/icon-edit.png",
                        label: Localization().getStringEx("panel.group_detail.button.group.add_event.title", "Add public event"),
                        onTap: (){
                          Navigator.pop(context);
                          _onTapBrowseEvents();
                        })),
                Visibility(
                    visible: _canAddEvent,
                    child: RibbonButton(
                        height: null,
                        leftIcon: "images/icon-edit.png",
                        label: Localization().getStringEx("panel.group_detail.button.group.create_event.title", "Create group event"),
                        onTap: (){
                          Navigator.pop(context);
                          _onTapCreateEvent();
                        })),
              ]));
        });
  }

  void _onTapEventOptions() {
    Analytics().logSelect(target: "Event options");
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
                        height: null,
                        leftIcon: "images/icon-edit.png",
                        label: Localization().getStringEx("panel.group_detail.button.group.add_event.title", "Add public event"),
                        onTap: (){
                          Navigator.pop(context);
                          _onTapBrowseEvents();
                        })),
                Visibility(
                    visible: _canAddEvent,
                    child: RibbonButton(
                        height: null,
                        leftIcon: "images/icon-edit.png",
                        label: Localization().getStringEx("panel.group_detail.button.group.create_event.title", "Create group event"),
                        onTap: (){
                          Navigator.pop(context);
                          _onTapCreateEvent();
                        })),
              ]));
        });
  }

  void _onTab(_DetailTab tab) {
    Analytics().logSelect(target: "Tab: $tab");
    if (_currentTab != tab) {
      setState(() {
        _currentTab = tab;
      });
      
      if ((_currentTab == _DetailTab.Posts)) {
        if (AppCollection.isCollectionNotEmpty(_visibleGroupPosts)) {
          _scheduleLastPostScroll();
        }
      }
    }
  }

  void _onTapLeave() {
    Analytics().logSelect(target: "Leave Group");
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
    Analytics().logSelect(target: 'Group url');
    String url = _group?.webURL;
    if (AppString.isStringNotEmpty(url)) {
      launch(url);
    }
  }

  void _onTapMembers(){
    Analytics().logSelect(target: "Group Members");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembersPanel(group: _group)));
  }

  void _onTapSettings(){
    Analytics().logSelect(target: "Group Settings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupSettingsPanel(group: _group,)));
  }

  void _onMembershipRequest() {
    Analytics().logSelect(target: "Request to join", attributes: widget.group.analyticsAttributes);
    if (AppCollection.isCollectionNotEmpty(_group?.questions)) {
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
    Analytics().logSelect(target: "Cancel membership request");
    showDialog(
        context: context,
        builder: (context) => _buildConfirmationDialog(
            confirmationTextMsg:
                Localization().getStringEx("panel.group_detail.label.confirm.cancel", "Are you sure you want to cancel your request to join this group?"),
            positiveButtonLabel: Localization().getStringEx("panel.group_detail.button.dialog.cancel_request.title", "Cancel request"),
            onPositiveTap: _onTapCancelMembershipDialog, positiveBtnHorizontalPadding: 1.5));
  }

  void _onTapCancelMembershipDialog() {
    _cancelMembershipRequest();
    Navigator.pop(context);
  }

  void _onTapCreateEvent(){
    Analytics().logSelect(target: "Create Event");
    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEventPanel(group: _group,)));
  }

  void _onTapBrowseEvents(){
    Analytics().logSelect(target: "Browse Events");
    Navigator.push(context, MaterialPageRoute(builder: (context) => ExplorePanel(browseGroupId: _group?.id, initialFilter: ExploreFilter(type: ExploreFilterType.event_time, selectedIndexes: {0/*Upcoming*/} ),)));
  }

  void _onTapCreatePost() {
    Analytics().logSelect(target: "Create Post");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostDetailPanel(group: _group))).then((result) {
      if (_refreshingPosts != true) {
        _refreshCurrentPosts();
      }
      if (result == true) {
        _shouldScrollToLastAfterRefresh = true;
      }
    });
  }

  void _scheduleLastPostScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastPost();
    });
  }

  void _scrollToLastPost() {
    BuildContext currentContext = _lastPostKey?.currentContext;
    if (currentContext != null) {
      Scrollable.ensureVisible(currentContext, duration: Duration(milliseconds: 10));
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
}

class _OfficerCard extends StatelessWidget {
  final Member groupMember;
  
  _OfficerCard({this.groupMember});

  @override
  Widget build(BuildContext context) {

    return Container(
      width: 128,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Container(height: 144, width: 128,
          decoration: BoxDecoration(
            image: DecorationImage(image: AppString.isStringNotEmpty(groupMember?.photoURL) ? NetworkImage(groupMember?.photoURL) : AssetImage('images/missing-photo-placeholder.png'), fit: BoxFit.contain),
              borderRadius: BorderRadius.all(Radius.circular(4))),
          ),
        Padding(padding: EdgeInsets.only(top: 4),
          child: Text(groupMember?.name ?? "", style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary),),),
        Text(groupMember?.officerTitle ?? "", style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground),),
      ],),
    );
  }
}