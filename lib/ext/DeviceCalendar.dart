
import 'package:flutter/material.dart';
import 'package:illinois/model/DeviceCalendar.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/DeviceCalendarPrompt.dart';
import 'package:rokwire_plugin/model/device_calendar.dart' as rokwire;
import 'package:rokwire_plugin/service/device_calendar.dart';
import 'package:rokwire_plugin/service/localization.dart';

extension DeviceCalendarExt on DeviceCalendar {

  void addToCalendar(BuildContext context, dynamic event) async {
    if (Storage().calendarShouldPrompt) {
      bool? addConfirmed = await DeviceCalendarAddEventPrompt.show(context);
      if (addConfirmed == true) {
        _addToCalendar(context, event);
      }
    }
    else {
      _addToCalendar(context, event);
    }
  }

  void _addToCalendar(BuildContext context, dynamic event) async {
    DeviceCalendarEvent? calendarEvent = DeviceCalendarEvent.from(event);
    rokwire.DeviceCalendarError? error = (calendarEvent != null) ? await placeCalendarEvent(calendarEvent) : rokwire.DeviceCalendarError.internal();
    String message;
    if (error == null) {
      message = Localization().getStringEx('model.device_calendar.message.add.event.succeeded', 'Event added to Calendar');
    }
    else if (error.code == rokwire.DeviceCalendarErrorCodes.permissionDenied) {
      message = Localization().getStringEx('model.device_calendar.message.add.event.failed.permission.denied', 'Permission denined to add event to Calendar');
    }
    else {
      message = Localization().getStringEx('model.device_calendar.message.add.event.failed', 'Failed to add event to Calendar');
    }

    DeviceCalendarMessage.show(context, message);
  }
}

