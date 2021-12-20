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

import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/Location.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/Utils.dart';


enum LaundryRoomStatus { online, offline }

class LaundryRoom implements Favorite {
  String? id;
  String? title;
  String? campusName;
  LaundryRoomStatus? status;
  Location? location;

  LaundryRoom({this.id, this.title, this.campusName, this.status, this.location});

  bool operator ==(o) => o is LaundryRoom && o.title == title && o.campusName == campusName && o.id == id;

  int get hashCode => title.hashCode ^ id.hashCode ^ campusName.hashCode;

  static LaundryRoom? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? LaundryRoom(
        id: json['id'],
        title: json['title'],
        campusName: json['campus_name'],
        status: roomStatusFromString(json['status']),
        location: Location.fromJSON(json['location'])
      ) : null;
  }

  toJson() {
    return {
      "id": id,
      "title": title,
      "campus_name": campusName,
      "status": _roomStatusToString(status),
      "location": (location != null ? location!.toJson() : null)
    };
  }

  Map<String, dynamic> get analyticsAttributes {
    return {
      Analytics.LogAttributeLaundryId: id,
      Analytics.LogAttributeLaundryName: title,
    };
  }

  static LaundryRoomStatus? roomStatusFromString(String? roomStatusString) {
    if (AppString.isStringEmpty(roomStatusString)) {
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

  static String? _roomStatusToString(LaundryRoomStatus? roomStatus) {
    if (roomStatus == null) {
      return null;
    }
    switch (roomStatus) {
      case LaundryRoomStatus.online:
        return 'online';
      case LaundryRoomStatus.offline:
        return 'offline';
    }
    return null;
  }

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
