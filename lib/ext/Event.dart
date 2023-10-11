import 'dart:ui';

import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension EventExt on Event {

  // Explore
  bool get displayAsInPerson =>
       isInPerson ?? !(isVirtual == true); // if (isInPerson == null && isVirtual == null) => isInPerson = true //Old event that miss isInPerson flag should be InPerson events by default

  bool get displayAsVirtual =>
      isVirtual ?? false;

  String? get typeDisplayString => ((displayAsVirtual == true) ? Localization().getStringEx('panel.explore_detail.event_type.online', "Online Event") : "" )
      +(displayAsVirtual && displayAsInPerson  ? ", " : "")
      +((displayAsInPerson == true) ? Localization().getStringEx('panel.explore_detail.event_type.in_person', "In-person event") : "");

  bool get isFavorite => isRecurring
    ? Auth2().isListFavorite(recurringEvents?.cast<Favorite>())
    : Auth2().isFavorite(this);

  void toggleFavorite() {
    if (isRecurring) {
      Auth2().prefs?.toggleListFavorite(recurringEvents?.cast<Favorite>());
    }
    else {
      Auth2().prefs?.toggleFavorite(this);
    }
  }

  Map<String, dynamic>? get analyticsAttributes => {
    Analytics.LogAttributeEventId: id,
    Analytics.LogAttributeEventName: title,
    Analytics.LogAttributeEventCategory: category,
    Analytics.LogAttributeRecurrenceId: recurrenceId,
    Analytics.LogAttributeLocation : location?.analyticsValue,
  };

  Color? get uiColor => Styles().colors?.eventColor;

  String? get eventImageUrl => StringUtils.isNotEmpty(exploreImageURL) ? exploreImageURL : randomImageUrl;

  String? get randomImageUrl {
    if (randomImageURL == null) {
      String listKey = ((category == "Athletics" || category == "Recreation") && (registrationLabel != null && registrationLabel!.isNotEmpty)) ?
        'sports.$registrationLabel' : 'events.$category';
      randomImageURL = Content().randomImageUrl(listKey);
    }
    return randomImageURL;
  }

  // Event

  ///
  /// Specific for Events with 'Athletics' category
  ///
  /// Requirement 1 (Deprecated! since 08/11/2021):
  /// 'When in explore/events and the category is athletics, do not show the time anymore, just the date. Also do not process it for timezone (now we go to athletics detail panel we will rely on how detail already deals with any issues)'
  ///
  /// Requirement 2: 'If an event is longer than 1 day, then please show the Date as (for example) Sep 26 - Sep 29.'
  ///
  /// Requirement 3 (Since 08/11/2021): Display start time for Athletics events
  ///

  String? get displayDateTime {
    String dateFormat = 'MMM dd';
    if (isMoreThanOneDay) {
      if (isNotTheSameYear) {
        dateFormat += ' yyyy';
      }
      String? startDateFormatted = AppDateTime().formatDateTime(startDateGmt, format: dateFormat);
      String? endDateFormatted = AppDateTime().formatDateTime(endDateGmt, format: dateFormat);
      return '$startDateFormatted - $endDateFormatted';
    } else {
      return AppDateTimeUtils.getDisplayDateTime(startDateGmt, allDay: allDay);
    }
  }

  String? get displayDate => AppDateTimeUtils.getDisplayDay(dateTimeUtc: startDateGmt, allDay: allDay);

  String? get displayStartEndTime {
    if (allDay!) {
      return Localization().getStringEx('model.explore.date_time.all_day', 'All day');
    }
    String? startTime = AppDateTimeUtils.getDisplayTime(dateTimeUtc: startDateGmt, allDay: allDay);
    String? endTime = AppDateTimeUtils.getDisplayTime(dateTimeUtc: endDateGmt, allDay: allDay);
    String displayTime = '$startTime';
    if (StringUtils.isNotEmpty(endTime)) {
      displayTime += '-$endTime';
    }
    return displayTime;
  }

  String? get displaySuperTime {
    String? date = AppDateTimeUtils.getDisplayDay(dateTimeUtc: startDateGmt, allDay: allDay);
    String? time = displayStartEndTime;
    return '$date, $time';
  }

  String? get displayRecurringDates {
    if ((recurringEvents != null) && isRecurring) {
      Event? first = recurringEvents!.first;
      Event? last = recurringEvents!.last;
      return _buildDisplayDates(first, last);
    }
    else {
      return null;
    }
  }

  String? get displaySuperDates {
    if (isSuperEvent == true) {
      if (subEvents != null && subEvents!.isNotEmpty) {
        Event first = subEvents!.first;
        Event last = subEvents!.last;
        return _buildDisplayDates(first, last);
      }
      else {
        return displayDateTime;
      }
    }
    else {
      return null;
    }
  }

  String? get timeDisplayString {
      if (isRecurring) {
        return displayRecurringDates;
      } else if (isSuperEvent == true) {
        return displaySuperDates;
      }
      else {
        return displayDateTime;
      }
  }

  static String? _buildDisplayDates(Event firstEvent, Event? lastEvent) {
    bool useDeviceLocalTime = Storage().useDeviceLocalTimeZone!;
    DateTime? startDateTime;
    DateTime? endDateTime;
    if (useDeviceLocalTime) {
      startDateTime = AppDateTime().getDeviceTimeFromUtcTime(firstEvent.startDateGmt);
      endDateTime = AppDateTime().getDeviceTimeFromUtcTime(lastEvent!.startDateGmt);
    } else {
      startDateTime = AppDateTime().getUniLocalTimeFromUtcTime(firstEvent.startDateGmt);
      endDateTime = AppDateTime().getUniLocalTimeFromUtcTime(lastEvent!.startDateGmt);
    }
    bool sameDay = ((startDateTime != null) && (endDateTime != null) && (startDateTime.year == endDateTime.year) &&
        (startDateTime.month == endDateTime.month) && (startDateTime.day == endDateTime.day));
    String? startDateString = AppDateTimeUtils.getDisplayDay(dateTimeUtc: firstEvent.startDateGmt, allDay: firstEvent.allDay);
    if (sameDay) {
      return startDateString;
    }
    String? endDateString = AppDateTimeUtils.getDisplayDay(dateTimeUtc: lastEvent.startDateGmt, allDay: lastEvent.allDay);
    return '$startDateString - $endDateString';
  }

  String get displayInterests {
    String interests = "";
    if (CollectionUtils.isNotEmpty(tags)) {
      tags!.forEach((String tag){
          if(Auth2().prefs?.hasPositiveTag(tag) ?? false) {
            if (interests.isNotEmpty) {
              interests += ", ";
            }
            interests += tag;
          }
      });
    }
    return interests;
  }
}