import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Event2AttendanceTakerPanel extends StatelessWidget {
  final Event2? event;

  Event2AttendanceTakerPanel(this.event, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx('panel.event2.detail.attendance.header.title', 'Event Attendance')),
    body: Padding(padding: EdgeInsets.all(16), child:
      Event2AttendanceTakerWidget(event),
    ),
    backgroundColor: Styles().colors!.white,
  );
}

class Event2AttendanceTakerWidget extends StatefulWidget {
  final Event2? event;

  Event2AttendanceTakerWidget(this.event, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2AttendanceTakerWidgetState();
}

class _Event2AttendanceTakerWidgetState extends State<Event2AttendanceTakerWidget> {
  
  List<Event2Person>? _registrants;
  List<Event2Person>? _attendees;
  Set<String> _atendeesNetIds = <String>{};
  String? _errorMessage;

  bool _scanning = false;
  bool _loadingPeople = false;
  bool _attendeesSectionExpanded = false;

  @override
  void initState() {

    if (widget.event?.id != null) {
      _loadingPeople = true;
      Events2().loadEventPeople(widget.event!.id!).then((result) {
        if (mounted) {
          if (result is Event2PersonsResult) {
            setState(() {
              _loadingPeople = false;
              _registrants = result.registrants;
              _attendees = result.attendees;
              _atendeesNetIds = Event2Person.netIdsFromList(result.attendees) ?? <String>{};
            });
          }
          else {
            setState(() {
              _loadingPeople = false;
              _errorMessage = (result is String) ? result : _internalErrorString;
            });
          }
        }
      });
    }
    else {
      _errorMessage = _internalErrorString;
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  int? get _capacityNum => widget.event?.registrationDetails?.eventCapacity;
  int? get _registrationsNum => _registrants?.length;
  int? get _attendeesNum => _attendees?.length;
  bool get _hasError => (_errorMessage != null);
  bool get _isAdmin => (widget.event?.userRole == Event2UserRole.admin);
  String get _internalErrorString => Localization().getStringEx('logic.general.internal_error', 'Internal Error Occured');

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildEventDetailsSection(),
      _buildAttendeesListDropDownSection(),
      _buildScanIlliniIdSection()
    ]);
  }

  Widget _buildEventDetailsSection() => Event2CreatePanel.buildSectionWidget(
    body: Column(children: [
      _buildEventDetail(label: Localization().getStringEx('panel.event2.detail.attendance.event.capacity.label.title', 'EVENT CAPACITY:'), value: _capacityNum),
      _buildEventDetail(label: Localization().getStringEx('panel.event2.detail.attendance.event.registrations.label.title', 'TOTAL NUMBER OF REGISTRATIONS:'), value: _registrationsNum, loading: _loadingPeople, defaultValue: _hasError ? '-' : ''),
      _buildEventDetail(label: Localization().getStringEx('panel.event2.detail.attendance.event.attendees.label.title', 'TOTAL NUMBER OF ATTENDEES:'), value: _attendeesNum, loading: _loadingPeople, defaultValue: _hasError ? '-' : ''),
      StringUtils.isNotEmpty(_errorMessage) ? _buildErrorStatus(_errorMessage ?? '') : Container(),
    ],),
  );
  
