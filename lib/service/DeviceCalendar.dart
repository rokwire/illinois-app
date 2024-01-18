
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/device_calendar.dart' as rokwire;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:device_calendar/device_calendar.dart';

class DeviceCalendar extends rokwire.DeviceCalendar {

  // Singletone Factory

  @protected
  DeviceCalendar.internal() : super.internal();

  factory DeviceCalendar() => ((rokwire.DeviceCalendar.instance is DeviceCalendar) ? (rokwire.DeviceCalendar.instance as DeviceCalendar) : (rokwire.DeviceCalendar.instance = DeviceCalendar.internal()));

  // Service



  @protected
  void onCreateOrUpdateEventSucceeded(Result<String>? createEventResult) {
    AppToast.show(Localization().getStringEx('logic.calendar.create_event_succeeded', 'Event added to calendar.'));
  }

  @override
  void onCreateOrUpdateEventFailed(Result<String>? createEventResult) {
    AppToast.show(createEventResult?.data ?? createEventResult?.errors.toString() ?? Localization().getStringEx('logic.calendar.create_event_failed', 'Failed to create event.'));
  }

  @override
  void onRequestPermissionFailed() {
    AppToast.show(Localization().getStringEx('logic.calendar.permission_denied', 'Unable to save event to calendar. Permissions not granted.'));
  }
}
