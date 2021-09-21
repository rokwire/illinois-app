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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Connectivity.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/athletics/AthleticsSportItemWidget.dart';
import 'package:illinois/ui/athletics/AthleticsTeamPanel.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

typedef void SportsTapListener (String  sport);
class AthleticsTeamsWidget extends StatefulWidget {

  final bool _handleLabelClick;
  final List<String> preferredSports;
  final SportsTapListener onSportTaped;

  AthleticsTeamsWidget({bool handleLabelClick = false, this.preferredSports, this.onSportTaped}) : _handleLabelClick = handleLabelClick;

  @override
  AthleticsTeamsWidgetState createState() => AthleticsTeamsWidgetState();
}

class AthleticsTeamsWidgetState extends State<AthleticsTeamsWidget>
    implements NotificationsListener {
  List<SportDefinition> menSports;
  List<SportDefinition> womenSports;
  List<String> _preferredSports;

  @override
  void initState() {
    NotificationService().subscribe(this, [User.notifyUserUpdated, User.notifyInterestsUpdated]);
    _loadSportCategories();
    _loadPreferredSports();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  void _loadSportCategories() {
    menSports = Sports().getMenSports();
    womenSports = Sports().getWomenSports();
  }

  void _loadPreferredSports() {
    if(widget.preferredSports!=null){
      _preferredSports = widget.preferredSports; //so we can see the result in the parent
    } else {
      _preferredSports = User().getSportsInterestSubCategories();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildMenSectionHeader(),
            Container(
              decoration: BoxDecoration(
                  border:
                  Border.all(color: Styles().colors.surfaceAccent, width: 1)),
              child: Column(
                children: buildSportList(menSports),
              ),
            ),
            Container(
              height: 20,
            ),
            buildWomenSectionHeader(),
            Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Styles().colors.surfaceAccent, width: 1)),
                child: Column(
                  children: buildSportList(womenSports),
                )),
          ],
        ),
      ],
    );
  }

  List<Widget> buildSportList(List<SportDefinition> sports) {
    List<Widget> widgetList = [];
    if (sports != null && sports.isNotEmpty) {
      for (SportDefinition sport in sports) {
        if (widgetList.isNotEmpty) {
          widgetList.add(Divider(
            color: Styles().colors.surfaceAccent,
            height: 1,
          ));
        }
        widgetList.add(AthleticsSportItemWidget(
            sport: sport,
            showChevron: widget._handleLabelClick,
            label: sport.customName,
            checkMarkVisibility: Auth2().privacyMatch(3),
            selected: _preferredSports != null &&
                _preferredSports.contains(sport.shortName),
            onLabelTap: () =>
            (widget._handleLabelClick
                ? _onTapAthleticsSportLabel(context, sport)
                : _onTapAthleticsSportCheck(context, sport)),
            onCheckTap: () => _onTapAthleticsSportCheck(context, sport)));
      }
    }
    return widgetList;
  }

  Widget buildMenSectionHeader(){
    bool allMenSelected = Sports().isAllSportsSelected(menSports, _preferredSports);
    String menSelectClearTextKey = allMenSelected ? "widget.athletics_teams.label.clear" : "widget.athletics_teams.label.select_all";
    String menSelectClearImageKey = allMenSelected ? "images/icon-x-orange-small.png" : "images/icon-check-simple.png";
    return Container(
      decoration: BoxDecoration(
          color: Styles().colors.fillColorPrimary,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4))),
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 8, top: 10, bottom: 10),
        child: Row(
          children: <Widget>[
            Expanded(child:
            Semantics(label:Localization().getStringEx(
                "widget.athletics_teams.label.men_sports.title",
                "MEN'S SPORTS"),
                hint: Localization().getStringEx('widget.athletics_teams.label.men_sports.title.hint', ''),
                header: true,
                excludeSemantics: true,
                child:
                Text(
                  Localization().getStringEx(
                      "widget.athletics_teams.label.men_sports.title",
                      "MEN'S SPORTS"),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: Styles().fontFamilies.bold,
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 1.0),
                ))),
            Visibility(visible: Auth2().privacyMatch(3),
              child: Semantics(excludeSemantics: true,
                label: Localization().getStringEx(
                    'widget.athletics_teams.men_sports.title.checkmark',
                    'Tap to select or deselect all men sports'),
                value: (allMenSelected?Localization().getStringEx("toggle_button.status.checked", "checked",) :
                Localization().getStringEx("toggle_button.status.unchecked", "unchecked")) +
                    ", "+ Localization().getStringEx("toggle_button.status.checkbox", "checkbox"),
                child: GestureDetector(
                  onTap: () {
                    Sports().switchAllSports(menSports, _preferredSports, !allMenSelected);
                    AppSemantics.announceCheckBoxStateChange(context, !allMenSelected,
                        Localization().getStringEx("widget.athletics_teams.label.men_sports.title", "MEN'S SPORTS"));// with ! because we announce before the actual state change
                  },
                  child: Row(children: <Widget>[
                    Text(Localization().getStringEx(menSelectClearTextKey, ''),
                      style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: Styles().fontFamilies.medium),), Padding(padding: EdgeInsets.symmetric(horizontal: 8),child: Image.asset(menSelectClearImageKey),)
                  ],),),),)
          ],
        ),
      ),
    );
  }

  Widget buildWomenSectionHeader(){
    bool allWomenSelected = Sports().isAllSportsSelected(womenSports, _preferredSports);
    String womenSelectClearTextKey = allWomenSelected ? "widget.athletics_teams.label.clear" : "widget.athletics_teams.label.select_all";
    String womenSelectClearImageKey = allWomenSelected ? "images/icon-x-orange-small.png" : "images/icon-check-simple.png";
    return Container(
      decoration: BoxDecoration(
          color: Styles().colors.fillColorPrimary,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4))),
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 8, top: 10, bottom: 10),
        child: Row(
          children: <Widget>[
            Expanded(child:
            Semantics(label:Localization().getStringEx(
                "widget.athletics_teams.label.women_sports.title",
                "WOMEN'S SPORTS"),
                hint: Localization().getStringEx('widget.athletics_teams.label.women_sports.title.hint', ''),
                header: true,
                excludeSemantics: true,
                child:
                Text(
                  Localization().getStringEx(
                      "widget.athletics_teams.label.women_sports.title",
                      "WOMEN'S SPORTS"),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: Styles().fontFamilies.bold,
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 1.0),
                ))),
            Visibility(visible: Auth2().privacyMatch(3),
              child: Semantics(excludeSemantics: true,
                label: Localization().getStringEx(
                    'widget.athletics_teams.women_sports.title.checkmark',
                    'Tap to select or deselect all women sports'),
                value: (allWomenSelected?Localization().getStringEx("toggle_button.status.checked", "checked",) :
                Localization().getStringEx("toggle_button.status.unchecked", "unchecked")) +
                    ", "+ Localization().getStringEx("toggle_button.status.checkbox", "checkbox"),
                child: GestureDetector(
                  onTap: () {
                    Sports().switchAllSports(womenSports, _preferredSports, !allWomenSelected);
                    AppSemantics.announceCheckBoxStateChange(context, !allWomenSelected,
                        Localization().getStringEx("widget.athletics_teams.label.women_sports.title", "WOMEN'S SPORTS"));// with ! because we announce before the actual state change
                  },
                  child: Row(children: <Widget>[
                    Text(Localization().getStringEx(womenSelectClearTextKey, ''),
                      style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: Styles().fontFamilies.medium),), Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Image.asset(womenSelectClearImageKey),)
                  ],),),),)
          ],
        ),
      ),
    );
  }

  void _onTapAthleticsSportLabel(BuildContext context, SportDefinition sport) {
    Analytics.instance.logSelect(target: "Sport Label Tap: "+sport.name);
    if (Connectivity().isNotOffline) {
      Navigator.push(context,
          CupertinoPageRoute(builder: (context) => AthleticsTeamPanel(sport)));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('widget.athletics_teams.label.offline.sports_events', 'Sports events are not available while offline.'));
    }
  }

  void _onTapAthleticsSportCheck(BuildContext context, SportDefinition sport) {
    Analytics.instance.logSelect(target: "Sport Check Tap: "+sport.name);

    if(widget.onSportTaped==null) {
      User().switchSportSubCategory(sport.shortName);
    } else {
      widget.onSportTaped(sport.shortName);
    }

    bool selected = _preferredSports != null &&
        _preferredSports.contains(sport.shortName);
    AppSemantics.announceCheckBoxStateChange(context, selected, sport?.customName);

    setState(() {});
  }

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == User.notifyInterestsUpdated || name == User.notifyUserUpdated) {
      _loadPreferredSports();
    }
  }
}