  Widget _buildEventDetail({required String label, int? value, bool? loading, String defaultValue = ''}) {
    return Padding(padding: Event2CreatePanel.innerSectionPadding, child:
      Semantics(label: label, header: true, excludeSemantics: true, child:
        Row(children: [
          Expanded(child:
            Event2CreatePanel.buildSectionTitleWidget(label)
          ),
          (loading == true) ?
            SizedBox(width: 16, height: 16, child:
              CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 2,),
            ) :
            Text(value?.toString() ?? defaultValue, style: Styles().textStyles?.getTextStyle('widget.label.medium.fat'))
        ])
      )
    );
  }

  Widget _buildErrorStatus(String errorText) {
    TextStyle? boldStyle = Styles().textStyles?.getTextStyle("panel.settings.error.text");
    TextStyle? regularStyle = Styles().textStyles?.getTextStyle("panel.settings.error.text.small");
    return Row(children: [
      Expanded(child:
        RichText(text: TextSpan(style: regularStyle, children: <InlineSpan>[
          TextSpan(text: Localization().getStringEx('logic.general.error', 'Error') + ': ', style: boldStyle,),
          TextSpan(text: errorText, style: regularStyle,),
        ]))
      )
    ],);
  }

  Widget _buildAttendeesListDropDownSection() => Event2CreatePanel.buildDropdownSectionWidget(
    heading: Event2CreatePanel.buildDropdownSectionHeadingWidget(Localization().getStringEx('panel.event2.detail.attendance.attendees.drop_down.hint', 'ATTENDEE LIST'),
      expanded: _attendeesSectionExpanded,
      onToggleExpanded: _onToggleAttendeesListSection,
    ),
    body: _buildAttendeesListSectionBody(),
    bodyPadding: EdgeInsets.zero,
    expanded: _attendeesSectionExpanded,
    trailing: _isAdmin ? _buildUploadAttendeesDescription() : null,
  );


  void _onToggleAttendeesListSection() {
    Analytics().logSelect(target: "Toggle Attendees List");
    setStateIfMounted(() {
      _attendeesSectionExpanded = !_attendeesSectionExpanded;
    });
  }

  Widget _buildAttendeesListSectionBody() {
    List<Widget> contentList = <Widget>[];
    if (_registrants != null) {
      for (Event2Person registrant in _registrants!) {
        if (contentList.isNotEmpty) {
          contentList.add(Divider(color: Styles().colors?.dividerLineAccent, thickness: 1, height: 1,));
        }
        contentList.add(_RegistrantWidget(registrant,
          selected: _atendeesNetIds.contains(registrant.identifier?.netId),
          onTap: () => _onTapRegistrant(registrant),
        ));
      }
    }
    return Column(mainAxisSize: MainAxisSize.max, children: contentList,);
  }

  void _onTapRegistrant(Event2Person registrant) {
    Analytics().logSelect(target: "Toggle Registrant");
    String? registrantNetId = registrant.identifier?.netId;
    if (registrantNetId != null) {
      setState(() {
        if (_atendeesNetIds.contains(registrantNetId)) {
          _atendeesNetIds.remove(registrantNetId);
        }
        else {
          _atendeesNetIds.add(registrantNetId);
        }
      });
    }
  }

  Widget _buildUploadAttendeesDescription() {
    TextStyle? mainStyle = Styles().textStyles?.getTextStyle('widget.item.small.thin.italic');
    final Color defaultStyleColor = Colors.red;
    final String adminAppUrl = 'go.illinois.edu/ILappAdmin'; //TBD: DD - move it to config
    final String adminAppUrlMacro = '{{admin_app_url}}';
    String contentHtml = Localization().getStringEx('panel.event2.detail.attendance.attendees.description', "Looking for a way to upload an attendee list or download your current attendees? Share the link or visit <a href='{{admin_app_url}}'>{{admin_app_url}}</a>.");
    contentHtml = contentHtml.replaceAll(adminAppUrlMacro, adminAppUrl);
    return Padding(padding: EdgeInsets.only(top: 12), child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Styles().images?.getImage('info') ?? Container(),
        Expanded(child:
          Padding(padding: EdgeInsets.only(left: 6), child:
            HtmlWidget(contentHtml, onTapUrl: _onTapHtmlLink, textStyle: mainStyle,
              customStylesBuilder: (element) => (element.localName == "a") ? { "color": ColorUtils.toHex(mainStyle?.color ?? defaultStyleColor), "text-decoration-color": ColorUtils.toHex(Styles().colors?.fillColorSecondary ?? defaultStyleColor)} : null,
            )
          ),
        ),
      ])
    );
  }

  bool _onTapHtmlLink(String? url) {
    Analytics().logSelect(target: '($url)');
    UrlUtils.launchExternal(url);
    return true;
  }

  Widget _buildScanIlliniIdSection() => Event2CreatePanel.buildSectionWidget(
    body: RoundedButton(
      label: Localization().getStringEx('panel.event2.detail.attendance.scan.button', 'Scan Illini ID'),
      textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
      onTap: _onTapScanButton,
      backgroundColor: Styles().colors!.white,
      borderColor: Styles().colors!.fillColorSecondary,
      contentWeight: 0.5,
      progress: _scanning,
    ),
  );

  void _onTapScanButton() {
    Analytics().logSelect(target: 'Scan Illini Id');
    if (!_scanning) {
      setState(() {
        _scanning = true;
      });
      
      String lineColor = UiColors.toHex(Styles().colors?.fillColorSecondary) ?? '#E84A27';
      String cancelButtonTitle = Localization().getStringEx('panel.event2.detail.attendance.scan.cancel.button.title', 'Cancel');
      FlutterBarcodeScanner.scanBarcode(lineColor, cancelButtonTitle, true, ScanMode.QR).then((String scanResult) {
        if (mounted) {
          setState(() {
            _scanning = false;
          });
          _onScanFinished(scanResult);
        }
      });
    }
  }

  void _onScanFinished(String scanResult) {
    if (scanResult != '-1') { // The user did not hit "Cancel button"
      String? uin = _extractUin(scanResult);
      if (uin != null) {
        AppAlert.showDialogResult(context, 'Scanned UIN: $uin.');
      }
      else {
        AppAlert.showDialogResult(context, Localization().getStringEx('panel.event2.detail.attendance.qr_code.uin.not_valid.msg', 'This QR code does not contain valid UIN number.'));
      }
    }
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
}

class _RegistrantWidget extends StatelessWidget {
  final Event2Person registrant;
  final bool? selected;
  final void Function()? onTap;
  
  _RegistrantWidget(this.registrant, { Key? key, this.selected, this.onTap }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 16), child:
          _nameWidget
        )
      ),
      InkWell(onTap: onTap, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
          _checkMarkWidget
        ),
      )
    ],);

  }

  Widget get _nameWidget {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    TextStyle? boldStyle = Styles().textStyles?.getTextStyle("widget.card.title.small.fat");
    TextStyle? regularStyle = Styles().textStyles?.getTextStyle("widget.card.title.small");
    String? registrantNetId = registrant.identifier?.netId;
    if (registrantNetId != null) {
      descriptionList.add(TextSpan(text: registrantNetId, style: boldStyle,));
    }
    return RichText(text: TextSpan(style: regularStyle, children: descriptionList));
  }

  Widget get _checkMarkWidget {
    return Styles().images?.getImage((selected == true) ? 'check-circle-filled' : 'circle-outline') ?? Container();
  }
}

