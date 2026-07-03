import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluation.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluationResultsDetailPanel.dart';
import 'package:illinois/ui/academics/courses/EssentialSkillsCoachWidgets.dart';
import 'package:illinois/ui/academics/courses/SkillsScoreChart.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class SkillsHistoryPanel extends StatefulWidget {

  const SkillsHistoryPanel();

  @override
  State<SkillsHistoryPanel> createState() => _SkillsHistoryPanelState();
}

class _SkillsHistoryPanelState extends State<SkillsHistoryPanel> {
  String? _selectedSkillType;

  final SkillsScoreChartController _chartController = SkillsScoreChartController();

  static const String _defaultComparisonResponseId = 'none';
  String _comparisonResponseId = _defaultComparisonResponseId;
  Map<String, SkillsSelfEvaluationContent> _resultsContentItems = {};
  List<SurveyResponse> _responses = [];
  SurveyResponse? _latestResponse;
  SurveyResponse? _comparedResponse;

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
      color: Styles().colors.background,
      child: SingleChildScrollView(
          child: Column(
            children: [
              _buildFilterDropDown(),
              SkillsScoreChart(controller: _chartController, ),
              _buildSkillsScoreData(),
              _buildSkillsCards()
            ],
          )
      ),
    );
  }

  Widget _buildSkillsScoreData(){
    return Padding(padding: const EdgeInsets.only(top: 20, left: 28, right: 28), child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Divider(color: Styles().colors.fillColorPrimary, thickness: 2),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(flex: 4, fit: FlexFit.tight, child: Text(Localization().getStringEx('panel.skills_self_evaluation.results.skills.title', 'SKILLS'), style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.results.table.header'),)),
          Flexible(flex: 3, fit: FlexFit.tight, child: Text(DateTimeUtils.localDateTimeToString(_latestResponse?.dateTaken, format: 'MM/dd/yy\nh:mma') ?? 'NONE', textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.results.table.header'),)),
          Flexible(flex: 3, fit: FlexFit.tight, child: DropdownButtonHideUnderline(child:
            DropdownButton<String>(
              icon: Styles().images.getImage('chevron-down', excludeFromSemantics: true),
              isExpanded: true,
              style: Styles().textStyles.getTextStyle('panel.essential_skills_coach.results.table.header'),
              items: _buildResponseDateDropDownItems(),
              value: _comparisonResponseId,
              onChanged: _onResponseDateDropDownChanged,
              dropdownColor: Styles().colors.surface,
            ),
          )),
        ],)),
      ],
    ));
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
      SurveyStats? lastStats = _latestResponse?.survey.stats;
      SurveyStats? stats = _comparedResponse?.survey.stats;
      if(_selectedSkillType == null){
        return ListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: List.generate(SkillsScoreChart.skillSections.length, (index) {
            String section = SkillsScoreChart.skillSections[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Card(
                color: Styles().colors.surface,
                child: InkWell(
                  onTap: (){
                    _showScoreDescription(section);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Flexible(flex: 5, fit: FlexFit.tight, child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            Localization().getStringEx("panel.essential_skills_coach.skills_history.$section.label", StringUtils.capitalize('${section}_skills', allWords: true, splitDelimiter: '_')),
                            style: Styles().textStyles.getTextStyle("widget.message.small.fat"),
                          ),
                        )),
                        Flexible(flex: 3, fit: FlexFit.tight, child: Text(
                            _determineSkillScore(lastStats?.scores[section], lastStats?.maximumScores[section]),
                            style: TextStyle(color: SkillsScoreChart.getSectionColor(section), fontSize: 32),
                            textAlign: TextAlign.center,
                        ),),
                        Flexible(flex: 3, fit: FlexFit.tight, child: Text(
                            _determineSkillScore(stats?.scores[section], stats?.maximumScores[section]),
                            style: TextStyle(color: Styles().colors.mediumGray, fontSize: 32),
                            textAlign: TextAlign.center,
                        ),),
                        Flexible(flex: 1, fit: FlexFit.tight, child: SizedBox(height: 16.0 , child: Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true))),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Card(
            color: Styles().colors.surface,
            child: InkWell(
              onTap: (){
                _showScoreDescription(_selectedSkillType!);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Flexible(flex: 5, fit: FlexFit.tight, child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        Localization().getStringEx("panel.essential_skills_coach.skills_history.$_selectedSkillType!.label", StringUtils.capitalize('${_selectedSkillType!}_skills', allWords: true, splitDelimiter: '_')),
                        style: Styles().textStyles.getTextStyle("widget.message.small.fat"),
                      ),
                    )),
                    Flexible(flex: 3, fit: FlexFit.tight, child: Text(
                        _determineSkillScore(lastStats?.scores[_selectedSkillType!], lastStats?.maximumScores[_selectedSkillType!]),
                        style: TextStyle(color: SkillsScoreChart.getSectionColor(_selectedSkillType!), fontSize: 36),
                        textAlign: TextAlign.center,
                    ),),
                    Flexible(flex: 3, fit: FlexFit.tight, child: Text(
                        _determineSkillScore(stats?.scores[_selectedSkillType!], stats?.maximumScores[_selectedSkillType!]),
                        style: TextStyle(color: Styles().colors.mediumGray, fontSize: 36),
                        textAlign: TextAlign.center,
                    ),),
                    Flexible(flex: 1, fit: FlexFit.tight, child: SizedBox(height: 16.0 , child: Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true))),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return Center(child: CircularProgressIndicator());
  }

  Widget _buildFilterDropDown(){
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: EssentialSkillsCoachDropdown(
        value: _selectedSkillType,
        items: _buildFilterDropdownItems(),
        onChanged: (String? selected) {
          setState(() {
            _selectedSkillType = selected;
          });
          _chartController.updateData(_responses, _selectedSkillType);
        }
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildFilterDropdownItems() {
    List<DropdownMenuItem<String>> dropDownItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(
          value: null,
          child: Text(Localization().getStringEx("panel.essential_skills_coach.skills_history.all.label", "All Essential Skills"), style: Styles().textStyles.getTextStyle("widget.detail.large"))
      )
    ];

    for (String section in SkillsScoreChart.skillSections) {
      dropDownItems.add(DropdownMenuItem(
          value: section,
          child: Text(
            Localization().getStringEx("panel.essential_skills_coach.skills_history.$section.label", StringUtils.capitalize('${section}_skills', allWords: true, splitDelimiter: '_')),
            style: Styles().textStyles.getTextStyle("widget.detail.large")
          )
      ));
    }
    return dropDownItems;
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
            }else{
              _latestResponse = _responses[0];
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

  String _determineSkillScore(num? score, num? maxScore){
    if(score != null && maxScore != null){
      return ((score/maxScore)*100).round().toString();
    }
    return '--';
  }

  void _onResponseDateDropDownChanged(String? value) {
    setState(() {
      _comparisonResponseId = value ?? _defaultComparisonResponseId;
      _comparedResponse = _responses.firstWhereOrNull((survey) => survey.id == value);
    });
  }

  void _showScoreDescription(String section) {
    String skillDefinition = _latestResponse?.survey.resultData is Map<String, dynamic> ? _latestResponse?.survey.resultData['${section}_results'] ?? '' :
    Localization().getStringEx('panel.skills_self_evaluation.results.empty.message', 'No results yet.');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SkillsSelfEvaluationResultsDetailPanel(content: _resultsContentItems[section], params: {'skill_definition': skillDefinition})));
  }

  void _loadContentItems() {
    SkillsSelfEvaluationWidget.loadContentItems(["bessi_results", "bessi_profile"]).then((content) {
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
