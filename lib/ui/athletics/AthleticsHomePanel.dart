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
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Connectivity.dart';
import 'package:illinois/service/LiveStats.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/athletics/AthleticsGameDayWidget.dart';
import 'package:illinois/ui/athletics/AthleticsTeamPanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/athletics/AthleticsTeamsWidget.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsListPanel.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/HomeHeader.dart';
import 'package:illinois/ui/widgets/OptionSelectionCell.dart';

import 'AthleticsTeamsPanel.dart';

class AthleticsHomePanel extends StatefulWidget {
  final bool showTabBar;

  AthleticsHomePanel({this.showTabBar = true});

  @override
  _AthleticsHomePanelState createState() => _AthleticsHomePanelState();
}

class _AthleticsHomePanelState extends State<AthleticsHomePanel>
    implements NotificationsListener {

  List<Game> _visibleGames;
  List<Game> _todayGames;

  bool _loading = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Storage.offsetDateKey,
      Connectivity.notifyStatusChanged,
      User.notifyInterestsUpdated
    ]);

    _loadGames();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(
          context: context,
          titleWidget: Semantics(label: Localization().getStringEx('panel.athletics.header.title', 'Athletics'),
              excludeSemantics:true,
              child:
              Text(
                Localization().getStringEx('panel.athletics.header.title', 'Athletics'),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0),
              )
          ),
          rightButtonVisible: true,
          rightButtonText: Localization().getStringEx('headerbar.teams.title', 'Teams'),
          onRightButtonTap: () {
            Analytics.instance.logSelect(target: "Teams");
            Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) =>
                        AthleticsTeamsPanel()));
          },
      ),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child: _buildContentWidget()),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: widget.showTabBar ? TabBarWidget() : null,
      );
  }

  Widget _buildContentWidget() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    return Column(
      children: <Widget>[
        Expanded(
            child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
              color: Styles().colors.background,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  _buildGameDayWidgets(),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Semantics(
                          label: Localization().getStringEx("panel.athletics.label.upcoming_events.title", "Upcoming Events"),
                          hint: Localization().getStringEx("panel.athletics.label.upcoming_events.hint", ""),
                          header: true,
                          excludeSemantics: true,
                          child: HomeHeader(
                              title: Localization().getStringEx("panel.athletics.label.upcoming_events.title", "Upcoming Events"),
                              imageRes: 'images/icon-calendar.png'),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 0, right: 0),
                          child: ListView.separated(
                            shrinkWrap: true,
                            separatorBuilder: (context, index) => Divider(
                                  color: Colors.transparent,
                                  height: 20,
                                ),
                            itemCount: (_visibleGames != null) ? _visibleGames.length : 0,
                            itemBuilder: (context, index) {
                              Game game = _visibleGames[index];
                              return _AthleticsCard(
                                game: game,
                                onTap: () => _onTapAthleticsGame(context, game),
                              );
                            },
                            controller: ScrollController(),
                          ),
                        ),
                        Visibility(
                          visible: true,
                          child: Padding(
                            padding: EdgeInsets.only(top: 20, bottom: 60, left: 10, right:10),
                            child: 
                            Row(children: <Widget>[
                              Expanded(flex: 1, child: Container()),
                              Expanded(
                                flex: 5,
                                child: ScalableRoundedButton(
                                  label: Localization().getStringEx("panel.athletics.button.see_more_events.title", 'See more events'),
                                  hint: Localization().getStringEx("panel.athletics.button.see_more_events.hint", ''),
                                  onTap: _onTapMoreUpcomingEvents,
                                  backgroundColor: Styles().colors.background,
                                  borderColor: Styles().colors.fillColorSecondary,
                                  textColor: Styles().colors.fillColorPrimary,
                                ),
                              ),
                              Expanded(flex: 1, child: Container())
                            ],),
                          
                          ),
                        ),
                        Stack(
                          alignment: Alignment.topCenter,
                          children: <Widget>[
                            Container(
                              color: Styles().colors.backgroundVariant,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 10),
                                      child: Text(
                                        Localization().getStringEx("panel.athletics.label.all_illinois_sports.title",'All Illinois Sports'),
                                        style: TextStyle(
                                            color: Styles().colors.fillColorPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    Semantics(
                                      label: Localization().getStringEx("panel.athletics.label.tap_to_follow_team.title", "Tap the checkmark to follow your favorite teams"),
                                      hint: Localization().getStringEx("panel.athletics.label.tap_to_follow_team.hint", ""),
                                      excludeSemantics: true,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            Localization().getStringEx("panel.athletics.label.tap_the.title", "Tap the "),
                                            style: TextStyle(
                                                fontFamily: Styles().fontFamilies.medium,
                                                color: Styles().colors.textBackground,
                                                fontSize: 16),
                                          ),
                                          Image.asset(
                                              'images/icon-check-example.png'),
                                          Expanded(
                                            child:Text(
                                              Localization().getStringEx("panel.athletics.label.follow_team.title", " to follow your favorite teams"),
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontFamily: Styles().fontFamilies.medium,
                                                  color: Styles().colors.textBackground,
                                                  fontSize: 16),
                                            )
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 90, bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: AthleticsTeamsWidget(handleLabelClick: true,),
                                  ),
                                  Container(
                                    height: 40,
                                  ),
                                  Stack(
                                    alignment: Alignment.topCenter,
                                    children: <Widget>[
                                      Column(
                                        children: <Widget>[
                                          Container(
                                            color: Styles().colors.fillColorPrimary,
                                            height: 40,
                                          ),
                                          Container(
                                            height: 112,
                                            width: double.infinity,
                                            child: Image.asset('images/slant-down-right-blue.png',
                                              fit:BoxFit.fill,
                                              color: Styles().colors.fillColorPrimaryVariant
                                            ),
                                          )
                                        ],
                                      ),
                                      Column(
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Semantics( header: true, excludeSemantics: true,
                                                label: Localization().getStringEx("panel.athletics.label.explore_athletics.title", 'Explore Athletics'),
                                                child: Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      right: 16),
                                                  child: Image.asset(
                                                      'images/explore.png'),
                                                ),
                                                Expanded(child:
                                                  Text(
                                                    Localization().getStringEx("panel.athletics.label.explore_athletics.title", 'Explore Athletics'),
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20),
                                                  )
                                                )
                                              ],
                                            )),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: <Widget>[
                                                Column(
                                                  children: <Widget>[
                                                    GestureDetector(
                                                      onTap:
                                                          _onTapMoreUpcomingEvents,
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                bottom: 8),
                                                        child:
                                                            OptionSelectionCell(
                                                              label:
                                                                Localization().getStringEx("panel.athletics.button.upcoming_events.title", 'Upcoming Events'),
                                                              hint:
                                                                Localization().getStringEx("panel.athletics.button.upcoming_events.hint", ''),
                                                              iconPath:
                                                                  'images/2.0x/upcoming_events_orange.png',
                                                              selectedIconPath:
                                                                  'images/2.0x/upcoming_events_orange.png',
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        _onTapNews();
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                bottom: 8),
                                                        child:
                                                            OptionSelectionCell(
                                                              label:
                                                                Localization().getStringEx("panel.athletics.button.news.title", 'News'),
                                                              hint:
                                                                Localization().getStringEx("panel.athletics.button.news.hint", ''),
                                                              iconPath:
                                                                  'images/2.0x/teal.png',
                                                              selectedIconPath:
                                                                  'images/2.0x/teal.png',
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                                Column(
                                                  children: <Widget>[
                                                    GestureDetector(
                                                      onTap: () {
                                                        _onTapTickets();
                                                          },
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                bottom: 8),
                                                        child:
                                                            OptionSelectionCell(
                                                              label:
                                                                Localization().getStringEx("panel.athletics.button.tickets.title", 'Tickets'),
                                                              hint:
                                                                Localization().getStringEx("panel.athletics.button.tickets.hint", ''),
                                                              iconPath:
                                                                'images/2.0x/tickets_yellow.png',
                                                              selectedIconPath:
                                                                'images/2.0x/tickets_yellow.png',
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        _onTapGameDayGuide();
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                bottom: 8),
                                                        child:
                                                            OptionSelectionCell(
                                                              label:
                                                                Localization().getStringEx("panel.athletics.button.game_day_guide.title", 'Game Day Guide'),
                                                              hint:
                                                                Localization().getStringEx("panel.athletics.button.game_day_guide.hint", ''),
                                                              iconPath:
                                                                  'images/2.0x/game_day_blue.png',
                                                              selectedIconPath:
                                                                  'images/2.0x/game_day_blue.png',
                                                        ),
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
                            )
                          ],
                        )
                      ])
                ],
              )),
        )),
      ],
    );
  }

  Widget _buildGameDayWidgets() {
    if (_todayGames == null || _todayGames.isEmpty) {
      return Container();
    }
    List<Widget> gameDayWidgets = [];

    for (Game todayGame in _todayGames) {
      gameDayWidgets.add(AthleticsGameDayWidget(game: todayGame));
    }
    return Column(children: gameDayWidgets);
  }

  void _loadGames() {
    if (Connectivity().isNotOffline) {
      _setLoading(true);
      Sports().loadTopScheduleGames().then((games) => _onGamesLoaded(games));
    }
  }

  void _reloadGames() {
    if (Connectivity().isNotOffline) {
      Sports().loadTopScheduleGames().then((games) => _onGamesLoaded(games));
    }
  }

  void _onGamesLoaded(List<Game> games) {
    _visibleGames = games;
    _todayGames = Sports().getTodayGames(_visibleGames);
    if (_todayGames != null && _todayGames.isNotEmpty) {
      _visibleGames.removeRange(0, _todayGames.length);
    }
    _setLoading(false);
  }

  void _onTapMoreUpcomingEvents() {
    Analytics.instance.logSelect(target: "More Events");
    if (Connectivity().isNotOffline) {
      ExploreFilter initialFilter = ExploreFilter(type: ExploreFilterType.categories, selectedIndexes: {3});
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialTab: ExploreTab.Events, initialFilter: initialFilter, showHeaderBack: true,)));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.see_more_events', 'See more events is not available while offline.'));
    }
  }

  void _onTapNews() {
    Analytics.instance.logSelect(target:"News");
    if (Connectivity().isNotOffline) {
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder:
                  (context) =>
                      AthleticsNewsListPanel()));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.news', 'News are not available while offline.'));
    }
  }

  void _onTapTickets() {
    Analytics.instance.logSelect(target:"Tickets");
    if (Connectivity().isNotOffline && (Config().ticketsUrl != null)) {
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) =>
                  WebPanel(
                      url:
                          Config().ticketsUrl)));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.tickets', 'Tickets are not available while offline.'));
    }
  }

  void _onTapGameDayGuide() {
    Analytics.instance.logSelect(target:"Game Day Guide");
    if (Connectivity().isNotOffline && (Config().gameDayAllUrl != null)) {
        Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) =>
                    WebPanel(
                        url:
                        Config().gameDayAllUrl)));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.game_day_guide', 'Game Day Guide is not available while offline.'));
    }
  }

  void _onTapAthleticsGame(BuildContext context, Game game) {
    Analytics.instance.logSelect(target: "Game: "+game.title);
    if (Connectivity().isNotOffline) {
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => AthleticsGameDetailPanel(game: game)));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.game', 'Game detail is not available while offline.'));
    }
  }

  Future<void>_onPullToRefresh() async{
    _reloadGames();
    LiveStats().refresh();
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _loading = loading;
      });
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Connectivity.notifyStatusChanged) {
      _loadGames();
    }
    if(name == Storage.offsetDateKey){
      _loadGames();
    }
    else if (name == User.notifyInterestsUpdated) {
      _reloadGames();
    }
  }
}

