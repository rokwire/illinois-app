
import 'package:flutter/material.dart';
import 'package:illinois/model/DeviceCalendar.dart';
import 'package:illinois/service/DeviceCalendar.dart';
import 'package:illinois/ui/widgets/DeviceCalendarAddPrompt.dart';

extension DeviceCalendarExt on DeviceCalendar {

  Future<bool> addToCalendar(BuildContext context, dynamic event) async {
    if (canAddToCalendar) {
      if (shouldPrompt) {
        bool? addConfirmed = await DeviceCalendarAddPrompt.show(context);
        if (addConfirmed == true) {
          return _addToCalendar(event);
        }
        else {
          debugPrint("Add to Calendar not confirmed");
          return false;
        }
      }
      else {
        return _addToCalendar(event);
      }
    }
    else {
      debugPrint("Add to Calendar is not enabled");
      return false;
    }
  }

  Future<bool> _addToCalendar(dynamic event) async {
    DeviceCalendarEvent? deviceCalendarEvent = DeviceCalendarEvent.from(event);
    if (deviceCalendarEvent != null) {
      //init check
      bool initResult = await loadDefaultCalendarIfNeeded();
      if (initResult) {
        return placeCalendarEvent(event);
      }
      else {
        debugPrint("Unable to init plugin");
        return false;
      }
    }
    else {
      debugPrint("Failed to create calendar event");
      return false;
    }
  }
}

