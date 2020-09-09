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
import 'package:illinois/model/sport/Team.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/athletics/AthleticsScheduleCard.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class AthleticsSchedulePanel extends StatefulWidget {
  final SportDefinition sport;

  AthleticsSchedulePanel({this.sport});

  @override
  _AthleticsSchedulePanelState createState() => _AthleticsSchedulePanelState();
}

class _AthleticsSchedulePanelState extends State<AthleticsSchedulePanel> {

  TeamSchedule _schedule;
  String _scheduleYear;
  List<dynamic> _displayList;
  bool _displayUpcoming = true;
  ScrollController _scrollController = ScrollController();
  bool _loading;

  @override
  void initState() {
    _loadSchedules();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String headerLabel = widget.sport?.name ?? Localization().getStringEx('panel.athletics_schedule.header.title', 'SCHEDULE');
    String scheduleYear = AppString.getDefaultEmptyString(value: _scheduleYear);
    String scheduleLabel = scheduleYear + " " + Localization().getStringEx("panel.athletics_schedule.label.schedule.title", "Schedule");
    int itemsCount = _displayList?.length ?? 0;
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context, titleWidget: Text(headerLabel, style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),),
      body: _loading ? Center(child: CircularProgressIndicator()) : Column(children: <Widget>[
        Container(color:Styles().colors.fillColorPrimaryVariant, child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Column(children: <Widget>[
          Row(children: <Widget>[
            Image.asset(widget.sport.iconPath),
            Padding(padding: EdgeInsets.only(left: 8)),
            Text(widget.sport.name, style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Styles().colors.whiteTransparent06,)),
          ],),
          Padding(padding: EdgeInsets.only(top: 8)),
          Row(children: <Widget>[
            Expanded(child: Text(scheduleLabel, style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, color: Colors.white ))),
          ],)
        ],)
        ),),

        Container(color:Styles().colors.background, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:Row(children: <Widget>[
          Expanded(child:_ScheduleTabButton(
            text: Localization().getStringEx("panel.athletics_schedule.button.upcoming.title", "Upcoming"),
            hint: Localization().getStringEx("panel.athletics_schedule.button.upcoming.hint", ""),
            left: true, selected: _displayUpcoming, onTap: () { _setDisplayUpcoming(true); },
          )),
          Expanded(child:_ScheduleTabButton(
              text: Localization().getStringEx("panel.athletics_schedule.button.past.title", "Past"),
              hint: Localization().getStringEx("panel.athletics_schedule.button.past.hint", ""),
              left: false, selected: !_displayUpcoming, onTap: () { _setDisplayUpcoming(false); }
          )),
        ],))
        ),

        Expanded(child: Container(color:Styles().colors.background, child:
        ListView.separated(
          shrinkWrap: true,
          separatorBuilder: (context, index) => Divider(color: Colors.transparent, height: 24,),
          itemCount: itemsCount,
          itemBuilder: (context, index) {
            return Padding(padding: EdgeInsets.only(right: 16, left: 16),
                child: (index == (itemsCount - 1) ? Container(height: 48,) : _displayItemAtIndex(context, index)));
          },
          controller: _scrollController,
        ),),)
      ]),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  void _loadSchedules() {
    _setLoading(true);
    Sports()
        .loadScheduleForCurrentSeason(widget.sport?.shortName).then((sportSeason) => _onSportSeasonLoaded(sportSeason));
  }

  void _onSportSeasonLoaded(Map<String, TeamSchedule> sportSeason) {
    if (sportSeason != null) {
      _scheduleYear = sportSeason.keys.elementAt(0);
      _schedule = sportSeason.values.elementAt(0);
      _displayList = _buildDisplayList();
    }
    _setLoading(false);
  }

  List _buildDisplayList() {
    List displayList = List();
    if (_schedule.games != null && _schedule.games.isNotEmpty) {
      DateTime now = DateTime.now();
      for (Game game in _schedule.games) {
        DateTime gameDateTime = game.dateTimeUniLocal;
        if (gameDateTime != null) {
          if ((_displayUpcoming && gameDateTime.isAfter(now)) ||
              (!_displayUpcoming && gameDateTime.isBefore(now))) {
            displayList.add(game);
          }
        }
      }
      displayList.sort((a, b) {
        return _displayUpcoming
            ? _compareSchedulesAscending(a, b)
            : _compareSchedulesDescending(a, b);
      });
    }
    return displayList;
  }

  int _compareSchedulesAscending(Game a, Game b) {
    DateTime dateTimeA = a.dateTimeUniLocal;
    DateTime dateTimeB = b.dateTimeUniLocal;
    if ((dateTimeA != null)) {
      return (dateTimeB != null) ? dateTimeA.compareTo(dateTimeB) : -1;
    }
    else {
      return (dateTimeB != null) ? 1 : 0;
    }
  }

  int _compareSchedulesDescending(Game a, Game b) {
    DateTime dateTimeA = a.dateTimeUniLocal;
    DateTime dateTimeB = b.dateTimeUniLocal;
    if ((dateTimeA != null)) {
      return (dateTimeB != null) ? dateTimeB.compareTo(dateTimeA) : 1;
    }
    else {
      return (dateTimeB != null) ? -1 : 0;
    }
  }

  Widget _displayItemAtIndex(BuildContext context, int index) {
    Game game = _displayList[index];
    AthleticsScheduleCard scheduleCard = AthleticsScheduleCard(game: game,);
    return scheduleCard;
  }

  void _setDisplayUpcoming(bool displayUpcoming) {
    Analytics.instance.logSelect(target: displayUpcoming ? "Upcoming" : "Past");
    if (_displayUpcoming != displayUpcoming) {
      setState(() {
        _scrollController.jumpTo(0);
        _displayUpcoming = displayUpcoming;
        _displayList = _buildDisplayList();
      });
    }
  }

  void _setLoading(bool loading) {
    setState(() {
      _loading = loading;
    });
  }

}

class _ScheduleTabButton extends StatelessWidget {
  final String text;
  final String hint;
  final bool left;
  final bool selected;
  final GestureTapCallback onTap;
  final double buttonHeight;

  _ScheduleTabButton({Key key, this.text, this.hint, this.left, this.selected, this.onTap, this.buttonHeight = 48})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    BorderSide borderSide = BorderSide(color: Styles().colors.surfaceAccent, width: 2, style: BorderStyle.solid);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
          label: text,
          hint: hint,
          button: true,
          excludeSemantics: true,
          child:Container(
            height: 32 + 16*MediaQuery.of(context).textScaleFactor,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Styles().colors.lightGray,
              border: Border.fromBorderSide(borderSide),
              borderRadius: left ? BorderRadius.horizontal(left: Radius.circular(100.0)) : BorderRadius.horizontal(right: Radius.circular(100.0)),
            ),
            child:
            Row( children:[
            Expanded(child: Text(text,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily:
                        selected ? Styles().fontFamilies.extraBold : Styles().fontFamilies.medium,
                        fontSize: 16,
                        color: Styles().colors.fillColorPrimary))),
            ])
          )),
    );
  }
}
