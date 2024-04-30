/*
 * Copyright 2024 Board of Trustees of the University of Illinois.
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

import 'package:flutter/material.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailHeading.dart';
import 'package:illinois/ui/athletics/AthleticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AthleticsGameDayContentWidget extends StatefulWidget {

  AthleticsGameDayContentWidget();

  @override
  _AthleticsGameDayContentWidgetState createState() => _AthleticsGameDayContentWidgetState();
}

class _AthleticsGameDayContentWidgetState extends State<AthleticsGameDayContentWidget> implements NotificationsListener {
  List<Game>? _todayGames;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Auth2UserPrefs.notifyInterestsChanged]);
    _loadTodayGames();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Styles().colors.surface,
        child: Column(children: [
          AthleticsTeamsFilterWidget(),
          Expanded(child: _buildContent())
        ]));
  }

  void _loadTodayGames() {
    setStateIfMounted(() {
      _loading = true;
    });
    Sports().loadPreferredTodayGames().then((List<Game>? games) {
      setStateIfMounted(() {
        _loading = false;
        _todayGames = games;
      });
    });
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoadingContent();
    } else if (_todayGames == null) {
      return _buildErrorContent();
    } else if (_todayGames?.length == 0) {
      return _buildEmptyContent();
    } else {
      return _buildGameDayContent();
    }
  }

  Widget _buildLoadingContent() {
    return _buildCenteredWidget(CircularProgressIndicator(color: Styles().colors.fillColorSecondary));
  }

  Widget _buildEmptyContent() {
    return _buildCenteredWidget(Text(
        Localization()
            .getStringEx('panel.athletics.content.game_day.empty.message', 'There are no available gameday guides for the selected teams.'),
        textAlign: TextAlign.center,
        style: Styles().textStyles.getTextStyle('widget.item.medium.fat')));
  }

  Widget _buildErrorContent() {
    return _buildCenteredWidget(Text(
        Localization().getStringEx('panel.athletics.content.game_day.failed.message', "Failed to load today's games."),
        textAlign: TextAlign.center,
        style: Styles().textStyles.getTextStyle('widget.item.medium.fat')));
  }

  Widget _buildCenteredWidget(Widget child) {
    return Center(child: child);
  }

  Widget _buildGameDayContent() {
    if (CollectionUtils.isEmpty(_todayGames)) {
      return Container();
    }
    List<Widget> gameDayWidgets = <Widget>[];
    for (Game game in _todayGames!) {
      gameDayWidgets.add(AthleticsGameDetailHeading(game: game));
    }
    return SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child: Column(children: gameDayWidgets));
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Auth2UserPrefs.notifyInterestsChanged) {
      _loadTodayGames();
    }
  }
}

