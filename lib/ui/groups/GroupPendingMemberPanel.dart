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
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class GroupPendingMemberPanel extends StatefulWidget {
  final GroupPendingMember member;
  final GroupDetail groupDetail;
  GroupPendingMemberPanel({this.member, this.groupDetail});
  _GroupPendingMemberPanelState createState() => _GroupPendingMemberPanelState();
}


class _GroupPendingMemberPanelState extends State<GroupPendingMemberPanel> {

  bool _decision;

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
                    _buildDetails(),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomButtons(context)
        ],
      ),
    );
  }

  Widget _buildHeading(){
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(65),
            child: Container(width: 65, height: 65 ,child: Image.network(widget.member.photoURL)),
          ),
        ),
        Container(width: 16,),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(Localization().getStringEx("panel.pending_member_detail.label.pending", "PENDING"),
                style: TextStyle(
                  fontFamily: Styles().fontFamilies.bold,
                  fontSize: 12,
                  color: Styles().colors.fillColorPrimary
                ),
              ),
              Container(height: 8,),
              Text(widget.member?.name ?? "",
                style: TextStyle(
                    fontFamily: Styles().fontFamilies.extraBold,
                    fontSize: 20,
                    color: Styles().colors.fillColorPrimary
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDetails(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(height: 32,),
        _buildQuestions(),
        _buildContact()
      ],
    );
  }

  Widget _buildQuestions(){
    List<Widget> list = List<Widget>();
    for (int index = 0; index < widget.member.membershipRequest.answers.length; index++) {
      GroupMembershipAnswer answer = widget.member.membershipRequest.answers[index];
      GroupMembershipQuestion question = (index < (widget.groupDetail?.membershipQuest?.questions?.length ?? 0)) ? widget.groupDetail.membershipQuest.questions[index] : null;
      list.add(_MembershipAnswer(member: widget.member, question: question, answer: answer));
      list.add(Container(height: 10,));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(Localization().getStringEx("panel.pending_member_detail.label.membership_questions", "MEMBERSHIP QUESTIONS"),
          style: TextStyle(
              fontFamily: Styles().fontFamilies.bold,
              fontSize: 12,
              color: Styles().colors.fillColorPrimary
          ),
        ),
        Container(height: 13,),
        Column(children: list,),
      ],
    );
  }

  Widget _buildContact(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(height: 28,),
        Text(Localization().getStringEx("panel.pending_member_detail.label.contact", "CONTACT"),
          style: TextStyle(
              fontFamily: Styles().fontFamilies.bold,
              fontSize: 12,
              color: Styles().colors.fillColorPrimary
          ),
        ),
        Container(height: 8,),
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Styles().colors.white,
                    borderRadius: BorderRadius.circular(4)
                ),
                child: Text(widget.member?.email ?? "",
                  style: TextStyle(
                      fontFamily: Styles().fontFamilies.regular,
                      fontSize: 16,
                      color: Styles().colors.textBackground
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context){
    return SafeArea(child: Container(
      color: Styles().colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Stack(children: <Widget>[
              ScalableRoundedButton(
                label: Localization().getStringEx("panel.pending_member_detail.button.deny.title", "Deny"),
                hint: Localization().getStringEx("panel.pending_member_detail.button.deny.hint", ""),
                backgroundColor: Styles().colors.white,
                borderColor: Styles().colors.fillColorPrimary,
                textColor: Styles().colors.fillColorPrimary,
                fontFamily: Styles().fontFamilies.regular,
                onTap: () { _processMembership(decision: false); },
              ),
              Visibility(visible: _decision == false, child:
                Center(child:
                  Padding(padding: EdgeInsets.only(top: 12), child:
                  Container(width: 24, height: 24, child:
                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary), strokeWidth: 2,)
                    ),
                  ),
                ),
              ),
            ],),
          ),
          Container(width: 8,),
          Expanded(
            child: Stack(children: <Widget>[
              ScalableRoundedButton(
                label: Localization().getStringEx("panel.pending_member_detail.button.add.title", "Add"),
                hint: Localization().getStringEx("panel.pending_member_detail.button.add.hint", ""),
                backgroundColor: Styles().colors.white,
                borderColor: Styles().colors.fillColorSecondary,
                textColor: Styles().colors.fillColorPrimary,
                fontFamily: Styles().fontFamilies.bold,
                onTap: () { _processMembership(decision: true); },
              ),
              Visibility(visible: _decision == true, child:
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

  void _processMembership({bool decision}) {
    if (_decision == null) {
      setState(() {
        _decision = decision;
      });
    }
    Groups().acceptMembership(widget.groupDetail.id, widget.member.uin, decision).then((bool result) {
      if (mounted) {
        setState(() {
          _decision = null;
        });
        if (result) {
          Navigator.pop(context);
        }
        else {
          AppAlert.showDialogResult(context, 'Failed to submit decision'); //TBD localize
        }
      }
    });
  }
}

class _MembershipAnswer extends StatelessWidget{
  final GroupPendingMember member;
  final GroupMembershipAnswer answer;
  final GroupMembershipQuestion question;
  _MembershipAnswer({@required this.member, @required this.answer, @required this.question});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(question?.question ?? '',
          style: TextStyle(
              fontFamily: Styles().fontFamilies.regular,
              fontSize: 14,
              color: Styles().colors.textBackground
          ),
        ),
        Container(height: 5,),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Styles().colors.white,
            borderRadius: BorderRadius.all(Radius.circular(4))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Container(width: 32, height: 32 ,child: Image.network(member.photoURL)),
                  ),
                  Container(width: 12,),
                  Text(AppDateTime().formatDateTime(member.membershipRequest.dateCreated, format: "MMM dd"),
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.regular,
                        fontSize: 14,
                        color: Styles().colors.textBackground
                    ),
                  )
                ],
              ),
              Container(height: 16,),
              Text(answer?.answer ?? "",
                style: TextStyle(
                    fontFamily: Styles().fontFamilies.regular,
                    fontSize: 16,
                    color: Styles().colors.textBackground
                ),
              )
            ],
          ),
        )
       ],
    );
  }
}