import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart' as rokwire;
class SurveyPanel extends rokwire.SurveyPanel with AnalyticsInfo {

  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  SurveyPanel({required super.survey, super.surveyDataKey, super.inputEnabled,
    super.dateTaken, super.showResult, super.onComplete, super.initPanelDepth, super.defaultResponses,
    super.summarizeResultRules, super.summarizeResultRulesWidget, super.headerBar, super.tabBar, super.offlineWidget,
    this.analyticsFeature});

  @override
  PreferredSizeWidget? buildHeaderBar(String? title) => HeaderBar(title: title);
}

