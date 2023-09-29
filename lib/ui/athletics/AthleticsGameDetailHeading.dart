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
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/livestats/LiveGame.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/LiveStats.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ext/Game.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/athletics/AthleticsRosterListPanel.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

class AthleticsGameDetailHeading extends StatefulWidget {
  final Game? game;
  final bool showImageTout;

  AthleticsGameDetailHeading({this.game, this.showImageTout = true});

  _AthleticsGameDetailHeadingState createState() => _AthleticsGameDetailHeadingState();
}

class _AthleticsGameDetailHeadingState extends State<AthleticsGameDetailHeading> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [
      LiveStats.notifyLiveGamesLoaded,
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
    if (name == LiveStats.notifyLiveGamesLoaded) {
      setStateIfMounted(() {});
    } else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted(() {});
    } else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    String? sportKey = widget.game?.sport?.shortName;
    String? sportName = widget.game?.sport?.title!;
    SportDefinition? sportDefinition = Sports().getSportByShortName(sportKey);
    bool isTicketedSport = sportDefinition?.ticketed ?? false;
    bool isMenBasketball = ('mbball' == sportKey);
    bool isHomeGame = widget.game?.isHomeGame ?? false;
    bool isGameDay = widget.game?.isGameDay ?? false;
    bool showOrderFoodAndDrink = (isMenBasketball && isHomeGame) || isGameDay;
    bool showGetTickets = isTicketedSport && (widget.game?.links?.tickets != null);
    bool showParking = widget.game?.parkingUrl != null;
    bool showGameDayGuide = (widget.game?.isHomeGame ?? false) && _hasGameDayGuide;
    bool hasScores = sportDefinition?.hasScores ?? false;
    bool hasLiveGame = (Storage().debugDisableLiveGameCheck == true) || LiveStats().hasLiveGame(widget.game?.id);
    bool showScore = hasScores && (widget.game?.isGameDay ?? false) && hasLiveGame;
    bool isGameFavorite = Auth2().isFavorite(widget.game);
    bool isUpcomingGame = widget.game?.isUpcoming ?? false;
    String? liveStatsUrl = widget.game?.links?.liveStats;
    String? audioUrl = widget.game?.links?.audio;
    String? videoUrl = widget.game?.links?.video;

    double wrapperHeight = 30;
    wrapperHeight += StringUtils.isNotEmpty(audioUrl) ? 48 : 0;
    wrapperHeight += StringUtils.isNotEmpty(videoUrl) ? 48 : 0;
    wrapperHeight += showOrderFoodAndDrink ? 48 : 0;
    wrapperHeight += showGetTickets || showParking ? 48 : 0;
    wrapperHeight += showGameDayGuide ? 48 : 0;
    wrapperHeight += showScore ? 155 : 0;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        Container(
          child: Column(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: _buildHeaderWidgets(),
                  ),
                  Container(
                    color: Styles().colors!.fillColorPrimary,
                    child: Padding(
                      padding: EdgeInsets.only(left: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                  color: Styles().colors!.whiteTransparent01,
                                  borderRadius: BorderRadius.all(Radius.circular(2)),
                                ),
                                
                                child: Semantics( header: true, excludeSemantics: true,
                                    label: sportName,
                                    child:Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                    child: Text(
                                      sportName?.toUpperCase() ?? '',
                                      style: Styles().textStyles?.getTextStyle("widget.title.light.small.fat.spaced")
                                    ),
                                  )),
                              ),
                              Expanded(
                                child: Container(),
                              ),
                              Visibility(
                                visible: (Auth2().canFavorite && isUpcomingGame),
                                child: Semantics(
                                  label: Localization().getStringEx("widget.game_detail_heading.button.save_game.title", "Save Game"),
                                  hint: Localization().getStringEx("widget.game_detail_heading.button.save_game.hint", "Tap to save"),
                                  button: true,
                                  checked: isGameFavorite,
                                  child: GestureDetector(
                                      child: Container(padding: EdgeInsets.only(right: 24, left: 10, bottom: 20, top: 20),
                                        child: Styles().images?.getImage(isGameFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true
                                      )),
                                      onTap: _onTapSwitchFavorite),
                                ),
                              )
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              widget.game?.title ?? '',
                              style: Styles().textStyles?.getTextStyle("widget.heading.huge.extra_fat"),
                            ),
                          ),
                          (!StringUtils.isEmpty(widget.game?.description)
                              ? Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    widget.game?.description ?? '',
                                    textAlign: TextAlign.left,
                                    style: Styles().textStyles?.getTextStyle("widget.athletics.heading.regular.fat.variant")
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.only(top: 16),
                                )),
                          Visibility(
                              visible: StringUtils.isNotEmpty(widget.game?.displayTime),
                              child: Semantics(
                                label: widget.game?.displayTime,
                                button: false,
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: <Widget>[
                                      Styles().images?.getImage('calendar', excludeFromSemantics: true) ?? Container(),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          widget.game?.displayTime ?? '',
                                          style: Styles().textStyles?.getTextStyle("widget.athletics.heading.regular.variant")
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              )),
                          Visibility(
                            visible: StringUtils.isNotEmpty(widget.game?.location?.location),
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 20),
                              child: Semantics(
                                label: widget.game?.location?.location ?? "",
                                button: false,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Styles().images?.getImage('location', excludeFromSemantics: true),
                                    ),
                                    Flexible(
                                        child: Text(
                                      widget.game?.location?.location ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: Styles().textStyles?.getTextStyle("widget.athletics.heading.regular.variant")
                                    ))
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Container(
                child: Semantics(excludeSemantics: true, child: Styles().images?.getImage('slant-dark', excludeFromSemantics: true)),
              ),
              Container(
                color: Styles().colors!.background,
                height: wrapperHeight,
              )
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(10.0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                showScore ? _createScoreBoard() : Container(),
                StringUtils.isEmpty(liveStatsUrl)
                    ? Container()
                    : _DetailRibbonButton(
                        iconKey: 'chart',
                        title: Localization().getStringEx('widget.game_detail_heading.button.live_stats.title', 'Live Stats'),
                        hint: Localization().getStringEx('widget.game_detail_heading.button.live_stats.hint', ''),
                        onTap: () {
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: liveStatsUrl)));
                        },
                      ),
                StringUtils.isEmpty(liveStatsUrl)
                    ? Container()
                    : Container(
                        color: Styles().colors!.fillColorPrimaryTransparent015,
                        height: 1,
                      ),
                StringUtils.isEmpty(audioUrl)
                    ? Container()
                    : _DetailRibbonButton(
                        iconKey: 'sound',
                        title: Localization().getStringEx('widget.game_detail_heading.button.listen.title', 'Listen'),
                        hint: Localization().getStringEx('widget.game_detail_heading.button.listen.hint', ''),
                        subTitle: widget.game?.radio,
                        onTap: () => _onTapListen(audioUrl),
                      ),
                StringUtils.isEmpty(audioUrl)
                    ? Container()
                    : Container(
                        color: Styles().colors!.fillColorPrimaryTransparent015,
                        height: 1,
                      ),
                StringUtils.isEmpty(videoUrl)
                    ? Container()
                    : _DetailRibbonButton(
                        iconKey: 'play-circle',
                        title: Localization().getStringEx('widget.game_detail_heading.button.watch.title', 'Watch'),
                        hint: Localization().getStringEx('widget.game_detail_heading.button.watch.hint', ''),
                        subTitle: widget.game?.tv,
                        onTap: () => _onTapWatch(videoUrl),
                      ),
                StringUtils.isEmpty(videoUrl)
                    ? Container()
                    : Container(
                        color: Styles().colors!.fillColorPrimaryTransparent015,
                        height: 1,
                      ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      Visibility(
                        visible: showGetTickets || showParking,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Visibility(
                              visible: showGetTickets,
                              child: Expanded(
                                child: RoundedButton(
                                  label: Localization().getStringEx('widget.game_detail_heading.button.get_tickets.title', 'Get Tickets'),
                                  hint: Localization().getStringEx('widget.game_detail_heading.button.get_tickets.hint', ''),
                                  textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
                                  backgroundColor: Colors.white,
                                  borderColor: Styles().colors!.fillColorSecondary,
                                  onTap: _onTapGetTickets,
                                ),
                              ),
                            ),
                            Visibility(
                              visible: (showGetTickets && showParking),
                              child: Padding(padding: EdgeInsets.only(right: 3)),
                            ),
                            Visibility(
                              visible: showParking,
                              child: Expanded(
                                child: RoundedButton(
                                    label: Localization().getStringEx('widget.game_detail_heading.button.parking.title', 'Parking'),
                                    hint: Localization().getStringEx('widget.game_detail_heading.button.parking.hint', ''),
                                    textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
                                    backgroundColor: Colors.white,
                                    borderColor: Styles().colors!.fillColorSecondary,
                                    onTap: _onTapParking),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: showGetTickets || showParking,
                        child: Padding(padding: EdgeInsets.only(bottom: 6)),
                      ),
                      Visibility(
                        visible: showGameDayGuide,
                        child: RoundedButton(
                          label: Localization().getStringEx('widget.game_detail_heading.button.game_day_guide.title', 'Game Day Guide'),
                          hint: Localization().getStringEx('widget.game_detail_heading.button.game_day_guide.hint', ''),
                          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
                          backgroundColor: Colors.white,
                          borderColor: Styles().colors!.fillColorSecondary,
                          onTap: () {
                            _onTapGameDayGuide();
                          },
                        ),
                      ),
                      Padding(padding: EdgeInsets.only(bottom: 6)),
                      RoundedButton(
                        label: Localization().getStringEx('widget.game_detail_heading.button.roster.title', 'Roster'),
                        hint: Localization().getStringEx('widget.game_detail_heading.button.roster.hint', ''),
                        textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
                        backgroundColor: Colors.white,
                        borderColor: Styles().colors!.fillColorSecondary,
                        onTap: () {
                          Analytics().logSelect(target: "Roster");
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsRosterListPanel(sportDefinition, null)));
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _createScoreBoard() {
    String? sport = widget.game?.sport?.shortName;
    switch (sport) {
      case "football":
        {
          return _FootballScoreWidget(game: widget.game);
        }
      case "mbball":
        {
          return _BasketballScoreWidget(game: widget.game);
        }
      case "wbball":
        {
          return _BasketballScoreWidget(game: widget.game);
        }
      case "wvball":
        {
          return _VolleyballScoreWidget(game: widget.game);
        }
      default:
        {
          return _SportScoreWidget(game: widget.game);
        }
    }
  }

  List<Widget> _buildHeaderWidgets() {
    List<Widget> widgets = [];
    if(widget.showImageTout) {
      if (!StringUtils.isEmpty(widget.game?.imageUrl)) {
        widgets.add(Positioned(
            child: ModalImageHolder(
                child: Image.network(widget.game!.imageUrl!,
              semanticLabel: widget.game?.sport?.title ?? "sport",
            ))));
      }
      widgets.add(Semantics(
          excludeSemantics: true,
          child: CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors!.fillColorPrimary),
            child: Container(
              height: 60,
            ),
          )));
    }
    else{
      widgets.add(Container());
    }
    return widgets;
  }

  void _onTapSwitchFavorite() {
    Analytics().logSelect(target: "Favorite: ${widget.game?.title}");
    Auth2().prefs?.toggleFavorite(widget.game);
  }

  void _onTapGetTickets() {
    Analytics().logSelect(target: "Get Tickets");

    if (PrivacyTicketsDialog.shouldConfirm) {
      PrivacyTicketsDialog.show(context, onContinueTap: () {
        _showTicketsPanel();
      });
    } else {
      _showTicketsPanel();
    }
  }

  void _showTicketsPanel() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: widget.game?.links!.tickets)));
  }

  void _onTapParking() {
    Analytics().logSelect(target: "Parking");

    Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: widget.game?.parkingUrl)));
  }

  void _onTapGameDayGuide() {
    Analytics().logSelect(target: "Game Day");
    String? url = _gameDayGuideUrl;
    if (url != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
    }
  }

  void _onTapListen(String? audioUrl) {
    Analytics().logSelect(target: "Listen");
    if (StringUtils.isNotEmpty(audioUrl)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: audioUrl)));
    }
  }

  void _onTapWatch(String? videoUrl) {
    Analytics().logSelect(target: "Watch");
    if (StringUtils.isNotEmpty(videoUrl)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: videoUrl)));
    }
  }

  String? get _gameDayGuideUrl {
    String? sportKey = widget.game?.sport?.shortName;
    return Sports.getGameDayGuideUrl(sportKey);
  }

  bool get _hasGameDayGuide {
    return StringUtils.isNotEmpty(_gameDayGuideUrl);
  }
}

