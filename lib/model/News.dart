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
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/Utils.dart';

import 'UserData.dart';

class News implements Favorite {
  final String id;
  final String title;
  final String link;
  final String category;
  final String description;
  final String fullText;
  final String fullTextRaw;
  final String imageUrl;
  final DateTime pubDateUtc;

  final Map<String, dynamic> json;

  News({this.id, this.title, this.link, this.category, this.description, this.fullText, this.fullTextRaw, this.imageUrl, this.pubDateUtc, this.json});

  factory News.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return null;
    }
    return News(
        id: json['id'],
        title: json['title'],
        link: json['link'],
        category: json["category"],
        description: json['description'],
        fullText: json['fulltext'],
        fullTextRaw: json['fulltext_raw'],
        imageUrl: json['image_url'],
        pubDateUtc: AppDateTime().dateTimeFromString(json['pub_date_utc'], format: AppDateTime.serverResponseDateTimeFormat, isUtc: true),
        json: json);
  }

  String get fillText {
    return AppString.isStringNotEmpty(fullText) ? fullText : fullTextRaw;
  }

  String get displayTime {
    if (pubDateUtc == null) {
      return "";
    }
    bool useDeviceLocalTimeZone = Storage().useDeviceLocalTimeZone;
    DateTime pubDateTime = useDeviceLocalTimeZone ? AppDateTime().getDeviceTimeFromUtcTime(pubDateUtc) : pubDateUtc;
    return AppDateTime().formatDateTime(pubDateTime, format: "MMM dd ", ignoreTimeZone: useDeviceLocalTimeZone);
  }

  @override
  String get favoriteId => id;

  @override
  String get favoriteTitle => title;

  @override
  String get favoriteKey => favoriteKeyName;

  static String favoriteKeyName = "athleticNewsIds";
}
