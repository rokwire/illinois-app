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
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Game with Explore implements Favorite {
  final String? id;
  final String? dateToString;
  final String? timeToString;
  final String? dateTimeUtcString;
  final DateTime? dateTimeUtc;
  final String? endDateTimeUtcString;
  final DateTime? endDateTimeUtc;
  final String? endDateString;
  final bool? allDay;
  final String? status;
  final String? description;
  final Sport? sport;
  final GameLocation? location;
  final String? tv;
  final String? radio;
  final String? parkingUrl;
  final Links? links;
  Opponent? opponent;
  String? sponsor;
  List<GameResult>? results;

  Map<String, dynamic>? jsonData;

  String? randomImageURL;

  static final String dateFormat = 'MM/dd/yyyy';
  static final String dateTimeFormat = 'MM/dd/yyyy HH:mm:ss a';
  static final String utcDateTimeFormat = 'yyyy-MM-ddTHH:mm:ssZ';

  Game(
      {this.id,
      this.dateToString,
      this.timeToString,
      this.dateTimeUtcString,
      this.dateTimeUtc,
      this.endDateTimeUtcString,
      this.endDateTimeUtc,
      this.endDateString,
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

  static Game? fromJson(Map<String, dynamic>? json) {
    return ((json != null) && json.isNotEmpty) ? Game(
      id: json['id'],
      dateToString: json['date'],
      timeToString: json['time'],
      dateTimeUtcString: json['datetime_utc'],
      dateTimeUtc: DateTimeUtils.dateTimeFromString(json['datetime_utc'], format: utcDateTimeFormat, isUtc: true),
      endDateTimeUtcString: json['end_datetime_utc'],
      endDateTimeUtc: DateTimeUtils.dateTimeFromString(json['end_datetime_utc'], format: utcDateTimeFormat, isUtc: true),
      endDateString: json['end_date'],
      allDay: json['all_day'],
      status: json['status'],
      description: json['description'],
      sport: Sport.fromJson(json['sport']),
      location: GameLocation.fromJson(json['location']),
      tv: json['tv'],
      radio: json['radio'],
      parkingUrl: json['parking_url'],
      links: Links.fromJson(json['links']),
      opponent: Opponent.fromJson(json['opponent']),
      sponsor: json['sponsor'],
      results: GameResult.listFromJson(JsonUtils.listValue(json['results'])),
      jsonData: json,
    ) : null;
  }

  @override
  bool operator ==(other) =>
      (other is Game) &&
      (const DeepCollectionEquality().equals(other.jsonData, jsonData));

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(jsonData);


  String get title {
    String? opponentName = opponent?.name;
    String cancelledLabel = Localization().getStringEx("common.label.cancelled", "Cancelled");
    String teamName = Localization().getString('app.team_name') ?? '';
    String title = isHomeGame ? '$opponentName at $teamName' : '$teamName at $opponentName';

    // Show cancelled label (C O V I D - 1 9 use case)
    return ((status?.toUpperCase() ?? "") == "C") ? "$title\n$cancelledLabel" : title;
  }

  bool get isHomeGame {
    String? gameLocationHan = location?.han; //values "H" - home, "A" - away, "N" - N/A
    return ('H' == gameLocationHan);
  }

  bool get isGameDay {
    if (date == null) {
      return false;
    }
    DateTime universityLocalGameStartDateTime = date!; //dateTimeUtc.add(durationDifferenceUniversityToGmt);
    DateTime? universityLocalGameEndDateTime = endDate; //AppDateTime().getUniLocalTimeFromUtcTime(endDateTimeUtc);
    DateTime nowUtcDateTime = AppDateTime().now.toUtc();
    DateTime nowUniversityDateTime = AppDateTime().getUniLocalTimeFromUtcTime(nowUtcDateTime)!;
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
    return dateTimeUtc != null && DateTime.now().isBefore(dateTimeUtc!);
  }

  DateTime? get dateTimeUniLocal {
    return AppDateTime().getUniLocalTimeFromUtcTime(dateTimeUtc);
  }

  DateTime? get date {
    return DateTimeUtils.dateTimeFromString(dateToString, format: dateFormat);
  }

  DateTime? get endDate {
    return DateTimeUtils.dateTimeFromString(endDateString, format: dateFormat);
  }

  bool get isMoreThanOneDay {
    int gameEventDays = (endDateTimeUtc?.difference(dateTimeUtc!).inDays ?? 0).abs();
    return (gameEventDays >= 1);
  }

  String? get imageUrl {
    String? imageUrl = links?.preGame?.storyImageUrl;
    if ((imageUrl != null) && imageUrl.isEmpty) {
      return imageUrl;
    } else {
      return _randomImageURL;
    }
  }

  String? get newsTitle {
    return links?.preGame?.text;
  }

  String? get newsImageUrl {
    String? imageUrl = links?.preGame?.storyImageUrl;
    if ((imageUrl != null) && imageUrl.isEmpty) {
      return imageUrl;
    } else {
      return _randomImageURL;
    }
  }

  String? get newsContent {
    return null;
  }

  String? get _randomImageURL {
    if (randomImageURL == null) {
      randomImageURL = Content().randomImageUrl('sports.${sport!.shortName}');
    }
    return randomImageURL!.isNotEmpty ? randomImageURL : null;
  }

  ExploreLocation? get _exploreLocation {
    if (location == null) {
      return null;
    }
    return ExploreLocation(description: location!.location);
  }

  ////////////////////////////
  // Explore implementation

  @override String? get exploreId => id;
  @override String? get exploreTitle => title;
  @override String? get exploreDescription => description;
  @override DateTime? get exploreDateTimeUtc => dateTimeUtc;
  @override String? get exploreImageURL => imageUrl;
  @override ExploreLocation? get exploreLocation => _exploreLocation;

  ////////////////////////////
  // Favorite implementation

  static const String favoriteKeyName = "athleticEventIds";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => id;
  
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "date": dateToString,
      "time": timeToString,
      "datetime_utc": dateTimeUtcString,
      "end_datetime_utc": endDateTimeUtcString,
      "end_date": endDateString,
      "all_day": allDay,
      "status": status,
      "description": description,
      "sport": sport?.toJson(),
      "location": location?.toJson(),
      "tv": tv,
      "radio": radio,
      "parking_url": parkingUrl,
      "links": links?.toJson(),
      "opponent": opponent?.toJson(),
      "sponsor": sponsor,
      "results": GameResult.listToJson(results)
    };
  }

  static List<Game>? listFromJson(List<dynamic>? jsonList) {
    List<Game>? result;
    if (jsonList != null) {
      result = <Game>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Game.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

class Sport {
  final String? title;
  final String? shortName;

  Sport({this.title, this.shortName});

  Map<String, dynamic> toJson() {
    return {"title": title, "shortname": shortName};
  }

  static Sport? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return Sport(title: json['title'], shortName: json['shortname']);
  }
}

class GameLocation {
  final String? location;
  final String? han;

  GameLocation({this.location, this.han});

  Map<String, dynamic> toJson() {
    return {"location": location, "HAN": han};
  }

  static GameLocation? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return GameLocation(location: json['location'], han: json['HAN']);
  }

  String? get analyticsValue => location;
}

class Links {
  final String? liveStats;
  final String? video;
  final String? audio;
  final String? tickets;
  final GameStory? preGame;

  Links({this.liveStats, this.video, this.audio, this.tickets, this.preGame});

  Map<String, dynamic> toJson() {
    return {"livestats": liveStats, "video": video, "audio": audio, "tickets": tickets, "pregame": preGame?.toJson()};
  }

  static Links? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    dynamic preGameJson = json['pregame'];
    GameStory? preGame = preGameJson != null ? GameStory.fromJson(preGameJson) : null;
    return Links(liveStats: json['livestats'], video: json['video'], audio: json['audio'], tickets: json['tickets'], preGame: preGame);
  }
}

