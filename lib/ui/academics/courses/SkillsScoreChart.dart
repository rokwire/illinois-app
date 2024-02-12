
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

  @override
  State<StatefulWidget> createState() => SkillsScoreChartState();


}

class SkillsScoreChartState extends State<SkillsScoreChart> {
  static const double shadowOpacity = 0.2;
  static const int minMaxScore = 500;
  String _selectedSkill = "All Essential Skills";

  List<ScoreBarData> _chartItems = [];

  double _barWidth = 20;
  double _barSpacing = 10;

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
        _selectedSkill = selectedSkill ?? "All Essential Skills";
        _processSurveyData(responses, selectedSkill);
      });
    }
  }

  void _processSurveyData(List<SurveyResponse>? responses, String? selectedSkill) {
    _chartItems = [];
    _maxScore = minMaxScore;
    switch(selectedSkill) {
      case "All Essential Skills":
        _maxScore = 500;
        _processAllSkills(responses);
        break;
      default:
        _maxScore = 100;
        _processOneSkill(responses, selectedSkill ?? "");
        break;
    }

    if (_chartItems.length <= 8) {
      _barWidth = 30;
      _barSpacing = 24;
    } else if (_chartItems.length <= 12) {
      _barWidth = 20;
      _barSpacing = 10;
    }
  }
  
  void _processOneSkill(List<SurveyResponse>? responses, String selectedSkill /*, {bool displayDate = true}*/){
    for (SurveyResponse survey in responses ?? []) {
      SurveyStats? stats = survey.survey.stats;
      int totalScore = 0;
      List<ScoreBarSegment> scoreBarSegments = [];
      if(stats != null){
        switch(selectedSkill){
          case "Cooperation Skills":
            int score = _determineSkillScore(stats.scores["cooperation"], stats.maximumScores["cooperation"]);
            totalScore +=score;
            scoreBarSegments.add(ScoreBarSegment(skillType: "cooperation", color: Styles().colors.getColor('essentialSkillsCoachRedAccent'), score: score));
            _chartItems.add(ScoreBarData(title: DateTimeUtils.localDateTimeToString(survey.dateTaken, format: 'MM/dd/yy\nh:mma') ?? '', scoreBarSegments: scoreBarSegments, score: totalScore));
            break;
          case "Emotional Resilience Skills":
            int score = _determineSkillScore(stats.scores["emotional_resilience"], stats.maximumScores["emotional_resilience"]);
            totalScore +=score;
            scoreBarSegments.add(ScoreBarSegment(skillType: "emotional_resilience", color: Styles().colors.getColor('essentialSkillsCoachOrange'), score: score));
            _chartItems.add(ScoreBarData(title: DateTimeUtils.localDateTimeToString(survey.dateTaken, format: 'MM/dd/yy\nh:mma') ?? '', scoreBarSegments: scoreBarSegments, score: totalScore));
            break;
          case "Innovation Skills":
            int score = _determineSkillScore(stats.scores["innovation"], stats.maximumScores["innovation"]);
            totalScore +=score;
            scoreBarSegments.add(ScoreBarSegment(skillType: "innovation", color: Styles().colors.getColor('essentialSkillsCoachGreen'), score: score));
            _chartItems.add(ScoreBarData(title: DateTimeUtils.localDateTimeToString(survey.dateTaken, format: 'MM/dd/yy\nh:mma') ?? '', scoreBarSegments: scoreBarSegments, score: totalScore));
            break;
          case "Self-Management Skills":
            int score = _determineSkillScore(stats.scores["self_management"], stats.maximumScores["self_management"]);
            totalScore +=score;
            scoreBarSegments.add(ScoreBarSegment(skillType: "self_management", color: Styles().colors.getColor('essentialSkillsCoachBlue'), score: score));
            _chartItems.add(ScoreBarData(title: DateTimeUtils.localDateTimeToString(survey.dateTaken, format: 'MM/dd/yy\nh:mma') ?? '', scoreBarSegments: scoreBarSegments, score: totalScore));
            break;
          case "Social Engagement Skills":
            int score = _determineSkillScore(stats.scores["social_engagement"], stats.maximumScores["social_engagement"]);
            totalScore +=score;
            scoreBarSegments.add(ScoreBarSegment(skillType: "social_engagement", color: Styles().colors.getColor('essentialSkillsCoachPurple'), score: score));
            _chartItems.add(ScoreBarData(title: DateTimeUtils.localDateTimeToString(survey.dateTaken, format: 'MM/dd/yy\nh:mma') ?? '', scoreBarSegments: scoreBarSegments, score: totalScore));
            break;
        }
      }
    }
  }

  void _processAllSkills(List<SurveyResponse>? responses /*, {bool displayDate = true}*/) {
    for (SurveyResponse survey in responses ?? []) {
      SurveyStats? stats = survey.survey.stats;
      if(stats != null){
        List<ScoreBarSegment> scoreBarSegments = [];
        int totalScore = 0;
        stats.scores.forEach((key, value) {
          switch(key){
            case "cooperation":
              int score = _determineSkillScore(value, stats.maximumScores["cooperation"]);
              totalScore +=score;
              scoreBarSegments.add(ScoreBarSegment(skillType: "cooperation", color: Styles().colors.getColor('essentialSkillsCoachRedAccent'), score: score));
              break;
            case "emotional_resilience":
              int score = _determineSkillScore(value, stats.maximumScores["emotional_resilience"]);
              totalScore +=score;
              scoreBarSegments.add(ScoreBarSegment(skillType: "emotional_resilience", color: Styles().colors.getColor('essentialSkillsCoachOrange'), score: score));
              break;
            case "innovation":
              int score = _determineSkillScore(value, stats.maximumScores["innovation"]);
              totalScore +=score;
              scoreBarSegments.add(ScoreBarSegment(skillType: "innovation", color: Styles().colors.getColor('essentialSkillsCoachGreen'), score: score));
              break;
            case "self_management":
              int score = _determineSkillScore(value, stats.maximumScores["self_management"]);
              totalScore +=score;
              scoreBarSegments.add(ScoreBarSegment(skillType: "self_management", color: Styles().colors.getColor('essentialSkillsCoachBlue'), score: score));
              break;
            case "social_engagement":
              int score = _determineSkillScore(value, stats.maximumScores["social_engagement"]);
              totalScore +=score;
              scoreBarSegments.add(ScoreBarSegment(skillType: "social_engagement", color: Styles().colors.getColor('essentialSkillsCoachPurple'), score: score));
              break;
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
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(
            height: 220,
            child: SingleChildScrollView(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _chartItems.length * 60,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.center,
                    maxY: _maxScore.toDouble(),
                    minY: 0,
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
                          tooltipBgColor: Styles().colors.background,
                          tooltipBorder: BorderSide(color: Styles().colors.dividerLine, width: 1.0),
                          getTooltipItem: getTooltipItem,
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
                          interval: _maxScore / 4,
                          reservedSize: 42,
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
                            color: Styles().colors.surface.withOpacity(0.1),
                            strokeWidth: 3,
                          );
                        }
                        return FlLine(
                          color: Styles().colors.surface.withOpacity(0.05),
                          strokeWidth: 0.8,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    barGroups: _chartItems.mapIndexed((i, e) => generateGroup(i, e)).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(alignment: WrapAlignment.center, children: [
            Opacity(
              opacity: (_selectedSkill != "Cooperation Skills" && _selectedSkill != "All Essential Skills") ? .3 : 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Styles().colors.getColor('essentialSkillsCoachRed'), borderRadius: BorderRadius.circular(4)), child: Container(width: 15, height: 15,)),
                  ),
                  Text(Localization().getStringEx('', 'Cooperation\nSkills'), style: Styles().textStyles.getTextStyle("widget.toggle_button.title.tiny.thin.enabled"), textAlign: TextAlign.center,),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Opacity(
              opacity: (_selectedSkill != "Emotional Resilience Skills" && _selectedSkill != "All Essential Skills") ? .3 : 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Styles().colors.getColor('essentialSkillsCoachOrange'), borderRadius: BorderRadius.circular(4)), child: Container(width: 15, height: 15,)),
                  ),
                  Text(Localization().getStringEx('', 'Emotional\nResilience\nSkills'), style: Styles().textStyles.getTextStyle("widget.toggle_button.title.tiny.thin.enabled"), textAlign: TextAlign.center,),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Opacity(
              opacity: (_selectedSkill != "Innovation Skills" && _selectedSkill != "All Essential Skills") ? .3 : 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Styles().colors.getColor('essentialSkillsCoachGreen'), borderRadius: BorderRadius.circular(4)), child: Container(width: 15, height: 15,)),
                  ),
                  Text(Localization().getStringEx('', 'Innovation\nSkills'), style: Styles().textStyles.getTextStyle("widget.toggle_button.title.tiny.thin.enabled"), textAlign: TextAlign.center,),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Opacity(
              opacity: (_selectedSkill != "Self-Management Skills" && _selectedSkill != "All Essential Skills") ? .3 : 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Styles().colors.getColor('essentialSkillsCoachBlue'), borderRadius: BorderRadius.circular(4)), child: Container(width: 15, height: 15,)),
                  ),
                  Text(Localization().getStringEx('', 'Self-\nManagement\nSkills'), style: Styles().textStyles.getTextStyle("widget.toggle_button.title.tiny.thin.enabled"), textAlign: TextAlign.center,),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Opacity(
              opacity: (_selectedSkill != "Social Engagement Skills" && _selectedSkill != "All Essential Skills") ? .3 : 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Styles().colors.getColor('essentialSkillsCoachPurple'), borderRadius: BorderRadius.circular(4)), child: Container(width: 15, height: 15,)),
                  ),
                  Text(Localization().getStringEx('', 'Social\nEngagement\nSkills'), style: Styles().textStyles.getTextStyle("widget.toggle_button.title.tiny.thin.enabled"), textAlign: TextAlign.center,),
                ],
              ),
            ),
          ]),
        )
      ],
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    // style = TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 10);
    String text = bottomTitleStrings(value.toInt());
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 10)),
    );
  }

  String bottomTitleStrings(int i) {
    return _chartItems[i].title;
  }

  Widget leftTitles(double value, TitleMeta meta) {
    // style = TextStyle(color: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 10);
    String text;
    if (value == 0) {
      text = '0';
    } else {
      text = value.toInt().toString();
    }
    return SideTitleWidget(
      angle: AppMathUtils.degreesToRadians(value < 0 ? -45 : 45),
      axisSide: meta.axisSide,
      space: 4,
      child: Text(
        text,
        style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 10),
        textAlign: TextAlign.center,
      ),
    );
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
            color: scoreBar.color ?? Colors.white,
            width: _barWidth,
            borderSide: BorderSide(
              color: scoreBar.color ?? Colors.white,
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

class AppMathUtils {
  static const double pi = 3.141592653589793238;
  static double degreesToRadians(double degree) {
    return degree * pi / 180;
  }
}

