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

import 'package:flutter/material.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/LiveStats.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/athletics/AthleticsGameDayWidget.dart';

class HomeAthleticsGameDayWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeAthleticsGameDayWidget({Key? key, this.favoriteId, this.updateController,}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.game_day.label.my_game_day', 'My Game Day');

  State<HomeAthleticsGameDayWidget> createState() => _HomeAthleticsGameDayWidgetState();
}

class _HomeAthleticsGameDayWidgetState extends State<HomeAthleticsGameDayWidget> implements NotificationsListener {

  List<Game>? _todayGames;
  DateTime? _pausedDateTime;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      AppLivecycle.notifyStateChanged,
    ]);

    widget.updateController?.stream.listen((String command) {
      if (command == HomePanel.notifyRefresh) {
        LiveStats().refresh();
        _loadTodayGames();
      }
    });

    _loadTodayGames();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Connectivity.notifyStatusChanged) {
      _loadTodayGames();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _loadTodayGames();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if ((_todayGames != null) && (0 < _todayGames!.length)) {
      List<Widget> gameDayWidgets = [];
      for (Game todayGame in _todayGames!) {
        gameDayWidgets.add(AthleticsGameDayWidget(game: todayGame, favoriteId: widget.favoriteId,));
      }
      return Column(children: gameDayWidgets);
    }
    else {
      return HomeSlantWidget(favoriteId: widget.favoriteId,
        title: Localization().getStringEx('widget.game_day.label.its_game_day', 'It\'s Game Day!'),
        titleIconKey: 'athletics',
        child: HomeMessageCard(message: Localization().getStringEx('widget.game_day.label.no_games', 'No Illini Big 10 events today.')),
      );
    }
  }

  void _loadTodayGames() {
    if (Connectivity().isNotOffline) {
      Sports().loadTopScheduleGames().then((List<Game>? games) {
        if (mounted) {
          setState(() {
            _todayGames = Sports().getTodayGames(games);
          });
        }
      });
    }
  }


}
