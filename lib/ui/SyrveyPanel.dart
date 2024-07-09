import 'package:flutter/material.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart' as rokwire;
class SurveyPanel extends rokwire.SurveyPanel{

  SurveyPanel({required super.survey, super.surveyDataKey, super.inputEnabled, super.backgroundColor,
    super.dateTaken, super.showResult, super.onComplete, super.initPanelDepth, super.defaultResponses,
    super.summarizeResultRules, super.summarizeResultRulesWidget, super.headerBar, super.tabBar, super.offlineWidget});

  @override
  PreferredSizeWidget? buildHeaderBar(String? title) => HeaderBar(title: title);
}

