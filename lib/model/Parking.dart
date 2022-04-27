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

import 'dart:math';

import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ParkingEvent {
  final String? id;
  final String? name;
  final String? fromDateString;
  final String? toDateString;
  final String? parkingFromDateString;
  final String? parkingToDateString;
  final DateTime? fromDateUtc;
  final DateTime? toDateUtc;
  final DateTime? parkingFromDateUtc;
  final DateTime? parkingToDateUtc;
  final String? landMarkId;
  final String? slug;
  final bool? live;

  List<ParkingLot>? lots;

  static final String dateTimeFormat = "yyyy-MM-ddTHH:mm:ssZ";


  ParkingEvent({this.id, this.name,
    this.fromDateString, this.toDateString, this.parkingFromDateString, this.parkingToDateString,
    this.fromDateUtc, this.toDateUtc, this.parkingFromDateUtc, this.parkingToDateUtc,
    this.landMarkId, this.slug, this.live, this.lots});

  static ParkingEvent? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    List<dynamic>? lotsJson = json.containsKey('lots') ? json['lots'] : null;
    List<ParkingLot>? lots;
    if (CollectionUtils.isNotEmpty(lotsJson)) {
      lots = <ParkingLot>[];
      for (dynamic lotEntry in lotsJson!) {
        ListUtils.add(lots, ParkingLot.fromJson(JsonUtils.mapValue(lotEntry)));
      }
    }

    return ParkingEvent(
      id: json['id'],
      name: json['name'],
      fromDateString: json['from'],
      toDateString: json['to'],
      parkingFromDateString: json['parking_from'],
      parkingToDateString: json['parking_to'],
      fromDateUtc: DateTimeUtils.dateTimeFromString(json['from'], format: dateTimeFormat, isUtc: true),
      toDateUtc: DateTimeUtils.dateTimeFromString(json['to'], format: dateTimeFormat, isUtc: true),
      parkingFromDateUtc: DateTimeUtils.dateTimeFromString(json['parking_from'], format: dateTimeFormat, isUtc: true),
      parkingToDateUtc: DateTimeUtils.dateTimeFromString(json['parking_to'], format: dateTimeFormat, isUtc: true),
      landMarkId: json['landmark_id'],
      slug: json['slug'],
      live: json['live'],
      lots: lots,
    );
  }

  Map<String, dynamic> toJson() {
    List<dynamic>? lotsJsonList;
    if (CollectionUtils.isNotEmpty(lots)) {
      lotsJsonList = [];
      for (ParkingLot lot in lots!) {
        lotsJsonList.add(lot.toJson());
      }
    }

    return {
      "id": id,
      "name": name,
      'from': fromDateString,
      'to': toDateString,
      'parking_from': parkingFromDateString,
      'parking_to': parkingToDateString,
      'landmark_id': landMarkId,
      'slug': slug,
      'live': live,
      'lots': lotsJsonList,
    };
  }

  static List<ParkingEvent>? listFromJson(List<dynamic>? jsonList) {
    List<ParkingEvent>? result;
    if (jsonList != null) {
      result = <ParkingEvent>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, ParkingEvent.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<ParkingEvent>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  String get displayFromDate {
    return AppDateTimeUtils.getDisplayDateTime(fromDateUtc);
  }

  String get displayToDate {
    return AppDateTimeUtils.getDisplayDateTime(toDateUtc);
  }

  String get displayParkingFromDate {
    return AppDateTimeUtils.getDisplayDateTime(parkingFromDateUtc);
  }

  String get displayParkingToDate {
    return AppDateTimeUtils.getDisplayDateTime(parkingToDateUtc);
  }
}

class ParkingLot {
  final String? lotId;
  final String? lotName;
  final String? lotAddress;
  final int? totalSpots;
  final LatLng? entrance;
  final List<LatLng>? polygon;
  final int? spotsSold;
  final int? spotsPreSold;

  ParkingLot({this.lotId, this.lotName, this.lotAddress, this.entrance, this.polygon, this.spotsSold, this.spotsPreSold, this.totalSpots});

  static ParkingLot? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    Map<String, dynamic>? lotJson = JsonUtils.mapValue(json['lot']);
    if (lotJson == null) {
      // For Parking events
      // Example: {"id": "c9c6842c-9cb6-4c10-89c5-aec9ba4e430b", "name": "Lot Illinois"}
      return ParkingLot(lotId:
        JsonUtils.stringValue(json['id']),
        lotName: JsonUtils.stringValue(json['name']));
    }
    else {
      // For Inventory
      // Example: {"lot": {"id": "12e8g939-b210-4019-de3b-19a00a31f58f", "name": "Lot - Illinois", "address1": "1800 S. First Street, Champaign, IL 61820", "total_spots": "483", "entrance": {"latitude": 40.094582, "longitude": -88.236374}, "polygon": [{"latitude": 40.094513, "longitude": -88.238494}, {"latitude": 40.095654, "longitude": -88.238505}, {"latitude": 40.095434, "longitude": -88.236751}, {"latitude": 40.09525, "longitude": -88.23655}, {"latitude": 40.246545, "longitude": -88.234361}]}, "spots_sold": 0, "spots_pre_sold": 0}

      return ParkingLot(
        lotId: JsonUtils.stringValue(lotJson['id']),
        lotName: JsonUtils.stringValue(lotJson['name']),
        lotAddress: JsonUtils.stringValue(lotJson['address1']),
        totalSpots: int.tryParse(JsonUtils.stringValue(lotJson['total_spots']) ?? '') ?? 0,
        entrance: LatLng.fromJson(JsonUtils.mapValue(lotJson['entrance'])),
        polygon: LatLng.listFromJson(JsonUtils.listValue(lotJson['polygon'])),
        spotsSold: json['spots_sold'],
        spotsPreSold: json['spots_pre_sold'],
      );
    }
  }

  int get availableSpots {
    return max((totalSpots! - (spotsSold! + spotsPreSold!)), 0);
  }

  bool get isAvailable {
    return availableSpots > 0;
  }

  Map<String, dynamic> toJson() {
    return {
      "lot_id": lotId,
      "lot_name": lotName,
      "lot_address1": lotAddress,
      "total_spots": totalSpots,
      "entrance": entrance?.toJson(),
      "polygon": LatLng.listToJson(polygon),
      "spots_sold": spotsSold,
      "spots_pre_sold": spotsPreSold,
    };
  }

  static List<ParkingLot>? listFromJson(List<dynamic>? jsonList) {
    List<ParkingLot>? result;
    if (jsonList != null) {
      result = <ParkingLot>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, ParkingLot.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<ParkingLot>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
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
      values = <LatLng>[];
      for (dynamic entry in json) {
        ListUtils.add(values, LatLng.fromJson(JsonUtils.mapValue(entry)));
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