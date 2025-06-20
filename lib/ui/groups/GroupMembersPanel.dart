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
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/ui/groups/GroupMembersSearchPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/Log.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/groups/GroupMemberPanel.dart';
import 'package:illinois/ui/groups/GroupPendingMemberPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

import 'GroupAddMembersPanel.dart';

enum GroupMembersFilter { all, admin, member, pending, rejected }

class GroupMembersPanel extends StatefulWidget with AnalyticsInfo {
  final Group? group;

  String? get groupId => group?.id;

  GroupMembersPanel({required this.group});

  @override
  _GroupMembersPanelState createState() => _GroupMembersPanelState();

  @override
  AnalyticsFeature? get analyticsFeature => (group?.researchProject == true) ? AnalyticsFeature.ResearchProject : AnalyticsFeature.Groups;

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group?.analyticsAttributes;
}

class _GroupMembersPanelState extends State<GroupMembersPanel> with NotificationsListener {
  static final int _defaultMembersLimit = 10;

  Group? _group;
  List<Member>? _visibleMembers;
  int? _membersOffset;
  int? _membersLimit;
  ScrollController? _scrollController;
  late List<GroupMembersFilter> _memberFilters;
  late GroupMembersFilter _selectedMemberFilter;
  bool _statusValuesVisible = false;
  int _loadingProgress = 0;
  bool _isLoadingMembers = false;

  bool _switchToAllIfNoPendingMembers = false;

  String? _searchTextValue;
  late FocusNode _searchFocus;

