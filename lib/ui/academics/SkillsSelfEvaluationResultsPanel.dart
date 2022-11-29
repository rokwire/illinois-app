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
import 'package:illinois/ui/academics/SkillsSelfEvaluation.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluationResultsDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SkillsSelfEvaluationResultsPanel extends StatefulWidget {
  final Map<String, SkillsSelfEvaluationContent> content;

  SkillsSelfEvaluationResultsPanel({required this.content});

  @override
  _SkillsSelfEvaluationResultsPanelState createState() => _SkillsSelfEvaluationResultsPanelState();
}

class _SkillsSelfEvaluationResultsPanelState extends State<SkillsSelfEvaluationResultsPanel> {
  List<SurveyResponse> _responses = [];
  SurveyResponse? _latestResponse;
  Set<String> _responseSections = {};
  DateTime? _selectedComparisonDate;

  @override
  void initState() {
    _loadResults();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootBackHeaderBar(title: Localization().getStringEx('panel.skills_self_evaluation.results.header.title', 'Skills Self-Evaluation'),),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child: SingleChildScrollView(
        child: SectionSlantHeader(
          header: _buildHeader(),
          slantColor: Styles().colors?.gradientColorPrimary,
          backgroundColor: Styles().colors?.background,
          children: _buildContent(),
          childrenPadding: const EdgeInsets.only(top: 180),
        ),
      )),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.section.title', 'Results'), style: TextStyle(fontFamily: "ProximaNovaExtraBold", fontSize: 36.0, color: Styles().colors?.surface), textAlign: TextAlign.center,),
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.score.description', 'Skills Domain Score'), style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.surface), textAlign: TextAlign.center,),
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.score.scale', '(0-100)'), style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.surface), textAlign: TextAlign.center,),
        _buildScoresHeader(),
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

