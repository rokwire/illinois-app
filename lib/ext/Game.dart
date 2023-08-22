import 'package:flutter/material.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

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

  String? get displayTime {
    if (dateTimeUtc != null) {
      TZDateTime nowUni = DateTimeUni.nowUniOrLocal();
      TZDateTime nowMidnightUni = TZDateTimeUtils.dateOnly(nowUni);

      TZDateTime startDateTimeUni = dateTimeUtc!.toUniOrLocal();
      TZDateTime startDateTimeMidnightUni = TZDateTimeUtils.dateOnly(startDateTimeUni);
      int statDaysDiff = startDateTimeMidnightUni.difference(nowMidnightUni).inDays;

      TZDateTime? endDateTimeUni = endDateTimeUtc?.toUniOrLocal();
      TZDateTime? endDateTimeMidnightUni = (endDateTimeUni != null) ? TZDateTimeUtils.dateOnly(endDateTimeUni) : null;
      int? endDaysDiff = (endDateTimeMidnightUni != null) ? endDateTimeMidnightUni.difference(nowMidnightUni).inDays : null;

      bool differentStartAndEndDays = (statDaysDiff != endDaysDiff);

      bool showStartYear = (nowUni.year != startDateTimeUni.year);
      String startDateFormat = 'MMM d' + (showStartYear ? ', yyyy' : '');

      if ((endDaysDiff == null) || (endDaysDiff == statDaysDiff)) {

        String displayDay;
        switch(statDaysDiff) {
          case 0: displayDay = Localization().getStringEx('model.explore.date_time.today', 'Today'); break;
          case 1: displayDay = Localization().getStringEx('model.explore.date_time.tomorrow', 'Tomorrow'); break;
          default: displayDay = DateFormat(startDateFormat).format(startDateTimeUni);
        }

        if (allDay != true) {
          String displayStartTime = DateFormat((startDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(startDateTimeUni).toLowerCase();
          if ((endDateTimeUni != null) && (TimeOfDay.fromDateTime(startDateTimeUni) != TimeOfDay.fromDateTime(endDateTimeUni))) {
            String displayEndTime = DateFormat((endDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(endDateTimeUni).toLowerCase();
            return Localization().getStringEx('model.explore.date_time.from_to.format', '{{day}} from {{start_time}} to {{end_time}}').
            replaceAll('{{day}}', displayDay).
            replaceAll('{{start_time}}', displayStartTime).
            replaceAll('{{end_time}}', displayEndTime);
          }
          else {
            return Localization().getStringEx('model.explore.date_time.at.format', '{{day}} at {{time}}').
            replaceAll('{{day}}', displayDay).
            replaceAll('{{time}}', displayStartTime);
          }
        }
        else {
          return displayDay;
        }
      }
      else {
        String displayDateTime = DateFormat(startDateFormat).format(startDateTimeUni);
        if (allDay != true) {
          displayDateTime += showStartYear ? ' ' : ', ';
          displayDateTime += DateFormat((startDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(startDateTimeUni).toLowerCase();
        }

        if ((endDateTimeUni != null) && (differentStartAndEndDays || (allDay != true))) {
          bool showEndYear = (nowUni.year != endDateTimeUni.year);
          String endDateFormat = 'MMM d' + (showEndYear ? ', yyyy' : '');

          displayDateTime += ' - ';
          if (differentStartAndEndDays) {
            displayDateTime += DateFormat(endDateFormat).format(endDateTimeUni);
          }
          if (allDay != true) {
            displayDateTime += differentStartAndEndDays ? ', ' : '';
            displayDateTime += DateFormat((endDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(endDateTimeUni).toLowerCase();
          }
        }
        return displayDateTime;
      }
    }
    else {
      return null;
    }
  }

}