class _AthleticsCard extends StatefulWidget {
  final Game game;
  final GestureTapCallback onTap;

  _AthleticsCard({@required this.game, this.onTap}) {
    assert(game != null);
  }

  @override
  _AthleticsCardState createState() => _AthleticsCardState();
}

class _AthleticsCardState extends State<_AthleticsCard> implements NotificationsListener {

  static const EdgeInsets _detailPadding = EdgeInsets.only(bottom: 12, left: 24, right: 24);
  static const EdgeInsets _iconPadding = EdgeInsets.only(right: 5);

  @override
  void initState() {
    NotificationService().subscribe(this, Auth2UserPrefs.notifyFavoritesChanged);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    String sportKey = widget.game.sport?.shortName;
    SportDefinition sport = Sports().getSportByShortName(sportKey);
    String sportName = (sport != null) ? sport.name : '';
    bool isTicketedSport = (sport != null) ? sport.ticketed : false;
    bool isGetTicketsVisible = isTicketedSport && (widget.game.links?.tickets != null);
    bool showImage =
        (isTicketedSport && !AppString.isStringEmpty(widget.game.imageUrl));
    bool isFavorite = Auth2().isFavorite(widget.game);
    String interestsLabelValue = _getInterestsLabelValue();
    bool showInterests = AppString.isStringNotEmpty(interestsLabelValue);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      child: Stack(
        alignment:
        showImage ? Alignment.bottomCenter : Alignment.topCenter,
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Stack(
                  alignment: showImage
                      ? Alignment.bottomCenter
                      : Alignment.topCenter,
                  children: <Widget>[
                    showImage
                        ? Positioned(
                        child: Image.network(
                          widget.game.imageUrl,
                          semanticLabel: "Sports",
                        ))
                        : Container(height: 0),
                    showImage
                        ? Container(
                      height: 72,
                      color: Styles().colors.fillColorSecondaryTransparent05,
                    )
                        : Container(height: 0)
                  ],
                ),
                showImage
                    ? Container(
                  height: 112,
                  width: double.infinity,
                  child: Image.asset('images/slant-down-right.png',
                    color: Styles().colors.fillColorSecondary,
                    fit: BoxFit.fill,
                  ),
                )
                    : Container(height: 0),
                Container(
                  height: 140,
                  color: Styles().colors.background,
                )
              ],
            ),
          ),
          Padding(
              padding: EdgeInsets.only(
                  left: 20, right: 20, top: (showImage ? 0 : 20)),
              child: Stack(alignment: Alignment.topCenter, children: [
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.all(Radius.circular(4))),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: ((showInterests &&
                        !(isTicketedSport)) ? 0 : 12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(left: 20, right: 0),
                          child: Row(
                            children: <Widget>[
                              Semantics(button: true,child:
                              GestureDetector(
                                  onTap: () => _onTapSportCategory(sport),
                                  child: Padding(
                                    padding: EdgeInsets.only(top:24),
                                    child:Container(
                                      color: Styles().colors.fillColorPrimary,
                                      child: Padding(
                                        padding: EdgeInsets.all(5),
                                        child: Text(
                                          sportName.toUpperCase(),
                                          style: TextStyle(
                                              fontFamily: Styles().fontFamilies.bold,
                                              fontSize: 14,
                                              letterSpacing: 1.0,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),))),
                              Expanded(
                                child: Container(),
                              ),
                              Visibility(visible: Auth2().canFavorite,
                                child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _onTapSave,
                                    child: Semantics(
                                        label: isFavorite
                                            ? Localization().getStringEx(
                                            'widget.card.button.favorite.off.title',
                                            'Remove From Favorites')
                                            : Localization().getStringEx(
                                            'widget.card.button.favorite.on.title',
                                            'Add To Favorites'),
                                        hint: isFavorite ? Localization()
                                            .getStringEx(
                                            'widget.card.button.favorite.off.hint',
                                            '') : Localization().getStringEx(
                                            'widget.card.button.favorite.on.hint',
                                            ''),
                                        excludeSemantics: true,
                                        child: Container(child: Padding(
                                            padding: EdgeInsets.only(
                                                right: 24,
                                                top: 24,
                                                left: 24,
                                                bottom: 8),
                                            child: Image.asset(isFavorite
                                                ? 'images/icon-star-selected.png'
                                                : 'images/icon-star.png')
                                        ))
                                    )),)
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          child: Text(
                            widget.game.title,
                            style: TextStyle(
                                fontSize: 24,
                                color: Styles().colors.fillColorPrimary,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                        _athleticsDetails(),
                        _athleticsDescription(),
                        Visibility(visible: showInterests,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start,
                              children: <Widget>[
                                Container(
                                  height: 1,
                                  color: Styles().colors.surfaceAccent,),
                                Padding(padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: <Widget>[
                                      Text(Localization().getStringEx(
                                          'widget.card.label.interests',
                                          'Because of your interest in:'),
                                        style: TextStyle(
                                            color: Styles().colors.textBackground,
                                            fontSize: 12,
                                            fontFamily: Styles().fontFamilies.bold),),
                                      Text(AppString.getDefaultEmptyString(
                                          value: interestsLabelValue),
                                        style: TextStyle(
                                            color: Styles().colors.textBackground,
                                            fontSize: 12,
                                            fontFamily: Styles().fontFamilies.medium),)
                                    ],),)
                              ],)),
                        Visibility(
                            visible: isGetTicketsVisible,
                            child: Padding(
                              padding:
                              EdgeInsets.symmetric(horizontal: 20),
                              child: RoundedButton(
                                label: Localization().getStringEx('widget.athletics_card.button.get_tickets.title', 'Get Tickets'),
                                hint: Localization().getStringEx('widget.athletics_card.button.get_tickets.hint', ''),
                                backgroundColor: Colors.white,
                                fontSize: 16,
                                borderColor: Styles().colors.fillColorSecondary,
                                textColor: Styles().colors.fillColorPrimary,
                                onTap: _onTapGetTickets,
                              ),
                            ))
                      ],
                    ),
                  ),
                ),
                !showImage
                    ? Container(
                    height: 7, color: Styles().colors.fillColorPrimary)
                    : Container(),
              ])),
        ],
      ),
    );
  }

  void _onTapGetTickets() {
    Analytics.instance.logSelect(
        target: "AthleticsCard:Item:" + widget?.game?.title + " -Get Tickets");
    if (PrivacyTicketsDialog.shouldConfirm) {
      PrivacyTicketsDialog.show(context, onContinueTap: () {
        _showTicketsPanel();
      });
    } else {
      _showTicketsPanel();
    }
  }

  void _showTicketsPanel() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: widget.game.links?.tickets)));
  }

  Widget _athleticsDetails() {
    List<Widget> details = [];

    Widget time = _athleticsTimeDetail();
    if (time != null) {
      details.add(time);
    }

    Widget location = _athleticsLocationDetail();
    if (location != null) {
      details.add(location);
    }

    return (0 < details.length)
        ? Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details))
        : Container();
  }

  Widget _athleticsTimeDetail() {
    String displayTime = widget.game.displayTime;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Padding(
        padding: _detailPadding,
        child:Semantics(label:displayTime, excludeSemantics: true ,child: Row(
          children: <Widget>[
            Image.asset('images/icon-time.png'),
            Padding(
              padding: _iconPadding,
            ),
            Text(displayTime,
                style: TextStyle(
                    fontFamily: Styles().fontFamilies.medium,
                    fontSize: 16,
                    color: Styles().colors.textBackground)),
          ],
        )),
      );
    } else {
      return null;
    }
  }

  Widget _athleticsLocationDetail() {
    String locationText = widget.game.location?.location;
    if ((locationText != null) && locationText.isNotEmpty) {
      return Padding(
        padding: _detailPadding,
        child: Semantics(label:locationText, excludeSemantics: true ,child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Image.asset('images/icon-location.png'),
            Padding(
              padding: _iconPadding,
            ),
            Flexible(
                child: Text(locationText,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.medium,
                        fontSize: 16,
                        color: Styles().colors.textBackground))),
          ],
        )),
      );
    } else {
      return null;
    }
  }

  Widget _athleticsDescription() {
    String description = widget.game.shortDescription;
    return ((description != null) && description.isNotEmpty)
        ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
                _divider(),
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    child: Text(
                      description,
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies.medium,
                          fontSize: 16,
                          color: Styles().colors.textBackground),
                    ))
              ])
        : Container();
  }

  Widget _divider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0),
      child: Container(
        height: 1,
        color: Styles().colors.fillColorPrimaryTransparent015,
      ),
    );
  }

  void _onTapSave() {
    Analytics.instance.logSelect(target: "Favorite: ${widget.game?.title}");
    Auth2().prefs?.toggleFavorite(widget.game);
  }

  void _onTapSportCategory(SportDefinition sport) {
    Analytics.instance.logSelect(target: "AthleticsCard:Item:" + widget?.game?.title + " -category: " + sport.name);
    if (sport != null) {
      if (Connectivity().isNotOffline) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsTeamPanel(sport)));
      }
      else {
        AppAlert.showOfflineMessage(context, Localization().getStringEx('widget.athletics_card.label.offline.sports', 'Sports are not available while offline.'));
      }
    }
  }

  String _getInterestsLabelValue() {
    String sportName = widget?.game?.sport?.shortName;
    bool isSportFavorite = Auth2().prefs?.hasSportInterest(sportName);
    return isSportFavorite ? Sports().getSportByShortName(sportName)?.customName : null;
  }
}
