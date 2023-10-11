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
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/model/sport/Team.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/model/News.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';

import 'package:illinois/model/sport/Coach.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/model/sport/Roster.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'package:rokwire_plugin/service/network.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class Sports with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.sports.changed";
  static const String notifySocialMediasChanged  = "edu.illinois.rokwire.sports.social.medias.changed";
  static const String notifyGameDetail = "edu.illinois.rokwire.sports.game.detail";

  static const String _sportsCacheFileName = "sports.json";
  static const String _sportsSocialMediaCacheFileName = "sportsSocialMedia.json";

  static final Sports _logic = Sports._internal();

  List<SportDefinition>? _sports;
  List<SportDefinition>? _menSports;
  List<SportDefinition>? _womenSports;
  List<SportSocialMedia>? _socialMedias;
  List<Map<String, dynamic>>? _gameDetailsCache;
  int? _lastCheckSportsTime, _lastCheckSocialMediasTime;

  // Singletone Factory

  factory Sports() {
    return _logic;
  }

  Sports._internal();

  // Service

  @override
  void createService() {
    super.createService();
    NotificationService().subscribe(this,[
      DeepLink.notifyUri,
      AppLivecycle.notifyStateChanged,
    ]);
    _gameDetailsCache = <Map<String, dynamic>>[];
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Future<void> initService() async {

    await Future.wait([
      _initSports(),
      _initSportSocialMedia(),
    ]);

    if ((_sports != null) && (_socialMedias != null)) {
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'Sports Initialization Failed',
        description: 'Failed to initialize Sports content.',
      );
    }
  }

  @override
  void initServiceUI() {
    _processCachedGameDetails();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config(), Auth2()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(param);
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.resumed) {
      _updateSportsFromNet();
      _updateSportSocialMediaFromNet();
    }
  }

  // Accessories

  List<SportDefinition>? get sports {
    return _sports;
  }

  List<SportDefinition>? get menSports {
    return _menSports;
  }

  List<SportDefinition>? get womenSports {
    return _womenSports;
  }

  // Utils

  static Future<File?> _getCacheFile(String fileName) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String cacheFilePath = join(appDocDir.path, fileName);
      return File(cacheFilePath);
    }
    catch(e) { print(e.toString()); }
    return null;
  }

  static Future<String?> _loadContentStringFromCache(String fileName) async {
    try {
      File? cacheFile = await _getCacheFile(fileName);
      return (await cacheFile?.exists() == true) ? await cacheFile?.readAsString() : null;
    }
    catch(e) { print(e.toString()); }
    return null;
  }

  static Future<void> _saveContentStringToCache(String fileName, String? value) async {
    try {
      File? cacheFile = await _getCacheFile(fileName);
      if (value != null) {
        await cacheFile?.writeAsString(value, flush: true);
      }
      else {
        await cacheFile?.delete();
      }
    }
    catch(e) { print(e.toString()); }
  }

  static Future<String?> _loadContentStringFromNet(String url) async {
    try {
      Response? response = await Network().get(url, auth: Auth2());
      return ((response != null) && (response.statusCode == 200)) ? response.body : null;
    }
    catch (e) { print(e.toString()); }
    return null;
  }

  // Sports

  Future<void> _initSports() async {
    List<SportDefinition>? sports = await _loadSportsFromCache();
    if (sports != null) {
      _applySports(sports);
      _updateSportsFromNet();
    }
    else {
      await _applySportsFromNet();
    }
  }

  static Future<List<SportDefinition>?> _loadSportsFromCache() async {
    return SportDefinition.listFromJson(JsonUtils.decodeList(await _loadContentStringFromCache(_sportsCacheFileName)));
  }

  void _applySports(List<SportDefinition>? sports) {
    _sports = sports;
    _menSports = SportDefinition.subList(_sports, gender: 'men');
    _womenSports = SportDefinition.subList(_sports, gender: 'women');
    _sortSports();
  }

  Future<bool> _applySportsFromNet() async {
    String? serviceUrl = Config().sportsServiceUrl;
    if (StringUtils.isNotEmpty(serviceUrl)) {
      String? contentString = await _loadContentStringFromNet("$serviceUrl/api/v2/sports");
      List<SportDefinition>? sports = SportDefinition.listFromJson(JsonUtils.decodeList(contentString));
      if (sports != null) {
        _lastCheckSportsTime = DateTime.now().millisecondsSinceEpoch;
        if (!DeepCollectionEquality().equals(_sports, sports)) {
          _applySports(sports);
          await _saveContentStringToCache(_sportsCacheFileName, contentString);
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _updateSportsFromNet() async {
    // Update once daily
    DateTime today = DateTimeUtils.midnight(DateTime.now())!;
    DateTime lastCheck = DateTimeUtils.midnight(DateTime.fromMillisecondsSinceEpoch(_lastCheckSportsTime ?? 0))!;
    if (lastCheck.compareTo(today) < 0) {
      if (await _applySportsFromNet()) {
        NotificationService().notify(notifyChanged, null);
      }
    }
  }

  void _sortSports() {
    if (CollectionUtils.isNotEmpty(_menSports)) {
      SportDefinition? firstExplicitItem;
      try {
        firstExplicitItem = (_menSports as List<SportDefinition?>).firstWhere((SportDefinition? sportType) {
          return sportType?.customName?.toLowerCase() == "football";
        }, orElse: () => null);
      }
      catch(e) {}

      SportDefinition? secondExplicitItem;
      try {
        secondExplicitItem = (_menSports as List<SportDefinition?>).firstWhere((SportDefinition? sportType) {
          return sportType?.customName?.toLowerCase() == "basketball";
        }, orElse: () => null);
      }
      catch(e) {}

      //sort
      _menSports!.sort(_compareDefinitions);

      //Explicitly ordered items
      if (firstExplicitItem != null) {
        _menSports!.remove(firstExplicitItem);
        _menSports!.insert(0, firstExplicitItem);
      }

      if (secondExplicitItem != null) {
        _menSports!.remove(secondExplicitItem);
        _menSports!.insert(1, secondExplicitItem);
      }
    }

    if (CollectionUtils.isNotEmpty(_womenSports)) {
      SportDefinition? firstExplicitItem;
      try {
        firstExplicitItem = (_womenSports as List<SportDefinition?>).firstWhere((SportDefinition? sportType) {
          return sportType?.customName?.toLowerCase() == "volleyball";
        }, orElse: () => null);
      }
      catch(e) {}

      SportDefinition? secondExplicitItem;
      try {
        secondExplicitItem = (_womenSports as List<SportDefinition?>).firstWhere((SportDefinition? sportType) {
          return sportType?.customName?.toLowerCase() == "basketball";
        }, orElse: () => null);
      }
      catch(e) {}

      //sort
      _womenSports!.sort(_compareDefinitions);

      //Explicitly ordered items
      if (firstExplicitItem != null) {
        _womenSports!.remove(firstExplicitItem);
        _womenSports!.insert(0, firstExplicitItem);
      }

      if (secondExplicitItem != null) {
        _womenSports!.remove(secondExplicitItem);
        _womenSports!.insert(1, secondExplicitItem);
      }
    }
  }

  int _compareDefinitions(SportDefinition first, SportDefinition second) {
        if (first.customName != null) {
          return (second.customName != null) ? first.customName!.compareTo(second.customName!) : 1;
        }
        else {
          return  (second.customName != null) ? -1 : 0;
        }
  }

  // Sport Social Media

  Future<void> _initSportSocialMedia() async {
    List<SportSocialMedia>? socialMedias = await _loadSportSocialMediaFromCache();
    if (socialMedias != null) {
      _socialMedias = socialMedias;
      _updateSportSocialMediaFromNet();
    }
    else {
      await _applySportSocialMediaFromNet();
    }
  }

  static Future<List<SportSocialMedia>?> _loadSportSocialMediaFromCache() async {
    return SportSocialMedia.listFromJson(JsonUtils.decodeList(await _loadContentStringFromCache(_sportsSocialMediaCacheFileName)));
  }

  Future<bool> _applySportSocialMediaFromNet() async {
    String? serviceUrl = Config().sportsServiceUrl;
    if (StringUtils.isNotEmpty(serviceUrl)) {
      String? contentString = await _loadContentStringFromNet("$serviceUrl/api/v2/social");
      List<SportSocialMedia>? socialMedias = SportSocialMedia.listFromJson(JsonUtils.decodeList(contentString));
      if (socialMedias != null) {
        _lastCheckSocialMediasTime = DateTime.now().millisecondsSinceEpoch;
        if (!DeepCollectionEquality().equals(_socialMedias, socialMedias)) {
          _socialMedias = socialMedias;
          await _saveContentStringToCache(_sportsSocialMediaCacheFileName, contentString);
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _updateSportSocialMediaFromNet() async {
    // Update once daily
    DateTime today = DateTimeUtils.midnight(DateTime.now())!;
    DateTime lastCheck = DateTimeUtils.midnight(DateTime.fromMillisecondsSinceEpoch(_lastCheckSocialMediasTime ?? 0))!;
    if (lastCheck.compareTo(today) < 0) {
      if (await _applySportSocialMediaFromNet()) {
        NotificationService().notify(notifyChanged, null);
      }
    }
  }

  // Getters

  SportDefinition? getSportByShortName(String? sportShortName) {
    if (CollectionUtils.isNotEmpty(_sports) && StringUtils.isNotEmpty(sportShortName)) {
      for (SportDefinition sport in _sports!) {
        if (sportShortName == sport.shortName) {
          return sport;
        }
      }
    }
    return null;
  }


  SportSocialMedia? getSocialMediaForSport(String? shortName) {
    if (StringUtils.isNotEmpty(shortName) && CollectionUtils.isNotEmpty(_socialMedias)) {
      try {
        return (_socialMedias as List<SportSocialMedia?>).firstWhere((socialMedia) => shortName == socialMedia?.shortName, orElse: () => null);
      }
      catch(e){}
    }
    return null;
  }

  static String? getGameDayGuideUrl(String? sportKey) {
    if (sportKey == "football") {
      return Config().gameDayFootballUrl;
    } else if (sportKey == "mbball") {
      return Config().gameDayBasketballUrl;
    } else {
      return null;
    }
  }

  // APIs

  Future<List<Roster>?> loadRosters(String? sportKey) async {
    if (StringUtils.isNotEmpty(Config().sportsServiceUrl) && StringUtils.isNotEmpty(sportKey)) {
      final rostersUrl = "${Config().sportsServiceUrl}/api/v2/players?sport=$sportKey";
      final response = await Network().get(rostersUrl, auth: Auth2());
      String? responseBody = response?.body;
      int responseCode = response?.statusCode ?? -1;
      if (responseCode == 200) {
        List<dynamic>? jsonData = JsonUtils.decode(responseBody);
        if (CollectionUtils.isNotEmpty(jsonData)) {
          List<Roster> rosters = <Roster>[];
          for (dynamic jsonEntry in jsonData!) {
            Roster? roster = Roster.fromJson(JsonUtils.mapValue(jsonEntry));
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

  Future<List<Coach>?> loadCoaches(String? sportKey) async {
    if (StringUtils.isNotEmpty(Config().sportsServiceUrl) && StringUtils.isNotEmpty(sportKey)) {
      final coachesUrl = "${Config().sportsServiceUrl}/api/v2/coaches?sport=$sportKey";
      final response = await Network().get(coachesUrl, auth: Auth2());
      String? responseBody = response?.body;
      int? responseCode = response?.statusCode;
      if (responseCode == 200) {
        List<dynamic>? jsonList = JsonUtils.decode(responseBody);
        if (CollectionUtils.isNotEmpty(jsonList)) {
          List<Coach> coaches = <Coach>[];
          for (dynamic jsonEntry in jsonList!) {
            Coach? coach = Coach.fromJson(JsonUtils.mapValue(jsonEntry));
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

  Future<TeamSchedule?> loadScheduleForCurrentSeason(String? sportKey) async {
    if (StringUtils.isEmpty(Config().sportsServiceUrl) || StringUtils.isEmpty(sportKey)) {
      return null;
    }
    String scheduleUrl = '${Config().sportsServiceUrl}/api/v2/team-schedule?sport=$sportKey';
    final response = await Network().get(scheduleUrl, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? jsonData = JsonUtils.decode(responseBody);
      TeamSchedule? schedule = TeamSchedule.fromJson(jsonData);
      return schedule;
    } else {
      Log.e('Failed to load schedule for $sportKey. Reason: $responseBody');
      return null;
    }
  }

  Future<TeamRecord?> loadRecordForCurrentSeason(String? sportKey) async {
    if (StringUtils.isEmpty(Config().sportsServiceUrl) && StringUtils.isEmpty(sportKey)) {
      return null;
    }
    String scheduleUrl = '${Config().sportsServiceUrl}/api/v2/team-record?sport=$sportKey';
    final response = await Network().get(scheduleUrl, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? jsonData = JsonUtils.decode(responseBody);
      TeamRecord? record = TeamRecord.fromJson(jsonData);
      return record;
    } else {
      Log.e('Failed to load record for $sportKey. Reason: $responseBody');
      return null;
    }
  }

  Future<List<Game>?> loadTopScheduleGames() async {
    List<Game>? gamesList = await loadGames();
    return getTopScheduleGamesFromList(gamesList);
  }

  List<Game>? getTopScheduleGamesFromList(List<Game>? gamesList) {
    if (CollectionUtils.isEmpty(gamesList)) {
      return null;
    }

    Set<String>? preferredSports = Auth2().prefs?.sportsInterests;

    // Step 1: Group games by sport
    Map<String, List<Game>> gamesMap = Map<String, List<Game>>();
    List<Game> preferredGames = <Game>[];
    for (Game game in gamesList!) {
      if (game.sport?.shortName != null) {
        if (!gamesMap.containsKey(game.sport!.shortName)) {
          gamesMap[game.sport!.shortName!] = <Game>[];
        }
        gamesMap[game.sport!.shortName]?.add(game);
      }
    }

    // Step 2: Add all preferred games
    if (preferredSports != null && preferredSports.isNotEmpty) {
      for (String? preferredSport in preferredSports) {
        List<Game>? subList = gamesMap[preferredSport];
        if (subList != null) {
          preferredGames.addAll(subList);
        }
      }
    }

    // Step 3: In case of multiple preferences - show only the top upcoming game per sport
    Set<String> limitedSports = Set<String>();
    if (preferredGames.isNotEmpty) {
      preferredGames.sort((game1, game2) => game1.dateTimeUtc!.compareTo(game2.dateTimeUtc!));
      List<Game> limitedGames = <Game>[];
      for (Game game in preferredGames) {
        if (!limitedSports.contains(game.sport?.shortName)) {
          limitedGames.add(game);
          if (game.sport?.shortName != null) {
            limitedSports.add(game.sport!.shortName!);
          }
        } else if (preferredSports!.length == 1 && limitedGames.length < 3) {
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

        if (!limitedSports.contains(game.sport?.shortName)) {
          preferredGames.add(game);
          if (game.sport?.shortName != null) {
            limitedSports.add(game.sport!.shortName!);
          }
        }
      }
    }

    return preferredGames;
  }

  Future<Game?> loadGame(String? sportKey, String? gameId) async {
    if (StringUtils.isEmpty(gameId)) {
      Log.d('Missing game id to load.');
      return null;
    }
    final DateTime startDate = DateTime(2010, 1, 1); // Explicitly set old start date because Sports BB automatically sets start date = now and ignores old events
    List<Game>? games = await loadGames(id: gameId, sports: [sportKey], startDate: startDate);
    return games?.first;
  }

  Future<List<Game>?> loadGames({String? id, List<String?>? sports, DateTime? startDate, DateTime? endDate, int? limit}) async {
    if (StringUtils.isEmpty(Config().sportsServiceUrl)) {
      return null;
    }

    String queryParams = '';

    if (StringUtils.isNotEmpty(id)) {
      queryParams += '?id=$id';
    } else if (startDate == null) {
      startDate = AppDateTime().now;
    }

    if (startDate != null) {
      String? startDateFormatted = AppDateTime().formatDateTime(startDate, format: 'MM/dd/yyyy', ignoreTimeZone: true);
      queryParams += '&start=$startDateFormatted';
    }

    if (endDate != null) {
      String? endDateFormatted = AppDateTime().formatDateTime(endDate, format: 'MM/dd/yyyy', ignoreTimeZone: true);
      queryParams += '&end=$endDateFormatted';
    }

    if (CollectionUtils.isNotEmpty(sports)) {
      for (String? sport in sports!) {
        if (StringUtils.isNotEmpty(sport)) {
          queryParams += '&sport=$sport';
        }
      }
    }
    if ((limit != null) && (limit > 0)) {
      queryParams += '&limit=$limit';
    }
    String gamesUrl = '${Config().sportsServiceUrl}/api/v2/games';

    if (StringUtils.isNotEmpty(queryParams)) {
      if (queryParams.startsWith('&')) {
        queryParams = queryParams.replaceFirst('&', '?');
      }
      gamesUrl += queryParams;
    }

    final response = await Network().get(gamesUrl, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseBody = response?.body;

    if (responseCode == 200) {
      List<dynamic>? jsonData = JsonUtils.decode(responseBody);
      if (CollectionUtils.isNotEmpty(jsonData)) {
        List<Game> gamesList = <Game>[];
        for (dynamic entry in jsonData!) {
          Game? game = Game.fromJson(entry);
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

  Future<News?> loadNewsArticle(String? id) async {
    if (StringUtils.isNotEmpty(Config().sportsServiceUrl) && StringUtils.isNotEmpty(id)) {
      String newsUrl = Config().sportsServiceUrl! + '/api/v2/news?id=$id';
      final response = await Network().get(newsUrl, auth: Auth2());
      String? responseBody = response?.body;
      if (response?.statusCode == 200) {
        List<dynamic>? jsonData = JsonUtils.decode(responseBody);
        if (CollectionUtils.isNotEmpty(jsonData)) {
          return News.fromJson(jsonData!.first);
        }
      } else {
        Log.e('Failed to load news');
        Log.e(responseBody);
      }
    }
    return null;
  }

  Future<List<News>?> loadNews(String? sportKey, int? count) async {
    if (Config().sportsServiceUrl != null) {
      String newsUrl = Config().sportsServiceUrl! + '/api/v2/news';
      bool hasSportParam = StringUtils.isNotEmpty(sportKey);
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

      final response = await Network().get(newsUrl, auth: Auth2());
      String? responseBody = response?.body;
      if ((response != null) && (response.statusCode == 200)) {
        List<dynamic>? jsonData = JsonUtils.decode(responseBody);
        if (CollectionUtils.isNotEmpty(jsonData)) {
          List<News> newsList = <News>[];
          for (dynamic jsonEntry in jsonData!) {
            News? news = News.fromJson(JsonUtils.mapValue(jsonEntry));
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

  Game? getFirstUpcomingGame(List<Game> games) {
    if (CollectionUtils.isNotEmpty(games)) {
      return games.first;
    } else {
      return null;
    }
  }

  List<Game>? getTodayGames(List<Game>? games) {
    //TMP: return (games != null) ? List.from(games) : null;
    if (CollectionUtils.isEmpty(games)) {
      return null;
    }
    List<Game> todayGames = <Game>[];
    for (Game game in games!) {
      if (game.isGameDay) {
        todayGames.add(game);
      }
    }
    if (CollectionUtils.isEmpty(todayGames)) {
      return null;
    }
    _sortTodayGames(todayGames);
    return todayGames;
  }

  void _sortTodayGames(List<Game> todayGames) {
    if (CollectionUtils.isEmpty(todayGames)) {
      return;
    }
    final List<String?> gameDaySortOrder = [
      'football',
      'mbball',
      'wvball',
      'wbball'
    ];
    final int missingIndexValue = -1;
    final int defaultSortIndex = 100;
    todayGames.sort((game1, game2) {
      String? gameShortName1 = game1.sport?.shortName;
      int gameIndex1 = gameDaySortOrder.indexOf(gameShortName1);
      if (gameIndex1 == missingIndexValue) {
        gameIndex1 = defaultSortIndex;
      }
      String? gameShortName2 = game2.sport?.shortName;
      int gameIndex2 = gameDaySortOrder.indexOf(gameShortName2);
      if (gameIndex2 == missingIndexValue) {
        gameIndex2 = defaultSortIndex;
      }
      return gameIndex1.compareTo(gameIndex2);
    });
  }

  ///Assert that games are sorted by start date
  bool hasTodayGame(List<Game> games) {
    Game? upcomingGame = getFirstUpcomingGame(games);
    return upcomingGame?.isGameDay ?? false;
  }

  bool showWelcome(List<Game> games) {
    return !hasTodayGame(games);
  }

  //Preferred Sports helpers

  ///
  /// addSports == 'true' - adds all sports to favorites, 'false' - removes them
  ///
  static Set<String> switchAllSports(List<SportDefinition>? allSports, Set<String>? preferredSports, bool addSports) {
    Set<String> sportsToUpdate = Set<String>();
    if (allSports != null && allSports.isNotEmpty) {
      for (SportDefinition sport in allSports) {
        String? sportShortName = sport.shortName;
        if (sportShortName != null) {
          bool preferredSport = (preferredSports?.contains(sportShortName) ?? false);
          bool addFavoriteSport = !preferredSport && addSports;
          bool removeFavoriteSport = preferredSport && !addSports;
          if (addFavoriteSport || removeFavoriteSport) {
            sportsToUpdate.add(sportShortName);
          }
        }
      }
    }
    return sportsToUpdate;
  }

  static bool isAllSportsSelected(List<SportDefinition>? allSports, Set<String>? preferredSports) {
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

  String get gameDetailUrl => '${DeepLink().appUrl}/game_detail';

  void _onDeepLinkUri(Uri? uri) {
    if (uri != null) {
      Uri? gameUri = Uri.tryParse(gameDetailUrl);
      if ((gameUri != null) &&
          (gameUri.scheme == uri.scheme) &&
          (gameUri.authority == uri.authority) &&
          (gameUri.path == uri.path))
      {
        try { _handleGameDetail(uri.queryParameters.cast<String, dynamic>()); }
        catch (e) { print(e.toString()); }
      }
    }
  }

  void _handleGameDetail(Map<String, dynamic>? params) {
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
      List<Map<String, dynamic>> gameDetailsCache = _gameDetailsCache!;
      _gameDetailsCache = null;

      for (Map<String, dynamic> gameDetail in gameDetailsCache) {
        _processGameDetail(gameDetail);
      }
    }
  }
}
