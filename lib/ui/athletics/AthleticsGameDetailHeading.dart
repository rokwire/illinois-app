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
import 'package:illinois/model/livestats/LiveGame.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/service/LiveStats.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/athletics/AthleticsRosterListPanel.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

class AthleticsGameDetailHeading extends StatefulWidget {
  final Game game;
  final bool showImageTout;

  AthleticsGameDetailHeading({this.game, this.showImageTout = true});

  _AthleticsGameDetailHeadingState createState() => _AthleticsGameDetailHeadingState();
}

class _AthleticsGameDetailHeadingState extends State<AthleticsGameDetailHeading> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [LiveStats.notifyLiveGamesLoaded, User.notifyFavoritesUpdated]);
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
      setState(() {});
    } else if (name == User.notifyFavoritesUpdated) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    String sportKey = widget.game.sport?.shortName;
    String sportName = widget.game.sport?.title;
    SportDefinition sportDefinition = Sports().getSportByShortName(sportKey);
    bool isTicketedSport = (sportDefinition != null) ? sportDefinition.ticketed : false;
    bool isMenBasketball = ('mbball' == sportKey);
    bool isHomeGame = widget.game.isHomeGame;
    bool isGameDay = widget.game.isGameDay;
    bool showOrderFoodAndDrink = (isMenBasketball && isHomeGame) || isGameDay;
    bool showGetTickets = isTicketedSport && (widget.game.links?.tickets != null);
    bool showParking = widget.game.parkingUrl != null;
    bool showGameDayGuide = widget.game.isHomeGame;
    bool hasScores = sportDefinition.hasScores;
    bool hasLiveGame = Storage().debugDisableLiveGameCheck ? true : LiveStats().hasLiveGame(widget.game.id);
    bool showScore = hasScores && widget.game.isGameDay && hasLiveGame;
    bool isGameSaved = User().isFavorite(widget.game);
    String liveStatsUrl = widget.game?.links?.liveStats;
    String audioUrl = widget.game?.links?.audio;
    String videoUrl = widget.game?.links?.video;

    double wrapperHeight = 30;
    wrapperHeight += AppString.isStringNotEmpty(audioUrl) ? 48 : 0;
    wrapperHeight += AppString.isStringNotEmpty(videoUrl) ? 48 : 0;
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
                    color: Styles().colors.fillColorPrimary,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                  color: Styles().colors.whiteTransparent01,
                                  borderRadius: BorderRadius.all(Radius.circular(2)),
                                ),
                                
                                child: Semantics( header: true, excludeSemantics: true,
                                    label: sportName,
                                    child:Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                    child: Text(
                                      sportName.toUpperCase(),
                                      style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 14, letterSpacing: 1.0, color: Colors.white),
                                    ),
                                  )),
                              ),
                              Expanded(
                                child: Container(),
                              ),
                              Visibility(
                                visible: User().favoritesStarVisible,
                                child: Semantics(
                                  label: Localization().getStringEx("widget.game_detail_heading.button.save_game.title", "Save Game"),
                                  hint: Localization().getStringEx("widget.game_detail_heading.button.save_game.hint", ""),
                                  button: true,
                                  checked: isGameSaved,
                                  child: GestureDetector(
                                      child: Image.asset(
                                        isGameSaved ? 'images/icon-star-solid.png' : 'images/icon-star-white.png',
                                      ),
                                      onTap: _onTapSaveGame),
                                ),
                              )
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              widget.game.title,
                              style: TextStyle(fontSize: 32, color: Colors.white),
                            ),
                          ),
                          (!AppString.isStringEmpty(widget.game.longDescription)
                              ? Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    widget.game.longDescription,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(fontFamily: Styles().fontFamilies.bold, color: Styles().colors.whiteTransparent06, fontSize: 16),
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.only(top: 16),
                                )),
                          Visibility(
                              visible: AppString.isStringNotEmpty(widget.game.displayTime),
                              child: Semantics(
                                label: widget.game.displayTime,
                                button: false,
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: <Widget>[
                                      Image.asset('images/icon-calendar.png'),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          widget.game.displayTime,
                                          style: TextStyle(fontFamily: Styles().fontFamilies.medium, color: Styles().colors.whiteTransparent06, fontSize: 16),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              )),
                          Visibility(
                            visible: AppString.isStringNotEmpty(widget?.game?.location?.location),
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 20),
                              child: Semantics(
                                label: widget.game.location?.location ?? "",
                                button: false,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Image.asset('images/icon-location.png'),
                                    ),
                                    Flexible(
                                        child: Text(
                                      widget.game.location?.location,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(fontFamily: Styles().fontFamilies.medium, color: Styles().colors.whiteTransparent06, fontSize: 16),
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
                child: Semantics(excludeSemantics: true, child: Image.asset('images/2.0x/slant-down-right-blue.png', color: Styles().colors.fillColorPrimary,)),
              ),
              Container(
                color: Styles().colors.background,
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
                AppString.isStringEmpty(liveStatsUrl)
                    ? Container()
                    : _DetailRibbonButton(
                        iconResource: 'images/icon-live-stats.png',
                        title: Localization().getStringEx('widget.game_detail_heading.button.live_stats.title', 'Live Stats'),
                        hint: Localization().getStringEx('widget.game_detail_heading.button.live_stats.hint', ''),
                        onTap: () {
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: liveStatsUrl)));
                        },
                      ),
                AppString.isStringEmpty(liveStatsUrl)
                    ? Container()
                    : Container(
                        color: Styles().colors.fillColorPrimaryTransparent015,
                        height: 1,
                      ),
                AppString.isStringEmpty(audioUrl)
                    ? Container()
                    : _DetailRibbonButton(
                        iconResource: 'images/icon-listen.png',
                        title: Localization().getStringEx('widget.game_detail_heading.button.listen.title', 'Listen'),
                        hint: Localization().getStringEx('widget.game_detail_heading.button.listen.hint', ''),
                        subTitle: widget.game?.radio,
                        onTap: () => _onTapListen(audioUrl),
                      ),
                AppString.isStringEmpty(audioUrl)
                    ? Container()
                    : Container(
                        color: Styles().colors.fillColorPrimaryTransparent015,
                        height: 1,
                      ),
                AppString.isStringEmpty(videoUrl)
                    ? Container()
                    : _DetailRibbonButton(
                        iconResource: 'images/icon-watch.png',
                        title: Localization().getStringEx('widget.game_detail_heading.button.watch.title', 'Watch'),
                        hint: Localization().getStringEx('widget.game_detail_heading.button.watch.hint', ''),
                        subTitle: widget.game?.tv,
                        onTap: () => _onTapWatch(videoUrl),
                      ),
                AppString.isStringEmpty(videoUrl)
                    ? Container()
                    : Container(
                        color: Styles().colors.fillColorPrimaryTransparent015,
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
                                child: ScalableRoundedButton(
                                  label: Localization().getStringEx('widget.game_detail_heading.button.get_tickets.title', 'Get Tickets'),
                                  hint: Localization().getStringEx('widget.game_detail_heading.button.get_tickets.hint', ''),
                                  backgroundColor: Colors.white,
                                  fontSize: 16.0,
                                  textColor: Styles().colors.fillColorPrimary,
                                  borderColor: Styles().colors.fillColorSecondary,
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
                                child: ScalableRoundedButton(
                                    label: Localization().getStringEx('widget.game_detail_heading.button.parking.title', 'Parking'),
                                    hint: Localization().getStringEx('widget.game_detail_heading.button.parking.hint', ''),
                                    backgroundColor: Colors.white,
                                    fontSize: 16.0,
                                    textColor: Styles().colors.fillColorPrimary,
                                    borderColor: Styles().colors.fillColorSecondary,
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
                        child: ScalableRoundedButton(
                          label: Localization().getStringEx('widget.game_detail_heading.button.game_day_guide.title', 'Game Day Guide'),
                          hint: Localization().getStringEx('widget.game_detail_heading.button.game_day_guide.hint', ''),
                          backgroundColor: Colors.white,
                          fontSize: 16.0,
                          textColor: Styles().colors.fillColorPrimary,
                          borderColor: Styles().colors.fillColorSecondary,
                          onTap: () {
                            _onTapGameDayGuide();
                          },
                        ),
                      ),
                      Padding(padding: EdgeInsets.only(bottom: 6)),
                      ScalableRoundedButton(
                        label: Localization().getStringEx('widget.game_detail_heading.button.roster.title', 'Roster'),
                        hint: Localization().getStringEx('widget.game_detail_heading.button.roster.hint', ''),
                        backgroundColor: Colors.white,
                        fontSize: 16.0,
                        textColor: Styles().colors.fillColorPrimary,
                        borderColor: Styles().colors.fillColorSecondary,
                        onTap: () {
                          Analytics.instance.logSelect(target: "Roster");
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
    String sport = widget.game.sport?.shortName;
    switch (sport) {
      case "football":
        {
          return _FootballScoreWidget(game: widget.game);
        }
        break;
      case "mbball":
        {
          return _BasketballScoreWidget(game: widget.game);
        }
        break;
      case "wbball":
        {
          return _BasketballScoreWidget(game: widget.game);
        }
        break;
      case "wvball":
        {
          return _VolleyballScoreWidget(game: widget.game);
        }
        break;
      default:
        {
          return _SportScoreWidget(game: widget.game);
        }
    }
  }

  List<Widget> _buildHeaderWidgets() {
    List<Widget> widgets = List();
    if(widget.showImageTout) {
      if (!AppString.isStringEmpty(widget.game.imageUrl)) {
        widgets.add(Positioned(
            child: Semantics(
                excludeSemantics: true,
                child: Image.network(
                  widget.game.imageUrl,
                ))));
      }
      widgets.add(Semantics(
          excludeSemantics: true,
          child: CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors.fillColorPrimary),
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

  void _onTapSaveGame() {
    Analytics.instance.logSelect(target: "Favorite");
    User().switchFavorite(widget.game);
  }

  void _onTapGetTickets() {
    Analytics.instance.logSelect(target: "Get Tickets");

    if (User().showTicketsConfirmationModal) {
      PrivacyTicketsDialog.show(context, onContinueTap: () {
        _showTicketsPanel();
      });
    } else {
      _showTicketsPanel();
    }
  }

  void _showTicketsPanel() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: widget.game.links.tickets)));
  }

  void _onTapParking() {
    Analytics.instance.logSelect(target: "Parking");

    Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: widget.game.parkingUrl)));
  }

  void _onTapGameDayGuide() {
    Analytics.instance.logSelect(target: "Game Day");
    String sportKey = widget.game.sport?.shortName;
    String url = AppUrl.getGameDayGuideUrl(sportKey);
    if (url != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
    }
  }

  void _onTapListen(String audioUrl) {
    Analytics.instance.logSelect(target: "Listen");
    if (AppString.isStringNotEmpty(audioUrl)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: audioUrl)));
    }
  }

  void _onTapWatch(String videoUrl) {
    Analytics.instance.logSelect(target: "Watch");
    if (AppString.isStringNotEmpty(videoUrl)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: videoUrl)));
    }
  }
}

