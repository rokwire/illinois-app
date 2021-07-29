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

class News implements Favorite{
  String id;

  String title;
  String link;
  String category;
  String description;
  String summary;
  String fulltext;
  DateTime pubDateUTC;

  Map<String,dynamic> jsonData;


  News(
      {
        this.id,
        this.title,
        this.link,
        this.category,
        this.description,
        this.summary,
        this.fulltext,
        this.pubDateUTC,
        this.jsonData});

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id          : json['id'],
      title       : json['title'],
      link        : json['link'],
      category    : json["category"],
      description : json['description'],
      summary     : json['summary'],
      fulltext    : json['fulltext'],
      pubDateUTC  : AppDateTime().dateTimeFromString(json['pubDateUTC'], format: AppDateTime.serverResponseDateTimeFormat, isUtc: true),
      jsonData    : json,
    );
  }

  String getImageUrl(){
      Map<String,dynamic> enclosure = jsonData!=null ? jsonData["enclosure"] : null;
      return enclosure!=null ? enclosure["url"] : null;
  }

  String getFillText(){
    return AppString.isStringNotEmpty(fulltext) ? fulltext : jsonData['fulltext_raw'];
  }

  String getDisplayTime() {
    if (pubDateUTC == null) {
      return "";
    }
    bool useDeviceLocalTimeZone = Storage().useDeviceLocalTimeZone;
    DateTime pubDateTime = useDeviceLocalTimeZone ? AppDateTime()
        .getDeviceTimeFromUtcTime(pubDateUTC) : pubDateUTC;
    return AppDateTime().formatDateTime(pubDateTime, format: "MMM dd ",
        ignoreTimeZone: useDeviceLocalTimeZone);
  }

  @override
  String get favoriteId => id;

  @override
  String get favoriteTitle => title;

  @override
  String get favoriteKey => favoriteKeyName;

  static String favoriteKeyName = "athleticNewsIds";


}


