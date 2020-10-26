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
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
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
  bool _updating = false;
  bool _removing = false;

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

  void _update() {
    if (_updating != true) {

      setState(() {
        _updating = true;
      });

      Groups().updateGroupMember(widget.groupDetail?.id, _member).then((GroupMember member) {
        if (mounted) {
          setState(() {
            _updating = false;
          });
          if (member == null) {
            AppAlert.showDialogResult(context, 'Failed to update member');
          }
        }
      });
    }
  }

  void _remove() {
    if (_removing != true) {

      setState(() {
        _removing = true;
      });

      Groups().updateGroupMember(widget.groupDetail?.id, _member).then((GroupMember member) {
        if (mounted) {
          setState(() {
            _removing = false;
          });
          if (member == null) {
            AppAlert.showDialogResult(context, 'Failed to update member');
          }
        }
      });
    }
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
        ],
      ),
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildHeading(){
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
    bool canAdmin = ((_member?.status != null) && (_member?.status != GroupMemberStatus.inactive));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Visibility(
          visible: canAdmin,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(height: 24,),
              Stack(
                alignment: Alignment.center,
                children: [
                  ToggleRibbonButton(
                      height: null,
                      borderRadius: BorderRadius.circular(4),
                      label: Localization().getStringEx("panel.member_detail.label.admin", "Admin"),
                      toggled: _member?.admin ?? false,
                      context: context,
                      onTap: () {
                        setState(() {
                          _member.admin = !(_member?.admin ?? false);
                          _update();
                        });
                      }
                  ),
                  _updating ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary), ) : Container()
                ],
              ),
              Container(height: 8,),
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
        Container(height: 22,),
        _buildRemoveFromGroup(),
      ],
    );
  }

  Widget _buildRemoveFromGroup() {
    return Stack(children: <Widget>[
        ScalableRoundedButton(label: 'Remove from Group',
          backgroundColor: Styles().colors.white,
          textColor: Styles().colors.fillColorPrimary,
          fontFamily: Styles().fontFamilies.bold,
          fontSize: 16,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          borderColor: Styles().colors.fillColorPrimary,
          borderWidth: 2,
          onTap:() { _remove();  }
        ),
      Visibility(visible: (_removing == true), child:
        Center(child:
          Padding(padding: EdgeInsets.only(top: 10.5), child:
           Container(width: 21, height:21, child:
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary), strokeWidth: 2,)
            ),
          ),
        ),
      ),
    ],);
  }
}