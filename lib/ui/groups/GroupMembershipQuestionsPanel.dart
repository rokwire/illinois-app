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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class GroupMembershipQuestionsPanel extends StatefulWidget {
  final List<GroupMembershipQuestion>? questions;

  GroupMembershipQuestionsPanel({this.questions});

  @override
  _GroupMembershipQuestionsPanelState createState() =>
      _GroupMembershipQuestionsPanelState();
}

class _GroupMembershipQuestionsPanelState extends State<GroupMembershipQuestionsPanel> {
  List<GroupMembershipQuestion>? _questions;
  List<FocusNode>? _focusNodes;
  List<TextEditingController>? _controllers;

  bool get _addButtonEnabled{
    for(TextEditingController textEditingController in _controllers!){
      if(StringUtils.isEmpty(textEditingController.text)){
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    _questions = GroupMembershipQuestion.listFromOthers(widget.questions) ?? [];
    if (_questions!.isEmpty) {
      _questions!.add(GroupMembershipQuestion());
    }
    _focusNodes = [];
    _controllers = [];
    for (GroupMembershipQuestion? question in _questions!) {
      _controllers!.add(TextEditingController(text: question!.question ?? ''));
      _focusNodes!.add(FocusNode());
    }

    super.initState();
  }

  @override
  void dispose() {
    for (TextEditingController controller in _controllers!) {
      controller.dispose();
    }
    _controllers = null;

    for (FocusNode focusNode in _focusNodes!) {
      focusNode.dispose();
    }
    _focusNodes = null;
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        backIconRes: 'images/icon-circle-close.png',
        titleWidget: Text(Localization().getStringEx("panel.membership_questions.label.title", 'Membership Question')!,
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: Styles().fontFamilies!.extraBold,
              letterSpacing: 1.0),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildHeading(),
                    _buildQuestions(),
                  ],
                ),
            ),
          ),
          _buildSubmit(),
        ],
      ),
      backgroundColor: Styles().colors!.background,
    );
  }

  Widget _buildHeading() {
    return Container(color:Colors.white,
      child: Padding(padding: EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children:<Widget>[
            Row(children: <Widget>[
              Text(Localization().getStringEx("panel.membership_questions.label.edit", 'Edit Questions')!, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary),),
            ],),
            Padding(padding: EdgeInsets.only(top: 8), child:
              Text(Localization().getStringEx("panel.membership_questions.label.description", 'Learn more about people who want to join your group by asking them some questions. Only the admins of your group will see the answers.')!, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Color(0xff494949))),
            ),
          ]),
      ),
    );
  }

  Widget _buildQuestions() {
    List<Widget> content = [];
    for (int index = 0; index < _questions!.length; index++) {
      content.add(_buildQuestion(index: index));
    }

    content.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      Expanded(child: Container(),),
      GroupMembershipAddButton(
        height: 26 + 16*MediaQuery.of(context).textScaleFactor ,
        title: Localization().getStringEx("panel.membership_questions.button.add_question.title", 'Add question'),
        onTap: _addQuestion,
        enabled: _addButtonEnabled,
      ),
    ],));

    return Padding(padding: EdgeInsets.all(32),
      child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: content),
    );
  }

  Widget _buildQuestion({required int index}) {
    return Padding(padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.only(bottom: 4),
          child: Text(Localization().getStringEx("panel.membership_questions.label.question", 'QUESTION #')!+(index+1).toString(), style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 12, color: Styles().colors!.fillColorPrimary),),
        ),
        Stack(children: <Widget>[
          Container(color: Styles().colors!.white,
            child: TextField(
              maxLines: 2,
              controller: _controllers![index],
              focusNode: _focusNodes![index],
              onChanged: _onTextChanged,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
              style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground,),
            ),
          ),
          Align(alignment: Alignment.topRight,
            child: GestureDetector(onTap: () { _removeQuestion(index: index); },
              child: Container(width: 36, height: 36,
                child: Align(alignment: Alignment.center,
                  child:Semantics(
                    label: Localization().getStringEx("panel.membership_questions.button.clear.hint", "clear"),
                    button: true,
                    excludeSemantics: true,
                    child: Text('X', style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.fillColorPrimary,),),
                )),
              ),
            ),
          ),
        ],),
      ],),);
  }

  Widget _buildSubmit() {
    return Container(color: Colors.white,
      child: Padding(padding: EdgeInsets.all(16),
        child: Row(children: <Widget>[
          Expanded(flex: 1,child: Container(),),
          Expanded(flex: 5,
          child: ScalableRoundedButton(label: Localization().getStringEx("panel.membership_questions.button.update_question.title", 'Update questions'),
            backgroundColor: Styles().colors!.white,
            textColor: Styles().colors!.fillColorPrimary,
            fontFamily: Styles().fontFamilies!.bold,
            fontSize: 16,
            padding: EdgeInsets.symmetric(horizontal: 32, ),
            borderColor: Styles().colors!.fillColorSecondary,
            borderWidth: 2,
            onTap:() { _onSubmit();  }
            )
          ),
          Expanded(flex: 1, child: Container(),),
        ],),
      ),
    );
  }

  void _addQuestion() {
    Analytics().logSelect(target: 'Add question');
    setState(() {
      _questions!.add(GroupMembershipQuestion());
      _controllers!.add(TextEditingController());
      _focusNodes!.add(FocusNode());
    });
    Timer(Duration(milliseconds: 100), () {
      _focusNodes!.last.requestFocus();
    });
  }

  void _removeQuestion({int? index}) {
    Analytics().logSelect(target: 'Remove question');
    setState(() {
      _questions!.removeAt(index!);
      _controllers!.removeAt(index);
      _focusNodes!.removeAt(index);
    });
  }

  void _onSubmit() {
    Analytics().logSelect(target: 'Update questions');
    for (int index = 0; index < _questions!.length; index++) {
      String question = _controllers![index].text;
      if ((0 < question.length)) {
        _questions![index].question = question;
      }
      else {
        AppAlert.showDialogResult(context, Localization().getStringEx("panel.membership_questions.label.question.alert", 'Please input question #')!+(index+1).toString()).then((_){
          _focusNodes![index].requestFocus();
        });
        return;
      }
    }

    Navigator.pop(context, _questions);
  }

  void _onTextChanged(String text){
    setState(() {});
  }

}