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
import 'package:illinois/ui/widgets/AccessWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;


class EssentialSkillsLearning extends StatefulWidget {
  final Function (String?)? onStartCourse;
  final String? selectedSkill;

  EssentialSkillsLearning({required this.onStartCourse, this.selectedSkill});

  @override
  _EssentialSkillsLearningState createState() => _EssentialSkillsLearningState();
}

class _EssentialSkillsLearningState extends State<EssentialSkillsLearning> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('', 'Let\'s Get Started'), leading: RootHeaderBarLeading.Back,),
      body: SectionSlantHeader(
        headerWidget: _buildHeader(),
        slantColor: Styles().colors.gradientColorPrimary,
        slantPainterHeadingHeight: 0,
        backgroundColor: Styles().colors.background,
        children: [
          Styles().images.getImage("streak", color: Styles().colors.fillColorPrimary) ?? Container(),
          Padding(padding: EdgeInsets.only(top: 64, left: 64, right: 80), child: RoundedButton(
              label: Localization().getStringEx("", 'Start'),
              textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat.variant"),
              backgroundColor: Styles().colors.surface,
              onTap: _onTap
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
        Text(Localization().getStringEx('', 'Start Learning'), style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.get_started.header'), textAlign: TextAlign.left,),
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
      Text(Localization().getStringEx("", 'Check back every day to complete your daily activity and keep your streak!'), style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.header.description'),),
      // Padding(padding: EdgeInsets.only(top: 8), child: Text(
      //   Localization().getStringEx("panel.essential_skills_coach.get_started.description.list", '\t\t\u2022 self-management\n\t\t\u2022 innovation\n\t\t\u2022 cooperation\n\t\t\u2022 social engagement\n\t\t\u2022 emotional resilience'),
      //   style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.header.description'),
      // ))
    ]);
  }

  void _onTap() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onStartCourse?.call(widget.selectedSkill);
  }

}
