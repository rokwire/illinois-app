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
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/groups/GroupsHomePanel.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';

class GroupMemberPanel extends StatefulWidget with AnalyticsInfo {
  final Group group;
  final String memberId;

  GroupMemberPanel({required this.group, required this.memberId});

  @override
  _GroupMemberPanelState createState() => _GroupMemberPanelState();

  @override
  AnalyticsFeature? get analyticsFeature => (group.researchProject == true) ? AnalyticsFeature.ResearchProject : AnalyticsFeature.Groups;

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group.analyticsAttributes;
}

class _GroupMemberPanelState extends State<GroupMemberPanel> {
  Group? _group;
  Member? _member;
  List<Member>? _groupAdmins;
  int _progressLoading = 0;
  bool _isAdmin = false;
  bool _updating = false;
  bool _removing = false;
  bool _deletingGroup = false;
  bool _loadingAdmins = false;

  @override
  void initState() {
    super.initState();
    _loadGroup();
    _loadMember();
    _loadGroupAdmins();
  }

  void _loadGroup() {
    _increaseProgress();
    Groups().loadGroup(widget.group.id).then((group) {
      _group = group;
      _decreaseProgress();
    });
  }

  void _loadMember() {
    _increaseProgress();
    Groups().loadMembers(groupId: widget.group.id, memberId: widget.memberId).then((members) {
      _member = members?.first;
      _isAdmin = _member?.isAdmin ?? false;
      _decreaseProgress();
    });
  }

  void _loadGroupAdmins({bool showProgress = true}){
    if(_loadingAdmins)
      return;

    setStateIfMounted((){_loadingAdmins = true;});
    if(showProgress)
      _increaseProgress();
    Groups().loadMembers(groupId: widget.group.id, statuses: [GroupMemberStatus.admin]).then((admins) {
      _groupAdmins = admins;
      if(showProgress)
        _decreaseProgress();
      setStateIfMounted((){_loadingAdmins = false;});
    });
  }

  void _updateMemberStatus() {
    Analytics().logSelect(target: 'Admin');
    if(_loadingAdmins || _updating)
      return;

    if(_isLastAdmin){
      showDialog(context: context, builder: _buildDeleteGroupDialog); //Don't allow removing the last admin. Delete the Group Instead
      return;
    }

      setState(() {
        _updating = true;
      });

    // First invoke api  and then update the UI - if succeeded
    bool newIsAdmin = !_isAdmin;

    GroupMemberStatus status = newIsAdmin ? GroupMemberStatus.admin : GroupMemberStatus.member;
    Groups().updateMemberStatus(_group, widget.memberId, status).then((bool succeed) {
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
    }).whenComplete((){
      _loadGroupAdmins(showProgress: false);
    });
  }

