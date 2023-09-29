/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/flex_ui.dart';
import 'package:illinois/ui/widgets/AccessWidgets.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widget_builders/scroll_pager.dart';
import 'package:rokwire_plugin/ui/widget_builders/survey.dart';
import 'package:rokwire_plugin/ui/widgets/ribbon_button.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/scroll_pager.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/storage.dart';

import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';

class WellnessHealthScreenerHomeWidget extends StatefulWidget {
  final ScrollController scrollController;

  WellnessHealthScreenerHomeWidget(this.scrollController);

  @override
  State<WellnessHealthScreenerHomeWidget> createState() => _WellnessHealthScreenerHomeWidgetState();
}

class _WellnessHealthScreenerHomeWidgetState extends State<WellnessHealthScreenerHomeWidget> implements NotificationsListener {
  final String _healthScreenerSurveyType = "health_screener";

  String resourceName = 'wellness.health_screener';
  List<String> _timeframes = ["Today", "This Week", "This Month", "All Time"];

  String? _selectedTimeframe = "This Week";

  List<SurveyResponse> _responses = [];

  late ScrollPagerController _pagerController;

  @override
  void initState() {
    _pagerController = ScrollPagerController(limit: 20, onPage: _loadPage, onStateChanged: _onPagerStateChanged);
    _pagerController.registerScrollController(widget.scrollController);

    super.initState();
    NotificationService().subscribe(this, [
      Storage.notifySettingChanged,
      Surveys.notifySurveyResponseCreated,
      FlexUI.notifyChanged
    ]);
  }

  @override
  void dispose() {
    _pagerController.deregisterScrollController();
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    Widget? accessWidget = AccessCard.builder(resource: resourceName);
    bool showHistory = JsonUtils.stringListValue(FlexUI()[resourceName])?.contains('history') ?? false;
    return SectionSlantHeader(
      titleIconKey: 'health',
      headerWidget: _buildHeader(),
      slantColor: Styles().colors?.gradientColorPrimary,
      slantPainterHeadingHeight: 0,
      backgroundColor: Styles().colors?.background,
      children: _buildInfoAndSettings(accessWidget, showHistory),
      childrenPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      allowOverlap: false,
    );
  }

