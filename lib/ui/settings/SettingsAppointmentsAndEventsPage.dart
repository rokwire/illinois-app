/*
 * Copyright 2022 Board of Trustees of the University of Illinois.
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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/web_semantics.dart';

//TBD Update content
class SettingsAppointmentsAndEventsPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _SettingsAppointmentsAndEventsPageState();
}

class _SettingsAppointmentsAndEventsPageState extends State<SettingsAppointmentsAndEventsPage> {
  @override
  Widget build(BuildContext context) =>
    FocusTraversalGroup(policy: OrderedTraversalPolicy(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 16),
      ... _appointmentsSettings,
      Container(height: 32),
      ... _calendarSettings,
      Container(height: 32),
    ]));

  List<Widget> get _appointmentsSettings => <Widget>[
    Text(_appointmentsSectionTitle, style: _sectionTextStyle),
    Container(height: 4),
    WebFocusableSemanticsWidget(onSelect: _onToggleAppointmentsMcKinley, child: ToggleRibbonButton(
      title: _appointmentsSettingTitle,
      toggled: Storage().appointmentsCanDisplay ?? false,
      border: Border.all(color: Styles().colors.blackTransparent018, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(4)),
      onTap: _onToggleAppointmentsMcKinley
    ))
  ];

  String get _appointmentsSectionTitle =>
    Localization().getStringEx('panel.settings.home.appointments_and_events.appointments.section.text.format', 'Display appointments in the {{app_title}} app for:').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));

  String get _appointmentsSettingTitle =>
    Localization().getStringEx('panel.settings.home.appointments_and_events.appointments.mckinley.text', 'MyMcKinley');

  List<Widget> get _calendarSettings => <Widget>[
    Text(_calendarSectionTitle, style: _sectionTextStyle),
    Container(height: 4),
    WebFocusableSemanticsWidget(onSelect: _onToggleCalendarPrompt, child: ToggleRibbonButton(
      title: _calendarSettingTitle,
      toggled: Storage().calendarShouldPrompt,
      border: Border.all(color: Styles().colors.blackTransparent018, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(4)),
      onTap: _onToggleCalendarPrompt
    ))
  ];

  String get _calendarSectionTitle =>
    Localization().getStringEx('panel.settings.home.appointments_and_events.calendar.section.text', 'Add to My Device\'s Calendar');

  String get _calendarSettingTitle =>
      Localization().getStringEx('panel.settings.home.appointments_and_events.calendar.prompt.text', 'Prompt when saving events or appointments to my calendar');

  TextStyle? get _sectionTextStyle =>
    Styles().textStyles.getTextStyle("widget.detail.regular.fat");

  void _onToggleAppointmentsMcKinley() {
    Analytics().logSelect(target: 'MyMcKinley appointment settings');
    setStateIfMounted(() {
      Storage().appointmentsCanDisplay = !(Storage().appointmentsCanDisplay ?? false);
    });
  }

  void _onToggleCalendarPrompt() {
    Analytics().logSelect(target: 'Prompt when saving events to calendar');
    setStateIfMounted(() {
      Storage().calendarShouldPrompt = (Storage().calendarShouldPrompt != true);
    });
  }
}
