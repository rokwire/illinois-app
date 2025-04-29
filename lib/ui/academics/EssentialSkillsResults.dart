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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/CustomCourses.dart';
import 'package:illinois/ui/academics/EssentialSkillsLearning.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluation.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluationResultsDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';


class EssentialSkillsResults extends StatefulWidget {
  final SurveyResponse? latestResponse;
  final Function (String?)? onStartCourse;

  EssentialSkillsResults({this.latestResponse, this.onStartCourse});

  @override
  _EssentialSkillsResultsState createState() => _EssentialSkillsResultsState();
}

class _EssentialSkillsResultsState extends State<EssentialSkillsResults> {
  Map<String, SkillsSelfEvaluationContent> _resultsContentItems = {};
  List<SkillsSelfEvaluationProfile> _profileContentItems = [];
  List<SurveyResponse> _responses = [];
  SurveyResponse? _latestResponse;
  Course? _course;

  late String _contactEmailAddress;
  late GestureRecognizer _contactEmailGestureRecognizer;

  bool _latestCleared = false;
  bool _loading = false;
  String? _selectedRadioValue;

  @override
  void initState() {
    _latestResponse = widget.latestResponse;

    _contactEmailAddress = Localization().getStringEx('panel.skills_self_evaluation.results.contact.address', 'bwrobrts@illinois.edu');
    _contactEmailGestureRecognizer = TapGestureRecognizer()..onTap = () => _onContactEmailAddress();

    _loadResults();
    _loadContentItems();
    _loadCourse();
    super.initState();
  }