  Widget _buildScoresHeader() {
    return Padding(padding: const EdgeInsets.only(top: 40, left: 28, right: 28, bottom: 32), child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Divider(color: Styles().colors?.surface, thickness: 2),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(flex: 4, fit: FlexFit.tight, child: Text(Localization().getStringEx('panel.skills_self_evaluation.results.skills.title', 'SKILLS'), style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 12.0, color: Styles().colors?.surface),)),
          Flexible(flex: 3, fit: FlexFit.tight, child: Text(_latestResponse != null ? DateTimeUtils.localDateTimeToString(_latestResponse!.dateTaken, format: 'MM/dd/yy h:mma') ?? 'NONE' : 'NONE', textAlign: TextAlign.center, style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 12.0, color: Styles().colors?.surface),)),
          Flexible(flex: 3, fit: FlexFit.tight, child: DropdownButtonHideUnderline(child:
            DropdownButton<DateTime?>(
              icon: Image.asset('images/icon-down.png', color: Styles().colors?.surface),
              isExpanded: true,
              style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 12.0, color: Styles().colors?.surface,),
              items: _buildResponseDateDropDownItems(),
              value: _selectedComparisonDate,
              onChanged: _onResponseDateDropDownChanged,
              dropdownColor: Styles().colors?.textBackground,
            ),
          )),
        ],)),
      ],
    ));
  }

  List<Widget> _buildContent() {
    return _latestResponse != null ? <Widget>[
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8),
        itemCount: _responseSections.length,
        itemBuilder: (BuildContext context, int index) {
          String section = _responseSections.elementAt(index);
          String title = _latestResponse!.survey.constants[section].toString();
          num? mostRecentScore = _latestResponse!.survey.stats?.percentages[section];
          if (mostRecentScore != null) {
            mostRecentScore = (mostRecentScore*100).round();
          }
          num? comparisonScore;
          try {
            comparisonScore = _responses.firstWhere((element) => element.dateTaken.isAtSameMomentAs(_selectedComparisonDate ?? DateTime(0))).survey.stats?.percentages[section];
            comparisonScore = (comparisonScore!*100).round();
          } catch (e) {
            debugPrint(e.toString());
          }

          return Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Card(
              child: InkWell(
                onTap: () => _showScoreDescription(section),
                child: Padding(padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16), child: Row(children: [
                  Flexible(flex: 5, fit: FlexFit.tight, child: Text(title, style: TextStyle(fontFamily: "ProximaNovaBold", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant))),
                  Flexible(flex: 3, fit: FlexFit.tight, child: Text(mostRecentScore?.toString() ?? "--", style: TextStyle(fontFamily: "ProximaNovaBold", fontSize: 36.0, color: Styles().colors?.fillColorSecondary), textAlign: TextAlign.center,)),
                  Flexible(flex: 3, fit: FlexFit.tight, child: Text(comparisonScore?.toString() ?? "--", style: TextStyle(fontFamily: "ProximaNovaBold", fontSize: 36.0, color: Styles().colors?.mediumGray), textAlign: TextAlign.center)),
                  Flexible(flex: 1, fit: FlexFit.tight, child: SizedBox(height: 16.0 , child: Image.asset('images/chevron-right.png', color: Styles().colors?.fillColorSecondary))),
                ],)),
              )
            ));
      }),
      Padding(padding: const EdgeInsets.only(top: 16, bottom: 32), child: GestureDetector(onTap: _onTapClearAllScores, child:
        Text("Clear All Scores", style: TextStyle(
          fontFamily: "ProximaNovaBold", 
          fontSize: 16.0, 
          color: Styles().colors?.fillColorPrimaryVariant,
          decoration: TextDecoration.underline,
          decorationColor: Styles().colors?.fillColorSecondary
        )
      ),)),
    ] : [];
  }

  List<DropdownMenuItem<DateTime?>> _buildResponseDateDropDownItems() {
    //TODO: add student average option?
    List<DropdownMenuItem<DateTime?>> items = <DropdownMenuItem<DateTime?>>[
      DropdownMenuItem<DateTime?>(
        value: null,
        child: Text('NONE', style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 12.0, color: Styles().colors?.surface,), textAlign: TextAlign.center,),
      )
    ];
    if (CollectionUtils.isNotEmpty(_responses)) {
      for (SurveyResponse response in _responses) {
        String dateString = DateTimeUtils.localDateTimeToString(response.dateTaken, format: 'MM/dd/yy h:mma') ?? '';
        items.add(DropdownMenuItem<DateTime>(
          value: response.dateTaken,
          child: Text(dateString, style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 12.0, color: Styles().colors?.surface,), textAlign: TextAlign.center,),
        ));
      }
    }
    return items;
  }

  void _loadResults() {
    Polls().loadSurveyResponses(surveyTypes: ["bessi"], limit: 10).then((responses) {
      if (CollectionUtils.isNotEmpty(responses)) {
        _responses = responses!;
        _responses.sort(((a, b) => b.dateTaken.compareTo(a.dateTaken)));
        _latestResponse = _responses[0];

        _responseSections.clear();
        for (SurveyResponse response in responses) {
          _responseSections.addAll(response.survey.stats?.scores.keys ?? []);
        }
        setState(() {});
      }
    });
  }

  Future<void> _onPullToRefresh() async {
    _loadResults();
  }

  void _onResponseDateDropDownChanged(DateTime? value) {
    setState(() {
      _selectedComparisonDate = value;
    });
  }

  void _showScoreDescription(String section) {
    if (_latestResponse?.survey.resultData is Map<String, dynamic>) {
      String skillDefinition = _latestResponse!.survey.resultData['${section}_results'] ?? '';
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SkillsSelfEvaluationResultsDetailPanel(content: widget.content[section], params: {'skill_definition': skillDefinition})));
    }
  }

  void _onTapClearAllScores() {
    //TODO: call Polls BB API to clear all responses for survey type "bessi" after confirming
  }
}

