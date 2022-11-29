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
import 'package:illinois/ui/academics/SkillsSelfEvaluation.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';

class SkillsSelfEvaluationResultsDetailPanel extends StatefulWidget {
  final SkillsSelfEvaluationContent? content;
  final String skillDefinition;

  SkillsSelfEvaluationResultsDetailPanel({required this.content, required this.skillDefinition});

  @override
  _SkillsSelfEvaluationResultsDetailPanelState createState() => _SkillsSelfEvaluationResultsDetailPanelState();
}

class _SkillsSelfEvaluationResultsDetailPanelState extends State<SkillsSelfEvaluationResultsDetailPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootBackHeaderBar(title: Localization().getStringEx('panel.skills_self_evaluation.results.header.title', 'Skills Self-Evaluation'),),
      body: widget.content != null ? SectionSlantHeader(
        header: _buildHeader(),
        slantColor: Styles().colors?.gradientColorPrimary,
        backgroundColor: Styles().colors?.background,
        // children: _buildContent(),
        // childrenPadding: const EdgeInsets.only(top: 240),
      ) : Padding(padding: const EdgeInsets.all(24.0), child: Text(
        Localization().getStringEx("panel.skills_self_evaluation.results_detail.missing_content", "There is no detailed results content for this skill."),
        style: TextStyle(fontFamily: "ProximaNovaBold", fontSize: 20.0, color: Styles().colors?.fillColorPrimaryVariant),
        textAlign: TextAlign.center,
      )),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: null,
    );
  }

  Widget _buildHeader() {
  return Container(
    padding: EdgeInsets.only(top: 100, bottom: 32),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(widget.content!.header?.title ?? '', style: TextStyle(fontFamily: "ProximaNovaExtraBold", fontSize: 36.0, color: Styles().colors?.surface), textAlign: TextAlign.center,),
      // Text(Localization().getStringEx('panel.skills_self_evaluation.results.score.description', 'Skills Domain Score'), style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.surface), textAlign: TextAlign.center,),
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
}
