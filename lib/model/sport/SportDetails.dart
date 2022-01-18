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

import 'package:illinois/utils/Utils.dart';

class SportSeasons {
  String? code;
  String? label;
  String? staff;
  List<SportSeasonSchedule>? seasons;

  SportSeasons({this.code, this.label, this.staff, this.seasons});

  static SportSeasons? fromJson(Map<String, dynamic>? json) {
    return ((json != null) && json.isNotEmpty) ? SportSeasons(
      code: JsonUtils.stringValue(json['code']),
      label: JsonUtils.stringValue(json['label']),
      staff: JsonUtils.stringValue(json['staff']),
      seasons: SportSeasonSchedule.listFromJson(JsonUtils.listValue(json['schedules']))
    ) : null;
  }
}

class SportSeasonSchedule {
  String? year;
  String? roster;
  String? schedule;

  SportSeasonSchedule({this.year, this.roster, this.schedule});

  static SportSeasonSchedule? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return SportSeasonSchedule(
      year: JsonUtils.stringValue(json['year']),
      roster: JsonUtils.stringValue(json['roster']),
      schedule: JsonUtils.stringValue(json['schedule']),
    );
  }

  static List<SportSeasonSchedule>? listFromJson(List<dynamic>? jsonList) {
    List<SportSeasonSchedule>? result;
    if (jsonList != null) {
      result = <SportSeasonSchedule>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, SportSeasonSchedule.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

class SportSocialMedia {
  final String? shortName;
  final String? twitterName;
  final String? instagramName;
  final String? facebookPage;

  SportSocialMedia({this.shortName, this.twitterName, this.instagramName, this.facebookPage});

  static SportSocialMedia? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return SportSocialMedia(
        shortName: JsonUtils.stringValue(json['shortname']),
        twitterName: JsonUtils.stringValue(json['sport_twitter_name']),
        instagramName: JsonUtils.stringValue(json['sport_instagram_name']),
        facebookPage: JsonUtils.stringValue(json['sport_facebook_page']));
  }

  static List<SportSocialMedia>? listFromJson(List<dynamic>? jsonList) {
    List<SportSocialMedia>? result;
    if (jsonList != null) {
      result = <SportSocialMedia>[];
      for (dynamic jsonEntry in jsonList) {
        SportSocialMedia? entry = (jsonEntry is Map<String, dynamic>) ? SportSocialMedia.fromJson(jsonEntry) : null;
        if (entry != null) {
          result.add(entry);
        }
      }
    }
    return result;
  }

  bool operator ==(o) =>
    (o is SportSocialMedia) &&
      (o.shortName == shortName) &&
      (o.twitterName == twitterName) &&
      (o.instagramName == instagramName) &&
      (o.facebookPage == facebookPage);

  int get hashCode =>
    (shortName?.hashCode ?? 0) ^
    (twitterName?.hashCode ?? 0) ^
    (instagramName?.hashCode ?? 0) ^
    (facebookPage?.hashCode ?? 0);
}

class SportDefinition {
  String? name;
  String? customName;
  String? shortName;
  bool? hasHeight;
  bool? hasWeight;
  bool? hasPosition;
  bool? hasSortByPosition;
  bool? hasSortByNumber;
  bool? hasScores;
  String? gender;
  bool? ticketed;
  String? iconPath;

  SportDefinition({this.name, this.customName, this.shortName, this.hasHeight,
    this.hasWeight, this.hasPosition, this.hasSortByPosition,
    this.hasSortByNumber, this.hasScores, this.gender, this.ticketed,
    this.iconPath});

  static SportDefinition? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return SportDefinition(
      name: JsonUtils.stringValue(json["name"]),
      customName: JsonUtils.stringValue(json["custom_name"]),
      shortName: JsonUtils.stringValue(json["shortName"]),
      hasHeight: JsonUtils.boolValue(json["hasHeight"]),
      hasWeight: JsonUtils.boolValue(json["hasWeight"]),
      hasPosition: JsonUtils.boolValue(json["hasPosition"]),
      hasSortByPosition: JsonUtils.boolValue(json["hasSortByPosition"]),
      hasSortByNumber: JsonUtils.boolValue(json["hasSortByNumber"]),
      hasScores: JsonUtils.boolValue(json["hasScores"]) ?? false,
      gender: JsonUtils.stringValue(json["gender"]),
      ticketed: JsonUtils.boolValue(json["ticketed"]),
      iconPath: JsonUtils.stringValue(json["icon"]),
    );
  }

  static List<SportDefinition>? listFromJson(List<dynamic>? jsonList) {
    List<SportDefinition>? result;
    if (jsonList != null) {
      result = <SportDefinition>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, SportDefinition.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<SportDefinition>? subList(List<SportDefinition>? list, { String? gender }) {
    List<SportDefinition>? result;
    if (list != null) {
      result = <SportDefinition>[];
      for (SportDefinition entry in list) {
        if ((gender == null) || (gender == entry.gender)) {
          result.add(entry);
        }
      }
    }
    return result;
  }

  bool operator ==(o) =>
    (o is SportDefinition) &&
      (o.name == name) &&
      (o.customName == customName) &&
      (o.shortName == shortName) &&
      (o.hasHeight == hasHeight) &&
      (o.hasWeight == hasWeight) &&
      (o.hasPosition == hasPosition) &&
      (o.hasSortByPosition == hasSortByPosition) &&
      (o.hasSortByNumber == hasSortByNumber) &&
      (o.hasScores == hasScores) &&
      (o.gender == gender) &&
      (o.ticketed == ticketed) &&
      (o.iconPath == iconPath);

  int get hashCode =>
    (name?.hashCode ?? 0) ^
    (customName?.hashCode ?? 0) ^
    (shortName?.hashCode ?? 0) ^
    (hasHeight?.hashCode ?? 0) ^
    (hasWeight?.hashCode ?? 0) ^
    (hasPosition?.hashCode ?? 0) ^
    (hasSortByPosition?.hashCode ?? 0) ^
    (hasSortByNumber?.hashCode ?? 0) ^
    (hasScores?.hashCode ?? 0) ^
    (gender?.hashCode ?? 0) ^
    (ticketed?.hashCode ?? 0) ^
    (iconPath?.hashCode ?? 0);
}