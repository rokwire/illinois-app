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
import 'package:illinois/service/Localization.dart';
import 'package:location/location.dart' as Core;

import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Event.dart';

import 'package:illinois/model/Location.dart';
import 'package:illinois/utils/Utils.dart';

//////////////////////////////
/// Explore

abstract class Explore {

  String   get exploreId;
  String   get exploreTitle;
  String   get exploreSubTitle;
  String   get exploreShortDescription;
  String   get exploreLongDescription;
  String   get exploreImageURL;
  String   get explorePlaceId;
  Location get exploreLocation;
  Color    get uiColor;
  Map<String, dynamic> get analyticsAttributes;
  Map<String, dynamic> toJson();

  Map<String, dynamic> get analyticsSharedExploreAttributes {
    return exploreLocation?.analyticsAttributes;
  }

  static bool canJson(Map<String, dynamic> json) {
    return false;
  }

  static Explore fromJson(Map<String, dynamic> json) {
    if (Event.canJson(json)) {
      return Event.fromJson(json);
    }
    else if (Dining.canJson(json)) {
      return Dining.fromJson(json);
    }
    return null;
  }

  static List<Explore> listFromJson(List<dynamic> jsonList) {
    List<Explore> explores = [];
    if (jsonList is List) {
      for (dynamic jsonEntry in jsonList) {
        Explore explore = Explore.fromJson(jsonEntry);
        if (explore != null) {
          explores.add(explore);
        }
      }
    }
    return explores;
  }

  static List<dynamic> listToJson(List<Explore> explores) {
    List<dynamic> result;
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

  final String name;
  final List<String> subCategories;

  ExploreCategory({this.name, this.subCategories});

  factory ExploreCategory.fromJson(Map<String, dynamic> json) {
    List<dynamic> subCategoriesData = json['subcategories'];
    List<String> subCategoriesList = AppCollection.isCollectionNotEmpty(subCategoriesData) ? subCategoriesData.cast() : [];
    return ExploreCategory(
      name: json['category'],
      subCategories: subCategoriesList
    );
  }

  toJson(){
    return{
      'category': name,
      'subcategories': subCategories
    };
  }

}

//////////////////////////////
/// ExploreHelper

class ExploreHelper {

  static String getShortDisplayLocation(Explore explore, Core.LocationData locationData) {
    if (explore != null) {
      Location location = explore.exploreLocation;
      if (location != null) {
        if ((locationData != null) && (location.latitude != null) && (location.longitude != null)) {
          double distance = AppLocation.distance(location.latitude, location.longitude, locationData.latitude, locationData.longitude);
          return distance.toStringAsFixed(1) + " mi away";
        }
        if ((location.description != null) && location.description.isNotEmpty) {
          return location.description;
        }
        if ((location.name != null) && (explore.exploreTitle != null) && (location.name == explore.exploreTitle)) {
          if ((location.building != null) && location.building.isNotEmpty) {
            return location.building;
          }
        }
        else {
          String displayName = location.getDisplayName();
          if ((displayName != null) && displayName.isNotEmpty) {
            return displayName;
          }
        }
        String displayAddress = location.getDisplayAddress();
        if ((displayAddress != null) && displayAddress.isNotEmpty) {
          return displayAddress;
        }
      }
    }
    return null;
  }

  static String getLongDisplayLocation(Explore explore, Core.LocationData locationData) {
    if (explore != null) {
      String displayText = "";
      Location location = explore.exploreLocation;
      if (location != null) {
        if ((locationData != null) && (location.latitude != null) && (location.longitude != null)) {
          double distance = AppLocation.distance(location.latitude, location.longitude, locationData.latitude, locationData.longitude);
          displayText = distance.toStringAsFixed(1) + " mi away";
        }
        if ((location.description != null) && location.description.isNotEmpty) {
          return displayText += (displayText.isNotEmpty ? ", " : "")  + location.description;
        }
        if ((location.name != null) && (explore.exploreTitle != null) && (location.name == explore.exploreTitle)) {
          if ((location.building != null) && location.building.isNotEmpty) {
            return displayText += (displayText.isNotEmpty ? ", " : "")  + location.building;
          }
        }
        else {
          String displayName = location.getDisplayName();
          if ((displayName != null) && displayName.isNotEmpty) {
            return displayText += (displayText.isNotEmpty ? ", " : "")  + displayName;
          }
        }
        String displayAddress = location.getDisplayAddress();
        if ((displayAddress != null) && displayAddress.isNotEmpty) {
          return displayText += (displayText.isNotEmpty ? ", " : "")  + displayAddress;
        }
      }
    }
    return null;
  }

  static String getExploresListDisplayTitle(List<Explore> exploresList) {
    String exploresType;
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
}