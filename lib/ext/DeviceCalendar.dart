
import 'package:flutter/material.dart';
import 'package:illinois/model/DeviceCalendar.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/DeviceCalendar.dart';
import 'package:illinois/ui/widgets/DeviceCalendarPrompt.dart';

extension DeviceCalendarExt on DeviceCalendar {

  Future<bool> addToCalendar(BuildContext context, dynamic event) async {
    if (canAddToCalendar) {
      if (shouldPrompt) {
        bool? addConfirmed = await DeviceCalendarAddEventPrompt.show(context);
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

  void processFavorite(BuildContext context, dynamic event) async {
    if (canAddToCalendar && shouldAutoSave) {
      DeviceCalendarEvent? deviceCalendarEvent = DeviceCalendarEvent.from(event);
      if (deviceCalendarEvent != null) {
        bool isFavorite = Auth2().isFavorite(event);
        if (shouldPrompt) {
          String message = isFavorite ? DeviceCalendarAddEventPrompt.message : DeviceCalendarRemoveEventPrompt.message;
          bool? processConfirmed = await DeviceCalendarPrompt.show(context, message);
          if (processConfirmed == true) {
            await _processFavorite(deviceCalendarEvent, isFavorite);
          }
        }
        else {
          await _processFavorite(deviceCalendarEvent, isFavorite);
        }
      }
    }
  }

  Future<bool> _processFavorite(DeviceCalendarEvent deviceCalendarEvent, bool isFavorite) =>
    isFavorite ? placeCalendarEvent(deviceCalendarEvent) : deleteEvent(deviceCalendarEvent);
}