///
/// _DetailRibbonButton
///
class _DetailRibbonButton extends StatelessWidget {
  final String iconResource;
  final String title;
  final String subTitle;
  final String hint;
  final GestureTapCallback onTap;

  _DetailRibbonButton({@required this.iconResource, @required this.title, this.subTitle = '', this.hint = '', this.onTap});

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
                  Image.asset(iconResource),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      title,
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies.bold,
                          color: Styles().colors.fillColorPrimary,
                          fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                  Visibility(
                      child: Text(
                        (!AppString.isStringEmpty(subTitle) ? subTitle : ''),
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies.medium,
                            color: Styles().colors.textBackground,
                            fontSize: 16),
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
  final Game _game;

  _SportScoreWidget({@required Game game}) : _game = game;

  @override
  _SportScoreWidgetState createState() => _SportScoreWidgetState();
}

class _SportScoreWidgetState extends State<_SportScoreWidget> implements NotificationsListener {
  LiveStats _livestatsLogic;
  LiveGame _currentLiveGame;

  _SportScoreWidgetState() {
    _livestatsLogic = LiveStats();
  }

  @override
  void initState() {
    NotificationService().subscribe(this, [
      LiveStats.notifyLiveGamesLoaded,
      LiveStats.notifyLiveGamesUpdated,
    ]);

    LiveGame liveGame = _livestatsLogic.getLiveGame(widget._game.id);
    _setCurrentData(liveGame);

    _livestatsLogic.addTopic(widget._game.sport.shortName);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _livestatsLogic.removeTopic(widget._game.sport.shortName);
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
                _currentLiveGame != null ? _formatPeriod(_currentLiveGame.period) : "-",
                style: TextStyle(fontFamily: Styles().fontFamilies.bold, color: Styles().colors.fillColorPrimary, fontSize: 16),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.transparent,
              ),
            ),
            Text(
              _currentLiveGame != null ? _formatClock(_currentLiveGame.clockSeconds) : "-",
              style: TextStyle(fontFamily: Styles().fontFamilies.medium, color: Styles().colors.textBackground, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeriod(int period) {
    if (period <= 0) return "";

    return _convertToOrdinal(period) + " " + _getPeriodName();
  }

  String _getPeriodName() {
    String shortName = widget._game.sport.shortName;
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

  String _convertToOrdinal(int period) {
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
        color: Styles().colors.background,
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
              left: BorderSide(width: 1, color: Styles().colors.fillColorPrimaryTransparent015),
              right: BorderSide(width: 0.5, color: Styles().colors.fillColorPrimaryTransparent015),
              top: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
              bottom: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
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
                _currentLiveGame != null ? _currentLiveGame.homeScore.toString() : "-",
                style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getHomeImage() {
    if (widget._game.isHomeGame) {
      //return illinois image
      return Image.asset('images/block-i-orange.png', height: 58, fit: BoxFit.fitHeight);
    } else {
      //return opponent image
      Opponent opponent = widget._game.opponent;
      String opponentUrl = opponent != null ? opponent.logoImage : null;
      if(AppString.isStringNotEmpty(opponentUrl)) {
        return Image.network(opponentUrl);
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
              left: BorderSide(width: 0.5, color: Styles().colors.fillColorPrimaryTransparent015),
              right: BorderSide(width: 0.5, color: Styles().colors.fillColorPrimaryTransparent015),
              top: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
              bottom: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
            )),
        height: 68,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                _currentLiveGame != null ? _currentLiveGame.visitingScore.toString() : "-",
                style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 32),
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
    if (!widget._game.isHomeGame) {
      //return illinois image
      return Image.asset('images/block-i-orange.png', height: 58, fit: BoxFit.fitHeight);
    } else {
      //return opponent image
      Opponent opponent = widget._game.opponent;
      String opponentUrl = opponent != null ? opponent.logoImage : null;
      if(AppString.isStringNotEmpty(opponentUrl)) {
        return Image.network(opponentUrl);
      } else {
        return Container();
      }
    }
  }

  void _setCurrentData(LiveGame liveGame) {
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
      _setCurrentData(_livestatsLogic.getLiveGame(widget._game.id));
    });
  }

  void _onLiveGameUpdated(LiveGame liveGame) {
    if ((liveGame != null) && (widget._game.id == liveGame.gameId)) {
      _setCurrentData(liveGame);
    }
  }
}

///
/// _VolleyballScoreWidget
///
class _VolleyballScoreWidget extends _SportScoreWidget {