  @override
  void initState() {
    super.initState();
    
    NotificationService().subscribe(this, [
      Groups.notifyGroupMembershipApproved, 
      Groups.notifyGroupMembershipRejected,
      Groups.notifyGroupMembershipRemoved,
      FirebaseMessaging.notifyGroupsNotification,
    ]);

    _searchFocus = FocusNode();
    _scrollController = ScrollController();
    _scrollController?.addListener(_scrollListener);

    _group = widget.group;

    _memberFilters = _buildMemberFilters();

    // First try to load pending members if the user is admin.
    if (widget.group?.currentUserIsAdmin == true) {
      _selectedMemberFilter = GroupMembersFilter.pending;
      _switchToAllIfNoPendingMembers = true;
    }
    else {
      _selectedMemberFilter = _ensureMemberFilter(GroupMembersFilter.all, filters: _memberFilters) ??
          _defaultMemberFilter(filters: _memberFilters);
    }
    _reloadGroupContent();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void onNotification(String name, param) {
    bool reloadMembers = false;
    if ((name == Groups.notifyGroupMembershipApproved) ||
        (name == Groups.notifyGroupMembershipRejected) ||
        (name == Groups.notifyGroupMembershipRemoved)) {
      Group? group = (param is Group) ? param : null;
      reloadMembers = (group?.id != null) && (group?.id == _group?.id);
    }
    else if (name == FirebaseMessaging.notifyGroupsNotification) {
      String? groupId = (param is Map) ? JsonUtils.stringValue(param['entity_id']) : null;
      reloadMembers = (groupId != null) && (groupId == _group?.id);
    }

    if (reloadMembers) {
      // Switch to all members if there are no more pending users
      if (_selectedMemberFilter == GroupMemberStatus.pending) {
        _switchToAllIfNoPendingMembers = true;
      }
      _reloadMembers();
    }
  }

  @override
  Widget build(BuildContext context) {
    String headerTitle;
    if (_isAdmin) {
      headerTitle = _isResearchProject ? "Manage Participants" : Localization().getStringEx("panel.manage_members.header.admin.title", "Manage Members");
    }
    else {
      headerTitle = _isResearchProject ? "Participants" : Localization().getStringEx("panel.manage_members.header.member.title", "Members");
    }
    return Scaffold(
        backgroundColor: Styles().colors.background,
        appBar: HeaderBar(title: headerTitle),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary)))
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
            child: Text(_emptyStatusText, textAlign: TextAlign.center,
                style: Styles().textStyles.getTextStyle('widget.group.members.title'))),
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
          memberCard = PendingMemberCard(member: member, group: _group);
        } else {
          memberCard = GroupMemberCard(member: member, group: _group);
        }
        members.add(memberCard);
      }
      if (members.isNotEmpty) {
        members.add(Container(height: 10));
      }
      contentWidget = Column(children: members);
    }

    return Column(children: <Widget>[
        Visibility(visible: 1 < CollectionUtils.length(_memberFilters), child:
          Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
          RibbonButton(
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
            backgroundColor: Styles().colors.white,
            borderRadius: BorderRadius.all(Radius.circular(5)),
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
            rightIconKey: _statusValuesVisible ? 'chevron-up' : 'chevron-down',
            label: _selectedMemberStatusFilterTitle,
            onTap: _onTapRibbonButton))),
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          Row(
            children: [
              Expanded(child: _buildDateUpdatedFields()),
              Padding(padding: EdgeInsets.only(right: 16), child:
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildApproveAllButton(),
                    _buildSearchButton(),
                    _buildAddButton()
                  ],
                )
              )
            ],
          )
        ),
        Stack(children: [
          Padding(padding: EdgeInsets.only(top: 0, left: 16, right: 16), child: contentWidget),
          Visibility(visible: _statusValuesVisible, child: _buildStatusDismissLayer()),
          Visibility(visible: _statusValuesVisible, child: _buildStatusValuesWidget()),
        ])
    ]);
  }

  Widget _buildApproveAllButton() {
    return Visibility(visible: _isApproveAllVisible, child:
      GestureDetector(
        onTap: _onTapApproveAll,
        child: Padding(
            padding: EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: Text(Localization().getStringEx("panel.manage_members.button.approve_all.title", 'Approve All'),
                style: Styles().textStyles.getTextStyle('panel.group.button.leave.title')
            ))));
  }

  Widget _buildSearchButton(){
    return  Semantics(
      label: Localization().getStringEx('panel.manage_members.button.search.title', 'Search'),
      hint: Localization().getStringEx('panel.manage_members.button.search.hint', ''),
      button: true,
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(left: 8, top: 8, bottom: 8),
        child: GestureDetector(
          onTap: _onTapSearch,
          child: Styles().images.getImage('search', excludeFromSemantics: true),
        ),
      ),
    );
  }

  Widget _buildAddButton(){
    return  Visibility( visible: _canAddMembers,
      child: Semantics(
        label: Localization().getStringEx('', 'Add members'), //TBD localize
        hint: Localization().getStringEx('panel.manage_members.button.search.hint', ''),
        button: true,
        excludeSemantics: true,
        child: Padding(
          padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: _onTapAddMembers,
            child: Styles().images.getImage('plus-circle', excludeFromSemantics: true),
          ),
        ),
      )
    );
  }

  Widget _buildDateUpdatedFields() {
    if (!_isAdmin) {
      return Container();
    }
    bool showSynced = _group?.authManEnabled == true && StringUtils.isNotEmpty(_group?.displayManagedMembershipUpdateTime);
    bool showUpdated = StringUtils.isNotEmpty(_group?.displayMembershipUpdateTime);

    return Visibility(visible: showSynced || showUpdated,
      child: Container(child: Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
        Visibility(visible: showSynced, child:
          Semantics(container: true, child:
            Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
              Padding(padding: EdgeInsets.only(right: 5), child: Text(Localization().getStringEx('panel.group_detail.date.updated.managed.membership.label', 'Synced:'), style: Styles().textStyles.getTextStyle('widget.detail.small.fat'))),
              Expanded(child:
                Text(StringUtils.ensureNotEmpty(_group?.displayManagedMembershipUpdateTime, defaultValue: 'N/A'), style: Styles().textStyles.getTextStyle('widget.detail.small'), overflow: TextOverflow.ellipsis)
              )
        ]))),
        Visibility(visible: showUpdated, child:
          Semantics(container: true, child:
          Padding(padding: EdgeInsets.only(top: 5), child:
            Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
              Padding(padding: EdgeInsets.only(right: 5), child: Text(Localization().getStringEx('panel.group_detail.date.updated.membership.label', 'Updated:'), style: Styles().textStyles.getTextStyle('widget.detail.small.fat'))),
              Expanded(child:
                Text(StringUtils.ensureNotEmpty(_group?.displayMembershipUpdateTime, defaultValue: 'N/A'), style: Styles().textStyles.getTextStyle('widget.detail.small'), overflow: TextOverflow.ellipsis,)
              )
        ]))))
    ]))));
  }

  Future<void> _onPullToRefresh() async {
    if ((_group?.syncAuthmanAllowed == true) && (Config().allowGroupsAuthmanSync)) {
      await Groups().syncAuthmanGroup(group: _group!);
    }
    _reloadGroupContent();
  }

  void _onTapSearch(){
    Analytics().logSelect(target: "Group Members Search", attributes: _group?.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembersSearchPanel(group: _group, selectedMemberStatus: _selectedMemberFilter.memberStatus)));
  }

  void _onTapAddMembers(){
    Analytics().logSelect(target: "Group Members Add Members", attributes: _group?.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupAddMembersPanel(group: _group, selectedMemberStatus: _selectedMemberFilter.memberStatus))); //TBD
  }

  void _onTapApproveAll(){
    AppAlert.showConfirmationDialog(context,
      message: Localization().getStringEx('', 'Do you want to approve all pending user requests?'),
      positiveCallback: _onTapConfirmApproveAll
    );
  }

  _onTapConfirmApproveAll(){
    _increaseProgress();
    Groups().loadMembers(groupId: widget.groupId, statuses: [GroupMemberStatus.pending]).then((members) {
      if(CollectionUtils.isNotEmpty(members)){
        List<String>? pendingUserIds = MemberExt.extractUserIds(members);
        Groups().acceptMembershipMulti(group: _group, ids: pendingUserIds).then((success){
          if(success){
            Log.d("Successfully approved all");
          } else {
            AppAlert.showDialogResult(context, Localization().getStringEx("", 'Failed to approve  all pending user requests'));
          }
        });
      } else {
        //No members to approve
      }
    }).whenComplete(() => _decreaseProgress());
  }

  void _scrollListener() {
    if ((_scrollController!.offset >= _scrollController!.position.maxScrollExtent)) {
      _loadMembers(showLoadingIndicator: false);
    }
  }

  Widget _buildStatusDismissLayer() {
    return
    Container(
        constraints: BoxConstraints(minHeight:  MediaQuery.of(context).size.height),
        child: BlockSemantics(child:
          Semantics(label: "dismiss", child:
            GestureDetector(
              onTap: () {
                Analytics().logSelect(target: 'Close Dropdown');
                setState(() {
                  _statusValuesVisible = false;
                });
              },
              child: Container(color: Styles().colors.blackTransparent06)
            )
          )
        )
    );
  }

  Widget _buildStatusValuesWidget() {
    List<Widget> widgetList = <Widget>[];
    widgetList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (GroupMembersFilter statusFilter in _memberFilters) {
      widgetList.add(RibbonButton(
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        textStyle: Styles().textStyles.getTextStyle((_selectedMemberFilter == statusFilter) ? 'widget.button.title.medium.fat.secondary' : 'widget.button.title.medium.fat'),
        rightIconKey: (_selectedMemberFilter == statusFilter) ? 'check-accent' : null,
        label: _memberStatusFilterTitle(statusFilter),
        onTap: () => _onTapStatusFilter(statusFilter)
      ));
    }
    return Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 32), child: SingleChildScrollView(child: Column(children: widgetList)));
  }

  void _onTapRibbonButton() {
    Analytics().logSelect(target: 'Toggle Dropdown');
    if (1 < CollectionUtils.length(_memberFilters)) {
      _changeMemberStatusValuesVisibility();
    }
  }

  void _onTapStatusFilter(GroupMembersFilter status) {
    Analytics().logSelect(target: '$status');
    _selectedMemberFilter = status;
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

  ///
  /// Constructs alphabetically sorted list of GroupMemberStatus values
  ///
  List<GroupMembersFilter> _buildMemberFilters() {
    if (_group?.currentUserIsAdmin == true) {
      return <GroupMembersFilter>[GroupMembersFilter.all, GroupMembersFilter.admin, GroupMembersFilter.member, GroupMembersFilter.pending, GroupMembersFilter.rejected];
    }
    else if ((_group?.currentUserIsMember == true) && (_group?.researchProject != true)) {
        return <GroupMembersFilter>[GroupMembersFilter.all, GroupMembersFilter.admin, GroupMembersFilter.member];
    }
    else {
      return <GroupMembersFilter>[GroupMembersFilter.admin];
    }
  }

  GroupMembersFilter? _ensureMemberFilter(GroupMembersFilter? filter, { List<GroupMembersFilter>? filters }) =>
    (filters?.contains(filter) != false) ? filter : null;

  GroupMembersFilter _defaultMemberFilter({ List<GroupMembersFilter>? filters }) =>
    ((filters != null) && filters.isNotEmpty) ? filters.first : GroupMembersFilter.all;

  void _reloadGroupContent() {
    _loadGroup();
    _reloadMembers();
  }

  void _loadGroup() {
    _increaseProgress();
    Groups().loadGroup(widget.groupId).then((Group? group) {
      _group = group;
      _memberFilters = _buildMemberFilters();
      if (_memberFilters.contains(_selectedMemberFilter) == false) {
        _selectedMemberFilter = _memberFilters.isNotEmpty ? _memberFilters.first : GroupMembersFilter.admin;
      }
      _decreaseProgress();
    });
  }

  void _loadMembers({bool showLoadingIndicator = true}) async {
    if (!_isLoadingMembers && ((_visibleMembers == null) || ((_membersLimit != null) && (_membersOffset != null)))) {
      _isLoadingMembers = true;
      if (showLoadingIndicator) {
        _increaseProgress();
      }
      List<Member>? members = await Groups().loadMembers(groupId: widget.groupId, name: _searchTextValue, statuses: _selectedMemberFilter.memberStatuses, offset: _membersOffset, limit: _membersLimit);
      if (mounted && _switchToAllIfNoPendingMembers) {
        _switchToAllIfNoPendingMembers = false; // Do not switch after this

        int resultsCount = members?.length ?? 0;
        // If there are no pending members and the user is admin - select 'All' value
        if ((resultsCount == 0) && (_selectedMemberFilter == GroupMembersFilter.pending) && (widget.group?.currentUserIsAdmin ?? false)) {
          _selectedMemberFilter = _ensureMemberFilter(GroupMembersFilter.all, filters: _memberFilters) ?? _defaultMemberFilter(filters: _memberFilters); // All group statuses
          members = await Groups().loadMembers(groupId: widget.groupId, name: _searchTextValue, statuses: _selectedMemberFilter.memberStatuses, offset: _membersOffset, limit: _membersLimit);
        }
      }

      if (mounted) {
        int resultsCount = members?.length ?? 0;
        _isLoadingMembers = false;
        if (resultsCount > 0) {
          if (_visibleMembers == null) {
            _visibleMembers = <Member>[];
          }
          _visibleMembers!.addAll(members!);
          _membersOffset = (_membersOffset ?? 0) + resultsCount;
          _membersLimit = 10;
        }
        else {
          _membersOffset = null;
          _membersLimit = null;
        }

        if (showLoadingIndicator) {
          _decreaseProgress();
        } else {
          _updateState();
        }
      }
    }
  }

  void _reloadMembers() {
    _membersOffset = 0;
    _membersLimit = _defaultMembersLimit;
    _visibleMembers = null;
    _loadMembers();
  }

  String get _emptyStatusText =>
    _isResearchProject ? _selectedMemberFilter.emptyResearchProjectStatusText : _selectedMemberFilter.emptyGroupStatusText;

  String get _selectedMemberStatusFilterTitle =>
    _memberStatusFilterTitle(_selectedMemberFilter);

  String _memberStatusFilterTitle(GroupMembersFilter statusFilter) =>
    _isResearchProject ? statusFilter.displayResearchProjectTitle : statusFilter.displayGroupTitle;

  bool get _isLoading => (_loadingProgress > 0);
  bool get _isResearchProject => _group?.researchProject == true;
  bool get _isAdmin => _group?.currentMember?.isAdmin ?? false;
  bool get _isApproveAllVisible => _isAdmin && (_selectedMemberFilter == GroupMembersFilter.pending);
  bool get _canAddMembers => _isAdmin;
}

