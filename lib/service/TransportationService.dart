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

import 'dart:convert';
import 'dart:ui';

import 'package:illinois/model/Parking.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/service/Styles.dart';

class TransportationService /* with Service */ {

  static final TransportationService _logic = TransportationService._internal();

  factory TransportationService() {
    return _logic;
  }

  TransportationService._internal();

  Future<List<ParkingEvent>?> loadParkingEvents() async {
    final url = (Config().transportationUrl != null) ? "${Config().transportationUrl}/parking/events" : null;
    final response = await Network().get(url, auth: Auth2NetworkAuth());
    return (response?.statusCode == 200) ? ParkingEvent.listFromJson(JsonUtils.decodeList(response?.body)) : null;
  }

  Future<List<ParkingLot>?> loadParkingEventInventory(String? eventId) async {
    if (StringUtils.isNotEmpty(eventId)) {
      final url = (Config().transportationUrl != null) ? "${Config().transportationUrl}/parking/v2/inventory?event-id=$eventId" : null;
      final response = await Network().get(url, auth: Auth2NetworkAuth());
      return (response?.statusCode == 200) ? ParkingLot.listFromJson(JsonUtils.decodeList(response?.body)) : null;
    }
    return null;
  }

  Future<Color?> loadBusColor({String? userId, String? deviceId}) async {
    String? transportationUrl =Config().transportationUrl;
    String url = "$transportationUrl/bus/color";
    Map<String, dynamic> data = {
      'user_id': userId,
      'device_id': deviceId,
    };

    try {
      String body = json.encode(data);
      final response = await Network().get(url, auth: Auth2NetworkAuth(), body:body);

      if ((response != null) && (response.statusCode == 200)) {
        Map<String, dynamic>? jsonData = JsonUtils.decodeMap(response.body);
        String? colorHex = (jsonData != null) ? jsonData["color"] : null;
        return StringUtils.isNotEmpty(colorHex) ? UiColors.fromHex(colorHex) : null;
      } else {
        Log.e('Failed to load bus color');
        Log.e(response?.body);
      }
    } catch(e){}
    return null;
  }

  Future<dynamic> loadBusPass({String? userId, String? deviceId, Map<String, dynamic>? iBeaconData}) async {
    try {
      String url = "${Config().transportationUrl}/bus/pass";
      Map<String, dynamic> data = {
        'user_id': userId,
        'device_id': deviceId,
        'ibeacon_data': iBeaconData,
      };
      String body = json.encode(data);
      final response = await Network().get(url, auth: Auth2NetworkAuth(), body:body);
      if (response != null) {
        if (response.statusCode == 200) {
          String responseBody = response.body;
          return JsonUtils.decode(responseBody);
        } else {
          return response.statusCode;
        }
      }
    }
    catch(e) {
      Log.e(e.toString());
    }
    return null;
  }
}