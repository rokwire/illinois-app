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

  Future<List<LaundryRoom>?> loadRooms() async {
    String? roomDataUrl = (Config().laundryHostUrl != null) ? "${Config().laundryHostUrl}/school?api_key=${Config().laundryApiKey}&method=getRoomData" : null;
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

  Future<LaundryRoomAvailability?> loadRoomAvailability(String? laundryRoomId) async {
    String? availabilityUrl = (Config().laundryHostUrl != null) ?  "${Config().laundryHostUrl}/school?api_key=${Config().laundryApiKey}&method=getNumAvailable" : null;
    if (availabilityUrl != null) {
      Response? response = await Network().get(availabilityUrl);
      if (response?.statusCode == 200) {
        XmlDocument? responseXml = XmlUtils.parse(response?.body);
        Iterable<XmlElement>? xmlList = XmlUtils.children(XmlUtils.child(responseXml, "laundry_rooms"), "laundryroom");
        return ((xmlList != null) && xmlList.isNotEmpty) ? LaundryRoomAvailability.fromXmlList(xmlList, roomId: laundryRoomId) : null;
      }
      else {
        Log.e('Failed to load laundry room data:\n${response?.body}');
      }
    }
    return null;
  }

  Future<List<LaundryRoomAppliance>?> loadRoomAppliances(String? laundryRoomId) async {
    String? appliancesUrl = ((Config().laundryHostUrl != null) && (laundryRoomId != null)) ? "${Config().laundryHostUrl}/room?api_key=${Config().laundryApiKey}&location=$laundryRoomId&method=getAppliances" : null;
    if (appliancesUrl != null) {
      Response? response = await Network().get(appliancesUrl);
      if (response?.statusCode == 200) {
        XmlDocument? responseXml = XmlUtils.parse(response?.body);
        Iterable<XmlElement>? xmlList = XmlUtils.children(XmlUtils.child(XmlUtils.child(responseXml, "laundry_room"), "appliances"), "appliance");
        return LaundryRoomAppliance.listFromXml(xmlList);
      }
      else {
        Log.e('Failed to load laundry room appliances:\n${response?.body}');
      }
    }
    return null;
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
}
