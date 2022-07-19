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
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
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

class _GroupMembersPanelState extends State<GroupMembersPanel> implements NotificationsListener{
  Group? _group;
  bool _isMembersLoading = false;
  bool _isPendingMembersLoading = false;
  bool get _isLoading => _isMembersLoading || _isPendingMembersLoading;

  bool _showAllRequestVisibility = true;

  List<Member>? _pendingMembers;
  List<Member>? _members;

  String? _allMembersFilter;
  String? _selectedMembersFilter;
  List<String>? _membersFilter;
  String? _searchTextValue;

  TextEditingController _searchEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Groups.notifyUserMembershipUpdated, Groups.notifyGroupCreated, Groups.notifyGroupUpdated]);
    _initMemberFilter();
    _reloadGroup();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  void _reloadGroup(){
    setState(() {
      _isMembersLoading = true;
    });
    Groups().loadGroup(widget.groupId).then((Group? group){
      if (mounted) {
        if(group != null) {
          _group = group;
          _loadMembers();
        }
        setState(() {
          _isMembersLoading = false;
        });
      }
    });
  }

  void _loadMembers(){
    setState(() {
      _isMembersLoading = false;
      _pendingMembers = _group?.getMembersByStatus(GroupMemberStatus.pending);
      _pendingMembers?.sort((member1, member2) => member1.displayName.compareTo(member2.displayName));

      _members = CollectionUtils.isNotEmpty(_group?.members)
          ? _group!.members!.where((member) => (member.status != GroupMemberStatus.pending)).toList()
          : [];
      _members!.sort((member1, member2){
        if(member1.status == member2.status){
          return member1.displayName.compareTo(member2.displayName);
        } else {
          if(member1.isAdmin && !member2.isAdmin) return -1;
          else if(!member1.isAdmin && member2.isAdmin) return 1;
          else return 0;
        }
      });
      _refreshAllMembersFilterText();
      _applyMembersFilter();
    });
  }

  void _initMemberFilter(){
    _selectedMembersFilter = _allMembersFilter;
    _refreshAllMembersFilterText();
  }

  void _refreshAllMembersFilterText(){
    if(_selectedMembersFilter == _allMembersFilter){
      _selectedMembersFilter = _allMembersFilter = Localization().getStringEx("panel.manage_members.label.filter_by.all_members", "All Members (#)").replaceAll("#", _members?.length.toString() ?? "0");
    } else {
      _allMembersFilter = Localization().getStringEx("panel.manage_members.label.filter_by.all_members", "All Members (#)").replaceAll("#", _members?.length.toString() ?? "0");
    }
  }
  void _applyMembersFilter(){
    List<String> membersFilter = [];
    if (_allMembersFilter != null) {
      membersFilter.add(_allMembersFilter!);
    }
    if(CollectionUtils.isNotEmpty(_members)){
      for(Member member in _members!){
        if(StringUtils.isNotEmpty(member.officerTitle) && !membersFilter.contains(member.officerTitle)){
          membersFilter.add(member.officerTitle!);
        }
      }
    }
    _membersFilter = membersFilter;
    setState(() {});
  }

  @override
  void onNotification(String name, param) {
    if (name == Groups.notifyUserMembershipUpdated) {
      setState(() {});
    }
    else if (param == _group!.id && (name == Groups.notifyGroupCreated || name == Groups.notifyGroupUpdated)){
      _reloadGroup();
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
            ? Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), ))
            : RefreshIndicator(onRefresh: _onPullToRefresh, child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
          child:Column(
            children: <Widget>[
              Visibility(visible: _isAdmin, child: _buildRequests()),
              _buildMembers()
            ],
          ),
        )),
        bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildRequests(){
    if((_pendingMembers?.length ?? 0) > 0) {
      List<Widget> requests = [];
      for (Member? member in (_pendingMembers!.length > 2 && _showAllRequestVisibility) ? _pendingMembers!.sublist(0, 1) : _pendingMembers!) {
        if(requests.isNotEmpty){
          requests.add(Container(height: 10,));
        }
        requests.add(_PendingMemberCard(member: member, group: _group,));
      }

      if(_pendingMembers!.length > 2 && _showAllRequestVisibility){
        requests.add(Container(
          padding: EdgeInsets.only(top: 20, bottom: 10),
          child: SmallRoundedButton(
            label: Localization().getStringEx("panel.manage_members.button.see_all_requests.title", "See all # requests").replaceAll("#", _pendingMembers!.length.toString()),
            hint: Localization().getStringEx("panel.manage_members.button.see_all_requests.hint", ""),
            onTap: () {
              Analytics().logSelect(target: 'See all requests');
              setState(() {
                _showAllRequestVisibility = false;
              });
            },
          ),
        ));
      }

      return SectionSlantHeader(title: Localization().getStringEx("panel.manage_members.label.requests", "Requests"),
        titleIconAsset: 'images/icon-reminder.png',
        children: <Widget>[
          Column(
            children: requests,
          )
        ],
      );
    }
    return Container();
  }

  Widget _buildMembers(){
    if((_members?.length ?? 0) > 0) {
      List<Widget> members = [];
      for (Member? member in _members!) {
        if( !_isMemberMatchingFilter(member) ||
            !_isMemberMatchingSearch(member)){
          continue;
        }
        if(members.isNotEmpty){
          members.add(Container(height: 10,));
        }
        members.add(_GroupMemberCard(member: member, group: _group,));
      }
      if(members.isNotEmpty) {
        members.add(Container(height: 10,));
      }

      return Container(
        child: Column(
          children: <Widget>[
            Container(
              child: SectionRibbonHeader(
                title: Localization().getStringEx("panel.manage_members.label.members", "Members"),
                titleIconAsset: 'images/icon-member.png',
              ),
            ),
            _buildMembersFilter(),
            _buildMembersSearch(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: members,
              ),
            )
          ],
        ),
      );
    }
    return Container();
  }

  Widget _buildMembersFilter(){
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Styles().colors!.white,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                child: GroupDropDownButton<String?>(
                  emptySelectionText: _allMembersFilter,
                  initialSelectedValue: _selectedMembersFilter,
                  items: _membersFilter,
                  constructTitle: (dynamic title) => title,
                  decoration: BoxDecoration(),
                  padding: EdgeInsets.all(0),
                  onValueChanged: (value){
                    setState(() {
                      _selectedMembersFilter = value;
                    });
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
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
                    controller: _searchEditingController,
                    onChanged: (text) => _onSearchTextChanged(text),
                    onSubmitted: (_) => _onTapSearch(),
                    autofocus: true,
                    cursorColor: Styles().colors!.fillColorSecondary,
                    keyboardType: TextInputType.text,
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: Styles().fontFamilies!.regular,
                        color: Styles().colors!.textBackground),
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
    print('vleeez');
    if ((_group?.syncAuthmanAllowed == true) && (Config().allowGroupsAuthmanSync)) {
      await Groups().syncAuthmanGroup(group: _group!);
    }
    _reloadGroup();
  }

  void _onSearchTextChanged(String text) {
    // implement if needed
  }

  void _onTapSearch() {
    setState(() {
      _searchTextValue = _searchEditingController.text.toString();
    });
  }

  void _onTapClearSearch() {
    _searchEditingController.text = "";
    setState(() {
      _searchTextValue = "";
    });
  }

  bool _isMemberMatchingSearch(Member? member){
    return StringUtils.isEmpty(_searchTextValue) ||
        (member?.name?.toLowerCase().contains(_searchTextValue!.toLowerCase())?? false) ||
        (member?.email?.toLowerCase().contains(_searchTextValue!.toLowerCase())?? false);
  }

  bool _isMemberMatchingFilter(Member? member){
    return _selectedMembersFilter == _allMembersFilter ||
        _selectedMembersFilter == member!.officerTitle;
  }

  bool get _isAdmin {
    return _group?.currentUserAsMember?.isAdmin ?? false;
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
                    style: TextStyle(
                      fontFamily: Styles().fontFamilies!.bold,
                      fontSize: 20,
                      color: Styles().colors!.fillColorPrimary
                    ),
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
                            style: TextStyle(
                                fontFamily: Styles().fontFamilies!.bold,
                                fontSize: 20,
                                color: Styles().colors!.fillColorPrimary
                            ),
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
                              style: TextStyle(
                                  fontFamily: Styles().fontFamilies!.bold,
                                  fontSize: 12,
                                  color: Styles().colors!.white
                              ),
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
                                            style: TextStyle(
                                                fontFamily: Styles().fontFamilies!.bold, fontSize: 12, color: Styles().colors!.white)))))),
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
      await Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMemberPanel(group: group, member: member)));
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
    return group?.currentUserAsMember?.isAdmin ?? false;
  }

  bool get _displayAttended {
    return (group?.attendanceGroup == true) && _isAdmin && (member?.dateAttendedUtc != null);
  }
}