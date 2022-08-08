
import 'package:illinois/model/StudentCourse.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/localization.dart';

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
  
  String? get displayDays {
    String? result;
    if (days != null) {
      List<String>? dayNames = <String>[];
      DateTime now = DateTime.now();
      DateTime nowUni = AppDateTime().getUniLocalTimeFromUtcTime(now.toUtc()) ?? now;
      int todayNum = nowUni.weekday;
      int tomorrowNum = todayNum % DateTime.daysPerWeek + 1;
      List<String> dayAbbreviations = days!.split(',');
      for (String dayAbbreviation in dayAbbreviations) {
        String? dayName;
        int? dayNum = _dayAbbreviations[dayAbbreviation];
        if (dayNum != null) {
          if (dayNum == todayNum) {
            dayName = Localization().getStringEx('model.explore.time.today', 'Today');
          }
          else if (dayNum == tomorrowNum) {
            dayName = Localization().getStringEx('model.explore.time.tomorrow', 'Tomorrow');
          }
          else {
            switch(dayNum) {
              case DateTime.monday:    dayName = Localization().getStringEx('model.explore.time.monday', 'Monday'); break;
              case DateTime.tuesday:   dayName = Localization().getStringEx('model.explore.time.tuesday', 'Tuesday'); break;
              case DateTime.wednesday: dayName = Localization().getStringEx('model.explore.time.wednesday', 'Wednesday'); break;
              case DateTime.thursday:  dayName = Localization().getStringEx('model.explore.time.thursday', 'Thursday'); break;
              case DateTime.friday:    dayName = Localization().getStringEx('model.explore.time.friday', 'Friday'); break;
              case DateTime.saturday:  dayName = Localization().getStringEx('model.explore.time.saturday', 'Saturday'); break;
              case DateTime.sunday:    dayName = Localization().getStringEx('model.explore.time.sunday', 'Sunday'); break;
            }
          }
        }
        dayNames.add(dayName ?? dayAbbreviation);
      }
      result = dayNames.join(', ');
    }

    return result;
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
      int? hours = int.tryParse(time.substring(0, 2));
      if (hours != null) {
        String indicator;
        if (12 < hours) {
          hours -= 12;
          indicator = 'pm';
        }
        else {
          indicator = 'am';
        }
        String minutesStr = time.substring(2);
        String indicatorStr = addIndicator ? indicator : '';
        return "$hours:$minutesStr$indicatorStr";
      }
    }
    return null;
  }


}