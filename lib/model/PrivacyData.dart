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

import 'package:illinois/service/Assets.dart';
import 'package:illinois/service/Localization.dart';

class PrivacyData{
  List<PrivacyLevel> levels;
  List<PrivacyType> types;
  List<PrivacyDescription> privacyDescription;
  List<PrivacyCategory> categories;
  List<PrivacyFeature2> features2;

  Map<String,dynamic> jsonData;

  PrivacyData({this.levels,this.types,this.categories,this.features2, this.privacyDescription, this.jsonData});

  factory PrivacyData.fromJson(Map<String, dynamic> json) {
    List<dynamic> levelsJson = json['levels'];
    List<PrivacyLevel> levels = (levelsJson != null) ? levelsJson.map((
        value) => PrivacyLevel.fromJson(value))
        .toList() : null;

    List<dynamic> typesJson = json['types'];
    List<PrivacyType> types = (typesJson != null) ? typesJson.map((
        value) => PrivacyType.fromJson(value))
        .toList() : null;

    List<dynamic> categoriesJson = json['categories'];
    List<PrivacyCategory> categories = (categoriesJson != null) ? categoriesJson.map((
        value) => PrivacyCategory.fromJson(value))
        .toList() : null;

    List<dynamic> descriptionJson = json['description'];
    List<PrivacyDescription> description = (descriptionJson != null) ? descriptionJson.map((
        value) => PrivacyDescription.fromJson(value))
        .toList() : null;

    List<dynamic> features2Json = json['features2'];
    List<PrivacyFeature2> features2 = (features2Json != null) ? features2Json.map((
        value) => PrivacyFeature2.fromJson(value))
        .toList() : null;


    return PrivacyData(
      levels: levels,
      types: types,
      categories: categories,
      features2: features2,
      privacyDescription: description,
      jsonData: json
    );
  }

  reload() {
    if (categories != null) {
      List<dynamic> categoriesJson = jsonData['categories'];
      categories = (categoriesJson != null) ? categoriesJson.map((value) => PrivacyCategory.fromJson(value))
          .toList() : null;
    }

    if (types != null) {
      List<dynamic> typesJson = jsonData['types'];
      types = (typesJson != null) ? typesJson.map((value) => PrivacyType.fromJson(value)).toList() : null;
    }
  }

  //Util methods
  String getLocalizedString(String text) {
    return Localization().getStringFromMapping(text, (jsonData != null) ? jsonData['strings'] : Assets()['privacy.strings']);
  }
}

class PrivacyCategory{
  String title;
  Map<String, dynamic> description;
  List<PrivacyEntry> entries;
  List<PrivacyEntry2> entries2;

  PrivacyCategory({this.title,this.description,this.entries, this.entries2});

  factory PrivacyCategory.fromJson(Map<String, dynamic> json) {
    List<dynamic> entriesJson = json['entries'];
    List<PrivacyEntry> entries = (entriesJson != null) ? entriesJson.map((
        value) => PrivacyEntry.fromJson(value))
        .toList() : null;
    List<dynamic> entries2Json = json['entries2'];
    List<PrivacyEntry2> entries2 = (entries2Json != null) ? entries2Json.map((
        value) => PrivacyEntry2.fromJson(value))
        .toList() : null;

    return PrivacyCategory(
      title:PrivacyData().getLocalizedString(json["title"]),
      description:json['description'],
      entries: entries,
      entries2: entries2
    );
  }
}

class PrivacyEntry{
  String key;
  String text;
  String type;
  int minLevel;

  PrivacyEntry({this.key,this.text,this.type,this.minLevel});

  factory PrivacyEntry.fromJson(Map<String, dynamic> json) {
    return PrivacyEntry(
        key:json["key"],
        text: PrivacyData().getLocalizedString(json["text"]),
        type:json["type"],
        minLevel:json["min_level"]
    );
  }
}

class PrivacyEntry2{
  String title;
  String titleKey;
  String description;
  String descriptionKey;
  String dataUsage;
  String dataUsageKey;
  String additionalDescription;
  String additionalDescriptionKey;
  String additionalDataUsage;
  String additionalDataUsageKey;
  int additionalDataMinLevel;
  int minLevel;
  String iconRes;
  String offIconRes;

  PrivacyEntry2({this.title, this.titleKey, this.description, this.descriptionKey, this.dataUsage, this.dataUsageKey,this.additionalDescription, this.additionalDescriptionKey, this.additionalDataUsage, this.additionalDataUsageKey,
    this.iconRes, this.offIconRes, this.minLevel, this.additionalDataMinLevel});

  factory PrivacyEntry2.fromJson(Map<String, dynamic> json) {
    return PrivacyEntry2(
        title: json["title"],
        titleKey: json["title_key"],
        description: json["description"],
        descriptionKey: json["description_key"],
        dataUsage: json["dataUsage"],
        dataUsageKey: json["dataUsage_key"],
        additionalDescription: json["additional_description"],
        additionalDescriptionKey: json["additional_description_key"],
        additionalDataUsage: json["additional_dataUsage"],
        additionalDataUsageKey: json["additional_dataUsage_key"],
        iconRes: json["icon_resource"],
        offIconRes: json["off_icon_resource"],
        minLevel:json["min_level"],
        additionalDataMinLevel:json["additional_min_level"]
    );
  }
}

class PrivacyDescription{
  String key;
  String text;
  int level;

  PrivacyDescription({this.key, this.text, this.level});

  factory PrivacyDescription.fromJson(Map<String, dynamic> json) {
    if(json!=null){
      return PrivacyDescription(
          key:json["key"],
          text:PrivacyData().getLocalizedString(json["text"]),
          level:json["level"]
      );
    }
    return null;
  }
}

class PrivacyLevel{
  int value;
  String title;

  PrivacyLevel({this.value,this.title});

  factory PrivacyLevel.fromJson(Map<String, dynamic> json) {
    return PrivacyLevel(
        value:json["value"],
        title:PrivacyData().getLocalizedString(json["title"])
    );
  }
}

class PrivacyType{
  String value;
  String title;

  PrivacyType({this.value,this.title});

  factory PrivacyType.fromJson(Map<String, dynamic> json) {
    if(json!=null){
     return  PrivacyType(
        value:json["value"],
        title:PrivacyData().getLocalizedString(json["title"])
      );
    }
    return null;
  }
}

class PrivacyCategoryDescription{
  String type;
  String text;

  PrivacyCategoryDescription({this.type,this.text});

  factory PrivacyCategoryDescription.fromJson(Map<String, dynamic> json) {
    if(json!=null){
      return PrivacyCategoryDescription(
          type:json["type"],
          text:PrivacyData().getLocalizedString(json["text"]),
      );
    }
    return null;
  }
}

class PrivacyFeature2{
  String key;
  String text;
  int maxLevel;

  PrivacyFeature2({this.key, this.text, this.maxLevel});

  factory PrivacyFeature2.fromJson(Map<String, dynamic> json) {
    if(json!=null){
      return PrivacyFeature2(
          key:json["key"],
          text:PrivacyData().getLocalizedString(json["text"]),
          maxLevel:json["max_level"]
      );
    }
    return null;
  }
}