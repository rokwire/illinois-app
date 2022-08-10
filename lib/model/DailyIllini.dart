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

import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:xml/xml.dart';

class DailyIlliniItem {
  final String? title;
  final String? link;
  final String? description;
  final DateTime? pubDateTimeUtc;

  DailyIlliniItem({this.title, this.link, this.description, this.pubDateTimeUtc});

  String? get displayPubDate {
    DateTime? localDateTime = AppDateTime().getDeviceTimeFromUtcTime(pubDateTimeUtc);
    return AppDateTime().formatDateTime(localDateTime, format: 'LLLL, d yyyy', ignoreTimeZone: true);
  }

  static DailyIlliniItem? fromXml(XmlElement? xml) {
    if (xml == null) {
      return null;
    }
    String? pubDateString = XmlUtils.childText(xml, 'pubDate');
    return DailyIlliniItem(
      title: XmlUtils.childText(xml, 'title'),
      link: XmlUtils.childText(xml, 'link'),
      description: XmlUtils.childCdata(xml, 'description'),
      // DateTime format:
      // Tue, 09 Aug 2022 12:00:17 +0000
      pubDateTimeUtc: DateTimeUtils.dateTimeFromString(pubDateString, format: "E, dd LLL yyyy hh:mm:ss Z", isUtc: true),
    );
  }

  static List<DailyIlliniItem>? listFromXml(Iterable<XmlElement>? xmlList) {
    List<DailyIlliniItem>? resultList;
    if (xmlList != null) {
      resultList = <DailyIlliniItem>[];
      for (XmlElement xml in xmlList) {
        ListUtils.add(resultList, DailyIlliniItem.fromXml(xml));
      }
    }
    return resultList;
  }
}
