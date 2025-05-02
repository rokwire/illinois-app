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

import 'dart:core';
import 'package:http/http.dart' as http;
import 'package:illinois/service/Config.dart';
import 'package:illinois/model/Rewards.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/ext/network.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:http/http.dart' as http;

import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Rewards with Service {
  
  // Singleton Factory

  Rewards._internal();
  static final Rewards _instance = Rewards._internal();

  factory Rewards() {
    return _instance;
  }

  Rewards get instance {
    return _instance;
  }

  // Service

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config()]);
  }

  // APIs

  Future<http.Response?> _loadBalanceResponse() async => StringUtils.isNotEmpty(Config().rewardsUrl) ?
    Network().get('${Config().rewardsUrl}/user/balance', auth: Auth2()) : null;

  Future<int?> loadBalance() async {
    if (StringUtils.isEmpty(Config().rewardsUrl)) {
      Log.w('Rewards ballance failed to load. Missing rewards url.');
      return null;
    }
    http.Response? response = await _loadBalanceResponse();
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? json = JsonUtils.decodeMap(responseString);
      return (json != null) ? JsonUtils.intValue(json['amount']) : null;
    } else {
      Log.w('Failed to load user rewards balance. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<http.Response?> _loadHistoryResponse() async => StringUtils.isNotEmpty(Config().rewardsUrl) ?
    Network().get('${Config().rewardsUrl}/user/history', auth: Auth2()) : null;

  Future<List<RewardHistoryEntry>?> loadHistory() async {
    if (StringUtils.isEmpty(Config().rewardsUrl)) {
      Log.w('Rewards history failed to load. Missing rewards url.');
      return null;
    }
    http.Response? response = await _loadHistoryResponse();
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<RewardHistoryEntry>? entries = RewardHistoryEntry.listFromJson(JsonUtils.decodeList(responseString));
      return entries;
    } else {
      Log.w('Failed to load user rewards history. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // User Data

  Future<Map<String, dynamic>?> loadUserDataJson() async {
    List<http.Response?> responses = await Future.wait<http.Response?>(<Future<http.Response?>>[
      _loadBalanceResponse(),
      _loadHistoryResponse(),
    ]);

    return {
      'balance': _responseUserData(ListUtils.entry<http.Response?>(responses, 0)),
      'history': _responseUserData(ListUtils.entry<http.Response?>(responses, 1), decoder: JsonUtils.decodeList),
    };
  }

  dynamic _responseUserData(http.Response? response, { Function(String?) decoder = JsonUtils.decodeMap }) =>
    (response?.succeeded == true) ? decoder(response?.body) : "${response?.statusCode} ${response?.body}";
}