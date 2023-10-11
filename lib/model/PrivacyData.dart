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

import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class PrivacyData{
  List<PrivacyLevel>? levels;
  List<PrivacyType>? types;
  List<PrivacyDescription>? privacyDescription;
  List<PrivacyCategory>? categories;
  List<PrivacyFeature2>? features2;

  Map<String,dynamic>? jsonData;

  PrivacyData({this.levels,this.types,this.categories,this.features2, this.privacyDescription, this.jsonData});

  static PrivacyData? fromJson(Map<String, dynamic>? json) {

    return (json != null) ? PrivacyData(
      levels: PrivacyLevel.listFromJson(JsonUtils.listValue(json['levels'])),
      types: PrivacyType.listFromJson(JsonUtils.listValue(json['types'])),
      categories: PrivacyCategory.listFromJson(JsonUtils.listValue(json['categories'])),
      features2: PrivacyFeature2.listFromJson(JsonUtils.listValue(json['features2'])),
      privacyDescription: PrivacyDescription.listFromJson(JsonUtils.listValue(json['description'])),
      jsonData: json
    ) : null;
  }

  reload() {
    if (jsonData != null) {
      categories = PrivacyCategory.listFromJson(JsonUtils.listValue(jsonData!['categories']));
      types = PrivacyType.listFromJson(JsonUtils.listValue(jsonData!['types']));
    }
  }

  //Util methods
  String? getLocalizedString(String? text) {
    return Localization().getStringFromMapping(text, (jsonData != null) ? jsonData!['strings'] : null);
  }
}

class PrivacyCategory{
  String? title;
  String? titleKey;
  Map<String, dynamic>? description;
  List<PrivacyEntry>? entries;
  List<PrivacyEntry2>? entries2;

  PrivacyCategory({this.title, this.titleKey, this.description,this.entries, this.entries2});

  static PrivacyCategory? fromJson(Map<String, dynamic>? json) {

    return (json != null) ? PrivacyCategory(
      title:PrivacyData().getLocalizedString(JsonUtils.stringValue(json["title"])),
      titleKey:PrivacyData().getLocalizedString(JsonUtils.stringValue(json["title_key"])),
      description:JsonUtils.mapValue(json['description']),
      entries: PrivacyEntry.listFromJson(JsonUtils.listValue(json['entries'])),
      entries2: PrivacyEntry2.listFromJson(JsonUtils.listValue(json['entries2']))
    ) : null;
  }

  static List<PrivacyCategory>? listFromJson(List<dynamic>? jsonList) {
    List<PrivacyCategory>? result;
    if (jsonList != null) {
      result = <PrivacyCategory>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, PrivacyCategory.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

class PrivacyEntry{
  String? key;
  String? text;
  String? type;
  int? minLevel;

  PrivacyEntry({this.key,this.text,this.type,this.minLevel});

  static PrivacyEntry? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? PrivacyEntry(
        key:json["key"],
        text: PrivacyData().getLocalizedString(json["text"]),
        type:json["type"],
        minLevel:json["min_level"]
    ) : null;
  }

  static List<PrivacyEntry>? listFromJson(List<dynamic>? jsonList) {
    List<PrivacyEntry>? result;
    if (jsonList != null) {
      result = <PrivacyEntry>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, PrivacyEntry.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

class PrivacyEntry2{
  String? title;
  String? titleKey;
  String? description;
  String? descriptionKey;
  String? dataUsage;
  String? dataUsageKey;
  String? additionalDescription;
  String? additionalDescriptionKey;
  String? additionalDataUsage;
  String? additionalDataUsageKey;
  int? additionalDataMinLevel;
  int? minLevel;
  String? iconRes;
  String? offIconRes;

  PrivacyEntry2({this.title, this.titleKey, this.description, this.descriptionKey, this.dataUsage, this.dataUsageKey,this.additionalDescription, this.additionalDescriptionKey, this.additionalDataUsage, this.additionalDataUsageKey,
    this.iconRes, this.offIconRes, this.minLevel, this.additionalDataMinLevel});

  static PrivacyEntry2? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? PrivacyEntry2(
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
    ) : null;
  }

  static List<PrivacyEntry2>? listFromJson(List<dynamic>? jsonList) {
    List<PrivacyEntry2>? result;
    if (jsonList != null) {
      result = <PrivacyEntry2>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, PrivacyEntry2.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

class PrivacyDescription{
  String? key;
  String? text;
  int? level;

  PrivacyDescription({this.key, this.text, this.level});

  static PrivacyDescription? fromJson(Map<String, dynamic>? json) {
    if(json!=null){
      return PrivacyDescription(
          key:json["key"],
          text:PrivacyData().getLocalizedString(json["text"]),
          level:json["level"]
      );
    }
    return null;
  }

  static List<PrivacyDescription>? listFromJson(List<dynamic>? jsonList) {
    List<PrivacyDescription>? result;
    if (jsonList != null) {
      result = <PrivacyDescription>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, PrivacyDescription.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

class PrivacyLevel{
  int? value;
  String? title;

  PrivacyLevel({this.value,this.title});

  static PrivacyLevel? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? PrivacyLevel(
        value:json["value"],
        title:PrivacyData().getLocalizedString(json["title"])
    ) : null;
  }

  static List<PrivacyLevel>? listFromJson(List<dynamic>? jsonList) {
    List<PrivacyLevel>? result;
    if (jsonList != null) {
      result = <PrivacyLevel>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, PrivacyLevel.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

class PrivacyType{
  String? value;
  String? title;

  PrivacyType({this.value,this.title});

  static PrivacyType? fromJson(Map<String, dynamic>?json) {
    if(json!=null){
     return  PrivacyType(
        value:json["value"],
        title:PrivacyData().getLocalizedString(json["title"])
      );
    }
    return null;
  }

  static List<PrivacyType>? listFromJson(List<dynamic>? jsonList) {
    List<PrivacyType>? result;
    if (jsonList != null) {
      result = <PrivacyType>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, PrivacyType.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

class PrivacyFeature2{
  String? key;
  String? text;
  int? maxLevel;

  PrivacyFeature2({this.key, this.text, this.maxLevel});

  static PrivacyFeature2? fromJson(Map<String, dynamic>? json) {
    if(json!=null){
      return PrivacyFeature2(
          key:json["key"],
          text:PrivacyData().getLocalizedString(json["text"]),
          maxLevel:json["max_level"]
      );
    }
    return null;
  }

  static List<PrivacyFeature2>? listFromJson(List<dynamic>? jsonList) {
    List<PrivacyFeature2>? result;
    if (jsonList != null) {
      result = <PrivacyFeature2>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, PrivacyFeature2.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}