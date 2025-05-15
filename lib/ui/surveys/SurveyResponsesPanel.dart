/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/surveys/SurveyPanel.dart';
import 'package:illinois/ui/events2/Event2ManageDataPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/widget_builders/survey.dart';
import 'package:rokwire_plugin/ui/widgets/scroll_pager.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyResponsesPanel extends StatefulWidget with AnalyticsInfo {
  final String? surveyId;
  final Event2? event;
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  SurveyResponsesPanel({Key? key, this.surveyId, this.event, this.analyticsFeature}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SurveyResponsesPanelState();
}

class _SurveyResponsesPanelState extends State<SurveyResponsesPanel>  {

  List<SurveyResponse> _surveyResponses = [];

  late ScrollPagerController _scrollPagerController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    _scrollPagerController = ScrollPagerController(limit: 20, onPage: _loadResponses, onStateChanged: _onPagerStateChanged);
    _scrollPagerController.registerScrollController(_scrollController);

    super.initState();
  }

  @override
  void dispose() {
    _scrollPagerController.deregisterScrollController();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _headerBar,
        body: _buildContent(),
        backgroundColor: Styles().colors.background);
  }

  Widget _buildContent() {
    return ScrollPager(controller: _scrollPagerController, padding: const EdgeInsets.all(16.0), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO: _buildFiltersWidget(), (for start, end dates)
        // TODO: _buildSortWidget(),
        _buildDownloadWidget(),
        SizedBox(height: 16.0),
        ..._buildResponseWidgets(),
      ]
    ));
  }

  Widget _buildDownloadWidget() {
    return Visibility(visible: _isDownloadVisible, child: GestureDetector(onTap: _onTapDownloadResults, child: Padding(padding: EdgeInsets.symmetric(vertical: 5), child:
      Text(Localization().getStringEx('panel.event2.survey.responses.download.label', 'Download survey results'),
        style: Styles().textStyles.getTextStyle('panel.event.survey.responses.hyperlink.underlined')))));
  }

  List<Widget> _buildResponseWidgets() {
    List<Widget> content = [];

    for(int i = 0; i < _surveyResponses.length; i++) {
      SurveyResponse response = _surveyResponses[i];
      response.survey.replaceKey('event_name', widget.event?.name);
      Widget responseCard = SurveyBuilder.surveyResponseCard(context, response, title: 'Response ${i+1}', onTap: () => _onTapSurveyResponse(response));
      content.add(responseCard);
      content.add(Container(height: 16.0));
    }

    if (content.isEmpty) {
      content = _buildEmptyResponsesContent();
    }
    return content;
  }

  void _onTapSurveyResponse(SurveyResponse response) =>
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: response.survey, inputEnabled: false, dateTaken: response.dateTaken, showResult: true)));

  List<Widget> _buildEmptyResponsesContent() {
    return <Widget>[
      Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
        Text(
            Localization().getStringEx('panel.event2.survey.responses.surveys.empty.msg', 'There are no survey responses available.'),
            textAlign: TextAlign.center,
            style: Styles().textStyles.getTextStyle('widget.message.light.medium.thin')
        ),
      ),
    ];
  }

  Future<int> _loadResponses({required int offset, required int limit}) async {
    List<SurveyResponse>? responses = widget.surveyId != null ? await Surveys().loadAllSurveyResponses(widget.surveyId!, limit: limit, offset: offset) : null;
    if (responses != null) {
      setState(() {
        _surveyResponses.addAll(responses);
      });
    }
    return responses?.length ?? 0;
  }

  void _onPagerStateChanged() {
    setState(() {});
  }

  Survey? get _survey => _surveyResponses.isNotEmpty ? _surveyResponses.first.survey : null;

  // HeaderBar

  PreferredSizeWidget get _headerBar => HeaderBar(
    title: Localization().getStringEx('panel.survey.responses.header.title', '{{survey_name}} Survey Responses').replaceAll('{{survey_name}}', widget.event?.name ?? _survey?.title ?? ''),
    onLeading: _onHeaderBarBack,
  );

  void _onHeaderBarBack() {
    Analytics().logSelect(target: 'HeaderBar: Back');
    Navigator.of(context).pop();
  }

  // Download responses

  bool get _isDownloadVisible => CollectionUtils.isNotEmpty(_surveyResponses) && Event2ManageDataPanel.canManage;

  void _onTapDownloadResults() {
    Analytics().logSelect(target: 'Download survey results');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2ManageDataPanel(event: widget.event)));
  }
}