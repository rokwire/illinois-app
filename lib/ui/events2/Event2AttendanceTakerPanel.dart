//import 'dart:math';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
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
  Map<String, Event2Person> _displayMap = <String, Event2Person>{};
  List<Event2Person> _displayList = <Event2Person>[];
  Set<String> _atendeesNetIds = <String>{};
  Set<String> _processingNetIds = <String>{};
  String? _processedNetId;
  Timer? _processedTimer;
  String? _errorMessage;

  bool _scanning = false;
  bool _manualInputProgress = false;
  bool _loadingPeople = false;
  bool _attendeesSectionExpanded = false;

  final GlobalKey _manualNetIdKey = GlobalKey();
  final TextEditingController _manualNetIdController = TextEditingController();
  final FocusNode _manualNetIdFocusNode = FocusNode();

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
      Events2().loadEventPeopleEx(eventId).then((result) {
        if (mounted) {
          if (result is Event2PersonsResult) {
            setState(() {
              _loadingPeople = false;
              _persons = result;
              _displayMap = result.buildDisplayMap();
              _displayList = _displayMap.buildDisplayList();
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
    _manualNetIdController.dispose();
    _manualNetIdFocusNode.dispose();
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
      _buildManualNetIdInputSection(),
      _buildScanIlliniIdSection()
    ]);
  }

  Widget _buildEventDetailsSection() {
    String? attendeesStatus;
    TextStyle? attendeesTextStyle, attendeesStatusTextStyle = Styles().textStyles?.getTextStyle('widget.label.small.fat.spaced');
    int attendeesCount = _atendeesNetIds.length;
    int? eventCapacity = widget.event?.registrationDetails?.eventCapacity;
    if (eventCapacity != null) {
      if (eventCapacity < attendeesCount) {
        attendeesStatus =  Localization().getStringEx('panel.event2.detail.attendance.attendees.capacity.exceeded.text', 'Event capacity exceeded');
        attendeesStatusTextStyle = attendeesTextStyle = Styles().textStyles?.getTextStyle('widget.label.small.extra_fat.spaced');
      }
      else if (eventCapacity == attendeesCount) {
        attendeesStatus = Localization().getStringEx('panel.event2.detail.attendance.attendees.capacity.reached.text', 'Event capacity is reached');
        attendeesStatusTextStyle = Styles().textStyles?.getTextStyle('widget.item.small.thin.italic'); // widget.label.small.fat.spaced
      }
    }

    return Event2CreatePanel.buildSectionWidget(
      body: Column(children: [
        _buildEventDetail(label: Localization().getStringEx('panel.event2.detail.attendance.event.capacity.label.title', 'EVENT CAPACITY:'), value: eventCapacity),
        _buildEventDetail(label: Localization().getStringEx('panel.event2.detail.attendance.event.registrations.label.title', 'TOTAL NUMBER OF REGISTRATIONS:'), value: Event2Person.countInList(_persons?.registrants, role: Event2UserRole.participant), loading: _loadingPeople, defaultValue: _hasError ? '-' : ''),
        _buildEventDetail(label: Localization().getStringEx('panel.event2.detail.attendance.event.attendees.label.title', 'TOTAL NUMBER OF ATTENDEES:'), value: attendeesCount, loading: _loadingPeople, defaultValue: _hasError ? '-' : '',
          description: attendeesStatus,
          descriptionTextStyle: attendeesStatusTextStyle,
          labelTextStyle: attendeesTextStyle,
        ),
        StringUtils.isNotEmpty(_errorMessage) ? _buildErrorStatus(_errorMessage ?? '') : Container(),
      ],),
    );
  }
  
  Widget _buildEventDetail({required String label, int? value, String? description, 
    TextStyle? labelTextStyle, TextStyle? valueTextStyle, TextStyle? descriptionTextStyle,
    bool? loading, String defaultValue = ''
  }) {
    String valueLabel = value?.toString() ?? defaultValue;
    String semanticsLabel = "$label: $valueLabel";

    return Padding(padding: Event2CreatePanel.innerSectionPadding, child:
      Semantics(label: semanticsLabel, excludeSemantics: true, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child:
              Event2CreatePanel.buildSectionTitleWidget(label, textStyle: labelTextStyle)
            ),
            (loading == true) ?
              Padding(padding: EdgeInsets.all(2.5), child:
                SizedBox(width: 16, height: 16, child:
                  CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 2,),
                ),
              ) :
              Text(valueLabel, style: valueTextStyle ?? Styles().textStyles?.getTextStyle('widget.label.medium.fat'),)
          ]),

          (description != null) ? Row(children: [
            Expanded(child:
              Text(description, style: descriptionTextStyle ?? valueTextStyle ?? Event2CreatePanel.headingTextStype,)
            )
          ],) : Container()

        ],)
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
    heading: Event2CreatePanel.buildDropdownSectionHeadingWidget(Localization().getStringEx('panel.event2.detail.attendance.attendees.drop_down.hint', 'GUEST LIST'),
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
    Event2CreatePanel.hideKeyboard(context);
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
    Event2CreatePanel.hideKeyboard(context);
    String? eventId = widget.event?.id;
    Event2PersonIdentifier? personIdentifier = person.identifier;
    String? netId = personIdentifier?.netId;
    if (widget.manualCheckEnabled != true) {
      Event2Popup.showMessage(context,
        title: Localization().getStringEx("panel.event2.detail.attendance.message.not_available.title", "Not Available"),
        message: Localization().getStringEx("panel.event2.detail.attendance.manual_check.disabled", "Manual check is not enabled for this event."));
    }
    else if ((eventId != null) && (netId != null) && (personIdentifier != null) && !_processingNetIds.contains(netId))  {
      if (_atendeesNetIds.contains(netId)) {
        _unattendEvent(eventId: eventId, netId: netId, personIdentifier: personIdentifier);
      }
      else {
        _attendEvent_CheckAttendee(eventId: eventId, netId: netId, personIdentifier: personIdentifier);
      }
    }
  }
  
  // In _attendEvent_CheckAttendee we check if the attendee candidate is already registered or already attended the event
  void _attendEvent_CheckAttendee({required String eventId, required String netId, required Event2PersonIdentifier personIdentifier}) {
    if (_isInternalRegisterationEvent && !_isAttendeeNetIdRegistered(netId)) {
      _promptUnregisteredAttendee().then((bool? result) {
        if ((result == true) && mounted) {
          _attendEvent_CheckCapacity(eventId: eventId, netId: netId, personIdentifier: personIdentifier);
        }
      });
    }
    else {
      _attendEvent_CheckCapacity(eventId: eventId, netId: netId, personIdentifier: personIdentifier);
    }
  }

  // In _attendEvent_CheckCapacity we check if the event capacity is reached
  void _attendEvent_CheckCapacity({required String eventId, required String netId, required Event2PersonIdentifier personIdentifier}) {
    if (_isInternalRegisterationEvent && (_isEventCapacityReached == true)) {
      _promptCapacityReached().then((bool? result) {
        if ((result == true) && mounted) {
          _attendEvent(eventId: eventId, netId: netId, personIdentifier: personIdentifier);
        }
      });
    }
    else {
      _attendEvent(eventId: eventId, netId: netId, personIdentifier: personIdentifier);
    }
  }
  
  // In _attendEvent we call the Event2 service unconditionally
  void _attendEvent({required String eventId, required String netId, required Event2PersonIdentifier personIdentifier}) {
    setState(() {
      _processingNetIds.add(netId);
    });
    Events2().attendEvent(eventId, personIdentifier: personIdentifier).then((dynamic result) {
      if (mounted) {
        setState(() {
          _processingNetIds.remove(netId);
        });

        if (result is Event2Person) {
          setState(() {
            _atendeesNetIds.add(netId);
          });
          _beep(true);
        }
        else {
          Event2Popup.showErrorResult(context, result);
          _beep(false);
        }
      }
    });
  }

  // In _unattendEvent we call the Event2 service unconditionally
  void _unattendEvent({required String eventId, required String netId, Event2PersonIdentifier? personIdentifier}) {
    setState(() {
      _processingNetIds.add(netId);
    });
    Events2().unattendEvent(eventId, personIdentifier: personIdentifier).then((dynamic result) {
      if (mounted) {
        setState(() {
          _processingNetIds.remove(netId);
        });

        if (result == true) {
          setState(() {
            _atendeesNetIds.remove(netId);
            if (netId == _processedNetId) {
              _processedNetId = null;
            }
          });
          _beep(true);
        }
        else {
          Event2Popup.showErrorResult(context, result);
          _beep(false);
        }
      }
    });
  }

  Widget _buildUploadAttendeesDescription() {
    TextStyle? mainStyle = Styles().textStyles?.getTextStyle('widget.item.small.thin.italic');
    final Color defaultStyleColor = Colors.red;
    final String? eventAttendanceUrl = Config().eventAttendanceUrl;
    final String eventAttendanceUrlMacro = '{{event_attendance_url}}';
    String contentHtml = Localization().getStringEx('panel.event2.detail.attendance.attendees.description',
        "Visit <a href='{{event_attendance_url}}'>{{event_attendance_url}}</a> to upload or download a list.");
    contentHtml = contentHtml.replaceAll(eventAttendanceUrlMacro, eventAttendanceUrl ?? '');
    return Visibility(visible: StringUtils.isNotEmpty(eventAttendanceUrl), child:
      Padding(padding: EdgeInsets.only(top: 12), child:
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
      ),
    );
  }

  bool _onTapHtmlLink(String? url) {
    Analytics().logSelect(target: '($url)');
    UrlUtils.launchExternal(url);
    return true;
  }

  Widget _buildManualNetIdInputSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.detail.attendance.manual.netid.label', 'Add NetID to the guest list:')),
    body: _buildManualNetIdInputWidget() ,
  );

  Widget _buildManualNetIdInputWidget() => Container(decoration: Event2CreatePanel.sectionDecoration, padding: const EdgeInsets.only(left: 12), child:
    Row(children: [
      Expanded(child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child:
          TextField(
            key: _manualNetIdKey,
            controller: _manualNetIdController,
            focusNode: _manualNetIdFocusNode,
            decoration: InputDecoration(border: InputBorder.none),
            style: Event2CreatePanel.textEditStyle,
            maxLines: 1,
            keyboardType: TextInputType.text,
            autocorrect: false,
            onEditingComplete: _onTapManualNetIdAdd,
          )
        )
      ),
      InkWell(onTap: _onTapManualNetIdAdd, child:
        Padding(padding: EdgeInsets.all(16), child:
          _manualInputProgress ? Padding(padding: EdgeInsets.all(2), child:
            SizedBox(width: 14, height: 14, child:
              CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 2,)
            )
          ) : Styles().images?.getImage('plus-circle')
        ),
      )
    ],)
  //Event2CreatePanel.buildTextEditWidget(_attendanceTakersController, keyboardType: TextInputType.text, maxLines: null)
  );

  void _onTapManualNetIdAdd() {
    String netId = _manualNetIdController.text.trim();
    String? eventId = widget.event?.id;
    if (netId.isNotEmpty && (eventId != null) && (_manualInputProgress == false)) {
      _manualAttendEvent_CheckAttendee(eventId: eventId, netId: netId);
    }
  }

  // In _manualAttendEvent_CheckAttendee we check if the attendee candidate is already registered or already attended the event
  void _manualAttendEvent_CheckAttendee({ required String eventId, required String netId}) {
    if (_isAttendeeNetIdAttended(netId)) {
      Event2Popup.showMessage(context, message: Localization().getStringEx('panel.event2.detail.attendance.prompt.attendee_already_registered.description', 'Already marked as attended.'));
    }
    else if (_isInternalRegisterationEvent && !_isAttendeeNetIdRegistered(netId)) {
      _promptUnregisteredAttendee().then((bool? result) {
        if ((result == true) && mounted) {
          _manualAttendEvent_CheckCapacity(eventId: eventId, netId: netId);
        }
      });
    }
    else {
      _manualAttendEvent_CheckCapacity(eventId: eventId, netId: netId);
    }
  }

  // In _manualAttendEvent_CheckCapacity we check if the event capacity is reached
  void _manualAttendEvent_CheckCapacity({ required String eventId, required String netId}) {
    if (_isInternalRegisterationEvent && (_isEventCapacityReached == true)) {
      _promptCapacityReached().then((bool? result) {
        if ((result == true) && mounted) {
          _manualAttendEvent(eventId: eventId, netId: netId);
        }
      });
    }
    else {
      _manualAttendEvent(eventId: eventId, netId: netId);
    }
  }

  // In _manualAttendEvent we call the Event2 service unconditionally
  void _manualAttendEvent({ required String eventId, required String netId}) {
    setState(() {
      _manualInputProgress = true;
    });
    Events2().attendEvent(eventId, personIdentifier: Event2PersonIdentifier(accountId: "", exteralId: netId)).then((result) {
      if (mounted) {
        setState(() {
          _manualInputProgress = false;
        });

        String? attendeeNetId = (result is Event2Person) ? result.identifier?.netId : null;
        if (attendeeNetId != null) {
          setState(() {
            _atendeesNetIds.add(attendeeNetId);
            if (!_displayMap.containsKey(attendeeNetId)) {
              _displayMap[attendeeNetId] = result;
              _displayList = _displayMap.buildDisplayList();
            }
            _processedNetId = attendeeNetId;
            _attendeesSectionExpanded = true;
          });
          _beep(true);
          _manualNetIdController.text = '';
          _setupProcessedTimer();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ensureVisibleManualNetIdInput();
            _manualNetIdFocusNode.requestFocus();
          });
        }
        else {
          Event2Popup.showErrorResult(context, result);
          _beep(false);
        }
      }
    });
  }

  void _ensureVisibleManualNetIdInput() {
    BuildContext? manualNetIdContext = _manualNetIdKey.currentContext;
    if (manualNetIdContext != null) {
      Scrollable.ensureVisible(manualNetIdContext, duration: Duration(milliseconds: 10));
    }
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
    Event2CreatePanel.hideKeyboard(context);

    if (widget.scanEnabled != true) {
      Event2Popup.showMessage(context,
        title: Localization().getStringEx("panel.event2.detail.attendance.message.not_available.title", "Not Available"),
        message: Localization().getStringEx("panel.event2.detail.attendance.scan.disabled", "Scanning Illini ID is not enabled for this event."));
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
        _scanAttendEvent_CheckAttendee(eventId: eventId, uin: uin);
      }
    }
    else {
      setState(() {
        _scanning = false;
      });
    }
  }

  // In _scanAttendEvent_CheckAttendee we check if the attendee candidate is already registered or already attended the event
  void _scanAttendEvent_CheckAttendee({ required String eventId, required String uin}) {
    if (_isInternalRegisterationEvent) {
      Events2().loadEventPerson(uin: uin).then((Event2PersonIdentifier? personIdentifier) {
        if (mounted) {
          String? netId = personIdentifier?.exteralId;
          if (netId != null) {
            if (_isAttendeeNetIdAttended(netId)) {
              setState(() {
                _scanning = false;
              });
              Event2Popup.showMessage(context, message: Localization().getStringEx('panel.event2.detail.attendance.prompt.attendee_already_registered.description', 'Already marked as attended.'));
            }
            else if (!_isAttendeeNetIdRegistered(netId)) {
              _promptUnregisteredAttendee().then((bool? result) {
                if (mounted) {
                  if (result == true) {
                    _scanAttendEvent_CheckCapacity(eventId: eventId, uin: uin);
                  }
                  else {
                    setState(() {
                      _scanning = false;
                    });
                  }
                }
              });
            }
            else {
              _scanAttendEvent_CheckCapacity(eventId: eventId, uin: uin);
            }
          }
          else {
            setState(() {
              _scanning = false;
            });
            Event2Popup.showErrorResult(context, Localization().getStringEx('panel.event2.detail.attendance.prompt.uin.not_recognized.description', 'This QR code contain a valid UIN but we failed to identify its owner.'));
          }
        }
      });
    }
    else {
      _scanAttendEvent_CheckCapacity(eventId: eventId, uin: uin);
    }
  }

  // In _scanAttendEvent_CheckCapacity we check if the event capacity is reached
  void _scanAttendEvent_CheckCapacity({ required String eventId, required String uin}) {
    if (_isInternalRegisterationEvent && (_isEventCapacityReached == true)) {
      _promptCapacityReached().then((bool? result) {
          if (mounted) {
            if (result == true) {
              _scanAttendEvent(eventId: eventId, uin: uin);
            }
            else {
              setState(() {
                _scanning = false;
              });
            }
          }
      });
    }
    else {
      _scanAttendEvent(eventId: eventId, uin: uin);
    }
  }

  // In _scanAttendEvent we call the Event2 service unconditionally
  void _scanAttendEvent({ required String eventId, required String uin}) {
    Events2().attendEvent(eventId, uin: uin).then((result) {
      if (mounted) {
        setState(() {
          _scanning = false;
        });

        String? attendeeNetId = (result is Event2Person) ? result.identifier?.netId : null;
        if (attendeeNetId != null) {
          setState(() {
            _atendeesNetIds.add(attendeeNetId);
            if (!_displayMap.containsKey(attendeeNetId)) {
              _displayMap[attendeeNetId] = result;
              _displayList = _displayMap.buildDisplayList();
            }
            _processedNetId = attendeeNetId;
            _attendeesSectionExpanded = true;
          });
          _beep(true);
          _setupProcessedTimer();
        }
        else {
          Event2Popup.showErrorResult(context, result);
          _beep(false);
        }
      }
    });
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

  bool get _isInternalRegisterationEvent =>
    widget.event?.registrationDetails?.type == Event2RegistrationType.internal;

  bool _isAttendeeNetIdRegistered(String attendeeNetId) =>
    _displayMap[attendeeNetId]?.registrationType != null;

  bool _isAttendeeNetIdAttended(String attendeeNetId) =>
    _atendeesNetIds.contains(attendeeNetId);

  bool? get _isEventCapacityReached {
    int attendeesCount = _atendeesNetIds.length;
    int? eventCapacity = widget.event?.registrationDetails?.eventCapacity;
    return ((eventCapacity != null) && (0 < eventCapacity)) ? (eventCapacity <= attendeesCount) : null;
  }

  Future<void> _beep(bool success) async {
    if (Platform.isAndroid) {
      await FlutterBeep.playSysSound(success ? AndroidSoundIDs.TONE_PROP_BEEP : AndroidSoundIDs.TONE_CDMA_ABBR_ALERT);
    }
    else if (Platform.isIOS) {
      await FlutterBeep.playSysSound(success ? iOSSoundIDs.AudioToneKey2 : iOSSoundIDs.SIMToolkitTone3);
    }
  }

  Future<bool?> _promptUnregisteredAttendee() => Event2Popup.showPrompt(context,
    Localization().getStringEx('panel.event2.detail.attendance.prompt.attendee_not_registered.title', 'Not registered'),
    Localization().getStringEx('panel.event2.detail.attendance.prompt.attendee_not_registered.description', 'Mark as attended?'),
    positiveButtonTitle: Localization().getStringEx("dialog.yes.title", "Yes"),
    negativeButtonTitle: Localization().getStringEx("dialog.no.title", "No"),
  );

  Future<bool?> _promptCapacityReached() => Event2Popup.showPrompt(context,
    Localization().getStringEx('panel.event2.detail.attendance.prompt.event_capacity_reached.title', 'At event capacity'),
    Localization().getStringEx('panel.event2.detail.attendance.prompt.event_capacity_reached.description', 'Mark as attended?'),
    positiveButtonTitle: Localization().getStringEx("dialog.yes.title", "Yes"),
    negativeButtonTitle: Localization().getStringEx("dialog.no.title", "No"),
  );

  Future<void> _refresh() async {
    String? eventId = widget.event?.id;
    if (eventId != null) {
      setStateIfMounted(() {
        _loadingPeople = true;
      });
      dynamic result = await Events2().loadEventPeopleEx(eventId);
      if (mounted) {
        if (result is Event2PersonsResult) {
          setState(() {
            _loadingPeople = false;
            _persons = result;
            _displayMap = result.buildDisplayMap();
            _displayList = _displayMap.buildDisplayList();
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
          _buildNameWidget(context)
        )
      ),
      
      (processing != true) ? InkWell(onTap: onTap, child: _checkMarkWidget) : _progressMarkWidget,
    ],);

  }

  Widget _buildNameWidget(BuildContext context) {
    String titleStyleKey;
    String descriptionStyleKey;
    if (enabled) {
      if (highlighted) {
        titleStyleKey = 'widget.label.regular.fat';
        descriptionStyleKey = 'widget.label.regular.thin';
      }
      else {
        titleStyleKey = 'widget.card.title.small.fat';
        descriptionStyleKey = 'widget.detail.light.regular';
      }
    }
    else {
      titleStyleKey = 'widget.card.title.small.fat.variant3';
      descriptionStyleKey = 'widget.card.title.small.variant3';
    }

    String? registrantNetId = registrant.identifier?.netId;
    String? registrantType = event2UserRegistrationToDisplayString(registrant.registrationType);
    return (registrantType != null) ? RichText(textScaleFactor: MediaQuery.of(context).textScaleFactor, text:
      TextSpan(text: registrantNetId, style: Styles().textStyles?.getTextStyle(titleStyleKey),  children: <InlineSpan>[
        TextSpan(text: " (${registrantType.toLowerCase()})", style: Styles().textStyles?.getTextStyle(descriptionStyleKey),),
      ])
    ) : Text(registrantNetId ?? '', style: Styles().textStyles?.getTextStyle(titleStyleKey));
  }

  Widget get _checkMarkWidget => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
    Styles().images?.getImage(_checkMarkImageKey) ?? Container()
  );

  String get _checkMarkImageKey {
    if (enabled) {
      if (highlighted) {
        return 'check-circle-outline';
      }
      else if (selected) {
        return 'check-circle-filled';
      }
      else {
        return 'circle-outline-gray';
      }
    }
    else {
      if (highlighted) {
        return 'check-circle-outline';
      }
      else if (selected) {
        return 'check-circle-outline-gray';
      }
      else {
        return 'circle-outline-gray';
      }
    }
  }

  Widget get _progressMarkWidget => Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18), child:
    SizedBox(width: 20, height: 20, child:
      CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 2,)
    )
  );

}

extension Event2PersonsResultExt on Event2PersonsResult {
  
  Map<String, Event2Person> buildDisplayMap() {
    Map<String, Event2Person> displayMap = <String, Event2Person>{};

    if (registrants != null) {
      for (Event2Person registrant in registrants!) {
        String? registrantNetId = registrant.identifier?.netId;
        if ((registrantNetId != null) && !displayMap.containsKey(registrantNetId)) {
          displayMap[registrantNetId] = registrant;
        }
      }
    }

    if (attendees != null) {
      for (Event2Person attendee in attendees!) {
        String? attendeeNetId = attendee.identifier?.netId;
        if ((attendeeNetId != null) && !displayMap.containsKey(attendeeNetId)) {
          displayMap[attendeeNetId] = attendee;
        }
      }
    }

    return displayMap;
  }
}

extension Event2PersonsMapExt on Map<String, Event2Person> {

  List<Event2Person> buildDisplayList() {
    List<Event2Person> displayList = List.from(values);

    displayList.sort((Event2Person person1, Event2Person person2) =>
      SortUtils.compare(person1.identifier?.netId, person2.identifier?.netId));

    return displayList;
  }
}