  _VolleyballScoreWidget({@required Game game}) : super(game: game);

  @override
  _VolleyballScoreWidgetState createState() => _VolleyballScoreWidgetState();
}

class _VolleyballScoreWidgetState extends _SportScoreWidgetState {

  _VolleyballScoreWidgetState() : super();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return _hasExtraData() ? _createRichContent(width, height) : _createLiteContent(width, height);
  }

  bool _hasExtraData() {
    if (_currentLiveGame == null) return false;

    dynamic customData = _currentLiveGame.custom;
    if (AppString.isStringEmpty(customData)) return false;

    Map<String, dynamic> mapCustomData = AppJson.decode(customData);
    if (mapCustomData == null) {
      return null;
    }
    return mapCustomData["HasExtraData"];
  }

  Widget _createLiteContent(double width, double height) {
    String period = _getPeriod();
    String homeScore = _getHomeScore();
    String visitingScore = _getVisitingScore();
    Image homeImage = _getHomeImageFrom(width, height);
    Image visitingImage = _getVisitingImage(width, height);
    return _LiteContent(period: period, homeScore: homeScore, visitingScore: visitingScore, homeImage: homeImage, visitingImage: visitingImage);
  }

  String _getPeriod() {
    if (_currentLiveGame == null) return "-";
    int period = _currentLiveGame.period;
    if (period <= 0) return "";

    return _convertToOrdinal(period) + " " + Localization().getStringEx("widget.score.period.set", "Set");
  }

