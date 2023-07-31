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

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/widget_builders/scroll_pager.dart';
import 'package:rokwire_plugin/ui/widget_builders/survey.dart';
import 'package:rokwire_plugin/ui/widgets/scroll_pager.dart';
import 'package:rokwire_plugin/ui/widgets/survey.dart';

class Event2SurveyResponsesPanel extends StatefulWidget {
  final String? surveyId;

  Event2SurveyResponsesPanel({Key? key, this.surveyId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2SurveyResponsesPanelState();
}

class _Event2SurveyResponsesPanelState extends State<Event2SurveyResponsesPanel>  {

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
        backgroundColor: Styles().colors?.background);
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO: _buildFiltersWidget(), (for start, end dates)
          // TODO: _buildSortWidget(),
          SizedBox(height: 16.0),
          ..._buildResponseWidgets(),
          ScrollPagerBuilder.buildScrollPagerFooter(_scrollPagerController) ?? Container(),
        ]
      ),
    );
  }

  List<Widget> _buildResponseWidgets() {
    List<Widget> content = [];
    for(SurveyResponse response in _surveyResponses) {
      Widget widget = SurveyBuilder.surveyResponseCard(context, response);
      content.add(widget);
      content.add(Container(height: 16.0));
    }

    if (content.isEmpty) {
      content = _buildEmptyResponsesContent();
    }
    return content;
  }

  List<Widget> _buildEmptyResponsesContent() {
    return <Widget>[
      Expanded(flex: 1, child: Container(),),
      Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
        Text(
            Localization().getStringEx('panel.event2.survey.responses.surveys.empty.msg', 'There are no survey responses available.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18)
        ),
      ),
      Expanded(flex: 2, child: Container(),),
    ];
  }

  Future<int> _loadResponses({required int offset, required int limit}) async {
    List<SurveyResponse>? responses = widget.surveyId != null ? await Surveys().loadSurveyResponses(surveyIDs: [widget.surveyId!],
        /*startDate: _selectedStartDate,*/ limit: limit, offset: offset) : null;
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

  /*
  Widget _buildSurveysSection() {
    String title = Localization().getStringEx('panel.event2.setup.survey.survey.title', 'SURVEY');
    return Padding(padding: Event2CreatePanel.sectionPadding, child:
      Semantics(container: true, child:
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(flex: 1, child:
            Padding(padding: EdgeInsets.only(right: 8), child:
              Wrap(children: [
                Event2CreatePanel.buildSectionTitleWidget(title),
              ]),
            ),
          ),
          Expanded(flex: 3, child: _surveysDropdownWidget),
        ]),
      ),
    );
  }

  Widget get _surveysDropdownWidget =>
    Container(decoration: Event2CreatePanel.dropdownButtonDecoration, child:
    Padding(padding: EdgeInsets.only(left: 12, right: 8), child:
      DropdownButtonHideUnderline(child:
        DropdownButton<Survey?>(
          icon: Styles().images?.getImage('chevron-down'),
          isExpanded: true,
          value: _survey,
          style: Styles().textStyles?.getTextStyle("panel.create_event.dropdown_button.title.regular"),
          hint: Text((_survey != null) ? (_survey?.displayTitle ?? '') : nullSurveyTitle),
          items: _buildSurveyDropDownItems(),
          onChanged: _onSurveyChanged
        ),
      ),
    ),
  );


  List<DropdownMenuItem<Survey?>>? _buildSurveyDropDownItems() {
    List<DropdownMenuItem<Survey?>> items = <DropdownMenuItem<Survey?>>[];
    items.add(DropdownMenuItem<Survey?>(value: null, child:
      Text(nullSurveyTitle),
    ));
    if (_surveys != null) {
      for (Survey survey in _surveys!) {
        items.add(DropdownMenuItem<Survey?>(value: survey, child:
          Text(survey.displayTitle ?? '')
        ));
      }
    }
    return items;
  }

  void _onSurveyChanged(Survey? survey) {
    Analytics().logSelect(target: "Survey: ${(survey != null) ? survey.title : 'null'}");
    if ((_survey != survey) && mounted) {
      setState(() {
        _selectSurvey(survey);
      });
      _checkModified();
      //TBD: Preview selected survey
    }
  }

  void _selectSurvey(Survey? survey) {
    _survey = survey;
    _displaySurvey = survey != null ? Survey.fromOther(survey) : null;
    _displaySurvey?.replaceKey('event_name', widget.eventName ?? widget.surveyParam.event?.name);
  }

  String get nullSurveyTitle => Localization().getStringEx('panel.event2.setup.survey.no_survey.title', '---');
  */

  // HeaderBar

  PreferredSizeWidget get _headerBar => HeaderBar(
    title: Localization().getStringEx('panel.event2.survey.responses.header.title', 'Event Follow-Up Survey Responses'),
    onLeading: _onHeaderBarBack,
  );

  void _onHeaderBarBack() {
    Analytics().logSelect(target: 'HeaderBar: Back');
    Navigator.of(context).pop();
  }
}