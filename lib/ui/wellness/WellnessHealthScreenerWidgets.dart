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
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/AccessWidgets.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/widget_builders/scroll_pager.dart';
import 'package:rokwire_plugin/ui/widget_builders/survey.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/scroll_pager.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

class WellnessHealthScreenerHomeWidget extends StatefulWidget {
  final ScrollController scrollController;

  WellnessHealthScreenerHomeWidget(this.scrollController);

  @override
  State<WellnessHealthScreenerHomeWidget> createState() => _WellnessHealthScreenerHomeWidgetState();
}

class _WellnessHealthScreenerHomeWidgetState extends State<WellnessHealthScreenerHomeWidget> implements NotificationsListener {
  //bool _loading = false;

  List<String> _timeframes = ["Today", "This Week", "This Month", "All Time"];
  // List<String> _surveyTypes = ["All", "Health Screener", "Symptoms", "Illness Screener"];

  String? _selectedTimeframe = "This Week";
  String? _selectedSurveyType = "Health Screener";

  List<SurveyResponse> _responses = [];

  late ScrollPagerController _pagerController;

  @override
  void initState() {
    _pagerController = ScrollPagerController(limit: 20, onPage: _loadPage, onStateChanged: _onPagerStateChanged);
    _pagerController.registerScrollController(widget.scrollController);

    super.initState();
    NotificationService().subscribe(this, [
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
    Widget? accessWidget = AccessCard.builder(resource: 'wellness.health_screener');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HomeSlantWidget(
          title: Localization().getStringEx('panel.wellness.sections.health_screener.label.screener.title', 'Screener'),
          titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
          childPadding: HomeSlantWidget.defaultChildPadding,
          child: accessWidget ?? _buildHealthScreenerSectionWidget(),
        ),
        Visibility(visible: accessWidget == null, child: _buildHistorySectionWidget()),
      ]);
  }

  Widget _buildHealthScreenerSectionWidget() {
    Widget content;
    if (StringUtils.isNotEmpty(Config().healthScreenerSurveyID)) {
      content = Column(children: [
        Text(
          Localization().getStringEx('panel.wellness.sections.health_screener.label.screener.details.title',
              'Not feeling well? Use the Illinois Health Screener to help you find the right resources'),
          style: Styles().textStyles?.getTextStyle('widget.title.large.fat'),
        ),
        SizedBox(height: 8),
        Text(
          Localization().getStringEx('panel.wellness.sections.health_screener.label.screener.details.text',
              'Your screening results are confidential unless you choose to share them'),
          style: Styles().textStyles?.getTextStyle('widget.detail.small'),
        ),
        SizedBox(height: 16),
        RoundedButton(
            label: Localization().getStringEx('panel.wellness.sections.health_screener.button.take_screener.title',
                'Take the Screener'),
            textStyle: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'),
            onTap: _onTapTakeScreener),
      ]);
    } else {
      content = Text(
        Localization().getStringEx('panel.wellness.sections.health_screener.label.screener.missing.title',
            'The Illinois Health Screener is currently unavailable. Please check back later.'),
        style: Styles().textStyles?.getTextStyle('widget.title.large.fat'),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: content
      ),
    );
  }

  Widget _buildHistorySectionWidget() {
    return HomeSlantWidget(
      title: Localization().getStringEx('panel.wellness.sections.health_screener.label.history.title', 'History'),
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true),
      childPadding: HomeSlantWidget.defaultChildPadding,
      child: Column(children: [
        _buildFiltersWidget(),
        SizedBox(height: 16.0),
        _buildResponsesSection(),
        ScrollPagerBuilder.buildScrollPagerFooter(_pagerController) ?? Container(),
      ]),
    );
  }

  Widget _buildFiltersWidget() {
    return Card(
      color: Styles().colors?.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(Localization().getStringEx("panel.wellness.sections.health_screener.dropdown.filter.timeframe.title", "Time:"), style: Styles().textStyles?.getTextStyle('widget.title.regular'),),
                Container(width: 8.0),
                Expanded(
                  child: DropdownButton(value: _selectedTimeframe, style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                      items: _getDropDownItems(_timeframes), isExpanded: true, onChanged: (String? selected) {
                    setState(() {
                      _selectedTimeframe = selected;
                      _refreshHistory();
                    });
                  }),
                ),
              ],
            ),
            // Row(
            //   children: [
            //     Text(Localization().getStringEx("panel.wellness.sections.health_screener.dropdown.filter.type.title", "Type:"), style: Styles().textStyles?.getTextStyle('widget.title.regular'),),
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

  List<String> get _selectedSurveyTypes {
    List<String> types = [];
    if (_selectedSurveyType == "All") {
      // types.addAll(_surveyTypes.skip(1));
    } else if (_selectedSurveyType != null) {
      types.add(_selectedSurveyType!);
    }
    for (int i = 0; i < types.length; i++) {
      types[i] = types[i].toLowerCase().replaceAll(' ', '_');
    }
    return types;
  }

  void _refreshHistory() {
    _responses.clear();
    _pagerController.reset();
  }

  Future<int> _loadPage({required int offset, required int limit}) async {
    List<SurveyResponse>? responses = await Surveys().loadSurveyResponses(surveyTypes: _selectedSurveyTypes,
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

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Surveys.notifySurveyResponseCreated) {
      _refreshHistory();
    } else if (name == FlexUI.notifyChanged) {
      setState(() {});
    }
  }
}
