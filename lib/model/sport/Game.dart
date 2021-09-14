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
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Localization.dart';

import '../UserData.dart';

class Game implements Favorite {
  final String id;
  final String dateToString;
  final String timeToString;
  final DateTime dateTimeUtc;
  final DateTime endDateTimeUtc;
  final DateTime endDateTime;
  final bool allDay;
  final String status;
  final String description;
  final Sport sport;
  final GameLocation location;
  final String tv;
  final String radio;
  final String parkingUrl;
  final Links links;
  Opponent opponent;
  String sponsor;
  List<GameResult> results;

  Map<String, dynamic> jsonData;

  String randomImageURL;

  Game(
      {this.id,
      this.dateToString,
      this.timeToString,
      this.dateTimeUtc,
      this.endDateTimeUtc,
      this.endDateTime,
      this.allDay,
      this.status,
      this.description,
      this.sport,
      this.location,
      this.tv,
      this.radio,
      this.parkingUrl,
      this.links,
      this.opponent,
      this.sponsor,
      this.results,
      this.jsonData});

  factory Game.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    List<dynamic> resultsJson = json['results'];
    List<GameResult> results = (resultsJson != null) ? resultsJson.map((value) => GameResult.fromJson(value)).toList() : null;
    return Game(
      id: json['id'],
      dateToString: json['date'],
      timeToString: json['time'],
      dateTimeUtc: AppDateTime().dateTimeFromString(json['datetime_utc'], format: AppDateTime.gameResponseDateTimeFormat, isUtc: true),
      endDateTimeUtc: AppDateTime().dateTimeFromString(json['end_datetime_utc'], format: AppDateTime.gameResponseDateTimeFormat, isUtc: true),
      endDateTime: AppDateTime().dateTimeFromString(json['end_datetime'], format: AppDateTime.gameResponseDateTimeFormat2),
      allDay: json['all_day'],
      status: json['status'],
      description: json['description'],
      sport: Sport.fromJson(json['sport']),
      location: GameLocation.fromJson(json['location']),
      tv: json['tv'],
      radio: json['radio'],
      parkingUrl: json['custom_display_field_2'],
      links: Links.fromJson(json['links']),
      opponent: Opponent.fromJson(json['opponent']),
      sponsor: json['sponsor'],
      results: results,
      jsonData: json,
    );
  }

  String get title {
    String opponentName = opponent?.name;
    String cancelledLabel = Localization().getStringEx("app.common.label.cancelled", "Cancelled") ?? '';
    String teamName = Localization().getString('app.team_name') ?? '';
    String title = isHomeGame ? '$opponentName at $teamName' : '$teamName at $opponentName';

    // Show cancelled label (C O V I D - 1 9 use case)
    return ((status?.toUpperCase() ?? "") == "C") ? "$title\n$cancelledLabel" : title;
  }

  bool get isHomeGame {
    String gameLocationHan = location?.han; //values "H" - home, "A" - away, "N" - N/A
    return ('H' == gameLocationHan);
  }

  bool get isGameDay {
    if (date == null) {
      return false;
    }
    DateTime universityLocalGameStartDateTime = date; //dateTimeUtc.add(durationDifferenceUniversityToGmt);
    DateTime universityLocalGameEndDateTime = AppDateTime().getUniLocalTimeFromUtcTime(endDateTimeUtc);
    DateTime nowUtcDateTime = (AppDateTime().now ?? DateTime.now()).toUtc();
    DateTime nowUniversityDateTime = AppDateTime().getUniLocalTimeFromUtcTime(nowUtcDateTime);
    bool startDateIsToday = (nowUniversityDateTime.year == universityLocalGameStartDateTime.year) &&
        (nowUniversityDateTime.month == universityLocalGameStartDateTime.month) &&
        (nowUniversityDateTime.day == universityLocalGameStartDateTime.day);
    bool endDateIsToday = (nowUniversityDateTime.year == universityLocalGameEndDateTime?.year) &&
        (nowUniversityDateTime.month == universityLocalGameEndDateTime?.month) &&
        (nowUniversityDateTime.day == universityLocalGameEndDateTime?.day);
    bool nowIsBetweenGameDates = (nowUniversityDateTime.isAfter(universityLocalGameStartDateTime) &&
        (universityLocalGameEndDateTime != null ? nowUniversityDateTime.isBefore(universityLocalGameEndDateTime) : false));
    return (startDateIsToday || endDateIsToday) || nowIsBetweenGameDates;
  }

  bool get isUpcoming {
    return dateTimeUtc != null && DateTime.now().isBefore(dateTimeUtc);
  }

  DateTime get dateTimeUniLocal {
    return AppDateTime().getUniLocalTimeFromUtcTime(dateTimeUtc);
  }

  DateTime get date {
    return AppDateTime().dateTimeFromString(dateToString, format: AppDateTime.scheduleServerQueryDateTimeFormat);
  }

  ///
  /// Requirement 1:
  /// Workaround because of the wrong dates that come from server.
  /// endpoint: http://fightingillini.com/services/schedule_xml_2.aspx
  /// json example:
  ///
  /// {
  ///      ...
  ///      "date": "10/5/2019",
  ///      ...
  ///      "datetime_utc": "2019-10-05T00:00:00Z",
  ///      ...
  ///      "time": "2:30 / 3 PM CT",
  ///      ...
  /// }
  ///
  /// Requirement 2: 'If an event is longer than 1 day, then please show the Date as (for example) Sep 26 - Sep 29.'
  ///
  String get displayTime {
    int gameEventDays = (endDateTimeUtc?.difference(dateTimeUtc)?.inDays ?? 0).abs();
    bool eventIsMoreThanOneDay = (gameEventDays >= 1);
    int hourUtc = dateTimeUtc.hour;
    int minuteUtc = dateTimeUtc.minute;
    int secondUtc = dateTimeUtc.second;
    int millisUtc = dateTimeUtc.millisecond;
    bool useStringDateTimes = (hourUtc == 0 && minuteUtc == 0 && secondUtc == 0 && millisUtc == 0);
    final String dateFormat = 'MMM dd';
    if (eventIsMoreThanOneDay) {
      DateTime startDate = useStringDateTimes ? date : dateTimeUtc;
      DateTime endDate = useStringDateTimes ? (endDateTime ?? endDateTimeUtc) : endDateTimeUtc;
      String startDateFormatted = AppDateTime().formatDateTime(startDate, format: dateFormat, ignoreTimeZone: useStringDateTimes);
      String endDateFormatted = AppDateTime().formatDateTime(endDate, format: dateFormat, ignoreTimeZone: useStringDateTimes);
      return '$startDateFormatted - $endDateFormatted';
    } else if (useStringDateTimes) {
      String dateFormatted = AppDateTime().formatDateTime(date, format: dateFormat, ignoreTimeZone: true, showTzSuffix: false); //another workaround
      dateFormatted += ' $timeToString';
      return dateFormatted;
    } else {
      return AppDateTime().getDisplayDateTime(dateTimeUtc, allDay: allDay ?? false);
    }
  }

  String get imageUrl {
    String imageUrl = links?.preGame?.storyImageUrl;
    if ((imageUrl != null) && imageUrl.isEmpty) {
      return imageUrl;
    } else {
      return _randomImageURL;
    }
  }

  String get shortDescription {
    return description;
  }

  String get longDescription {
    return description;
  }

  String get newsTitle {
    return links?.preGame?.text;
  }

  String get newsImageUrl {
    String imageUrl = links?.preGame?.storyImageUrl;
    if ((imageUrl != null) && imageUrl.isEmpty) {
      return imageUrl;
    } else {
      return _randomImageURL;
    }
  }

  String get newsContent {
    return null;
  }

  String get _randomImageURL {
    if (randomImageURL == null) {
      randomImageURL = Assets().randomStringFromListWithKey('images.random.sports.${sport.shortName}') ?? '';
    }
    return randomImageURL.isNotEmpty ? randomImageURL : null;
  }

  Map<String, dynamic> get analyticsAttributes {
    Map<String, dynamic> attributes = {Analytics.LogAttributeGameId: id, Analytics.LogAttributeGameName: title};
    attributes.addAll(location?.analyticsAttributes ?? {});
    return attributes;
  }


  @override
  String get favoriteId => id;

  @override
  String get favoriteTitle => title;

  @override
  String get favoriteKey => favoriteKeyName;

  static String favoriteKeyName = "athleticEventIds";
}