  String _getHomeScore() {
    if (_currentLiveGame == null) return "-";

    return _currentLiveGame.homeScore.toString();
  }

  String _getVisitingScore() {
    if (_currentLiveGame == null) return "-";

    return _currentLiveGame.visitingScore.toString();
  }

  Image _getHomeImageFrom(double width, double height) {
    if (widget._game.isHomeGame) {
      //return illinois image
      return Image.asset('images/block-i-orange.png', height: 58, fit: BoxFit.fitHeight);
    } else {
      //return opponent image
      Opponent opponent = widget._game.opponent;
      String opponentUrl = opponent != null ? opponent.logoImage : null;
      return Image.network(opponentUrl);
    }
  }

  Image _getVisitingImage(double width, double height) {
    if (!widget._game.isHomeGame) {
      //return illinois image
      return Image.asset('images/block-i-orange.png', height: 58, fit: BoxFit.fitHeight);
    } else {
      //return opponent image
      Opponent opponent = widget._game.opponent;
      String opponentUrl = opponent != null ? opponent.logoImage : null;
      return Image.network(opponentUrl);
    }
  }

  Widget _createRichContent(double width, double height) {
    if (_currentLiveGame == null) return Container();

    dynamic customData = _currentLiveGame.custom;
    if (AppString.isStringEmpty(customData)) return Container();

    Map<String, dynamic> mapCustomData = AppJson.decode(customData);
    if (mapCustomData == null) return Container();

    String phase = mapCustomData["Phase"];
    String phaseLabel = mapCustomData["PhaseLabel"];
    String hScore = mapCustomData["HScore"];
    String vScore = mapCustomData["VScore"];
    String hPoints = mapCustomData["HPoints"];
    String vPoints = mapCustomData["VPoints"];
    String serving = mapCustomData["Serving"];
    Image homeImage = _getHomeImageFrom(width, height);
    Image visitingImage = _getVisitingImage(width, height);
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
  final Image _homeImage;
  final Image _visitingImage;

  _LiteContent({@required String period, @required String homeScore, @required String visitingScore, @required Image homeImage, @required Image visitingImage})
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
                style: TextStyle(fontFamily: Styles().fontFamilies.bold, color: Styles().colors.fillColorPrimary, fontSize: 16),
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
        color: Styles().colors.background,
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
              left: BorderSide(width: 1, color: Styles().colors.fillColorPrimaryTransparent015),
              right: BorderSide(width: 0.5, color: Styles().colors.fillColorPrimaryTransparent015),
              top: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
              bottom: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
            )),
        height: 68,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: _homeImage),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Text(_homeScore, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 32)),
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
              left: BorderSide(width: 0.5, color: Styles().colors.fillColorPrimaryTransparent015),
              right: BorderSide(width: 0.5, color: Styles().colors.fillColorPrimaryTransparent015),
              top: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
              bottom: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
            )),
        height: 68,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(_visitingScore, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 32)),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: _visitingImage,
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
  final String _phase;
  final String _phaseLabel;
  final String _hScore;
  final String _vScore;
  final String _hPoints;
  final String _vPoints;
  final String _serving;
  final Image _homeImage;
  final Image _visitingImage;

  _RichContent(
      {@required String phase,
        @required String phaseLabel,
        @required String hScore,
        @required String vScore,
        @required String hPoints,
        @required String vPoints,
        @required String serving,
        @required Image homeImage,
        @required Image visitingImage})
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
                _phaseLabel,
                style: TextStyle(fontFamily: Styles().fontFamilies.bold, color: Styles().colors.fillColorPrimary, fontSize: 16),
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
        color: Styles().colors.background,
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
              left: BorderSide(width: 1, color: Styles().colors.fillColorPrimaryTransparent015),
              right: BorderSide(width: 0.5, color: Styles().colors.fillColorPrimaryTransparent015),
              top: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
              bottom: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
            )),
        height: 68,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: outerPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: _homeImage),
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
        Text(_hPoints, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 32)),
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
              Text(_hScore, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 23))
            ],
          ),
        ),
      ],
    )
        : Text(_hScore, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 32));
  }

  Widget _buildVisitingSection(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double outerPadding = width * 0.038;
    return Expanded(
      child: Container(
        decoration: new BoxDecoration(
            border: Border(
              left: BorderSide(width: 0.5, color: Styles().colors.fillColorPrimaryTransparent015),
              right: BorderSide(width: 0.5, color: Styles().colors.fillColorPrimaryTransparent015),
              top: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
              bottom: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
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
                child: _visitingImage,
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
              Text(_vScore, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 23))
            ],
          ),
        ),
        SizedBox(width: 15),
        Text(_vPoints, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 32)),
      ],
    )
        : Text(_vScore, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 32));
  }
}

