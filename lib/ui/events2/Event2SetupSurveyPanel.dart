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
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Event2SetupSurveyPanel extends StatefulWidget {
  final Event2SurveyDetails? details;

  Event2SetupSurveyPanel({Key? key, this.details}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2SetupSurveyPanelState();
}

class _Event2SetupSurveyPanelState extends State<Event2SetupSurveyPanel>  {

  late bool _hasSurvey;
  final TextEditingController _hoursController = TextEditingController();

  List<Survey>? _surveys;
  Survey? _selectedSurvey;
  bool _loadingSurveys = false;

  @override
  void initState() {
    _hasSurvey = widget.details?.hasSurvey ?? false;
    _hoursController.text = widget.details?.hoursAfterEvent?.toString() ?? '';
    _loadSurveys();
    super.initState();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: Localization().getStringEx('panel.event2.setup.survey.header.title', 'Event Follow-Up Survey'), onLeading: _onHeaderBack),
        body: _buildPanelContent(),
        backgroundColor: Styles().colors!.white);
  }

  Widget _buildPanelContent() {
    return SingleChildScrollView(
        child: Column(children: [
      Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildHasSurveySection(), _buildHoursSection(), _buildSurveysSection()]))
    ]));
  }

  // Has Survey

  Widget _buildHasSurveySection() {
    return Padding(
        padding: Event2CreatePanel.sectionPadding,
        child: ToggleRibbonButton(
          padding: EdgeInsets.zero,
          label: Localization().getStringEx('panel.event2.setup.survey.has_survey.toggle.title', 'SEND FOLLOW-UP SURVEY'),
          toggled: _hasSurvey,
          onTap: _onTapTakeFollowUpSurvey,
        ));
  }

  void _onTapTakeFollowUpSurvey() {
    Analytics().logSelect(target: "Toggle Send Follow-Up Survey");
    setStateIfMounted(() {
      _hasSurvey = !_hasSurvey;
      if (!_hasSurvey) {
        _hoursController.text = '';
      }
    });
  }

  // Hours

  Widget _buildHoursSection() => Visibility(
      visible: _hasSurvey,
      child: Padding(
          padding: Event2CreatePanel.sectionPadding,
          child: Row(children: [
            Flexible(flex: 3, child: Event2CreatePanel.buildSectionTitleWidget(
                Localization().getStringEx('panel.event2.setup.survey.hours.title', 'How many hours after the event ends before sending this survey to attendees?'), maxLines: 4)),
            Flexible(flex: 1, child: Padding(padding: EdgeInsets.only(left: 6), child: Event2CreatePanel.buildTextEditWidget(_hoursController, keyboardType: TextInputType.number, maxLines: 1)))
          ])));

  // Surveys

  void _loadSurveys() {
    setStateIfMounted(() {
      _loadingSurveys = true;
    });
    Surveys().loadSurveys().then((surveys) {
      _surveys = surveys;
      setStateIfMounted(() {
        _loadingSurveys = false;
      });
    });
  }

  Widget _buildSurveysSection() {
    if (_hasSurvey && _loadingSurveys) {
      return Padding(padding: Event2CreatePanel.dropdownButtonContentPadding, child: Center(child: CircularProgressIndicator()));
    }
    String title = Localization().getStringEx('panel.event2.setup.survey.survey.title', 'SURVEY');
    return Visibility(
        visible: _hasSurvey,
        child: Padding(
            padding: Event2CreatePanel.sectionPadding,
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Wrap(children: [Event2CreatePanel.buildSectionTitleWidget(title)])),
                Expanded(
                    child: Container(
                        decoration: Event2CreatePanel.dropdownButtonDecoration,
                        child: Padding(
                            padding: EdgeInsets.only(left: 12, right: 8),
                            child: DropdownButtonHideUnderline(
                                child: DropdownButton<Survey?>(
                                    icon: Styles().images?.getImage('chevron-down'),
                                    isExpanded: true,
                                    value: _selectedSurvey,
                                    style: Styles().textStyles?.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                                    hint: Text(StringUtils.ensureNotEmpty(_selectedSurvey?.title ?? _selectedSurvey?.id)),
                                    items: _buildSurveyDropDownItems(),
                                    onChanged: _onSurveyChanged)))))
              ]),
            ])));
  }

  List<DropdownMenuItem<Survey?>>? _buildSurveyDropDownItems() {
    List<DropdownMenuItem<Survey?>> items = <DropdownMenuItem<Survey?>>[];
    items.add(DropdownMenuItem<Survey?>(value: null, child: Text('---')));
    if (CollectionUtils.isNotEmpty(_surveys)) {
      for (Survey survey in _surveys!) {
        items.add(DropdownMenuItem<Survey?>(value: survey, child: Text(StringUtils.ensureNotEmpty(survey.title, defaultValue: survey.id))));
      }
    }
    return items;
  }

  void _onSurveyChanged(Survey? survey) {
    Analytics().logSelect(target: "Survey: ${(survey != null) ? survey.title : 'null'}");
    setStateIfMounted(() {
      _selectedSurvey = survey;
      //TBD: Preview selected survey
    });
  }

  // Submit

  void _onHeaderBack() {
    if (_hasSurvey) {

      int? hoursNumber = int.tryParse(_hoursController.text);
      if ((hoursNumber == null) || (hoursNumber < 0)) {
        AppAlert.showDialogResult(context, Localization().getStringEx('panel.event2.setup.survey.hours.invalid.msg', 'Please, fill valid non-negative number for hours.'));
        return;
      }
      //TBD: Ackolwedge _selectedSurvey

      Navigator.of(context).pop(Event2SurveyDetails(hasSurvey: true, hoursAfterEvent: hoursNumber));
    }
    else {
      Navigator.of(context).pop(null);
    }
  }
}
