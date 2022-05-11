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

import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class LaundryRoom implements Favorite {
  String? id;
  String? name;
  LaundryRoomStatus? status;
  ExploreLocation? location;

  LaundryRoom({this.id, this.name, this.status, this.location});

  static LaundryRoom? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? LaundryRoom(
            id: JsonUtils.stringValue(json['ID']),
            name: JsonUtils.stringValue(json['Name']),
            status: roomStatusFromString(JsonUtils.stringValue(json['Status'])),
            location: ExploreLocation.fromJSON(JsonUtils.mapValue(json['Location'])))
        : null;
  }

  static List<LaundryRoom>? fromJsonList(List<dynamic>? jsonList) {
    List<LaundryRoom>? items;
    if (jsonList != null) {
      items = <LaundryRoom>[];
      for (dynamic json in jsonList) {
        ListUtils.add(items, LaundryRoom.fromJson(json));
      }
    }
    return items;
  }

  @override
  bool operator ==(other) =>
      (other is LaundryRoom) && (other.id == id) && (other.name == name) && (other.status == status) && (other.location == location);

  @override
  int get hashCode => (id?.hashCode ?? 0) ^ (name?.hashCode ?? 0) ^ (status?.hashCode ?? 0) ^ (location?.hashCode ?? 0);

  Map<String, dynamic> get analyticsAttributes {
    return {
      Analytics.LogAttributeLaundryId: id,
      Analytics.LogAttributeLaundryName: name,
    };
  }

  // Favorite

  @override
  String? get favoriteId => id;

  @override
  String? get favoriteTitle => name;

  @override
  String get favoriteKey => favoriteKeyName;

  static String favoriteKeyName = "laundryPlaceIds";
}

class LaundryRoomAppliance {
  String? id;
  String? label;
  LaundryApplianceStatus? status;
  LaundryApplianceType? type;
  int? avgCycleTimeinMins;
  int? timeRemainingInMins;
  ExploreLocation? location;

  LaundryRoomAppliance({this.id, this.label, this.status, this.type, this.avgCycleTimeinMins, this.timeRemainingInMins, this.location});

  static LaundryRoomAppliance? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? LaundryRoomAppliance(
            id: JsonUtils.stringValue(json['ID']),
            label: JsonUtils.stringValue(json['Label']),
            status: applianceStatusFromString(JsonUtils.stringValue(json['Status'])),
            type: applianceTypeFromString(JsonUtils.stringValue(json['ApplianceType'])),
            avgCycleTimeinMins: JsonUtils.intValue(json['AverageCycleTime']),
            timeRemainingInMins: JsonUtils.intValue(json['TimeRemaining']),
            location: ExploreLocation.fromJSON(JsonUtils.mapValue(json['Location'])))
        : null;
  }

  static List<LaundryRoomAppliance>? listFromJson(List<dynamic>? jsonList) {
    List<LaundryRoomAppliance>? resultList;
    if (jsonList != null) {
      resultList = <LaundryRoomAppliance>[];
      for (dynamic json in jsonList) {
        ListUtils.add(resultList, LaundryRoomAppliance.fromJson(json));
      }
    }
    return resultList;
  }
}

class LaundryRoomDetails {
  String? roomName;
  String? campusName;
  int? availableWashersCount;
  int? availableDryersCount;
  List<LaundryRoomAppliance>? appliances;

  LaundryRoomDetails({this.roomName, this.campusName, this.availableWashersCount, this.availableDryersCount, this.appliances});

  static LaundryRoomDetails? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? LaundryRoomDetails(
            roomName: JsonUtils.stringValue(json['RoomName']),
            campusName: JsonUtils.stringValue(json['CampusName']),
            availableWashersCount: JsonUtils.intValue(json['NumWashers']),
            availableDryersCount: JsonUtils.intValue(json['NumDryers']),
            appliances: LaundryRoomAppliance.listFromJson(JsonUtils.listValue(json['Appliances'])))
        : null;
  }
}

class LaundryMachineServiceIssues {
  final String? machineId;
  final String? message;
  final bool? hasOpenIssue;
  final String? typeString;
  final List<String>? problemCodes;

  LaundryMachineServiceIssues({this.machineId, this.message, this.hasOpenIssue, this.typeString, this.problemCodes});

  static LaundryMachineServiceIssues? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? LaundryMachineServiceIssues(
            machineId: JsonUtils.stringValue(json['MachineID']),
            message: JsonUtils.stringValue(json['Message']),
            hasOpenIssue: JsonUtils.boolValue(json['OpenIssue']),
            typeString: JsonUtils.stringValue(json['MachineType']),
            problemCodes: JsonUtils.listStringsValue(json['ProblemCodes']))
        : null;
  }

  LaundryApplianceType? get type {
    return applianceTypeFromString(this.typeString);
  }
}

// LaundryRoomStatus

enum LaundryRoomStatus { online, offline }

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

// LaundryApplianceStatus

enum LaundryApplianceStatus { available, in_use, out_of_service }

LaundryApplianceStatus? applianceStatusFromString(String? applianceStatusString) {
  if (StringUtils.isEmpty(applianceStatusString)) {
    return null;
  }
  switch (applianceStatusString) {
    case 'available':
      return LaundryApplianceStatus.available;
    case 'in_use':
      return LaundryApplianceStatus.in_use;
    case 'out_of_service':
      return LaundryApplianceStatus.out_of_service;
    default:
      return null;
  }
}

// LaundryApplianceType

enum LaundryApplianceType { washer, dryer, air_machine }

LaundryApplianceType? applianceTypeFromString(String? applianceTypeString) {
  if (StringUtils.isEmpty(applianceTypeString)) {
    return null;
  }
  switch (applianceTypeString!.toUpperCase()) { // Explicitly compare with uppercase because not all items come with upper case from Gateway BB
    case 'WASHER':
      return LaundryApplianceType.washer;
    case 'DRYER':
      return LaundryApplianceType.dryer;
    case 'AIR MACHINE':
      return LaundryApplianceType.air_machine;
    default:
      return null;
  }
}
