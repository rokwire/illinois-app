//import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
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
  final StreamController<String> _updateController = StreamController.broadcast();

  Event2AttendanceTakerPanel(this.event, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx('panel.event2.detail.attendance.header.title', 'Event Attendance')),
    body: RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
        Padding(padding: EdgeInsets.all(16), child:
          Event2AttendanceTakerWidget(event, updateController: _updateController,),
        ),
      ),
    ),
    backgroundColor: Styles().colors!.white,
  );

  Future<void> _onRefresh() async {
    _updateController.add(Event2AttendanceTakerWidget.notifyRefresh);
  }
}

class Event2AttendanceTakerWidget extends StatefulWidget {
  static const String notifyRefresh = "edu.illinois.rokwire.event2.attendance_taker.refresh";

  final Event2? event;
  final StreamController<String>? updateController;

  Event2AttendanceTakerWidget(this.event, { Key? key, this.updateController }) : super(key: key);

  bool get scanEnabled => event?.attendanceDetails?.scanningEnabled ?? false;
  bool get manualCheckEnabled => event?.attendanceDetails?.manualCheckEnabled ?? false;

  @override
  State<StatefulWidget> createState() => _Event2AttendanceTakerWidgetState();
}

class _Event2AttendanceTakerWidgetState extends State<Event2AttendanceTakerWidget> {
  
  Event2PersonsResult? _persons;
  List<Event2Person> _displayList = <Event2Person>[];
  Set<String> _atendeesNetIds = <String>{};
  Set<String> _processingNetIds = <String>{};
  String? _processedNetId;
  Timer? _processedTimer;
  String? _errorMessage;

  bool _scanning = false;
  bool _loadingPeople = false;
  bool _attendeesSectionExpanded = false;

