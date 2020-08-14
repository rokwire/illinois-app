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

class SportSeasons {
  String code;
  String label;
  String staff;
  List<SportSeasonSchedule> seasons;

  SportSeasons({this.code, this.label, this.staff, this.seasons});

  factory SportSeasons.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    List<dynamic> schedulesJson = json['schedules'];
    List<SportSeasonSchedule> seasons = (schedulesJson != null)
        ? schedulesJson.map((value) => SportSeasonSchedule.fromJson(value)).toList()
        : null;
    return SportSeasons(
        code: json['code'],
        label: json['label'],
        staff: json['staff'],
        seasons: seasons);
  }
}

class SportSeasonSchedule {
  String year;
  String roster;
  String schedule;

  SportSeasonSchedule({this.year, this.roster, this.schedule});

  factory SportSeasonSchedule.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return SportSeasonSchedule(
      year: json['year'],
      roster: json['roster'],
      schedule: json['schedule'],
    );
  }
}

class SportSocialMedia {
  int id;
  String shortName;
  String abbrev;
  String name;
  String shortDisplayName;
  String globalSportShortName;
  String twitterName;
  String instagramName;
  String facebookPage;
  String facebookId;

  SportSocialMedia(
      {this.id,
        this.shortName,
        this.abbrev,
        this.name,
        this.shortDisplayName,
        this.globalSportShortName,
        this.twitterName,
        this.instagramName,
        this.facebookPage,
        this.facebookId});

  factory SportSocialMedia.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return SportSocialMedia(
        id: json['id'],
        shortName: json['shortname'],
        abbrev: json['abbrev'],
        name: json['name'],
        shortDisplayName: json['short_display_name'],
        globalSportShortName: json['global_sport_shortname'],
        twitterName: json['sport_twitter_name'],
        instagramName: json['sport_instagram_name'],
        facebookPage: json['sport_facebook_page'],
        facebookId: json['sport_facebook_id']);
  }
}

class SportDefinition {
  String name;
  String customName;
  String shortName;
  bool hasHeight;
  bool hasWeight;
  bool hasPosition;
  bool hasSortByPosition;
  bool hasSortByNumber;
  bool hasScores;
  String gender;
  bool ticketed;
  String iconPath;

  SportDefinition({this.name, this.customName, this.shortName, this.hasHeight,
    this.hasWeight, this.hasPosition, this.hasSortByPosition,
    this.hasSortByNumber, this.hasScores, this.gender, this.ticketed,
    this.iconPath});

  factory SportDefinition.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return SportDefinition(
      name: json["name"],
      customName: json["custom_name"],
      shortName: json["shortName"],
      hasHeight: json["hasHeight"],
      hasWeight: json["hasWeight"],
      hasPosition: json["hasPosition"],
      hasSortByPosition: json["hasSortByPosition"],
      hasSortByNumber: json["hasSortByNumber"],
      hasScores: json["hasScores"] ?? false,
      gender: json["gender"],
      ticketed: json["ticketed"],
      iconPath: json["icon"],
    );
  }
}