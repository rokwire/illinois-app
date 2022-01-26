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

import 'package:flutter/material.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:sprintf/sprintf.dart';

class GroupMemberPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Group? group;
  final Member? member;

  String? get groupId => group?.id;
  String? get memberId => member?.id;

  GroupMemberPanel({this.group, this.member});

  @override
  _GroupMemberPanelState createState() => _GroupMemberPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group?.analyticsAttributes;
}

class _GroupMemberPanelState extends State<GroupMemberPanel>{
  Member? _member;
  late Group _group;
  bool _isLoading = false;
  bool _isAdmin = false;
  bool _updating = false;
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    _reloadGroup();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _reloadGroup(){
    if(mounted) {
      setState(() {
        _isLoading = true;
      });
      Groups().loadGroup(widget.groupId).then((Group? group) {
        if (mounted) {
          if (group != null) {
            _group = group;
            _loadMember();
          }
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _loadMember(){
    if(mounted) {
      if (CollectionUtils.isNotEmpty(_group.members)) {
        setState(() {
          _member = _group.getMembersById(widget.memberId);
          _isAdmin = _member!.isAdmin;
        });
      }
    }
  }

  void _updateMemberStatus() {
    Analytics().logSelect(target: 'Admin');
    if (!_updating) {

      setState(() {
        _updating = true;
      });

      // First invoke api  and then update the UI - if succeeded
      bool newIsAdmin = !_isAdmin;

      GroupMemberStatus status = newIsAdmin ? GroupMemberStatus.admin : GroupMemberStatus.member;
      Groups().updateMembership(widget.group, widget.member, status).then((bool succeed) {
        if (mounted) {
          setState(() {
            _updating = false;
          });
          if(succeed){
            setState(() {
              _isAdmin = newIsAdmin;
            });
          } else {
            AppAlert.showDialogResult(context, Localization().getStringEx("panel.member_detail.label.empty", 'Failed to update member'));
          }
        }
      });
    }
  }

  Future<void> _removeMembership() async{
    bool success = await Groups().deleteMembership(widget.group, widget.member);
    if(!success){
      throw sprintf(Localization().getStringEx("panel.member_detail.label.error.format", "Unable to remove %s from this group")!, [_member?.name ?? ""]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors!.background,
      appBar: SimpleHeaderBarWithBack(
        context: context,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), ))
          : Column(
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
    String? memberDateAdded = (_member?.dateCreatedUtc != null) ? AppDateTime().formatDateTime(_member?.dateCreatedUtc?.toLocal(), format: "MMMM dd") : null;
    String memberSince = (memberDateAdded != null) ? (Localization().getStringEx("panel.member_detail.label.member_since", "Member since")! + memberDateAdded) : '';

    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(65),
            child: Container(
                width: 65, height: 65 ,
                child: StringUtils.isNotEmpty(_member?.photoURL) ? Image.network(_member!.photoURL!, excludeFromSemantics: true,) : Image.asset('images/missing-photo-placeholder.png', excludeFromSemantics: true,)
            ),
          ),
        ),
        Container(width: 16,),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(_member?.name ?? "",
                style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary
                ),
              ),
              Container(height: 6,),
              Text(memberSince,
                style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 14, color: Styles().colors!.textBackground),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDetails(BuildContext context){
    bool canAdmin = _group.currentUserIsAdmin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Visibility(
          visible: canAdmin,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(height: 24,),
              Visibility(
                visible: !_member!.isRejected,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ToggleRibbonButton(
                        height: null,
                        borderRadius: BorderRadius.circular(4),
                        label: Localization().getStringEx("panel.member_detail.label.admin", "Admin"),
                        toggled: _isAdmin,
                        context: context,
                        onTap: _updateMemberStatus
                    ),
                    _updating ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorPrimary), ) : Container()
                  ],
                ),
              ),
              Container(height: 8,),
              Text(Localization().getStringEx("panel.member_detail.label.admin_description", "Admins can manage settings, members, and events.")!,
                style: TextStyle(
                    fontFamily: Styles().fontFamilies!.regular,
                    fontSize: 16,
                    color: Styles().colors!.textBackground
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
        ScalableRoundedButton(label: Localization().getStringEx("panel.member_detail.button.remove.title", 'Remove from Group'),
          backgroundColor: Styles().colors!.white,
          textColor: Styles().colors!.fillColorPrimary,
          fontFamily: Styles().fontFamilies!.bold,
          fontSize: 16,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          borderColor: Styles().colors!.fillColorPrimary,
          borderWidth: 2,
          onTap: (){
            Analytics().logSelect(target: 'Remove from Group');
            showDialog(context: context, builder: _buildRemoveFromGroupDialog);
          }
        ),
    ],);
  }

  Widget _buildRemoveFromGroupDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Styles().colors!.fillColorPrimary,
      child: StatefulBuilder(
        builder: (context, setStateEx){
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 26),
                  child: Text(
                    sprintf(Localization().getStringEx("panel.member_detail.label.confirm_remove.format", "Remove %s From this group?")!,[_member?.name]),
                    textAlign: TextAlign.left,
                    style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.white),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    RoundedButton(
                      label: Localization().getStringEx("panel.member_detail.button.back.title", "Back"),
                      fontFamily: "ProximaNovaRegular",
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.white,
                      backgroundColor: Styles().colors!.white,
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      onTap: (){
                        Analytics().logAlert(text: "Remove member from this group?", selection: "Back");
                        Navigator.pop(context);
                      },
                    ),
                    Container(width: 16,),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        RoundedButton(
                          label: Localization().getStringEx("panel.member_detail.dialog.button.remove.title", "Remove"),
                          fontFamily: "ProximaNovaBold",
                          textColor: Styles().colors!.fillColorPrimary,
                          borderColor: Styles().colors!.white,
                          backgroundColor: Styles().colors!.white,
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          onTap: (){
                            Analytics().logAlert(text: "Remove member from this group?", selection: "Remove");
                            if(!_removing) {
                              if (mounted) {
                                setStateEx(() {
                                  _removing = true;
                                });
                              }
                              _removeMembership().then((_) {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              }).whenComplete((){
                                if (mounted) {
                                  setStateEx(() {
                                    _removing = false;
                                  });
                                }
                              }).catchError((error) {
                                Navigator.pop(context);
                                AppAlert.showDialogResult(context, error);
                              });
                            }
                          },
                        ),
                        _removing ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), strokeWidth: 2,) : Container(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}