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

import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';

class SkillsSelfEvaluationResultsPanel extends StatefulWidget {

  SkillsSelfEvaluationResultsPanel();

  @override
  _SkillsSelfEvaluationResultsPanelState createState() => _SkillsSelfEvaluationResultsPanelState();
}

class _SkillsSelfEvaluationResultsPanelState extends State<SkillsSelfEvaluationResultsPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootBackHeaderBar(title: Localization().getStringEx('panel.skills_self_evaluation.results.header.title', 'Skills Self-Evaluation'),),
      body: SectionSlantHeader(
        header: _buildHeader(),
        slantColor: Styles().colors?.gradientColorPrimary,
        backgroundColor: Styles().colors?.background,
      ),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.section.title', 'Results'), style: TextStyle(fontFamily: "ProximaNovaExtraBold", fontSize: 32.0, color: Styles().colors?.surface), textAlign: TextAlign.center,),
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.score.description', 'Skills Domain Score'), style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.surface), textAlign: TextAlign.center,),
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.score.scale', '(0-100)'), style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.surface), textAlign: TextAlign.center,),
      ]),
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Styles().colors?.fillColorPrimaryVariant ?? Colors.transparent,
                Styles().colors?.gradientColorPrimary ?? Colors.transparent,
              ])),
      // color: Styles().colors?.fillColorPrimaryVariant,
    );
  }

  // List<Widget> _buildHeaderWidgets() {
  //   List<Widget> headerWidgets = [];
  //   headerWidgets.add(
  //     Text(Localization().getStringEx('panel.skills_self_evaluation.results.section.title', 'Results'), style: TextStyle(fontFamily: "ProximaNovaExtraBold", fontSize: 32.0, color: Styles().colors?.surface),),
  //   );
  //   headerWidgets.add(
  //     Text(Localization().getStringEx('panel.skills_self_evaluation.results.section.title', 'Results'), style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.surface),),
  //   );
  //   headerWidgets.add(
  //     Text(Localization().getStringEx('panel.skills_self_evaluation.results.section.title', 'Results'), style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.surface),),
  //   );
  //   return headerWidgets;
  // }
}