///
/// _DetailRibbonButton
///
class _DetailRibbonButton extends StatelessWidget {
  final String iconKey;
  final String? title;
  final String? subTitle;
  final String? hint;
  final GestureTapCallback? onTap;

  _DetailRibbonButton({required this.iconKey, required this.title, this.subTitle = '', this.hint = '', this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
        label: title,
        hint: hint,
        button: true,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 28+ 16* MediaQuery.of(context).textScaleFactor,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Styles().images?.getImage(iconKey, excludeFromSemantics: true) ?? Container(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      title!,
                      style: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat")
                  )),
                  Expanded(
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                  Visibility(
                      child: Text(
                        (!StringUtils.isEmpty(subTitle) ? subTitle! : ''),
                        style: Styles().textStyles?.getTextStyle("widget.button.light.title.medium")
                      ))
                ],
              ),
            ),
          ),
        ));
  }
}

///
/// _SportScoreWidget
///
class _SportScoreWidget extends StatefulWidget {
  final Game? _game;

  _SportScoreWidget({required Game? game}) : _game = game;

  @override
  _SportScoreWidgetState createState() => _SportScoreWidgetState();
}

class _SportScoreWidgetState extends State<_SportScoreWidget> implements NotificationsListener {
  late LiveStats _livestatsLogic;
  LiveGame? _currentLiveGame;

