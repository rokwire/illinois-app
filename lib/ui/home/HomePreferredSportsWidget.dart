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

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/home/HomeFavorite.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/athletics/AthleticsSportItemWidget.dart';
import 'package:illinois/ui/athletics/AthleticsTeamPanel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomePreferredSportsWidget extends StatefulWidget {

  final bool menSports;
  final bool womenSports;
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomePreferredSportsWidget({Key? key, this.menSports = false, this.womenSports = false, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: 'Sport Prefs' /*TBD: Localization */,
    );

  _HomePreferredSportsWidgetState createState() => _HomePreferredSportsWidgetState();
}

class _HomePreferredSportsWidgetState extends State<HomePreferredSportsWidget> implements NotificationsListener {
  final int _minPrivacyLevel = 3;

  bool _displayPreferredSports = true;

  List<SportDefinition>? _menSports;
  List<SportDefinition>? _womenSports;
  Set<String>?  _sportPreferences;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2UserPrefs.notifyInterestsChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refreshSports();
        }
      });
    }

    _menSports = widget.menSports ? Sports().menSports?.where((sport)=>(!_displayPreferredSports || (_sportPreferences != null && _sportPreferences!.contains(sport.shortName)))).toList() : null;
    _womenSports = widget.womenSports ? Sports().womenSports?.where((sport)=>(!_displayPreferredSports || (_sportPreferences != null && _sportPreferences!.contains(sport.shortName)))).toList() : null;
    _sportPreferences = Auth2().prefs?.sportsInterests ?? Set<String>();

    _setDisplayPreferredSports(Auth2().privacyMatch(_minPrivacyLevel));
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
    if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      _setDisplayPreferredSports(Auth2().privacyMatch(_minPrivacyLevel));
    }
    else if (name == Auth2UserPrefs.notifyInterestsChanged) {
      if (mounted) {
        setState(() {
          _sportPreferences = Auth2().prefs?.sportsInterests ?? Set<String>();
        });
      }
    }
  }

  void _refreshSports(){
    if (mounted) {
      setState(() {
        _menSports = widget.menSports ? Sports().menSports?.where((sport)=>(!_displayPreferredSports || (_sportPreferences != null && _sportPreferences!.contains(sport.shortName)))).toList() : null;
        _womenSports = widget.womenSports ? Sports().womenSports?.where((sport)=>(!_displayPreferredSports || (_sportPreferences != null && _sportPreferences!.contains(sport.shortName)))).toList() : null;
        _sportPreferences = Auth2().prefs?.sportsInterests ?? Set<String>();
      });
    }
  }

  bool get _hasMenSports {
    return CollectionUtils.isNotEmpty(_menSports);
  }

  bool get _hasWomenSports {
    return CollectionUtils.isNotEmpty(_womenSports);
  }

  @override
  Widget build(BuildContext context) {
    bool allMenSelected = Sports.isAllSportsSelected(_menSports, _sportPreferences);
    bool allWomenSelected = Sports.isAllSportsSelected(_womenSports, _sportPreferences);
    String menSelectClearTextKey = allMenSelected ? "widget.athletics_teams.label.clear" : "widget.athletics_teams.label.select_all";
    String menSelectClearImageKey = allMenSelected ? "images/icon-x-orange-small.png" : "images/icon-check-simple.png";
    String womenSelectClearTextKey = allWomenSelected ? "widget.athletics_teams.label.clear" : "widget.athletics_teams.label.select_all";
    String womenSelectClearImageKey = allWomenSelected ? "images/icon-x-orange-small.png" : "images/icon-check-simple.png";

    List<Widget> content = <Widget>[];
    if (_hasMenSports) {
      content.add(Column(children: <Widget>[
        Container(decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
          child: Semantics(
            label: Localization().getStringEx('widget.home_prefered_sports.label.mens_sports', "MEN'S SPORTS"),
            hint: Localization().getStringEx('widget.home_prefered_sports.label.mens_sports.hint', ""), header:true, excludeSemantics: true,
            child: Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 10, bottom: 10),
              child: Row(children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: Text(
                        Localization().getStringEx('widget.home_prefered_sports.label.mens_sports', "MEN'S SPORTS"),
                        textAlign: TextAlign.left,
                        style: TextStyle(fontFamily: Styles().fontFamilies!.bold, color: Colors.white, fontSize: 14, letterSpacing: 1.0),
                      )
                    ),
                    Visibility(visible: (!_displayPreferredSports && Auth2().privacyMatch(_minPrivacyLevel)),
                      child: Expanded(
                        flex: 3,
                        child:Semantics(excludeSemantics: true,
                        label: Localization().getStringEx('widget.athletics_teams.men_sports.title.checkmark', 'Tap to select or deselect all men sports'),
                        checked: allMenSelected,
                        child: GestureDetector(
                          onTap: () {
                            Analytics().logSelect(target: "Sport Label Tap: MEN'S SPORTS");
                            AppSemantics.announceCheckBoxStateChange(context, !allMenSelected,
                                Localization().getStringEx("widget.athletics_teams.label.men_sports.title", "MEN'S SPORTS"));// with ! because we announce before the actual state change
                            Auth2().prefs?.toggleSportInterests(Sports.switchAllSports(_menSports, _sportPreferences, !allMenSelected));
                          } ,
                          child: Row(children: <Widget>[
                            Expanded(child:
                            Text(Localization().getStringEx(menSelectClearTextKey, ''),
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: Styles().fontFamilies!.medium),),
                            ),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Image.asset(menSelectClearImageKey),
                            ),
                          ],),
                        ),
                      )),
                    ),
                  ],
                ),
              )),
        ),
        Container(decoration: BoxDecoration(border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1)),
          child: Column(children: _createMenSportItems(),),
        ),
        Container(height: 20,),
      ],),);
    }

    if (_hasWomenSports) {
      content.add(Column(children: <Widget>[
          Container(
            decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
            child: Semantics(
                label: Localization().getStringEx('widget.home_prefered_sports.label.womens_sports', "WOMEN'S SPORTS"),
                hint: Localization().getStringEx('widget.home_prefered_sports.label.womens_sports.hint', ""),header:true, excludeSemantics: true,
                child: Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 10, bottom: 10),
                  child: Row(children: <Widget>[
                      Expanded(
                        flex: 5,
                        child: Text(
                          Localization().getStringEx('widget.home_prefered_sports.label.womes_sports', "WOMEN'S SPORTS"),
                          textAlign: TextAlign.left,
                          style: TextStyle(fontFamily: Styles().fontFamilies!.bold, color: Colors.white, fontSize: 14, letterSpacing: 1.0),
                        ),
                      ),

                      Visibility(visible: (!_displayPreferredSports && Auth2().privacyMatch(_minPrivacyLevel)),
                        child: Expanded(
                          flex: 3,
                          child: Semantics(excludeSemantics: true,
                          label: Localization().getStringEx('widget.athletics_teams.women_sports.title.checkmark', 'Tap to select or deselect all women sports'),
                          checked: allWomenSelected,
                          child: GestureDetector(
                            onTap: () {
                              Analytics().logSelect(target: "Sport Label Tap: WOMEN'S SPORTS");
                              AppSemantics.announceCheckBoxStateChange(context, !allWomenSelected,
                                  Localization().getStringEx("widget.athletics_teams.label.women_sports.title", "WOMEN'S SPORTS"));// with ! because we announce before the actual state change
                              Auth2().prefs?.toggleSportInterests(Sports.switchAllSports(_womenSports, _sportPreferences, !allWomenSelected));
                            },
                            child: Row(children: <Widget>[
                              Expanded(child:
                              Text(Localization().getStringEx(womenSelectClearTextKey, ''),
                                style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: Styles().fontFamilies!.medium),),
                              ),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Image.asset(womenSelectClearImageKey),
                              )
                            ],),
                          ),
                        )),
                      ),
                    ],
                  ),
                )),
          ),
          Container(decoration: BoxDecoration(border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1)),
            child: Column(children: _createWomenSportItems(),),
          ),
          Container(height: 20,),
      ],),);
    }

    return Stack(alignment: Alignment.topCenter, children: <Widget>[
      Column(children: <Widget>[
        Container(color: Styles().colors!.backgroundVariant, height: 100,),
        Container(height: 52, decoration: BoxDecoration(image: DecorationImage(image: AssetImage("images/slant-down-right-grey.png"), fit: BoxFit.fill)),)
      ],),
      Column(
        children: <Widget>[
          !Auth2().privacyMatch(_minPrivacyLevel)? Container():
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top:16), child:Row(children: <Widget>[
            Expanded(child:_HomePreferredSportFilterTab(text: Localization().getStringEx('widget.home_prefered_sports.button.your_teams.title', 'Your Teams'), hint: Localization().getStringEx('widget.home_prefered_sports.button.your_teams.hint', ''), left: true, selected: _displayPreferredSports, onTap: () { _setDisplayPreferredSports(true); },)),
            Expanded(child:_HomePreferredSportFilterTab(text: Localization().getStringEx('widget.home_prefered_sports.button.all_sports.title', 'All Illinois Sports'), hint: Localization().getStringEx('widget.home_prefered_sports.button.all_sports.hint', ''), left: false, selected: !_displayPreferredSports, onTap: () { _setDisplayPreferredSports(false); })),
          ],)),
          Padding(padding: EdgeInsets.all(16), child:
            Column(children: content,),
          ),
          Container(height: 48,),
        ],
      )],);
  }

  List<Widget> _createMenSportItems() {
    return _createSportItemsForSection(_menSports);
  }

  List<Widget> _createWomenSportItems() {
    return _createSportItemsForSection(_womenSports);
  }

  List<Widget> _createSportItemsForSection(List<SportDefinition>? sports) {
    List<Widget> list = [];

    if(sports != null) {
      for (SportDefinition sport in sports) {
        if (list.isNotEmpty) {
          list.add(Divider(color: Styles().colors!.surfaceAccent, height: 1,));
        }

        list.add(AthleticsSportItemWidget(
          sport: sport,
          label: sport.customName,
          showChevron: true,
          selected: (_sportPreferences != null) && _sportPreferences!.contains(sport.shortName),
          onLabelTap: () => _onTapAthleticsSportLabel(sport),
          onCheckTap: () => _onTapAthleticsSportCheckmark(sport),
        ));
      }
    }
    return list;
  }

  void _setDisplayPreferredSports(bool displayPreferredSports) {
    if (_displayPreferredSports != displayPreferredSports) {
      _displayPreferredSports = !_displayPreferredSports;
      _refreshSports();
    }
  }

  void _onTapAthleticsSportLabel(SportDefinition sport) {
    Analytics().logSelect(target: "HomePreferedSports TapSportLabel: "+ sport.name!);
    if (Connectivity().isNotOffline) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsTeamPanel(sport)));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('widget.home_prefered_sports.label.offline.sports', 'Sports are not available while offline.'));
    }
  }

  void _onTapAthleticsSportCheckmark(SportDefinition sport) {
    Analytics().logSelect(target: "HomePreferedSports TapSportCheckmark: "+ sport.name!);
    AppSemantics.announceCheckBoxStateChange(context, _sportPreferences?.contains(sport.shortName) ?? false, sport.customName);
    Auth2().prefs?.toggleSportInterest(sport.shortName);
  }

}

class _HomePreferredSportFilterTab extends StatelessWidget {
  final String? text;
  final String? hint;
  final bool? left;
  final bool? selected;
  final GestureTapCallback? onTap;

  _HomePreferredSportFilterTab({Key? key, this.text, this.hint = '', this.left, this.selected, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Semantics(label: text, hint:hint, button:true, excludeSemantics: true, child:Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected! ? Colors.white : Color(0xffededed),
            border: Border.all(color: Color(0xffc1c1c1), width: 1, style: BorderStyle.solid),
            borderRadius: left! ? BorderRadius.horizontal(left: Radius.circular(100.0)) : BorderRadius.horizontal(right: Radius.circular(100.0)),
          ),
          child:Center(child: Text(text!,style:TextStyle(
              fontFamily: selected! ? Styles().fontFamilies!.extraBold : Styles().fontFamilies!.medium,
              fontSize: 16,
              color: Styles().colors!.fillColorPrimary),
              overflow: TextOverflow.ellipsis,
          )),
        ),
        ));
  }
}

