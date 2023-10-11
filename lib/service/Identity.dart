/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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

import 'package:http/http.dart';
import 'package:illinois/model/Identity.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Identity /* with Service */ {
  
  // Singleton Factory
  static final Identity _instance = Identity._internal();
  factory Identity() => _instance;
  Identity._internal();

  // External Authorization Header

  final String _externalAuthorizationHeaderKey = "External-Authorization";
  String? get _externalAuthorizationHeaderValue => Auth2().uiucToken?.accessToken;
  Map<String, String?> get _externalAuthorizationHeader => {_externalAuthorizationHeaderKey: _externalAuthorizationHeaderValue};

  // Mobile Credential

  Future<MobileCredential?> loadMobileCredential() async {
    if (StringUtils.isEmpty(Config().identityUrl)) {
      Log.e('Identity: Failed to load mobile credential - missing identity url.');
      return null;
    }
    Response? response = await Network().get("${Config().identityUrl}/mobilecredential", auth: Auth2(), headers: _externalAuthorizationHeader);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      return MobileCredential.fromJson(JsonUtils.decodeMap(responseString));
    } else {
      Log.e('Identity: Failed to load mobile credential. Reason ($responseCode): $responseString');
      return null;
    }
  }

  Future<bool> deleteMobileCredential() async {
    if (StringUtils.isEmpty(Config().identityUrl)) {
      Log.e('Identity: Failed to delete mobile credential - missing identity url.');
      return false;
    }
    Response? response = await Network().delete("${Config().identityUrl}/mobilecredential", auth: Auth2(), headers: _externalAuthorizationHeader);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Log.i('Identity: Successfully deleted mobile credential.');
      return true;
    } else {
      Log.e('Identity: Failed to delete mobile credential. Reason ($responseCode): $responseString');
      return false;
    }
  }

  // Student id

  Future<StudentId?> loadStudentId() async {
    if (StringUtils.isEmpty(Config().identityUrl)) {
      Log.e('Identity: loadStudentId - missing identity url.');
      return null;
    }
    Response? response = await Network().get("${Config().identityUrl}/studentid", auth: Auth2(), headers: _externalAuthorizationHeader);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      return StudentId.fromJson(JsonUtils.decodeMap(responseString));
    } else {
      Log.e('Identity: Failed to load student id. Reason ($responseCode): $responseString');
      return null;
    }
  }

  Future<StudentId?> renewMobileId() async {
    if (StringUtils.isEmpty(Config().identityUrl)) {
      Log.e('Identity: renewMobileId - missing identity url.');
      return null;
    }
    Response? response = await Network().get("${Config().identityUrl}/renewmobileid", auth: Auth2(), headers: _externalAuthorizationHeader);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      return StudentId.fromJson(JsonUtils.decodeMap(responseString));
    } else {
      Log.e('Identity: Failed to renew mobile id. Reason ($responseCode): $responseString');
      return null;
    }
  }
}
