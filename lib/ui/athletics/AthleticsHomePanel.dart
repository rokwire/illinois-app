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
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/LiveStats.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/ext/Game.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/athletics/AthleticsGameDayWidget.dart';
import 'package:illinois/ui/athletics/AthleticsTeamPanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/athletics/AthleticsTeamsWidget.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/tile_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsListPanel.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/widgets/section_header.dart';

import 'AthleticsTeamsPanel.dart';

class AthleticsHomePanel extends StatefulWidget {
  final bool rootTabDisplay;

  AthleticsHomePanel({this.rootTabDisplay = false});

  @override
  _AthleticsHomePanelState createState() => _AthleticsHomePanelState();
}

class _AthleticsHomePanelState extends State<AthleticsHomePanel>
    implements NotificationsListener {

  List<Game>? _visibleGames;
  List<Game>? _todayGames;

  bool _loading = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Storage.offsetDateKey,
      Connectivity.notifyStatusChanged,
      Auth2UserPrefs.notifyInterestsChanged
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
      appBar: AppBar(
        backgroundColor: Styles().colors!.fillColorPrimaryVariant,
        leading: widget.rootTabDisplay ? _buildHeaderHomeButton() : _buildHeaderBackButton(),
        title: _buildHeaderTitle(),
        actions: [_buildHeaderActions()],

      ),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child: _buildContentWidget()),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: widget.rootTabDisplay ? null : uiuc.TabBar(),
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
              color: Styles().colors!.background,
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
                          child: SectionRibbonHeader(
                            title: Localization().getStringEx("panel.athletics.label.upcoming_events.title", "Upcoming Events"),
                            titleIconKey: 'calendar',
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 0, right: 0),
                          child: ListView.separated(
                            shrinkWrap: true,
                            separatorBuilder: (context, index) => Divider(
                                  color: Colors.transparent,
                                  height: 20,
                                ),
                            itemCount: (_visibleGames != null) ? _visibleGames!.length : 0,
                            itemBuilder: (context, index) {
                              Game game = _visibleGames![index];
                              return AthleticsCard(game: game, onTap: () => _onTapAthleticsGame(context, game),
                                showImage: true, showDescription: true, showInterests: true, showGetTickets: true,);
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
                                child: RoundedButton(
                                  label: Localization().getStringEx("panel.athletics.button.see_more_events.title", 'See More Events'),
                                  hint: Localization().getStringEx("panel.athletics.button.see_more_events.hint", ''),
                                  textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                                  onTap: _onTapMoreUpcomingEvents,
                                  backgroundColor: Styles().colors!.background,
                                  borderColor: Styles().colors!.fillColorSecondary,
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
                              color: Styles().colors!.backgroundVariant,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 10),
                                      child: Text(
                                        Localization().getStringEx("panel.athletics.label.all_sports.title",'All {{app_title}} Sports').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
                                        style: Styles().textStyles?.getTextStyle('panel.athletics.home.title.large'),
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
                                            style: Styles().textStyles?.getTextStyle('panel.athletics.home.detail.medium') ,
                                          ),
                                          Styles().images?.getImage('check-circle-outline-gray', excludeFromSemantics: true) ?? Container(),
                                          Expanded(
                                            child:Text(
                                              Localization().getStringEx("panel.athletics.label.follow_team.title", " to follow your favorite teams"),
                                              overflow: TextOverflow.ellipsis,
                                              style: Styles().textStyles?.getTextStyle('panel.athletics.home.detail.medium'),
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
                                    child: AthleticsTeamsWidget(handleTeamTap: true,),
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
                                            color: Styles().colors!.fillColorPrimary,
                                            height: 40,
                                          ),
                                          Container(
                                            height: 112,
                                            width: double.infinity,
                                            child: Styles().images?.getImage('slant-dark',
                                              fit:BoxFit.fill,
                                              excludeFromSemantics: true
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
                                                  child: Styles().images?.getImage('compass', excludeFromSemantics: true),
                                                ),
                                                Expanded(child:
                                                  Text(
                                                    Localization().getStringEx("panel.athletics.label.explore_athletics.title", 'Explore Athletics'),
                                                    style: Styles().textStyles?.getTextStyle('widget.heading.large'),
                                                  )
                                                )
                                              ],
                                            )),
                                          ),
                                          Padding(padding: EdgeInsets.all(16), child:
                                            Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                                              Expanded(child:
                                                Column(children: <Widget>[
                                                  Padding(padding: EdgeInsets.only(bottom: 8), child:
                                                    TileButton(
                                                      title: Localization().getStringEx("panel.athletics.button.upcoming_events.title", 'Upcoming Events'),
                                                      hint: Localization().getStringEx("panel.athletics.button.upcoming_events.hint", ''),
                                                      iconAsset: 'images/2.0x/upcoming_events_orange.png',
                                                      contentSpacing: 16, padding: EdgeInsets.all(16), borderWidth: 0, borderShadow: [],
                                                      onTap: _onTapMoreUpcomingEvents,
                                                    ),
                                                  ),
                                                  Padding(padding: EdgeInsets.only(bottom: 8), child:
                                                    TileButton(
                                                      title: Localization().getStringEx("panel.athletics.button.news.title", 'News'),
                                                      hint: Localization().getStringEx("panel.athletics.button.news.hint", ''),
                                                      iconAsset: 'images/2.0x/teal.png',
                                                      contentSpacing: 16, padding: EdgeInsets.all(16), borderWidth: 0, borderShadow: [],
                                                      onTap: _onTapNews,
                                                    ),
                                                  ),
                                                ],),
                                              ),
                                              Container(width: 12,),
                                              Expanded(child:
                                                Column(children: <Widget>[
                                                  /*Padding(padding: EdgeInsets.only(bottom: 8), child:
                                                    TileButton(
                                                      title: Localization().getStringEx("panel.athletics.button.tickets.title", 'Tickets'),
                                                      hint: Localization().getStringEx("panel.athletics.button.tickets.hint", ''),
                                                      iconAsset: 'images/2.0x/tickets_yellow.png',
                                                      contentSpacing: 16, padding: EdgeInsets.all(16), borderWidth: 0, borderShadow: [],
                                                      onTap: _onTapTickets,
                                                      ),
                                                    ),*/
                                                  Padding(padding: EdgeInsets.only(bottom: 8), child:
                                                    TileButton(
                                                      title: Localization().getStringEx("panel.athletics.button.game_day_guide.title", 'Game Day Guide'),
                                                      hint: Localization().getStringEx("panel.athletics.button.game_day_guide.hint", ''),
                                                      iconAsset: 'images/2.0x/game_day_blue.png',
                                                      contentSpacing: 16, padding: EdgeInsets.all(16), borderWidth: 0, borderShadow: [],
                                                      onTap: _onTapGameDayGuide,
                                                    ),
                                                  ),
                                                ],)
                                              ),
                                            ],),
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
    if (_todayGames == null || _todayGames!.isEmpty) {
      return Container();
    }
    List<Widget> gameDayWidgets = [];

    for (Game todayGame in _todayGames!) {
      gameDayWidgets.add(AthleticsGameDayWidget(game: todayGame));
    }
    return Column(children: gameDayWidgets);
  }

  Widget _buildHeaderHomeButton() {
    return Semantics(label: Localization().getStringEx('headerbar.home.title', 'Home'), hint: Localization().getStringEx('headerbar.home.hint', ''), button: true, excludeSemantics: true, child:
          IconButton(icon: Styles().images?.getImage('university-logo', excludeFromSemantics: true) ?? Container(), onPressed: _onTapHome,),);
  }

  Widget _buildHeaderBackButton() {
    return Semantics(label: Localization().getStringEx('headerbar.back.title', 'Back'), hint: Localization().getStringEx('headerbar.back.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Styles().images?.getImage('chevron-left-white', excludeFromSemantics: true) ?? Container(), onPressed: _onTapBack,));
  }

  Widget _buildHeaderTitle() {
    return Semantics(label: Localization().getStringEx('panel.athletics.header.title', 'Athletics'), excludeSemantics: true, child:
          Text(Localization().getStringEx('panel.athletics.header.title', 'Athletics'), style: Styles().textStyles?.getTextStyle('panel.athletics.home.heading.regular')),);
  }

  Widget _buildHeaderTeamsButton({double horizontalPadding = 16}) {
    return Semantics(label: Localization().getStringEx('headerbar.teams.title', 'Teams'), button: true, excludeSemantics: true, child: 
        InkWell(onTap: _onTapTeams, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 19), child:
            Text(Localization().getStringEx('headerbar.teams.title', 'Teams'), style: Styles().textStyles?.getTextStyle('panel.athletics.home.button.underline'))
          ),
        ),
      );
  }

  Widget _buildHeaderSettingsButton() {
    return Semantics(label: Localization().getStringEx('headerbar.settings.title', 'Settings'), hint: Localization().getStringEx('headerbar.settings.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Styles().images?.getImage('settings-white', excludeFromSemantics: true) ?? Container(), onPressed: _onTapSettings));
  }

  Widget _buildHeaderActions() {
    List<Widget> actions = <Widget>[ _buildHeaderTeamsButton(horizontalPadding: widget.rootTabDisplay ? 0 : 16) ];
    if (widget.rootTabDisplay) {
      actions.add(_buildHeaderSettingsButton());
    }
    return Row(mainAxisSize: MainAxisSize.min, children: actions,);
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

  void _onGamesLoaded(List<Game>? games) {
    _visibleGames = games;
    _todayGames = Sports().getTodayGames(_visibleGames);
    if (_todayGames != null && _todayGames!.isNotEmpty) {
      _visibleGames!.removeRange(0, _todayGames!.length);
    }
    _setLoading(false);
  }

  void _onTapHome() {
    Analytics().logSelect(target: "Home");
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onTapBack() {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }

  void _onTapTeams() {
    Analytics().logSelect(target: "Teams");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsTeamsPanel()));
  }

  void _onTapSettings() {
    Analytics().logSelect(target: "Settings");
    SettingsHomeContentPanel.present(context);
  }

  void _onTapMoreUpcomingEvents() {
    Analytics().logSelect(target: "More Events");
    if (Connectivity().isNotOffline) {
      ExploreFilter initialFilter = ExploreFilter(type: ExploreFilterType.categories, selectedIndexes: {2});
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(exploreType: ExploreType.Events, initialFilter: initialFilter)));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.see_more_events', 'See more events is not available while offline.'));
    }
  }

  void _onTapNews() {
    Analytics().logSelect(target:"News");
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

  /*void _onTapTickets() {
    Analytics().logSelect(target:"Tickets");
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
  }*/

  void _onTapGameDayGuide() {
    Analytics().logSelect(target:"Game Day Guide");
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
    Analytics().logSelect(target: "Game: "+game.title);
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
    else if (name == Auth2UserPrefs.notifyInterestsChanged) {
      _reloadGames();
    }
  }
}