  Future<void> _removeMembership() async{
    bool success = await Groups().deleteMembership(_group, widget.memberId);
    if(!success){
      throw sprintf( _isResearchProject?
          Localization().getStringEx("panel.member_detail.label.error.project.format", "Unable to remove %s from this project") :
          Localization().getStringEx("panel.member_detail.label.error.format", "Unable to remove %s from this group"),
        [_member?.displayShortName ?? ""]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.background,
      appBar: HeaderBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary), ))
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
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildHeading() {
    bool showAttendance = (_group?.attendanceGroup ?? false) && (_member?.dateAttendedUtc != null);
    DateTime? dateTimeUtc = showAttendance ? _member?.dateAttendedUtc : _member?.dateCreatedUtc;
    String? formattedDate = (dateTimeUtc != null) ? AppDateTime().formatDateTime(dateTimeUtc.toLocal(), format: "MMMM dd") : null;
    String datePrefixLabelFormat = showAttendance ? Localization().getStringEx("panel.member_detail.label.attended_on", "Attended on %s") : Localization().getStringEx("panel.member_detail.label.member_since", "Member since %s");
    String dateDescriptionMsg = (formattedDate != null) ? sprintf(datePrefixLabelFormat, [formattedDate]) : '';

    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(65),
            child: Container(width: 65, height: 65, child:
              Semantics(label: "user image", hint: "Double tap to zoom", child:
                GroupMemberProfileImage(userId: _member?.userId))
            ),
          ),
        ),
        Container(width: 16,),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(_member?.displayShortName ?? "",
                style: Styles().textStyles.getTextStyle("widget.detail.large.extra_fat")
              ),
              Container(height: 6,),
              Text(dateDescriptionMsg,
                style: Styles().textStyles.getTextStyle("widget.detail.small")
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDetails(BuildContext context) {
    bool canAdmin = _group?.currentUserIsAdmin ?? false;
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
                        borderRadius: BorderRadius.circular(4),
                        label: Localization().getStringEx("panel.member_detail.label.admin", "Admin"),
                        toggled: _isAdmin,
                        onTap: _updateMemberStatus
                    ),
                    _updating || _loadingAdmins ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorPrimary), ) : Container()
                  ],
                ),
              ),
              Container(height: 8,),
              Text(Localization().getStringEx("panel.member_detail.label.admin_description", "Admins can manage settings, members, and events."),
                style: Styles().textStyles.getTextStyle("widget.detail.light.regular")
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
    return
        RoundedButton(label: _isResearchProject?
            Localization().getStringEx("panel.member_detail.button.remove.title.project", "Remove from Project") :
            Localization().getStringEx("panel.member_detail.button.remove.title", 'Remove from Group'),
          textStyle: Styles().textStyles.getTextStyle("widget.button.light.title.medium.fat"),
          backgroundColor: Styles().colors.background,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          borderColor: Styles().colors.surface,
          borderWidth: 2,
          onTap: _onTapRemoFromGroup
        );
  }

  void _onTapRemoFromGroup(){
    Analytics().logSelect(target: 'Remove from Group');
    if(_isLastAdmin){
      showDialog(context: context, builder: _buildDeleteGroupDialog);
      return;
    }
    showDialog(context: context, builder: _buildRemoveFromGroupDialog);
  }

  Widget _buildRemoveFromGroupDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Styles().colors.fillColorPrimary,
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
                    sprintf(_isResearchProject?
                      Localization().getStringEx("panel.member_detail.label.confirm_remove.project.format", "Remove %s From this project?"):
                      Localization().getStringEx("panel.member_detail.label.confirm_remove.format", "Remove %s From this group?"),
                    [_member?.displayName]),
                    textAlign: TextAlign.left,
                    style: Styles().textStyles.getTextStyle("widget.dialog.message.medium")
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    RoundedButton(
                      label: Localization().getStringEx("panel.member_detail.button.back.title", "Back"),
                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.thin"),
                      borderColor: Styles().colors.surface,
                      backgroundColor: Styles().colors.surface,
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      contentWeight: 0.0,
                      onTap: (){
                        Analytics().logAlert(text: "Remove member from this group?", selection: "Back");
                        Navigator.pop(context);
                      },
                    ),
                    Container(width: 16,),
                        RoundedButton(
                          label: Localization().getStringEx("panel.member_detail.dialog.button.remove.title", "Remove"),
                          textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                          borderColor: Styles().colors.surface,
                          backgroundColor: Styles().colors.surface,
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          contentWeight: 0.0,
                          progress: _removing || _loadingAdmins,
                          onTap: (){
                            Analytics().logAlert(text: "Remove member from this group?", selection: "Remove");
                            if(!_removing && !_loadingAdmins) {
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
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeleteGroupDialog(BuildContext context) =>
      Dialog(
        backgroundColor: Styles().colors.fillColorPrimary,
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
                        _isResearchProject?
                        Localization().getStringEx("", "Would you like to remove yourself as the only project admin and delete this project?"):
                        Localization().getStringEx("", "Would you like to remove yourself as the only group admin and delete this group?"),
                        textAlign: TextAlign.left,
                        style: Styles().textStyles.getTextStyle("widget.dialog.message.medium")
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      RoundedButton(
                        label: Localization().getStringEx("", "No"),
                        textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.thin"),
                        borderColor: Styles().colors.surface,
                        backgroundColor: Styles().colors.surface,
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        contentWeight: 0.0,
                        onTap: (){
                          Analytics().logAlert(text: "Delete this group?", selection: "No");
                          Navigator.pop(context);
                        },
                      ),
                      Container(width: 16,),
                      RoundedButton(
                        label: Localization().getStringEx("", "Yes"),
                        textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                        borderColor: Styles().colors.surface,
                        backgroundColor: Styles().colors.surface,
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        contentWeight: 0.0,
                        progress: _deletingGroup,
                        onTap: (){
                          Analytics().logAlert(text: "Delete this group?", selection: "Yes");
                          if(!_deletingGroup) {
                            if (mounted) {
                              setStateEx(() {
                                _deletingGroup = true;
                              });
                            }
                            Groups().deleteGroup(_group?.id).then((success) {
                              if(success){
                                Navigator.of(context).popUntil((Route route){
                                  return route.settings.name == GroupsHomePanel.routeName;
                                });
                              } else {
                                Navigator.pop(context);
                              }


                            }).whenComplete((){
                              if (mounted) {
                                setStateEx(() {
                                  _deletingGroup = false;
                                });
                              }
                            }).catchError((error) {
                              Navigator.pop(context);
                              AppAlert.showDialogResult(context, error);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

  bool get _isLastAdmin => _isAdmin && (_groupAdmins != null && _groupAdmins!.length <=1);

  void _increaseProgress() {
    _progressLoading++;
    if (mounted) {
      setState(() {});
    }
  }

  void _decreaseProgress() {
    _progressLoading--;
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isLoading {
    return (_progressLoading > 0);
  }

  bool get _isResearchProject {
    return _group?.isResearchProject ?? false;
  }
}