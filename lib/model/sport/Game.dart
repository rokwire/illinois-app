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

class Game implements Favorite{
  String id;
  String dateToString;
  String formattedDate;
  DateTime dateTimeUtc;
  DateTime endDateTimeUtc;
  DateTime endDateTime;
  DateInfo dateInfo;
  String timeToString;
  String type;
  String status;
  String noPlayText;
  String doubleHeader;
  String gamePromotionName;
  Sport sport;
  GameLocation location;
  String tv;
  String tvImage;
  String radio;
  String customDisplayField1;
  String customDisplayField2;
  String customDisplayField3;
  String ticketMasterEventId;
  Links links;
  Opponent opponent;
  String sponsor;
  List<GameResult> results;

  Map<String,dynamic> jsonData;

  String randomImageURL;

  Game(
      {this.id,
      this.dateToString,
      this.formattedDate,
      this.dateTimeUtc,
      this.endDateTimeUtc,
      this.endDateTime,
      this.dateInfo,
      this.timeToString,
      this.type,
      this.status,
      this.noPlayText,
      this.doubleHeader,
      this.gamePromotionName,
      this.sport,
      this.location,
      this.tv,
      this.tvImage,
      this.radio,
      this.customDisplayField1,
      this.customDisplayField2,
      this.customDisplayField3,
      this.ticketMasterEventId,
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
    List<GameResult> results = (resultsJson != null)
        ? resultsJson.map((value) => GameResult.fromJson(value)).toList()
        : null;
    return Game(
        id: json['id'],
        dateToString: json['date'],
        formattedDate: json['formatted_date'],
        dateTimeUtc: AppDateTime().dateTimeFromString(
            json['datetime_utc'], format: AppDateTime.gameResponseDateTimeFormat, isUtc: true),
        endDateTimeUtc:
        AppDateTime().dateTimeFromString(json['end_datetime_utc'],
            format: AppDateTime.gameResponseDateTimeFormat, isUtc: true),
        endDateTime: AppDateTime().dateTimeFromString(
            json['end_datetime'], format: AppDateTime.gameResponseDateTimeFormat2),
        dateInfo: DateInfo.fromJson(json['date_info']),
        timeToString: json['time'],
        type: json['type'],
        status: json['status'],
        noPlayText: json['noplay_text'],
        doubleHeader: json['doubleheader'],
        gamePromotionName: json['game_promotion_name'],
        sport: Sport.fromJson(json['sport']),
        location: GameLocation.fromJson(json['location']),
        tv: json['tv'],
        tvImage: json['tv_image'],
        radio: json['radio'],
        customDisplayField1: json['custom_display_field_1'],
        customDisplayField2: json['custom_display_field_2'],
        customDisplayField3: json['custom_display_field_3'],
        ticketMasterEventId: json['ticketmaster_event_id'],
        links: Links.fromJson(json['links']),
        opponent: Opponent.fromJson(json['opponent']),
        sponsor: json['sponsor'],
        results: results,
        jsonData: json,
    );
  }

  String get title {
    String opponentName = opponent?.name;
    String cancelledLabel = Localization().getStringEx("app.common.label.cancelled","Cancelled") ?? '';
    String teamName = Localization().getString('app.team_name') ?? '';
    String title = isHomeGame
        ? '$opponentName at $teamName'
        : '$teamName at $opponentName';

    // Show cancelled label (COVID-19 use case)
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
    DateTime universityLocalGameStartDateTime = date;//dateTimeUtc.add(durationDifferenceUniversityToGmt);
    DateTime universityLocalGameEndDateTime = AppDateTime().getUniLocalTimeFromUtcTime(endDateTimeUtc);
    DateTime nowUtcDateTime = (AppDateTime().now ?? DateTime.now()).toUtc();
    DateTime nowUniversityDateTime = AppDateTime().getUniLocalTimeFromUtcTime(nowUtcDateTime);
    bool startDateIsToday = (nowUniversityDateTime.year ==
        universityLocalGameStartDateTime.year) &&
        (nowUniversityDateTime.month ==
            universityLocalGameStartDateTime.month) &&
        (nowUniversityDateTime.day == universityLocalGameStartDateTime.day);
    bool endDateIsToday = (nowUniversityDateTime.year ==
        universityLocalGameEndDateTime?.year) &&
        (nowUniversityDateTime.month == universityLocalGameEndDateTime?.month) &&
        (nowUniversityDateTime.day == universityLocalGameEndDateTime?.day);
    bool nowIsBetweenGameDates = (nowUniversityDateTime.isAfter(universityLocalGameStartDateTime) &&
        (universityLocalGameEndDateTime!=null ? nowUniversityDateTime.isBefore(universityLocalGameEndDateTime) : false));
    return (startDateIsToday || endDateIsToday) || nowIsBetweenGameDates;
  }

  bool get isUpcoming {
    return dateTimeUtc != null && DateTime.now().isBefore(dateTimeUtc);
  }

  DateTime get dateTimeUniLocal {
    return AppDateTime().getUniLocalTimeFromUtcTime(dateTimeUtc);
  }

  DateTime get date {
    return AppDateTime().dateTimeFromString(
        dateToString, format: AppDateTime.scheduleServerQueryDateTimeFormat);
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
    bool useStringDateTimes = (hourUtc == 0 && minuteUtc == 0 &&
        secondUtc == 0 &&
        millisUtc == 0);
    final String dateFormat = 'MMM dd';
    if (eventIsMoreThanOneDay) {
      DateTime startDate = useStringDateTimes ? date : dateTimeUtc;
      DateTime endDate = useStringDateTimes ? (endDateTime ?? endDateTimeUtc) : endDateTimeUtc;
      String startDateFormatted = AppDateTime().formatDateTime(startDate, format: dateFormat, ignoreTimeZone: useStringDateTimes);
      String endDateFormatted = AppDateTime().formatDateTime(endDate, format: dateFormat, ignoreTimeZone: useStringDateTimes);
      return '$startDateFormatted - $endDateFormatted';
    }
    else if (useStringDateTimes) {
      String dateFormatted = AppDateTime().formatDateTime(date, format: dateFormat, ignoreTimeZone: true, showTzSuffix: false); //another workaround
      dateFormatted += ' $timeToString';
      return dateFormatted;
    } else {
      return AppDateTime().getDisplayDateTime(
          dateTimeUtc, allDay: dateInfo?.allDay ?? false);
    }
  }

  String get imageUrl {
    String imageUrl = links?.preGame?.storyImageUrl;
    if ((imageUrl != null) && imageUrl.isEmpty) {
      return imageUrl;
    }
    else {
      return _randomImageURL;
    }
  }

  String get shortDescription {
    return gamePromotionName;
  }

  String get longDescription {
    return gamePromotionName;
  }

  String get newsTitle {
    return links?.preGame?.text;
  }

  String get newsImageUrl {
    String imageUrl = links?.preGame?.storyImageUrl;
    if ((imageUrl != null) && imageUrl.isEmpty) {
      return imageUrl;
    }
    else {
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
    Map<String, dynamic> attributes = {
      Analytics.LogAttributeGameId : id,
      Analytics.LogAttributeGameName : title
    };
    attributes.addAll(location?.analyticsAttributes ?? {});
    return attributes;
  }

  String get parkingUrl {
    if (customDisplayField2 == null)
      return null;
    //<a href="https://ev11.evenue.net/cgi-bin/ncommerce3/SEGetEventInfo?ticketCode=GS%3AILLINOIS%3AF19%3A03P%3A&linkID=illinois&shopperContext=&pc=&caller=&appCode=&groupCode=FP&cgc=&dataAccId=863&locale=en_US&siteId=ev_illinois&poolId=pac8-evcluster1&sDomain=ev11.evenue.net" target="_blank">Buy Parking</a>
    bool hasHref = customDisplayField2.startsWith('<a href="');
    if (!hasHref)
      return null;

    int startQuotesIndex = customDisplayField2.indexOf('"');
    if (startQuotesIndex == -1)
      return null;

    String url = customDisplayField2.substring(startQuotesIndex + 1, customDisplayField2.length);

    int endQuotesIndex = url.indexOf('"');
    if (endQuotesIndex == -1)
      return null;

    url = url.substring(0, endQuotesIndex);
    return url;
  }

  @override
  String get favoriteId => id;

  @override
  String get favoriteKey => favoriteKeyName;

  static String favoriteKeyName = "athleticEventIds";
}

class DateInfo {
  bool tbd;
  bool allDay;
  DateTime startDateTime;
  String startDateToString;

  DateInfo({this.tbd, this.allDay, this.startDateTime, this.startDateToString});

  factory DateInfo.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return DateInfo(
        tbd: json['tbd'],
        allDay: json['all_day'],
        startDateTime:
        AppDateTime().dateTimeFromString(json['start_datetime'],
            format: AppDateTime.gameResponseDateTimeFormat),
        startDateToString: json['start_date']);
  }
}

class Sport {
  int id;
  String title;
  String shortName;
  String sportShortDisplay;
  String abbrev;
  int globalSportId;

