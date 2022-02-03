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

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/ext/Game.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/LiveStats.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/RecentItems.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailHeading.dart';
import 'package:illinois/ui/athletics/AthleticsSchedulePanel.dart';
import 'package:illinois/ui/athletics/AthleticsTeamPanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsListPanel.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/OptionSelectionCell.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AthleticsGameDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Game? game;

  final String? gameId;
  final String? sportName;

  AthleticsGameDetailPanel({this.game, this.gameId, this.sportName});

  @override
  _AthleticsGameDetailPanelState createState() => _AthleticsGameDetailPanelState(game);

  @override
  Map<String, dynamic>? get analyticsPageAttributes => game?.analyticsAttributes;
}

class _AthleticsGameDetailPanelState extends State<AthleticsGameDetailPanel> {
  Game? game;
  bool _newsExpanded = false;
  bool _loading = false;

  _AthleticsGameDetailPanelState(this.game);

  @override
  void initState() {
    if (game != null)
      RecentItems().addRecentItem(RecentItem.fromOriginalType(game));
    else
      _loadGame();

    super.initState();
  }

  _loadGame() {
    String? sportName = widget.sportName ?? game?.sport?.shortName;
    String? gameId = widget.gameId ?? game?.id;

    _setLoading(true);
    Sports().loadGame(sportName, gameId).then((loadedGame) {
      game = loadedGame;
      RecentItems().addRecentItem(RecentItem.fromOriginalType(game));
      _setLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  RefreshIndicator(
        onRefresh: _onPullToRefresh,
        child: _buildContent(),
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildContent() {
    if (_loading == true) {
      return Center(child: CircularProgressIndicator());
    }

    if (game == null) {
      return Center(child: Text(Localization().getStringEx('panel.athletics_game_detail.load.failed.msg', 'Failed to load game. Please, try again.')!));
    }

    String? sportKey = game?.sport?.shortName;
    String? sportName = game?.sport?.title;
    SportDefinition? sportDefinition = Sports().getSportByShortName(sportKey);
    return CustomScrollView(
      scrollDirection: Axis.vertical,
      slivers: <Widget>[
        SliverToutHeaderBar(
          context: context,
          imageUrl: game?.imageUrl,
          backColor: Styles().colors!.fillColorPrimary,
          leftTriangleColor: Styles().colors!.fillColorPrimary,
          rightTriangleColor: Styles().colors!.fillColorSecondaryTransparent05,
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Container(
              color: Styles().colors!.background,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AthleticsGameDetailHeading(game: game, showImageTout: false, ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildNewsWidgets(),
                    ),
                  ),
                  Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Container(
                            color: Styles().colors!.fillColorPrimary,
                            height: 40,
                          ),
                          Container(
                            height: 112,
                            width: double.infinity,
                            child: Image.asset('images/slant-down-right.png',
                              color: Styles().colors!.fillColorPrimary,
                              fit: BoxFit.fill,
                              excludeFromSemantics: true,
                            ),
                          )
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(right: 16),
                                  child: Image.asset(
                                    'images/icon-athletics-orange.png',
                                    excludeFromSemantics: true,
                                  ),
                                ),
                                Expanded(child:
                                  Text(
                                    Localization().getStringEx("panel.athletics_game_detail.label.more.title", "More")! + " " + "$sportName",
                                    style:
                                    TextStyle(color: Colors.white, fontSize: 20),
                                  )
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: () => _onScheduleTap(),
                                      child: Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: OptionSelectionCell(
                                          label: Localization().getStringEx("panel.athletics_game_detail.button.schedule.title", "Schedule"),
                                          hint: Localization().getStringEx("panel.athletics_game_detail.button.schedule.hint", ""),
                                          iconPath:
                                          'images/2.0x/schedule-orange.png',
                                          selectedIconPath:
                                          'images/2.0x/schedule-orange.png',
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Analytics().logSelect(target: "News");
                                        Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                                builder: (context) =>
                                                    AthleticsNewsListPanel()));
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: OptionSelectionCell(
                                            label: Localization().getStringEx("panel.athletics_game_detail.button.news.title", "News"),
                                            hint: Localization().getStringEx("panel.athletics_game_detail.button.news.hint", ""),
                                            iconPath:
                                            'images/2.0x/teal.png',
                                            selectedIconPath:
                                            'images/2.0x/teal.png'),
                                      ),
                                    )
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: _onTapTickets,
                                      child: Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: OptionSelectionCell(
                                            label: Localization().getStringEx("panel.athletics_game_detail.button.tickets.title", "Tickets"),
                                            hint: Localization().getStringEx("panel.athletics_game_detail.button.tickets.hint", ""),
                                            iconPath:
                                            'images/2.0x/tickets_yellow.png',
                                            selectedIconPath:
                                            'images/2.0x/tickets_yellow.png'),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Analytics().logSelect(target: "Teams");
                                        Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                                builder: (context) =>
                                                    AthleticsTeamPanel(
                                                        sportDefinition)));
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: OptionSelectionCell(
                                            label: Localization().getStringEx("panel.athletics_game_detail.button.teams.title", "Teams"),
                                            hint: Localization().getStringEx("panel.athletics_game_detail.button.teams.hint", ""),
                                            iconPath:
                                            'images/2.0x/navy.png',
                                            selectedIconPath:
                                            'images/2.0x/navy.png'),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ]),
        )
      ],
    );
  }

  List<Widget> _buildNewsWidgets() {
    List<Widget> widgets = [];
    if (!StringUtils.isEmpty(game?.newsImageUrl)) {
      widgets.add(Container(
        height: 200,
        child: SizedBox.expand(
          child: Image.network(
            game!.newsImageUrl!,
            excludeFromSemantics: true,
            fit: BoxFit.fitWidth,
          ),
        ),
      ));
    }
    if (!StringUtils.isEmpty(game?.newsTitle)) {
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text(
          game!.newsTitle!,
          textAlign: TextAlign.left,
          style: TextStyle(color: Styles().colors!.textBackground, fontSize: 20),
        ),
      ));
    }
    if (!StringUtils.isEmpty(game?.newsContent)) {
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Column(
          children: <Widget>[
            Container(
              height: (_newsExpanded ? null : 65),
              child: Text(
                game!.newsContent!,
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontFamily: Styles().fontFamilies!.regular,
                    color: Styles().colors!.textBackground,
                    fontSize: 16),
              ),
            ),
            Visibility(
                visible: !_newsExpanded,
                child: Container(
                  color: Styles().colors!.fillColorSecondary,
                  height: 1,
                )),
            GestureDetector(
              onTap: () => _onTapNewsExpand(),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      (_newsExpanded
                          ? Localization().getStringEx("panel.athletics_game_detail.label.see_less.title", "See less")!
                          : Localization().getStringEx("panel.athletics_game_detail.label.see_more.title", "See more")!),
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies!.bold,
                          color: Styles().colors!.fillColorPrimary,
                          fontSize: 16),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Image.asset((_newsExpanded
                          ? 'images/icon-up.png'
                          : 'images/icon-down-orange.png'),
                        excludeFromSemantics: true,),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ));
    }
    return widgets;
  }

  void _onTapNewsExpand() {
    Analytics().logSelect(target: "News Expand");
    setState(() {
      _newsExpanded = !_newsExpanded;
    });
  }

  void _onScheduleTap() {
    Analytics().logSelect(target: "Schedule");
    Sport? sport = game?.sport;
    SportDefinition? sportDefinition = Sports().getSportByShortName(sport?.shortName);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsSchedulePanel(sport: sportDefinition)));
  }

  void _onTapTickets() {
    Analytics().logSelect(target: "Tickets");
    if (PrivacyTicketsDialog.shouldConfirm) {
      PrivacyTicketsDialog.show(context, onContinueTap: () {
        _showTicketsPanel();
      });
    } else {
      _showTicketsPanel();
    }
  }

  void _showTicketsPanel() {
    if (Connectivity().isNotOffline && (Config().ticketsUrl != null)) {
      Navigator.push(context, CupertinoPageRoute(
        builder: (context) => WebPanel(url: Config().ticketsUrl)));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.tickets', 'Tickets are not available while offline.'));
    }
  }

  Future<void>_onPullToRefresh() async{
    _loadGame();
    LiveStats().refresh();
  }

  void _setLoading(bool loading) {
    _loading = loading;
    if (mounted) {
      setState(() {});
    }
  }
}
