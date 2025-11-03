import 'package:device_calendar/device_calendar.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart' as timezone;

import '../widgets/HeaderBar.dart';

class Event2SetupNotificationsPanel extends StatefulWidget {
  final Event2? event;
  final String? eventName;
  final DateTime? eventStartDateTimeUtc;
  final bool? eventHasInternalRegistration;
  final bool? isGroupEvent;
  final List<Event2NotificationSetting>? notifications;

  Event2SetupNotificationsPanel(
      {required this.event,
        this.eventName,
        this.eventHasInternalRegistration,
        this.eventStartDateTimeUtc,
        this.isGroupEvent,
        this.notifications});

  @override
  _Event2SetupNotificationsPanelState createState() => _Event2SetupNotificationsPanelState();
}

class _Event2SetupNotificationsPanelState extends State<Event2SetupNotificationsPanel> with NotificationsListener {
  static final EdgeInsets _defaultBottomPadding = EdgeInsets.only(bottom: 8);
  static final int _notificationsCount = 2;

  late List<Event2NotificationSetting?> _notificationSettings;
  late List<TextEditingController> _bodyControllers;
  late List<dynamic> _sendDates;
  late List<dynamic> _sendTimes;
  late List<Location?> _timeZones;
  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Events2.notifyNotificationsUpdated]);
    _initNotificationSettings();
    _loadNotifications();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: HeaderBar(title: Localization().getStringEx("panel.event2.setup.notifications.title", "Custom Notifications")), //TBD Localize whole panel
        body: SingleChildScrollView(
            child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Padding(
                        padding: _defaultBottomPadding,
                        child: Row(children: [
                          Expanded(
                              child: Text(
                                  'Create and schedule up to two custom Illinois app event notifications. Illinois app users need to be signed in with their NetID at a privacy level 4 or higher to receive notifications. For device push-notifications, app users must have Illinois app notifications turned on in their device settings.',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 10,
                                /*TBD  style: TextStyle(color: AppColors.darkSlateBlueTwo, fontSize: 16, fontFamily: 'ProximaNovaRegular')*/))
                        ])),
                    Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _buildItalicDescriptionWidget(
                            label:
                            'Thirty minutes prior to your event start time, an event reminder notification will automatically be sent to all app users who have starred your event.')),
                    Padding(
                        padding: _defaultBottomPadding,
                        child: _buildItalicDescriptionWidget(
                            label:
                            'If you have used the app to take attendance and send a follow-up survey, a notification will be sent to all event attendees at the time you designate under your event follow-up survey settings.')),
                    _buildNotificationsContent(defaultBottomPadding: _defaultBottomPadding, bottom10Padding: EdgeInsets.only(bottom: 10)),
                    Container(
                        // constraints: BoxConstraints(),
                        padding: _defaultBottomPadding,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Expanded(child:
                                RoundedButton(
                                    label: 'Save',
                                    borderColor: Styles().colors.fillColorSecondary,
                                    textColor: Styles().colors.fillColorPrimary,
                                    backgroundColor: Colors.white,
                                    progress: _saving,
                                    onTap: _onTapSave)),
                              Container(width: 16),
                              Expanded(child:
                                RoundedButton(
                                    label: 'Clear All',
                                    borderColor: Styles().colors.fillColorSecondary,
                                    textColor: Styles().colors.fillColorPrimary,
                                    backgroundColor: Colors.white,
                                    progress: _deleting,
                                    onTap: _onTapClearAll)),
                            ]))
                  ])
        )),
        backgroundColor: Styles().colors.white,
    );
  }

  Widget _buildNotificationsContent({required EdgeInsets defaultBottomPadding, required EdgeInsets bottom10Padding}) {
    if (_loading) {
      return Center(child: Padding(padding: defaultBottomPadding, child: CircularProgressIndicator()));
    }
    List<Widget> notificationWidgets = <Widget>[];
    for (int i = 0; i < _notificationsCount; i++) {
      Widget notificationWidget = _buildSingleNotificationWidget(
          notificationIndex: i, defaultBottomPadding: defaultBottomPadding, bottom10Padding: bottom10Padding);
      ListUtils.add(notificationWidgets, notificationWidget);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: notificationWidgets);
  }

  Widget _buildSingleNotificationWidget(
      {required int notificationIndex, required EdgeInsets defaultBottomPadding, required EdgeInsets bottom10Padding}) {
    Event2NotificationSetting? notification = _notificationSettings[notificationIndex];
    bool favoritedValue = notification?.sendToFavorited ?? false;
    bool registeredValue = notification?.sendToRegistered ?? false;
    bool groupsValue = notification?.sendToPublishedInGroups ?? false;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: defaultBottomPadding, child: _buildHorizontalDividerWidget()),
      Padding(padding: defaultBottomPadding, child: _buildHeaderLabelWidget(label: 'Custom Notification #${notificationIndex + 1}')),
      Padding(padding: bottom10Padding, child: _buildSubHeaderLabelWidget(label: 'AUDIENCE', isRequired: true)),
      Padding(
          padding: bottom10Padding,
          child: _buildToggleWidget(
              label: _toggleFavoritedEventTitle,
              value: favoritedValue,
              onTap: () => _onTapFavoritedEvent(index: notificationIndex))),
      Padding(
          padding: bottom10Padding,
          child: _buildToggleWidget(
              label: _toggleRegisteredEventTitle,
              value: registeredValue,
              enabled: _allowRegisteredUser,
              onTap: () => _onTapRegisteredEvent(index: notificationIndex))),
      Padding(
          padding: defaultBottomPadding,
          child: _buildToggleWidget(
              label: _togglePublishedGroupEventTitle,
              value: groupsValue,
              enabled: _allowGroupMembers,
              onTap: () => _onTapPublishedGroupEvent(index: notificationIndex))),
      Padding(padding: bottom10Padding, child: _buildSubHeaderLabelWidget(label: 'SCHEDULE', isRequired: true)),
      Padding(padding: defaultBottomPadding, child: _buildEventDateTimeContent(notificationIndex)),
      Padding(
          padding: defaultBottomPadding,
          child: Row(crossAxisAlignment: (CrossAxisAlignment.start ), children: [
            _buildSubHeaderLabelWidget(label: 'Notification subject:'),
            Expanded(
                child: Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Text(_notificationSubject,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        /*TBD style: TextStyle(color: AppColors.darkSlateBlueTwo, fontSize: 14, fontFamily: 'ProximaNovaRegular')*/)))
          ])),
      Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Row(crossAxisAlignment: (CrossAxisAlignment.start), children: [
            _buildSubHeaderLabelWidget(label: 'Notification message', isRequired: true),
            Expanded(
                child: Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Text('(Limited to 250 characters)',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        /*TBD style: TextStyle(color: AppColors.darkSlateBlueTwo, fontSize: 12, fontFamily: 'ProximaNovaRegular', letterSpacing: 1.25)*/)))
          ])),
      Padding(
          padding: EdgeInsets.only(bottom: 30),
          child: TextField(
              controller: _bodyControllers[notificationIndex],
              maxLines: 10,
              maxLength: 250,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Styles().colors.surfaceAccent, width: 1),
                  borderRadius: BorderRadius.circular(8)
                ),),
              )),
    ]);
  }

  Widget _buildHeaderLabelWidget({required String label}) {
    return Text(label, /*TBD style: TextStyle(fontFamily: 'ProximaNovaBold', fontSize: 20, color: AppColors.darkSlateBlueTwo)*/);
  }

  Widget _buildSubHeaderLabelWidget({required String label, bool isRequired = false}) {
    return Row(children: [
      Text(label.toUpperCase(),
          /*TBD style: TextStyle(fontFamily: 'ProximaNovaBold', fontSize: 14, color: AppColors.darkSlateBlueTwo, letterSpacing: 1.2)*/),
      Text('*', /*TBD style: TextStyle(color: AppColors.illinoisOrange, fontSize: 16, fontFamily: 'ProximaNovaBold')*/)
    ]);
  }

  Widget _buildItalicDescriptionWidget({required String label}) {
    return Row(children: [
      Expanded(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              maxLines: 12,
              /*TBD style:  TextStyle(color: AppColors.greyishBrown, fontSize: 14, fontFamily: 'ProximaNovaRegularIt')*/))
    ]);
  }

  Widget _buildToggleWidget({required String label, bool? value, bool enabled = true, void Function()? onTap}) {
    bool toggled = (value == true);
    String hint = AppSemantics.toggleHint(toggled,
      enabled: enabled,
      subject: label
    );

    return Semantics(label: label, hint: hint, button: true, enabled: enabled, toggled: enabled ? toggled : null, excludeSemantics: true, child:
      InkWell(splashColor: Colors.transparent, onTap: onTap, child:
        Padding(padding: EdgeInsets.symmetric(vertical: 6), child:
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(child: enabled == true ?
              Styles().images.getImage((toggled == true) ? 'toggle-on' : 'toggle-off') :
              Styles().images.getImage('toggle-off', color: Styles().colors.fillColorPrimaryTransparent03, colorBlendMode: BlendMode.dstIn,)
            ),
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 10, right: 16), child:
                Text(label, style: enabled ? _enabledButtonTextStyle : _disabledButtonTextStyle)
              )
            )
          ])
        )
      )
    );
  }

  Widget _buildEventDateTimeContent(int index) {
    return Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: EdgeInsets.only(top: 20, bottom: 10),
          child: Semantics(container: true, child:
            Row(children: <Widget>[
              Expanded(flex: 4, child:
                Event2CreatePanel.buildSectionTitleWidget(Localization().getStringEx("panel.create_event.date_time.time_zone.title", "TIME ZONE"), required: true),
              ),
              Container(width: 16,),
              Expanded(flex: 6, child:
                Container(decoration: Event2CreatePanel.dropdownButtonDecoration, child:
                  Padding(padding: EdgeInsets.only(left: 12, right: 8), child:
                    DropdownButtonHideUnderline(child:
                      DropdownButton<Location>(
                          icon: Styles().images.getImage('chevron-down'),
                          isExpanded: true,
                          style: Styles().textStyles.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                          hint: Text(_timeZones[index]?.name ?? ""),
                          items: _timezoneDropDownItems,
                          onChanged: (value) => _onTimezoneChanged(index: index, value: value)
                      ),
                    ),
                  ),
                ),
              ),
            ])
        )),
      Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
              Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Send Date and Time',
                     /*TBD style: TextStyle(color: AppColors.darkSlateBlueTwo, fontSize: 16, fontFamily: "ProximaNovaSemiBold")*/)),
              _buildDateTextField(label: 'Send Date', date: _sendDates[index], onTap: () => _onTapSendDate(index)),
              _buildTimeTextField(label: 'Send Time', time: _sendTimes[index], onTap: () => _onTapSendTime(index))
            ]))
      ])
    ]);
  }

  Widget _buildDateTextField({required String label, DateTime? date, required void Function() onTap}) {
    String value = (date != null) ? DateFormat('yyyy-MM-dd').format(date) : '';
    return InkWell(
        onTap: onTap,
        child: Container(
            padding: EdgeInsets.only(bottom: 8),
            child: Center(
                child: TextField(
                    controller: TextEditingController(text: value),
                    decoration: InputDecoration(icon: Icon(Icons.calendar_today), labelText: label),
                    /*TBD style: TextStyle(fontFamily: 'ProximaNovaRegular', fontSize: 16, color: AppColors.greyishBrown),*/
                    enabled: false,
                    readOnly: true))));
  }

  Widget _buildTimeTextField({required String label, TimeOfDay? time, required void Function() onTap}) {
    String value = (time != null) ? time.format(context) : '';
    return InkWell(
        onTap: onTap,
        child: Container(
            padding: EdgeInsets.only(bottom: 8),
            child: Center(
                child: TextField(
                    controller: TextEditingController(text: value),
                    decoration: InputDecoration(icon: Icon(Icons.access_time), labelText: label),
                    /* TBD style: TextStyle(fontFamily: 'ProximaNovaRegular', fontSize: 16, color: AppColors.greyishBrown),*/
                    enabled: false,
                    readOnly: true))));
  }

  void _onTimezoneChanged({Location? value, required int index}) {
    setStateIfMounted(() {
      if(value!=null)
        _timeZones[index] = value;
    });
  }

  List<DropdownMenuItem<Location>> get _timezoneDropDownItems {
    List<DropdownMenuItem<Location>> items = [];
   timeZoneDatabase.locations.forEach((String name,
        Location location) {
      if (name.startsWith('US/')) {
        items.add(DropdownMenuItem<Location>(
          value: location,
          child: Semantics(label: name,
              excludeSemantics: true,
              container: true,
              child: Text(name,)),
        ));
      }
    });

    return items;
  }

  void _onTapSendDate(int index) {
    // EventDetailsPanel.hideKeyboard(context);
    DateTime now = DateUtils.dateOnly(DateTime.now());
    DateTime eventStartDate = DateUtils.dateOnly(widget.eventStartDateTimeUtc!.toLocal());
    DateTime minDate = now;
    DateTime maxDate = eventStartDate.add(Duration(days: 7)); // one week after the event date
    showDatePicker(
        context: context,
        initialDate: _sendDates[index] ?? minDate,
        firstDate: minDate,
        lastDate: maxDate,
        currentDate: now,
        // builder: (context, child) {
        //   return AppThemes.datePickerTheme(context, child!);
        //  }
      ).then((DateTime? result) {
        if ((result != null) && mounted) {
          setState(() {
            _sendDates[index] = DateUtils.dateOnly(result);
          });
        }
    });
  }

  void _onTapSendTime(int index) {
    // EventDetailsPanel.hideKeyboard(context);
    showTimePicker(
        context: context,
        initialTime: _sendTimes[index] ?? TimeOfDay(hour: 0, minute: 0),
        // builder: (context, child) {
        //   return AppThemes.timePickerTheme(context, child!);
        // }
      ).then((TimeOfDay? result) {
        if ((result != null) && mounted) {
          setState(() {
            _sendTimes[index] = result;
          });
        }
    });
  }

  Widget _buildHorizontalDividerWidget() => Container(height: 1, color: Styles().colors.dividerLine);

  String get _toggleFavoritedEventTitle => 'App users who have starred this event';

  void _onTapFavoritedEvent({required int index}) {
    if (!_processing) {
      Event2NotificationSetting? notification = _notificationSettings[index];
      Event2NotificationSetting updatedNotification = (notification == null) ?
        Event2NotificationSetting(sendToFavorited: true) :
        Event2NotificationSetting.fromOther(notification, sendToFavorited: !notification.sendToFavorited);
      setStateIfMounted(() {
        _notificationSettings[index] = updatedNotification;
      });
      AppSemantics.announceMessage(context, AppSemantics.toggleAnnouncement(updatedNotification.sendToFavorited, subject: _toggleFavoritedEventTitle));
    }
  }

  String get _toggleRegisteredEventTitle => 'App users who have registered via the Illinois app for this event';

  void _onTapRegisteredEvent({required int index}) {
    if (!_processing) {
      if (!_allowRegisteredUser) {
        Event2NotificationSetting? notification = _notificationSettings[index];
        Event2NotificationSetting updatedNotification = (notification == null) ?
          Event2NotificationSetting(sendToRegistered: true) :
          Event2NotificationSetting.fromOther(notification, sendToRegistered: !notification.sendToRegistered);
        setStateIfMounted(() {
          _notificationSettings[index] = updatedNotification;
        });
        AppSemantics.announceMessage(context, AppSemantics.toggleAnnouncement(updatedNotification.sendToRegistered, subject: _toggleRegisteredEventTitle));
      }
      else {
        AppAlert.showDialogResult(context, 'Please, set Event Registration as "Via the App" in order to allow this option.');
      }
    }
  }

  String get _togglePublishedGroupEventTitle => 'Members of Illinois app groups in which this event is published';

  void _onTapPublishedGroupEvent({required int index}) {
    if (!_processing) {
      if (_allowGroupMembers) {
        Event2NotificationSetting? notification = _notificationSettings[index];
        Event2NotificationSetting updatedNotification = (notification == null) ?
          Event2NotificationSetting(sendToPublishedInGroups: true) :
          Event2NotificationSetting.fromOther(notification, sendToPublishedInGroups: !notification.sendToPublishedInGroups);
        setStateIfMounted(() {
          _notificationSettings[index] = updatedNotification;
        });
        AppSemantics.announceMessage(context, AppSemantics.toggleAnnouncement(updatedNotification.sendToPublishedInGroups, subject: _togglePublishedGroupEventTitle));
      }
      else {
        AppAlert.showDialogResult(context, 'Please, select at least one Event Group in order to allow this option.');
      }
    }
  }

  void _onTapSave() {
    if (_processing) {
      return;
    }
    String? validationError = _validateSaving();
    if (validationError != null) {
      AppAlert.showDialogResult(context, validationError);
      return;
    }
    // Pre-fill the subject which is static
    for (int i = 0; i < _notificationsCount; i++) {
      Event2NotificationSetting? notification = _notificationSettings[i];
      if (notification != null) {
        Location? tzLocation = _timeZones[i];
        DateTime sendDate = _sendDates[i];
        DateTime sendDateTime = DateTime(sendDate.year, sendDate.month, sendDate.day, _sendTimes[i].hour, _sendTimes[i].minute);
        TZDateTime? eventTzDateTime = (tzLocation != null) ? DateTimeUtils.changeTimeZoneToDate(sendDateTime, tzLocation) : null;
        _notificationSettings[i] = Event2NotificationSetting.fromOther(notification,
          sendDateTimeUtc: eventTzDateTime?.toUtc(),
          subject: _notificationSubject,
          body: _bodyControllers[i].text,
          sendTimezone: tzLocation?.name,
        );
      }
    }
    if (_eventId == null) {
      // New event, so pass the notifications to the event and save them on create event operation
      Navigator.of(context).pop(_notificationsSettingsResult);
      return;
    }
    setStateIfMounted(() {
      _saving = true;
    });
    Events2().saveNotificationSettings(eventId: _eventId!, notificationSettings: _notificationSettings).then((result) {
      setStateIfMounted(() {
        _saving = false;
      });
      if (result is String) {
        AppAlert.showDialogResult(context, result);
      } else { //Success
        //We will reload when notified
        // Navigator.of(context).pop(_notificationsSettingsResult);
      }
    });
  }

  ///
  /// Returns null if all is valid, String error message - otherwise
  ///
  String? _validateSaving() {
    List<dynamic> notificationErrors = List.filled(_notificationsCount, null, growable: false);
    for (int i = 0; i < _notificationsCount; i++) {
      dynamic notification = _notificationSettings[i];
      StringBuffer buffer = StringBuffer();
      if (notification is Event2NotificationSetting) {
        if (!notification.hasAudience) {
          buffer.writeln('At least one target audience.');
        }
        _checkExternalFields(buffer: buffer, index: i);
      } else {
        if (_externalFieldHasValue(i)) {
          buffer.writeln('At least one target audience.');
          _checkExternalFields(buffer: buffer, index: i);
        }
      }
      if (buffer.isNotEmpty) {
        notificationErrors[i] = buffer.toString();
      }
    }
    StringBuffer resultBuffer = StringBuffer();
    for (int i = 0; i < _notificationsCount; i++) {
      String? error = notificationErrors[i];
      if (StringUtils.isNotEmpty(error)) {
        resultBuffer.writeln('Custom Notification #${i + 1}:');
        resultBuffer.writeln(error);
        resultBuffer.writeln('');
      }
    }
    return resultBuffer.isNotEmpty ? ('Please, fill the following fields:\n\n' + resultBuffer.toString()) : null;
  }

  void _checkExternalFields({required StringBuffer buffer, required int index}) {
    if (_timeZones[index] == null) {
      buffer.writeln('Timezone');
    }
    if (_sendDates[index] == null) {
      buffer.writeln('Send Date');
    }
    if (_sendTimes[index] == null) {
      buffer.writeln('Send Time');
    }
    if (StringUtils.isEmpty(_bodyControllers[index].text)) {
      buffer.writeln('Notification Message');
    }
  }

  bool _externalFieldHasValue(int index) =>
      (_timeZones[index] != null) ||
          (_sendDates[index] != null) ||
          (_sendTimes[index] != null) ||
          StringUtils.isNotEmpty(_bodyControllers[index].text);

  void _onTapClearAll() {
    if (_processing) {
      return;
    }
    if (CollectionUtils.isEmpty(_notificationSettings)) {
      AppAlert.showDialogResult(context, 'There are no existing notifications.');
      return;
    }
    List<String> notificationIds = <String>[];
    if (CollectionUtils.isNotEmpty(_notificationSettings)) {
      for (Event2NotificationSetting? setting in _notificationSettings) {
        String? id = setting?.id;
        if (id != null) {
          ListUtils.add(notificationIds, id);
        }
      }
    }

    AppAlert.showConfirmationDialog(context,
        message: 'Are you sure that you want to remove all notifications?',
        positiveButtonLabel: 'Yes',
        positiveCallback: () {
          _clearAllNotifications(notificationIds);
        },
        negativeButtonLabel: 'No');
  }

  void _clearAllNotifications(List<String> notificationIds) {
    if ((_eventId == null) || CollectionUtils.isEmpty(notificationIds)) {
      setStateIfMounted(() {
        _initNotificationSettings();
      });
      AppAlert.showDialogResult(context, 'Successfully removed all notifications.');
      return;
    }
    setStateIfMounted(() {
      _deleting = true;
    });
    Events2().deleteAllNotification(eventId: _eventId!, notificationIds: notificationIds).then((result) {
      setStateIfMounted(() {
        _deleting = false;
      });
      if (result is String) {
        AppAlert.showDialogResult(context, result);
      } else {
        AppAlert.showDialogResult(context, 'Successfully removed all notifications.');
      }
    });
  }

  void _loadNotifications() {
    if (_eventId == null) {
      //new event - load arguments
      if (CollectionUtils.isNotEmpty(widget.notifications)) {
        int notificationLength = widget.notifications!.length;
        for (int i = 0; i < _notificationsCount; i++) {
          Event2NotificationSetting? notification = (i < notificationLength) ? widget.notifications![i] : null;
          _notificationSettings[i] = notification;
        }
      }
      _initFields();
      return;
    }

    setStateIfMounted(() {
      _loading = true;
    });

    Events2().loadNotificationSettings(eventId: _eventId!).then((result) {
      if (result is String) {
        AppAlert.showDialogResult(context, result);
      } else if (result is List<Event2NotificationSetting>) {
        setStateIfMounted(() {
          for (int i = 0; i < _notificationsCount; i++) {
            if (i < result.length) {
              _notificationSettings[i] = result[i];
            } else {
              _notificationSettings[i] = null;
            }
          }
        });
      } else {
        AppAlert.showDialogResult(context, 'Unknown error occurred.');
      }
      _initFields();
      setStateIfMounted(() {
        _loading = false;
      });
    });
  }

  void _initFields() {
    _bodyControllers = <TextEditingController>[];
    _sendDates = List.filled(_notificationsCount, null, growable: false);
    _sendTimes = List.filled(_notificationsCount, null, growable: false);
    _timeZones = List.filled(_notificationsCount, null, growable: false);
    for (int i = 0; i < _notificationsCount; i++) {
      Event2NotificationSetting? notification = (i < _notificationSettings.length) ? _notificationSettings[i] : null;
      String controllerText = StringUtils.ensureNotEmpty(notification?.body);

      timezone.Location? _timezone = (notification?.sendTimezone != null) ? timeZoneDatabase.locations[notification!.sendTimezone] : null ;
      _timezone ??= DateTimeLocal.timezoneLocal;

      DateTime? notificationDateTime = notification?.sendDateTimeUtc != null ? TZDateTime.from(notification!.sendDateTimeUtc!, _timezone) : null;
      DateTime? sendDate = (notificationDateTime != null) ? DateUtils.dateOnly(notificationDateTime) : null;
      TimeOfDay? sendTime = (notificationDateTime != null) ? TimeOfDay.fromDateTime(notificationDateTime) : null;

      _bodyControllers.add(TextEditingController(text: controllerText));
      _sendDates[i] = sendDate;
      _sendTimes[i] = sendTime;
      _timeZones[i] = _timezone;
    }
  }

  void _initNotificationSettings() {
    _notificationSettings = List.filled(_notificationsCount, null, growable: false);
  }

  void _disposeControllers() {
    if (CollectionUtils.isNotEmpty(_bodyControllers)) {
      for (TextEditingController controller in _bodyControllers) {
        controller.dispose();
      }
    }
  }

  String? get _eventId => widget.event?.id;

  String get _notificationSubject => 'Event "${StringUtils.ensureNotEmpty(widget.eventName, defaultValue: 'Event Name')}"';

  bool get _allowRegisteredUser => widget.eventHasInternalRegistration ?? false;

  bool get _allowGroupMembers => (widget.isGroupEvent == true);

  TextStyle? get _enabledButtonTextStyle => Styles().textStyles.getTextStyle("widget.button.title.enabled");

  TextStyle? get _disabledButtonTextStyle => Styles().textStyles.getTextStyle("widget.button.title.disabled");

  bool get _processing => (_loading || _saving || _deleting);

  List<Event2NotificationSetting>? get _notificationsSettingsResult => _notificationSettings.whereType<Event2NotificationSetting>().toList();

  @override
  void onNotification(String name, param) {
    if (name == Events2.notifyNotificationsUpdated) {
      _loadNotifications();
    }
  }
}