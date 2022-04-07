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
      resultList = [];
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

  LaundryRoomAppliance(
      {this.applianceDescKey,
      this.lrmStatus,
      this.applianceType,
      this.status,
      this.outOfService,
      this.label,
      this.avgCycleTime,
      this.timeRemaining});
}

class LaundryRoomAvailability {
  String? location;
  String? availableWashers;
  String? availableDryers;

  LaundryRoomAvailability({this.location, this.availableWashers, this.availableDryers});
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
