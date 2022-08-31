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
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/groups/GroupMemberPanel.dart';
import 'package:illinois/ui/groups/GroupPendingMemberPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class GroupMembersPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Group? group;

  String? get groupId => group?.id;

  GroupMembersPanel({required this.group});

  @override
  _GroupMembersPanelState createState() => _GroupMembersPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group?.analyticsAttributes;
}

class _GroupMembersPanelState extends State<GroupMembersPanel> implements NotificationsListener {
  static final int _defaultMembersLimit = 10;

  Group? _group;
  List<Member>? _visibleMembers;
  int? _membersOffset;
  int? _membersLimit;
  ScrollController? _scrollController;
  GroupMemberStatus? _selectedMemberStatus;
  List<GroupMemberStatus>? _sortedMemberStatusList;
  bool _statusValuesVisible = false;
  int _loadingProgress = 0;

  String? _searchTextValue;
  TextEditingController _searchEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Groups.notifyUserMembershipUpdated, Groups.notifyGroupUpdated]);
    _scrollController = ScrollController();
    _scrollController!.addListener(_scrollListener);
    _buildSortedMemberStatusList();
    _reloadGroupContent();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  ///
  /// Constructs alphabetically sorted list of GroupMemberStatus values
  ///
  void _buildSortedMemberStatusList() {
    _sortedMemberStatusList = GroupMemberStatus.values.toList();
    _sortedMemberStatusList?.sort((s1, s2) => s1.toString().compareTo(s2.toString()));
  }

  void _reloadGroupContent() {
    _loadGroup();
    _reloadMembers();
  }

  void _loadGroup() {
    _increaseProgress();
    Groups().loadGroup(widget.groupId).then((Group? group) {
      _group = group;
      _decreaseProgress();
    });
  }

  void _loadMembers({bool showLoadingIndicator = true}) {
    if ((_visibleMembers == null) || ((_membersLimit != null) && (_membersOffset != null) && !_isLoading)) {
      if (showLoadingIndicator) {
        _increaseProgress();
      }
      List<GroupMemberStatus>? memberStatuses;
      if (_selectedMemberStatus != null) {
        memberStatuses = [_selectedMemberStatus!];
      }
      Groups().loadMembers(groupId: widget.groupId, name: _searchTextValue, statuses: memberStatuses, offset: _membersOffset, limit: _membersLimit).then((members) {
        int resultsCount = members?.length ?? 0;
        if (resultsCount > 0) {
          if (_visibleMembers == null) {
            _visibleMembers = <Member>[];
          }
          _visibleMembers!.addAll(members!);
        }
        _setMembersPagingParams(resultsCount: resultsCount);
        if (showLoadingIndicator) {
          _decreaseProgress();
        } else {
          _updateState();
        }
      });
    }
  }

  void _reloadMembers() {
    _initMembersPagingParamsToDefaults();
    _visibleMembers = null;
    _loadMembers();
  }

  @override
  void onNotification(String name, param) {
    if (name == Groups.notifyUserMembershipUpdated) {
      if (mounted) {
        setState(() {});
      }
    }
    else if ((param == _group!.id) && (name == Groups.notifyGroupUpdated)){
      _reloadGroupContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    String headerTitle = _isAdmin
        ? Localization().getStringEx("panel.manage_members.header.admin.title", "Manage Members")
        : Localization().getStringEx("panel.manage_members.header.member.title", "Members");
    return Scaffold(
        backgroundColor: Styles().colors!.background,
        appBar: HeaderBar(title: headerTitle),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary)))
            : RefreshIndicator(
                onRefresh: _onPullToRefresh,
                child: SingleChildScrollView(
                    physics: _statusValuesVisible ? NeverScrollableScrollPhysics() : AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    child: _buildMembersContent())),
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildMembersContent() {
    late Widget contentWidget;
    if (CollectionUtils.isEmpty(_visibleMembers)) {
      contentWidget = Center(
          child: Column(children: <Widget>[
        Container(height: MediaQuery.of(context).size.height / 5),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(_getEmptyMembersMessage(), textAlign: TextAlign.center,
                style: Styles().getTextStyle('widget.group.members.title'))),
        Container(height: MediaQuery.of(context).size.height / 4)
      ]));
    } else {
      List<Widget> members = [];
      for (Member member in _visibleMembers!) {
        if (members.isNotEmpty) {
          members.add(Container(height: 10));
        }
        late Widget memberCard;
        if (member.status == GroupMemberStatus.pending) {
          memberCard = _PendingMemberCard(member: member, group: _group);
        } else {
          memberCard = _GroupMemberCard(member: member, group: _group);
        }
        members.add(memberCard);
      }
      if (members.isNotEmpty) {
        members.add(Container(height: 10));
      }
      contentWidget = Column(children: members);
    }

    return Column(children: <Widget>[
      Container(
          child: SectionRibbonHeader(
              title: (_selectedMemberStatus == GroupMemberStatus.pending)
                  ? Localization().getStringEx("panel.manage_members.label.requests", "Requests")
                  : Localization().getStringEx("panel.manage_members.label.members", "Members"),
              titleIconAsset: 'images/icon-member.png')),
      _buildMembersSearch(),
      Padding(
          padding: EdgeInsets.only(left: 16, top: 16, right: 16),
          child: RibbonButton(
              textColor: Styles().colors!.fillColorSecondary,
              backgroundColor: Styles().colors!.white,
              borderRadius: BorderRadius.all(Radius.circular(5)),
              border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
              rightIconAsset: (_statusValuesVisible ? 'images/icon-up.png' : 'images/icon-down-orange.png'),
              label: _memberStatusToString(_selectedMemberStatus),
              onTap: _onTapRibbonButton)),
      Stack(children: [
        Padding(padding: EdgeInsets.only(top: 16, left: 16, right: 16), child: contentWidget),
        _buildStatusValuesContainer()
      ])
    ]);
  }

  Widget _buildMembersSearch() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: EdgeInsets.only(left: 16),
        color: Colors.white,
        height: 48,
        child: Row(
          children: <Widget>[
            Flexible(
                child:
                Semantics(
                  label: Localization().getStringEx('panel.manage_members.field.search.title', 'Search'),
                  hint: Localization().getStringEx('panel.manage_members.field.search.hint', ''),
                  textField: true,
                  excludeSemantics: true,
                  child: TextField(
                    // Do not allow searching when drop-down values are visible
                    enabled: !_statusValuesVisible,
                    readOnly: _statusValuesVisible,
                    controller: _searchEditingController,
                    onChanged: (text) => _onSearchTextChanged(text),
                    onSubmitted: (_) => _onTapSearch(),
                    autofocus: false,
                    cursorColor: Styles().colors!.fillColorSecondary,
                    keyboardType: TextInputType.text,
                    style:  Styles().getTextStyle('widget.group.members.search'),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                )
            ),
            Semantics(
                label: Localization().getStringEx('panel.manage_members.button.search.clear.title', 'Clear'),
                hint: Localization().getStringEx('panel.manage_members.button.search.clear.hint', ''),
                button: true,
                excludeSemantics: true,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: _onTapClearSearch,
                    child: Image.asset(
                        'images/icon-x-orange.png',
                        width: 25,
                        height: 25,
                        excludeFromSemantics: true
                    ),
                  ),
                )
            ),
            Semantics(
              label: Localization().getStringEx('panel.manage_members.button.search.title', 'Search'),
              hint: Localization().getStringEx('panel.manage_members.button.search.hint', ''),
              button: true,
              excludeSemantics: true,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: _onTapSearch,
                  child: Image.asset(
                      'images/icon-search.png',
                      color: Styles().colors!.fillColorSecondary,
                      width: 25,
                      height: 25,
                      excludeFromSemantics: true
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPullToRefresh() async {
    if ((_group?.syncAuthmanAllowed == true) && (Config().allowGroupsAuthmanSync)) {
      await Groups().syncAuthmanGroup(group: _group!);
    }
    _reloadGroupContent();
  }

  void _onSearchTextChanged(String text) {
    // implement if needed
  }

  void _onTapSearch() {
    if (_statusValuesVisible) {
      // Do not try to search when drop down values are visible.
      return;
    }
    String? initialSearchTextValue = _searchTextValue;
    _searchTextValue = _searchEditingController.text.toString();
    String? currentSearchTextValue = _searchTextValue;
    if (!(StringUtils.isEmpty(initialSearchTextValue) && StringUtils.isEmpty(currentSearchTextValue))) {
      FocusScope.of(context).unfocus();
      _reloadMembers();
    }
  }

  void _onTapClearSearch() {
    if (_statusValuesVisible) {
      // Do not try to clear search when drop down values are visible.
      return;
    }
    if (StringUtils.isNotEmpty(_searchTextValue)) {
      _searchEditingController.text = "";
      _searchTextValue = "";
      _reloadMembers();
    }
  }

  void _scrollListener() {
    if ((_scrollController!.offset >= _scrollController!.position.maxScrollExtent)) {
      _loadMembers(showLoadingIndicator: false);
    }
  }

   void _initMembersPagingParamsToDefaults() {
    _membersOffset = 0;
    _membersLimit = _defaultMembersLimit;
  }

  void _setMembersPagingParams({required int resultsCount}) {
    if (resultsCount > 0) {
      _membersOffset = (_membersOffset ?? 0) + resultsCount;
      _membersLimit = 10;
    } else {
      _membersOffset = null;
      _membersLimit = null;
    }
  }

  Widget _buildStatusValuesContainer() {
    return Visibility(
        visible: _statusValuesVisible,
        child: Positioned.fill(child: Stack(children: <Widget>[_buildStatusDismissLayer(), _buildStatusValuesWidget()])));
  }

  Widget _buildStatusDismissLayer() {
    return Positioned.fill(
        child: BlockSemantics(
            child: GestureDetector(
                onTap: () {
                  Analytics().logSelect(target: 'Close Dropdown');
                  setState(() {
                    _statusValuesVisible = false;
                  });
                },
                child: Container(color: Styles().colors!.blackTransparent06))));
  }

  Widget _buildStatusValuesWidget() {
    List<Widget> widgetList = <Widget>[];
    widgetList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    if (_selectedMemberStatus != null) {
      widgetList.add(_buildStatusItem(null));
    }
    if (CollectionUtils.isNotEmpty(_sortedMemberStatusList)) {
      for (GroupMemberStatus status in _sortedMemberStatusList!) {
        if ((_selectedMemberStatus != status)) {
          widgetList.add(_buildStatusItem(status));
        }
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: widgetList)));
  }

  Widget _buildStatusItem(GroupMemberStatus? status) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        rightIcon: null,
        label: _memberStatusToString(status),
        onTap: () => _onTapStatusItem(status));
  }

  void _onTapRibbonButton() {
    Analytics().logSelect(target: 'Toggle Dropdown');
    _changeMemberStatusValuesVisibility();
  }

  void _onTapStatusItem(GroupMemberStatus? status) {
    Analytics().logSelect(target: '$status');
    _selectedMemberStatus = status;
    _reloadMembers();
    _changeMemberStatusValuesVisibility();
  }

  void _changeMemberStatusValuesVisibility() {
    _statusValuesVisible = !_statusValuesVisible;
    _updateState();
  }

  void _increaseProgress() {
    _loadingProgress++;
    _updateState();
  }

  void _decreaseProgress() {
    _loadingProgress--;
    _updateState();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  String _getEmptyMembersMessage() {
    switch (_selectedMemberStatus) {
      case GroupMemberStatus.admin:
        return Localization().getStringEx('panel.manage_members.status.admin.empty.message', 'There are no admins.');
      case GroupMemberStatus.member:
        return Localization().getStringEx('panel.manage_members.status.member.empty.message', 'There are no members.');
      case GroupMemberStatus.pending:
        return Localization().getStringEx('panel.manage_members.status.pending.empty.message', 'There are no pending members.');
      case GroupMemberStatus.rejected:
        return Localization().getStringEx('panel.manage_members.status.rejected.empty.message', 'There are no rejected members.');
      default: // All
        return Localization().getStringEx('panel.manage_members.status.all.empty.message', 'There are no members.');
    }
  }

  static String? _memberStatusToString(GroupMemberStatus? status) {
    switch (status) {
      case GroupMemberStatus.admin:
        return Localization().getStringEx('panel.manage_members.member.status.admin.label', 'Admin');
      case GroupMemberStatus.member:
        return Localization().getStringEx('panel.manage_members.member.status.member.label', 'Member');
      case GroupMemberStatus.pending:
        return Localization().getStringEx('panel.manage_members.member.status.pending.label', 'Pending');
      case GroupMemberStatus.rejected:
        return Localization().getStringEx('panel.manage_members.member.status.rejected.label', 'Rejected');
      default:
        return Localization().getStringEx('panel.manage_members.member.status.all.label', 'All');
    }
  }

  bool get _isLoading {
    return (_loadingProgress > 0);
  }

  bool get _isAdmin {
    return _group?.currentMember?.isAdmin ?? false;
  }
}

