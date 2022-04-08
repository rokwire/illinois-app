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

import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:xml/xml.dart';


enum LaundryRoomStatus { online, offline }

class LaundryRoom implements Favorite {
  String? id;
  String? title;
  String? campusName;
  LaundryRoomStatus? status;
  ExploreLocation? location;

  LaundryRoom({this.id, this.title, this.campusName, this.status, this.location});

  static LaundryRoom? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? LaundryRoom(
        id: JsonUtils.stringValue(json['id']) ,
        title: JsonUtils.stringValue(json['title']),
        campusName: JsonUtils.stringValue(json['campus_name']),
        status: roomStatusFromString(JsonUtils.stringValue(json['status'])),
        location: ExploreLocation.fromJSON(JsonUtils.mapValue(json['location']))
      ) : null;
  }

  toJson() {
    return {
      "id": id,
      "title": title,
      "campus_name": campusName,
      "status": roomStatusToString(status),
      "location": location?.toJson(),
    };
  }

  static LaundryRoom? fromXml(XmlElement? xml, { Map<String, ExploreLocation>? locations }) {
    if (xml != null) {
      String? roomId = XmlUtils.childText(xml, "location");
      return LaundryRoom(
        id: roomId,
        title: XmlUtils.childText(xml, "laundry_room_name"),
        campusName: XmlUtils.childText(xml, "campus_name"),
        status: roomStatusFromString(XmlUtils.childText(xml, "status")),
        location: (locations != null) ? locations[roomId] : null,
      );
    }
    return null;
  }

  static List<LaundryRoom>? listFromXml(Iterable<XmlElement>? xmlList, { Map<String, ExploreLocation>? locations }) {
    List<LaundryRoom>? resultList;
    if (xmlList != null) {
      resultList = <LaundryRoom>[];
      for (XmlElement xml in xmlList) {
        ListUtils.add(resultList, LaundryRoom.fromXml(xml, locations: locations));
      }
    }
    return resultList;
  }

  @override
  bool operator ==(other) => (other is LaundryRoom) &&
    (other.id == id) &&
    (other.title == title) &&
    (other.campusName == campusName) &&
    (other.status == status) &&
    (other.location == location);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (campusName?.hashCode ?? 0) ^
    (status?.hashCode ?? 0) ^
    (location?.hashCode ?? 0);

  Map<String, dynamic> get analyticsAttributes {
    return {
      Analytics.LogAttributeLaundryId: id,
      Analytics.LogAttributeLaundryName: title,
    };
  }

  // Favorite

  @override
  String? get favoriteId => id;

  @override
  String? get favoriteTitle => title;

  @override
  String get favoriteKey =>  favoriteKeyName;

  static String favoriteKeyName = "laundryPlaceIds";
}

class LaundryRoomAppliance {
  String? applianceDescKey;
  String? lrmStatus;
  String? applianceType;
  String? status;
  String? outOfService;
  String? label;
  String? avgCycleTime;
  String? timeRemaining;

  LaundryRoomAppliance({
    this.applianceDescKey,
    this.lrmStatus,
    this.applianceType,
    this.status,
    this.outOfService,
    this.label,
    this.avgCycleTime,
    this.timeRemaining});

  static LaundryRoomAppliance? fromXml(XmlElement? xml) {
    return (xml != null) ? LaundryRoomAppliance(
      applianceDescKey: XmlUtils.childText(xml, "appliance_desc_key"),
      lrmStatus: XmlUtils.childText(xml, "lrm_status"),
      applianceType: XmlUtils.childText(xml, "appliance_type"),
      status: XmlUtils.childText(xml, "status"),
      outOfService: XmlUtils.childText(xml, "out_of_service"),
      label: XmlUtils.childText(xml, "label"),
      avgCycleTime: XmlUtils.childText(xml, "avg_cycle_time"),
      timeRemaining: XmlUtils.childText(xml, "time_remaining"),
    ) : null;
  }

  static List<LaundryRoomAppliance>? listFromXml(Iterable<XmlElement>? xmlList) {
    List<LaundryRoomAppliance>? resultList;
    if (xmlList != null) {
      resultList = <LaundryRoomAppliance>[];
      for (XmlElement xml in xmlList) {
        ListUtils.add(resultList, LaundryRoomAppliance.fromXml(xml));
      }
    }
    return resultList;
  }
}

class LaundryRoomAvailability {
  String? roomId;
  String? _availableWashers;
  String? _availableDryers;

  static const String _undefined = "undefined";

  LaundryRoomAvailability({this.roomId, String? availableWashers, String? availableDryers}) :
    _availableWashers = availableWashers,
    _availableDryers = availableDryers;

  static LaundryRoomAvailability? fromXml(XmlElement? xml) {
    return (xml != null) ? LaundryRoomAvailability(
      roomId: XmlUtils.childText(xml, "location"),
      availableWashers: XmlUtils.childText(xml, "available_washers"),
      availableDryers: XmlUtils.childText(xml, "available_dryers"),
    ) : null;
  }

  static LaundryRoomAvailability? fromXmlList(Iterable<XmlElement>? xmlList, { String? roomId } ) {
    if (xmlList != null) {
      for (XmlElement xml in xmlList) {
        String? xmlRoomId = XmlUtils.childText(xml, "location");
        if ((xmlRoomId != null) && (xmlRoomId == roomId)) {
          return LaundryRoomAvailability.fromXml(xml);
        }
      }
    }
    return null;
  }

  String? get availableWashers => (_availableWashers != _undefined) ? _availableWashers : null;
  String? get availableDryers => (_availableDryers != _undefined) ? _availableDryers : null;
}

// LaundryRoomStatus

LaundryRoomStatus? roomStatusFromString(String? roomStatusString) {
  if (StringUtils.isEmpty(roomStatusString)) {
    return null;
  }
  switch (roomStatusString) {
    case 'online':
      return LaundryRoomStatus.online;
    case 'offline':
      return LaundryRoomStatus.offline;
    default:
      return null;
  }
}

String? roomStatusToString(LaundryRoomStatus? roomStatus) {
  if (roomStatus != null) {
    switch (roomStatus) {
      case LaundryRoomStatus.online:
        return 'online';
      case LaundryRoomStatus.offline:
        return 'offline';
    }
  }
  return null;
}