  @override
  void dispose() {
    _contactEmailGestureRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(
        title: Localization().getStringEx('panel.skills_self_evaluation.results.header.title', 'Skills Self-Evaluation & Career Explorer'),
        leading: RootHeaderBarLeading.Back,
      ),
      body: RefreshIndicator(
        onRefresh: _onPullToRefresh,
        child: Stack(
          children: [
            SingleChildScrollView(
            child: SectionSlantHeader(
              headerWidget: _buildHeader(),
              slantColor: Styles().colors.gradientColorPrimary,
              slantPainterHeadingHeight: 0,
              backgroundColor: Styles().colors.background,
              children: Connectivity().isOffline ? _buildOfflineMessage() : _buildContent(),
              childrenPadding: EdgeInsets.symmetric(horizontal: 16.0),
              allowOverlap: false,
              childrenAlignment: CrossAxisAlignment.start,
            ),
          ),
            Column(
              children: [
                Expanded(child: Container()),
                Padding(
                  padding: EdgeInsets.only(left: 64, right: 64, bottom: 8),
                  child: RoundedButton(
                    label: Localization().getStringEx("panel.essential_skills_coach.evaluation_results.button.continue.label", 'Continue'),
                    textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat.variant"),
                    backgroundColor: Styles().colors.surface,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => EssentialSkillsLearning(onStartCourse: widget.onStartCourse, selectedSkill: _selectedRadioValue,)));
                    },
                  ),
                ),
              ],
            ),
          ]
        ),
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }


  List<Widget> _buildOfflineMessage() {
    return [
      Padding(padding: EdgeInsets.all(28), child:
      Center(child:
      Text(
          Localization().getStringEx('panel.skills_self_evaluation.results.offline.error.msg', 'Results not available while offline.'),
          textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.title')
      )
      ),
      ),
    ];
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.section.title', 'Results'), style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.results.header'), textAlign: TextAlign.center,),
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.score.description', 'Skills Domain Score'), style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.header.description'), textAlign: TextAlign.center,),
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.score.scale', '(0-100)'), style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.header.description'), textAlign: TextAlign.center,),
        SizedBox(height: 28),
      ]),
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

  List<Widget> _buildContent() {
    Iterable<String> responseSections = _resultsContentItems['section_titles']?.params?.keys ?? [];
    //Map<String, num>? comparisonScores;
    //SkillsSelfEvaluationProfile? selectedProfile;
    List<Widget> workOnSections = [];
    List<Widget> proficientSections = [];
    List<Widget> unavailableSections = [];

    int proficientScore = 70;
    dynamic proficientScoreVal = _latestResponse?.survey.constants['proficient_score'];
    if (proficientScoreVal is int) {
      proficientScore = proficientScoreVal;
    }

    responseSections.forEach((section) {
      String title = _resultsContentItems['section_titles']?.params?[section].toString() ?? '';
      num? mostRecentScore = (_latestResponse?.survey.stats?.percentages[section] ?? 0) * 100;
      mostRecentScore = mostRecentScore.round();
      bool isProficient = mostRecentScore >= proficientScore;

      Module? sectionModule = _course?.searchByKey(moduleKey: "${section}_skills");
      bool isSelectable = sectionModule?.units?.isNotEmpty ?? false;

      Widget sectionWidget = Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Card(
              child: InkWell(
                  onTap: () => _showScoreDescription(section),
                  child: Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 12, left: (isSelectable ? 0 : 16)),
                      child: Row(
                        children: [
                          if (isSelectable)
                            Radio<String>(
                              activeColor: Styles().colors.fillColorPrimary,
                              value: section,
                              groupValue: _selectedRadioValue,
                              onChanged: (value) {
                                setState(() {
                                  _selectedRadioValue = value;
                                });
                              },
                            ),
                          Flexible(
                              flex: 5,
                              fit: FlexFit.tight,
                              child: Text(
                                title,
                                style: !isProficient ?
                                  Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.title')
                                    : Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.title')?.apply(color: Styles().colors.mediumGray),// Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.title')
                              )
                          ),
                          Flexible(
                              flex: 3,
                              fit: FlexFit.tight,
                              child: Text(
                                mostRecentScore.toString(),
                                style: !isProficient ?
                                  Styles().textStyles.getTextStyle('panel.skills_self_evaluation.results.score.current')
                                    : Styles().textStyles.getTextStyle('panel.skills_self_evaluation.results.score.past'),
                                textAlign: TextAlign.center,
                              )
                          ),
                          Flexible(
                              flex: 1,
                              fit: FlexFit.tight,
                              child: SizedBox(
                                  height: 16.0,
                                  child: Styles().images.getImage('chevron-right-bold',
                                      excludeFromSemantics: true, color: Styles().colors.mediumGray)
                              )
                          ),
                        ],
                      )
                  )
              )
          )
      );

      if (isProficient) {
        proficientSections.add(sectionWidget);
      } else if (isSelectable) {
        workOnSections.add(sectionWidget);
      } else {
        unavailableSections.add(sectionWidget);
      }
    });

    List<Widget> finalWidgets = [
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(Localization().getStringEx('panel.essential_skills_coach.evaluation_results.select_skill.message', 'Pick a skill to get started:'),
          style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.title.large')
        ),
      ),
    ];

    if (responseSections.isEmpty) {
      finalWidgets.add(Padding(
        padding: const EdgeInsets.only(top: 80, bottom: 32, left: 32, right: 32),
        child: Text(
          Localization().getStringEx(
              'panel.skills_self_evaluation.results.unavailable.message',
              'Results content is currently unavailable. Please try again later.'),
          style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.body'),
          textAlign: TextAlign.center,
        ),
      ));
      return finalWidgets;
    }

    if (workOnSections.isNotEmpty) {
      finalWidgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Improve:", style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.title')),
      ));
      finalWidgets.addAll(workOnSections);
    }

    if (proficientSections.isNotEmpty) {
      finalWidgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Proficient:", style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.title')),
      ));
      finalWidgets.addAll(proficientSections);
    }

    if (unavailableSections.isNotEmpty) {
      finalWidgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Unavailable:", style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.title')),
      ));
      finalWidgets.addAll(unavailableSections);
    }

    finalWidgets.add(
      Visibility(
          visible: _loading,
          child: Container(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorPrimary)),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 64),
          )
      ),
    );

    finalWidgets.add(Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Center(
        child: Text(
          Localization().getStringEx('panel.skills_self_evaluation.results.more_info.description', '*Tap score cards for more info'),
          style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.body.small'),
          textAlign: TextAlign.left,
        ),
      ),
    ));

    finalWidgets.add(Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 80),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: Localization().getStringEx('panel.skills_self_evaluation.results.contact1',
              'If you have any questions or concerns about the BESSI score feedback '
                  'you just received, please contact Dr. Brent Roberts ('),
              style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.body.small')),
          TextSpan(text: _contactEmailAddress,
              recognizer: _contactEmailGestureRecognizer,
              style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.link.small')),
          TextSpan(text: Localization().getStringEx('panel.skills_self_evaluation.results.contact2',
              ').  Dr. Roberts is a professor of psychology at the University of '
                  'Illinois at Urbana-Champaign and a co-creator of the BESSI inventory '
                  'and associated BESSI assessment tools.'),
              style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.content.body.small'))
        ]),
      ),
    ));

    return finalWidgets;
  }

  void _onContactEmailAddress() {
    String url = 'mailto:$_contactEmailAddress';
    Analytics().logSelect(target: url);
    Uri? uri = Uri.tryParse(url);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _loadResults() {
    setState(() {
      _loading = true;
    });
    Surveys().loadUserSurveyResponses(surveyTypes: ["bessi"], limit: 10).then((responses) {
      if (mounted) {
        if (CollectionUtils.isNotEmpty(responses)) {
          responses?.sort(((a, b) => b.dateTaken.compareTo(a.dateTaken)));
        }
        setState(() {
          _responses.clear();
          if ((responses != null) && responses.isNotEmpty) {
            if (widget.latestResponse == null) {
              _latestResponse = responses[0];
            }
            _responses = responses.sublist(_latestResponse?.id == responses[0].id ? 1 : 0);
          } else if (!_latestCleared) {
            _latestResponse = widget.latestResponse;
          }
          _loading = false;
        });
      }
    });
  }

  void _loadContentItems() {
    SkillsSelfEvaluation.loadContentItems(["bessi_results", "bessi_profile"]).then((content) {
      if (mounted && (content?.isNotEmpty == true)) {
        setState(() {
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
        });
      }
    });
  }

  Future<void> _loadCourse() async {
    if (StringUtils.isNotEmpty(Config().essentialSkillsCoachKey) && mounted) {
      setState(() {
        _loading = true;
      });
      Course? course = await CustomCourses().loadCourse(Config().essentialSkillsCoachKey!);
      setStateIfMounted(() {
        if (course != null) {
          _course = course;
        }
        _loading = false;
      });
    }
  }

  Future<void> _onPullToRefresh() async {
    _loadResults();
    _loadContentItems();
    _loadCourse();
  }

  void _showScoreDescription(String section) {
    String skillDefinition = _latestResponse?.survey.resultData is Map<String, dynamic> ? _latestResponse!.survey.resultData['${section}_results'] ?? '' :
    Localization().getStringEx('panel.skills_self_evaluation.results.empty.message', 'No results yet.');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SkillsSelfEvaluationResultsDetailPanel(content: _resultsContentItems[section], params: {'skill_definition': skillDefinition})));
  }
}

