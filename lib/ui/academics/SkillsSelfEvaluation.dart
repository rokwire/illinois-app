// Copyright 2022 Board of Trustees of the University of Illinois.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluationResultsPanel.dart';
import 'package:rokwire_plugin/service/flex_ui.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/polls.dart' as polls;
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/widgets/ribbon_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';


class SkillsSelfEvaluation extends StatefulWidget {

  SkillsSelfEvaluation();

  @override
  _SkillsSelfEvaluationState createState() => _SkillsSelfEvaluationState();
}

class _SkillsSelfEvaluationState extends State<SkillsSelfEvaluation> {
  //TODO: The completion of the UI for this widget will be addressed by #2513
  @override
  Widget build(BuildContext context) {
    return SectionSlantHeader(
        header: _buildHeader(),
        slantColor: Styles().colors?.gradientColorPrimary,
        backgroundColor: Styles().colors?.background,
        // children: _buildContent(),
        // childrenPadding: const EdgeInsets.only(top: 240),
      );
    // return Column(children: <Widget>[
    //   Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
    //     RibbonButton(
    //       label: 'Get Started',
    //       onTap: _onTapStartEvaluation
    //     ),
    //   ),
    //   Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
    //     RibbonButton(
    //       label: 'Results',
    //       onTap: _onTapResults
    //     ),
    //   ),
    // ]);
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 100, bottom: 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(Localization().getStringEx('panel.skills_self_evaluation.get_started.section.title', 'Skills Self Evaluation'), style: TextStyle(fontFamily: "ProximaNovaExtraBold", fontSize: 36.0, color: Styles().colors?.surface), textAlign: TextAlign.left,),
          IconButton(icon: Image.asset('images/tab-more.png', color: Styles().colors?.surface), onPressed: _onTapShowBottomSheet,),
        ]),
        Text(Localization().getStringEx('panel.skills_self_evaluation.get_started.time.description', '5 Minutes'), style: TextStyle(fontFamily: "ProximaNovaBold", fontSize: 16.0, color: Styles().colors?.fillColorSecondary), textAlign: TextAlign.left,),
      ]),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Styles().colors?.fillColorPrimaryVariant ?? Colors.transparent,
            Styles().colors?.gradientColorPrimary ?? Colors.transparent,
          ]
        )
      ),
    );
  }

  void _onTapShowBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Styles().colors?.surface,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Container(
                height: 24,
              ),
              RibbonButton(
                rightIconAsset: "images/chevron-right.png",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.past_results.label", "View past results"),
                textColor: Styles().colors?.fillColorPrimaryVariant,
                onTap: _onTapResults,
              ),
              RibbonButton(
                rightIconAsset: "images/chevron-right.png",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.where_results_go.label", "Where do my results go?"),
                textColor: Styles().colors?.fillColorPrimaryVariant,
                // onTap: () {
                //   Navigator.of(context).pop();
                //   _onTapCreatePost();
                // }
              ),
              RibbonButton(
                rightIconAsset: "images/chevron-right.png",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.how_results_determined.label", "How are my results determined?"),
                textColor: Styles().colors?.fillColorPrimaryVariant,
                // onTap: () {
                //   Navigator.of(context).pop();
                //   _onTapCreatePost();
                // }
              ),
              RibbonButton(
                rightIconAsset: "images/chevron-right.png",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.why_skills_matter.label", "Why do these skills matter?"),
                textColor: Styles().colors?.fillColorPrimaryVariant,
                // onTap: () {
                //   Navigator.of(context).pop();
                //   _onTapCreatePost();
                // }
              ),
              RibbonButton(
                rightIconAsset: "images/chevron-right.png",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.who_created_assessment.label", "Who created this assessment?"),
                textColor: Styles().colors?.fillColorPrimaryVariant,
                // onTap: () {
                //   Navigator.of(context).pop();
                //   _onTapCreatePost();
                // }
              ),
            ]));
      });
  }

  void _onTapStartEvaluation() {
    dynamic academicUiComponents = FlexUI()['academics'];
    if (academicUiComponents is Iterable<String>) {
      if (Config().bessiSurveyID != null && Auth2().isOidcLoggedIn && academicUiComponents.contains('skills_self_evaluation')) {
        // You need to be signed in with your NetID to access Assessments.\nSet your privacy level to 4 or 5. Then, sign in with your NetID under Settings.
        Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: Config().bessiSurveyID, onComplete: _onTapResults,)));
      }
    } 
  }

  void _onTapResults() {
    Navigator.of(context).pop();
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SkillsSelfEvaluationResultsPanel()));
  }
}

class SkillsSelfEvaluationResultsWidget extends StatefulWidget {

  SkillsSelfEvaluationResultsWidget();

  @override
  _SkillsSelfEvaluationResultsWidgetState createState() => _SkillsSelfEvaluationResultsWidgetState();
}

class _SkillsSelfEvaluationResultsWidgetState extends State<SkillsSelfEvaluationResultsWidget> implements NotificationsListener {

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      polls.Polls.notifySurveyResponseCreated,
    ]);
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionSlantHeader(
      slantColor: Styles().colors?.fillColorPrimary
    );
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == polls.Polls.notifySurveyResponseCreated) {
      // _refreshHistory();
    }
  }
}