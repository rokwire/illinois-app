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
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/groups/GroupMemberPanel.dart';
import 'package:illinois/ui/groups/GroupPendingMemberPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/HomeHeader.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class GroupMembersPanel extends StatefulWidget{
  final String groupId;

  GroupMembersPanel({@required this.groupId});

  _GroupMembersPanelState createState() => _GroupMembersPanelState();
}

class _GroupMembersPanelState extends State<GroupMembersPanel> implements NotificationsListener{
  Group _group;
  bool _isMembersLoading = false;
  bool _isPendingMembersLoading = false;
  bool get _isLoading => _isMembersLoading || _isPendingMembersLoading;

  bool _showAllRequestVisibility = true;

  List<Member> _pendingMembers;
  List<Member> _members;

  String _allMembersFilter;
  String _selectedMembersFilter;
  List<String> _membersFilter;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Groups.notifyUserMembershipUpdated, Groups.notifyGroupCreated, Groups.notifyGroupUpdated]);
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
    Groups().loadGroup(widget.groupId).then((Group group){
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
      _pendingMembers = _group.getMembersByStatus(GroupMemberStatus.pending);
      _pendingMembers.sort((member1, member2) => member1.name.compareTo(member2.name));

      _members = AppCollection.isCollectionNotEmpty(_group?.members)
          ? _group.members.where((member) => (member.status != GroupMemberStatus.pending)).toList()
          : [];
      _members.sort((member1, member2){
        if(member1.status == member2.status){
          return member1.name.compareTo(member2.name);
        } else {
          if(member1.isAdmin && !member2.isAdmin) return -1;
          else if(!member1.isAdmin && member2.isAdmin) return 1;
          else return 0;
        }
      });
    _applyMembersFilter();
    });
  }

  void _applyMembersFilter(){
    List<String> membersFilter = [];
    _allMembersFilter = Localization().getStringEx("panel.manage_members.label.filter_by.all_members", "All members (#)").replaceAll("#", _members.length.toString());
    _selectedMembersFilter = _allMembersFilter;
    membersFilter.add(_allMembersFilter);
    if(AppCollection.isCollectionNotEmpty(_members)){
      for(Member member in _members){
        if(AppString.isStringNotEmpty(member.officerTitle) && !membersFilter.contains(member.officerTitle)){
          membersFilter.add(member.officerTitle);
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
    else if (param == _group.id && (name == Groups.notifyGroupCreated || name == Groups.notifyGroupUpdated)){
      _reloadGroup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Styles().colors.background,
        appBar: SimpleHeaderBarWithBack(
          context: context,
          titleWidget: Text(Localization().getStringEx("panel.manage_members.header.title", "Manage Members",),
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: Styles().fontFamilies.extraBold,
                letterSpacing: 1.0),
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary), ))
            : SingleChildScrollView(
          child:Column(
            children: <Widget>[
              _buildRequests(),
              _buildMembers()
            ],
          ),
        ),
        bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildRequests(){
    if((_pendingMembers?.length ?? 0) > 0) {
      List<Widget> requests = [];
      for (Member member in (_pendingMembers.length > 2 && _showAllRequestVisibility) ? _pendingMembers.sublist(0, 1) : _pendingMembers) {
        if(requests.isNotEmpty){
          requests.add(Container(height: 10,));
        }
        requests.add(_PendingMemberCard(member: member, group: _group,));
      }

      if(_pendingMembers.length > 2 && _showAllRequestVisibility){
        requests.add(Container(
          padding: EdgeInsets.only(top: 20, bottom: 10),
          child: SmallRoundedButton(
            label: Localization().getStringEx("panel.manage_members.button.see_all_requests.title", "See all # requests").replaceAll("#", _pendingMembers.length.toString()),
            hint: Localization().getStringEx("panel.manage_members.button.see_all_requests.hint", ""),
            onTap: (){setState(() {
              _showAllRequestVisibility = false;
            });},
          ),
        ));
      }

      return SectionTitlePrimary(title: Localization().getStringEx("panel.manage_members.label.requests", "Requests"),
        iconPath: 'images/icon-reminder.png',
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
      for (Member member in _members) {
        if(_selectedMembersFilter != _allMembersFilter && _selectedMembersFilter != member.officerTitle){
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
              child: HomeHeader(
                title: Localization().getStringEx("panel.manage_members.label.members", "Members"),
                imageRes: 'images/icon-member.png',
              ),
            ),
            _buildMembersFilter(),
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
        color: Styles().colors.white,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                child: GroupDropDownButton<String>(
                  emptySelectionText: _allMembersFilter,
                  initialSelectedValue: _allMembersFilter,
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
}

class _PendingMemberCard extends StatelessWidget {
  final Member member;
  final Group group;
  _PendingMemberCard({@required this.member, this.group});

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
            child: Container(width: 65, height: 65 ,child: AppString.isStringNotEmpty(member?.photoURL) ? Image.network(member.photoURL) : Image.asset('images/missing-photo-placeholder.png')),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    member?.name ?? "",
                    style: TextStyle(
                      fontFamily: Styles().fontFamilies.bold,
                      fontSize: 20,
                      color: Styles().colors.fillColorPrimary
                    ),
                  ),
                  Container(height: 4,),
                      ScalableRoundedButton(
                        label: Localization().getStringEx("panel.manage_members.button.review_request.title", "Review request"),
                        hint: Localization().getStringEx("panel.manage_members.button.review_request.hint", ""),
                        borderColor: Styles().colors.fillColorSecondary,
                        textColor: Styles().colors.fillColorPrimary,
                        backgroundColor: Styles().colors.white,
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

class _GroupMemberCard extends StatelessWidget{
  final Member member;
  final Group group;
  _GroupMemberCard({@required this.member, @required this.group});

  @override
  Widget build(BuildContext context) {
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
              child: Container(width: 65, height: 65 ,child: AppString.isStringNotEmpty(member?.photoURL) ? Image.network(member.photoURL) : Image.asset('images/missing-photo-placeholder.png')),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child:
                          Text(
                            member?.name ?? "",
                            style: TextStyle(
                                fontFamily: Styles().fontFamilies.bold,
                                fontSize: 20,
                                color: Styles().colors.fillColorPrimary
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
                            color: groupMemberStatusToColor(member.status),
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                          child: Center(
                            child: Text(groupMemberStatusToDisplayString(member.status).toUpperCase(),
                              style: TextStyle(
                                  fontFamily: Styles().fontFamilies.bold,
                                  fontSize: 12,
                                  color: Styles().colors.white
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: Container(),),
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

  void _onTapMemberCard(BuildContext context)async{
    Analytics().logSelect(target: "Member Detail");
    await Navigator.push(context, CupertinoPageRoute(builder: (context)=> GroupMemberPanel(groupId: group.id, memberId: member.id,)));
  }
}