class PendingMemberCard extends StatelessWidget {
  final Member? member;
  final Group? group;
  PendingMemberCard({required this.member, this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Styles().colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1, style: BorderStyle.solid)
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
                    style: Styles().textStyles.getTextStyle('widget.group.members.title'),
                  ),
                  Container(height: 4,),
                      RoundedButton(
                        label: Localization().getStringEx("panel.manage_members.button.review_request.title", "Review Request"),
                        hint: Localization().getStringEx("panel.manage_members.button.review_request.hint", ""),
                        textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                        borderColor: Styles().colors.fillColorSecondary,
                        backgroundColor: Styles().colors.white,
                        rightIcon: Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true),
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

class GroupMemberCard extends StatelessWidget {
  final Member? member;
  final Group? group;
  GroupMemberCard({required this.member, required this.group});

  @override
  Widget build(BuildContext context) {
    String? memberStatus = (group?.researchProject == true) ? researchParticipantStatusToDisplayString(member?.status) : groupMemberStatusToDisplayString(member?.status);
    return GestureDetector(
      onTap: ()=>_onTapMemberCard(context),
      child: Container(
        decoration: BoxDecoration(
            color: Styles().colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1, style: BorderStyle.solid)
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: <Widget>[
            ClipRRect(
                borderRadius: BorderRadius.circular(65),
                child: Semantics(label: "user image", hint: "Double tap to zoom", child:
                  Container(width: 65, height: 65, child: GroupMemberProfileImage(userId: member?.userId)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child:
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(StringUtils.ensureNotEmpty(_memberDisplayName),
                                  style: Styles().textStyles.getTextStyle('widget.group.members.title')
                              ),
                              GroupProfilePronouncementWidget(accountId: member?.userId,)
                            ],
                          )
                        ),
                      ],
                    ),
                    Visibility(
                      visible: StringUtils.isNotEmpty(_memberDetailsString),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(StringUtils.ensureNotEmpty(_memberDetailsString),
                                style: Styles().textStyles.getTextStyle('widget.group.members.title')
                            ),
                          )
                      ],),
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
                            child: Text(memberStatus?.toUpperCase() ?? '',
                              style: Styles().textStyles.getTextStyle('widget.heading.extra_small')
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
                                        color: Styles().colors.fillColorPrimary, borderRadius: BorderRadius.all(Radius.circular(2))),
                                    child: Center(
                                        child: Text(Localization().getStringEx('widget.group.member.card.attended.label', 'ATTENDED'),
                                            style: Styles().textStyles.getTextStyle('widget.heading.extra_small')))))),
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

  String? get _memberDisplayName => member?.name;

  String? get _memberDetailsString{
    if (_isAdmin) {
      String details = '';
      if (StringUtils.isNotEmpty(member?.email)) {
        if (StringUtils.isNotEmpty(details)) {
          details += ' ';
        }
        details += member?.email! ?? "";
      }

      return details;
    }

    return "";
  }

  bool get _isAdmin {
    return group?.currentMember?.isAdmin ?? false;
  }

  bool get _displayAttended {
    return (group?.attendanceGroup == true) && _isAdmin && (member?.dateAttendedUtc != null);
  }
}

