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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/athletics/AthleticsTeamPanel.dart';
import 'package:illinois/ui/athletics/AthleticsWidgets.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AthleticsTeamsContentWidget extends StatefulWidget {
  AthleticsTeamsContentWidget();

  @override
  State<AthleticsTeamsContentWidget> createState() => _AthleticsTeamsContentWidgetState();
}

class _AthleticsTeamsContentWidgetState extends State<AthleticsTeamsContentWidget> with NotificationsListener {
  List<SportDefinition>? _teams;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Auth2UserPrefs.notifyInterestsChanged]);
    _load();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Styles().colors.white,
        child: Column(children: [
          AthleticsTeamsFilterWidget(hideFilterDescription: true),
          Expanded(child: _buildContent())
        ]));
  }

  Widget _buildContent() {
    if (_teams == null) {
      return _buildErrorContent();
    } else if (_teams?.length == 0) {
      return _buildEmptyContent();
    } else {
      return _buildTeamsContent();
    }
  }

  Widget _buildTeamsContent() {
    List<Widget> cardsList = <Widget>[];
    for (SportDefinition team in _teams!) {
      String? teamName = team.name;
      if (teamName != null) {
        cardsList.add(Padding(
            padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0),
            child: InkWell(
                splashColor: Colors.transparent,
                onTap: () => _onTapTeam(team),
                child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Styles().colors.disabledTextColor, width: 1), borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(children: [
                          Expanded(
                              child: Text(teamName.toUpperCase(),
                                  style: Styles().textStyles.getTextStyle('widget.button.title.small.fat'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                          Styles().images.getImage('chevron-right-bold') ?? Container()
                        ]))))));
      }
    }
    return SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child: Padding(padding: EdgeInsets.all(16), child: Column(children: cardsList)));
  }

  Widget _buildEmptyContent() {
    return _buildCenteredWidget(Text(Localization().getStringEx('panel.athletics.content.teams.empty.message', 'Select your favorite teams to display here.'),
        textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat')));
  }

  Widget _buildErrorContent() {
    return _buildCenteredWidget(Text(
        Localization().getStringEx('panel.athletics.content.teams.unknown_error.message', 'Unknown Error Occurred.'),
        textAlign: TextAlign.center,
        style: Styles().textStyles.getTextStyle('widget.item.medium.fat')));
  }

  Widget _buildCenteredWidget(Widget child) {
    return Center(child: child);
  }

  void _onTapTeam(SportDefinition sport) {
    Analytics().logSelect(target: 'Team: ' + StringUtils.ensureNotEmpty(sport.shortName));
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsTeamPanel(sport)));
  }

  void _load() {
    Set<String>? preferredTeams = Auth2().prefs?.sportsInterests;
    if (CollectionUtils.isNotEmpty(preferredTeams)) {
      _teams = <SportDefinition>[];
      for (String sportShortName in preferredTeams!) {
        SportDefinition? sport = Sports().getSportByShortName(sportShortName);
        if (sport != null) {
          _teams!.add(sport);
        }
      }
      _sortTeams();
    } else {
      _teams = <SportDefinition>[];
    }
  }

  void _sortTeams() {
    _teams?.sort((SportDefinition first, SportDefinition second) {
      String? firstCustomName = first.customName;
      String? secondCustomName = second.customName;
      if (firstCustomName == secondCustomName) {
        if (first.name != null) {
          return (second.name != null) ? first.name!.compareTo(second.name!) : 1;
        } else {
          return (second.name != null) ? -1 : 0;
        }
      } else {
        if (firstCustomName != null) {
          return (secondCustomName != null) ? firstCustomName.compareTo(secondCustomName) : 1;
        } else {
          return (secondCustomName != null) ? -1 : 0;
        }
      }
    });
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Auth2UserPrefs.notifyInterestsChanged) {
      _load();
    }
  }
}
