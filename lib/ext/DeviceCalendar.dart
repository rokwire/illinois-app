
import 'package:flutter/material.dart';
import 'package:illinois/model/DeviceCalendar.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/widgets/DeviceCalendarPrompt.dart';
import 'package:rokwire_plugin/model/device_calendar.dart' as rokwire;
import 'package:rokwire_plugin/service/device_calendar.dart';
import 'package:rokwire_plugin/service/localization.dart';

extension DeviceCalendarExt on DeviceCalendar {

  void addToCalendar(BuildContext context, dynamic event) async {
    if (canAddToCalendar) {
      if (shouldPrompt) {
        bool? addConfirmed = await DeviceCalendarAddEventPrompt.show(context);
        if (addConfirmed == true) {
          _addToCalendar(context, event);
        }
      }
      else {
        _addToCalendar(context, event);
      }
    }
  }

  void _addToCalendar(BuildContext context, dynamic event) async {
    DeviceCalendarEvent? calendarEvent = DeviceCalendarEvent.from(event);
    rokwire.DeviceCalendarError? error = (calendarEvent != null) ? await placeCalendarEvent(calendarEvent) : rokwire.DeviceCalendarError.internal();
    DeviceCalendarMessage.show(context, (error != null)  ?
      Localization().getStringEx('model.device_calendar.message.add.event.succeeded', 'Event added to Calendar') :
      Localization().getStringEx('model.device_calendar.message.add.event.failed', 'Failed to add event to Calendar')
    );
  }

  void processFavorite(BuildContext context, dynamic event) async {
    if (canAddToCalendar && shouldAutoSave) {
      DeviceCalendarEvent? deviceCalendarEvent = DeviceCalendarEvent.from(event);
      if (deviceCalendarEvent != null) {
        bool isFavorite = Auth2().isFavorite(event);
        if (shouldPrompt) {
          String message = isFavorite ? DeviceCalendarAddEventPrompt.message : DeviceCalendarRemoveEventPrompt.message;
          bool? processConfirmed = await DeviceCalendarPrompt.show(context, message);
          if (processConfirmed == true) {
            _processFavorite(context, deviceCalendarEvent, isFavorite);
          }
        }
        else {
          _processFavorite(context, deviceCalendarEvent, isFavorite);
        }
      }
    }
  }

  void _processFavorite(BuildContext context, DeviceCalendarEvent deviceCalendarEvent, bool isFavorite) async {
    rokwire.DeviceCalendarError? error = isFavorite ? await placeCalendarEvent(deviceCalendarEvent) : await removeCalendarEvent(deviceCalendarEvent);
    if (shouldPrompt) {
      DeviceCalendarMessage.show(context, (error != null)  ?
        (isFavorite ? Localization().getStringEx('model.device_calendar.message.add.event.succeeded', 'Event added to Calendar') : Localization().getStringEx('model.device_calendar.message.remove.event.succeeded', 'Event removed from Calendar')) :
        (isFavorite ? Localization().getStringEx('model.device_calendar.message.add.event.failed', 'Failed to add event to Calendar') : Localization().getStringEx('model.device_calendar.message.remove.event.failed', 'Failed to remove event from Calendar'))
      );
    }
  }
}