extension GroupMembersFilterImpl on GroupMembersFilter {
  String get displayGroupTitle => displayGroupTitleLng();
  String get displayGroupTitleEn => displayGroupTitleLng('en');

  String displayGroupTitleLng([String? language]) {
    switch (this) {
      case GroupMembersFilter.all: return Localization().getStringEx('panel.manage_members.member.status.all.label', 'All');
      case GroupMembersFilter.admin: return Localization().getStringEx('panel.manage_members.member.status.admin.label', 'Admin');
      case GroupMembersFilter.member: return Localization().getStringEx('panel.manage_members.member.status.member.label', 'Member');
      case GroupMembersFilter.pending: return Localization().getStringEx('panel.manage_members.member.status.pending.label', 'Pending');
      case GroupMembersFilter.rejected: return Localization().getStringEx('panel.manage_members.member.status.rejected.label', 'Denied');
    }
  }

  String get displayResearchProjectTitle => displayResearchProjectTitleLng();
  String get displayResearchProjectTitleEn => displayResearchProjectTitleLng('en');

  String displayResearchProjectTitleLng([String? language]) {
    switch (this) {
      case GroupMembersFilter.all: return Localization().getStringEx('panel.manage_members.member.status.all.project.label', 'All');
      case GroupMembersFilter.admin: return Localization().getStringEx('panel.manage_members.member.status.admin.project.label', 'Principal Investigator');
      case GroupMembersFilter.member: return Localization().getStringEx('panel.manage_members.member.status.member.project.label', 'Participant');
      case GroupMembersFilter.pending: return Localization().getStringEx('panel.manage_members.member.status.pending.project.label', 'Pending');
      case GroupMembersFilter.rejected: return Localization().getStringEx('panel.manage_members.member.status.rejected.project.label', 'Denied');
    }
  }

