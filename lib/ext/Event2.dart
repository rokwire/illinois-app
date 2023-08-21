
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Content.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

// Event2

extension Event2Ext on Event2 {

  bool get hasSurvey => (attendanceDetails?.isNotEmpty ?? false) && (surveyDetails?.isNotEmpty ?? false);
  bool get hasLinkedEvents => (isSuperEvent || isRecurring);

  Color? get uiColor => Styles().colors?.eventColor;

  String? get displayImageUrl => StringUtils.isNotEmpty(imageUrl) ? imageUrl : randomImageUrl;

  String? get randomImageUrl {
    if (assignedImageUrl == null) {
      dynamic category = (attributes != null) ? attributes!['category'] : null;
      assignedImageUrl = _randomImageUrlForAttribute('events', category);
    }
    if (assignedImageUrl == null) {
      dynamic sport = (attributes != null) ? attributes!['sport'] : null;
      assignedImageUrl = _randomImageUrlForAttribute('sports', sport, mapping: _sportCodes);
    }
    if (assignedImageUrl == null) {
      assignedImageUrl = Content().randomImageUrl('events.Other');
    }
    return assignedImageUrl;
  }

  String? _randomImageUrlForAttribute(String prefix, dynamic value, { Map<String, String>? mapping }) {
    if (value is String) {
      return (mapping != null) ?
        (Content().randomImageUrl('$prefix.${mapping[value]}') ?? Content().randomImageUrl('$prefix.$value')) :
        Content().randomImageUrl('$prefix.$value');
    }
    else if (value is List) {
      for (dynamic entry in value) {
        String? result = _randomImageUrlForAttribute(prefix, entry, mapping: mapping);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  static const Map<String, String> _sportCodes = {
    "Baseball" : "baseball",
    "Men's Basketball" : "mbball",
    "Men's Cross Country" : "mcross",
    "Football" : "football",
    "Men's Golf" : "mgolf",
    "Men's Gymnastics" : "mgym",
    "Men's Tennis" : "mten",
    "Men's Track Field" : "mtrack",
    "Wrestling" : "wrestling",
    "Women's Basketball" : "wbball",
    "Women's Cross Country" : "wcross",
    "Women's Golf" : "wgolf",
    "Women's Gymnastics" : "wgym",
    "Women's Soccer" : "wsoc",
    "Softball" : "softball",
    "Swim Dive" : "wswim",
    "Women's Tennis" : "wten",
    "Women's Track Field" : "wtrack",
    "Volleyball" : "wvball"
  };

  Map<String, dynamic>? get analyticsAttributes => {
    Analytics.LogAttributeEventId: id,
    Analytics.LogAttributeEventName: name,
    Analytics.LogAttributeEventAttributes: attributes,
    Analytics.LogAttributeLocation : location?.analyticsValue,
  };

  String? get shortDisplayDateAndTime => _buildDisplayDateAndTime(longFormat: false);
  String? get longDisplayDateAndTime => _buildDisplayDateAndTime(longFormat: true);
  
  String? _buildDisplayDateAndTime({bool longFormat = false}) {
    if (startTimeUtc != null) {
      TZDateTime nowUni = DateTimeUni.nowUniOrLocal();
      TZDateTime nowMidnightUni = TZDateTimeUtils.dateOnly(nowUni);

      TZDateTime startDateTimeUni = startTimeUtc!.toUniOrLocal();
      TZDateTime startDateTimeMidnightUni = TZDateTimeUtils.dateOnly(startDateTimeUni);
      int statDaysDiff = startDateTimeMidnightUni.difference(nowMidnightUni).inDays;

      TZDateTime? endDateTimeUni = endTimeUtc?.toUniOrLocal();
      TZDateTime? endDateTimeMidnightUni = (endDateTimeUni != null) ? TZDateTimeUtils.dateOnly(endDateTimeUni) : null;
      int? endDaysDiff = (endDateTimeMidnightUni != null) ? endDateTimeMidnightUni.difference(nowMidnightUni).inDays : null;

      bool differentStartAndEndDays = (statDaysDiff != endDaysDiff);

      bool showStartYear = (nowUni.year != startDateTimeUni.year);
      String startDateFormat = (longFormat ? 'EEE, MMM d' : 'MMM d') + (showStartYear ? ', yyyy' : '');

      if ((endDaysDiff == null) || (endDaysDiff == statDaysDiff)) /* no end time or start date == end date */ {
        
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
          String endDateFormat = (longFormat ? 'EEE, MMM d' : 'MMM d') + (showEndYear ? ', yyyy' : '');

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

  String? get shortDisplayDate => _buildDisplayDate(longFormat: false);
  String? get longDisplayDate => _buildDisplayDate(longFormat: true);

  String? _buildDisplayDate({bool longFormat = false}) {
    if (startTimeUtc != null) {
      TZDateTime nowUni = DateTimeUni.nowUniOrLocal();
      TZDateTime nowMidnightUni = TZDateTimeUtils.dateOnly(nowUni);

      TZDateTime startDateTimeUni = startTimeUtc!.toUniOrLocal();
      TZDateTime startDateTimeMidnightUni = TZDateTimeUtils.dateOnly(startDateTimeUni);
      int statDaysDiff = startDateTimeMidnightUni.difference(nowMidnightUni).inDays;

      TZDateTime? endDateTimeUni = endTimeUtc?.toUniOrLocal();
      TZDateTime? endDateTimeMidnightUni = (endDateTimeUni != null) ? TZDateTimeUtils.dateOnly(endDateTimeUni) : null;
      int? endDaysDiff = (endDateTimeMidnightUni != null) ? endDateTimeMidnightUni.difference(nowMidnightUni).inDays : null;

      bool differentStartAndEndDays = (statDaysDiff != endDaysDiff);

      bool showStartYear = (nowUni.year != startDateTimeUni.year);
      String startDateFormat = (longFormat ? 'EEE, MMM d' : 'MMM d') + (showStartYear ? ', yyyy' : '');

      if ((endDaysDiff == null) || (endDaysDiff == statDaysDiff)) /* no end time or start date == end date */ {
        
        String displayDay;
        switch(statDaysDiff) {
          case 0: displayDay = Localization().getStringEx('model.explore.date_time.today', 'Today'); break;
          case 1: displayDay = Localization().getStringEx('model.explore.date_time.tomorrow', 'Tomorrow'); break;
          default: displayDay = DateFormat(startDateFormat).format(startDateTimeUni);
        }

        return displayDay;
      }
      else {
        String displayDateTime = DateFormat(startDateFormat).format(startDateTimeUni);
        if ((endDateTimeUni != null) && differentStartAndEndDays) {
          bool showEndYear = (nowUni.year != endDateTimeUni.year);
          String endDateFormat = (longFormat ? 'EEE, MMM d' : 'MMM d') + (showEndYear ? ', yyyy' : '');

          displayDateTime += ' - ';
          if (differentStartAndEndDays) {
            displayDateTime += DateFormat(endDateFormat).format(endDateTimeUni);
          }
        }
        return displayDateTime;
      }
    }
    else {
      return null;
    }
  }

  String? get shortDisplayTime => _buildDisplayTime(longFormat: false);
  String? get longDisplayTime => _buildDisplayTime(longFormat: true);
  
  String? _buildDisplayTime({bool longFormat = false}) {
    if (startTimeUtc != null) {
      TZDateTime nowUni = DateTimeUni.nowUniOrLocal();
      TZDateTime nowMidnightUni = TZDateTimeUtils.dateOnly(nowUni);

      TZDateTime startDateTimeUni = startTimeUtc!.toUniOrLocal();
      TZDateTime startDateTimeMidnightUni = TZDateTimeUtils.dateOnly(startDateTimeUni);
      int statDaysDiff = startDateTimeMidnightUni.difference(nowMidnightUni).inDays;

      TZDateTime? endDateTimeUni = endTimeUtc?.toUniOrLocal();
      TZDateTime? endDateTimeMidnightUni = (endDateTimeUni != null) ? TZDateTimeUtils.dateOnly(endDateTimeUni) : null;
      int? endDaysDiff = (endDateTimeMidnightUni != null) ? endDateTimeMidnightUni.difference(nowMidnightUni).inDays : null;

      bool differentStartAndEndDays = (statDaysDiff != endDaysDiff);

      if ((endDaysDiff == null) || (endDaysDiff == statDaysDiff)) /* no end time or start date == end date */ {
        
        if (allDay != true) {
          String displayStartTime = DateFormat((startDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(startDateTimeUni).toLowerCase();
          if ((endDateTimeUni != null) && (TimeOfDay.fromDateTime(startDateTimeUni) != TimeOfDay.fromDateTime(endDateTimeUni))) {
           String displayEndTime = DateFormat((endDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(endDateTimeUni).toLowerCase();
            return Localization().getStringEx('model.explore.time.from_to.format', '{{start_time}} to {{end_time}}').
              replaceAll('{{start_time}}', displayStartTime).
              replaceAll('{{end_time}}', displayEndTime);
          }
          else {
            return Localization().getStringEx('model.explore.time.at.format', '{{time}}').
              replaceAll('{{time}}', displayStartTime);
          }
        }
        else {
          return null;
        }
      }
      else {
        String displayDateTime = DateFormat((startDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(startDateTimeUni).toLowerCase();
        if ((endDateTimeUni != null) && (differentStartAndEndDays || (allDay != true))) {
          displayDateTime += ' - ';
          displayDateTime += DateFormat((endDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(endDateTimeUni).toLowerCase();
        }
        return displayDateTime;
      }
    }
    else {
      return null;
    }
  }

  String? getDisplayDistance(Position? userLocation) {
    double? latitude = location?.latitude;
    double? longitude = location?.longitude;
    if ((latitude != null) && (latitude != 0) && (longitude != null) && (longitude != 0) && (userLocation != null)) {
      double distanceInMeters = Geolocator.distanceBetween(latitude, longitude, userLocation.latitude, userLocation.longitude);
      double distanceInMiles = distanceInMeters / 1609.344;
      //int whole = (((distanceInMiles * 10) + 0.5).toInt() % 10);
      int displayPrecision = ((distanceInMiles < 10) && ((((distanceInMiles * 10) + 0.5).toInt() % 10) != 0)) ? 1 : 0;
      return Localization().getStringEx('model.explore.distance.format', '{{distance}} mi away').
        replaceAll('{{distance}}', distanceInMiles.toStringAsFixed(displayPrecision));
    }
    else {
      return null;
    }
  }

  bool get isSurveyAvailable {
    int? hours = surveyDetails?.hoursAfterEvent ?? 0;
    DateTime? eventTime = endTimeUtc ?? startTimeUtc;
    return (eventTime == null) || eventTime.toUtc().add(Duration(hours: hours)).isBefore(DateTime.now().toUtc());
  }

  bool get isFavorite =>
      //isRecurring //TBD Recurring id
      // ? Auth2().isListFavorite(recurringEvents?.cast<Favorite>());
      Auth2().isFavorite(this);

  bool get canUserEdit =>
      userRole == Event2UserRole.admin;

  bool get canUserDelete =>
      userRole == Event2UserRole.admin;

  bool get hasGame =>
      game != null;

  Game? get game =>
      isSportEvent ? Game.fromJson(data) : null;
}

extension Event2ContactExt on Event2Contact {
  
  String get fullName {
    if (StringUtils.isNotEmpty(firstName)) {
      if (StringUtils.isNotEmpty(lastName)) {
        return '$firstName $lastName';
      }
      else {
        return firstName ?? '';
      }
    }
    else {
        return lastName ?? '';
    }
  }
}


// Event2SortType

String? event2SortTypeToDisplayString(Event2SortType? value) {
  switch (value) {
    case Event2SortType.dateTime: return Localization().getStringEx('model.event2.sort_type.date_time', 'Date & Time');
    case Event2SortType.alphabetical: return Localization().getStringEx('model.event2.sort_type.alphabetical', 'Alphabetical');
    case Event2SortType.proximity: return Localization().getStringEx('model.event2.sort_type.proximity', 'Proximity');
    default: return null;
  }
}

String? event2SortTypeDisplayStatusString(Event2SortType? value) {
  switch (value) {
    case Event2SortType.dateTime: return Localization().getStringEx('model.event2.sort_type.status.date_time', 'Date');
    case Event2SortType.alphabetical: return Localization().getStringEx('model.event2.sort_type.status.alphabetical', 'Alpha');
    case Event2SortType.proximity: return Localization().getStringEx('model.event2.sort_type.status.proximity', 'Proximity');
    default: return null;
  }
}

// Event2SortOrder

String? event2SortOrderIndicatorDisplayString(Event2SortOrder? value) {
  switch (value) {
    case Event2SortOrder.ascending: return Localization().getStringEx('model.event2.sort_order.indicator.ascending', '⇩');
    case Event2SortOrder.descending: return Localization().getStringEx('model.event2.sort_order.indicator.descending', '⇧');
    default: return null;
  }
}

String? event2SortOrderStatusDisplayString(Event2SortOrder? value) {
  switch (value) {
    case Event2SortOrder.ascending: return Localization().getStringEx('model.event2.sort_order.status.ascending', 'Asc');
    case Event2SortOrder.descending: return Localization().getStringEx('model.event2.sort_order.status.descending', 'Desc');
    default: return null;
  }
}

// Event2TypeFilter

String? event2TypeFilterToDisplayString(Event2TypeFilter? value) {
  switch (value) {
    case Event2TypeFilter.free: return Localization().getStringEx('model.event2.event_type.free', 'Free');
    case Event2TypeFilter.paid: return Localization().getStringEx('model.event2.event_type.paid', 'Paid');
    case Event2TypeFilter.inPerson: return Localization().getStringEx('model.event2.event_type.in_person', 'In-person');
    case Event2TypeFilter.online: return Localization().getStringEx('model.event2.event_type.online', 'Online');
    case Event2TypeFilter.hybrid: return Localization().getStringEx('model.event2.event_type.hybrid', 'Hybrid');
    case Event2TypeFilter.public: return Localization().getStringEx('model.event2.event_type.public', 'Public');
    case Event2TypeFilter.private: return Localization().getStringEx('model.event2.event_type.private', 'Private');
    case Event2TypeFilter.nearby: return Localization().getStringEx('model.event2.event_type.nearby', 'Nearby');
    case Event2TypeFilter.superEvent: return Localization().getStringEx('model.event2.event_type.super_event', 'Multi-event');
    default: return null;
  }
}

// Event2TimeFilter

String? event2TimeFilterToDisplayString(Event2TimeFilter? value) {
  switch (value) {
    case Event2TimeFilter.upcoming: return Localization().getStringEx("model.event2.event_time.upcoming", "Upcoming");
    case Event2TimeFilter.today: return Localization().getStringEx("model.event2.event_time.today", "Today");
    case Event2TimeFilter.tomorrow: return Localization().getStringEx("model.event2.event_time.tomorrow", "Tomorrow");
    case Event2TimeFilter.thisWeek: return Localization().getStringEx("model.event2.event_time.this_week", "This week");
    case Event2TimeFilter.thisWeekend: return Localization().getStringEx("model.event2.event_time.this_weekend", "This weekend");
    case Event2TimeFilter.nextWeek: return Localization().getStringEx("model.event2.event_time.next_week", "Next week");
    case Event2TimeFilter.nextWeekend: return Localization().getStringEx("model.event2.event_time.next_weekend", "Next weekend");
    case Event2TimeFilter.thisMonth: return Localization().getStringEx("model.event2.event_time.this_month", "This month");
    case Event2TimeFilter.nextMonth: return Localization().getStringEx("model.event2.event_time.next_month", "Next month");
    case Event2TimeFilter.customRange: return Localization().getStringEx("model.event2.event_time.custom_range.select", "Choose");
    default: return null;
  }
}

String? event2TimeFilterDisplayInfo(Event2TimeFilter? value, { TZDateTime? customStartTime, TZDateTime? customEndTime }) {
  final String dateFormat = 'MM/dd';
  Map<String, dynamic> options = <String, dynamic>{};
  Events2Query.buildTimeLoadOptions(options, value, customStartTimeUtc: customStartTime?.toUtc(), customEndTimeUtc: customEndTime?.toUtc());

  int? startTimeEpoch = JsonUtils.intValue(options['end_time_after']);
  TZDateTime? startTimeUni = (startTimeEpoch != null) ? TZDateTime.fromMillisecondsSinceEpoch(customStartTime?.location ?? DateTimeUni.timezoneUniOrLocal, startTimeEpoch * 1000) : null;

  int? endTimeEpoch = JsonUtils.intValue(options['start_time_before']);
  TZDateTime? endTimeUni = (endTimeEpoch != null) ? TZDateTime.fromMillisecondsSinceEpoch(customEndTime?.location ?? DateTimeUni.timezoneUniOrLocal, endTimeEpoch * 1000).toUniOrLocal() : null;

  if (value == Event2TimeFilter.upcoming) {
    return null;
  }
  else if ((value == Event2TimeFilter.today) || (value == Event2TimeFilter.tomorrow)) {
    return (startTimeUni != null) ? DateFormat(dateFormat).format(startTimeUni) : null;
  }
  else {
    String? displayStartTime = (startTimeUni != null) ? DateFormat(dateFormat).format(startTimeUni) : null;
    String? displayEndTime = (endTimeUni != null) ? DateFormat(dateFormat).format(endTimeUni) : null;
    if (displayStartTime != null) {
      return (displayEndTime != null) ? '$displayStartTime - $displayEndTime' : '$displayStartTime ⇧';  
    }
    else {
      return (displayEndTime != null) ? '$displayEndTime ⇩' : null;
    }
  }

}

// Event2Type

String? event2TypeToDisplayString(Event2Type? value) {
  switch (value) {
    case Event2Type.inPerson: return Localization().getStringEx("model.event2.event_type.in_person", "In-person");
    case Event2Type.online: return Localization().getStringEx("model.event2.event_type.online", "Online");
    case Event2Type.hybrid: return Localization().getStringEx("model.event2.event_type.hybrid", "Hybrid");
    default: return null;
  }
}

String? event2ContactToDisplayString(Event2Contact? value){
  if(value == null)
    return null;

  String contactDetails = '';

  if (StringUtils.isNotEmpty(value.firstName)) {
    contactDetails += value.firstName!;
  }
  if (StringUtils.isNotEmpty(value.lastName)) {
    if (StringUtils.isNotEmpty(contactDetails)) {
      contactDetails += ' ';
    }
    contactDetails += value.lastName!;
  }
  if (StringUtils.isNotEmpty(value.organization)) {
    contactDetails += ' (${value.organization})';
  }
  if (StringUtils.isNotEmpty(value.email)) {
    if (StringUtils.isNotEmpty(contactDetails)) {
      contactDetails += ', ';
    }
    contactDetails += value.email!;
  }
  if (StringUtils.isNotEmpty(value.phone)) {
    if (StringUtils.isNotEmpty(contactDetails)) {
      contactDetails += ', ';
    }
    contactDetails += value.phone!;
  }

  return contactDetails;
}

// Event2RegistrationType

String event2RegistrationToDisplayString(Event2RegistrationType value) {
  switch (value) {
    case Event2RegistrationType.none: return Localization().getStringEx("model.event2.registration_type.none", "None");
    case Event2RegistrationType.internal: return Localization().getStringEx("model.event2.registration_type.internal", "Via the app");
    case Event2RegistrationType.external: return Localization().getStringEx("model.event2.registration_type.external", "Via external link");
  }
}
