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
import 'package:illinois/ext/Game.dart';
import 'package:illinois/service/LiveStats.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailHeading.dart';
import 'package:illinois/ui/athletics/AthleticsSchedulePanel.dart';
import 'package:illinois/ui/athletics/AthleticsTeamPanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsListPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/tile_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AthleticsGameDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Game? game;

  final String? gameId;
  final String? sportName;

  final Event2Selector<Event2SelectorData>? eventSelector;

  AthleticsGameDetailPanel({this.game, this.gameId, this.sportName, this.eventSelector});

  @override
  _AthleticsGameDetailPanelState createState() => _AthleticsGameDetailPanelState(game);

  @override
  Map<String, dynamic>? get analyticsPageAttributes => game?.analyticsAttributes;
}

class _AthleticsGameDetailPanelState extends State<AthleticsGameDetailPanel> implements Event2SelectorDataProvider{
  Game? game;
  bool _newsExpanded = false;
  bool _loading = false;

  _AthleticsGameDetailPanelState(this.game);

  @override
  void initState() {
    if (game != null)
      RecentItems().addRecentItem(RecentItem.fromSource(game));
    else
      _loadGame();
    _initSelector();
    super.initState();
  }

  @override
  void dispose(){
    widget.eventSelector?.dispose(this);
    super.dispose();
  }

