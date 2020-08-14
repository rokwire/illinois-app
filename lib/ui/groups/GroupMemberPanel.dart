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
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class GroupMemberPanel extends StatefulWidget {
  final GroupMember member;
  final GroupDetail groupDetail;
  GroupMemberPanel({this.member, this.groupDetail});
  _GroupMemberPanelState createState() => _GroupMemberPanelState();
}

class _GroupMemberPanelState extends State<GroupMemberPanel>{

  GroupMember _member;
  bool _submitting;

  //String _selectedOfficerTitle = "President";
  List<String> _officerTitleTypes;

  @override
  void initState() {
    super.initState();
    _member = GroupMember.fromOther(widget.member);
    Groups().officerTitles.then((List<String> officerTitles){
      setState(() {
        _officerTitleTypes = officerTitles;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.background,
      appBar: SimpleHeaderBarWithBack(
        context: context,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child:Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: <Widget>[
                    _buildHeading(),
                    _buildDetails(context),
                  ],
                ),
              ),
            ),
          ),
          _buildSubmit(),
        ],
      ),
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildHeading(){
    bool badgeVisible = _member?.status == GroupMemberStatus.officer;
    String memberStatus;
    if (_member?.status == GroupMemberStatus.officer) {
      memberStatus = _member?.officerTitle;
      if ((memberStatus == null) || (memberStatus.length == 0)) {
        memberStatus = groupMemberStatusToDisplayString(GroupMemberStatus.officer);
      }
    }
    else {
      memberStatus = groupMemberStatusToDisplayString(_member?.status);
      if ((memberStatus != null) && (0 < memberStatus.length)) {
        memberStatus = "${memberStatus.toUpperCase()} MEMBER";
      }
    }
    if ((memberStatus == null) || (memberStatus.length == 0)) {
      memberStatus = "MEMBER";
    }

    String memberDateAdded = (_member?.dateAdded != null) ? AppDateTime().formatDateTime(_member?.dateAdded, format: "MMMM dd") : null;
    String memberSince = (memberDateAdded != null) ? "Member since $memberDateAdded" : '';

    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(65),
            child: Container(width: 65, height: 65 ,child: Image.network(_member?.photoURL ?? '')),
          ),
        ),
        Container(width: 16,),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Visibility(
                    visible: badgeVisible,
                    child: Container(width: 16, height: 16,
                      margin: EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(color: Styles().colors.fillColorSecondary, borderRadius: BorderRadius.all(Radius.circular(16)) ),
                      child: Image.asset('images/icon-saved-white.png'),
                    )
                  ),
                  Text(memberStatus.toUpperCase(),
                    style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 12, color: Styles().colors.fillColorPrimary),
                  ),
                ],
              ),
              Container(height: 8,),
              Text(_member?.name ?? "",
                style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, color: Styles().colors.fillColorPrimary
                ),
              ),
              Container(height: 6,),
              Text(memberSince,
                style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 14, color: Styles().colors.textBackground),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDetails(BuildContext context){
    bool canOfficerTitle = (_member?.status == GroupMemberStatus.officer);
    bool canAdmin = ((_member?.status != null) && (_member?.status != GroupMemberStatus.inactive));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(height: 32,),
        Text(Localization().getStringEx("panel.member_detail.label.status", "STATUS"),
          style: TextStyle(
              fontFamily: Styles().fontFamilies.bold,
              fontSize: 12,
              color: Styles().colors.fillColorPrimary
          ),
        ),
        Container(height: 8,),
        GroupDropDownButton<GroupMemberStatus>(
          emptySelectionText: 'Select member status.',
          initialSelectedValue: _member.status ?? GroupMemberStatus.values.first,
          items: GroupMemberStatus.values,
          constructTitle: (dynamic status) => groupMemberStatusToDisplayString(status),
          onValueChanged: (value) {
            setState(() {
              _member.status = value;
            });
          },
        ),
        Visibility(
          visible: canOfficerTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(height: 24,),
              Text(Localization().getStringEx("panel.member_detail.label.officer_title", "OFFICER TITLE"),
                style: TextStyle(
                    fontFamily: Styles().fontFamilies.bold,
                    fontSize: 12,
                    color: Styles().colors.fillColorPrimary
                ),
              ),
              Container(height: 8,),
              GroupDropDownButton<String>(
                emptySelectionText: 'Select officer title.',
                initialSelectedValue: _member?.officerTitle,
                items: _officerTitleTypes ?? [],
                constructTitle: (dynamic title) => title,
                onValueChanged: (value){
                  setState(() {
                    _member.officerTitle = value;
                  });
                },
              ),
            ]
          ),
        ),
        Visibility(
          visible: canAdmin,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(height: 24,),
              ToggleRibbonButton(
                  borderRadius: BorderRadius.circular(4),
                  label: Localization().getStringEx("panel.member_detail.label.admin", "Admin"),
                  toggled: _member?.admin ?? false,
                  context: context,
                  onTap: () {
                    setState(() {
                      _member.admin = !(_member?.admin ?? false);
                    });
                  }
              ),
              Text(Localization().getStringEx("panel.member_detail.label.admin_description", "Admins can manage settings, members, and events."),
                style: TextStyle(
                    fontFamily: Styles().fontFamilies.regular,
                    fontSize: 16,
                    color: Styles().colors.textBackground
                ),
              ),
            ]
          ),
        ),
      ],
    );
  }

  Widget _buildSubmit() {
    return Container(color: Colors.white,
      child: Padding(padding: EdgeInsets.all(16),
        child: Stack(children: <Widget>[
          Row(children: <Widget>[
            Expanded(child: Container(),),
            RoundedButton(label: 'Update member',
              backgroundColor: Styles().colors.white,
              textColor: Styles().colors.fillColorPrimary,
              fontFamily: Styles().fontFamilies.bold,
              fontSize: 16,
              padding: EdgeInsets.symmetric(horizontal: 32, ),
              borderColor: Styles().colors.fillColorSecondary,
              borderWidth: 2,
              height: 42,
              onTap:() { _onSubmit();  }
            ),
            Expanded(child: Container(),),
          ],),
          Visibility(visible: (_submitting == true), child:
            Center(child:
              Padding(padding: EdgeInsets.only(top: 10.5), child:
               Container(width: 21, height:21, child:
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary), strokeWidth: 2,)
                ),
              ),
            ),
          ),
        ],),
      ),
    );
  }

  void _onSubmit() {
    if (_submitting != true) {

      setState(() {
        _submitting = true;
      });

      Groups().updateGroupMember(widget.groupDetail?.id, _member).then((GroupMember member) {
        if (mounted) {
          setState(() {
            _submitting = false;
          });
          if (member != null) {
            Navigator.pop(context);
          }
          else {
            AppAlert.showDialogResult(context, 'Failed to update member');
          }
        }
      });
    }
  }
}