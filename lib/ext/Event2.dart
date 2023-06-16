
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
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
}

// EventSortType

String? eventSortTypeToDisplayString(EventSortType? value) {
  switch (value) {
    case EventSortType.dateTime: return Localization().getStringEx('model.event2.sort_type.date_time', 'Date & Time');
    case EventSortType.alphabetical: return Localization().getStringEx('model.event2.sort_type.alphabetical', 'Alphabetical');
    case EventSortType.proximity: return Localization().getStringEx('model.event2.sort_type.proximity', 'Proximity');
    default: return null;
  }
}

String? eventSortTypeToDisplayStatusString(EventSortType? value) {
  switch (value) {
    case EventSortType.dateTime: return Localization().getStringEx('model.event2.sort_type.status.date_time', 'by Date & Time');
    case EventSortType.alphabetical: return Localization().getStringEx('model.event2.sort_type.status.alphabetical', 'Alphabetically');
    case EventSortType.proximity: return Localization().getStringEx('model.event2.sort_type.status.proximity', 'by Proximity');
    default: return null;
  }
}

// EventTypeFilter

String? eventTypeFilterToDisplayString(EventTypeFilter? value) {
  switch (value) {
    case EventTypeFilter.free: return Localization().getStringEx('model.event2.event_type.free', 'Free');
    case EventTypeFilter.paid: return Localization().getStringEx('model.event2.event_type.paid', 'Paid');
    case EventTypeFilter.inPerson: return Localization().getStringEx('model.event2.event_type.in_person', 'In-person');
    case EventTypeFilter.online: return Localization().getStringEx('model.event2.event_type.online', 'Online');
    case EventTypeFilter.public: return Localization().getStringEx('model.event2.event_type.public', 'Public');
    case EventTypeFilter.private: return Localization().getStringEx('model.event2.event_type.private', 'Private');
    case EventTypeFilter.nearby: return Localization().getStringEx('model.event2.event_type.nearby', 'Nearby');
    default: return null;
  }
}

// EventTimeFilter

String? eventTimeFilterToDisplayString(EventTimeFilter? value) {
  switch (value) {
    case EventTimeFilter.upcoming: return Localization().getStringEx("model.event2.event_time.upcoming", "Upcoming");
    case EventTimeFilter.today: return Localization().getStringEx("model.event2.event_time.today", "Today");
    case EventTimeFilter.tomorrow: return Localization().getStringEx("model.event2.event_time.tomorrow", "Tomorrow");
    case EventTimeFilter.thisWeek: return Localization().getStringEx("model.event2.event_time.this_week", "This week");
    case EventTimeFilter.thisWeekend: return Localization().getStringEx("model.event2.event_time.this_weekend", "This weekend");
    case EventTimeFilter.nextWeek: return Localization().getStringEx("model.event2.event_time.next_week", "Next week");
    case EventTimeFilter.nextWeekend: return Localization().getStringEx("model.event2.event_time.next_weekend", "Next weekend");
    case EventTimeFilter.thisMonth: return Localization().getStringEx("model.event2.event_time.this_month", "This month");
    case EventTimeFilter.nextMonth: return Localization().getStringEx("model.event2.event_time.next_month", "Next month");
    case EventTimeFilter.customRange: return Localization().getStringEx("model.event2.event_time.custom_range", "Choose");
    default: return null;
  }
}

String? eventTimeFilterDisplayInfo(EventTimeFilter? value, { DateTime? customStartTimeUtc, DateTime? customEndTimeUtc }) {
  final String dateFormat = 'MM/dd';
  Map<String, dynamic> options = <String, dynamic>{};
  Events2Query.buildTimeLoadOptions(options, value, customStartTimeUtc: customStartTimeUtc, customEndTimeUtc: customEndTimeUtc);

  int? startTimeEpoch = JsonUtils.intValue(options['end_time_after']);
  TZDateTime? startTimeUni = (startTimeEpoch != null) ? DateTime.fromMillisecondsSinceEpoch(startTimeEpoch * 1000).toUniOrLocal() : null;

  int? endTimeEpoch = JsonUtils.intValue(options['start_time_before']);
  TZDateTime? endTimeUni = (endTimeEpoch != null) ? DateTime.fromMillisecondsSinceEpoch(endTimeEpoch * 1000).toUniOrLocal() : null;

  if (value == EventTimeFilter.upcoming) {
    return null;
  }
  else if ((value == EventTimeFilter.today) || (value == EventTimeFilter.tomorrow)) {
    return (startTimeUni != null) ? DateFormat(dateFormat).format(startTimeUni) : null;
  }
  else {
    String? displayStartTime = (startTimeUni != null) ? DateFormat(dateFormat).format(startTimeUni) : null;
    String? displayEndTime = (endTimeUni != null) ? DateFormat(dateFormat).format(endTimeUni) : null;
    return ((displayStartTime != null) && (displayEndTime != null)) ? '$displayStartTime - $displayEndTime' : null;
  }

}
