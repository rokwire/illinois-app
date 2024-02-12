import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import '../SkillsSelfEvaluation.dart';
import '../SkillsSelfEvaluationResultsDetailPanel.dart';
import 'SkillsScoreChart.dart';

class SkillsHistoryPanel extends StatefulWidget {

  const SkillsHistoryPanel();

  @override
  State<SkillsHistoryPanel> createState() => _SkillsHistoryPanelState();
}

class _SkillsHistoryPanelState extends State<SkillsHistoryPanel> implements NotificationsListener {
  String? _selectedSkillType = "All Essential Skills";
  final List<String> _skillTypes = ["All Essential Skills", "Cooperation Skills",
    "Emotional Resilience Skills", "Innovation Skills", "Self-Management Skills", "Social Engagement Skills"];
  final SkillsScoreChartController _chartController = SkillsScoreChartController();
  static const String _defaultComparisonResponseId = 'none';
  String _comparisonResponseId = _defaultComparisonResponseId;
  Map<String, SkillsSelfEvaluationContent> _resultsContentItems = {};
  List<SurveyResponse> _responses = [];
  late SurveyResponse _latestResponse;
  late SurveyResponse _comparedResponse;
  bool _loading = false;

  @override
  void initState() {

    _loadResults();
    _loadContentItems();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Styles().colors.lightGray,
      child: SingleChildScrollView(
          child: Column(
            children: [
              _buildFilterDropDown(),
              _buildSkillsScoreChart(),
              _buildSkillsScoreData(),
              _buildSkillsCards()
            ],
          )
      ),
    );
  }

  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }

  Widget _buildSkillsScoreData(){
    if(!_loading){
      return Padding(padding: const EdgeInsets.only(top: 20, left: 28, right: 28), child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(color: Styles().colors.fillColorPrimary, thickness: 2),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(flex: 4, fit: FlexFit.tight, child: Text(Localization().getStringEx('panel.skills_self_evaluation.results.skills.title', 'SKILLS'), style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.results.table.header'),)),
            Flexible(flex: 3, fit: FlexFit.tight, child: Text(DateTimeUtils.localDateTimeToString(_latestResponse.dateTaken, format: 'MM/dd/yy\nh:mma') ?? 'NONE', textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.results.table.header'),)),
            Flexible(flex: 3, fit: FlexFit.tight, child: DropdownButtonHideUnderline(child:
            DropdownButton<String>(
              icon: Styles().images.getImage('chevron-down', excludeFromSemantics: true),
              isExpanded: true,
              style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.results.table.header'),
              items: _buildResponseDateDropDownItems(),
              value: _comparisonResponseId,
              onChanged: _onResponseDateDropDownChanged,
              dropdownColor: Styles().colors.white,
            ),
            )),
          ],)),
        ],
      ));
    }else{
      return Container();
    }
  }

  List<DropdownMenuItem<String>> _buildResponseDateDropDownItems() {
    List<DropdownMenuItem<String>> items = [
      DropdownMenuItem<String>(
        value: _defaultComparisonResponseId,
        child: Align(alignment: Alignment.center, child: Text('NONE', style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.results.table.header'), textAlign: TextAlign.center,)),
      ),
    ];

    for (SurveyResponse response in _responses) {
      String dateString = DateTimeUtils.localDateTimeToString(response.dateTaken, format: 'MM/dd/yy\nh:mma') ?? '';
      items.add(DropdownMenuItem<String>(
        value: response.id,
        child: Align(alignment: Alignment.center, child: Text(dateString, style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.results.table.header'), textAlign: TextAlign.center,)),
      ));
    }
    return items;
  }

  Widget _buildSkillsCards(){
    if(!_loading){
      SurveyStats? lastStats = _latestResponse.survey.stats;
      SurveyStats? stats = _comparedResponse.survey.stats;
      if(_selectedSkillType == "All Essential Skills"){
        return ListView(
          padding: const EdgeInsets.all(8),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            Container(
              height: 80,
              child: Card(
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(width: 170, child: Text("Cooperation Skills", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_determineSkillScore(lastStats?.scores["cooperation"], lastStats?.maximumScores["cooperation"]).toString(), style: TextStyle(color: Styles().colors.getColor('essentialSkillsCoachRed'), fontSize: 32)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_determineSkillScore(stats?.scores["cooperation"], stats?.maximumScores["cooperation"]).toString(), style: TextStyle(color: Styles().colors.mediumGray, fontSize: 32)),
                    ),
                    IconButton(
                      onPressed: (){
                        _showScoreDescription("cooperation");
                      },
                      icon: Styles().images.getImage('chevron-right-bold') ?? Container()
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 80,
              child: Card(
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(width: 170, child: Text("Emotional\nResilience Skills", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_determineSkillScore(lastStats?.scores["emotional_resilience"], lastStats?.maximumScores["emotional_resilience"]).toString(), style: TextStyle(color: Styles().colors.getColor('essentialSkillsCoachOrange'), fontSize: 32)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_determineSkillScore(stats?.scores["emotional_resilience"], stats?.maximumScores["emotional_resilience"]).toString(), style: TextStyle(color: Styles().colors.mediumGray, fontSize: 32)),
                    ),
                    IconButton(
                        onPressed: (){
                          _showScoreDescription("emotional_resilience");
                        },
                        icon: Styles().images.getImage('chevron-right-bold') ?? Container()
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 80,
              child: Card(
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(width:170, child: Text("Innovation Skills", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_determineSkillScore(lastStats?.scores["innovation"], lastStats?.maximumScores["innovation"]).toString(), style: TextStyle(color: Styles().colors.getColor('essentialSkillsCoachGreen'), fontSize: 32)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_determineSkillScore(stats?.scores["innovation"], stats?.maximumScores["innovation"]).toString(), style: TextStyle(color: Styles().colors.mediumGray, fontSize: 32)),
                    ),
                    IconButton(
                        onPressed: (){
                          _showScoreDescription("innovation");
                        },
                        icon: Styles().images.getImage('chevron-right-bold') ?? Container()
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 80,
              child: Card(
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(width: 170, child: Text("Self-Management\nSkills", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_determineSkillScore(lastStats?.scores["self_management"], lastStats?.maximumScores["self_management"]).toString(), style: TextStyle(color: Styles().colors.getColor('essentialSkillsCoachBlue'), fontSize: 32)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_determineSkillScore(stats?.scores["self_management"], stats?.maximumScores["self_management"]).toString(), style: TextStyle(color: Styles().colors.mediumGray, fontSize: 32)),
                    ),
                    IconButton(
                        onPressed: (){
                          _showScoreDescription("self_management");
                        },
                        icon: Styles().images.getImage('chevron-right-bold') ?? Container()
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 80,
              child: Card(
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(width: 170, child: Text("Social Engagement\nSkills", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_determineSkillScore(lastStats?.scores["social_engagement"], lastStats?.maximumScores["social_engagement"]).toString(), style: TextStyle(color: Styles().colors.getColor('essentialSkillsCoachPurple'), fontSize: 32)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_determineSkillScore(stats?.scores["social_engagement"], stats?.maximumScores["social_engagement"]).toString(), style: TextStyle(color: Styles().colors.mediumGray, fontSize: 32)),
                    ),
                    IconButton(
                        onPressed: (){
                          _showScoreDescription("social_engagement");
                        },
                        icon: Styles().images.getImage('chevron-right-bold') ?? Container()
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }else{
        switch(_selectedSkillType){
          case "Cooperation Skills":
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 80,
                child: Card(
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(width: 170, child: Text("Cooperation Skills", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),)),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_determineSkillScore(lastStats?.scores["cooperation"], lastStats?.maximumScores["cooperation"]).toString(), style: TextStyle(color: Styles().colors.getColor('essentialSkillsCoachRed'), fontSize: 32)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_determineSkillScore(stats?.scores["cooperation"], stats?.maximumScores["cooperation"]).toString(), style: TextStyle(color: Styles().colors.mediumGray, fontSize: 32)),
                      ),
                      IconButton(
                          onPressed: (){
                            _showScoreDescription("cooperation");
                          },
                          icon: Styles().images.getImage('chevron-right-bold') ?? Container()
                      ),
                    ],
                  ),
                ),
              ),
            );
          case "Emotional Resilience Skills":
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 80,
                child: Card(
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(width: 170, child: Text("Emotional\nResilience Skills", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_determineSkillScore(lastStats?.scores["emotional_resilience"], lastStats?.maximumScores["emotional_resilience"]).toString(), style: TextStyle(color: Styles().colors.getColor('essentialSkillsCoachOrange'), fontSize: 32)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_determineSkillScore(stats?.scores["emotional_resilience"], stats?.maximumScores["emotional_resilience"]).toString(), style: TextStyle(color: Styles().colors.mediumGray, fontSize: 32)),
                      ),
                      IconButton(
                          onPressed: (){
                            _showScoreDescription("emotional_resilience");
                          },
                          icon: Styles().images.getImage('chevron-right-bold') ?? Container()
                      )
                    ],
                  ),
                ),
              ),
            );
          case "Innovation Skills":
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 80,
                child: Card(
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(width:170, child: Text("Innovation Skills", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_determineSkillScore(lastStats?.scores["innovation"], lastStats?.maximumScores["innovation"]).toString(), style: TextStyle(color: Styles().colors.getColor('essentialSkillsCoachGreen'), fontSize: 32)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_determineSkillScore(stats?.scores["innovation"], stats?.maximumScores["innovation"]).toString(), style: TextStyle(color: Styles().colors.mediumGray, fontSize: 32)),
                      ),
                      IconButton(
                          onPressed: (){
                            _showScoreDescription("innovation");
                          },
                          icon: Styles().images.getImage('chevron-right-bold') ?? Container()
                      )
                    ],
                  ),
                ),
              ),
            );
          case "Self-Management Skills":
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 80,
                child: Card(
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(width: 170, child: Text("Self-Management\nSkills", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_determineSkillScore(lastStats?.scores["self_management"], lastStats?.maximumScores["self_management"]).toString(), style: TextStyle(color: Styles().colors.getColor('essentialSkillsCoachBlue'), fontSize: 32)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_determineSkillScore(stats?.scores["self_management"], stats?.maximumScores["self_management"]).toString(), style: TextStyle(color: Styles().colors.mediumGray, fontSize: 32)),
                      ),
                      IconButton(
                          onPressed: (){
                            _showScoreDescription("self_management");
                          },
                          icon: Styles().images.getImage('chevron-right-bold') ?? Container()
                      )
                    ],
                  ),
                ),
              ),
            );
          case "Social Engagement Skills":
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 80,
                child: Card(
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(width: 170, child: Text("Social Engagement\nSkills", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_determineSkillScore(lastStats?.scores["social_engagement"], lastStats?.maximumScores["social_engagement"]).toString(), style: TextStyle(color: Styles().colors.getColor('essentialSkillsCoachPurple'), fontSize: 32)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_determineSkillScore(stats?.scores["social_engagement"], stats?.maximumScores["social_engagement"]).toString(), style: TextStyle(color: Styles().colors.mediumGray, fontSize: 32)),
                      ),
                      IconButton(
                          onPressed: (){
                            _showScoreDescription("social_engagement");
                          },
                          icon: Styles().images.getImage('chevron-right-bold') ?? Container()
                      )
                    ],
                  ),
                ),
              ),
            );
          default:
            return Container();
        }
      }
    }else{
      return Container();
    }

  }

  Widget _buildSkillsScoreChart() {
    return SkillsScoreChart(controller: _chartController, );
  }

  Widget _buildFilterDropDown(){
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton(
                  alignment: AlignmentDirectional.center,
                  value: _selectedSkillType,
                  iconDisabledColor: Colors.white,
                  iconEnabledColor: Styles().colors.fillColorSecondary,
                  focusColor: Styles().colors.fillColorSecondary,
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  underline: Divider(color: Styles().colors.fillColorSecondary, thickness: 2,),
                  items: DropdownBuilder.getItems(_skillTypes, style: Styles().textStyles.getTextStyle("widget.title.large")),
                  onChanged: (String? selected) {
                    setState(() {
                      _selectedSkillType = selected;
                    });
                    _chartController.updateData(_responses, _selectedSkillType);
                  }
              ),
            ),
          )
      ),
    );
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
          if ((responses != null) && responses.isNotEmpty) {
            _responses = List.from(responses);

            if(responses.length > 1){
              _latestResponse = _responses[0];
              _comparedResponse = _responses[1];
              _comparisonResponseId = _responses[1].id;
            }else{
              _latestResponse = _responses[0];
              _comparedResponse = _responses[0];
              _comparisonResponseId = _responses[0].id;
            }
          }
          else {
            _responses.clear();
          }
          _chartController.updateData(responses, _selectedSkillType);
          _loading = false;
        });
      }
    });
  }

  int _determineSkillScore(num? score, num? maxScore){
    if(score != null && maxScore != null){
      return ((score/maxScore)*100).round();
    }else{
      return 0;
    }
  }

  void _onResponseDateDropDownChanged(String? value) {
    setState(() {
      _comparisonResponseId = value ?? _defaultComparisonResponseId;
      if(_comparisonResponseId != _defaultComparisonResponseId){
        _comparedResponse = _responses.firstWhere((survey) =>
            survey.id.contains(value ?? ""));
      }
    });
  }

  void _showScoreDescription(String section) {
    String skillDefinition = _latestResponse.survey.resultData is Map<String, dynamic> ? _latestResponse.survey.resultData['${section}_results'] ?? '' :
    Localization().getStringEx('panel.skills_self_evaluation.results.empty.message', 'No results yet.');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SkillsSelfEvaluationResultsDetailPanel(content: _resultsContentItems[section], params: {'skill_definition': skillDefinition})));
  }

  void _loadContentItems() {
    SkillsSelfEvaluation.loadContentItems(["bessi_results", "bessi_profile"]).then((content) {
      if ((content != null) && content.isNotEmpty && mounted) {
        setState(() {
          _resultsContentItems.clear();
          for (MapEntry<String, Map<String, dynamic>> item in content.entries) {
            switch (item.value['category']) {
              case 'bessi_results':
                _resultsContentItems[item.key] = SkillsSelfEvaluationContent.fromJson(item.value);
                break;
            }
          }
        });
      }
    });
  }

}

class DropdownBuilder {
  static List<DropdownMenuItem<T>> getItems<T>(List<T> options, {String? nullOption, TextStyle? style}) {
    List<DropdownMenuItem<T>> dropDownItems = <DropdownMenuItem<T>>[];
    if (nullOption != null) {
      dropDownItems.add(DropdownMenuItem(value: null, child: Text(nullOption, style: style ?? Styles().textStyles.getTextStyle("widget.detail.regular"))));
    }
    for (T option in options) {
      dropDownItems.add(DropdownMenuItem(value: option, child: Text(option.toString(), style: style ?? Styles().textStyles.getTextStyle("widget.detail.regular"))));
    }
    return dropDownItems;
  }
}