
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SkillsScoreChartController {
  void Function(List<SurveyResponse>? responses, String? selectedSkill) updateData = (blocks, skill) => {};
  SkillsScoreChartController();
}

class ScoreBarData {
  String title;
  int score;
  int count;
  List<ScoreBarSegment> scoreBarSegments;
  DateTimeRange? dateRange;

  ScoreBarData({required this.title, required this.score, this.count = 0, this.dateRange, required this.scoreBarSegments});
}

class ScoreBarSegment{
  String skillType;
  Color? color;
  int score;

  ScoreBarSegment({required this.skillType, required this.color, required this.score });
}

class SkillsScoreChart extends StatefulWidget {
  final SkillsScoreChartController controller;
  final int maxBars;
  SkillsScoreChart({super.key, required this.controller, this.maxBars = 10});

  static Color? getSectionColor(String section) {
    switch(section){
      case "cooperation":
        return Styles().colors.getColor('essentialSkillsCoachRed');
      case "emotional_resilience":
        return Styles().colors.getColor('essentialSkillsCoachOrange');
      case "innovation":
        return Styles().colors.getColor('essentialSkillsCoachGreen');
      case "self_management":
        return Styles().colors.getColor('essentialSkillsCoachBlue');
      case "social_engagement":
        return Styles().colors.getColor('essentialSkillsCoachPurple');
      default:
        return null;
    }
  }

  static const List<String> skillSections = ['cooperation', 'emotional_resilience', 'innovation', 'self_management', 'social_engagement'];

  @override
  State<StatefulWidget> createState() => SkillsScoreChartState();
}

class SkillsScoreChartState extends State<SkillsScoreChart> {
  static const double shadowOpacity = 0.2;
  static const int minMaxScore = 500;
  String? _selectedSkill;

  List<ScoreBarData> _chartItems = [];

  double _barWidth = 30;
  double _barSpacing = 24;

  int _maxScore = 500;

  int touchedIndex = -1;
  int touchedRodIndex = -1;

  @override
  void initState() {
    widget.controller.updateData = _updateData;
    super.initState();
  }

  void _updateData(List<SurveyResponse>? responses, String? selectedSkill) {
    if (mounted) {
      setState(() {
        _selectedSkill = selectedSkill;
        _processSurveyData(responses, selectedSkill);
      });
    }
  }

  void _processSurveyData(List<SurveyResponse>? responses, String? selectedSkill) {
    _chartItems = [];
    _maxScore = minMaxScore;
    switch(selectedSkill) {
      case null:
        _maxScore = 500;
        _processAllSkills(responses);
        break;
      default:
        _maxScore = 100;
        _processOneSkill(responses, selectedSkill!);
        break;
    }

    if (_chartItems.length > 8) {
      _barWidth = 24;
    }

    if (_chartItems.length == 10) {
      _barSpacing = 12;
    } else if (_chartItems.length >= 8) {
      _barSpacing = 16;
    }
  }
  
  void _processOneSkill(List<SurveyResponse>? responses, String selectedSkill){
    for (SurveyResponse survey in responses ?? []) {
      SurveyStats? stats = survey.survey.stats;
      int totalScore = 0;
      List<ScoreBarSegment> scoreBarSegments = [];
      if(stats != null){
        int score = _determineSkillScore(stats.scores[selectedSkill], stats.maximumScores[selectedSkill]);
        totalScore += score;
        scoreBarSegments.add(ScoreBarSegment(skillType: selectedSkill, color: SkillsScoreChart.getSectionColor(selectedSkill), score: score));
        _chartItems.add(ScoreBarData(title: DateTimeUtils.localDateTimeToString(survey.dateTaken, format: 'MM/dd/yy\nh:mma') ?? '', scoreBarSegments: scoreBarSegments, score: totalScore));
      }
    }
  }

  void _processAllSkills(List<SurveyResponse>? responses) {
    for (SurveyResponse survey in responses ?? []) {
      SurveyStats? stats = survey.survey.stats;
      if(stats != null){
        List<ScoreBarSegment> scoreBarSegments = [];
        int totalScore = 0;
        stats.scores.forEach((key, value) {
          if (SkillsScoreChart.skillSections.contains(key)) {
            int score = _determineSkillScore(value, stats.maximumScores[key]);
            totalScore +=score;
            scoreBarSegments.add(ScoreBarSegment(skillType: key, color: SkillsScoreChart.getSectionColor(key), score: score));
          }
        });

        _chartItems.add(ScoreBarData(title:DateTimeUtils.localDateTimeToString(survey.dateTaken, format: 'MM/dd/yy\nh:mma') ?? '', scoreBarSegments: scoreBarSegments, score: totalScore));
      }
    }
  }

