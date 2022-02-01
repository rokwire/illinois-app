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

import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
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
  }

}