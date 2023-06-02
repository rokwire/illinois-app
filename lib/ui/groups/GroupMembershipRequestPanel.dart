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
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GroupMembershipRequestPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Group? group;

  GroupMembershipRequestPanel({this.group});

  @override
  _GroupMembershipRequestPanelState createState() =>
      _GroupMembershipRequestPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes =>
    group?.analyticsAttributes;
}

class _GroupMembershipRequestPanelState extends State<GroupMembershipRequestPanel> {
  late List<GroupMembershipQuestion> _questions;
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  bool _submitting = false;
  bool _researchProjectConsent = false;
  final double outerPadding = 16;

  @override
  void initState() {
    _focusNodes = [];
    _controllers = [];
    _questions = widget.group?.questions ?? [];
    for (int index = 0; index < _questions.length; index++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }

    super.initState();
  }

  @override
  void dispose() {
    for (int index = 0; index < _questions.length; index++) {
      _controllers[index].dispose();
      _focusNodes[index].dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> content = [
      _buildHeading()
    ];

    content.addAll(_buildQuestions());

    content.add(_buildResearchProjectSubmit());

    return Scaffold(
      appBar: HeaderBar(
        title: (widget.group?.researchProject != true) ?
          Localization().getStringEx("panel.membership_request.label.request.membership.title", 'Membership Questions') :
          Localization().getStringEx("panel.membership_request.label.request.participate.title", 'Invitation Questions'),
        leadingIconKey: 'close-circle-white',
      ),
      body: Column(children: <Widget>[
        Expanded(child:
          SingleChildScrollView(child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: content,),
          ),
        ),
        _buildSubmit(),
      ],),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildHeading() {
    String headingText = (widget.group?.researchProject != true) ?
      Localization().getStringEx("panel.membership_request.label.group.description", 'This group asks you to answer the following question(s) for membership consideration.') :
      Localization().getStringEx("panel.membership_request.label.project.description", 'This Research Project wants you to answer the following question(s) for participation consideration.');
    return Padding(padding: EdgeInsets.only(left: outerPadding, right: outerPadding, top: outerPadding), child:
      Text(headingText, style: Styles().textStyles?.getTextStyle("widget.description.variant.regular.thin"))
    );
  }

  List<Widget> _buildQuestions() {
    List<Widget> content = [];
    for (int index = 0; index < _questions.length; index++) {
      content.add(_buildQuestion(question: _questions[index].question!, controller:_controllers[index], focusNode: _focusNodes[index]));
    }
    return content;
  }

  Widget _buildQuestion({required String question, TextEditingController? controller, FocusNode? focusNode}) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: outerPadding, vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(question, style: Styles().textStyles?.getTextStyle("widget.title.regular.fat")),
        Padding(padding: EdgeInsets.only(top: 8),
          child: TextField(
            maxLines: 6,
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
            style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")
          ),
        ),
      ],)
    ,);
  }

  Widget _buildSubmit() {
    if (widget.group?.researchProject != true) {
      return Container(decoration: BoxDecoration(color: Styles().colors?.white, border: Border(top: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1))), child:
        Padding(padding: EdgeInsets.all(16), child:
          RoundedButton(label: Localization().getStringEx("panel.membership_request.button.submit.title", 'Submit request'),
            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
            backgroundColor: Styles().colors!.white,
            borderColor: Styles().colors!.fillColorSecondary,
            borderWidth: 2,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            progress: (_submitting == true),
            onTap:() { _onSubmit();  }
          ),
        ),
      );
    }
    else {
      return Container();
    }
  }

  Widget _buildResearchProjectSubmit() {
    if (widget.group?.researchProject == true) {
      bool showConsent = StringUtils.isNotEmpty(widget.group?.researchConsentStatement);
      bool requestToJoinEnabled = StringUtils.isEmpty(widget.group?.researchConsentStatement) || _researchProjectConsent;
      return Padding(padding: EdgeInsets.zero, child:
        Column(children: [
          Visibility(visible: showConsent, child:
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              InkWell(onTap: _onResearchProjectConsent, child:
                Padding(padding: EdgeInsets.only(left: outerPadding, right: 8, top: 16, bottom: 16), child:
                  Styles().images?.getImage(_researchProjectConsent ? "check-box-filled" : "box-outline-gray", excludeFromSemantics: true),
                ),
              ),
              Expanded(child:
                Padding(padding: EdgeInsets.only(right: 16, top: 16, bottom: 16), child:
                  Text(widget.group?.researchConsentStatement ?? '', style: Styles().textStyles?.getTextStyle("widget.detail.regular"), textAlign: TextAlign.left,)
                ),
              ),
            ]),
          ),
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: showConsent ? 0 : 16, bottom: 16), child:
            RoundedButton(label: "Request to participate",
              textStyle: requestToJoinEnabled ? Styles().textStyles?.getTextStyle("widget.button.title.enabled") : Styles().textStyles?.getTextStyle("widget.button.title.disabled"),
              backgroundColor: Styles().colors!.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              borderColor: requestToJoinEnabled ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
              borderWidth: 2,
              onTap:() { _onSubmit();  }
            ),
          ),
        ],),
      );
    }
    else {
      return Container();
    }
  }

  void _onResearchProjectConsent() {
    setState(() {
      _researchProjectConsent = !_researchProjectConsent;
    });
  }

  void _onSubmit() {
    Analytics().logSelect(target: 'Submit request');
    if (_submitting != true) {
      List<GroupMembershipAnswer> answers = [];
      for (int index = 0; index < _questions.length; index++) {
        String? question = _questions[index].question;
        TextEditingController controller = _controllers[index];
        FocusNode focusNode = _focusNodes[index];
        String answer = controller.text;
        if (0 < answer.length) {
          answers.add(GroupMembershipAnswer(question: question, answer: answer));
        }
        else {
          AppAlert.showDialogResult(context,Localization().getStringEx("panel.membership_request.label.alert",  'Please answer ')+ question!).then((_){
            focusNode.requestFocus();
          });
          return;
        }
      }

      setState(() {
        _submitting = true;
      });

      Groups().requestMembership(widget.group, answers).then((_){
        if (mounted) {
          setState(() {
            _submitting = false;
          });
          Navigator.pop(context);
        }
      }).catchError((_){
        AppAlert.showDialogResult(context, Localization().getStringEx("panel.membership_request.label.fail", 'Failed to submit request'));
      });
    }
  }
}