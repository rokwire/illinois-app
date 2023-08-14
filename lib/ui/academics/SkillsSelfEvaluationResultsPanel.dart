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
import 'package:illinois/ui/academics/SkillsSelfEvaluationOccupationListPanel.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluation.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluationResultsDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SkillsSelfEvaluationResultsPanel extends StatefulWidget {
  final SurveyResponse? latestResponse;

  SkillsSelfEvaluationResultsPanel({this.latestResponse});

  @override
  _SkillsSelfEvaluationResultsPanelState createState() => _SkillsSelfEvaluationResultsPanelState();
}

class _SkillsSelfEvaluationResultsPanelState extends State<SkillsSelfEvaluationResultsPanel> {
  static const String _defaultComparisonResponseId = 'none';

  Map<String, SkillsSelfEvaluationContent> _resultsContentItems = {};
  List<SkillsSelfEvaluationProfile> _profileContentItems = [];
  List<SurveyResponse> _responses = [];
  SurveyResponse? _latestResponse;
  String _comparisonResponseId = _defaultComparisonResponseId;

  bool _latestCleared = false;
  bool _loading = false;

  @override
  void initState() {
    _latestResponse = widget.latestResponse;

    _loadResults();
    _loadContentItems();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.skills_self_evaluation.results.header.title', 'Skills Self-Evaluation'), leading: RootHeaderBarLeading.Back,),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child: SingleChildScrollView(
        child: SectionSlantHeader(
          headerWidget: _buildHeader(),
          slantColor: Styles().colors?.gradientColorPrimary,
          slantPainterHeadingHeight: 0,
          backgroundColor: Styles().colors?.background,
          children: Connectivity().isOffline ? _buildOfflineMessage() : _buildContent(),
          childrenPadding: EdgeInsets.zero,
          allowOverlap: !Connectivity().isOffline,
        ),
      )),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  List<Widget> _buildOfflineMessage() {
    return [
      Padding(padding: EdgeInsets.all(28), child:
        Center(child:
          Text(
            Localization().getStringEx('panel.skills_self_evaluation.results.offline.error.msg', 'Results not available while offline.'),
            textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title')
          )
        ),
      ),
    ];
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.section.title', 'Results'), style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.header'), textAlign: TextAlign.center,),
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.score.description', 'Skills Domain Score'), style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.header.description'), textAlign: TextAlign.center,),
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.score.scale', '(0-100)'), style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.header.description'), textAlign: TextAlign.center,),
        // TODO: Need to change the look and size of the button
        Align(alignment: Alignment.center, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
          child: RoundedButton(
            label: Localization().getStringEx("panel.skills_self_evaluation.go_to_results.button.label", 'Career Explorer'),
            textColor: Styles().colors?.fillColorPrimaryVariant,
            backgroundColor: Styles().colors?.surface,
            onTap: () {
              Navigator.push(context, CupertinoPageRoute(builder: (context) => SkillSelfEvaluationOccupationListPanel(percentages: _latestResponse?.survey.stats?.percentages ?? {})));
            }
          ),
        )),
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
    return Padding(padding: const EdgeInsets.only(top: 20, left: 28, right: 28), child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Divider(color: Styles().colors?.surface, thickness: 2),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(flex: 4, fit: FlexFit.tight, child: Text(Localization().getStringEx('panel.skills_self_evaluation.results.skills.title', 'SKILLS'), style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.table.header'),)),
          Flexible(flex: 3, fit: FlexFit.tight, child: Text(_latestResponse != null ? DateTimeUtils.localDateTimeToString(_latestResponse!.dateTaken, format: 'MM/dd/yy h:mma') ?? 'NONE' : 'NONE', textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.table.header'),)),
          Flexible(flex: 3, fit: FlexFit.tight, child: DropdownButtonHideUnderline(child:
            DropdownButton<String>(
              icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
              isExpanded: true,
              style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.table.header'),
              items: _buildResponseDateDropDownItems(),
              value: _comparisonResponseId,
              onChanged: _onResponseDateDropDownChanged,
              dropdownColor: Styles().colors?.textBackground,
            ),
          )),
        ],)),
      ],
    ));
  }

  List<Widget> _buildContent() {
    Iterable<String> responseSections = _resultsContentItems['section_titles']?.params?.keys ?? [];
    Map<String, num>? comparisonScores;
    SkillsSelfEvaluationProfile? selectedProfile;
    if (_comparisonResponseId != _defaultComparisonResponseId) {
      try {
        selectedProfile = _profileContentItems.firstWhere((element) => element.key == _comparisonResponseId);
        comparisonScores = selectedProfile.scores;
      } catch (e) {
        try {
          comparisonScores = _responses.firstWhere((element) => element.id == _comparisonResponseId).survey.stats?.percentages;
        } catch (e) {
          debugPrint(e.toString());
        }
      }
    }

    return [
      Stack(children: [
        responseSections.length > 0 ? ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8),
          itemCount: responseSections.length,
          itemBuilder: (BuildContext context, int index) {
            String section = responseSections.elementAt(index);
            String title = _resultsContentItems['section_titles']?.params?[section].toString() ?? '';
            num? mostRecentScore = _latestResponse?.survey.stats?.percentages[section];
            if (mostRecentScore != null) {
              mostRecentScore = (mostRecentScore*100).round();
            }
            num? comparisonScore = comparisonScores?[section];
            if (comparisonScore != null) {
              comparisonScore = (comparisonScore*100).round();
            }

            return Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Card(
                child: InkWell(
                  onTap: () => _showScoreDescription(section),
                  child: Padding(padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16), child: Row(children: [
                    Flexible(flex: 5, fit: FlexFit.tight, child: Text(title, style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'))),
                    Flexible(flex: 3, fit: FlexFit.tight, child: Text(mostRecentScore?.toString() ?? "--", style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.score.current'), textAlign: TextAlign.center,)),
                    Flexible(flex: 3, fit: FlexFit.tight, child: Text(comparisonScore?.toString() ?? "--", style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.score.past'), textAlign: TextAlign.center)),
                    Flexible(flex: 1, fit: FlexFit.tight, child: SizedBox(height: 16.0 , child: Styles().images?.getImage('chevron-right-bold', excludeFromSemantics: true))),
                  ],)),
                )
              )
            );
        }) : Padding(padding: const EdgeInsets.only(top: 80, bottom: 32, left: 32, right: 32), child: Text(
          Localization().getStringEx('panel.skills_self_evaluation.results.unavailable.message', 'Results content is currently unavailable. Please try again later.'),
          style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.body'),
          textAlign: TextAlign.center,
        )),
        Visibility(
          visible: _loading,
          child: Container(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors?.fillColorPrimary)),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 64),
          )
        ),
      ],),
      Visibility(
        visible: responseSections.length > 0,
        child: Padding(padding: const EdgeInsets.only(top: 4), child: GestureDetector(onTap: _onTapClearAllScores, child:
          Text(Localization().getStringEx('panel.skills_self_evaluation.results.more_info.description', '*Tap score cards for more info'), style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.body.small'), textAlign: TextAlign.left,
        ),)),
      ),
      Visibility(
        visible: selectedProfile?.params['name'] is String && selectedProfile?.params['definition'] is String,
        child: Padding(padding: const EdgeInsets.only(top: 32, left: 32, right: 32), child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: selectedProfile?.params['name'] ?? '',
                style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'),
              ),
              TextSpan(
                text: ' = ${selectedProfile?.params['definition'] ?? ''}',
                style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.body'),
              ),
            ],
          ),
        ),)
      ),
      Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: GestureDetector(onTap: _onTapClearAllScores, child:
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.clear_scores.label', 'Clear All Scores'), style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.link.fat'),
      ),)),
    ];
  }

  List<DropdownMenuItem<String>> _buildResponseDateDropDownItems() {
    List<DropdownMenuItem<String>> items = [
      DropdownMenuItem<String>(
        value: _defaultComparisonResponseId,
        child: Align(alignment: Alignment.center, child: Text('NONE', style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.table.header'), textAlign: TextAlign.center,)),
      ),
    ];

    List<String> profileKeys = [];
    for (SkillsSelfEvaluationProfile profile in _profileContentItems) {
      if (profile.params['abbreviation'] is String && !profileKeys.contains(profile.key)) {
        items.add(DropdownMenuItem<String>(
          value: profile.key,
          child: Align(alignment: Alignment.center, child: Text(profile.params['abbreviation'], style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.table.header'), textAlign: TextAlign.center,)),
        ));
        profileKeys.add(profile.key);
      }
    }
    
    for (SurveyResponse response in _responses) {
      String dateString = DateTimeUtils.localDateTimeToString(response.dateTaken, format: 'MM/dd/yy h:mma') ?? '';
      items.add(DropdownMenuItem<String>(
        value: response.id,
        child: Align(alignment: Alignment.center, child: Text(dateString, style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.table.header'), textAlign: TextAlign.center,)),
      ));
    }
    return items;
  }

  void _loadResults() {
    _setLoading(true);
    Surveys().loadUserSurveyResponses(surveyTypes: ["bessi"], limit: 10).then((responses) {
      _responses.clear();
      if (CollectionUtils.isNotEmpty(responses)) {
        responses!.sort(((a, b) => b.dateTaken.compareTo(a.dateTaken)));

        if (widget.latestResponse == null) {
          _latestResponse = responses[0];
        }
        _responses = responses.sublist(_latestResponse?.id == responses[0].id ? 1 : 0);
      } else if (!_latestCleared) {
        _latestResponse = widget.latestResponse;
      }

      _setLoading(false);
    });
  }

  void _loadContentItems() {
    SkillsSelfEvaluation.loadContentItems(["bessi_results", "bessi_profile"]).then((content) {
      if (content?.isNotEmpty ?? false) {
        _resultsContentItems.clear();
        _profileContentItems.clear();
        for (MapEntry<String, Map<String, dynamic>> item in content?.entries ?? []) {
          switch (item.value['category']) {
            case 'bessi_results': 
              _resultsContentItems[item.key] = SkillsSelfEvaluationContent.fromJson(item.value);
              break;
            case 'bessi_profile':
              _profileContentItems.add(SkillsSelfEvaluationProfile.fromJson(item.value));
              break;
          }
        }

        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void _setLoading(bool value) {
    if (mounted) {
      setState(() {
        _loading = value;
      });
    }
  }

  Future<void> _onPullToRefresh() async {
    _loadResults();
    _loadContentItems();
  }

  void _onResponseDateDropDownChanged(String? value) {
    setState(() {
      _comparisonResponseId = value ?? _defaultComparisonResponseId;
    });
  }

  void _showScoreDescription(String section) {
    String skillDefinition = _latestResponse?.survey.resultData is Map<String, dynamic> ? _latestResponse!.survey.resultData['${section}_results'] ?? '' : 
      Localization().getStringEx('panel.skills_self_evaluation.results.empty.message', 'No results yet.');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SkillsSelfEvaluationResultsDetailPanel(content: _resultsContentItems[section], params: {'skill_definition': skillDefinition})));
  }

  void _onTapClearAllScores() {
    List<Widget> buttons = [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: RoundedButton(
        label: Localization().getStringEx('dialog.no.title', 'No'),
        borderColor: Styles().colors?.fillColorPrimaryVariant,
        backgroundColor: Styles().colors?.surface,
        textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
        onTap: _onTapDismissDeleteScores,
      )),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: RoundedButton(
        label: Localization().getStringEx('dialog.yes.title', 'Yes'),
        borderColor: Styles().colors?.fillColorSecondary,
        backgroundColor: Styles().colors?.surface,
        textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
        onTap: _onTapConfirmDeleteScores,
      )),
    ];

    ActionsMessage.show(
      context: context,
      titleBarColor: Styles().colors?.surface,
      message: Localization().getStringEx('panel.skills_self_evaluation.results.delete_scores.message', 'Are you sure you want to delete all of your scores?'),
      messageTextStyle: Styles().textStyles?.getTextStyle('widget.description.medium'),
      messagePadding: const EdgeInsets.only(left: 32, right: 32, top: 8, bottom: 32),
      messageTextAlign: TextAlign.center,
      buttons: buttons,
      buttonsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
      closeButtonIcon: Styles().images?.getImage('close', excludeFromSemantics: true),
    );
  }

  void _onTapDismissDeleteScores() {
    Navigator.of(context).pop();
  }

  void _onTapConfirmDeleteScores() {
    Navigator.of(context).pop();
    Surveys().deleteSurveyResponses(surveyTypes: ["bessi"]).then((_) {
      _latestCleared = true;
      _latestResponse = null;
      _comparisonResponseId = _defaultComparisonResponseId;
      _loadResults();
    });
  }
}