class _ServingControl extends StatelessWidget {
  final bool _home;

  _ServingControl({@required bool home}) : _home = home;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(14, 14), painter: _ArrowPainter(_home));
  }
}

class _ArrowPainter extends CustomPainter {
  Paint _paint;
  bool _home;

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
  _FootballScoreWidget({@required Game game}) : super(game: game);

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
                style: TextStyle(fontFamily: Styles().fontFamilies.bold, color: Styles().colors.fillColorPrimary, fontSize: 16),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.transparent,
              ),
            ),
            Text(
              _currentLiveGame != null ? _getClock() : "-",
              style: TextStyle(fontFamily: Styles().fontFamilies.medium, color: Styles().colors.textBackground, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiddleSection() {
    String possession = _getPossession();
    return Container(
        height: 68,
        color: Styles().colors.background,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[_buildHomeSectionWithPossession(possession), _buildAwaySectionWithPossesion(possession)],
        ));
  }

  Widget _buildHomeSectionWithPossession(String possession) {
    bool isHomePossession = (possession == "H");
    return Expanded(
      child: Container(
        decoration: new BoxDecoration(
            border: Border(
              left: BorderSide(width: 1, color: Styles().colors.fillColorPrimaryTransparent015),
              right: BorderSide(width: 0.5, color: Styles().colors.fillColorPrimaryTransparent015),
              top: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
              bottom: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
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
                  child: Image.asset('images/posession.png', height: 25, fit: BoxFit.fitHeight),
                ),
              ),
              Text(
                _currentLiveGame != null ? _currentLiveGame.homeScore.toString() : "-",
                style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAwaySectionWithPossesion(String possession) {
    bool isVisitingPossession = possession == "V";
    return Expanded(
      child: Container(
        decoration: new BoxDecoration(
            border: Border(
              left: BorderSide(width: 0.5, color: Styles().colors.fillColorPrimaryTransparent015),
              right: BorderSide(width: 0.5, color: Styles().colors.fillColorPrimaryTransparent015),
              top: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
              bottom: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
            )),
        height: 68,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                _currentLiveGame != null ? _currentLiveGame.visitingScore.toString() : "-",
                style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 32),
              ),
              Visibility(
                visible: isVisitingPossession,
                child: Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Image.asset('images/posession.png', height: 25, fit: BoxFit.fitHeight),
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
    String lastPlay = _getLastPlay();
    bool hasLastPlay = AppString.isStringNotEmpty(lastPlay);
    return hasLastPlay
        ? Container(
        decoration: new BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
            )),
        child: Padding(
          padding: EdgeInsets.only(top: 6, bottom: 6, left: 20, right: 20),
          child: Text(sprintf(Localization().getStringEx('widget.score.last_play', 'Last Play: %s'), [lastPlay]), textAlign: TextAlign.left, style: TextStyle(fontSize: 16)),
        ))
        : Container();
  }

  String _getLastPlay() {
    if (AppString.isStringEmpty(_currentLiveGame?.custom)) return null;

    Map<String, dynamic> mapCustomData = AppJson.decode(_currentLiveGame.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["LastPlay"];
  }

  String _getPossession() {
    if (AppString.isStringEmpty(_currentLiveGame?.custom)) return null;

    Map<String, dynamic> mapCustomData = AppJson.decode(_currentLiveGame.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["Possession"];
  }

  String _getClock() {
    String customClock = _getCustomClock();
    //empty value is valid
    if (customClock != null) return customClock;

    //return regular clock
    return _getRegularClock();
  }

  String _getRegularClock() {
    if (_currentLiveGame.clockSeconds < 0) return "";

    final format = new DateFormat('mm:ss');
    return format.format(new DateTime.fromMillisecondsSinceEpoch(_currentLiveGame.clockSeconds * 1000));
  }

  String _getCustomClock() {
    if (AppString.isStringEmpty(_currentLiveGame.custom)) return null;

    Map<String, dynamic> mapCustomData = AppJson.decode(_currentLiveGame.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["Clock"];
  }

  String _getPhase() {
    String customPhase = _getCustomPhase();
    //empty value is valid
    if (customPhase != null) return customPhase;

    //return regular clock
    return _getPeriod();
  }

  String _getCustomPhase() {
    if (AppString.isStringEmpty(_currentLiveGame.custom)) return null;

    Map<String, dynamic> mapCustomData = AppJson.decode(_currentLiveGame.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["Phase"];
  }

  String _getPeriod() {
    if (_currentLiveGame.period <= 0) return "";

    return _convertToOrdinal(_currentLiveGame.period) + " " + Localization().getStringEx("widget.score.period.quarter", "Quarter");
  }
}

///
/// _BasketballScoreWidget
///
class _BasketballScoreWidget extends _SportScoreWidget {

  _BasketballScoreWidget({@required Game game}) : super(game: game);

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
                style: TextStyle(fontFamily: Styles().fontFamilies.bold, color: Styles().colors.fillColorPrimary, fontSize: 16),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.transparent,
              ),
            ),
            Text(
              _currentLiveGame != null ? _getClock() : "-",
              style: TextStyle(fontFamily: Styles().fontFamilies.medium, color: Styles().colors.textBackground, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiddleSection() {
    return Container(
        height: 68,
        color: Styles().colors.background,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[_buildHomeSection(), _buildAwaySection()],
        ));
  }

  Widget _buildBottomSection() {
    String lastPlay = _getLastPlay();
    bool hasLastPlay = AppString.isStringNotEmpty(lastPlay);
    return hasLastPlay
        ? Container(
        decoration: new BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 1.0, color: Styles().colors.fillColorPrimaryTransparent015),
            )),
        child: Padding(
          padding: EdgeInsets.only(top: 6, bottom: 6, left: 20, right: 20),
          child: Text("Last Play: " + lastPlay, textAlign: TextAlign.left, style: TextStyle(fontSize: 16)),
        ))
        : Container();
  }

  String _getLastPlay() {
    if (AppString.isStringEmpty(_currentLiveGame?.custom)) return null;

    Map<String, dynamic> mapCustomData = AppJson.decode(_currentLiveGame.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["LastPlay"];
  }

  String _getClock() {
    String customClock = _getCustomClock();
    //empty value is valid
    if (customClock != null) return customClock;

    //return regular clock
    return _getRegularClock();
  }

  String _getRegularClock() {
    if (_currentLiveGame.clockSeconds < 0) return "";

    final format = new DateFormat('mm:ss');
    return format.format(new DateTime.fromMillisecondsSinceEpoch(_currentLiveGame.clockSeconds * 1000));
  }

  String _getCustomClock() {
    if (AppString.isStringEmpty(_currentLiveGame.custom)) return null;

    Map<String, dynamic> mapCustomData = AppJson.decode(_currentLiveGame.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["Clock"];
  }

  String _getPhase() {
    String customPhase = _getCustomPhase();
    //empty value is valid
    if (customPhase != null) return customPhase;

    //return regular clock
    return _getPeriod();
  }

  String _getCustomPhase() {
    if (AppString.isStringEmpty(_currentLiveGame.custom)) return null;

    Map<String, dynamic> mapCustomData = AppJson.decode(_currentLiveGame.custom);
    if (mapCustomData == null) return null;
    return mapCustomData["Phase"];
  }

  String _getPeriod() {
    if (_currentLiveGame.period <= 0) {
      return "";
    }
    String shortName = widget._game.sport.shortName;
    String periodName = (shortName == "mbball") ? Localization().getStringEx("widget.score.period.half", "Half") : Localization().getStringEx(
        "widget.score.period.quarter", "Quarter");
    return _convertToOrdinal(_currentLiveGame.period) + " " + periodName;
  }

}