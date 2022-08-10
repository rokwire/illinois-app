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

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/model/DailyIllini.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:xml/xml.dart';

class DailyIllini  /* with Service */ {

  // Singletone instance

  static final DailyIllini _service = DailyIllini._internal();
  DailyIllini._internal();

  factory DailyIllini() {
    return _service;
  }

  // Service

  Future<List<DailyIlliniItem>?> loadFeed() async {
    if (StringUtils.isEmpty(Config().dailyIlliniFeedUrl)) {
      debugPrint('Failed to load Daily Illini feed - missing url.');
      return null;
    }
    String url = Config().dailyIlliniFeedUrl!;
    Response? response = await Network().get(url);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      XmlDocument? feedXml = await XmlUtils.parseAsync(responseString);
      XmlElement? rssXml = XmlUtils.child(feedXml, 'rss');
      XmlElement? channelXml = XmlUtils.child(rssXml, 'channel');
      Iterable<XmlElement>? itemsXmlList = XmlUtils.children(channelXml, 'item');
      return DailyIlliniItem.listFromXml(itemsXmlList);
    } else {
      debugPrint('Failed to load Daily Illini feed. Response: $responseCode $responseString');
    }
    return null;
  }
}