  _SportScoreWidgetState() {
    _livestatsLogic = LiveStats();
  }

  @override
  void initState() {
    NotificationService().subscribe(this, [
      LiveStats.notifyLiveGamesLoaded,
      LiveStats.notifyLiveGamesUpdated,
    ]);

    LiveGame? liveGame = _livestatsLogic.getLiveGame(widget._game!.id);
    _setCurrentData(liveGame);

    _livestatsLogic.addTopic(widget._game!.sport!.shortName);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _livestatsLogic.removeTopic(widget._game!.sport!.shortName);
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 5),
      child: Column(
        children: <Widget>[
          _buildTopSection(),
          Padding(padding: EdgeInsets.only(bottom: 6)),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      height: 48,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _currentLiveGame != null ? _formatPeriod(_currentLiveGame!.period!) : "-",
                style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.transparent,
              ),
            ),
            Text(
              _currentLiveGame != null ? _formatClock(_currentLiveGame!.clockSeconds!) : "-",
              style: Styles().textStyles?.getTextStyle("widget.item.regular")
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeriod(int period) {
    if (period <= 0) return "";

    return _convertToOrdinal(period) + " " + _getPeriodName()!;
  }

  String? _getPeriodName() {
    String? shortName = widget._game!.sport!.shortName;
    if (shortName == "football") {
      return Localization().getStringEx("widget.score.period.quarter", "Quarter");
    } else if (shortName == "mbball") {
      return Localization().getStringEx("widget.score.period.half", "Half");
    } else if (shortName == "wbball") {
      return Localization().getStringEx("widget.score.period.quarter", "Quarter");
    } else if (shortName == "mvball" || shortName == "wvball") {
      return Localization().getStringEx("widget.score.period.set", "Set");
    } else if (shortName == "mtennis" || shortName == "wtennis") {
      return Localization().getStringEx("widget.score.period.set", "Set");
    } else if (shortName == "baseball" || shortName == "softball") {
      return Localization().getStringEx("widget.score.period.inning", "Inning");
    } else if (shortName == "wsoc") {
      return Localization().getStringEx("widget.score.period.half", "Half");
    } else {
      return Localization().getStringEx("widget.score.period.period", "Period");
    }
  }

  String _convertToOrdinal(int? period) {
    switch (period) {
      case 1:
        return "1st";
      case 2:
        return "2nd";
      case 3:
        return "3rd";
      default:
        return period.toString() + "th";
    }
  }

  String _formatClock(int seconds) {
    if (seconds < 0) return "";

    final format = new DateFormat('mm:ss');
    return format.format(new DateTime.fromMillisecondsSinceEpoch(seconds * 1000));
  }

  Widget _buildBottomSection() {
    return Container(
        height: 68,
        color: Styles().colors!.background,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[_buildHomeSection(), _buildAwaySection()],
        ));
  }

