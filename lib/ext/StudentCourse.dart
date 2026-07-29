
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

    if (section?.sectionId?.isNotEmpty ?? false) {
      if (result.isNotEmpty) {
        result += ' ';
      }
      result += "(${section?.sectionId})";
    }

    return result;
  }
  
  Color? get uiColor => Styles().colors.eventColor;
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

  String get comparableValue {
    List<String>? dayStringNumbers = <String>[];
    if (days != null) {
      List<String> dayAbbreviations = days!.split(',');
      for (String dayAbbreviation in dayAbbreviations) {
        int? dayNum = _dayAbbreviations[dayAbbreviation];
        if (dayNum != null) {
          dayStringNumbers.add(dayNum.toString());
        }
      }
    }
    String daysString = dayStringNumbers.join('');
    String timeString = startTime ?? (endTime ?? '');
    String resultString = daysString + timeString;
    return resultString;
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

  bool get isInPerson => (buildingId?.isNotEmpty == true) || (building?.hasValidLocation == true);

  List<int> get weekdays {
    List<int> result = <int>[];
    if (days != null) {
      for (String dayAbbreviation in days!.split(',')) {
        int? weekday = _dayAbbreviations[dayAbbreviation];
        if (weekday != null) {
          result.add(weekday);
        }
      }
    }
    return result;
  }

  int? get startTimeMinutes => _parseTimeMinutes(startTime);
  int? get endTimeMinutes => _parseTimeMinutes(endTime);

  static int? _parseTimeMinutes(String? time) {
    if ((time != null) && (4 <= time.length)) {
      int? hours = int.tryParse(time.substring(0, 2));
      int? minutes = int.tryParse(time.substring(2, 4));
      if ((hours != null) && (minutes != null)) {
        return (hours * 60) + minutes;
      }
    }
    return null;
  }

  ///
  /// Parses the backend's "MM/DD/YYYY - MM/DD/YYYY" meeting_dates_or_range string.
  /// Returns null (rather than throwing) if the value is missing or not in the expected format.
  ///
  DateTimeRange? get meetingDateRange {
    List<String> parts = meetingDates?.split('-') ?? <String>[];
    if (parts.length == 2) {
      DateTime? start = _parseMeetingDate(parts[0]);
      DateTime? end = _parseMeetingDate(parts[1]);
      if ((start != null) && (end != null)) {
        return DateTimeRange(start: start, end: end);
      }
    }
    return null;
  }

  static DateTime? _parseMeetingDate(String value) {
    List<String> parts = value.trim().split('/');
    if (parts.length == 3) {
      int? month = int.tryParse(parts[0]);
      int? day = int.tryParse(parts[1]);
      int? year = int.tryParse(parts[2]);
      if ((month != null) && (day != null) && (year != null)) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }
}