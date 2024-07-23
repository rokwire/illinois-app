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
import 'package:neom/service/Config.dart';
import 'package:neom/ui/surveys/SurveyPanel.dart';
import 'package:neom/ui/academics/EssentialSkillsResults.dart';
import 'package:neom/ui/widgets/AccessWidgets.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;


class EssentialSkillsCoachGetStarted extends StatefulWidget {
  final Function (String?)? onStartCourse;

  EssentialSkillsCoachGetStarted({required this.onStartCourse});

  @override
  _EssentialSkillsCoachGetStartedState createState() => _EssentialSkillsCoachGetStartedState();
}

class _EssentialSkillsCoachGetStartedState extends State<EssentialSkillsCoachGetStarted> {

  @override
  void initState() {
    _loadResults();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.essential_skills_coach.get_started.header.title', 'Take the Self-Evaluation'), leading: RootHeaderBarLeading.Back,),
      body: SectionSlantHeader(
        headerWidget: _buildHeader(),
        slantColor: Styles().colors.gradientColorPrimary,
        slantPainterHeadingHeight: 0,
        backgroundColor: Styles().colors.background,
        children: [
          Padding(padding: EdgeInsets.only(top: 64, left: 64, right: 80), child: RoundedButton(
            label: Localization().getStringEx("panel.essential_skills_coach.get_started.button.start.label", 'Start Evaluation'),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat.variant"),
            backgroundColor: Styles().colors.surface,
            onTap: _onTapStartEvaluation,
          )),
        ],
        childrenPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        allowOverlap: false,
      ),
        bottomNavigationBar: uiuc.TabBar()
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 32, bottom: 32),
      child: Padding(padding: EdgeInsets.only(left: 24, right: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(Localization().getStringEx('panel.essential_skills_coach.get_started.take_evaluation_header', 'Take the Essential Skills Self-Evaluation'), style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.get_started.header'), textAlign: TextAlign.left,),
        Text(Localization().getStringEx('panel.skills_self_evaluation.get_started.time.description', '5 Minutes'), style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.get_started.time.description'), textAlign: TextAlign.left,),
        Padding(padding: EdgeInsets.only(top: 24), child: _buildDescription()),
      ]),),
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Styles().colors.fillColorPrimaryVariant,
                Styles().colors.gradientColorPrimary,
              ]
          )
      ),
    );
  }

  Widget _buildDescription() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(Localization().getStringEx('panel.essential_skills_coach.get_started.take_evaluation.message',
          'Before getting started, take the skills self-evaluation to identify your current strengths related to:'),
        style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.header.description'),),
      Padding(padding: EdgeInsets.only(top: 8), child: Text(
        Localization().getStringEx("panel.essential_skills_coach.get_started.description.list",
            '\t\t\u2022 self-management\n\t\t\u2022 innovation\n\t\t\u2022 cooperation\n\t\t\u2022 social engagement\n\t\t\u2022 emotional resilience'),
        style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.header.description'),
      ))
    ]);
  }

  void _onTapStartEvaluation() {
    Future? result = AccessDialog.show(context: context, resource: 'academics.essential_skills_coach');
    if (Config().bessiSurveyID != null && result == null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: Config().bessiSurveyID, onComplete: _gotoResults, offlineWidget: _buildOfflineWidget(), tabBar: uiuc.TabBar())));
    }
  }

  void _gotoResults(dynamic response) {
    if (response is SurveyResponse) {
      Navigator.of(context).push(CupertinoPageRoute(builder: (context) => EssentialSkillsResults(onStartCourse: widget.onStartCourse, latestResponse: response,)));
    }
  }

  Widget _buildOfflineWidget() {
    return Padding(padding: EdgeInsets.all(28), child:
      Center(child:
        Text(
            Localization().getStringEx('panel.skills_self_evaluation.get_started.offline.error.msg', 'Skills Self-Evaluation is not available while offline.'),
            textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.title')
        )
      ),
    );
  }

  void _loadResults() {
    Surveys().loadUserSurveyResponses(surveyTypes: ["bessi"], limit: 10).then((responses) {
      if (CollectionUtils.isNotEmpty(responses)) {
        responses!.sort(((a, b) => b.dateTaken.compareTo(a.dateTaken)));
        if(mounted) {
          _gotoResults(responses[0]);
        }
      }
    });
  }
}
