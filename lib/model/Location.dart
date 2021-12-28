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

import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/Utils.dart';

//////////////////////////////
/// Location

class Location {
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

  Location(
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

  static Location? fromJSON(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return Location(
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

    if ((name != null) && (0 < name!.length)) {
      if (0 < displayText.length) {
        displayText += ", ";
      }
      displayText += name!;
    }

    if ((building != null) && (0 < building!.length)) {
      if (0 < displayText.length) {
        displayText += ", ";
      }
      displayText += building!;
    }

    return displayText;
  }

  String getDisplayAddress() {
    String displayText = "";

    if ((address != null) && (0 < address!.length)) {
      if (0 < displayText.length) {
        displayText += ", ";
      }
      displayText += address!;
    }

    if ((city != null) && (0 < city!.length)) {
      if (0 < displayText.length) {
        displayText += ", ";
      }
      displayText += city!;
    }

    String delimiter = ", ";

    if ((state != null) && (0 < state!.length)) {
      if (0 < displayText.length) {
        displayText += ", ";
      }
      displayText += state!;
      delimiter = " ";
    }

    if ((zip != null) && (0 < zip!.length)) {
      if (0 < displayText.length) {
        displayText += delimiter;
      }
      displayText += zip!;
    }

    return displayText;
  }

  Map<String, dynamic> get analyticsAttributes {
    String? value;
    if ((name != null) && name!.isNotEmpty) {
      value = name;
    }
    else if ((description != null) && description!.isNotEmpty) {
      value = description;
    }

    return { Analytics.LogAttributeLocation : value };
  }
}

//////////////////////////////
/// LatLng

class LatLng {
  num? latitude;
  num? longitude;

  LatLng({this.latitude, this.longitude});

  static LatLng? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return LatLng(
        latitude: json['latitude'],
        longitude: json['longitude']);
  }

  Map<String, dynamic> toJson() {
    return {
      "latitude": latitude,
      "longitude": longitude
    };
  }

  static List<LatLng>? listFromJson(List<dynamic>? json) {
    List<LatLng>? values;
    if (json != null) {
      values = [];
      for (dynamic entry in json) {
        AppList.add(values, LatLng.fromJson(AppJson.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<LatLng>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = [];
      for (LatLng value in values) {
        json.add(value.toJson());
      }
    }
    return json;
  }
}