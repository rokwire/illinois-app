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
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class AthleticsScheduleCard extends StatefulWidget {
  final Game _game;

  AthleticsScheduleCard({Key key, Game game})
      : _game = game,
        super(key: key);

  @override
  _AthleticsScheduleCardState createState() => _AthleticsScheduleCardState();
}

class _AthleticsScheduleCardState extends State<AthleticsScheduleCard> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, User.notifyFavoritesUpdated);
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
    if (name == User.notifyFavoritesUpdated) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Padding( padding: EdgeInsets.only(top: 24))
    Widget last = _cardScore();
    if (last == null) {
      last = _cardAction(context);
    }
    if (last == null) {
      last = Padding(
        padding: EdgeInsets.only(bottom: 24),
      );
    }

    String title = widget?._game?.title ?? "";
    String subTitle = widget?._game?.shortDescription ?? "";
    String displayTime = widget?._game?.displayTime ?? "";

    return GestureDetector(
      onTap: _onTapSchedule,
      child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4.0), bottomRight: Radius.circular(4.0)),
              boxShadow: [BoxShadow(color: Styles().colors.fillColorPrimaryTransparent015, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(0, 2))]),
          child: Container(
            color: Colors.white,
            child: Column(
              children: <Widget>[
                Container(height: 4, width: MediaQuery.of(context).size.width, color: Styles().colors.fillColorPrimaryVariant),
                Column(children: <Widget>[
                    Semantics(
                      label: "$title $subTitle $displayTime",
                      excludeSemantics: true,
                      button: true,
                      child: Column(
                        children: <Widget>[
                          _cardTitle(),
                          _cardSubTitle(),
                          _cardTimeDetail(),
                        ],
                      ),
                    ),
                    last,
                  ]),
              ],
            ),
          )),
    );
  }

  Widget _cardTitle() {
    bool starVisible = widget._game.isUpcoming && Auth2().canFavorite;
    bool isGameSaved = User().isFavorite(widget._game);

    return Padding(
      padding: EdgeInsets.only(left: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
                padding: EdgeInsets.only(top: 16, right: 24),
                child: Text(
                  widget._game.title,
                  style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 24, color: Styles().colors.fillColorPrimary),
                )),
          ),
          Visibility(
            visible: starVisible,
            child: Container(
                child: Padding(
                    padding: EdgeInsets.only(top: 20, right: 24),
                    child: GestureDetector(child: Image.asset(isGameSaved ? 'images/icon-star-selected.png' : 'images/icon-star.png'), onTap: _onTapSaveGame))),
          )
        ],
      ),
    );
  }

  Widget _cardSubTitle() {
    return AppString.isStringNotEmpty(widget._game.shortDescription)
        ? Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: Text(
                  widget._game.shortDescription,
                  style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.textBackground),
                ))
              ],
            ),
          )
        : Container();
  }

  Widget _cardTimeDetail() {
    String displayTime = widget._game.displayTime;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 12, left: 24, right: 24),
        child: Row(
          children: <Widget>[
            Image.asset('images/icon-calendar.png'),
            Padding(
              padding: EdgeInsets.only(right: 5),
            ),
            Text(displayTime, style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Styles().colors.textBackground)),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _cardAction(BuildContext context) {
    SportDefinition sport = Sports().getSportByShortName(widget._game.sport?.shortName);
    bool hasTickets = _hasTickets();
    return Semantics(
      label: _getTicketsInformationText(sport),
      hint: _getTicketsInformationHint(sport),
      button: true,
      child: Padding(
        padding: EdgeInsets.only(top: (widget._game.isHomeGame ? 16 : 24)),
        child: Column(
          children: <Widget>[
            Container(
              height: 1,
              color: Styles().colors.fillColorPrimaryTransparent015,
            ),
            GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (hasTickets) {
                    _onTapGetTickets();
                  } else {
                    _onTapSchedule();
                  }
                },
                child: Visibility(
                  visible: widget._game.isHomeGame,
                  child: Container(
                      height: 48,
                      color: Styles().colors.background,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Row(children: <Widget>[
                            Text(_getTicketsInformationText(sport),
                                style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary)),
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                            ),
                            Visibility(visible: hasTickets, child: Image.asset('images/chevron-right.png'))
                          ]))),
                ))
          ],
        ),
      ),
    );
  }

  String _getTicketsInformationText(SportDefinition sport) {
    if (widget._game.isHomeGame) {
      return _hasTickets()
          ? Localization().getStringEx("widget.schedule_card.button.get_tickets.title", "Get Tickets")
          : Localization().getStringEx("widget.schedule_card.button.free_admission.title", "Free Admission");
    } else {
      return "";
    }
  }

  String _getTicketsInformationHint(SportDefinition sport) {
    if (widget._game.isHomeGame) {
      return _hasTickets()
          ? Localization().getStringEx("widget.schedule_card.button.get_tickets.hint", "")
          : Localization().getStringEx("widget.schedule_card.button.free_admission.hint", "");
    } else {
      return "";
    }
  }

  Widget _cardScore() {
    GameResult result = (widget._game.results != null && widget._game.results.isNotEmpty) ? widget._game.results[0] : null;
    if (result == null) {
      return null;
    }
    String formattedResult = result.status + ' ' + result.teamScore + '-' + result.opponentScore;
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: Column(
        children: <Widget>[
          Container(
            height: 1,
            color: Styles().colors.fillColorPrimaryTransparent015,
          ),
          Container(
              height: 48,
              color: Styles().colors.background,
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(children: <Widget>[
                    Text(Localization().getStringEx("widget.schedule_card.final_score", "Final Score"),
                        style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary)),
                    Expanded(
                      child: Container(),
                    ),
                    Text(formattedResult, style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Styles().colors.textBackground)),
                  ])))
        ],
      ),
    );
  }

  void _onTapSaveGame() {
    Analytics.instance.logSelect(target: "Favorite: ${widget._game?.title}");
    User().switchFavorite(widget._game);
  }

  void _onTapSchedule() {
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => AthleticsGameDetailPanel(
                  game: widget._game,
                )));
  }

  void _onTapGetTickets() {
    Analytics.instance.logSelect(target: "SchedulteCard: " + widget._game.title + " -Tickets");

    if (PrivacyTicketsDialog.shouldConfirm) {
      PrivacyTicketsDialog.show(context, onContinueTap: () {
        _pushTicketsWebPanel();
      });
    } else {
      _pushTicketsWebPanel();
    }
  }

  void _pushTicketsWebPanel() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: widget._game.links.tickets)));
  }

  bool _hasTickets() {
    bool homeGame = widget._game.isHomeGame;
    SportDefinition sportDefinition = Sports().getSportByShortName(widget._game?.sport?.shortName);
    bool ticketedSport = sportDefinition?.ticketed ?? false;
    bool hasTicketsUrl = AppString.isStringNotEmpty(widget._game?.links?.tickets);
    return homeGame && ticketedSport && hasTicketsUrl;
  }
}
