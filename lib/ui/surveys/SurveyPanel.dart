import 'package:flutter/material.dart';
import 'package:neom/ext/Survey.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart' as rokwire;
import 'package:rokwire_plugin/ui/widgets/survey.dart';
class SurveyPanel extends rokwire.SurveyPanel{

  SurveyPanel({required super.survey, super.surveyDataKey, super.inputEnabled, super.backgroundColor,
    super.dateTaken, super.showResult, super.onComplete, super.initPanelDepth, super.defaultResponses,
    super.summarizeResultRules, super.summarizeResultRulesWidget, super.headerBar, super.tabBar,
    super.offlineWidget, super.textStyles});

  factory SurveyPanel.defaultStyles({required dynamic survey, String? surveyDataKey, bool inputEnabled = true,
    DateTime? dateTaken, bool showResult = false, Function(dynamic)? onComplete, int initPanelDepth = 0, Map<String, dynamic>? defaultResponses,
    bool summarizeResultRules = false, Widget? summarizeResultRulesWidget, PreferredSizeWidget? headerBar, Widget? tabBar,
    Widget? offlineWidget}) {
    return SurveyPanel(
      survey: survey,
      surveyDataKey: surveyDataKey,
      inputEnabled: inputEnabled,
      dateTaken: dateTaken,
      showResult: showResult,
      onComplete: onComplete,
      initPanelDepth: initPanelDepth,
      defaultResponses: defaultResponses,
      summarizeResultRules: summarizeResultRules,
      summarizeResultRulesWidget: summarizeResultRulesWidget,
      headerBar: headerBar,
      tabBar: tabBar,
      offlineWidget: offlineWidget,
      backgroundColor: defaultBackgroundColor,
      textStyles: defaultTextStyles,
    );
  }

  @override
  PreferredSizeWidget? buildHeaderBar(String? title) => ((survey is Survey) && ((survey as Survey).endDate != null)) ?
    HeaderBar(titleWidget: _SurveyHeaderBarTitleWidget(survey as Survey, title: title),) :
    HeaderBar(title: title);

  static Color? get defaultBackgroundColor => Styles().colors.surface;
  static SurveyWidgetTextStyles get defaultTextStyles => SurveyWidgetTextStyles.withDefaults(horizontalMultipleChoiceOption: Styles().textStyles.getTextStyle('widget.item.small.thin'));
}

class _SurveyHeaderBarTitleWidget extends StatelessWidget {
  final String? title;
  final Survey survey;

  // ignore: unused_element
  _SurveyHeaderBarTitleWidget(this.survey, {super.key, this.title, });

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title ?? survey.title, style: Styles().textStyles.getTextStyle('header_bar'),),
    if (survey.endDate != null)
      Text(_endDateDetailText ?? '', style: Styles().textStyles.getTextStyle('header_bar_detail'),),
  ],);

  String? get _endDateDetailText {
    String? endTimeValue = survey.displayEndDate;
    if (endTimeValue != null) {
      final String _valueMacro = '{{end_date}}';
      int? daysDiff = survey.endDateDiff;
      String macroString = ((daysDiff == 0) || (daysDiff == 1)) ?
        Localization().getStringEx('model.public_survey.label.detail.ends.1', '(Ends $_valueMacro)') :
        Localization().getStringEx('model.public_survey.label.detail.ends.2', '(Ends on $_valueMacro)');
      return macroString.replaceAll(_valueMacro, endTimeValue);
    }
    else {
      return null;
    }
  }

}