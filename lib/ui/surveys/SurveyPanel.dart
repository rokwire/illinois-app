import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neom/ext/Survey.dart';
import 'package:neom/service/AppDateTime.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/panels/survey_creation_panel.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart' as rokwire;
import 'package:rokwire_plugin/utils/utils.dart';

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
    );
  }

  @override
  PreferredSizeWidget? buildHeaderBar(BuildContext context, Survey? survey) => ((survey is Survey) && _SurveyHeaderBarTitleWidget.surveyHasDetails(survey)) ?
    HeaderBar(titleWidget: _SurveyHeaderBarTitleWidget(survey), actions: _buildActions(context, survey)) :
    HeaderBar(title: survey?.title, actions: _buildActions(context, survey));

  List<Widget>? _buildActions(BuildContext context, Survey? survey) {
    if (survey != null && (Auth2().isAppAdmin || Auth2().isDebugManager || kDebugMode)) {
      return [
        Visibility(
          visible: !survey.isSensitive,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Semantics(label: Localization().getStringEx('headerbar.panel.survey.download_responses.title', 'Download'), hint: Localization().getStringEx('headerbar.panel.survey.download_responses.hint', ''), button: true, excludeSemantics: true, child:
              InkWell(onTap: () => _onTapDownloadSurveyResults(context, survey), child:
                Padding(padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0), child:
                  Styles().images.getImage('download', excludeFromSemantics: true, color: Styles().colors.iconPrimary),
                )
              )
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Semantics(label: Localization().getStringEx('headerbar.panel.survey.edit.title', 'Edit'), hint: Localization().getStringEx('headerbar.panel.survey.edit.hint', ''), button: true, excludeSemantics: true, child:
            InkWell(onTap: () => _onTapEditSurvey(context, survey), child:
              Padding(padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0), child:
                Styles().images.getImage('edit', excludeFromSemantics: true, color: Styles().colors.iconPrimary),
              )
            )
          ),
        ),
      ];
    }
    return null;
  }

  void _onTapDownloadSurveyResults(BuildContext context, Survey survey) async {
    if (survey.isSensitive) {
      return;
    }

    List<dynamic> results = await Future.wait([
      _loadSurveyResponses(context, survey),
      _loadSurveyEvent(survey),
    ]);
    List<SurveyResponse>? surveyResponses = results[0];
    Event2? surveyEvent = results[1];

    if (CollectionUtils.isEmpty(surveyResponses)) {
      AppAlert.showDialogResult(context, 'There are no results for this survey.');
      return;
    }

    final String surveyName = survey.title;

    List<String>? accountIds = surveyResponses?.map((response) => StringUtils.ensureNotEmpty(response.userId)).toList();

    dynamic filterAccountsResult = await Auth2().filterAccountsBy(accountIds: accountIds!);
    List<Auth2Account>? accounts;
    if (filterAccountsResult is String) {
      AppAlert.showDialogResult(context, filterAccountsResult);
    } else if ((filterAccountsResult == null) || ((filterAccountsResult is List) && CollectionUtils.isEmpty(filterAccountsResult))) {
      AppAlert.showDialogResult(context, 'There are no accounts for the specified account ids.');
    } else if (filterAccountsResult is List<Auth2Account>) {
      accounts = filterAccountsResult;
    }
    final String defaultEmptyValue = '---';
    final String dateFormat = 'yyyy-MM-dd';
    final String timeFormat = 'HH:mm';
    String eventName = StringUtils.ensureNotEmpty(surveyEvent?.name, defaultValue: defaultEmptyValue);
    String eventStartDate = StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(surveyEvent?.startTimeUtc, format: dateFormat),
        defaultValue: defaultEmptyValue);
    String eventStartTime = StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(surveyEvent?.startTimeUtc, format: timeFormat),
        defaultValue: defaultEmptyValue);
    bool hasAccounts = CollectionUtils.isNotEmpty(accounts);
    List<List<dynamic>> rows = <List<dynamic>>[[
      'Survey Name',
      'Date Responded',
      'Time Responded',
    ]];
    if (StringUtils.isNotEmpty(survey.calendarEventId)) {
      rows.first.addAll([
        'Event Name',
        'Event Start Date',
        'Event Start Time',
      ]);
    }
    rows.first.addAll([
      'First Name',
      'Last Name',
    ]);
    bool addPromptHeaders = true;
    int firstPromptIndex = rows.first.length;

    for (SurveyResponse response in surveyResponses!) {
      String? accountId = response.userId;
      Auth2Account? account = ((accountId != null) && hasAccounts) ? accounts!.firstWhereOrNull((account) => (account.id == accountId)) : null;
      List<String> answers = [];
      int responsePromptIndex = 0;
      for (SurveyData? data = Surveys().getFirstQuestion(response.survey); data != null; data = Surveys().getFollowUp(response.survey, data)) {
        String question = data.text;
        if (addPromptHeaders) {
          rows.first.add(question);
        } else if (!rows.first.contains(question)) {
          rows.first.insert(firstPromptIndex + responsePromptIndex, question);
          for (int i = 1; i < rows.length; i++) {
            rows[i].insert(firstPromptIndex + responsePromptIndex, defaultEmptyValue);
          }
        }
        String answer = data.response.toString();
        if (data is SurveyQuestionTrueFalse && data.style == 'yes_no') {
          bool? response = data.response as bool?;
          if (response != null) {
            answer = response ? 'Yes' : 'No';
          }
        }
        answers.add(answer);

        responsePromptIndex++;
      }
      addPromptHeaders = false;

      rows.add([
        surveyName,
        StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(response.dateTakenLocal, format: dateFormat),
            defaultValue: defaultEmptyValue),
        StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(response.dateTakenLocal, format: timeFormat),
            defaultValue: defaultEmptyValue),
      ]);
      if (StringUtils.isNotEmpty(survey.calendarEventId)) {
        rows.last.addAll([
          eventName,
          eventStartDate,
          eventStartTime,
        ]);
      }
      rows.last.addAll([
        StringUtils.ensureNotEmpty(account?.profile?.firstName, defaultValue: defaultEmptyValue),
        StringUtils.ensureNotEmpty(account?.profile?.lastName, defaultValue: defaultEmptyValue),
        ...answers,
      ]);
    }
    String? dateExported = AppDateTime().formatDateTime(DateTime.now(), format: 'yyyy-MM-dd-HH-mm');
    String fileName = '${surveyName.toLowerCase().replaceAll(" ", "_")}_results_$dateExported.csv';
    AppCsv.exportCsv(context: context, rows: rows, fileName: fileName).then((_) {
      AppToast.show(context, child: Container(color: Styles().colors.background, child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('$surveyName results downloaded', style: Styles().textStyles.getTextStyle('widget.info.small')),
      )));
    });
  }

  void _onTapEditSurvey(BuildContext context, Survey survey) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyCreationPanel(survey: survey,)));
  }

  Future<List<SurveyResponse>?> _loadSurveyResponses(BuildContext context, Survey survey) async {
    if (StringUtils.isNotEmpty(survey.id) && !survey.isSensitive) {
      List<SurveyResponse>? result = await Surveys().loadAllSurveyResponses(survey.id, admin: true);
      if (result == null) {
        AppAlert.showDialogResult(context, Localization().getStringEx('panel.survey_details.responses.load.failed.message', 'Failed to load survey responses.'));
      }
      return result;
    }
    return null;
  }

  Future<Event2?> _loadSurveyEvent(Survey survey) async {
    String? eventId = survey.calendarEventId;
    return StringUtils.isNotEmpty(eventId) ? await Events2().loadEvent(eventId!, admin: true) : null;
  }
}

class _SurveyHeaderBarTitleWidget extends StatelessWidget {
  final Survey survey;

  // ignore: unused_element
  _SurveyHeaderBarTitleWidget(this.survey, {super.key, });

  @override
  Widget build(BuildContext context) {
    Widget? detailWidget = _buildDetailWidget(context);
    return (detailWidget != null) ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _titleWidget,
      detailWidget
    ],) : _titleWidget;
  }

  Widget get _titleWidget =>
      Text(survey.title, style: Styles().textStyles.getTextStyle('header_bar'),);

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