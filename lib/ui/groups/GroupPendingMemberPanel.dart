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
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class GroupPendingMemberPanel extends StatefulWidget {
  final Member member;
  final Group group;
  GroupPendingMemberPanel({this.member, this.group});
  _GroupPendingMemberPanelState createState() => _GroupPendingMemberPanelState();
}


class _GroupPendingMemberPanelState extends State<GroupPendingMemberPanel> {

  TextEditingController _reasonController = TextEditingController();
  bool _approved = false;
  bool _denied = false;
  bool _updating = false;

  @override
  void dispose() {
    _reasonController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.background,
      appBar: SimpleHeaderBarWithBack(
        context: context,
      ),
      body:
      Container(
        color:  Styles().colors.white,
        child:Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                  children: <Widget>[
                    _buildHeading(),
                    _buildDetails(),
                  ],
              ),
            ),
          ),
          _buildBottomButtons(context)
        ],
      )),
    );
  }

  Widget _buildHeading(){
    return
      Container(color: Styles().colors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child:Column(
        children: [
          Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(65),
                child: Container(width: 65, height: 65 ,child: AppString.isStringNotEmpty(widget.member?.photoURL) ? Image.network(widget.member.photoURL) : Image.asset('images/missing-photo-placeholder.png')),
              ),
            ),
            Container(width: 11,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(widget.member?.name ?? "",
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.extraBold,
                        fontSize: 20,
                        color: Styles().colors.fillColorPrimary
                    ),
                  ),
                  Text( Localization().getStringEx("panel.pending_member_detail.label.requested", "Requested on ${AppDateTime().formatDateTime(widget?.member?.dateCreated, format: "MMM dd, yyyy") ?? ""}"),
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.regular,
                        fontSize: 14,
                        color: Styles().colors.textSurface
                    ),
                  ),
                ],
              ),
            )
          ],
    ),
        ],
      ));
  }

  Widget _buildDetails(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildQuestions(),
        Container(height: 1, color: Styles().colors.surfaceAccent,),
        _buildApproval()
      ],
    );
  }

  Widget _buildQuestions(){
    List<Widget> list = List<Widget>();
    if(AppCollection.isCollectionNotEmpty(widget?.member?.answers)) {
      for (int index = 0; index < widget.member.answers.length; index++) {
        GroupMembershipAnswer answer = widget.member.answers[index];
        list.add(_MembershipAnswer(member: widget.member, answer: answer));
        list.add(Container(height: 16,));
      }
    }

    return
      Container(
        color: Styles().colors.background,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(children: list,),
        ],
      ));
  }

  Widget _buildApproval(){
    return
      Container(
        color: Styles().colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(height: 28,),
            Row(children: [
              Image.asset("images/user-check.png"),
              Container(width: 8,),
              Text(Localization().getStringEx("panel.pending_member_detail.label.approval", "Member approval"),
                style: TextStyle(
                    fontFamily: Styles().fontFamilies.bold,
                    fontSize: 16,
                    color: Styles().colors.fillColorPrimary
                ),
              ),
            ],),
            Container(height: 21,),
            ToggleRibbonButton(
                height: null,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Styles().colors.fillColorPrimary),
                label: Localization().getStringEx("panel.pending_member_detail.button.approve.text", "Approve "),
                toggled: _approved,
                context: context,
                onTap: () {
                  setState(() {
                    _approved = !_approved;
                    _denied = !_approved;
                  });
                }
            ),
            Container(height: 8,),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Styles().colors.fillColorPrimary),
              ),
              child: Column(
                children: [
                  ToggleRibbonButton(
                      height: null,
                      label: Localization().getStringEx("panel.pending_member_detail.button.deny.text", "Deny"),
                      borderRadius: BorderRadius.circular(4),
                      toggled: _denied,
                      context: context,
                      onTap: () {
                        setState(() {
                          _denied = !_denied;
                          _approved = !_denied;
                        });
                      }
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 13),
                    child:
                    Text(Localization().getStringEx("panel.pending_member_detail.deny.description", "If you choose not to accept this person, please provide a reason."),
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies.regular,
                          fontSize: 14,
                          color: Styles().colors.textSurface
                      ),
                  )),
                  Container(height: 8,),
                  Container(
                    height: 114,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Container(
                      padding: EdgeInsets.symmetric(),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Styles().colors.fillColorPrimary),
                      ),
                      child:
                      Row(children: [
                        Expanded(child: TextField(
                          controller: _reasonController,
                          decoration: InputDecoration(
                              border: InputBorder.none),
                          style: TextStyle(
                              color: Styles().colors.fillColorPrimary,
                              fontSize: 16,
                              fontFamily: Styles().fontFamilies.regular),
                          onChanged: (text){setState(() {});},
                          minLines: 4,
                          maxLines: 999,
                        ))
                      ],)
                  )),
                  Container(height: 13,)
                ],
              )
            )
          ],
          )
      );
  }

  Widget _buildBottomButtons(BuildContext context){
    return SafeArea(child: Container(
      color: Styles().colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: <Widget>[
            Expanded(child:
              Stack(children: <Widget>[
                ScalableRoundedButton(
                  label: _continueButtonText,
                  hint: Localization().getStringEx("panel.pending_member_detail.button.add.hint", ""),
                  backgroundColor: Styles().colors.white,
                  borderColor: _canContinue? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
                  textColor: _canContinue? Styles().colors.fillColorPrimary : Styles().colors.surfaceAccent,
                  fontFamily: Styles().fontFamilies.bold,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  onTap: () { _processMembership(); },
                ),
                Visibility(visible: _updating, child:
                  Center(child:
                    Padding(padding: EdgeInsets.only(top: 12), child:
                    Container(width: 24, height: 24, child:
                        CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary), strokeWidth: 2,)
                      ),
                    ),
                  ),
                ),
              ],),
            )
        ],
      ),
    ));
  }

  void _processMembership() {
    if(_updating){
      return;
    }
    setState(() {
      _updating = true;
    });

    Groups().acceptMembership(widget.group.id, widget.member.id, _approved, _reasonController.text).then((bool result) {
      if (mounted) {
        setState(() {
          _updating = false;
        });
        if (result) {
          Navigator.pop(context);
        }
        else {
          AppAlert.showDialogResult(context, 'Failed to' + (_approved ? " accept " : " reject ") + "the membership request"); //TBD localize
        }
      }
    });
  }

  bool get _canContinue{
    return _approved || (_denied && (_reasonController?.text?.isNotEmpty ?? false));
  }

  String get _continueButtonText{
      if(_approved){
        return Localization().getStringEx("panel.pending_member_detail.button.approve_member.title", "Approve member");
      }

      if(_denied){
        if(_reasonController?.text?.isNotEmpty ?? false) {
          return Localization().getStringEx("panel.pending_member_detail.button.approve_member.title", "Deny member");
        } else {
          return Localization().getStringEx("panel.pending_member_detail.button.approve_member.title", "Provide deny reason");
        }
      }
      return Localization().getStringEx("panel.pending_member_detail.button.selection.title", "Make selection above");
  }
}

class _MembershipAnswer extends StatelessWidget{
  final Member member;
  final GroupMembershipAnswer answer;
  _MembershipAnswer({@required this.member, @required this.answer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(answer?.question ?? '',
          style: TextStyle(
              fontFamily: Styles().fontFamilies.bold,
              fontSize: 14,
              color: Styles().colors.fillColorPrimary
          ),
        ),
        Container(height: 9,),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Styles().colors.white,
            border: Border.all(color: Styles().colors.fillColorPrimary)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(children: [
                Expanded(child:
                  Text(answer?.answer ?? "",
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.regular,
                        fontSize: 16,
                        color: Styles().colors.textBackground
                    ),
                  ),
                )
              ],),
              Container(height: 10,)
            ],
          ),
        )
       ],
    );
  }
}