  String get emptyGroupStatusText {
    switch (this) {
      case GroupMembersFilter.all: return Localization().getStringEx('panel.manage_members.status.all.empty.message', 'There are no members.');
      case GroupMembersFilter.admin: return Localization().getStringEx('panel.manage_members.status.admin.empty.message', 'There are no admins.');
      case GroupMembersFilter.member: return Localization().getStringEx('panel.manage_members.status.member.empty.message', 'There are no members.');
      case GroupMembersFilter.pending: return Localization().getStringEx('panel.manage_members.status.pending.empty.message', 'There are no pending members.');
      case GroupMembersFilter.rejected: return Localization().getStringEx('panel.manage_members.status.rejected.empty.message', 'There are no denied members.');
    }
  }

  String get emptyResearchProjectStatusText {
    switch (this) {
      case GroupMembersFilter.all: return Localization().getStringEx('panel.manage_members.status.all.empty.project.message', 'There are no participants.');
      case GroupMembersFilter.admin: return Localization().getStringEx('panel.manage_members.status.admin.empty.project.message', 'There are no principal investigators.') ;
      case GroupMembersFilter.member: return Localization().getStringEx('panel.manage_members.status.member.empty.project.message', 'There are no participants.');
      case GroupMembersFilter.pending: return Localization().getStringEx('panel.manage_members.status.pending.empty.project.message', 'There are no pending participants.');
      case GroupMembersFilter.rejected: return Localization().getStringEx('panel.manage_members.status.rejected.empty.project.message', 'There are no denied participants.');
    }
  }

  static GroupMembersFilter fromMemberStatus(GroupMemberStatus status) {
    switch (status) {
      case GroupMemberStatus.admin: return GroupMembersFilter.admin;
      case GroupMemberStatus.member: return GroupMembersFilter.member;
      case GroupMemberStatus.pending: return GroupMembersFilter.pending;
      case GroupMemberStatus.rejected: return GroupMembersFilter.rejected;
    }
  }

  GroupMemberStatus? get memberStatus {
    switch (this) {
      case GroupMembersFilter.all: return null;
      case GroupMembersFilter.admin: return GroupMemberStatus.admin;
      case GroupMembersFilter.member: return GroupMemberStatus.member;
      case GroupMembersFilter.pending: return GroupMemberStatus.pending;
      case GroupMembersFilter.rejected: return GroupMemberStatus.rejected;
    }
  }

  List<GroupMemberStatus>? get memberStatuses {
    GroupMemberStatus? status = memberStatus;
    return (status != null) ? <GroupMemberStatus>[status] : null;
  }
}