class AthleticsCard extends StatefulWidget {
  final Game game;
  final GestureTapCallback? onTap;
  final EdgeInsetsGeometry margin;
  final bool showImage;
  final bool showDescription;
  final bool showInterests;
  final bool showGetTickets;

  static const EdgeInsetsGeometry imageMargin = const EdgeInsets.only(left: 20, right: 20);
  static const EdgeInsetsGeometry regularMargin = const EdgeInsets.only(left: 20, right: 20, top: 20);

  AthleticsCard({required this.game, this.onTap,
    EdgeInsetsGeometry? margin,
    this.showImage = false,
    this.showDescription = false,
    this.showInterests = false,
    this.showGetTickets = false}) :
    margin = margin ?? (showImage ? imageMargin : regularMargin);

  @override
  _AthleticsCardState createState() => _AthleticsCardState();
}

class _AthleticsCardState extends State<AthleticsCard> implements NotificationsListener {

  static const EdgeInsets _detailPadding = EdgeInsets.only(bottom: 12, left: 24, right: 24);
  static const EdgeInsets _iconPadding = EdgeInsets.only(right: 5);

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
    ]);
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
      setStateIfMounted(() {});
    }
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    String? sportKey = widget.game.sport?.shortName;
    SportDefinition? sport = Sports().getSportByShortName(sportKey);
    String sportName = sport?.name ?? '';
    bool isTicketedSport = sport?.ticketed ?? false;
    bool showImage = widget.showImage && StringUtils.isNotEmpty(widget.game.imageUrl) && isTicketedSport;
    bool isGetTicketsVisible = widget.showGetTickets &&  StringUtils.isNotEmpty(widget.game.links?.tickets) && isTicketedSport;
    bool isFavorite = Auth2().isFavorite(widget.game);
    String? interestsLabelValue = _getInterestsLabelValue();
    bool showInterests = StringUtils.isNotEmpty(interestsLabelValue);
    String? description = widget.game.description;
    bool showDescription = widget.showDescription && StringUtils.isNotEmpty(description);

    return GestureDetector(behavior: HitTestBehavior.translucent, onTap: widget.onTap, child:
      Stack(alignment: showImage ? Alignment.bottomCenter : Alignment.topCenter, children: <Widget>[
        Column(children: <Widget>[
          Stack(alignment: showImage ? Alignment.bottomCenter : Alignment.topCenter, children: <Widget>[
            showImage? Positioned(child:
              InkWell(onTap: () => _onTapCardImage(widget.game.imageUrl!), child: Image.network(widget.game.imageUrl!, semanticLabel: "Sports",))
            ) : Container(),
            showImage ? Container(height: 72, color: Styles().colors!.fillColorSecondaryTransparent05,) : Container(height: 0)
          ],),
          showImage ? Container(height: 112, width: double.infinity, child:
            Styles().images?.getImage('slant', fit: BoxFit.fill, excludeFromSemantics: true),
          ) : Container(),
          showImage ? Container(height: 140, color: Styles().colors!.background,) : Container()
        ],),
        Padding(padding: widget.margin, child:
          Stack(alignment: Alignment.topCenter, children: [
            Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [const BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
              Padding(padding: EdgeInsets.only(bottom: ((showInterests && !isTicketedSport) ? 0 : 12)), child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Padding(padding: EdgeInsets.only(left: 20, right: 0), child:
                    Row(children: <Widget>[
                      Semantics(button: true, child:
                        GestureDetector(onTap: () => _onTapSportCategory(sport!), child:
                          Padding(padding: EdgeInsets.only(top:24), child:
                            Container(color: Styles().colors!.fillColorPrimary, child:
                              Padding(padding: EdgeInsets.all(5), child:
                                Text(sportName.toUpperCase(), style: Styles().textStyles?.getTextStyle('widget.colourful_button.title.regular.accent'),),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: Container(),),
                      Visibility(visible: Auth2().canFavorite, child:
                        GestureDetector(behavior: HitTestBehavior.opaque, onTap: _onTapSave, child:
                          Semantics(
                            label: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization().getStringEx( 'widget.card.button.favorite.on.title', 'Add To Favorites'),
                            hint: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx( 'widget.card.button.favorite.on.hint', ''),
                            excludeSemantics: true, child:
                            Padding(padding: EdgeInsets.only(right: 24, top: 24, left: 24, bottom: 8), child:
                              Styles().images?.getImage(isFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true)
                            ),
                          ),
                        ),
                      ),
                    ],),
                  ),
                  Padding(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), child:
                    Text(widget.game.title, style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat')),
                  ),
                  _athleticsDetails(),
                  Visibility(visible: showDescription, child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      _divider(),
                      Padding(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), child:
                        Text(description ?? '', style:Styles().textStyles?.getTextStyle('widget.card.detail.medium')),
                      )
                    ]),
                  ),
                  Visibility(visible: showInterests, child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Container(height: 1,color: Styles().colors!.surfaceAccent,),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Text(Localization().getStringEx('widget.card.label.interests', 'Because of your interest in:'), style: Styles().textStyles?.getTextStyle('widget.card.detail.tiny.fat')),
                          Text(StringUtils.ensureNotEmpty(interestsLabelValue), style: Styles().textStyles?.getTextStyle('widget.card.detail.tiny.medium_fat'),)
                        ],),
                      )
                    ],),
                  ),
                  Visibility(visible: isGetTicketsVisible, child:
                    Padding(padding: EdgeInsets.symmetric(horizontal: 20), child:
                      RoundedButton(
                        label: Localization().getStringEx('widget.athletics_card.button.get_tickets.title', 'Get Tickets'),
                        hint: Localization().getStringEx('widget.athletics_card.button.get_tickets.hint', ''),
                        textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
                        backgroundColor: Colors.white,
                        borderColor: Styles().colors!.fillColorSecondary,
                        onTap: _onTapGetTickets,
                      ),
                    ),
                  ),
                ],),
              ),
            ),
            !showImage ? Container(height: 7, color: Styles().colors!.fillColorPrimary) : Container(),
          ]),
        ),
      ],),
    );
  }

  void _onTapGetTickets() {
    Analytics().logSelect(
        target: "AthleticsCard:Item:${widget.game.title} -Get Tickets");
    if (PrivacyTicketsDialog.shouldConfirm) {
      PrivacyTicketsDialog.show(context, onContinueTap: () {
        _showTicketsPanel();
      });
    } else {
      _showTicketsPanel();
    }
  }

  void _onTapCardImage(String? url) {
    Analytics().logSelect(target: "Athletics Image");
    if (url != null) {
      Navigator.push(
          context,
          PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, _, __) =>
                  ModalImagePanel(imageUrl: url, onCloseAnalytics: () => Analytics().logSelect(target: "Close Image"))));
    }
  }

  void _showTicketsPanel() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: widget.game.links?.tickets)));
  }

  Widget _athleticsDetails() {
    List<Widget> details = [];

    Widget? time = _athleticsTimeDetail();
    if (time != null) {
      details.add(time);
    }

    Widget? location = _athleticsLocationDetail();
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

  Widget? _athleticsTimeDetail() {
    String? displayTime = widget.game.displayTime;
    if (StringUtils.isNotEmpty(displayTime)) {
      return Padding(
        padding: _detailPadding,
        child:Semantics(label:displayTime, excludeSemantics: true ,child: Row(
          children: <Widget>[
            Styles().images?.getImage('time', excludeFromSemantics: true) ?? Container(),
            Padding(
              padding: _iconPadding,
            ),
            Text(displayTime!,
                style: Styles().textStyles?.getTextStyle('widget.card.detail.medium')),
          ],
        )),
      );
    } else {
      return null;
    }
  }

  Widget? _athleticsLocationDetail() {
    String? locationText = widget.game.location?.location;
    if ((locationText != null) && locationText.isNotEmpty) {
      return Padding(
        padding: _detailPadding,
        child: Semantics(label:locationText, excludeSemantics: true ,child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Styles().images?.getImage('location', excludeFromSemantics: true) ?? Container(),
            Padding(
              padding: _iconPadding,
            ),
            Flexible(
                child: Text(locationText,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: Styles().textStyles?.getTextStyle('widget.card.detail.medium'))),
          ],
        )),
      );
    } else {
      return null;
    }
  }

  Widget _divider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0),
      child: Container(
        height: 1,
        color: Styles().colors!.fillColorPrimaryTransparent015,
      ),
    );
  }

  void _onTapSave() {
    Analytics().logSelect(target: "Favorite: ${widget.game.title}");
    Auth2().prefs?.toggleFavorite(widget.game);
  }

  void _onTapSportCategory(SportDefinition? sport) {
    Analytics().logSelect(target: "AthleticsCard:Item:${widget.game.title} -category: ${sport?.name}");
    if (sport != null) {
      if (Connectivity().isNotOffline) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsTeamPanel(sport)));
      }
      else {
        AppAlert.showOfflineMessage(context, Localization().getStringEx('widget.athletics_card.label.offline.sports', 'Sports are not available while offline.'));
      }
    }
  }

  String? _getInterestsLabelValue() {
    String? sportName = widget.game.sport?.shortName;
    bool isSportFavorite = Auth2().prefs?.hasSportInterest(sportName) ?? false;
    return isSportFavorite ? Sports().getSportByShortName(sportName)?.customName : null;
  }
}