  int _determineSkillScore(num? score, num? maxScore){
    if(score != null && maxScore != null){
      return ((score/maxScore)*100).round();
    }else{
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(
            height: 220,
            width: MediaQuery.of(context).size.width - 32,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.start,
                maxY: _maxScore.toDouble() + 1,
                minY: -1,
                groupsSpace: _barSpacing,
                barTouchData: BarTouchData(
                    allowTouchBarBackDraw: true,
                    handleBuiltInTouches: true,
                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        setState(() {
                          touchedIndex = -1;
                          touchedRodIndex = -1;
                        });
                        return;
                      }
                      setState(() {
                        touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                        touchedRodIndex = barTouchResponse.spot!.touchedRodDataIndex;
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: EdgeInsets.all(4),
                      //tooltipBgColor: Styles().colors.background,
                      tooltipBorder: BorderSide(color: Styles().colors.dividerLine, width: 1.0),
                      getTooltipItem: getTooltipItem,
                      getTooltipColor: (_) => Styles().colors.background,
                      // fitInsideVertically: true,
                    )
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: bottomTitles,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: leftTitles,
                      interval: _maxScore / 5,
                      reservedSize: 28,
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  checkToShowVerticalLine: (value) => value % 100 == 0,
                  getDrawingVerticalLine: (value) {
                    if (value == 0) {
                      return FlLine(
                        color: Styles().colors.surface.withValues(alpha: 0.1),
                        strokeWidth: 3,
                      );
                    }
                    return FlLine(
                      color: Styles().colors.surface.withValues(alpha: 0.05),
                      strokeWidth: 0.8,
                    );
                  },
                  horizontalInterval: _maxScore / 5,
                  getDrawingHorizontalLine: (value) => FlLine(strokeWidth: 2),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: _chartItems.mapIndexed((i, e) => generateGroup(i, e)).toList(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            alignment: WrapAlignment.center,
            children: List.generate(SkillsScoreChart.skillSections.length, (index) {
              String section = SkillsScoreChart.skillSections[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Opacity(
                  opacity: (_selectedSkill != section && _selectedSkill != null) ? .3 : 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: SkillsScoreChart.getSectionColor(section),
                                borderRadius: BorderRadius.circular(4)
                            )
                        ),
                      ),
                      Text(
                        Localization().getStringEx('widget.essential_skills_coach.history.score_chart.$section.label', StringUtils.capitalize('${section}_skills', allWords: true, splitDelimiter: '_')),
                        style: Styles().textStyles.getTextStyle("widget.toggle_button.title.tiny.thin.enabled"), textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            })
          ),
        )
      ],
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    String text = bottomTitleStrings(value.toInt());
    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: _chartItems.length >= 8 ? 8 : 10)),
    );
  }

  String bottomTitleStrings(int i) {
    return _chartItems[i].title;
  }

  Widget leftTitles(double value, TitleMeta meta) {
    if (value >= 0 && value <= _maxScore) {
      String text = value.toInt().toString();;
      return SideTitleWidget(
        meta: meta,
        child: Text(
          text,
          style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 10),
          textAlign: TextAlign.left,
        ),
      );
    }
    return SizedBox(height: 0);
  }
  
  BarChartGroupData generateGroup(int x, ScoreBarData data) {
    final isTouched = touchedIndex == x;
    List<BarChartRodData> barSegments = [];

    double fromY = 0;
    for(ScoreBarSegment scoreBar in data.scoreBarSegments){
      barSegments.add(
          BarChartRodData(
            fromY:fromY,
            toY: scoreBar.score.toDouble() + fromY,
            color: scoreBar.color ?? Styles().colors.surface,
            width: _barWidth,
            borderSide: BorderSide(
              color: scoreBar.color ?? Styles().colors.surface,
              width: isTouched ? 2 : 0,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
        )
      );
      fromY = fromY + scoreBar.score.toDouble();
    }

    return BarChartGroupData(
      x: x,
      groupVertically: true,
      showingTooltipIndicators: isTouched ? [0,1,2,3,4] : [],
      barRods: barSegments
    );
  }

  BarTooltipItem? getTooltipItem(BarChartGroupData group, int groupIndex, BarChartRodData rod, int rodIndex) {
    List<TextSpan> barData = [];
    final textStyle = TextStyle(
      color: rod.color,
      fontFamily: Styles().fontFamilies.bold,
      fontSize: 14,
    );

    barData.add(TextSpan(text: '${(rod.toY.toInt()-rod.fromY.toInt())}${barData.isNotEmpty ? '\n' : ''}', style: textStyle));

    return BarTooltipItem('${bottomTitleStrings(group.x)}\n', textStyle, children: barData.reversed.toList());
  }


}
