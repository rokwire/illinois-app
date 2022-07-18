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

import 'package:collection/collection.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class News implements Favorite {
  final String? id;
  final String? title;
  final String? link;
  final String? category;
  final String? description;
  final String? fullText;
  final String? fullTextRaw;
  final String? imageUrl;
  final DateTime? pubDateUtc;

  final Map<String, dynamic>? json;

  static final String dateTimeFormat = 'E, dd MMM yyyy HH:mm:ss v';

  News({this.id, this.title, this.link, this.category, this.description, this.fullText, this.fullTextRaw, this.imageUrl, this.pubDateUtc, this.json});

  static News? fromJson(Map<String, dynamic>? json) {
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
        pubDateUtc: DateTimeUtils.dateTimeFromString(json['pub_date_utc'], format: dateTimeFormat, isUtc: true),
        json: json);
  }

  @override
  bool operator == (other) =>
    (other is News) &&
    (const DeepCollectionEquality().equals(other.json, json));

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(json);

  String? get fillText {
    return StringUtils.isNotEmpty(fullText) ? fullText : fullTextRaw;
  }

  String? get displayTime {
    if (pubDateUtc == null) {
      return "";
    }
    bool useDeviceLocalTimeZone = Storage().useDeviceLocalTimeZone!;
    DateTime? pubDateTime = useDeviceLocalTimeZone ? AppDateTime().getDeviceTimeFromUtcTime(pubDateUtc) : pubDateUtc;
    return AppDateTime().formatDateTime(pubDateTime, format: "MMM dd ", ignoreTimeZone: useDeviceLocalTimeZone);
  }

  // Favorite
  static const String favoriteKeyName = "athleticNewsIds";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => id;
}
