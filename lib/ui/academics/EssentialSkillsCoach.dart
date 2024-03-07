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
import 'package:rokwire_plugin/gen/styles.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'EssentialSkillsCoachGetStarted.dart';
import 'EssentialSkillsResults.dart';


class EssentialSkillsCoach extends StatefulWidget {
  final Function (String?)? onStartCourse;

  EssentialSkillsCoach({this.onStartCourse});

  @override
  _EssentialSkillsCoachState createState() => _EssentialSkillsCoachState();
}

class _EssentialSkillsCoachState extends State<EssentialSkillsCoach> {

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return _loading ? Center(child: CircularProgressIndicator()) : SectionSlantHeader(
        headerWidget: _buildHeader(),
        slantColor: AppColors.gradientColorPrimary,
        slantPainterHeadingHeight: 0,
        backgroundColor: AppColors.background,
        // children: [],
        childrenPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        allowOverlap: false,
      );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 32, bottom: 32),
      child: Padding(padding: EdgeInsets.only(left: 24, right: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(Localization().getStringEx('panel.essential_skills_coach.get_started.section.title', 'Essential Skills Coach'), style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.get_started.header'), textAlign: TextAlign.left,),
        Padding(padding: EdgeInsets.only(top: 24), child: _buildDescription()),
        Padding(padding: EdgeInsets.only(top: 64, left: 64, right: 80), child: RoundedButton(
          label: Localization().getStringEx("panel.essential_skills_coach.get_started.button.label", 'Get Started'),
          textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat.variant"),
          backgroundColor: AppColors.surface,
          onTap:_loadResults
        )),
      ]),),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.fillColorPrimaryVariant,
            AppColors.gradientColorPrimary,
          ]
        )
      ),
    );
  }

  Widget _buildDescription() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(Localization().getStringEx("panel.essential_skills_coach.get_started.description.title",
          'Improve your skills related to:'),
        style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.header.description'),),
      Padding(padding: EdgeInsets.only(top: 8), child: Text(
        Localization().getStringEx("panel.essential_skills_coach.get_started.description.list", '\t\t\u2022 self-management\n\t\t\u2022 innovation\n\t\t\u2022 cooperation\n\t\t\u2022 social engagement\n\t\t\u2022 emotional resilience'),
        style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.header.description'),
      ))
    ]);
  }

  // void _onTapStartSkillsCoach() async {
  //   //TODO: begin skills coach onboarding, for now create user course and immediately start
  //   Future<bool?>? result = AccessDialog.show(context: context, resource: 'academics.essential_skills_coach');
  //   if (result == null) {
  //     if (StringUtils.isNotEmpty(Config().essentialSkillsCoachKey)) {
  //       widget.onStartCourse?.call(null);
  //     }
  //   } else {
  //     bool? accessResult = await result;
  //     if (accessResult == true) {
  //       widget.onStartCourse?.call(null);
  //     }
  //   }
  // }

  void _loadResults() {
    setState(() {
      _loading = true;
    });
    Surveys().loadUserSurveyResponses(surveyTypes: ["bessi"], limit: 10).then((responses) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        if (CollectionUtils.isNotEmpty(responses)) {
          responses!.sort(((a, b) => b.dateTaken.compareTo(a.dateTaken)));
          Navigator.of(context).push(CupertinoPageRoute(builder: (context) => EssentialSkillsResults(latestResponse: responses[0], onStartCourse: widget.onStartCourse)));
        }
        else {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => EssentialSkillsCoachGetStarted(onStartCourse: widget.onStartCourse)));
        }
      }
    });
  }
}