class GameStory {
  final String? id;
  final String? url;
  final String? storyImageUrl;
  final String? text;

  GameStory({this.id, this.url, this.storyImageUrl, this.text});

  Map<String, dynamic> toJson() {
    return {"id": id, "url": url, "story_image_url": storyImageUrl, "text": text};
  }

  static GameStory? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return GameStory(id: json['id'], url: json['url'], storyImageUrl: json['story_image_url'], text: json['text']);
  }
}

class Opponent {
  final String? name;
  final String? logoImage;

  Opponent({this.name, this.logoImage});

  Map<String, dynamic> toJson() {
    return {"name": name, "logo_image": logoImage};
  }

  static Opponent? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return Opponent(name: json['name'], logoImage: json['logo_image']);
  }
}

class GameResult {
  final String? status;
  final String? teamScore;
  final String? opponentScore;

  GameResult({this.status, this.teamScore, this.opponentScore});

  Map<String, dynamic> toJson() {
    return {"status": status, "team_score": teamScore, "opponent_score": opponentScore};
  }

  static GameResult? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return GameResult(status: json['status'], teamScore: json['team_score'], opponentScore: json['opponent_score']);
  }

  static List<GameResult>? listFromJson(List<dynamic>? jsonList) {
    List<GameResult>? result;
    if (jsonList != null) {
      result = <GameResult>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, GameResult.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<GameResult?>? results) {
    List<dynamic>? jsonList;
    if (CollectionUtils.isNotEmpty(results)) {
      jsonList = [];
      for (GameResult? result in results!) {
        jsonList.add(result?.toJson());
      }
    }
    return jsonList;
  }
}