  Sport(
      {this.id,
      this.title,
      this.shortName,
      this.sportShortDisplay,
      this.abbrev,
      this.globalSportId});

  factory Sport.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return Sport(
        id: json['id'],
        title: json['title'],
        shortName: json['shortname'],
        sportShortDisplay: json['sport_short_display'],
        abbrev: json['abbrev'],
        globalSportId: json['global_sport_id']);
  }
}

class GameLocation {
  String location;
  String han;
  String facility;
  String geoFencePlaceId;

  GameLocation({this.location, this.han, this.facility, this.geoFencePlaceId});

  factory GameLocation.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return GameLocation(
        location: json['location'],
        han: json['HAN'],
        facility: json['facility'],
        geoFencePlaceId: json['geofence_place_id']);
  }

  Map<String, dynamic> get analyticsAttributes {
    return { Analytics.LogAttributeLocation : location };
  }
}

class Links {
  String liveStats;
  String video;
  String audio;
  String notes;
  String tickets;
  BoxScore boxScore;
  GameStory preGame;
  GameStory postGame;
  List<GameFile> gameFiles;

  Links(
      {this.liveStats,
      this.video,
      this.audio,
      this.notes,
      this.tickets,
      this.boxScore,
      this.preGame,
      this.postGame,
      this.gameFiles});

