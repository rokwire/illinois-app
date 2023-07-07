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
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Event2AttendanceDetailPanel extends StatefulWidget {
  final Event2? event;

  Event2AttendanceDetailPanel({Key? key, this.event}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2AttendanceDetailPanelState();
}

class _Event2AttendanceDetailPanelState extends State<Event2AttendanceDetailPanel> {
  static const double _mainHorizontalPadding = 25;
  static const double _mainVerticalPadding = 24;

  late bool _scanningEnabled;
  late bool _manualCheckEnabled;

  @override
  void initState() {
    _scanningEnabled = widget.event?.attendanceDetails?.scanningEnabled ?? false;
    _manualCheckEnabled = widget.event?.attendanceDetails?.manualCheckEnabled ?? false;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.event2.detail.attendance.header.title', 'Event Attendance'), onLeading: _onTapBack),
      body: _buildPanelContent(),
      backgroundColor: Styles().colors!.white,
    );
  }

  Widget _buildPanelContent() {
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildSetupContent(), _buildEventDetails()]));
  }

  Widget _buildSetupContent() {
    if (!_isEventAdmin) {
      return Container();
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: EdgeInsets.only(left: _mainHorizontalPadding, top: _mainVerticalPadding, right: _mainHorizontalPadding),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildScanSection(), _buildManualSection()])),
      _dividerWidget
    ]);
  }

  Widget _buildScanSection() {
    return Padding(
        padding: Event2CreatePanel.sectionPadding,
        child: Semantics(
            toggled: _scanningEnabled,
            excludeSemantics: true,
            label: Localization().getStringEx('panel.event2.detail.attendance.scan.toggle.title', 'Scan Illini ID'),
            hint: Localization().getStringEx('panel.event2.detail.attendance.scan.toggle.hint', ''),
            child: ToggleRibbonButton(
                padding: EdgeInsets.zero,
                label: Localization().getStringEx('panel.event2.detail.attendance.scan.toggle.title', 'Scan Illini ID'),
                description: Localization().getStringEx('panel.event2.detail.attendance.scan.toggle.description', 'Does not require advance registration.'),
                toggled: _scanningEnabled,
                onTap: _onTapScanToggle)));
  }

  void _onTapScanToggle() {
    Analytics().logSelect(target: 'Toggle Scan Illini ID');
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _scanningEnabled = !_scanningEnabled;
    });
  }

  Widget _buildManualSection() {
    return Padding(
        padding: Event2CreatePanel.sectionPadding,
        child: Semantics(
            toggled: _manualCheckEnabled,
            excludeSemantics: true,
            label: Localization().getStringEx('panel.event2.detail.attendance.manual.toggle.title', 'Allow manual attendance check'),
            hint: Localization().getStringEx('panel.event2.detail.attendance.manual.toggle.hint', ''),
            child: ToggleRibbonButton(
                padding: EdgeInsets.zero,
                label: Localization().getStringEx('panel.event2.detail.attendance.manual.toggle.title', 'Allow manual attendance check'),
                description: Localization().getStringEx('panel.event2.detail.attendance.manual.toggle.description', 'Requires advance registration.'),
                toggled: _manualCheckEnabled,
                onTap: _onTapManual)));
  }

  void _onTapManual() {
    Analytics().logSelect(target: 'Toggle Manual Check');
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _manualCheckEnabled = !_manualCheckEnabled;
    });
  }

  Widget _buildEventDetails() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildEventDetailSection(
          label: Localization().getStringEx('panel.event2.detail.attendance.event.capacity.label.title', 'EVENT CAPACITY:'),
          value: widget.event?.registrationDetails?.eventCapacity),
      _buildEventDetailSection(
          label: Localization().getStringEx('panel.event2.detail.attendance.event.registrations.label.title', 'TOTAL NUMBER OF REGISTRATIONS:'), value: null),//TBD: read registrations from event2 model
      _buildEventDetailSection(
          label: Localization().getStringEx('panel.event2.detail.attendance.event.attendees.label.title', 'TOTAL NUMBER OF ATTENDEES:'), value: null),//TBD: read attendees from event2 model
      _buildAttendeesDropDown(),
      _buildUploadAttendeesDescription(),
      _buildScanIlliniIdButton()
    ]);
  }

  Widget _buildEventDetailSection({required String label, int? value}) {
    return Padding(
        padding: Event2CreatePanel.innerSectionPadding,
        child: Semantics(
            label: label,
            header: true,
            excludeSemantics: true,
            child: Padding(
                padding: EdgeInsets.only(left: _mainHorizontalPadding, top: 4, right: _mainHorizontalPadding),
                child: Row(children: [
                  Expanded(child: Event2CreatePanel.buildSectionTitleWidget(label)),
                  _buildDetailNumber(value)
                ]))));
  }

  Widget _buildDetailNumber(int? number) {
    return Text(StringUtils.ensureNotEmpty(number?.toString(), defaultValue: '-'), style: Styles().textStyles?.getTextStyle('widget.label.medium.fat'));
  }

  //TBD: DD - fill with proper data when we know where to retrieve it from. Handle drop-down item selection when we know what exactly to do.
  Widget _buildAttendeesDropDown() {
    return Padding(
        padding: EdgeInsets.only(left: _mainHorizontalPadding, top: 16, right: _mainHorizontalPadding),
        child: Container(
            decoration: Event2CreatePanel.dropdownButtonDecoration,
            child: Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: DropdownButtonHideUnderline(
                    child: DropdownButton<dynamic>(
                        icon: Styles().images?.getImage('chevron-down'),
                        isExpanded: true,
                        style: Styles().textStyles?.getTextStyle('panel.create_event.dropdown_button.title.regular'),
                        hint: Event2CreatePanel.buildSectionTitleWidget(
                            Localization().getStringEx('panel.event2.detail.attendance.attendees.drop_down.hint', 'ATTENDEE LIST')),
                        items: null,
                        onChanged: null)))));
  }

  Widget _buildUploadAttendeesDescription() {
    //TBD: DD - implement
    return Visibility(visible: _isEventAdmin, child: Container());
  }

  Widget _buildScanIlliniIdButton() {
    return Padding(
        padding: EdgeInsets.only(left: _mainHorizontalPadding, top: 39, right: _mainHorizontalPadding),
        child: RoundedButton(
            label: Localization().getStringEx('panel.event2.detail.attendance.scan.button', 'Scan Illini ID'),
            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
            onTap: _onTapScanButton,
            backgroundColor: Styles().colors!.white,
            borderColor: Styles().colors!.fillColorSecondary,
            contentWeight: 0.5));
  }

  void _onTapScanButton() {
    Analytics().logSelect(target: 'Scan Illini Id');
    //TBD: DD - implement when we know what to do
  }

  void _onTapBack() {
    Navigator.of(context).pop();
    //TBD: DD - implement
  }

  Widget get _dividerWidget => Divider(color: Styles().colors?.dividerLineAccent, thickness: 1);

  bool get _isEventAdmin => (widget.event?.userRole == Event2UserRole.admin);
}
