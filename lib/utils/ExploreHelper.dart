/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:ui';

import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:geolocator/geolocator.dart' as Core;

//////////////////////////////
/// ExploreHelper

class ExploreHelper {

  static String? getShortDisplayLocation(Explore? explore, Core.Position? locationData) {
    if (explore != null) {
      ExploreLocation? location = explore.exploreLocation;
      if (location != null) {
        if ((locationData != null) && (location.latitude != null) && (location.longitude != null)) {
          double distance = LocationUtils.distance(location.latitude!.toDouble(), location.longitude!.toDouble(), locationData.latitude, locationData.longitude);
          return distance.toStringAsFixed(1) + " mi away";
        }
        if ((location.description != null) && location.description!.isNotEmpty) {
          return location.description;
        }
        if ((location.name != null) && (explore.exploreTitle != null) && (location.name == explore.exploreTitle)) {
          if ((location.building != null) && location.building!.isNotEmpty) {
            return location.building;
          }
        }
        else {
          String displayName = location.getDisplayName();
          if (displayName.isNotEmpty) {
            return displayName;
          }
        }
        String displayAddress = location.getDisplayAddress();
        if (displayAddress.isNotEmpty) {
          return displayAddress;
        }
      }
    }
    return null;
  }

  static String? getLongDisplayLocation(Explore? explore, Core.Position? locationData) {
    if (explore != null) {
      String displayText = "";
      ExploreLocation? location = explore.exploreLocation;
      if (location != null) {
        if ((locationData != null) && (location.latitude != null) && (location.longitude != null)) {
          double distance = LocationUtils.distance(location.latitude!.toDouble(), location.longitude!.toDouble(), locationData.latitude, locationData.longitude);
          displayText = distance.toStringAsFixed(1) + " mi away";
        }
        if ((location.description != null) && location.description!.isNotEmpty) {
          return displayText += (displayText.isNotEmpty ? ", " : "")  + location.description!;
        }
        if ((location.name != null) && (explore.exploreTitle != null) && (location.name == explore.exploreTitle)) {
          if ((location.building != null) && location.building!.isNotEmpty) {
            return displayText += (displayText.isNotEmpty ? ", " : "")  + location.building!;
          }
        }
        else {
          String displayName = location.getDisplayName();
          if (displayName.isNotEmpty) {
            return displayText += (displayText.isNotEmpty ? ", " : "")  + displayName;
          }
        }
        String displayAddress = location.getDisplayAddress();
        if ( displayAddress.isNotEmpty) {
          return displayText += (displayText.isNotEmpty ? ", " : "")  + displayAddress;
        }
      }
    }
    return null;
  }

  static String? getExploresListDisplayTitle(List<Explore>? exploresList) {
    String? exploresType;
    if (exploresList != null) {
      for (Explore explore in exploresList) {
        String exploreType = explore.runtimeType.toString().toLowerCase();
        if (exploresType == null) {
          exploresType = exploreType;
        }
        else if (exploresType != exploreType) {
          exploresType = null;
          break;
        }
      }
    }

    if (exploresType == "event") {
      return Localization().getStringEx('panel.explore.item.events.name', 'Events');
    }
    else if (exploresType == "dining") {
      return Localization().getStringEx('panel.explore.item.dinings.name', 'Dinings');
    }
    else if (exploresType == "place") {
      return Localization().getStringEx('panel.explore.item.places.name', 'Places');
    }
    else {
      return Localization().getStringEx('panel.explore.item.unknown.name', 'Explores');
    }
  }

  static String? getExploreTypeText(Explore? explore) {
    if (explore != null) {
      if (explore is Event) {
        bool isVirtual = explore.isVirtual ?? false;
        return isVirtual
            ? Localization().getStringEx('panel.explore_detail.event_type.online', "Online event")
            : Localization().getStringEx('panel.explore_detail.event_type.in_person', "In-person event");
      } else if (explore is Game) {
        return Localization().getStringEx('panel.explore_detail.event_type.in_person', "In-person event");
      }
    }
    return null;
  }

  // Favorites

  static bool isFavorite(Explore? explore) {
    if (explore is Favorite) {
      return ((explore is Event) && explore.isRecurring) ?
        Auth2().isListFavorite(explore.recurringEvents?.cast<Favorite>()) :
        Auth2().isFavorite(explore as Favorite);
    }
    return false;
  }

  static bool toggleFavorite(Explore? explore) {
    if (explore is Favorite) {
      if ((explore is Event) && explore.isRecurring) {
        List<Favorite>? favorites = explore.recurringEvents?.cast<Favorite>();
        Auth2().prefs?.setListFavorite(favorites, !Auth2().isListFavorite(favorites));
      }
      else {
        Auth2().prefs?.toggleFavorite(explore as Favorite);
      }
    }
    return false;
  }

  // Analytics

