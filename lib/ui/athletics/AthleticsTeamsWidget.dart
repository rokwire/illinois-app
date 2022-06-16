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

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/athletics/AthleticsSportItemWidget.dart';
import 'package:illinois/ui/athletics/AthleticsTeamPanel.dart';
import 'package:rokwire_plugin/service/styles.dart';

typedef void SportsTapListener (String  sport);
class AthleticsTeamsWidget extends StatefulWidget {

  final bool handleTeamTap;
  final int? sportsLimit;
  final bool updateSportPrefs;

  AthleticsTeamsWidget({this.handleTeamTap = false, this.updateSportPrefs = true, this.sportsLimit});

  @override
  AthleticsTeamsWidgetState createState() => AthleticsTeamsWidgetState();
}

class AthleticsTeamsWidgetState extends State<AthleticsTeamsWidget> implements NotificationsListener {
  List<SportDefinition>? _menSports;
  List<SportDefinition>? _womenSports;
  Set<String>? _preferredSports;

  List<SportDefinition>? get menSports => _menSports;
  List<SportDefinition>? get womenSports => _womenSports;

  @override
  void initState() {
    NotificationService().subscribe(this, [Auth2UserPrefs.notifyInterestsChanged]);
    _menSports = Sports().menSports;
    _womenSports = Sports().womenSports;
    _preferredSports = Auth2().prefs?.sportsInterests  ?? Set<String>();
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
    if (name == Auth2UserPrefs.notifyInterestsChanged) {
      if (mounted) {
        setState(() {
          _preferredSports = Auth2().prefs?.sportsInterests ?? Set<String>();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      buildMenSectionHeader(),
      Container(decoration: BoxDecoration(border:Border.all(color: Styles().colors!.surfaceAccent!, width: 1)), child:
        Column(children: buildSportList(_menSports),),
      ),
      Container(height: 20,),
      buildWomenSectionHeader(),
      Container(decoration: BoxDecoration(border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1)), child:
        Column(children: buildSportList(_womenSports),),
      ),
    ],);
  }

  List<Widget> buildSportList(List<SportDefinition>? sports) {
    List<Widget> widgetList = [];
    if (sports != null && sports.isNotEmpty) {
      int visibleCount = (widget.sportsLimit != null) ? min(widget.sportsLimit!, sports.length) : sports.length;
      for (int index = 0; index < visibleCount; index++) {
        SportDefinition sport = sports[index];
        if (widgetList.isNotEmpty) {
          widgetList.add(Divider(color: Styles().colors!.surfaceAccent, height: 1,));
        }
        widgetList.add(AthleticsSportItemWidget(
            sport: sport,
            showChevron: widget.handleTeamTap,
            label: sport.customName,
            checkMarkVisibility: Auth2().privacyMatch(3) && widget.updateSportPrefs,
            selected: _preferredSports != null && _preferredSports!.contains(sport.shortName),
            onLabelTap: () => widget.handleTeamTap ? _onTapAthleticsTeam(sport) : _onTapAthleticsSportPref(sport),
            onCheckTap: () => _onTapAthleticsSportPref(sport)));
      }
    }
    return widgetList;
  }

  Widget buildMenSectionHeader(){
    bool allMenSelected = Sports.isAllSportsSelected(_menSports, _preferredSports);
    String menSelectClearTextKey = allMenSelected ? "widget.athletics_teams.label.clear" : "widget.athletics_teams.label.select_all";
    String menSelectClearImageKey = allMenSelected ? "images/icon-x-orange-small.png" : "images/icon-check-simple.png";
    return Container(decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))), child:
      Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 10, bottom: 10), child:
        Row(children: <Widget>[
          Expanded(child:
            Semantics(label:Localization().getStringEx("widget.athletics_teams.label.men_sports.title", "MEN'S SPORTS"), hint: Localization().getStringEx('widget.athletics_teams.label.men_sports.title.hint', ''), header: true, excludeSemantics: true, child:
              Text(Localization().getStringEx("widget.athletics_teams.label.men_sports.title", "MEN'S SPORTS"), textAlign: TextAlign.left, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, color: Colors.white, fontSize: 14, letterSpacing: 1.0),),
            ),
          ),
          Visibility(visible: Auth2().privacyMatch(3) && widget.updateSportPrefs, child:
            Semantics(excludeSemantics: true, label: Localization().getStringEx('widget.athletics_teams.men_sports.title.checkmark', 'Tap to select or deselect all men sports'), value: (allMenSelected?Localization().getStringEx("toggle_button.status.checked", "checked",) : Localization().getStringEx("toggle_button.status.unchecked", "unchecked")) + ", "+ Localization().getStringEx("toggle_button.status.checkbox", "checkbox"), child:
              GestureDetector(onTap: _onToggleManSports, child:
                Row(children: <Widget>[
                  Text(Localization().getStringEx(menSelectClearTextKey, ''), style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: Styles().fontFamilies!.medium),), Padding(padding: EdgeInsets.symmetric(horizontal: 8),child: Image.asset(menSelectClearImageKey),)
                ],),
              ),
            ),
          ),
        ],),
      ),
    );
  }

  Widget buildWomenSectionHeader(){
    bool allWomenSelected = Sports.isAllSportsSelected(_womenSports, _preferredSports);
    String womenSelectClearTextKey = allWomenSelected ? "widget.athletics_teams.label.clear" : "widget.athletics_teams.label.select_all";
    String womenSelectClearImageKey = allWomenSelected ? "images/icon-x-orange-small.png" : "images/icon-check-simple.png";
    return Container(decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.only( topLeft: Radius.circular(4), topRight: Radius.circular(4))), child:
      Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 10, bottom: 10), child:
        Row(children: <Widget>[
          Expanded(child:
            Semantics(label:Localization().getStringEx("widget.athletics_teams.label.women_sports.title", "WOMEN'S SPORTS"), hint: Localization().getStringEx('widget.athletics_teams.label.women_sports.title.hint', ''), header: true, excludeSemantics: true, child:
              Text(Localization().getStringEx("widget.athletics_teams.label.women_sports.title", "WOMEN'S SPORTS"), textAlign: TextAlign.left, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, color: Colors.white, fontSize: 14, letterSpacing: 1.0),),
            ),
          ),
          Visibility(visible: Auth2().privacyMatch(3) && widget.updateSportPrefs, child:
            Semantics(excludeSemantics: true, label: Localization().getStringEx( 'widget.athletics_teams.women_sports.title.checkmark', 'Tap to select or deselect all women sports'), value: (allWomenSelected?Localization().getStringEx("toggle_button.status.checked", "checked",) : Localization().getStringEx("toggle_button.status.unchecked", "unchecked")) +", "+ Localization().getStringEx("toggle_button.status.checkbox", "checkbox"), child:
              GestureDetector(onTap: _onToggleWomenSports, child:
                Row(children: <Widget>[
                  Text(Localization().getStringEx(womenSelectClearTextKey, ''), style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: Styles().fontFamilies!.medium),),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Image.asset(womenSelectClearImageKey),
                  )
                ],)
              ,),
            ),
          ),
        ],),
      ),
    );
  }

  void _onToggleManSports() {
    Analytics().logSelect(target: "Sport Label Tap: MEN'S SPORTS");
    bool allMenSelected = Sports.isAllSportsSelected(_menSports, _preferredSports);
    AppSemantics.announceCheckBoxStateChange(context, !allMenSelected,
        Localization().getStringEx("widget.athletics_teams.label.men_sports.title", "MEN'S SPORTS"));// with ! because we announce before the actual state change
    Auth2().prefs?.toggleSportInterests(Sports.switchAllSports(_menSports, _preferredSports, !allMenSelected));
  }

  void _onToggleWomenSports() {
    bool allWomenSelected = Sports.isAllSportsSelected(_womenSports, _preferredSports);
    Analytics().logSelect(target: "Sport Label Tap: WOMEN'S SPORTS");
    AppSemantics.announceCheckBoxStateChange(context, !allWomenSelected,
        Localization().getStringEx("widget.athletics_teams.label.women_sports.title", "WOMEN'S SPORTS"));// with ! because we announce before the actual state change
    Auth2().prefs?.toggleSportInterests(Sports.switchAllSports(_womenSports, _preferredSports, !allWomenSelected));
  }

  void _onTapAthleticsTeam(SportDefinition sport) {
    Analytics().logSelect(target: "Sport Label Tap: "+sport.name!);
    if (Connectivity().isNotOffline) {
      Navigator.push(context,
          CupertinoPageRoute(builder: (context) => AthleticsTeamPanel(sport)));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('widget.athletics_teams.label.offline.sports_events', 'Sports events are not available while offline.'));
    }
  }

  void _onTapAthleticsSportPref(SportDefinition sport) {
    Analytics().logSelect(target: "Sport Check Tap: "+sport.name!);
    AppSemantics.announceCheckBoxStateChange(context, _preferredSports?.contains(sport.shortName) ?? false, sport.customName);
    Auth2().prefs?.toggleSportInterest(sport.shortName);
  }

}