class _PendingMemberCard extends StatelessWidget {
  final Member? member;
  final Group? group;
  _PendingMemberCard({required this.member, this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Styles().colors!.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1, style: BorderStyle.solid)
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: <Widget>[
          ClipRRect(
              borderRadius: BorderRadius.circular(65),
              child: Container(width: 65, height: 65, child: GroupMemberProfileImage(userId: member?.userId))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    member?.displayName ?? "",
                    style: Styles().getTextStyle('widget.group.members.title'),
                  ),
                  Container(height: 4,),
                      RoundedButton(
                        label: Localization().getStringEx("panel.manage_members.button.review_request.title", "Review Request"),
                        hint: Localization().getStringEx("panel.manage_members.button.review_request.hint", ""),
                        borderColor: Styles().colors!.fillColorSecondary,
                        textColor: Styles().colors!.fillColorPrimary,
                        backgroundColor: Styles().colors!.white,
                        fontSize: 16,
                        rightIcon: Image.asset('images/chevron-right.png'),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        onTap: (){
                          Analytics().logSelect(target:"Review request");
                          Navigator.push(context, CupertinoPageRoute(builder: (context)=> GroupPendingMemberPanel(member: member, group: group,)));
                        },
                      ),
                ],
              ),
            ),
          ),
          Container(width: 8,)
        ],
      ),
    );
  }
}