  @override
  void initState() {

    widget.updateController?.stream.listen((String command) {
      if (command == Event2AttendanceTakerWidget.notifyRefresh) {
        _refresh();
      }
    });

    String? eventId = widget.event?.id;
    if (eventId != null) {
      _loadingPeople = true;
      Events2().loadEventPeople(eventId).then((result) {
        if (mounted) {
          if (result is Event2PersonsResult) {
            setState(() {
              _loadingPeople = false;
              _persons = result;
              _displayList = result.buildDisplayList();
              _atendeesNetIds = Event2Person.netIdsFromList(result.attendees) ?? <String>{};
            });
          }
          else {
            setState(() {
              _loadingPeople = false;
              _errorMessage = StringUtils.isNotEmptyString(result) ? result : _internalErrorString;
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
    _processedTimer?.cancel();
    _processedTimer = null;
    super.dispose();
  }

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
      _buildEventDetail(label: Localization().getStringEx('panel.event2.detail.attendance.event.capacity.label.title', 'EVENT CAPACITY:'), value: widget.event?.registrationDetails?.eventCapacity),
      _buildEventDetail(label: Localization().getStringEx('panel.event2.detail.attendance.event.registrations.label.title', 'TOTAL NUMBER OF REGISTRATIONS:'), value: _persons?.registrants?.length, loading: _loadingPeople, defaultValue: _hasError ? '-' : ''),
      _buildEventDetail(label: Localization().getStringEx('panel.event2.detail.attendance.event.attendees.label.title', 'TOTAL NUMBER OF ATTENDEES:'), value: (_persons?.attendees != null) ? _atendeesNetIds.length : null, loading: _loadingPeople, defaultValue: _hasError ? '-' : ''),
      StringUtils.isNotEmpty(_errorMessage) ? _buildErrorStatus(_errorMessage ?? '') : Container(),
    ],),
  );
  
  Widget _buildEventDetail({required String label, int? value, bool? loading, String defaultValue = ''}) {
    String valueLabel = value?.toString() ?? defaultValue;
    String semanticsLabel = "$label: $valueLabel";

    return Padding(padding: Event2CreatePanel.innerSectionPadding, child:
      Semantics(label: semanticsLabel, excludeSemantics: true, child:
        Row(children: [
          Expanded(child:
            Event2CreatePanel.buildSectionTitleWidget(label)
          ),
          (loading == true) ?
            Padding(padding: EdgeInsets.all(2.5), child:
              SizedBox(width: 16, height: 16, child:
                CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 2,),
              ),
            ) :
            Text(valueLabel, style: Styles().textStyles?.getTextStyle('widget.label.medium.fat'),)
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
    for (Event2Person displayPerson in _displayList) {
      if (contentList.isNotEmpty) {
        contentList.add(Divider(color: Styles().colors?.dividerLineAccent, thickness: 1, height: 1,));
      }
      contentList.add(_AttendeeListItemWidget(displayPerson,
        enabled: widget.manualCheckEnabled,
        selected: _atendeesNetIds.contains(displayPerson.identifier?.netId),
        processing: _processingNetIds.contains(displayPerson.identifier?.netId),
        highlighted: (_processedNetId == displayPerson.identifier?.netId),
        onTap: () => _onTapAttendeeListItem(displayPerson),
      ));
    }
    if (_loadingPeople) {
      return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
        Center(child:
          SizedBox(width: 24, height: 24, child:
            CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3,)
          ),
        ),
      );
    }
    if (0 < contentList.length) {
      return Column(mainAxisSize: MainAxisSize.max, children: contentList,);
    }
    else {
      return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
        Row(children: [
          Expanded(child:
            Text(_hasError ?
              Localization().getStringEx("panel.event2.detail.attendance.attendees.failed.text", "Failed to load attendees list.") :
              Localization().getStringEx("panel.event2.detail.attendance.attendees.empty.text", "There are no users registered or attending for this event yet."),
              textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle('widget.item.small.thin.italic'),),
          )
        ],)
      );
    }
  }

  void _onTapAttendeeListItem(Event2Person person) {
    Analytics().logSelect(target: "Toggle Attendee");
    String? eventId = widget.event?.id;
    String? personNetId = person.identifier?.netId;
    if (widget.manualCheckEnabled != true) {
      Event2Popup.showMessage(context,
        Localization().getStringEx("panel.event2.detail.attendance.message.not_available.title", "Not Available"),
        Localization().getStringEx("panel.event2.detail.attendance.manual_check.disabled", "Manual check is not enabled for this event."));
    }
    else if ((eventId != null) && (personNetId != null) && !_processingNetIds.contains(personNetId))  {

      setState(() {
        _processingNetIds.add(personNetId);
      });

      if (_atendeesNetIds.contains(personNetId)) {
        Events2().unattendEvent(eventId, personIdentifier: person.identifier).then((dynamic result) {
          if (mounted) {
              setState(() {
                _processingNetIds.remove(personNetId);
              });

            if (result == true) {
              setState(() {
                _atendeesNetIds.remove(personNetId);
                if (personNetId == _processedNetId) {
                  _processedNetId = null;
                }
              });
            }
            else {
              Event2Popup.showErrorResult(context, result);
            }
          }
        });
      }
      else {
        Events2().attendEvent(eventId, personIdentifier: person.identifier).then((dynamic result) {
          if (mounted) {
            setState(() {
              _processingNetIds.remove(personNetId);
            });
            if (result is Event2Person) {
              setState(() {
                _atendeesNetIds.add(personNetId);
              });
            }
            else {
              Event2Popup.showErrorResult(context, result);
            }
          }
        });
      }
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

  Widget _buildScanIlliniIdSection() => Event2CreatePanel.buildSectionWidget(body:
    RoundedButton(
      label: Localization().getStringEx('panel.event2.detail.attendance.scan.button', 'Scan Illini ID'),
      textStyle: Styles().textStyles?.getTextStyle(widget.scanEnabled ? 'widget.button.title.large.fat' : 'widget.button.title.large.fat.variant3'),
      borderColor: widget.scanEnabled ? Styles().colors!.fillColorSecondary : Styles().colors?.surfaceAccent,
      backgroundColor: Styles().colors!.white,
      onTap: _onTapScanButton,
      contentWeight: 0.5,
      progress: _scanning,
    ),);

  void _onTapScanButton() {
    Analytics().logSelect(target: 'Scan Illini Id');
    if (widget.scanEnabled != true) {
      Event2Popup.showMessage(context,
        Localization().getStringEx("panel.event2.detail.attendance.message.not_available.title", "Not Available"),
        Localization().getStringEx("panel.event2.detail.attendance.scan.disabled", "Scanning Illini ID is not enabled for this event."));
    }
    else if (!_scanning) {
      setState(() {
        _scanning = true;
      });

      /* TMP Future.delayed(Duration(seconds: 1)).then((_) {
        int uin = 100000000 + Random().nextInt(900000000);
        _onScanFinished("$uin");
      }); */
      
      String lineColor = UiColors.toHex(Styles().colors?.fillColorSecondary) ?? '#E84A27';
      String cancelButtonTitle = Localization().getStringEx('panel.event2.detail.attendance.scan.cancel.button.title', 'Cancel');
      FlutterBarcodeScanner.scanBarcode(lineColor, cancelButtonTitle, true, ScanMode.QR).then((String scanResult) {
        if (mounted) {
          _onScanFinished(scanResult);
        }
      });
    }
  }

  void _onScanFinished(String scanResult) {
    if (scanResult != '-1') { // The user did not hit "Cancel button"
      String? uin = _extractUin(scanResult);
      String? eventId = widget.event?.id;
      if (uin == null) {
        setState(() {
          _scanning = false;
        });
        Event2Popup.showErrorResult(context, Localization().getStringEx('panel.event2.detail.attendance.qr_code.uin.not_valid.msg', 'This QR code does not contain valid UIN number.'));
      }
      else if (eventId == null) {
        setState(() {
          _scanning = false;
        });

        Event2Popup.showErrorResult(context, _internalErrorString);
      }
      else {
        Events2().attendEvent(eventId, uin: uin).then((result) {
          if (mounted) {
            setState(() {
              _scanning = false;
            });

            String? attendeeNetId = (result is Event2Person) ? result.identifier?.netId : null;
            if (attendeeNetId != null) {

              List<Event2Person>? displayList;
              if (!Event2Person.containsInList(_displayList, netId: attendeeNetId)) {
                displayList = List.from(_displayList);
                displayList.add(result);
                displayList.sort((Event2Person person1, Event2Person person2) =>
                  SortUtils.compare(person1.identifier?.netId, person2.identifier?.netId));
              }

              setState(() {
                _atendeesNetIds.add(attendeeNetId);
                if (displayList != null) {
                  _displayList = displayList;
                }
                _processedNetId = attendeeNetId;
              });
              _setupProcessedTimer();
            }
            else {
              Event2Popup.showErrorResult(context, result);
            }
          }
        });
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

  void _setupProcessedTimer() {
    if (_processedTimer != null) {
      _processedTimer?.cancel();
    }
    _processedTimer = Timer(Duration(seconds: 3), (){
      _processedTimer = null;
      if (mounted) {
        setState(() {
          _processedNetId = null;
        });
      }
    });
  }

  Future<void> _refresh() async {
    String? eventId = widget.event?.id;
    if (eventId != null) {
      setStateIfMounted(() {
        _loadingPeople = true;
      });
      dynamic result = await Events2().loadEventPeople(eventId);
      if (mounted) {
        if (result is Event2PersonsResult) {
          setState(() {
            _loadingPeople = false;
            _persons = result;
            _displayList = result.buildDisplayList();
            _atendeesNetIds = Event2Person.netIdsFromList(result.attendees) ?? <String>{};
          });
        }
        else {
          setState(() {
            _loadingPeople = false;
            _errorMessage = StringUtils.isNotEmptyString(result) ? result : _internalErrorString;
          });
        }
      }
    }
  }
}

class _AttendeeListItemWidget extends StatelessWidget {
  final Event2Person registrant;
  final bool enabled;
  final bool selected;
  final bool processing;
  final bool highlighted;
  final void Function()? onTap;
  
  _AttendeeListItemWidget(this.registrant, { Key? key, this.enabled = true, this.selected = false, this.processing = false, this.highlighted = false, this.onTap }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 16), child:
          _nameWidget
        )
      ),
      
      (processing != true) ? InkWell(onTap: onTap, child: _checkMarkWidget) : _progressMarkWidget,
    ],);

  }

  Widget get _nameWidget {
    String? registrantNetId = registrant.identifier?.netId;
    String textStyleKey = (enabled ? (highlighted ? 'widget.label.regular.fat' : 'widget.card.title.small.fat') : 'widget.card.title.small.fat.variant3');
    return Text(registrantNetId ?? '', style: Styles().textStyles?.getTextStyle(textStyleKey));
  }

  Widget get _checkMarkWidget => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
    Styles().images?.getImage(_checkMarkImageKey) ?? Container()
  );

  String get _checkMarkImageKey {
    if (enabled) {
      if (highlighted == true) {
        return 'check-circle-outline';
      }
      else if (selected == true) {
        return 'check-circle-filled';
      }
    }
    return 'circle-outline-gray';
  }

  Widget get _progressMarkWidget => Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18), child:
    SizedBox(width: 20, height: 20, child:
      CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 2,)
    )
  );
}

extension Event2PersonsResultExt on Event2PersonsResult {
  List<Event2Person> buildDisplayList() {
    List<Event2Person> displayList = <Event2Person>[];
    Set<String> displayNetIds  = <String>{};

    if (registrants != null) {
      for (Event2Person registrant in registrants!) {
        String? registrantNetId = registrant.identifier?.netId;
        if ((registrantNetId != null) && !displayNetIds.contains(registrantNetId)) {
          displayList.add(registrant);
          displayNetIds.add(registrantNetId);
        }
      }
    }

    if (attendees != null) {
      for (Event2Person attendee in attendees!) {
        String? attendeeNetId = attendee.identifier?.netId;
        if ((attendeeNetId != null) && !displayNetIds.contains(attendeeNetId)) {
          displayList.add(attendee);
          displayNetIds.add(attendeeNetId);
        }
      }
    }

    displayList.sort((Event2Person person1, Event2Person person2) =>
      SortUtils.compare(person1.identifier?.netId, person2.identifier?.netId));

    return displayList;
  }
}