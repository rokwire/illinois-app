import 'package:flutter/material.dart';
import 'package:illinois/ext/Survey.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart' as rokwire;

class SurveyPanel extends rokwire.SurveyPanel with AnalyticsInfo {

  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  SurveyPanel({required super.survey, super.surveyDataKey, super.inputEnabled,
    super.dateTaken, super.showResult, super.onComplete, super.initPanelDepth, super.defaultResponses,
    super.summarizeResultRules, super.summarizeResultRulesWidget, super.headerBar, super.tabBar, super.offlineWidget,
    this.analyticsFeature});

  @override
  PreferredSizeWidget? buildHeaderBar(String? title) => ((survey is Survey) && _SurveyHeaderBarTitleWidget.surveyHasDetails(survey)) ?
    HeaderBar(titleWidget: _SurveyHeaderBarTitleWidget(survey as Survey, title: title),) :
    HeaderBar(title: title);
}

class _SurveyHeaderBarTitleWidget extends StatelessWidget {
  final String? title;
  final Survey survey;

  // ignore: unused_element_parameter
  _SurveyHeaderBarTitleWidget(this.survey, {super.key, this.title, });

  @override
  Widget build(BuildContext context) {
    Widget? detailWidget = _buildDetailWidget(context);
    return (detailWidget != null) ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _titleWidget,
      detailWidget
    ],) : _titleWidget;
  }

  Widget get _titleWidget =>
      Text(title ?? survey.title, style: Styles().textStyles.getTextStyle('header_bar'),);

  static bool surveyHasDetails(Survey survey) =>
    (survey.endDate != null) || survey.isCompleted;

  Widget? _buildDetailWidget(BuildContext context) {
    List<InlineSpan> details = <InlineSpan>[];

    if (survey.endDate != null) {
      details.add(TextSpan(
        text: _endDateDetailText ?? '')
      );
    }

    if (survey.isCompleted) {
      if (details.isNotEmpty) {
        details.add(TextSpan(text: ', '));
      }
      details.add(TextSpan(
        text: Localization().getStringEx('model.public_survey.label.detail.completed', 'Completed'),
        style: Styles().textStyles.getTextStyle('header_bar.detail.highlighted.fat')
      ));
    }

    if (details.isNotEmpty) {
      return RichText(textScaler: MediaQuery.of(context).textScaler, text:
        TextSpan(style: Styles().textStyles.getTextStyle("header_bar.detail"), children: details)
      );
    }
    else {
      return null;
    }
  }


  String? get _endDateDetailText {
    String? endTimeValue = survey.displayEndDate;
    if (endTimeValue != null) {
      final String _valueMacro = '{{end_date}}';
      int? daysDiff = survey.endDateDiff;
      String macroString = ((daysDiff == 0) || (daysDiff == 1)) ?
        Localization().getStringEx('model.public_survey.label.detail.ends.1', 'Ends $_valueMacro') :
        Localization().getStringEx('model.public_survey.label.detail.ends.2', 'Ends on $_valueMacro');
      return macroString.replaceAll(_valueMacro, endTimeValue);
    }
    else {
      return null;
    }
  }

}