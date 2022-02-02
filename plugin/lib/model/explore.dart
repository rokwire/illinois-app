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

import 'package:rokwire_plugin/utils/utils.dart';

//////////////////////////////
/// Explore

abstract class Explore implements Comparable<Explore> {

  String?   get exploreId;
  String?   get exploreTitle;
  String?   get exploreSubTitle;
  String?   get exploreShortDescription;
  String?   get exploreLongDescription;
  DateTime? get exploreStartDateUtc;
  String?   get exploreImageURL;
  String?   get explorePlaceId;
  ExploreLocation? get exploreLocation;
  Map<String, dynamic> toJson();

  @override
  int compareTo(Explore other) => SortUtils.compare(exploreStartDateUtc, other.exploreStartDateUtc);

  // ExploreJsonHandler
  static final Set<ExploreJsonHandler> _jsonHandlers = {};
  static void addJsonHandler(ExploreJsonHandler handler) => _jsonHandlers.add(handler);
  static void removeJsonHandler(ExploreJsonHandler handler) => _jsonHandlers.remove(handler);

  static ExploreJsonHandler? _getJsonHandler(Map<String, dynamic>? json) {
    if (json != null) {
      for (ExploreJsonHandler handler in _jsonHandlers) {
        if (handler.exploreCanJson(json)) {
          return handler;
        }
      }
    }
    return null;
  }

  static Explore? fromJson(Map<String, dynamic>? json) => _getJsonHandler(json)?.exploreFromJson(json);

  // List
  
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
/// ExploreJsonHandler

abstract class ExploreJsonHandler {
  bool exploreCanJson(Map<String, dynamic>? json) => false;
  Explore? exploreFromJson(Map<String, dynamic>? json) => null;
}

//////////////////////////////
/// ExploreLocation

class ExploreLocation {
  String? locationId;
  String? name;
  String? building;
  String? address;
  String? city;
  String? state;
  String? zip;
  num? latitude;
  num? longitude;
  int? floor;
  String? description;

  ExploreLocation(
      {this.locationId,
      this.name,
      this.building,
      this.address,
      this.city,
      this.state,
      this.zip,
      this.latitude,
      this.longitude,
      this.floor,
      this.description});

  toJson() {
    return {
      "locationId": locationId,
      "name": name,
      "building": building,
      "address": address,
      "city": city,
      "state": state,
      "zip": zip,
      "latitude": latitude,
      "longitude": longitude,
      "floor": floor,
      "description": description
    };
  }

  static ExploreLocation? fromJSON(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return ExploreLocation(
        locationId: json['locationId'],
        name: json['name'],
        building: json['building'],
        address: json['address'],
        city: json['city'],
        state: json['state'],
        zip: json['zip'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        floor: json['floor'],
        description: json['description']);
  }

  String getDisplayName() {
    String displayText = "";

    if ((name != null) && name!.isNotEmpty) {
      if (displayText.isNotEmpty) {
        displayText += ", ";
      }
      displayText += name!;
    }

    if ((building != null) && building!.isNotEmpty) {
      if (displayText.isNotEmpty) {
        displayText += ", ";
      }
      displayText += building!;
    }

    return displayText;
  }

  String getDisplayAddress() {
    String displayText = "";

    if ((address != null) && address!.isNotEmpty) {
      if (displayText.isNotEmpty) {
        displayText += ", ";
      }
      displayText += address!;
    }

    if ((city != null) && city!.isNotEmpty) {
      if (displayText.isNotEmpty) {
        displayText += ", ";
      }
      displayText += city!;
    }

    String delimiter = ", ";

    if ((state != null) && state!.isNotEmpty) {
      if (displayText.isNotEmpty) {
        displayText += ", ";
      }
      displayText += state!;
      delimiter = " ";
    }

    if ((zip != null) && zip!.isNotEmpty) {
      if (displayText.isNotEmpty) {
        displayText += delimiter;
      }
      displayText += zip!;
    }

    return displayText;
  }

  String? get analyticsValue {
    if ((name != null) && name!.isNotEmpty) {
      return name;
    }
    else if ((description != null) && description!.isNotEmpty) {
      return description;
    }
    else {
      return null;
    }
  }
}