class _GroupMemberCard extends StatelessWidget {
  final Member? member;
  final Group? group;
  _GroupMemberCard({required this.member, required this.group});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=>_onTapMemberCard(context),
      child: Container(
        decoration: BoxDecoration(
            color: Styles().colors!.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1, style: BorderStyle.solid)
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: <Widget>[
            ClipRRect(
                borderRadius: BorderRadius.circular(65),
                child: Container(width: 65, height: 65, child: GroupMemberProfileImage(userId: member?.userId))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child:
                          Text(StringUtils.ensureNotEmpty(_memberDisplayName),
                            style: Styles().getTextStyle('widget.group.members.title')
                          )
                        )
                      ],
                    ),
                    Container(height: 4,),
                    Row(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: groupMemberStatusToColor(member!.status),
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                          child: Center(
                            child: Text(groupMemberStatusToDisplayString(member!.status)!.toUpperCase(),
                              style: Styles().getTextStyle('widget.heading.small')
                            ),
                          ),
                        ),
                        Visibility(
                            visible: _displayAttended,
                            child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.all(Radius.circular(2))),
                                    child: Center(
                                        child: Text(Localization().getStringEx('widget.group.member.card.attended.label', 'ATTENDED'),
                                            style: Styles().getTextStyle('widget.heading.small')))))),
                        Expanded(child: Container()),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTapMemberCard(BuildContext context) async {
    if (_isAdmin) {
      Analytics().logSelect(target: "Member Detail");
      await Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMemberPanel(group: group!, memberId: member!.id!)));
    }
  }

  String? get _memberDisplayName {
    if (_isAdmin) {
      return member?.displayName;
    } else {
      return member?.name;
    }
  }

  bool get _isAdmin {
    return group?.currentMember?.isAdmin ?? false;
  }

  bool get _displayAttended {
    return (group?.attendanceGroup == true) && _isAdmin && (member?.dateAttendedUtc != null);
  }
}