  Widget _buildHeader() {
    Widget content;
    if (StringUtils.isNotEmpty(Config().healthScreenerSurveyID)) {
      content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(Localization().getStringEx('panel.wellness.sections.health_screener.label.screener.title', 'Not feeling well?'), style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.get_started.header'), textAlign: TextAlign.left,),
        Text(Localization().getStringEx('panel.wellness.sections.health_screener.label.screener.subtitle', 'Find the right resources'), style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.get_started.time.description'), textAlign: TextAlign.left,),
        Padding(padding: EdgeInsets.only(top: 24), child: _buildDescription()),
        Padding(padding: EdgeInsets.only(top: 64, left: 64, right: 80), child: RoundedButton(
            label: Localization().getStringEx('panel.wellness.sections.health_screener.button.take_screener.title',
                'Take the Screener'),
            textStyle: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'),
            onTap: _onTapTakeScreener
        )),
      ]);
    } else {
      content = Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          Localization().getStringEx('panel.wellness.sections.health_screener.label.screener.missing.title',
              'The Illinois Health Screener is currently unavailable. Please check back later.'),
          style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.get_started.header'),
        )
      ],);
    }
    return Container(
      padding: EdgeInsets.only(top: 32, bottom: 32),
      child: Padding(padding: EdgeInsets.only(left: 24, right: 8), child: content,),
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Styles().colors?.fillColorPrimaryVariant ?? Colors.transparent,
                Styles().colors?.gradientColorPrimary ?? Colors.transparent,
              ]
          )
      ),
    );
  }

  Widget _buildDescription() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(Localization().getStringEx('panel.wellness.sections.health_screener.description.title',
        'Use the Illinois Health Screener to help you find the right resources'), style: Styles().textStyles?.getTextStyle('panel.wellness.sections.health_screener.description'),),
      Padding(padding: EdgeInsets.only(top: 8), child: Text(
        Localization().getStringEx('panel.wellness.sections.health_screener.label.screener.details.text',
            'Your screening results are confidential unless you choose to share them'),
        style: Styles().textStyles?.getTextStyle('panel.wellness.sections.health_screener.description'),
      ))
    ]);
  }

  List<Widget> _buildInfoAndSettings(Widget? accessWidget, bool showHistory) {
    bool saveEnabled = Storage().assessmentsSaveResultsMap?[_healthScreenerSurveyType] != false;
    return <Widget>[
      RibbonButton(
        leftIconKey: "info",
        label: saveEnabled ? Localization().getStringEx("panel.wellness.sections.health_screener.body.save.description", "Your results will be saved for you to revisit or compare to future results.") :
        Localization().getStringEx("panel.wellness.sections.health_screener.body.dont_save.description", "Your results will not be saved for you to compare to future results."),
        textStyle: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'),
        backgroundColor: Colors.transparent,
        onTap: _onTapSavedResultsInfo,
      ),
      RibbonButton(
        leftIconKey: "settings",
        label: saveEnabled ? Localization().getStringEx("panel.wellness.sections.health_screener.body.dont_save.label", "Don't Save My Results") :
        Localization().getStringEx("panel.wellness.sections.health_screener.body.save.label", "Save My Results"),
        textStyle: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.link.fat'),
        backgroundColor: Colors.transparent,
        onTap: _onTapSettings,
      ),
      Visibility(visible: showHistory && (accessWidget == null), child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
        child: _buildHistorySectionWidget(),
      ))
    ];
  }

  Widget _buildHistorySectionWidget() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(Localization().getStringEx('panel.wellness.sections.health_screener.label.history.title', 'My Screener History',),
        style: Styles().textStyles?.getTextStyle('widget.title.large.fat'),),
        _buildFiltersWidget(),
        SizedBox(height: 16.0),
        _buildResponsesSection(),
        ScrollPagerBuilder.buildScrollPagerFooter(_pagerController) ?? Container(),
      ]),
    );
  }

  Widget _buildFiltersWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              DropdownButton(value: _selectedTimeframe, style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                  items: _getDropDownItems(_timeframes), onChanged: (String? selected) {
                setState(() {
                  _selectedTimeframe = selected;
                  _refreshHistory();
                });
              }),
              Spacer(flex: 1,),
              TextButton(
                child: Text(Localization().getStringEx("panel.wellness.sections.health_screener.history.clear", "Clear All"),
                  style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.link.fat')),
                onPressed: _onTapClearHistoryConfirm,
              ),
            ],
          ),
          // Row(
          //   children: [
          //     Text(Localization().getStringEx("panel.wellness.sections.health_screener.dropdown.filter.type.title", "Type:"), style: Styles().textStyles?.getTextStyle('widget.title.regular.fat'),),
          //     Container(width: 8.0),
          //     Expanded(
          //       child: DropdownButton(value: _selectedSurveyType, style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          //           items: _getDropDownItems(_surveyTypes), isExpanded: true, onChanged: (String? selected) {
          //         setState(() {
          //           _selectedSurveyType = selected;
          //           _refreshHistory();
          //         });
          //       }),
          //     ),
          //   ],
          // ),
          // Row(
          //   children: [
          //     Text(Localization().getStringEx("panel.activity.dropdown.filter.illness.title", "Illness:"), style: Styles().textStyles.headline4,),
          //     Container(width: 8.0),
          //     Expanded(
          //       child: DropdownButton(value: _selectedPlan, isExpanded: true, style: Styles().textStyles.body, items: AppWidgets.getDropDownItems(Health().activePlans, nullOption: "All"), onChanged: (TreatmentPlan? selected) {
          //         setState(() {
          //           _selectedPlan = selected;
          //           _refreshEvents();
          //         });
          //       }),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildResponsesSection() {
    List<Widget> content = [];
    for(SurveyResponse response in _responses) {
      Widget widget = SurveyBuilder.surveyResponseCard(context, response, showTimeOnly: _selectedTimeframe == "Today");
      content.add(widget);
      content.add(Container(height: 16.0));
    }
    return Column(children: content);
  }

  void _onTapTakeScreener() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: Config().healthScreenerSurveyID, tabBar: uiuc.TabBar(), offlineWidget: _buildOfflineWidget(),)));
  }

  void _onTapClearHistoryConfirm() {
    List<Widget> buttons = [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: RoundedButton(
        label: Localization().getStringEx('dialog.no.title', 'No'),
        borderColor: Styles().colors?.fillColorPrimaryVariant,
        backgroundColor: Styles().colors?.surface,
        textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
        onTap: _onTapDismissClearHistory,
      )),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: RoundedButton(
        label: Localization().getStringEx('dialog.yes.title', 'Yes'),
        borderColor: Styles().colors?.fillColorSecondary,
        backgroundColor: Styles().colors?.surface,
        textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
        onTap: _onTapClearHistory,
      )),
    ];

    ActionsMessage.show(
      context: context,
      titleBarColor: Styles().colors?.surface,
      message: Localization().getStringEx('panel.wellness.sections.health_screener.history.clear.confirm', 'Are you sure you want to clear your history?'),
      messageTextStyle: Styles().textStyles?.getTextStyle('widget.description.medium'),
      messagePadding: const EdgeInsets.only(left: 32, right: 32, top: 8, bottom: 32),
      messageTextAlign: TextAlign.center,
      buttons: buttons,
      buttonsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
      closeButtonIcon: Styles().images?.getImage('close', excludeFromSemantics: true),
    );
  }

  void _onTapDismissClearHistory() {
    Navigator.of(context).pop();
  }

  void _onTapClearHistory() {
    Navigator.of(context).pop();
    Surveys().deleteSurveyResponses(surveyTypes: [_healthScreenerSurveyType]).then((_) {
      setState(() {
        _refreshHistory();
      });
    });
  }

  Widget _buildOfflineWidget() {
    return Padding(padding: EdgeInsets.all(28), child:
      Center(child:
        Text(
          Localization().getStringEx('panel.wellness.sections.health_screener.offline.error.msg', 'Illinois Health Screener is not available while offline.'),
          textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat')
        )
      ),
    );
  }

  DateTime? get _selectedStartDate {
    DateTime now = DateTime.now();
    switch(_selectedTimeframe) {
      case "Today":
        return DateTime(now.year, now.month, now.day);
      case "This Week":
        return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      case "This Month":
        return DateTime(now.year, now.month);
      case "All Time":
        return null;
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  void _refreshHistory() {
    _responses.clear();
    _pagerController.reset();
  }

  Future<int> _loadPage({required int offset, required int limit}) async {
    List<SurveyResponse>? responses = await Surveys().loadUserSurveyResponses(surveyTypes: [_healthScreenerSurveyType],
        startDate: _selectedStartDate, limit: limit, offset: offset);
    if (responses != null) {
      setState(() {
        _responses.addAll(responses);
      });
    }
    return responses?.length ?? 0;
  }

  void _onPagerStateChanged() {
    setState(() { });
  }
  List<DropdownMenuItem<T>> _getDropDownItems<T>(List<T> options, {String? nullOption}) {
    List<DropdownMenuItem<T>> dropDownItems = <DropdownMenuItem<T>>[];
    if (nullOption != null) {
      dropDownItems.add(DropdownMenuItem(value: null, child: Text(nullOption, style: Styles().textStyles?.getTextStyle('widget.detail.regular'))));
    }
    for (T option in options) {
      dropDownItems.add(DropdownMenuItem(value: option, child: Text(option.toString(), style: Styles().textStyles?.getTextStyle('widget.detail.regular'))));
    }
    return dropDownItems;
  }

  void _onTapSavedResultsInfo() {
    bool saveEnabled = Storage().assessmentsSaveResultsMap?[_healthScreenerSurveyType] != false;
    Widget textWidget = Text(
      saveEnabled ? Localization().getStringEx("panel.skills_self_evaluation.get_started.body.save.dialog",
          "Your results will be saved for you to compare to future results.\n\nNo data from this assessment will be shared with other people or systems or stored outside of your Illinois app account.") :
      Localization().getStringEx("panel.skills_self_evaluation.get_started.body.dont_save.description", "Your results will not be saved for you to compare to future results."),
      style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.auth_dialog.text'),
      textAlign: TextAlign.center,
    );
    showDialog(context: context, builder: (_) => InfoPopup(
      backColor: Styles().colors?.surface,
      padding: EdgeInsets.only(left: 32, right: 32, top: 40, bottom: 32),
      alignment: Alignment.center,
      infoTextWidget: textWidget,
      closeIcon: Styles().images?.getImage('close', excludeFromSemantics: true),
    ),);
  }

  void _onTapSettings() {
    SettingsHomeContentPanel.present(context, content: SettingsContent.assessments);
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Surveys.notifySurveyResponseCreated) {
      _refreshHistory();
    } else if (name == FlexUI.notifyChanged) {
      setState(() {});
    } else if (name == Storage.notifySettingChanged && param == Storage().assessmentsEnableSaveKey && mounted) {
      setState(() {});
    }
  }
}
