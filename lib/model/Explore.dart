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
import 'package:geolocator/geolocator.dart' as Core;

import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';

import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Event.dart';

import 'package:illinois/model/Location.dart';
import 'package:rokwire_plugin/utils/utils.dart';

//////////////////////////////
/// Explore

abstract class Explore {

  String?   get exploreId;
  String?   get exploreTitle;
  String?   get exploreSubTitle;
  String?   get exploreShortDescription;
  String?   get exploreLongDescription;
  DateTime? get exploreStartDateUtc;
  String?   get exploreImageURL;
  String?   get explorePlaceId;
  Location? get exploreLocation;
  Color?    get uiColor;
  Map<String, dynamic> get analyticsAttributes;
  Map<String, dynamic> toJson();

  Map<String, dynamic>? get analyticsSharedExploreAttributes {
    return exploreLocation?.analyticsAttributes;
  }

  bool get isFavorite {
    return (this is Favorite) && Auth2().isFavorite(this as Favorite);
  }

  void toggleFavorite() {
    if (this is Favorite) {
      Auth2().prefs?.toggleFavorite(this as Favorite);
    }
  }

  static bool canJson(Map<String, dynamic> json) {
    return false;
  }

  static Explore? fromJson(Map<String, dynamic>? json) {
    if (Event.canJson(json)) {
      return Event.fromJson(json);
    }
    else if (Dining.canJson(json)) {
      return Dining.fromJson(json);
    }
    return null;
  }

  static List<Explore>? listFromJson(List<dynamic>? jsonList) {
    List<Explore>? explores;
    if (jsonList is List) {
      explores = [];
      for (dynamic jsonEntry in jsonList) {
        Explore? explore = Explore.fromJson(jsonEntry);
        if (explore != null) {
          explores.add(explore);
        }
      }
    }
    return explores;
  }

  static List<dynamic>? listToJson(List<Explore>? explores) {
    List<dynamic>? result;
    if (explores != null) {
      result = [];
      for (Explore explore in explores) {
        result.add(explore.toJson());
      }
    }
    return result;
  }

}

//////////////////////////////
/// ExploreCategory

class ExploreCategory {

  final String? name;
  final List<String>? subCategories;

  ExploreCategory({this.name, this.subCategories});

  static ExploreCategory? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ExploreCategory(
      name: json['category'],
      subCategories: JsonUtils.listStringsValue(json['subcategories'])
    ) : null;
  }

  toJson(){
    return{
      'category': name,
      'subcategories': subCategories
    };
  }

  static List<ExploreCategory>? listFromJson(List<dynamic>? jsonList) {
    List<ExploreCategory>? result;
    if (jsonList is List) {
      result = <ExploreCategory>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, ExploreCategory.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

}

//////////////////////////////
/// ExploreHelper

class ExploreHelper {

  static String? getShortDisplayLocation(Explore? explore, Core.Position? locationData) {
    if (explore != null) {
      Location? location = explore.exploreLocation;
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
      Location? location = explore.exploreLocation;
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
}