  factory Links.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    dynamic boxScoreJson = json['boxscore'];
    BoxScore boxScore =
        boxScoreJson != null ? BoxScore.fromJson(boxScoreJson) : null;
    dynamic preGameJson = json['pregame'];
    GameStory preGame =
        preGameJson != null ? GameStory.fromJson(preGameJson) : null;
    dynamic postGameJson = json['postgame'];
    GameStory postGame =
        postGameJson != null ? GameStory.fromJson(postGameJson) : null;
    List<dynamic> gameFilesJson = json['gamefiles'];
    List<GameFile> gameFiles = (gameFilesJson != null)
        ? gameFilesJson.map((value) => GameFile.fromJson(value)).toList()
        : null;
    return Links(
        liveStats: json['livestats'],
        video: json['video'],
        audio: json['audio'],
        notes: json['notes'],
        tickets: json['tickets'],
        boxScore: boxScore,
        preGame: preGame,
        postGame: postGame,
        gameFiles: gameFiles);
  }
}

class BoxScore {
  String bid;
  String url;
  String text;

  BoxScore({this.bid, this.url, this.text});

  factory BoxScore.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return BoxScore(bid: json['bid'], url: json['url'], text: json['text']);
  }
}

class GameStory {
  String id;
  String url;
  String storyImageUrl;
  String text;

  GameStory({this.id, this.url, this.storyImageUrl, this.text});

  factory GameStory.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return GameStory(
        id: json['id'],
        url: json['url'],
        storyImageUrl: json['story_image_url'],
        text: json['text']);
  }
}

class GameFile {
  String link;
  String title;

  GameFile({this.link, this.title});

  factory GameFile.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return GameFile(link: json['link'], title: json['title']);
  }
}

class Opponent {
  int opponentGlobalId;
  String name;
  String logo;
  String logoImage;
  String location;
  String mascot;
  String opponentWebsite;
  String conferenceGame;
  String tournament;
  String tournamentColor;

  Opponent(
      {this.opponentGlobalId,
      this.name,
      this.logo,
      this.logoImage,
      this.location,
      this.mascot,
      this.opponentWebsite,
      this.conferenceGame,
      this.tournament,
      this.tournamentColor});

  factory Opponent.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return Opponent(
      opponentGlobalId: json['opponent_global_id'],
      name: json['name'],
      logo: json['logo'],
      logoImage: json['logo_image'],
      location: json['location'],
      mascot: json['mascot'],
      opponentWebsite: json['opponent_website'],
      conferenceGame: json['conference_game'],
      tournament: json['tournament'],
      tournamentColor: json['tournament_color'],
    );
  }
}

class GameResult {
  String game;
  String status;
  String teamScore;
  String opponentScore;
  String preScoreInfo;
  String postScoreInfo;
  String inProgressInfo;

  GameResult(
      {this.game,
      this.status,
      this.teamScore,
      this.opponentScore,
      this.preScoreInfo,
      this.postScoreInfo,
      this.inProgressInfo});

  factory GameResult.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return GameResult(
        game: json['game'],
        status: json['status'],
        teamScore: json['team_score'],
        opponentScore: json['opponent_score'],
        preScoreInfo: json['prescore_info'],
        postScoreInfo: json['postscore_info'],
        inProgressInfo: json['inprogress_info']);
  }
}
