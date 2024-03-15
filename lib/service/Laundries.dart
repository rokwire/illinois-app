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
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Laundries /*with Service*/ {

  // Singletone Factory

  static final Laundries _logic = Laundries._internal();

  factory Laundries() => _logic;

  Laundries._internal();


  // Implementation

  Future<LaundrySchool?> loadSchoolRooms() async {
    String? roomsUrl = (Config().gatewayUrl != null) ? "${Config().gatewayUrl}/laundry/rooms" : null;
    if (StringUtils.isNotEmpty(roomsUrl)) {
      Response? response = await Network().get(roomsUrl, auth: Auth2());
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        Map<String, dynamic>? jsonResponse = JsonUtils.decodeMap(responseString);
        return LaundrySchool.fromJson(jsonResponse);
      } else {
        Log.e('Failed to load school laundry rooms. Response code: $responseCode, Response:\n$responseString');
      }
    } else {
      Log.e('Missing gateway url.');
    }
    return null;
  }

  Future<LaundryRoomDetails?> loadRoomDetails(String? laundryRoomId) async {
    if (StringUtils.isEmpty(laundryRoomId) || StringUtils.isEmpty(Config().gatewayUrl)) {
      Log.e('Missing laundry room id or gateway url.');
      return null;
    }
    String? roomUrl = "${Config().gatewayUrl}/laundry/room?id=$laundryRoomId";
    Response? response = await Network().get(roomUrl, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? jsonResponse = JsonUtils.decodeMap(responseString);
      return LaundryRoomDetails.fromJson(jsonResponse);
    } else {
      Log.e('Failed to load laundry room details with id "$laundryRoomId". Response code: $responseCode, Response:\n$responseString');
      return null;
    }
  }

  Future<LaundryMachineServiceIssues?> loadMachineServiceIssues({required String machineId}) async {
    if (StringUtils.isEmpty(Config().gatewayUrl)) {
      Log.e('Missing gateway url.');
      return null;
    }
    String? requestUrl = "${Config().gatewayUrl}/laundry/initrequest?machineid=$machineId";
    Response? response = await Network().get(requestUrl, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? jsonResponse = JsonUtils.decodeMap(responseString);
      return LaundryMachineServiceIssues.fromJson(jsonResponse);
    } else {
      Log.e('Failed to load machine service issues with "$machineId". Response code: $responseCode, Response:\n$responseString');
      return null;
    }
  }

  Future<LaundryIssueResponse?> submitIssueRequest({required LaundryIssueRequest issueRequest}) async {
    if (StringUtils.isEmpty(Config().gatewayUrl)) {
      Log.e('Missing gateway url.');
      return null;
    }
    String? requestUrl = "${Config().gatewayUrl}/laundry/requestservice";
    String? body = JsonUtils.encode(issueRequest.toJson());
    Response? response = await Network().post(requestUrl, body: body, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      return LaundryIssueResponse.fromJson(JsonUtils.decode(responseString));
    } else {
      Log.e(
          'Failed to submit issue request for machine with id "${issueRequest.machineId}". Response code: $responseCode, Response:\n$responseString');
      return null;
    }
  }
}
