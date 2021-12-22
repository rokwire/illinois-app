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

import 'dart:async';
import 'package:illinois/service/Assets.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/model/Location.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:xml/xml.dart' as xml;

// LaundryService does rely on Service initialization API so it does not override service interfaces and is not registered in Services..
class LaundryService /* with Service */ {
  static final LaundryService _logic = LaundryService._internal();

  factory LaundryService() {
    return _logic;
  }

  LaundryService._internal();

  Future<List<LaundryRoom>?> getRoomData() async {
    Map<String?, Location?>? locationMapping = _loadLaundryLocationMapping();
    bool mappingExists =
        ((locationMapping != null) && locationMapping.isNotEmpty);
    List<LaundryRoom>? rooms;
    final roomDataUrl = (Config().laundryHostUrl != null) ? "${Config().laundryHostUrl}school?api_key=${Config().laundryApiKey}&method=getRoomData" : null;
    final response = await Network().get(roomDataUrl);
    String? responseBody = response?.body;
    if (response?.statusCode == 200) {
      xml.XmlDocument roomsXmlResponse = xml.XmlDocument.parse(responseBody!);
      var laundryRoomsXml = roomsXmlResponse.findAllElements('laundryroom');
      rooms = [];
      laundryRoomsXml.map((xml.XmlElement item) {
        String? location = _getValueFromXmlItem(item.findElements("location"));
        String? campusName =
            _getValueFromXmlItem(item.findElements("campus_name"));
        String? name =
            _getValueFromXmlItem(item.findElements("laundry_room_name"));
        String? statusValue = _getValueFromXmlItem(item.findElements("status"));
        Location? roomLocationDetails;
        if (mappingExists) {
          roomLocationDetails = locationMapping[location];
        }
        LaundryRoomStatus? roomStatus =
            LaundryRoom.roomStatusFromString(statusValue);
        rooms!.add(LaundryRoom(
            id: location,
            campusName: campusName,
            title: name,
            status: roomStatus,
            location: roomLocationDetails));
      }).toList();
    } else {
      Log.e('Failed to load laundry rooms:');
      Log.e(responseBody);
    }
    return rooms;
  }

  Future<LaundryRoomAvailability?> getNumAvailable(String? laundryLocation) async {
    if (AppString.isStringEmpty(laundryLocation)) {
      return null;
    }
    final availabilityUrl = (Config().laundryHostUrl != null) ? "${Config().laundryHostUrl}school?api_key=${Config().laundryApiKey}&method=getNumAvailable" : null;
    final response = await Network().get(availabilityUrl);
    String? responseBody = response?.body;
    if (response?.statusCode == 200) {
      final String undefinedValue = 'undefined';
      final String zeroValue = '0';
      xml.XmlDocument roomsXmlResponse = xml.XmlDocument.parse(responseBody!);
      var laundryRoomsXml = roomsXmlResponse.findAllElements('laundryroom');
      for (xml.XmlElement item in laundryRoomsXml) {
        String? location = _getValueFromXmlItem(item.findElements("location"));
        if (laundryLocation == location) {
          String? availableWashers = _getValueFromXmlItem(item.findElements("available_washers"));
          String? availableDryers = _getValueFromXmlItem(item.findElements("available_dryers"));
          if (undefinedValue == availableWashers) {
            availableWashers = zeroValue;
          }
          if (undefinedValue == availableDryers) {
            availableDryers = zeroValue;
          }
          return LaundryRoomAvailability(location: location, availableWashers: availableWashers, availableDryers: availableDryers);
        } else {
          continue;
        }
      }
    } else {
      Log.e('Failed to load laundry room data:');
      Log.e(responseBody);
    }
    return null;
  }

  Future<List<LaundryRoomAppliance>?> getAppliances(
      String? laundryRoomLocation) async {
    if (AppString.isStringEmpty(laundryRoomLocation)) {
      return null;
    }
    List<LaundryRoomAppliance>? laundryRoomAppliances;
    final appliancesUrl = (Config().laundryHostUrl != null) ?  "${Config().laundryHostUrl}room?api_key=${Config().laundryApiKey}&method=getAppliances&location=$laundryRoomLocation" : null;
    final response = await Network().get(appliancesUrl);
    String? responseBody = response?.body;
    if (response?.statusCode == 200) {
      xml.XmlDocument roomsXmlResponse = xml.XmlDocument.parse(responseBody!);
      var appliancesXml = roomsXmlResponse.findAllElements('appliance');
      laundryRoomAppliances = [];
      appliancesXml.map((xml.XmlElement item) {
        String? applianceDescKey =
            _getValueFromXmlItem(item.findElements("appliance_desc_key"));
        String? lrmStatus = _getValueFromXmlItem(item.findElements("lrm_status"));
        String? applianceType =
            _getValueFromXmlItem(item.findElements("appliance_type"));
        String? status = _getValueFromXmlItem(item.findElements("status"));
        String? outOfService =
            _getValueFromXmlItem(item.findElements("out_of_service"));
        String? label = _getValueFromXmlItem(item.findElements("label"));
        String? avgCycleTime =
            _getValueFromXmlItem(item.findElements("avg_cycle_time"));
        String? timeRemaining =
            _getValueFromXmlItem(item.findElements("time_remaining"));
        laundryRoomAppliances!.add(LaundryRoomAppliance(
            applianceDescKey: applianceDescKey,
            lrmStatus: lrmStatus,
            applianceType: applianceType,
            status: status,
            outOfService: outOfService,
            label: label,
            avgCycleTime: avgCycleTime,
            timeRemaining: timeRemaining));
      }).toList();
    } else {
      Log.e('Failed to load laundry room appliances:');
      Log.e(responseBody);
    }
    return laundryRoomAppliances;
  }

  Map<String?, Location?>? _loadLaundryLocationMapping() {
    List<dynamic>? jsonData = Assets()['laundry.locations'];
    if (AppCollection.isCollectionEmpty(jsonData)) {
      return null;
    }
    Map<String, Location> locationMapping = Map();
    for (dynamic jsonEntry in jsonData!) {
      String? locationIdentifier = jsonEntry['laundry_location'];
      Location? locationDetails =
          Location.fromJSON(jsonEntry['location_details']);
      if ((locationIdentifier != null) && (locationDetails != null)) {
        locationMapping.putIfAbsent(locationIdentifier, () => locationDetails);
      }
    }
    return locationMapping;
  }

  String? _getValueFromXmlItem(Iterable<xml.XmlElement> items) {
    if (AppCollection.isCollectionEmpty(items)) {
      return null;
    }
    var textValue;
    items.map((xml.XmlElement node) {
      textValue = node.text;
    }).toList();
    return textValue;
  }
}
