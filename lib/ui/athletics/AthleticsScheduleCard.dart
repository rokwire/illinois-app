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
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/ext/Game.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AthleticsScheduleCard extends StatefulWidget {
  final Game? _game;

  AthleticsScheduleCard({Key? key, Game? game})
      : _game = game,
        super(key: key);

  @override
  _AthleticsScheduleCardState createState() => _AthleticsScheduleCardState();
}

class _AthleticsScheduleCardState extends State<AthleticsScheduleCard> implements NotificationsListener {
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
    // Padding( padding: EdgeInsets.only(top: 24))
    Widget? last = _cardScore();
    if (last == null) {
      last = _cardAction(context);
    }
    if (last == null) {
      last = Padding(
        padding: EdgeInsets.only(bottom: 24),
      );
    }

    String title = widget._game?.title ?? "";
    String subTitle = widget._game?.description ?? "";
    String displayTime = widget._game?.displayTime ?? "";

    return GestureDetector(
      onTap: _onTapSchedule,
      child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4.0), bottomRight: Radius.circular(4.0)),
              boxShadow: [BoxShadow(color: Styles().colors!.fillColorPrimaryTransparent015!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(0, 2))]),
          child: Container(
            color: Colors.white,
            child: Column(
              children: <Widget>[
                Container(height: 4, width: MediaQuery.of(context).size.width, color: Styles().colors!.fillColorPrimaryVariant),
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
    bool starVisible = widget._game!.isUpcoming && Auth2().canFavorite;
    bool isGameSaved = Auth2().isFavorite(widget._game);

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
                  widget._game!.title,
                  style: Styles().textStyles?.getTextStyle('widget.card.title.large')
                )),
          ),
          Visibility(
            visible: starVisible,
            child: GestureDetector(child: Container(
                  padding: EdgeInsets.only(top: 20, right: 24),
                  child: Styles().images?.getImage(isGameSaved ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true)), onTap: _onTapSaveGame),
          )
        ],
      ),
    );
  }

  Widget _cardSubTitle() {
    return StringUtils.isNotEmpty(widget._game!.description)
        ? Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: Text(
                  widget._game!.description!,
                  style: Styles().textStyles?.getTextStyle('widget.card.detail.regular.fat')
                ))
              ],
            ),
          )
        : Container();
  }

  Widget _cardTimeDetail() {
    String? displayTime = widget._game?.displayTime;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 12, left: 24, right: 24),
        child: Row(
          children: <Widget>[
            Styles().images?.getImage('calendar', excludeFromSemantics: true) ?? Container(),
            Padding(
              padding: EdgeInsets.only(right: 5),
            ),
            Text(displayTime, style: Styles().textStyles?.getTextStyle('widget.card.detail.medium')),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Widget? _cardAction(BuildContext context) {
    SportDefinition? sport = Sports().getSportByShortName(widget._game!.sport?.shortName);
    bool hasTickets = _hasTickets();
    return Semantics(
      label: _getTicketsInformationText(sport),
      hint: _getTicketsInformationHint(sport),
      button: true,
      child: Padding(
        padding: EdgeInsets.only(top: (_hasTickets() ? 16 : 24)),
        child: Column(
          children: <Widget>[
            Container(
              height: 1,
              color: Styles().colors!.fillColorPrimaryTransparent015,
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
                  visible: _hasTickets(),
                  child: Container(
                      height: 48,
                      color: Styles().colors!.background,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Row(children: <Widget>[
                            Text(_getTicketsInformationText(sport)!,
                                style: Styles().textStyles?.getTextStyle('widget.card.title.small.fat')),
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                            ),
                            Visibility(visible: hasTickets, child: Styles().images?.getImage('chevron-right-bold', excludeFromSemantics: true) ?? Container())
                          ]))),
                ))
          ],
        ),
      ),
    );
  }

  String? _getTicketsInformationText(SportDefinition? sport) {
    return _hasTickets() ? Localization().getStringEx("widget.schedule_card.button.get_tickets.title", "Get Tickets") : "";
  }

  String? _getTicketsInformationHint(SportDefinition? sport) {
    return _hasTickets() ? Localization().getStringEx("widget.schedule_card.button.get_tickets.hint", "") : "";
  }

  Widget? _cardScore() {
    GameResult? result = (widget._game!.results != null && widget._game!.results!.isNotEmpty) ? widget._game!.results![0] : null;
    if (result == null) {
      return null;
    }
    String formattedResult = StringUtils.ensureNotEmpty(result.status);
    if (StringUtils.isNotEmpty(result.teamScore)) {
      formattedResult += ' ' + result.teamScore!;
      if (StringUtils.isNotEmpty(result.opponentScore)) {
        formattedResult += '-' + result.opponentScore!;
      }
    }
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: Column(
        children: <Widget>[
          Container(
            height: 1,
            color: Styles().colors!.fillColorPrimaryTransparent015,
          ),
          Container(
              height: 48,
              color: Styles().colors!.background,
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(children: <Widget>[
                    Text(Localization().getStringEx("widget.schedule_card.final_score", "Final Score"),
                        style: Styles().textStyles?.getTextStyle('widget.card.title.small.fat')),
                    Expanded(
                      child: Container(),
                    ),
                    Text(formattedResult, style: Styles().textStyles?.getTextStyle('widget.card.detail.medium')),
                  ])))
        ],
      ),
    );
  }

  void _onTapSaveGame() {
    Analytics().logSelect(target: "Favorite: ${widget._game?.title}");
    Auth2().prefs?.toggleFavorite(widget._game);
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
    Analytics().logSelect(target: "SchedulteCard: " + widget._game!.title + " -Tickets");

    if (PrivacyTicketsDialog.shouldConfirm) {
      PrivacyTicketsDialog.show(context, onContinueTap: () {
        _pushTicketsWebPanel();
      });
    } else {
      _pushTicketsWebPanel();
    }
  }

  void _pushTicketsWebPanel() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: widget._game!.links!.tickets)));
  }

  bool _hasTickets() {
    bool homeGame = widget._game!.isHomeGame;
    SportDefinition? sportDefinition = Sports().getSportByShortName(widget._game?.sport?.shortName);
    bool ticketedSport = sportDefinition?.ticketed ?? false;
    bool hasTicketsUrl = StringUtils.isNotEmpty(widget._game?.links?.tickets);
    return homeGame && ticketedSport && hasTicketsUrl;
  }
}