  _loadGame() {
    String? sportName = widget.sportName ?? game?.sport?.shortName;
    String? gameId = widget.gameId ?? game?.id;

    _setLoading(true);
    Sports().loadGame(sportName, gameId).then((loadedGame) {
      game = loadedGame;
      RecentItems().addRecentItem(RecentItem.fromSource(game));
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
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    if (_loading == true) {
      return Center(child: CircularProgressIndicator());
    }

    if (game == null) {
      return Center(child: Text(Localization().getStringEx('panel.athletics_game_detail.load.failed.msg', 'Failed to load game. Please, try again.')));
    }

    String? sportName = game?.sport?.title;
    return CustomScrollView(
      scrollDirection: Axis.vertical,
      slivers: <Widget>[
        SliverToutHeaderBar(
          flexImageUrl: game?.imageUrl,
          flexBackColor: Styles().colors?.fillColorPrimary,
          flexRightToLeftTriangleColor: Styles().colors!.fillColorPrimary,
          flexLeftToRightTriangleColor: Styles().colors!.fillColorSecondaryTransparent05,
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
                            child: Styles().images?.getImage('slant-dark',
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
                                  child: Styles().images?.getImage('athletics', excludeFromSemantics: true),
                                ),
                                Expanded(child:
                                  Text(
                                    Localization().getStringEx("panel.athletics_game_detail.label.more.title", "More") + " " + "$sportName",
                                    style: Styles().textStyles?.getTextStyle("widget.heading.large"),
                                  )
                                ),
                              ],
                            ),
                          ),
                          Padding(padding: EdgeInsets.all(16), child:
                            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                              Expanded(child:
                                Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
                                  Padding( padding: EdgeInsets.only(bottom: 8), child:
                                    TileButton(
                                      title: Localization().getStringEx("panel.athletics_game_detail.button.schedule.title", "Schedule"),
                                      hint: Localization().getStringEx("panel.athletics_game_detail.button.schedule.hint", ""),
                                      iconAsset: 'calendar', //images/2.0x/schedule-orange.png
                                      contentSpacing: 16, padding: EdgeInsets.all(16), borderWidth: 0, borderShadow: [],
                                      onTap: _onScheduleTap,
                                    ),
                                  ),
                                  Padding(padding: EdgeInsets.only(bottom: 8), child:
                                    TileButton(
                                      title: Localization().getStringEx("panel.athletics_game_detail.button.news.title", "News"),
                                      hint: Localization().getStringEx("panel.athletics_game_detail.button.news.hint", ""),
                                      iconAsset: 'news', //images/2.0x/teal.png
                                      contentSpacing: 16, padding: EdgeInsets.all(16), borderWidth: 0, borderShadow: [],
                                      onTap: _onTapNews,
                                    ),
                                  ),
                                ],),
                              ),
                              Container(width: 12,),
                              Expanded(child:
                                Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
                                  /*Padding(padding: EdgeInsets.only(bottom: 8), child:
                                    TileButton(
                                      title: Localization().getStringEx("panel.athletics_game_detail.button.tickets.title", "Tickets"),
                                      hint: Localization().getStringEx("panel.athletics_game_detail.button.tickets.hint", ""),
                                      iconAsset: 'images/2.0x/tickets_yellow.png',
                                      contentSpacing: 16, padding: EdgeInsets.all(16), borderWidth: 0, borderShadow: [],
                                      onTap: _onTapTickets,
                                    ),
                                  ),*/
                                  Padding(padding: EdgeInsets.only(bottom: 8), child:
                                    TileButton(
                                      title: Localization().getStringEx("panel.athletics_game_detail.button.teams.title", "Teams"),
                                      hint: Localization().getStringEx("panel.athletics_game_detail.button.teams.hint", ""),
                                      iconAsset: 'images/2.0x/navy.png', // TODO - ICONS find an icon
                                      contentSpacing: 16, padding: EdgeInsets.all(16), borderWidth: 0, borderShadow: [],
                                      onTap: _onTapTeams,
                                    ),
                                  ),
                                ],),
                              )
                            ],),
                          ),
                           _buildSelectorWidget()
                        ],
                      ),
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
          child: ModalImageHolder(child: Image.network(
            game!.newsImageUrl!,
            semanticLabel: "game",
            fit: BoxFit.fitWidth,
          )),
        ),
      ));
    }
    if (!StringUtils.isEmpty(game?.newsTitle)) {
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text(
          game!.newsTitle!,
          textAlign: TextAlign.left,
          style: Styles().textStyles?.getTextStyle("widget.item.large")
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
                style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")
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
                          ? Localization().getStringEx("panel.athletics_game_detail.label.see_less.title", "See less")
                          : Localization().getStringEx("panel.athletics_game_detail.label.see_more.title", "See more")),
                      style: Styles().textStyles?.getTextStyle("widget.title.regular.fat")
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Styles().images?.getImage(_newsExpanded ? 'chevron-up' : 'chevron-down', excludeFromSemantics: true,),
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

  void _onTapNews() {
    Analytics().logSelect(target: "News");
    Navigator.push(context, CupertinoPageRoute( builder: (context) => AthleticsNewsListPanel()));
  }

  void _onTapTeams() {
    Analytics().logSelect(target: "Teams");
    SportDefinition? sportDefinition = Sports().getSportByShortName(game?.sport?.shortName);
    Navigator.push(context, CupertinoPageRoute( builder: (context) => AthleticsTeamPanel(sportDefinition)));
  }

  /*void _onTapTickets() {
    Analytics().logSelect(target: "Tickets");
    if (PrivacyTicketsDialog.shouldConfirm) {
      PrivacyTicketsDialog.show(context, onContinueTap: () {
        _showTicketsPanel();
      });
    } else {
      _showTicketsPanel();
    }
  }*/

  /*void _showTicketsPanel() {
    if (Connectivity().isNotOffline && (Config().ticketsUrl != null)) {
      Navigator.push(context, CupertinoPageRoute(
        builder: (context) => WebPanel(
          url: Config().ticketsUrl
          analyticsName: "WebPanel(Tickets)",
          analyticsSource: game?.analyticsAttributes,
        )));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.tickets', 'Tickets are not available while offline.'));
    }
  }*/

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

  //Event to Group Binding support
  @override
  Event2SelectorData? selectorData;

  void _initSelector(){
    widget.eventSelector?.init(this);
  }

  Widget _buildSelectorWidget(){
    Widget? selectorWidget = widget.eventSelector?.buildWidget(this);
    if(selectorWidget != null){
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: selectorWidget,
      );
    }

    return Container();
  }
}
