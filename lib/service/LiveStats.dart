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

import 'dart:ui';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:illinois/model/livestats/LiveGame.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class LiveStats with Service implements NotificationsListener {

  static const String notifyLiveGamesLoaded   = "edu.illinois.rokwire.livestats.games.loaded";
  static const String notifyLiveGamesUpdated  = "edu.illinois.rokwire.livestats.games.updated";

  LiveStats._internal();
  static final LiveStats _logic = new LiveStats._internal();

  factory LiveStats() {
    return _logic;
  }

  List<LiveGame>? _liveGames;
  Map<String, int> _currentTopics = new Map();

  List<LiveGame>? get liveGames => _liveGames;

  @override
  void createService() {
    NotificationService().subscribe(this, [
      AppLifecycle.notifyStateChanged,
      FirebaseMessaging.notifyScoreMessage
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    if(_enabled) {
      _loadLiveGames();
      await super.initService();
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config(), Storage()]);
  }

  bool hasLiveGame(String? gameId) {
    if(_enabled) {
      if (_liveGames == null)
        return false;

      for (LiveGame current in _liveGames!) {
        if (current.gameId == gameId) {
          return true;
        }
      }
    }
    return false;
  }

  LiveGame? getLiveGame(String? gameId) {
    if(_enabled) {
      if (_liveGames == null)
        return null;

      for (LiveGame current in _liveGames!) {
        if (current.gameId == gameId) {
          return current;
        }
      }
    }
    return null;
  }

  void refresh() {
    if(_enabled) {
      _loadLiveGames();
    }
  }

  void addTopic(String? topic) {
    if(_enabled && (topic != null)) {
      //1. subscribe to Firebase
      FirebaseMessaging().subscribeToTopic(topic).then((bool success) {
        if (success) {
          //2. add it to the current topics
          int? currentCount = _currentTopics[topic];
          _currentTopics[topic] = currentCount == null ? 1 : currentCount + 1;
        } else {
          Log.e("Error subscribing to topic $topic");
        }
      });
    }
  }

  void removeTopic(String? topic) {
    if(_enabled && (topic != null)) {
      //1. remove it from the current topics
      int currentCount = _currentTopics[topic]!;
      _currentTopics[topic] = currentCount - 1;

      //2. Unsubscribe if no more topic
      if (_currentTopics[topic] == 0)
        FirebaseMessaging().unsubscribeFromTopic(topic);
    }
  }

  void _onScoreChanged(Map<String, dynamic>? newScore) {
    Log.d("On live game changed");

     LiveGame? liveGame = LiveGame.fromJson(newScore);
     if (liveGame != null)
       _updateLiveGame(liveGame);
  }

  void _updateLiveGame(LiveGame liveGame) {
    if (_liveGames == null)
      _liveGames = <LiveGame>[];

    //1. find the item index
    int itemIndex = -1;
    for (int i = 0; i < _liveGames!.length; i++) {
      LiveGame current = _liveGames![i];
      if (current.gameId == liveGame.gameId) {
        itemIndex = i;
        break;
      }
    }

    //2. apply the live game in the list.
    if (itemIndex != -1)
      _liveGames![itemIndex] = liveGame; //replace
    else
      _liveGames!.add(liveGame); //add

    //3. notify listeners
    NotificationService().notify(notifyLiveGamesUpdated, liveGame);
  }

  void _loadLiveGames() {
    String? url = (Config().sportsServiceUrl != null) ? "${Config().sportsServiceUrl}/api/v2/live-games" : null;
    var response = Network().get(url, auth: Auth2());
    response.then((response) {
    String? responseBody = response?.body;
      if ((response != null) && (response.statusCode == 200)) {
        List<dynamic>? gamesList = JsonUtils.decode(responseBody);
        List<LiveGame> result = <LiveGame>[];
        if (gamesList != null) {
          for (dynamic current in gamesList) {
            ListUtils.add(result, LiveGame.fromJson(current));
          }
        }
        _liveGames = result;
        NotificationService().notify(notifyLiveGamesLoaded, null);
      } else {
        Log.e("Failed to load live games. Reason: $responseBody");
      }
    });
  }

  /////////////////////////
  // Enabled

  bool get _enabled => StringUtils.isNotEmpty(Config().sportsServiceUrl);

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if(_enabled) {
      if (name == AppLifecycle.notifyStateChanged) {
        if (param == AppLifecycleState.resumed) {
          _loadLiveGames();
        }
      }
      else if (name == FirebaseMessaging.notifyScoreMessage) {
        _onScoreChanged(param);
      }
    }
  }
}
