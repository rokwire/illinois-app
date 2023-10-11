import 'package:flutter/material.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension GameExt on Game {
  
  String? get typeDisplayString {
    return Localization().getStringEx('panel.explore_detail.event_type.in_person', "In-person event");
  }

  Map<String, dynamic>? get analyticsAttributes => {
    Analytics.LogAttributeGameId: id,
    Analytics.LogAttributeGameName: title,
    Analytics.LogAttributeLocation : location?.location,
  };

  Color? get uiColor => Styles().colors?.fillColorPrimary;

  ///
  /// Note: Old requirements defined games were introduced
  ///
  /// Requirement 1:
  /// Workaround because of the wrong dates that come from server.
  /// endpoint: http://fightingillini.com/services/schedule_xml_2.aspx
  /// json example:
  ///
  /// {
  ///      ...
  ///      "date": "10/5/2019",
  ///      ...
  ///      "datetime_utc": "2019-10-05T00:00:00Z",
  ///      ...
  ///      "time": "2:30 / 3 PM CT",
  ///      ...
  /// }
  ///
  /// Requirement 2: 'If an event is longer than 1 day, then please show the Date as (for example) Sep 26 - Sep 29.'
  ///
  String? get displayTime {
    int hourUtc = dateTimeUtc!.hour;
    int minuteUtc = dateTimeUtc!.minute;
    int secondUtc = dateTimeUtc!.second;
    int millisUtc = dateTimeUtc!.millisecond;
    bool useStringDateTimes = (hourUtc == 0 && minuteUtc == 0 && secondUtc == 0 && millisUtc == 0);
    String displayDateFormat = 'MMM dd';
    if (isMoreThanOneDay) {
      if (_isNotTheSameYear) {
        displayDateFormat += ' yyyy';
      }
      DateTime? startDisplayDate = useStringDateTimes ? date : dateTimeUtc;
      DateTime? endDisplayDate = useStringDateTimes ? (endDate ?? endDateTimeUtc) : endDateTimeUtc;
      String? startDateFormatted = AppDateTime().formatDateTime(startDisplayDate, format: displayDateFormat, ignoreTimeZone: useStringDateTimes);
      String? endDateFormatted = AppDateTime().formatDateTime(endDisplayDate, format: displayDateFormat, ignoreTimeZone: useStringDateTimes);
      return '$startDateFormatted - $endDateFormatted';
    } else if (useStringDateTimes) {
      String dateFormatted = AppDateTime().formatDateTime(date, format: displayDateFormat, ignoreTimeZone: true, showTzSuffix: false)!; //another workaround
      dateFormatted += ' ${StringUtils.ensureNotEmpty(timeToString)}';
      return dateFormatted;
    } else {
      return AppDateTimeUtils.getDisplayDateTime(dateTimeUtc, allDay: allDay ?? false);
    }
  }

  bool get _isNotTheSameYear {
    int startYear = dateTimeUtc?.year ?? 0;
    int endYear = endDateTimeUtc?.year ?? 0;
    return (startYear != endYear);
  }
}