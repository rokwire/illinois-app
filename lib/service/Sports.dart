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
import 'package:illinois/service/Assets.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/service/Config.dart';

import 'package:illinois/model/Coach.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/model/Roster.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/Utils.dart';

import 'package:illinois/service/Network.dart';

class Sports with Service {

  static const String notifyChanged  = "edu.illinois.rokwire.sports.changed";
  static const String notifySocialMediasChanged  = "edu.illinois.rokwire.sports.social.medias.changed";

  static final Sports _logic = Sports._internal();

  List<SportDefinition> _sports;
  List<SportDefinition> _menSports;
  List<SportDefinition> _womenSports;
  List<SportSocialMedia> _socialMedias;


  factory Sports() {
    return _logic;
  }

  Sports._internal();

  @override
  Future<void> initService() async {
    if(_enabled) {
      await _loadSportDefinitions();
      await _loadSportSocialMedias();
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Config(), Assets(),]);
  }

  List<SportDefinition> getSports() {
    return _enabled ? _sports : null;
  }

  List<SportDefinition> getMenSports() {
    return _enabled ? _menSports : null;
  }

  List<SportDefinition> getWomenSports() {
    return _enabled ? _womenSports : null;
  }

  SportSocialMedia getSocialMediaForSport(String shortName) {
    if (_enabled) {
      if (AppString.isStringNotEmpty(shortName) && AppCollection.isCollectionNotEmpty(_socialMedias)) {
        return _socialMedias.firstWhere((socialMedia) => shortName == socialMedia.shortName);
      }
    }
    return null;
  }

  Future<void> _loadSportDefinitions() async {
    String serviceUrl = Config().sportsServiceUrl;
    if (AppString.isStringEmpty(serviceUrl)) {
      return;
    }
    String sportsUrl = serviceUrl + '/api/v2/sports';
    Response response = await Network().get(sportsUrl, auth: NetworkAuth.App);
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
      Log.e('Failed to load sport definitions');
      Log.e(responseBody);
    }
    _sortSports();
    NotificationService().notify(notifyChanged, null);
  }

  void _sortSports(){
    if(AppCollection.isCollectionNotEmpty(_menSports)){
      SportDefinition firstExplicitItem = _menSports.firstWhere((SportDefinition sportType){
        return sportType.customName?.toLowerCase() == "football";
      });
      SportDefinition secondExplicitItem = _menSports.firstWhere((SportDefinition sportType){
        return sportType.customName?.toLowerCase() == "basketball";
      });
      //sort
      _menSports.sort((SportDefinition first, SportDefinition second){
        return first?.customName?.compareTo(second?.customName);
      });
      //Explicitly ordered items
      if(firstExplicitItem!=null){
        _menSports.remove(firstExplicitItem);
        _menSports.insert(0,firstExplicitItem);
      }
      if(secondExplicitItem!=null){
        _menSports.remove(secondExplicitItem);
        _menSports.insert(1,secondExplicitItem);
      }
    }
    if(AppCollection.isCollectionNotEmpty(_womenSports)){
      SportDefinition firstExplicitItem = _womenSports.firstWhere((SportDefinition sportType){
        return sportType.customName?.toLowerCase() == "volleyball";
      });
      SportDefinition secondExplicitItem = _womenSports.firstWhere((SportDefinition sportType){
        return sportType.customName?.toLowerCase() == "basketball";
      });
      //sort
      _womenSports.sort((SportDefinition first, SportDefinition second){
        return first?.customName?.compareTo(second?.customName);
      });
      //Explicitly ordered items
      if(firstExplicitItem!=null){
        _womenSports.remove(firstExplicitItem);
        _womenSports.insert(0,firstExplicitItem);
      }
      if(secondExplicitItem!=null){
        _womenSports.remove(secondExplicitItem);
        _womenSports.insert(1,secondExplicitItem);
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
    Response response = await Network().get(socialUrl, auth: NetworkAuth.App);
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
    if(_enabled) {
      if (_sports == null || AppString.isStringEmpty(sportShortName)) {
        return null;
      }
      for (SportDefinition sport in _sports) {
        if (sportShortName == sport.shortName) {
          return sport;
        }
      }
    }
    return null;
  }

  Future<List<Roster>> loadRosters(String sportKey) async {
    if (_enabled && AppString.isStringNotEmpty(Config().sportsServiceUrl) && AppString.isStringNotEmpty(sportKey)) {
      final rostersUrl = "${Config().sportsServiceUrl}/api/v2/players?sport=$sportKey";
      final response = await Network().get(rostersUrl, auth: NetworkAuth.App);
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
    if (_enabled && AppString.isStringNotEmpty(Config().sportsServiceUrl) && AppString.isStringNotEmpty(sportKey)) {
      final coachesUrl = "${Config().sportsServiceUrl}/api/v2/coaches?sport=$sportKey";
      final response = await Network().get(coachesUrl, auth: NetworkAuth.App);
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

  ///returns Map<String, Schedule> where the key is the season name and the value is the Schedule itself
  Future<Map<String, TeamSchedule>> loadScheduleForCurrentSeason(String sportKey) async {
    if(_enabled) {
      if (AppString.isStringEmpty(sportKey)) {
        return null;
      }
      String baseScheduleUrl = await getCurrentSportSeasonScheduleUrl(sportKey);
      if (AppString.isStringEmpty(baseScheduleUrl)) {
        return null;
      }
      final String yearLabel = 'year=';
      int startIndex = baseScheduleUrl.indexOf(yearLabel) + yearLabel.length;
      String scheduleYear = baseScheduleUrl.substring(startIndex, baseScheduleUrl.length);
      final scheduleUrl = "$baseScheduleUrl&format=json";
      final response = await Network().get(scheduleUrl);
      String responseBody = response?.body;
      if ((response != null) && (response.statusCode == 200)) {
        Map<String, dynamic> jsonData = AppJson.decode(responseBody);
        TeamSchedule schedule = TeamSchedule.fromJson(jsonData);
        return {scheduleYear: schedule};
      } else {
        Log.e('Failed to load schedule for $sportKey');
        Log.e(responseBody);
        return null;
      }
    }
    return null;
  }

  Future<List<Game>> loadTopScheduleGames() async {
    if(_enabled) {
      List<Game> gamesList = await loadAllScheduleGames();
      return getTopScheduleGamesFromList(gamesList);
    }
    return null;
  }

  List<Game> getTopScheduleGamesFromList(List<Game> gamesList){
    if(_enabled) {
      List<String> preferredSports = User().getSportsInterestSubCategories();

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
          }
          else if (preferredSports.length == 1 && limitedGames.length < 3) {
            // In case of single preference - show 3 games
            limitedGames.add(game);
          }
        }
        preferredGames = limitedGames;
      }
      else {
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
    return null;
  }

  Future<Game> loadGame(String sportKey, String gameId) async {
    Game game;
    if(_enabled) {
      final url = (Config().sportScheduleUrl != null) ? "${Config().sportScheduleUrl}?path=$sportKey&format=json&game_id=$gameId" : null;
      final response = await Network().get(url);
      String responseBody = response?.body;
      if ((response != null) && (response.statusCode == 200)) {
        Map<String, dynamic> jsonData = AppJson.decode(responseBody);
        if (jsonData != null) {
          List<dynamic> scheduleList = jsonData["schedule"];
          if (scheduleList != null && scheduleList.length > 0) {
            game = Game.fromJson(scheduleList[0]);
          }
        }
      } else {
        Log.e('Failed to load game with id:' + gameId);
        Log.e(responseBody);
      }
    }
    return game;
  }

  Future<List<Game>> loadAllScheduleGames() async {
    List<Game> gamesList = [];
    if(_enabled) {
      String scheduleUrl = (Config().sportsServiceUrl != null) ? "${Config().sportsServiceUrl}/api/schedule" : null;
      DateTime now = AppDateTime().now;
      if (now != null) {
        String dateOffsetString = AppDateTime().formatDateTime(
            now, format: AppDateTime.scheduleServerQueryDateTimeFormat,
            ignoreTimeZone: true);
        scheduleUrl = '$scheduleUrl?date=$dateOffsetString';
      }

      final response = await Network().get(scheduleUrl, auth: NetworkAuth.App);
      if (response != null) {
        String responseBody = response.body;
        if (response.statusCode == 200) {
          List<dynamic> jsonListData = AppJson.decode(responseBody);
          if (AppCollection.isCollectionNotEmpty(jsonListData)) {
            for (var jsonData in jsonListData) {
              Game game = Game.fromJson(jsonData);
              gamesList.add(game);
            }
            gamesList.sort((game1, game2) => game1.dateTimeUtc.compareTo(game2.dateTimeUtc));
          }
        } else {
          Log.e('Failed to load upcoming upcoming games');
          Log.e(responseBody);
        }
      } else {
        Log.e('Failed to load upcoming upcoming games responce == null');
      }
    }
    return gamesList;
  }

  ///
  /// DD: This is used for Saved panel because sport service returns limited game results until 02/16/2019 when we query with startDate=10/01/2019.
  /// Workaround for not displaying Athletics games in Saved panel
  ///
  Future<List<Game>> loadAllScheduleGamesUnlimited() async {
    List<Game> gamesList;
    if(_enabled) {
      String scheduleUrl = Config().sportScheduleUrl;
      DateTime now = AppDateTime().now;
      String dateOffsetString = AppDateTime().formatDateTime(
          now, format: AppDateTime.scheduleServerQueryDateTimeFormat,
          ignoreTimeZone: true);
      scheduleUrl = '$scheduleUrl?format=json&starting=$dateOffsetString';
      final response = await Network().get(scheduleUrl, auth: NetworkAuth.App);

      if (response != null) {
        String responseBody = response.body;
        if (response.statusCode == 200) {
          Map<String, dynamic> jsonData = AppJson.decode(responseBody);
          TeamSchedule schedule = TeamSchedule.fromJson(jsonData);
          gamesList = schedule.games;
          gamesList.sort((game1, game2) =>
              game1.dateTimeUtc.compareTo(game2.dateTimeUtc));
        } else {
          Log.e('Failed to load unlimited upcoming games');
          Log.e(responseBody);
        }
      } else {
        Log.e(
            'Failed to load unlimited upcoming games: response is null');
      }
    }
    return gamesList;
  }

  Future<TeamSchedule> loadUpcomingScheduleItems(String sportKey, int limit) async {
    TeamSchedule schedule;
    if(_enabled) {
      if (limit <= 0 || AppString.isStringEmpty(sportKey)) {
        return null;
      }
      String baseScheduleUrl = await getCurrentSportSeasonScheduleUrl(sportKey);
      if (AppString.isStringEmpty(baseScheduleUrl)) {
        return null;
      }

      DateTime now = DateTime.now();
      String nowFormatted = AppDateTime().formatDateTime(
          now, format: AppDateTime.scheduleServerQueryDateTimeFormat,
          ignoreTimeZone: true);
      final scheduleUrl = "$baseScheduleUrl&format=json&starting=$nowFormatted&take=$limit";
      final response = await Network().get(scheduleUrl);
      String responseBody = response?.body;
      if ((response != null) && (response.statusCode == 200)) {
        Map<String, dynamic> jsonData = AppJson.decode(responseBody);
        schedule = TeamSchedule.fromJson(jsonData);
      } else {
        Log.e('Failed to load upcoming schedule for $sportKey');
        Log.e(responseBody);
      }
    }
    return schedule;
  }

  Future<SportSeasons> loadSportSeason(String sportKey) async {
    SportSeasons sportSeason;
    if(_enabled) {
      if (AppString.isStringEmpty(sportKey)) {
        return null;
      }
      final sportSeasonsUrl = (Config().sportScheduleUrl != null) ? "${Config().sportScheduleUrl}?format=json&path=$sportKey&sportseasons=true" : null;
      final response = await Network().get(sportSeasonsUrl);
      String responseBody = response?.body;
      if ((response != null) && (response.statusCode == 200)) {
        Map<String, dynamic> jsonData = AppJson.decode(responseBody);
        sportSeason = SportSeasons.fromJson(jsonData);
      } else {
        Log.e('Failed to load sport seasons for $sportKey');
        Log.e(responseBody);
      }
    }
    return sportSeason;
  }

  Future<String> getCurrentSportSeasonScheduleUrl(String sportKey) async {
    if(_enabled) {
      SportSeasons sportSeason = await loadSportSeason(sportKey);
      List<SportSeasonSchedule> seasons = sportSeason?.seasons;
      if (seasons == null || seasons.isEmpty) {
        return null;
      }
      SportSeasonSchedule lastSeason = seasons[seasons.length - 1];
      return lastSeason.schedule;
    }
    return null;
  }

  Future<List<News>> loadNews(String sportKey, int count) async {
    if (_enabled) {
      String sportQueryParam = AppString.isStringNotEmpty(sportKey) ? "&sport=$sportKey" : "";
      String countQueryParam = (count > 0) ? "&limit=$count" : "";
      if (Config().sportsServiceUrl != null) {
        String newsUrl = Config().sportsServiceUrl + '/api/v2/news';
        if (AppString.isStringNotEmpty(sportQueryParam) || AppString.isStringNotEmpty(countQueryParam)) {
          newsUrl += "?";
          if (AppString.isStringNotEmpty(sportQueryParam)) {
            newsUrl += sportQueryParam;
          }
          if (AppString.isStringNotEmpty(countQueryParam)) {
            newsUrl += countQueryParam;
          }
        }
        final response = await Network().get(newsUrl, auth: NetworkAuth.App);
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
    }
    return null;
  }

  ///Game Helpers

  Game getFirstUpcomingGame(List<Game> games) {
    if(_enabled) {
      if (games == null || games.isEmpty) {
        return null;
      }
      return games.first;
    }
    return null;
  }

  List<Game> getTodayGames(List<Game> games) {
    if(_enabled) {
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
    return null;
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
    if(_enabled) {
      Game upcomingGame = getFirstUpcomingGame(games);
      return upcomingGame?.isGameDay ?? false;
    }
    return false;
  }

  bool showWelcome(List<Game> games) {
    return _enabled ? !hasTodayGame(games) : false;
  }

  //Preferred Sports helpers

  ///
  /// addSports == 'true' - adds all sports to favorites, 'false' - removes them
  ///
  void switchAllSports(List<SportDefinition> allSports,
      List<String> preferredSports, bool addSports) {
    if(_enabled) {
      if (allSports == null || allSports.isEmpty) {
        return;
      }
      List<String> sportsToUpdate = [];
      for (SportDefinition sport in allSports) {
        String sportShortName = sport.shortName;
        bool preferredSport = (preferredSports?.contains(sportShortName) ??
            false);
        bool addFavoriteSport = !preferredSport && addSports;
        bool removeFavoriteSport = preferredSport && !addSports;
        if (addFavoriteSport || removeFavoriteSport) {
          sportsToUpdate.add(sportShortName);
        }
      }
      User().switchSportSubCategories(sportsToUpdate);
    }
  }

  bool isAllSportsSelected(List<SportDefinition> allSports,
      List<String> preferredSports) {
    if(_enabled) {
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
    return false;
  }

  /////////////////////////
  // Enabled

  bool get _enabled => AppString.isStringNotEmpty(Config().sportsServiceUrl)
      && AppString.isStringNotEmpty(Config().sportScheduleUrl);
}
