
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Content.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

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

String? eventSortTypeToDisplayString(EventSortType? value) {
  switch (value) {
    case EventSortType.dateTime: return Localization().getStringEx('model.event2.sort_type.date_time', 'Date & Time');
    case EventSortType.alphabetical: return Localization().getStringEx('model.event2.sort_type.alphabetical', 'Alphabetical');
    case EventSortType.proximity: return Localization().getStringEx('model.event2.sort_type.proximity', 'Proximity');
    default: return null;
  }
}

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

EventTypeFilter? eventTypeFilterFromDisplayString(String? value) {
  for (EventTypeFilter entry in EventTypeFilter.values) {
    if (value == eventTypeFilterToDisplayString(entry)) {
      return entry;
    }
  }
  return null;
}

List<EventTypeFilter>? eventTypeFilterListFromDisplayList(List<String>? values) {
  if (values != null) {
    List<EventTypeFilter> list = <EventTypeFilter>[];
    for (String value in values) {
      EventTypeFilter? entry = eventTypeFilterFromDisplayString(value);
      if (entry != null) {
        list.add(entry);
      }
    }
    return list;
  }
  return null;
}

List<String>? eventTypeFilterListToDisplayList(List<EventTypeFilter>? values) {
  if (values != null) {
    List<String> list = <String>[];
    for (EventTypeFilter value in values) {
      String? entry = eventTypeFilterToDisplayString(value);
      if (entry != null) {
        list.add(entry);
      }
    }
    return list;
  }
  return null;
}