  static Map<String, dynamic>? analyticsAttributes(Explore? explore) {
    if (explore is Event) {
      return {
        Analytics.LogAttributeEventId:   explore.exploreId,
        Analytics.LogAttributeEventName: explore.exploreTitle,
        Analytics.LogAttributeEventCategory: explore.category,
        Analytics.LogAttributeRecurrenceId: explore.recurrenceId,
        Analytics.LogAttributeLocation : explore.location?.analyticsValue,
      };
    }
    else if (explore is Dining) {
      return {
        Analytics.LogAttributeDiningId:   explore.exploreId,
        Analytics.LogAttributeDiningName: explore.exploreTitle,
        Analytics.LogAttributeLocation : explore.location?.analyticsValue,
      };
    }
    else if (explore is Game) {
      return {
        Analytics.LogAttributeGameId: explore.id,
        Analytics.LogAttributeGameName: explore.title,
        Analytics.LogAttributeLocation : explore.location?.analyticsValue,
      };
    }
    else {
      return null;
    }
  }

  // Styles

  static Color? uiColor(Explore? explore) {
    if (explore is Event) {
      return Styles().colors!.eventColor;
    }
    else if (explore is Dining) {
      return Styles().colors!.diningColor;
    }
    else if (explore is Game) {
      return Styles().colors!.eventColor;
    }
    else {
      return null;
    }
  }

  // Image

  static String? exploreImageURL(Explore? explore) {
    return (explore is Event) ? EventHelper.exploreImageURL(explore) : explore?.exploreImageURL;
  }
}

//////////////////////////////
/// EventHelper

class EventHelper {
  
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

  static String? displayDateTime(Event? event) {
    if (event != null) {
      final String dateFormat = 'MMM dd';
      int eventDays = (event.endDateGmt?.difference(event.startDateGmt!).inDays ?? 0).abs();
      bool eventIsMoreThanOneDay = (eventDays >= 1);
      if (eventIsMoreThanOneDay) {
        String? startDateFormatted = AppDateTime().formatDateTime(event.startDateGmt, format: dateFormat);
        String? endDateFormatted = AppDateTime().formatDateTime(event.endDateGmt, format: dateFormat);
        return '$startDateFormatted - $endDateFormatted';
      } else {
        return AppDateTimeUtils.getDisplayDateTime(event.startDateGmt, allDay: event.allDay);
      }
    }
    else {
      return null;
    }
  }

  static String? displayDate(Event? event) {
    return (event != null) ? AppDateTimeUtils.getDisplayDay(dateTimeUtc: event.startDateGmt, allDay: event.allDay) : null;
  }

  static String? displayStartEndTime(Event? event) {
    if (event != null) {
      if (event.allDay!) {
        return Localization().getStringEx('model.explore.time.all_day', 'All day');
      }
      String? startTime = AppDateTimeUtils.getDisplayTime(dateTimeUtc: event.startDateGmt, allDay: event.allDay);
      String? endTime = AppDateTimeUtils.getDisplayTime(dateTimeUtc: event.endDateGmt, allDay: event.allDay);
      String displayTime = '$startTime';
      if (StringUtils.isNotEmpty(endTime)) {
        displayTime += '-$endTime';
      }
      return displayTime;
    }
    else {
      return null;
    }
  }

  static String? displaySuperTime(Event? event) {
    if (event != null) {
      String? date = AppDateTimeUtils.getDisplayDay(dateTimeUtc: event.startDateGmt, allDay: event.allDay);
      String? time = displayStartEndTime(event);
      return '$date, $time';
    }
    else {
      return null;
    }
  }

  static String? displayRecurringDates(Event? event) {
    if ((event != null) && (event.recurringEvents != null) && event.isRecurring) {
      Event? first = event.recurringEvents!.first;
      Event? last = event.recurringEvents!.last;
      return _buildDisplayDates(first, last);
    }
    else {
      return null;
    }
  }

  static String? displaySuperDates(Event? event) {
    if ((event != null) && (event.isSuperEvent == true)) {
      if (event.subEvents != null && event.subEvents!.isNotEmpty) {
        Event first = event.subEvents!.first;
        Event last = event.subEvents!.last;
        return _buildDisplayDates(first, last);
      }
      else {
        return displayDateTime(event);
      }
    }
    else {
      return null;
    }
  }

  static String? timeDisplayString(Event? event) {
    if (event != null) {
      if (event.isRecurring) {
        return displayRecurringDates(event);
      } else if (event.isSuperEvent == true) {
        return displaySuperDates(event);
      }
    }
    return displayDateTime(event);
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

  static String displayInterests(Event? event) {
    String interests = "";
    if ((event != null) && CollectionUtils.isNotEmpty(event.tags)) {
      event.tags!.forEach((String tag){
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

  static String? exploreImageURL(Event? event) {
    String? imageUrl = event?.exploreImageURL;
    if (StringUtils.isEmpty(imageUrl)) {
      imageUrl = randomImageURL(event);
    }
    return imageUrl;
  }

  static String? randomImageURL(Event? event) {
    if (event != null) {
      if (event.randomImageURL == null) {
        String listKey = ((event.category == "Athletics" || event.category == "Recreation") && (event.registrationLabel != null && event.registrationLabel!.isNotEmpty)) ?
          'images.random.sports.${event.registrationLabel}' : 'images.random.events.${event.category}';
        event.randomImageURL = Assets().randomStringFromListWithKey(listKey);
      }
    }
    return event?.randomImageURL;
  }

}
