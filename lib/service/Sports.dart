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

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:illinois/model/sport/Team.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';

import 'package:illinois/model/Coach.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/model/Roster.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/Utils.dart';

import 'package:illinois/service/Network.dart';

class Sports with Service implements NotificationsListener {

  static const String GAME_URI = '${DeepLink.ROKWIRE_URL}/game_detail';

  static const String notifyChanged  = "edu.illinois.rokwire.sports.changed";
  static const String notifySocialMediasChanged  = "edu.illinois.rokwire.sports.social.medias.changed";
  static const String notifyGameDetail = "edu.illinois.rokwire.sports.game.detail";

  static final Sports _logic = Sports._internal();

  List<SportDefinition> _sports;
  List<SportDefinition> _menSports;
  List<SportDefinition> _womenSports;
  List<SportSocialMedia> _socialMedias;
  List<Map<String, dynamic>> _gameDetailsCache;

  // Singletone Factory

  factory Sports() {
    return _logic;
  }

  Sports._internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this,[
      DeepLink.notifyUri,
    ]);
    _gameDetailsCache = [];
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    await _loadSportDefinitions();
    await _loadSportSocialMedias();
    await super.initService();
  }

  @override
  void initServiceUI() {
    _processCachedGameDetails();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Auth2(), Storage(), Config()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(param);
    }
  }

  // Accessories

  List<SportDefinition> get sports {
    return _sports;
  }

  List<SportDefinition> get menSports {
    return _menSports;
  }

  List<SportDefinition> get womenSports {
    return _womenSports;
  }

  SportSocialMedia getSocialMediaForSport(String shortName) {
    if (AppString.isStringNotEmpty(shortName) && AppCollection.isCollectionNotEmpty(_socialMedias)) {
      return _socialMedias.firstWhere((socialMedia) => shortName == socialMedia.shortName);
    }
    return null;
  }

  Future<void> _loadSportDefinitions() async {
    String serviceUrl = Config().sportsServiceUrl;
    if (AppString.isStringEmpty(serviceUrl)) {
      return;
    }
    String sportsUrl = serviceUrl + '/api/v2/sports';
    Response response = await Network().get(sportsUrl, auth: NetworkAuth.Auth2);
    String responseBody = response?.body;
    if (response?.statusCode == 200) {
      List<dynamic> jsonData = AppJson.decode(responseBody);
      if (AppCollection.isCollectionNotEmpty(jsonData)) {
        _sports = [];
        _menSports = [];
        _womenSports = [];
        jsonData.forEach((value) {
          SportDefinition sport = SportDefinition.fromJson(value);
          if (sport != null) {
            _sports.add(sport);
            if ('men' == sport.gender) {
              _menSports.add(sport);
            } else if ('women' == sport.gender) {
              _womenSports.add(sport);
            }
          }
        });
      }
    } else {
      _sports = null;
      _menSports = null;
      _womenSports = null;
      Log.e('Failed to load sport definitions');
      Log.e(responseBody);
    }
    _sortSports();
    NotificationService().notify(notifyChanged, null);
  }

  void _sortSports() {
    if (AppCollection.isCollectionNotEmpty(_menSports)) {
      SportDefinition firstExplicitItem = _menSports.firstWhere((SportDefinition sportType) {
        return sportType.customName?.toLowerCase() == "football";
      });

      SportDefinition secondExplicitItem = _menSports.firstWhere((SportDefinition sportType) {
        return sportType.customName?.toLowerCase() == "basketball";
      });

      //sort
      _menSports.sort((SportDefinition first, SportDefinition second) {
        return first?.customName?.compareTo(second?.customName);
      });

      //Explicitly ordered items
      if (firstExplicitItem != null) {
        _menSports.remove(firstExplicitItem);
        _menSports.insert(0, firstExplicitItem);
      }

      if (secondExplicitItem != null) {
        _menSports.remove(secondExplicitItem);
        _menSports.insert(1, secondExplicitItem);
      }
    }

    if (AppCollection.isCollectionNotEmpty(_womenSports)) {
      SportDefinition firstExplicitItem = _womenSports.firstWhere((SportDefinition sportType) {
        return sportType.customName?.toLowerCase() == "volleyball";
      });

      SportDefinition secondExplicitItem = _womenSports.firstWhere((SportDefinition sportType) {
        return sportType.customName?.toLowerCase() == "basketball";
      });

      //sort
      _womenSports.sort((SportDefinition first, SportDefinition second) {
        return first?.customName?.compareTo(second?.customName);
      });

      //Explicitly ordered items
      if (firstExplicitItem != null) {
        _womenSports.remove(firstExplicitItem);
        _womenSports.insert(0, firstExplicitItem);
      }

      if (secondExplicitItem != null) {
        _womenSports.remove(secondExplicitItem);
        _womenSports.insert(1, secondExplicitItem);
      }
    }
  }

  Future<void> _loadSportSocialMedias() async {
    List<dynamic> jsonList = Storage().sportSocialMediaList;
    _socialMedias = (jsonList != null) ? jsonList.map((value) => SportSocialMedia.fromJson(value)).toList() : null;

    if (AppString.isStringEmpty(Config().sportsServiceUrl)) {
      return;
    }
    String socialUrl = Config().sportsServiceUrl + '/api/v2/social';
    Response response = await Network().get(socialUrl, auth: NetworkAuth.Auth2);
    String responseBody = response?.body;
    if (response?.statusCode == 200) {
      List<dynamic> jsonList = AppJson.decodeList(responseBody);
      List<SportSocialMedia> socialMedias =
          AppCollection.isCollectionNotEmpty(jsonList) ? jsonList.map((value) => SportSocialMedia.fromJson(value)).toList() : null;
      if ((socialMedias != null) && ((_socialMedias == null) || !DeepCollectionEquality().equals(socialMedias, _socialMedias))) {
        _socialMedias = socialMedias;
        Storage().sportSocialMediaList = jsonList;
        NotificationService().notify(notifyChanged, null);
      }
    } else {
      Log.e('Failed to load social media');
      Log.e(responseBody);
      return null;
    }
  }

  SportDefinition getSportByShortName(String sportShortName) {
    if (AppCollection.isCollectionNotEmpty(_sports) && AppString.isStringNotEmpty(sportShortName)) {
      for (SportDefinition sport in _sports) {
        if (sportShortName == sport.shortName) {
          return sport;
        }
      }
    }
    return null;
  }

  Future<List<Roster>> loadRosters(String sportKey) async {
    if (AppString.isStringNotEmpty(Config().sportsServiceUrl) && AppString.isStringNotEmpty(sportKey)) {
      final rostersUrl = "${Config().sportsServiceUrl}/api/v2/players?sport=$sportKey";
      final response = await Network().get(rostersUrl, auth: NetworkAuth.Auth2);
      String responseBody = response?.body;
      int responseCode = response?.statusCode ?? -1;
      if (responseCode == 200) {
        List<dynamic> jsonData = AppJson.decode(responseBody);
        if (AppCollection.isCollectionNotEmpty(jsonData)) {
          List<Roster> rosters = [];
          for (Map<String, dynamic> jsonEntry in jsonData) {
            Roster roster = Roster.fromJson(jsonEntry);
            if (roster != null) {
              rosters.add(roster);
            }
          }
          return rosters;
        }
      } else {
        Log.e('Failed to load rosters');
        Log.e(responseBody);
      }
    }
    return null;
  }

  Future<List<Coach>> loadCoaches(String sportKey) async {
    if (AppString.isStringNotEmpty(Config().sportsServiceUrl) && AppString.isStringNotEmpty(sportKey)) {
      final coachesUrl = "${Config().sportsServiceUrl}/api/v2/coaches?sport=$sportKey";
      final response = await Network().get(coachesUrl, auth: NetworkAuth.Auth2);
      String responseBody = response?.body;
      int responseCode = response?.statusCode;
      if (responseCode == 200) {
        List<dynamic> jsonList = AppJson.decode(responseBody);
        if (AppCollection.isCollectionNotEmpty(jsonList)) {
          List<Coach> coaches = [];
          for (Map<String, dynamic> jsonEntry in jsonList) {
            Coach coach = Coach.fromJson(jsonEntry);
            if (coach != null) {
              coaches.add(coach);
            }
          }
          return coaches;
        }
      } else {
        Log.e('Failed to load coaches.');
        Log.e(responseBody);
      }
    }
    return null;
  }

  Future<TeamSchedule> loadScheduleForCurrentSeason(String sportKey) async {
    if (AppString.isStringEmpty(Config().sportsServiceUrl) || AppString.isStringEmpty(sportKey)) {
      return null;
    }
    String scheduleUrl = '${Config().sportsServiceUrl}/api/v2/team-schedule?sport=$sportKey';
    final response = await Network().get(scheduleUrl, auth: NetworkAuth.Auth2);
    int responseCode = response?.statusCode ?? -1;
    String responseBody = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic> jsonData = AppJson.decode(responseBody);
      TeamSchedule schedule = TeamSchedule.fromJson(jsonData);
      return schedule;
    } else {
      Log.e('Failed to load schedule for $sportKey. Reason: $responseBody');
      return null;
    }
  }

  Future<TeamRecord> loadRecordForCurrentSeason(String sportKey) async {
    if (AppString.isStringEmpty(Config().sportsServiceUrl) && AppString.isStringEmpty(sportKey)) {
      return null;
    }
    String scheduleUrl = '${Config().sportsServiceUrl}/api/v2/team-record?sport=$sportKey';
    final response = await Network().get(scheduleUrl, auth: NetworkAuth.Auth2);
    int responseCode = response?.statusCode ?? -1;
    String responseBody = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic> jsonData = AppJson.decode(responseBody);
      TeamRecord record = TeamRecord.fromJson(jsonData);
      return record;
    } else {
      Log.e('Failed to load record for $sportKey. Reason: $responseBody');
      return null;
    }
  }

  Future<List<Game>> loadTopScheduleGames() async {
    List<Game> gamesList = await loadGames();
    return getTopScheduleGamesFromList(gamesList);
  }

  List<Game> getTopScheduleGamesFromList(List<Game> gamesList) {
    if (AppCollection.isCollectionEmpty(gamesList)) {
      return null;
    }

    Set<String> preferredSports = Auth2().prefs?.sportsInterests;

    // Step 1: Group games by sport
    Map<String, List<Game>> gamesMap = Map<String, List<Game>>();
    List<Game> preferredGames = [];
    for (Game game in gamesList) {
      if (!gamesMap.containsKey(game.sport.shortName)) {
        gamesMap[game.sport.shortName] = [];
      }
      gamesMap[game.sport.shortName].add(game);
    }

    // Step 2: Add all preferred games
    if (preferredSports != null && preferredSports.isNotEmpty) {
      for (String preferredSport in preferredSports) {
        List<Game> subList = gamesMap[preferredSport];
        if (subList != null) {
          preferredGames.addAll(subList);
        }
      }
    }

    // Step 3: In case of multiple preferences - show only the top upcoming game per sport
    Set<String> limitedSports = Set<String>();
    if (preferredGames.isNotEmpty) {
      preferredGames.sort((game1, game2) => game1.dateTimeUtc.compareTo(game2.dateTimeUtc));
      List<Game> limitedGames = [];
      for (Game game in preferredGames) {
        if (!limitedSports.contains(game.sport.shortName)) {
          limitedGames.add(game);
          limitedSports.add(game.sport.shortName);
        } else if (preferredSports.length == 1 && limitedGames.length < 3) {
          // In case of single preference - show 3 games
          limitedGames.add(game);
        }
      }
      preferredGames = limitedGames;
    } else {
      // Step 3.1: Show first 3 games (top one per sport)
      for (Game game in gamesList) {
        if (preferredGames.length >= 3) {
          break;
        }

        if (!limitedSports.contains(game.sport.shortName)) {
          preferredGames.add(game);
          limitedSports.add(game.sport.shortName);
        }
      }
    }

    return preferredGames;
  }

  Future<Game> loadGame(String sportKey, String gameId) async {
    if (AppString.isStringEmpty(gameId)) {
      Log.d('Missing game id to load.');
      return null;
    }
    List<Game> games = await loadGames(id: gameId, sports: [sportKey]);
    return games?.first;
  }

  Future<List<Game>> loadGames({String id, List<String> sports, DateTime startDate, DateTime endDate, int limit}) async {
    if (AppString.isStringEmpty(Config().sportsServiceUrl)) {
      return null;
    }

    String queryParams = '';

    if (AppString.isStringNotEmpty(id)) {
      queryParams += '?id=$id';
    } else if (startDate == null) {
      startDate = AppDateTime().now;
    }

    if (startDate != null) {
      startDate = startDate.toUtc();
      String startDateFormatted = AppDateTime().formatDateTime(startDate, format: AppDateTime.scheduleServerQueryDateTimeFormat, ignoreTimeZone: true);
      queryParams += '&start=$startDateFormatted';
    }

    if (endDate != null) {
      endDate = endDate.toUtc();
      String endDateFormatted = AppDateTime().formatDateTime(endDate, format: AppDateTime.scheduleServerQueryDateTimeFormat, ignoreTimeZone: true);
      queryParams += '&end=$endDateFormatted';
    }

    if (AppCollection.isCollectionNotEmpty(sports)) {
      for (String sport in sports) {
        if (AppString.isStringNotEmpty(sport)) {
          queryParams += '&sport=$sport';
        }
      }
    }
    if ((limit != null) && (limit > 0)) {
      queryParams += '&limit=$limit';
    }
    String gamesUrl = '${Config().sportsServiceUrl}/api/v2/games';

    if (AppString.isStringNotEmpty(queryParams)) {
      if (queryParams.startsWith('&')) {
        queryParams = queryParams.replaceFirst('&', '?');
      }
      gamesUrl += queryParams;
    }

    final response = await Network().get(gamesUrl, auth: NetworkAuth.Auth2);
    int responseCode = response?.statusCode ?? -1;
    String responseBody = response?.body;

    if (responseCode == 200) {
      List<dynamic> jsonData = AppJson.decode(responseBody);
      if (AppCollection.isCollectionNotEmpty(jsonData)) {
        List<Game> gamesList = [];
        for (dynamic entry in jsonData) {
          Game game = Game.fromJson(entry);
          if (game != null) {
            gamesList.add(game);
          }
        }
        return gamesList;
      }
    } else {
      Log.e('Failed to load games. Reason: $responseBody');
    }
    return null;
  }

  Future<News> loadNewsArticle(String id) async {
    if (AppString.isStringNotEmpty(Config().sportsServiceUrl) && AppString.isStringNotEmpty(id)) {
      String newsUrl = Config().sportsServiceUrl + '/api/v2/news?id=$id';
      final response = await Network().get(newsUrl, auth: NetworkAuth.Auth2);
      String responseBody = response?.body;
      if (response?.statusCode == 200) {
        List<dynamic> jsonData = AppJson.decode(responseBody);
        if (AppCollection.isCollectionNotEmpty(jsonData)) {
          return News.fromJson(jsonData.first);
        }
      } else {
        Log.e('Failed to load news');
        Log.e(responseBody);
      }
    }
    return null;
  }

  Future<List<News>> loadNews(String sportKey, int count) async {
    if (Config().sportsServiceUrl != null) {
      String newsUrl = Config().sportsServiceUrl + '/api/v2/news';
      bool hasSportParam = AppString.isStringNotEmpty(sportKey);
      if (hasSportParam) {
        newsUrl += '?sport=$sportKey';
      }
      if ((count != null) && (count > 0)) {
        if (hasSportParam) {
          newsUrl += '&';
        } else {
          newsUrl += '?';
        }
        newsUrl += 'limit=$count';
      }

      final response = await Network().get(newsUrl, auth: NetworkAuth.Auth2);
      String responseBody = response?.body;
      if ((response != null) && (response.statusCode == 200)) {
        List<dynamic> jsonData = AppJson.decode(responseBody);
        if (AppCollection.isCollectionNotEmpty(jsonData)) {
          List<News> newsList = [];
          for (Map<String, dynamic> jsonEntry in jsonData) {
            News news = News.fromJson(jsonEntry);
            if (news != null) {
              newsList.add(news);
            }
          }
          return newsList;
        }
      } else {
        Log.e('Failed to load news');
        Log.e(responseBody);
      }
    }
    return null;
  }

  ///Game Helpers

  Game getFirstUpcomingGame(List<Game> games) {
    if (AppCollection.isCollectionNotEmpty(games)) {
      return games.first;
    } else {
      return null;
    }
  }

  List<Game> getTodayGames(List<Game> games) {
    if (AppCollection.isCollectionEmpty(games)) {
      return null;
    }
    List<Game> todayGames = [];
    for (Game game in games) {
      if (game.isGameDay) {
        todayGames.add(game);
      }
    }
    if (AppCollection.isCollectionEmpty(todayGames)) {
      return null;
    }
    _sortTodayGames(todayGames);
    return todayGames;
  }

  void _sortTodayGames(List<Game> todayGames) {
    if (AppCollection.isCollectionEmpty(todayGames)) {
      return;
    }
    final List<String> gameDaySortOrder = [
      'football',
      'mbball',
      'wvball',
      'wbball'
    ];
    final int missingIndexValue = -1;
    final int defaultSortIndex = 100;
    todayGames.sort((game1, game2) {
      String gameShortName1 = game1.sport?.shortName;
      int gameIndex1 = gameDaySortOrder.indexOf(gameShortName1);
      if (gameIndex1 == missingIndexValue) {
        gameIndex1 = defaultSortIndex;
      }
      String gameShortName2 = game2.sport?.shortName;
      int gameIndex2 = gameDaySortOrder.indexOf(gameShortName2);
      if (gameIndex2 == missingIndexValue) {
        gameIndex2 = defaultSortIndex;
      }
      return gameIndex1.compareTo(gameIndex2);
    });
  }

  ///Assert that games are sorted by start date
  bool hasTodayGame(List<Game> games) {
    Game upcomingGame = getFirstUpcomingGame(games);
    return upcomingGame?.isGameDay ?? false;
  }

  bool showWelcome(List<Game> games) {
    return !hasTodayGame(games);
  }

  //Preferred Sports helpers

  ///
  /// addSports == 'true' - adds all sports to favorites, 'false' - removes them
  ///
  static Set<String> switchAllSports(List<SportDefinition> allSports, Set<String> preferredSports, bool addSports) {
    Set<String> sportsToUpdate = Set<String>();
    if (allSports != null && allSports.isNotEmpty) {
      for (SportDefinition sport in allSports) {
        String sportShortName = sport.shortName;
        bool preferredSport = (preferredSports?.contains(sportShortName) ?? false);
        bool addFavoriteSport = !preferredSport && addSports;
        bool removeFavoriteSport = preferredSport && !addSports;
        if (addFavoriteSport || removeFavoriteSport) {
          sportsToUpdate.add(sportShortName);
        }
      }
    }
    return sportsToUpdate;
  }

  static bool isAllSportsSelected(List<SportDefinition> allSports, Set<String> preferredSports) {
    if (allSports == null || allSports.isEmpty) {
      return false;
    }
    if (preferredSports == null || preferredSports.isEmpty) {
      return false;
    }
    bool allSportsSelected = true;
    for (SportDefinition sport in allSports) {
      if (!preferredSports.contains(sport.shortName)) {
        allSportsSelected = false;
        break;
      }
    }
    return allSportsSelected;
  }

  /////////////////////////
  // DeepLinks

  void _onDeepLinkUri(Uri uri) {
    if (uri != null) {
      Uri gameUri = Uri.tryParse(GAME_URI);
      if ((gameUri != null) &&
          (gameUri.scheme == uri.scheme) &&
          (gameUri.authority == uri.authority) &&
          (gameUri.path == uri.path))
      {
        try { _handleGameDetail(uri.queryParameters?.cast<String, dynamic>()); }
        catch (e) { print(e?.toString()); }
      }
    }
  }

  void _handleGameDetail(Map<String, dynamic> params) {
    if ((params != null) && params.isNotEmpty) {
      if (_gameDetailsCache != null) {
        _cacheGameDetail(params);
      }
      else {
        _processGameDetail(params);
      }
    }
  }

  void _processGameDetail(Map<String, dynamic> params) {
    NotificationService().notify(notifyGameDetail, params);
  }

  void _cacheGameDetail(Map<String, dynamic> params) {
    _gameDetailsCache?.add(params);
  }

  void _processCachedGameDetails() {
    if (_gameDetailsCache != null) {
      List<Map<String, dynamic>> gameDetailsCache = _gameDetailsCache;
      _gameDetailsCache = null;

      for (Map<String, dynamic> gameDetail in gameDetailsCache) {
        _processGameDetail(gameDetail);
      }
    }
  }
}