  Widget _buildHomeSection() {
    return Expanded(
      child: Container(
        decoration: new BoxDecoration(
            border: Border(
              left: BorderSide(width: 1, color: Styles().colors!.fillColorPrimaryTransparent015!),
              right: BorderSide(width: 0.5, color: Styles().colors!.fillColorPrimaryTransparent015!),
              top: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
              bottom: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
            )),
        height: 68,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: _getHomeImage()),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Text(
                _currentLiveGame != null ? _currentLiveGame!.homeScore.toString() : "-",
                style: Styles().textStyles?.getTextStyle("widget.title.huge"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getHomeImage() {
    if (widget._game!.isHomeGame) {
      //return illinois image
      return Styles().images?.getImage('university-logo', excludeFromSemantics: true) ?? Container();
    } else {
      //return opponent image
      Opponent? opponent = widget._game!.opponent;
      String? opponentUrl = opponent != null ? opponent.logoImage : null;
      if(StringUtils.isNotEmpty(opponentUrl)) {
        return ModalImageHolder(child: Image.network(opponentUrl!, excludeFromSemantics: true));
      } else {
        return Container();
      }
    }
  }

  Widget _buildAwaySection() {
    return Expanded(
      child: Container(
        decoration: new BoxDecoration(
            border: Border(
              left: BorderSide(width: 0.5, color: Styles().colors!.fillColorPrimaryTransparent015!),
              right: BorderSide(width: 0.5, color: Styles().colors!.fillColorPrimaryTransparent015!),
              top: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
              bottom: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
            )),
        height: 68,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                _currentLiveGame != null ? _currentLiveGame!.visitingScore.toString() : "-",
                style: Styles().textStyles?.getTextStyle("widget.title.huge")
              ),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: _getAwayImage(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getAwayImage() {
    if (!widget._game!.isHomeGame) {
      //return illinois image
      return Styles().images?.getImage('university-logo', excludeFromSemantics: true) ?? Container();
    } else {
      //return opponent image
      Opponent? opponent = widget._game!.opponent;
      String? opponentUrl = opponent != null ? opponent.logoImage : null;
      if(StringUtils.isNotEmpty(opponentUrl)) {
        return ModalImageHolder(child: Image.network(opponentUrl!, excludeFromSemantics: true));
      } else {
        return Container();
      }
    }
  }

  void _setCurrentData(LiveGame? liveGame) {
    setState(() {
      _currentLiveGame = liveGame;
    });
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == LiveStats.notifyLiveGamesLoaded) {
      _onLiveGamesLoaded();
    } else if (name == LiveStats.notifyLiveGamesUpdated) {
      _onLiveGameUpdated(param);
    }
  }

  void _onLiveGamesLoaded() {
    setState(() {
      _setCurrentData(_livestatsLogic.getLiveGame(widget._game!.id));
    });
  }

  void _onLiveGameUpdated(LiveGame? liveGame) {
    if ((liveGame != null) && (widget._game!.id == liveGame.gameId)) {
      _setCurrentData(liveGame);
    }
  }
}

///
/// _VolleyballScoreWidget
///
class _VolleyballScoreWidget extends _SportScoreWidget {

  _VolleyballScoreWidget({required Game? game}) : super(game: game);

  @override
  _VolleyballScoreWidgetState createState() => _VolleyballScoreWidgetState();
}

class _VolleyballScoreWidgetState extends _SportScoreWidgetState {

  _VolleyballScoreWidgetState() : super();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return _hasExtraData() == true ? _createRichContent(width, height) : _createLiteContent(width, height);
  }

  bool? _hasExtraData() {
    if (_currentLiveGame == null) return false;

    dynamic customData = _currentLiveGame!.custom;
    if (StringUtils.isEmpty(customData)) return false;

    Map<String, dynamic>? mapCustomData = JsonUtils.decode(customData);
    if (mapCustomData == null) {
      return null;
    }
    return mapCustomData["HasExtraData"];
  }

  Widget _createLiteContent(double width, double height) {
    String period = _getPeriod();
    String homeScore = _getHomeScore();
    String visitingScore = _getVisitingScore();
    Widget? homeImage = _getHomeImageFrom(width, height);
    Widget? visitingImage = _getVisitingImage(width, height);
    return _LiteContent(period: period, homeScore: homeScore, visitingScore: visitingScore, homeImage: homeImage, visitingImage: visitingImage);
  }

  String _getPeriod() {
    if (_currentLiveGame == null) return "-";
    int period = _currentLiveGame!.period!;
    if (period <= 0) return "";

    return _convertToOrdinal(period) + " " + Localization().getStringEx("widget.score.period.set", "Set");
  }

  String _getHomeScore() {
    if (_currentLiveGame == null) return "-";

    return _currentLiveGame!.homeScore.toString();
  }

  String _getVisitingScore() {
    if (_currentLiveGame == null) return "-";

    return _currentLiveGame!.visitingScore.toString();
  }

  Widget? _getHomeImageFrom(double width, double height) {
    if (widget._game!.isHomeGame) {
      //return illinois image
      return Styles().images?.getImage('university-logo', fit: BoxFit.fitHeight);
    } else {
      //return opponent image
      String? opponentUrl = widget._game!.opponent?.logoImage;
      return StringUtils.isNotEmpty(opponentUrl) ? ModalImageHolder(child: Image.network(opponentUrl!, excludeFromSemantics: true)) : null;
    }
  }

  Widget? _getVisitingImage(double width, double height) {
    if (!widget._game!.isHomeGame) {
      //return illinois image
      return Styles().images?.getImage('university-logo', fit: BoxFit.fitHeight);
    } else {
      //return opponent image
      String? opponentUrl = widget._game?.opponent?.logoImage;
      return StringUtils.isNotEmpty(opponentUrl) ? ModalImageHolder(child: Image.network(opponentUrl!, excludeFromSemantics: true)) : null;
    }
  }

  Widget _createRichContent(double width, double height) {
    if (_currentLiveGame == null) return Container();

    dynamic customData = _currentLiveGame!.custom;
    if (StringUtils.isEmpty(customData)) return Container();

    Map<String, dynamic>? mapCustomData = JsonUtils.decode(customData);
    if (mapCustomData == null) return Container();

    String? phase = mapCustomData["Phase"];
    String? phaseLabel = mapCustomData["PhaseLabel"];
    String? hScore = mapCustomData["HScore"];
    String? vScore = mapCustomData["VScore"];
    String? hPoints = mapCustomData["HPoints"];
    String? vPoints = mapCustomData["VPoints"];
    String? serving = mapCustomData["Serving"];
    Widget? homeImage = _getHomeImageFrom(width, height);
    Widget? visitingImage = _getVisitingImage(width, height);
    return _RichContent(
      phase: phase,
      phaseLabel: phaseLabel,
      hScore: hScore,
      vScore: vScore,
      hPoints: hPoints,
      vPoints: vPoints,
      serving: serving,
      homeImage: homeImage,
      visitingImage: visitingImage,
    );
  }
}

// Basic UI data
class _LiteContent extends StatelessWidget {
  final String _period;
  final String _homeScore;
  final String _visitingScore;
  final Widget? _homeImage;
  final Widget? _visitingImage;

  _LiteContent({required String period, required String homeScore, required String visitingScore, Widget? homeImage, Widget? visitingImage})
      : _period = period,
        _homeScore = homeScore,
        _visitingScore = visitingScore,
        _homeImage = homeImage,
        _visitingImage = visitingImage;

  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 5),
      child: Column(
        children: <Widget>[
          _buildTopSection(),
          Padding(padding: EdgeInsets.only(bottom: 6)),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      height: 48,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _period,
                style: Styles().textStyles?.getTextStyle("widget.detail.regular.fat")
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.transparent,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
        height: 68,
        color: Styles().colors!.background,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[_buildHomeSection(), _buildAwaySection()],
        ));
  }

  Widget _buildHomeSection() {
    return Expanded(
      child: Container(
        decoration: new BoxDecoration(
            border: Border(
              left: BorderSide(width: 1, color: Styles().colors!.fillColorPrimaryTransparent015!),
              right: BorderSide(width: 0.5, color: Styles().colors!.fillColorPrimaryTransparent015!),
              top: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
              bottom: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
            )),
        height: 68,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: _homeImage ?? Container(width: 22, height: 32)),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Text(_homeScore, style: Styles().textStyles?.getTextStyle("widget.title.huge")),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAwaySection() {
    return Expanded(
      child: Container(
        decoration: new BoxDecoration(
            border: Border(
              left: BorderSide(width: 0.5, color: Styles().colors!.fillColorPrimaryTransparent015!),
              right: BorderSide(width: 0.5, color: Styles().colors!.fillColorPrimaryTransparent015!),
              top: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
              bottom: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
            )),
        height: 68,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(_visitingScore, style: Styles().textStyles?.getTextStyle("widget.title.huge")),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: _visitingImage ?? Container(width: 22, height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Richer UI data containing more game details
class _RichContent extends StatelessWidget {
  final String? _phase;
  final String? _phaseLabel;
  final String? _hScore;
  final String? _vScore;
  final String? _hPoints;
  final String? _vPoints;
  final String? _serving;
  final Widget? _homeImage;
  final Widget? _visitingImage;

  _RichContent(
      {required String? phase,
        required String? phaseLabel,
        required String? hScore,
        required String? vScore,
        required String? hPoints,
        required String? vPoints,
        required String? serving,
        Widget? homeImage,
        Widget? visitingImage})
      : _phase = phase,
        _phaseLabel = phaseLabel,
        _hScore = hScore,
        _vScore = vScore,
        _hPoints = hPoints,
        _vPoints = vPoints,
        _serving = serving,
        _homeImage = homeImage,
        _visitingImage = visitingImage;

  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 5),
      child: Column(
        children: <Widget>[
          _buildTopSection(),
          Padding(padding: EdgeInsets.only(bottom: 6)),
          _buildBottomSection(context),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      height: 48,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _phaseLabel!,
                style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.transparent,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Container(
        height: 68,
        color: Styles().colors!.background,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[_buildHomeSection(context), _buildVisitingSection(context)],
        ));
  }

  Widget _buildHomeSection(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double outerPadding = width * 0.038;
    return Expanded(
      child: Container(
        decoration: new BoxDecoration(
            border: Border(
              left: BorderSide(width: 1, color: Styles().colors!.fillColorPrimaryTransparent015!),
              right: BorderSide(width: 0.5, color: Styles().colors!.fillColorPrimaryTransparent015!),
              top: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
              bottom: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
            )),
        height: 68,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: outerPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: _homeImage ?? Container(width: 22, height: 32)),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              _buildHomeScore()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeScore() {
    bool duringGame = _phase != "pre" && _phase != "final";
    bool serving = _serving == "H";
    return duringGame
        ? Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Text(_hPoints!, style: Styles().textStyles?.getTextStyle("widget.title.huge")),
        SizedBox(width: 15),
        Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Visibility(
                visible: serving,
                child: _ServingControl(home: true),
              ),
              Text(_hScore!, style: Styles().textStyles?.getTextStyle("widget.title.extra_large"))
            ],
          ),
        ),
      ],
    )
        : Text(_hScore!, style: Styles().textStyles?.getTextStyle("widget.title.huge"));
  }

  Widget _buildVisitingSection(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double outerPadding = width * 0.038;
    return Expanded(
      child: Container(
        decoration: new BoxDecoration(
            border: Border(
              left: BorderSide(width: 0.5, color: Styles().colors!.fillColorPrimaryTransparent015!),
              right: BorderSide(width: 0.5, color: Styles().colors!.fillColorPrimaryTransparent015!),
              top: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
              bottom: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
            )),
        height: 68,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: outerPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              _buildVisitingScore(),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: _visitingImage ?? Container(width: 22, height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitingScore() {
    bool duringGame = _phase != "pre" && _phase != "final";
    bool serving = _serving == "V";
    return duringGame
        ? Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Visibility(
                visible: serving,
                child: _ServingControl(home: false),
              ),
              Text(_vScore!, style: Styles().textStyles?.getTextStyle("widget.title.extra_large"))
            ],
          ),
        ),
        SizedBox(width: 15),
        Text(_vPoints!, style: Styles().textStyles?.getTextStyle("widget.title.huge")),
      ],
    )
        : Text(_vScore!, style: Styles().textStyles?.getTextStyle("widget.title.huge"));
  }
}

class _ServingControl extends StatelessWidget {
  final bool _home;

  _ServingControl({required bool home}) : _home = home;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(14, 14), painter: _ArrowPainter(_home));
  }
}

class _ArrowPainter extends CustomPainter {
  late Paint _paint;
  late bool _home;

  _ArrowPainter(bool home) {
    _home = home;
    _paint = Paint()
      ..color = Color(0xffEAC738)
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();
    if (_home) {
      //left arrow
      path.moveTo(0, size.height / 2);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      //right arrow
      path.moveTo(size.width, size.height / 2);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
      path.close();
    }
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

///
/// _FootballScoreWidget
///
class _FootballScoreWidget extends _SportScoreWidget {
  _FootballScoreWidget({required Game? game}) : super(game: game);

  @override
  _FootballScoreWidgetState createState() => _FootballScoreWidgetState();
}

class _FootballScoreWidgetState extends _SportScoreWidgetState {

  _FootballScoreWidgetState() : super();

  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildTopSection(),
          Padding(padding: EdgeInsets.only(bottom: 6)),
          _buildMiddleSection(),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      height: 48,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _currentLiveGame != null ? _getPhase() : "-",
                style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.transparent,
              ),
            ),
            Text(
              _currentLiveGame != null ? _getClock() : "-",
              style: Styles().textStyles?.getTextStyle("widget.item.regular"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiddleSection() {
    String? possession = _getPossession();
    return Container(
        height: 68,
        color: Styles().colors!.background,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[_buildHomeSectionWithPossession(possession), _buildAwaySectionWithPossesion(possession)],
        ));
  }

  Widget _buildHomeSectionWithPossession(String? possession) {
    bool isHomePossession = (possession == "H");
    return Expanded(
      child: Container(
        decoration: new BoxDecoration(
            border: Border(
              left: BorderSide(width: 1, color: Styles().colors!.fillColorPrimaryTransparent015!),
              right: BorderSide(width: 0.5, color: Styles().colors!.fillColorPrimaryTransparent015!),
              top: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
              bottom: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
            )),
        height: 68,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: _getHomeImage()),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Visibility(
                visible: isHomePossession,
                child: Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: Styles().images?.getImage('football', excludeFromSemantics: true),
                ),
              ),
              Text(
                _currentLiveGame != null ? _currentLiveGame!.homeScore.toString() : "-",
                style: Styles().textStyles?.getTextStyle("widget.title.huge"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAwaySectionWithPossesion(String? possession) {
    bool isVisitingPossession = possession == "V";
    return Expanded(
      child: Container(
        decoration: new BoxDecoration(
            border: Border(
              left: BorderSide(width: 0.5, color: Styles().colors!.fillColorPrimaryTransparent015!),
              right: BorderSide(width: 0.5, color: Styles().colors!.fillColorPrimaryTransparent015!),
              top: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
              bottom: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
            )),
        height: 68,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                _currentLiveGame != null ? _currentLiveGame!.visitingScore.toString() : "-",
                style: Styles().textStyles?.getTextStyle("widget.title.huge"),
              ),
              Visibility(
                visible: isVisitingPossession,
                child: Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Styles().images?.getImage('football', excludeFromSemantics: true),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: _getAwayImage(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    String? lastPlay = _getLastPlay();
    bool hasLastPlay = StringUtils.isNotEmpty(lastPlay);
    return hasLastPlay
        ? Container(
        decoration: new BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
            )),
        child: Padding(
          padding: EdgeInsets.only(top: 6, bottom: 6, left: 20, right: 20),
          child: Text(sprintf(Localization().getStringEx('widget.score.last_play', 'Last Play: %s'), [lastPlay]), textAlign: TextAlign.left, style: Styles().textStyles?.getTextStyle("widget.detail.regular")),
        ))
        : Container();
  }

  String? _getLastPlay() {
    if (StringUtils.isEmpty(_currentLiveGame?.custom)) return null;

    Map<String, dynamic>? mapCustomData = JsonUtils.decode(_currentLiveGame!.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["LastPlay"];
  }

  String? _getPossession() {
    if (StringUtils.isEmpty(_currentLiveGame?.custom)) return null;

    Map<String, dynamic>? mapCustomData = JsonUtils.decode(_currentLiveGame!.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["Possession"];
  }

  String _getClock() {
    String? customClock = _getCustomClock();
    //empty value is valid
    if (customClock != null) return customClock;

    //return regular clock
    return _getRegularClock();
  }

  String _getRegularClock() {
    if (_currentLiveGame!.clockSeconds! < 0) return "";

    final format = new DateFormat('mm:ss');
    return format.format(new DateTime.fromMillisecondsSinceEpoch(_currentLiveGame!.clockSeconds! * 1000));
  }

  String? _getCustomClock() {
    if (StringUtils.isEmpty(_currentLiveGame!.custom)) return null;

    Map<String, dynamic>? mapCustomData = JsonUtils.decode(_currentLiveGame!.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["Clock"];
  }

  String _getPhase() {
    String? customPhase = _getCustomPhase();
    //empty value is valid
    if (customPhase != null) return customPhase;

    //return regular clock
    return _getPeriod();
  }

  String? _getCustomPhase() {
    if (StringUtils.isEmpty(_currentLiveGame!.custom)) return null;

    Map<String, dynamic>? mapCustomData = JsonUtils.decode(_currentLiveGame!.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["Phase"];
  }

  String _getPeriod() {
    if (_currentLiveGame!.period! <= 0) return "";

    return _convertToOrdinal(_currentLiveGame!.period) + " " + Localization().getStringEx("widget.score.period.quarter", "Quarter");
  }
}

///
/// _BasketballScoreWidget
///
class _BasketballScoreWidget extends _SportScoreWidget {

  _BasketballScoreWidget({required Game? game}) : super(game: game);

  @override
  _BasketballScoreWidgetState createState() => _BasketballScoreWidgetState();
}

class _BasketballScoreWidgetState extends _SportScoreWidgetState {

  _BasketballScoreWidgetState() : super();

  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildTopSection(),
          Padding(padding: EdgeInsets.only(bottom: 6)),
          _buildMiddleSection(),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      height: 48,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _currentLiveGame != null ? _getPhase() : "-",
                style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.transparent,
              ),
            ),
            Text(
              _currentLiveGame != null ? _getClock() : "-",
              style: Styles().textStyles?.getTextStyle("widget.item.regular"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiddleSection() {
    return Container(
        height: 68,
        color: Styles().colors!.background,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[_buildHomeSection(), _buildAwaySection()],
        ));
  }

  Widget _buildBottomSection() {
    String? lastPlay = _getLastPlay();
    bool hasLastPlay = StringUtils.isNotEmpty(lastPlay);
    return hasLastPlay
        ? Container(
        decoration: new BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 1.0, color: Styles().colors!.fillColorPrimaryTransparent015!),
            )),
        child: Padding(
          padding: EdgeInsets.only(top: 6, bottom: 6, left: 20, right: 20),
          child: Text("Last Play: " + lastPlay!, textAlign: TextAlign.left, style: Styles().textStyles?.getTextStyle("widget.detail.regular")),
        ))
        : Container();
  }

  String? _getLastPlay() {
    if (StringUtils.isEmpty(_currentLiveGame?.custom)) return null;

    Map<String, dynamic>? mapCustomData = JsonUtils.decode(_currentLiveGame!.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["LastPlay"];
  }

  String _getClock() {
    String? customClock = _getCustomClock();
    //empty value is valid
    if (customClock != null) return customClock;

    //return regular clock
    return _getRegularClock();
  }

  String _getRegularClock() {
    if (_currentLiveGame!.clockSeconds! < 0) return "";

    final format = new DateFormat('mm:ss');
    return format.format(new DateTime.fromMillisecondsSinceEpoch(_currentLiveGame!.clockSeconds! * 1000));
  }

  String? _getCustomClock() {
    if (StringUtils.isEmpty(_currentLiveGame!.custom)) return null;

    Map<String, dynamic>? mapCustomData = JsonUtils.decode(_currentLiveGame!.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["Clock"];
  }

  String _getPhase() {
    String? customPhase = _getCustomPhase();
    //empty value is valid
    if (customPhase != null) return customPhase;

    //return regular clock
    return _getPeriod();
  }

  String? _getCustomPhase() {
    if (StringUtils.isEmpty(_currentLiveGame!.custom)) return null;

    Map<String, dynamic>? mapCustomData = JsonUtils.decode(_currentLiveGame!.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["Phase"];
  }

  String _getPeriod() {
    if (_currentLiveGame!.period! <= 0) {
      return "";
    }
    String? shortName = widget._game!.sport!.shortName;
    String periodName = (shortName == "mbball") ? Localization().getStringEx("widget.score.period.half", "Half") : Localization().getStringEx(
        "widget.score.period.quarter", "Quarter");
    return _convertToOrdinal(_currentLiveGame!.period) + " " + periodName;
  }

}