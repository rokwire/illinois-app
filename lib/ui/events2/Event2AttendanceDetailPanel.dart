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
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
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
  final TextEditingController _attendeeNetIdsController = TextEditingController();
  bool _scanning = false;

  @override
  void initState() {
    _scanningEnabled = widget.event?.attendanceDetails?.scanningEnabled ?? false;
    _manualCheckEnabled = widget.event?.attendanceDetails?.manualCheckEnabled ?? false;
    super.initState();
  }

  @override
  void dispose() {
    _attendeeNetIdsController.dispose();
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
    return SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildSetupContent(), _buildEventDetailsContent(), _buildImportAdditionalAttendeesContent()]));
  }

  Widget _buildSetupContent() {
    return Visibility(
        visible: _isAdmin,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(left: _mainHorizontalPadding, top: _mainVerticalPadding, right: _mainHorizontalPadding),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildScanSection(), _buildManualSection()])),
          _dividerWidget
        ]));
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
            label: Localization().getStringEx('panel.event2.detail.attendance.manual.toggle.title', 'Allow manual attendance taking'),
            hint: Localization().getStringEx('panel.event2.detail.attendance.manual.toggle.hint', ''),
            child: ToggleRibbonButton(
                padding: EdgeInsets.zero,
                label: Localization().getStringEx('panel.event2.detail.attendance.manual.toggle.title', 'Allow manual attendance taking'),
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

  Widget _buildEventDetailsContent() {
    return Visibility(visible: (_isAdmin || _isAttendanceTaker), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
    ]));
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
                            Localization().getStringEx('panel.event2.detail.attendance.attendees.drop_down.hint', 'GUEST LIST')),
                        items: null,
                        onChanged: null)))));
  }

  Widget _buildUploadAttendeesDescription() {
    TextStyle? mainStyle = Styles().textStyles?.getTextStyle('panel.event.attendance.detail.description.italic');
    final Color defaultStyleColor = Colors.red;
    final String? eventAttendanceUrl = Config().eventAttendanceUrl;
    final String eventAttendanceUrlMacro = '{{event_attendance_url}}';
    String contentHtml = Localization().getStringEx('panel.event2.detail.attendance.attendees.description',
        "Visit <a href='{{event_attendance_url}}'>{{event_attendance_url}}</a> to upload or download a list.");
    contentHtml = contentHtml.replaceAll(eventAttendanceUrlMacro, eventAttendanceUrl ?? '');
    return Visibility(
        visible: _isAdmin && StringUtils.isNotEmpty(eventAttendanceUrl),
        child: Padding(
            padding: EdgeInsets.only(left: _mainHorizontalPadding, top: 20, right: _mainHorizontalPadding),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: EdgeInsets.only(right: 8.8), child: Styles().images?.getImage('info')),
              Expanded(
                  child: HtmlWidget(StringUtils.ensureNotEmpty(contentHtml),
                      onTapUrl: (url) {
                        _onTapHtmlLink(url);
                        return true;
                      },
                      textStyle: mainStyle,
                      customStylesBuilder: (element) => (element.localName == "a")
                          ? {
                              "color": ColorUtils.toHex(mainStyle?.color ?? defaultStyleColor),
                              "text-decoration-color": ColorUtils.toHex(Styles().colors?.fillColorSecondary ?? defaultStyleColor)
                            }
                          : null))
            ])));
  }

  void _onTapHtmlLink(String? url) {
    Analytics().logSelect(target: '($url)');
    UrlUtils.launchExternal(url);
  }

  Widget _buildScanIlliniIdButton() {
    return Padding(
        padding: EdgeInsets.only(left: _mainHorizontalPadding, top: 39, right: _mainHorizontalPadding),
        child: Stack(alignment: Alignment.center, children: [
          RoundedButton(
              label: Localization().getStringEx('panel.event2.detail.attendance.scan.button', 'Scan Illini ID'),
              textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
              onTap: _onTapScanButton,
              backgroundColor: Styles().colors!.white,
              borderColor: Styles().colors!.fillColorSecondary,
              contentWeight: 0.5),
          Visibility(visible: _scanning, child: CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 1))
        ]));
  }

  void _onTapScanButton() {
    Analytics().logSelect(target: 'Scan Illini Id');
    if (_scanning) {
      return;
    }
    setStateIfMounted(() {
      _scanning = true;
    });
    FlutterBarcodeScanner.scanBarcode(UiColors.toHex(Styles().colors!.fillColorSecondary!)!,
            Localization().getStringEx('panel.event2.detail.attendance.scan.cancel.button.title', 'Cancel'), true, ScanMode.QR)
        .then((scanResult) {
      _onScanFinished(scanResult);
      setStateIfMounted(() {
        _scanning = false;
      });
    });
  }

  void _onScanFinished(String? scanResult) {
    if (scanResult == '-1') {
      // The user hit "Cancel button"
      return;
    }
    String? uin = _extractUin(scanResult);
    // There is no uin in the scanned QRcode
    if (uin == null) {
      AppAlert.showDialogResult(
          context, Localization().getStringEx('panel.event2.detail.attendance.qr_code.uin.not_valid.msg', 'This QR code does not contain valid UIN number.'));
      return;
    }
    //TBD: DD - check with backend team what we should do with the extracted UIN and implement it
    AppAlert.showDialogResult(context, 'The UIN is: $uin.');
  }

  ///
  /// Returns UIN number from string (uin or megTrack2), null - otherwise
  ///
  String? _extractUin(String? stringToCheck) {
    if (StringUtils.isEmpty(stringToCheck)) {
      return stringToCheck;
    }
    int stringSymbolsCount = stringToCheck!.length;
    final int uinNumbersCount = 9;
    final int megTrack2SymbolsCount = 28;
    // Validate UIN in format 'XXXXXXXXX'
    if (stringSymbolsCount == uinNumbersCount) {
      RegExp uinRegEx = RegExp('[0-9]{$uinNumbersCount}');
      bool uinMatch = uinRegEx.hasMatch(stringToCheck);
      return uinMatch ? stringToCheck : null;
    }
    // Validate megTrack2 in format 'AAAAXXXXXXXXXAAA=AAAAAAAAAAA' where 'XXXXXXXXX' is the UIN
    else if (stringSymbolsCount == megTrack2SymbolsCount) {
      RegExp megTrack2RegEx = RegExp('[0-9]{4}[0-9]{$uinNumbersCount}[0-9]{3}=[0-9]{11}');
      bool megTrackMatch = megTrack2RegEx.hasMatch(stringToCheck);
      if (megTrackMatch) {
        String uin = stringToCheck.substring(4, 13);
        return uin;
      } else {
        return null;
      }
    }
    return null;
  }

  Widget _buildImportAdditionalAttendeesContent() {
    return Visibility(visible: _isAdmin, child: Padding(padding: EdgeInsets.only(top: 32), child: Column(children: [
      Padding(padding: Event2CreatePanel.innerSectionPadding, child: _dividerWidget),
      _buildAttendeesInputSection(),
      _buildAttendeesInputDescriptionSection()
    ])));
  }

  Widget _buildAttendeesInputSection() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: _mainHorizontalPadding), child: Event2CreatePanel.buildSectionWidget(
        heading: Event2CreatePanel.buildSectionHeadingWidget(
            Localization().getStringEx('panel.event2.detail.attendance.additional.netids.label', 'Netids for additional attendance takers:')),
        body: Event2CreatePanel.buildTextEditWidget(_attendeeNetIdsController, keyboardType: TextInputType.text, maxLines: 1),
        padding: EdgeInsets.only(bottom: 7)));
  }

  Widget _buildAttendeesInputDescriptionSection() {
    TextStyle? mainStyle = Styles().textStyles?.getTextStyle('panel.event.attendance.detail.description.italic');
    final Color defaultStyleColor = Colors.red;
    final String? eventAttendanceUrl = Config().eventAttendanceUrl;
    final String eventAttendanceUrlMacro = '{{event_attendance_url}}';
    String contentHtml = Localization()
        .getStringEx('panel.event2.detail.attendance.attendees.netids.description', "Upload a list at <a href='$eventAttendanceUrlMacro'>$eventAttendanceUrlMacro</a>.");
    contentHtml = contentHtml.replaceAll(eventAttendanceUrlMacro, eventAttendanceUrl ?? '');
    return Visibility(visible: StringUtils.isNotEmpty(eventAttendanceUrl),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _mainHorizontalPadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: HtmlWidget(StringUtils.ensureNotEmpty(contentHtml),
                    onTapUrl: (url) {
                      _onTapHtmlLink(url);
                      return true;
                    },
                    textStyle: mainStyle,
                    customStylesBuilder: (element) => (element.localName == "a")
                        ? {
                            "color": ColorUtils.toHex(mainStyle?.color ?? defaultStyleColor),
                            "text-decoration-color": ColorUtils.toHex(Styles().colors?.fillColorSecondary ?? defaultStyleColor)
                          }
                        : null))
          ]),
        ])));
  }

  void _onTapBack() {
    Analytics().logSelect(target: 'Back');
    Navigator.of(context).pop();
    //TBD: DD - implement
  }

  Widget get _dividerWidget => Divider(color: Styles().colors?.dividerLineAccent, thickness: 1);

  bool get _isAdmin => (widget.event?.userRole == Event2UserRole.admin);

  bool get _isAttendanceTaker => (widget.event?.userRole == Event2UserRole.attendanceTaker);
}
