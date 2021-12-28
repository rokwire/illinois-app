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
      code: AppJson.stringValue(json['code']),
      label: AppJson.stringValue(json['label']),
      staff: AppJson.stringValue(json['staff']),
      seasons: SportSeasonSchedule.listFromJson(AppJson.listValue(json['schedules']))
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
      year: AppJson.stringValue(json['year']),
      roster: AppJson.stringValue(json['roster']),
      schedule: AppJson.stringValue(json['schedule']),
    );
  }

  static List<SportSeasonSchedule>? listFromJson(List<dynamic>? jsonList) {
    List<SportSeasonSchedule>? result;
    if (jsonList != null) {
      result = <SportSeasonSchedule>[];
      for (dynamic jsonEntry in jsonList) {
        AppList.add(result, SportSeasonSchedule.fromJson(AppJson.mapValue(jsonEntry)));
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
        shortName: AppJson.stringValue(json['shortname']),
        twitterName: AppJson.stringValue(json['sport_twitter_name']),
        instagramName: AppJson.stringValue(json['sport_instagram_name']),
        facebookPage: AppJson.stringValue(json['sport_facebook_page']));
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
      name: AppJson.stringValue(json["name"]),
      customName: AppJson.stringValue(json["custom_name"]),
      shortName: AppJson.stringValue(json["shortName"]),
      hasHeight: AppJson.boolValue(json["hasHeight"]),
      hasWeight: AppJson.boolValue(json["hasWeight"]),
      hasPosition: AppJson.boolValue(json["hasPosition"]),
      hasSortByPosition: AppJson.boolValue(json["hasSortByPosition"]),
      hasSortByNumber: AppJson.boolValue(json["hasSortByNumber"]),
      hasScores: AppJson.boolValue(json["hasScores"]) ?? false,
      gender: AppJson.stringValue(json["gender"]),
      ticketed: AppJson.boolValue(json["ticketed"]),
      iconPath: AppJson.stringValue(json["icon"]),
    );
  }
}