class Sport {
  final String title;
  final String shortName;

  Sport({this.title, this.shortName});

  factory Sport.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return Sport(title: json['title'], shortName: json['shortname']);
  }
}

class GameLocation {
  final String location;
  final String han;

  GameLocation({this.location, this.han});

  factory GameLocation.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return GameLocation(location: json['location'], han: json['HAN']);
  }

  Map<String, dynamic> get analyticsAttributes {
    return {Analytics.LogAttributeLocation: location};
  }
}

class Links {
  final String liveStats;
  final String video;
  final String audio;
  final String tickets;
  final GameStory preGame;

  Links({this.liveStats, this.video, this.audio, this.tickets, this.preGame});

  factory Links.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    dynamic preGameJson = json['pregame'];
    GameStory preGame = preGameJson != null ? GameStory.fromJson(preGameJson) : null;
    return Links(liveStats: json['livestats'], video: json['video'], audio: json['audio'], tickets: json['tickets'], preGame: preGame);
  }
}

class GameStory {
  final String id;
  final String url;
  final String storyImageUrl;
  final String text;

  GameStory({this.id, this.url, this.storyImageUrl, this.text});

  factory GameStory.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return GameStory(id: json['id'], url: json['url'], storyImageUrl: json['story_image_url'], text: json['text']);
  }
}

class Opponent {
  final String name;
  final String logoImage;

  Opponent({this.name, this.logoImage});

  factory Opponent.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return Opponent(name: json['name'], logoImage: json['logo_image']);
  }
}

class GameResult {
  final String status;
  final String teamScore;
  final String opponentScore;

  GameResult({this.status, this.teamScore, this.opponentScore});

  factory GameResult.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return GameResult(status: json['status'], teamScore: json['team_score'], opponentScore: json['opponent_score']);
  }
}
