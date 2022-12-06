
import 'package:flutter/material.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension StudentCourseExt on StudentCourse {

  String get displayInfo {
    String result = shortName ?? '';
    
    if (number?.isNotEmpty ?? false) {
      if (result.isNotEmpty) {
        result += ' ';
      }
      result += "($number)";
    }

    if (instructionMethod?.isNotEmpty ?? false) {
      if (result.isNotEmpty) {
        result += ' ';
      }
      result += "$instructionMethod";
    }

    return result;
  }
  
  Color? get uiColor => Styles().colors?.eventColor;
}

extension StudentCourseSectionExt on StudentCourseSection {
  
  static const Map<String, int> _dayAbbreviations = <String, int>{
    "M"  : DateTime.monday,
    "Tu" : DateTime.tuesday,
    "W"  : DateTime.wednesday,
    "Th" : DateTime.thursday,
    "F"  : DateTime.friday,
    "S"  : DateTime.saturday,
    "Su" : DateTime.sunday
  };

  String get displaySchedule {
    String displayDaysStr = displayDays;
    String displayTimeStr = displayTime;
    if (displayDaysStr.isNotEmpty) {
      return displayTimeStr.isNotEmpty ? "$displayDaysStr $displayTimeStr" : displayDaysStr;
    }
    else {
      return displayTimeStr;
    }
  }

  String get displayDays {
    String? result;
    if (days != null) {
      List<String>? dayNames = <String>[];
      List<String> dayAbbreviations = days!.split(',');
      for (String dayAbbreviation in dayAbbreviations) {
        String? dayName;
        int? dayNum = _dayAbbreviations[dayAbbreviation];
        if (dayNum != null) {
          switch(dayNum) {
            case DateTime.monday:    dayName = Localization().getStringEx('model.explore.time.mon', 'Mon'); break;
            case DateTime.tuesday:   dayName = Localization().getStringEx('model.explore.time.tue', 'Tue'); break;
            case DateTime.wednesday: dayName = Localization().getStringEx('model.explore.time.wed', 'Wed'); break;
            case DateTime.thursday:  dayName = Localization().getStringEx('model.explore.time.thu', 'Thu'); break;
            case DateTime.friday:    dayName = Localization().getStringEx('model.explore.time.fri', 'Fri'); break;
            case DateTime.saturday:  dayName = Localization().getStringEx('model.explore.time.sat', 'Sat'); break;
            case DateTime.sunday:    dayName = Localization().getStringEx('model.explore.time.sun', 'Sun'); break;
          }
        }
        dayNames.add(dayName ?? dayAbbreviation);
      }
      result = dayNames.join(', ');
    }

    return result ?? '';
  }

  String get displayTime {
    String startTimeStr = startTime ?? '';
    String endTimeStr = endTime ?? '';
    if (startTimeStr == endTimeStr) {
      return _convertTime(startTimeStr) ?? startTimeStr;
    }
    else {
      if (startTimeStr.isNotEmpty) {
        if (endTimeStr.isNotEmpty) {
          String startTimeStr2 = _convertTime(startTimeStr, addIndicator: false) ?? startTimeStr;
          String endTimeStr2 = _convertTime(endTimeStr) ?? endTimeStr;
          return "$startTimeStr2 - $endTimeStr2";
        }
        else {
          return _convertTime(startTimeStr) ?? startTimeStr;
        }
      }
      else {
        return _convertTime(endTimeStr) ?? endTimeStr;
      }
    }
  }

  static String? _convertTime(String? time, { bool addIndicator = true}) {
    if ((time != null) && (2 <= time.length)) {
      int? hours = int.tryParse(time.substring(0, 2))?.abs();
      if (hours != null) {
        String indicator;
        if ((0 <= hours) && (hours < 12)) {
          if (hours < 1) {
            hours += 12;
          }
          indicator = addIndicator ? 'am' : '';
        }
        else if ((12 <= hours) && (hours < 24)) {
          if (12 < hours) {
            hours -= 12;
          }
          indicator = addIndicator ? 'pm' : '';
        }
        else {
          indicator = '';
        }
        String minutes = time.substring(2);
        return "$hours:$minutes$indicator";
      }
    }
    return time;
  }

  String get displayLocation {
    String result = "";

    if (buildingName?.isNotEmpty ?? false) {
      if (result.isNotEmpty) {
        result += ', ';
      }
      result += buildingName!;
    }

    if (room?.isNotEmpty ?? false) {
      if (result.isNotEmpty) {
        result += ', ';
      }
      result += Localization().getStringEx('model.student_course.location.room.format', 'Room {Room}').replaceAll('{Room}', room!);
    }

    return result;
  }

}