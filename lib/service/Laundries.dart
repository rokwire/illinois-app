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
import 'package:http/http.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:xml/xml.dart';

// Laundries does rely on Service initialization API so it does not override service interfaces and is not registered in Services..
class Laundries /* with Service */ {
  static final Laundries _logic = Laundries._internal();

  factory Laundries() {
    return _logic;
  }

  Laundries._internal();

  Future<List<LaundryRoom>?> getRoomData() async {
    String? roomDataUrl = (Config().laundryHostUrl != null) ? "${Config().laundryHostUrl}school?api_key=${Config().laundryApiKey}&method=getRoomData" : null;
    if (roomDataUrl != null) {
      Response? response = await Network().get(roomDataUrl);
      if (response?.statusCode == 200) {
        XmlDocument? responseXml = XmlUtils.parse(response?.body);
        Iterable<XmlElement>? xmlList = XmlUtils.children(XmlUtils.child(XmlUtils.child(responseXml, "school"), "laundry_rooms"), "laundryroom");
        return LaundryRoom.listFromXml(xmlList, locations: _laundryLocationMapping);
      }
      else {
        Log.e('Failed to load laundry rooms:\n${response?.body}');
      }
    }
    return null;
  }

  Future<LaundryRoomAvailability?> getNumAvailable(String? laundryLocation) async {
    if (StringUtils.isEmpty(laundryLocation)) {
      return null;
    }
    final availabilityUrl = (Config().laundryHostUrl != null) ? "${Config().laundryHostUrl}school?api_key=${Config().laundryApiKey}&method=getNumAvailable" : null;
    final response = await Network().get(availabilityUrl);
    String? responseBody = response?.body;
    if (response?.statusCode == 200) {
      final String undefinedValue = 'undefined';
      final String zeroValue = '0';
      XmlDocument roomsXmlResponse = XmlDocument.parse(responseBody!);
      var laundryRoomsXml = roomsXmlResponse.findAllElements('laundryroom');
      for (XmlElement item in laundryRoomsXml) {
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
    if (StringUtils.isEmpty(laundryRoomLocation)) {
      return null;
    }
    List<LaundryRoomAppliance>? laundryRoomAppliances;
    final appliancesUrl = (Config().laundryHostUrl != null) ?  "${Config().laundryHostUrl}room?api_key=${Config().laundryApiKey}&method=getAppliances&location=$laundryRoomLocation" : null;
    final response = await Network().get(appliancesUrl);
    String? responseBody = response?.body;
    if (response?.statusCode == 200) {
      XmlDocument roomsXmlResponse = XmlDocument.parse(responseBody!);
      var appliancesXml = roomsXmlResponse.findAllElements('appliance');
      laundryRoomAppliances = [];
      appliancesXml.map((XmlElement item) {
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

  Map<String, ExploreLocation>? get _laundryLocationMapping {
    Map<String, ExploreLocation>? locationMapping;
    List<dynamic>? jsonList = JsonUtils.listValue(Assets()['laundry.locations']);
    if (jsonList != null) {
      locationMapping = {};
      for (dynamic jsonEntry in jsonList) {
        if (jsonEntry is Map) {
          String? locationIdentifier = JsonUtils.stringValue(jsonEntry['laundry_location']);
          if ((locationIdentifier != null) && (locationMapping[locationIdentifier] == null)) {
            ExploreLocation? locationDetails = ExploreLocation.fromJSON(JsonUtils.mapValue(jsonEntry['location_details']));
            if (locationDetails != null) {
              locationMapping[locationIdentifier] = locationDetails;
            }
          }
        }
      }
    }
    return locationMapping;
  }

  String? _getValueFromXmlItem(Iterable<XmlElement> items) {
    if (CollectionUtils.isEmpty(items)) {
      return null;
    }
    var textValue;
    items.map((XmlElement node) {
      textValue = node.text;
    }).toList();
    return textValue;
  }
}
