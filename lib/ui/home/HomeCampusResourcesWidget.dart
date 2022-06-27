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
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/groups/GroupsHomePanel.dart';
import 'package:illinois/ui/guide/CampusGuidePanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/polls/PollsHomePanel.dart';
import 'package:illinois/ui/settings/SettingsNotificationsContentPanel.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/laundry/LaundryHomePanel.dart';
import 'package:illinois/ui/settings/SettingsIlliniCashPanel.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

import 'HomeWidgets.dart';

class HomeCampusResourcesWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeCampusResourcesWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.campus_resources.label.campus_tools', 'Campus Resources');

  _HomeCampusResourcesWidgetState createState() => _HomeCampusResourcesWidgetState();
}

class _HomeCampusResourcesWidgetState extends State<HomeCampusResourcesWidget> implements NotificationsListener {

  List<String>? _displayCodes;
  Set<String>? _availableCodes;

  @override
  void initState() {

    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
        }
      });
    }

    _availableCodes = _buildAvailableCodes();
    _displayCodes = _buildDisplayCodes();

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
    if (name == FlexUI.notifyChanged) {
      _updateAvailableCodes();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _updateDisplayCodes();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> contentCodes = _buildContentCodes();
    return contentCodes.isNotEmpty ? HomeSlantWidget(favoriteId: widget.favoriteId,
        title: Localization().getStringEx('widget.home.campus_resources.label.campus_tools', 'Campus Resources'),
        titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
        child: Padding(padding: EdgeInsets.only(bottom: 24), child:
          HomeCampusResourcesGridWidget(favoriteCategory: widget.favoriteId, contentCodes: contentCodes, promptFavorite: true,)
        )
        ,
    ) : Container();
  }

  List<String> _buildContentCodes() {
    List<String> contentCodesList = <String>[];
    if (_displayCodes != null) {
      for (String code in _displayCodes!.reversed) {
        if ((_availableCodes == null) || _availableCodes!.contains(code)) {
          contentCodesList.add(code);
        }
      }
    }
    return contentCodesList;
  }


  Set<String>? _buildAvailableCodes() => JsonUtils.setStringsValue(FlexUI()['home.campus_resources']);

  void _updateAvailableCodes() {
    Set<String>? availableCodes = JsonUtils.setStringsValue(FlexUI()['home.campus_resources']);
    if ((availableCodes != null) && !DeepCollectionEquality().equals(_availableCodes, availableCodes) && mounted) {
      setState(() {
        _availableCodes = availableCodes;
      });
    }
  }

  List<String>? _buildDisplayCodes() {
    LinkedHashSet<String>? favorites = Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName(category: widget.favoriteId));
    if (favorites == null) {
      // Build a default set of favorites
      List<String>? fullContent = JsonUtils.listStringsValue(FlexUI().contentSourceEntry('home.campus_resources'));
      if (fullContent != null) {
        favorites = LinkedHashSet<String>.from(fullContent.reversed);
        Future.delayed(Duration(), () {
          Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: widget.favoriteId), favorites);
        });
      }
    }
    
    return (favorites != null) ? List.from(favorites) : null;
  }

  void _updateDisplayCodes() {
    List<String>? displayCodes = _buildDisplayCodes();
    if ((displayCodes != null) && !DeepCollectionEquality().equals(_displayCodes, displayCodes) && mounted) {
      setState(() {
        _displayCodes = displayCodes;
      });
    }
  }
}

class HomeCampusResourcesGridWidget extends StatelessWidget {
  final String? favoriteCategory;
  final bool promptFavorite;
  final List<String> contentCodes;

  HomeCampusResourcesGridWidget({Key? key, required this.contentCodes, this.favoriteCategory, this.promptFavorite = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: _buildContentList(context),);
  }

  List<Widget> _buildContentList(BuildContext context) {
    final int widgetsPerRow = 2;
    List<Widget> contentList = <Widget>[];
    List<Widget> currentRow = <Widget>[];
    for (String code in contentCodes) {
      Widget? contentEntry = _widgetFromCode(context, code);
      if (contentEntry != null) {
        currentRow.add(Expanded(child: contentEntry));
        if (widgetsPerRow <= currentRow.length) {
          contentList.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: List.from(currentRow)));
          currentRow.clear();
        }
      }
    }
    if (0 < currentRow.length) {
      while (currentRow.length < widgetsPerRow) {
        currentRow.add(Expanded(child: Container()));
      }
      contentList.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: List.from(currentRow)));
      currentRow.clear();
    }
    return contentList;
  }

  Widget? _widgetFromCode(BuildContext context, String code) {
    if (code == 'events') {
      return CampusResourceButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.events.title', 'Events'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.events.hint', ''),
        iconAsset: 'images/icon-browse-events.png',
        favorite: HomeFavorite(code, category: favoriteCategory),
        promptFavorite: promptFavorite,
        onTap: () => _onTapEvents(context),
      );
    }
    else if (code == 'dining') {
      return CampusResourceButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.dining.title', 'Dining'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.dining.hint', ''),
        iconAsset: 'images/icon-browse-dinings.png',
        favorite: HomeFavorite(code, category: favoriteCategory),
        promptFavorite: promptFavorite,
        onTap: () => _onTapDining(context),
      );
    }
    else if (code == 'athletics') {
      return CampusResourceButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.athletics.title', 'Athletics'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.athletics.hint', ''),
        iconAsset: 'images/icon-browse-athletics.png',
        favorite: HomeFavorite(code, category: favoriteCategory),
        promptFavorite: promptFavorite,
        onTap: () => _onTapAthletics(context)
      );
    }
    else if (code == 'illini_cash') {
      return CampusResourceButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.illini_cash.title', 'Illini Cash'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.illini_cash.hint', ''),
        iconAsset: 'images/icon-browse-illini-cash.png',
        favorite: HomeFavorite(code, category: favoriteCategory),
        promptFavorite: promptFavorite,
        onTap: () => _onTapIlliniCash(context)
      );
    }
    else if (code == 'laundry') {
      return CampusResourceButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.laundry.title', 'Laundry'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.laundry.hint', ''),
        iconAsset: 'images/icon-browse-laundry.png',
        favorite: HomeFavorite(code, category: favoriteCategory),
        promptFavorite: promptFavorite,
        onTap: () => _onTapLaundry(context)
      );
    }
    else if (code == 'my_illini') {
      return CampusResourceButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.my_illini.title', 'My Illini'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.my_illini.hint', ''),
        iconAsset: 'images/icon-browse-my-illini.png',
        favorite: HomeFavorite(code, category: favoriteCategory),
        promptFavorite: promptFavorite,
        onTap: () => _onTapMyIllini(context)
      );
    }
    else if (code == 'wellness') {
      return CampusResourceButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.wellness.title', 'Wellness'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.wellness.hint', ''),
        iconAsset: 'images/icon-browse-wellness.png',
        favorite: HomeFavorite(code, category: favoriteCategory),
        promptFavorite: promptFavorite,
        onTap: () => _onTapWellness(context)
      );
    }
    else if ((code == 'crisis_help') && _canCrisisHelp) {
      return CampusResourceButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.crisis_help.title', 'Crisis Help'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.crisis_help.hint', ''),
        iconAsset: 'images/icon-browse-crisis-help.png',
        favorite: HomeFavorite(code, category: favoriteCategory),
        promptFavorite: promptFavorite,
        onTap: () => _onTapCrisisHelp(context)
      );
    }
    else if (code == 'groups') {
      return CampusResourceButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.groups.title', 'Groups'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.groups.hint', ''),
        iconAsset: 'images/icon-browse-groups.png',
        favorite: HomeFavorite(code, category: favoriteCategory),
        promptFavorite: promptFavorite,
        onTap: () => _onTapGroups(context),
      );
    }
    else if (code == 'quick_polls') {
      return CampusResourceButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.quick_polls.title', 'Quick Polls'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.quick_polls.hint', ''),
        iconAsset: 'images/icon-browse-quick-polls.png',
        favorite: HomeFavorite(code, category: favoriteCategory),
        promptFavorite: promptFavorite,
        onTap: () => _onTapQuickPolls(context),
      );
    }
    else if (code == 'campus_guide') {
      return CampusResourceButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.campus_guide.title', 'Campus Guide'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.campus_guide.hint', ''),
        iconAsset: 'images/icon-browse-campus-guide.png',
        favorite: HomeFavorite(code, category: favoriteCategory),
        promptFavorite: promptFavorite,
        onTap: () => _onTapCampusGuide(context),
      );
    }
    else if (code == 'inbox') {
      return CampusResourceButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.inbox.title', 'Notifications'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.inbox.hint', ''),
        iconAsset: 'images/icon-browse-inbox.png',
        favorite: HomeFavorite(code, category: favoriteCategory),
        promptFavorite: promptFavorite,
        onTap: () => _onTapInbox(context),
      );
    }
    else {
      return null;
    }
  }

  void _onTapEvents(BuildContext context) {
    Analytics().logSelect(target: "Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(initialItem: ExploreItem.Events); } ));
  }
    
  void _onTapDining(BuildContext context) {
    Analytics().logSelect(target: "Dining");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(initialItem: ExploreItem.Dining); } ));
  }

  void _onTapAthletics(BuildContext context) {
    Analytics().logSelect(target: "Athletics");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel()));
  }

  void _onTapIlliniCash(BuildContext context) {
    Analytics().logSelect(target: "Illini Cash");
    SettingsIlliniCashPanel.present(context);
  }

  void _onTapLaundry(BuildContext context) {
    Analytics().logSelect(target: "Laundry");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel()));
  }

  void _onTapMyIllini(BuildContext context) {
    Analytics().logSelect(target: "My Illini");
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.my_illini', 'My Illini not available while offline.'));
    }
    else if (StringUtils.isNotEmpty(Config().myIlliniUrl)) {

      // Please make this use an external browser
      // Ref: https://github.com/rokwire/illinois-app/issues/1110
      launch(Config().myIlliniUrl!);

      //
      // Until webview_flutter get fixed for the dropdowns we will continue using it as a webview plugin,
      // but we will open in an external browser all problematic pages.
      // The other plugin doesn't work with VoiceOver
      // Ref: https://github.com/rokwire/illinois-client/issues/284
      //      https://github.com/flutter/plugins/pull/2330
      //
      // if (Platform.isAndroid) {
      //   launch(Config().myIlliniUrl);
      // }
      // else {
      //   String myIlliniPanelTitle = Localization().getStringEx(
      //       'widget.home.campus_resources.header.my_illini.title', 'My Illini');
      //   Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: Config().myIlliniUrl, title: myIlliniPanelTitle,)));
      // }
    }
  }

  void _onTapWellness(BuildContext context) {
    Analytics().logSelect(target: "Wellness");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel()));
  }

  bool get _canCrisisHelp => StringUtils.isNotEmpty(Config().crisisHelpUrl);
  
  void _onTapCrisisHelp(BuildContext context) {
    Analytics().logSelect(target: "Crisis Help");
    String? url = Config().crisisHelpUrl;
    if (StringUtils.isNotEmpty(url)) {
      launch(url!);
    } else {
      Log.e("Missing Config().crisisHelpUrl");
    }
  }

  void _onTapGroups(BuildContext context) {
    Analytics().logSelect(target: "Groups");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsHomePanel()));
  }

  void _onTapQuickPolls(BuildContext context) {
    Analytics().logSelect(target: "Quick Polls");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
  }

  void _onTapCampusGuide(BuildContext context) {
    Analytics().logSelect(target: "Campus Guide");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
  }

  void _onTapInbox(BuildContext context) {
    Analytics().logSelect(target: "Inbox");
    SettingsNotificationsContentPanel.present(context, content: SettingsNotificationsContent.inbox);
  }
}


class CampusResourceButton extends StatelessWidget {
  final HomeFavorite? favorite;
  final String? title;
  final String? hint;
  final String? iconAsset;
  final GestureTapCallback? onTap;
  final bool promptFavorite;

  const CampusResourceButton({ Key? key, this.favorite, this.title,  this.hint, this.iconAsset,  this.onTap, this.promptFavorite = true }) : super(key: key);

  bool get _canFavorite => FlexUI().contentSourceEntry((favorite?.category != null) ? 'home.${favorite?.category}' : 'home')?.contains(favorite?.favoriteId) ?? false;

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];
    if (title != null) {
      contentList.add(Text(title!, textAlign: TextAlign.center, style: TextStyle(color: Styles().colors?.fillColorPrimary, fontFamily: Styles().fontFamilies?.bold, fontSize: 20)));
    } 
    if ((title != null) && (iconAsset != null)) {
      contentList.add(Container(height: 26));
    } 
    if (iconAsset != null) {
      contentList.add(Image.asset(iconAsset!));
    }

    return InkWell(onTap: onTap, child:
      Semantics(label: title, hint: hint, button: true, excludeSemantics: true, child:
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), child:
          Container(decoration: BoxDecoration(color: Styles().colors?.white ?? const Color(0x00FFFFFF), borderRadius: BorderRadius.circular(4), border: Border.all(color: Styles().colors?.white ?? const Color(0x00FFFFFF), width: 2), boxShadow: [const BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
            Padding(padding: EdgeInsets.only(left: 16, bottom: 16), child: 
              Column(children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child:
                    Padding(padding: EdgeInsets.only(top: 16), child: 
                      Text(title ?? '', style: TextStyle(color: Styles().colors?.fillColorPrimary, fontFamily: Styles().fontFamilies?.bold, fontSize: 20)),
                    ),
                  ),
                  Opacity(opacity: _canFavorite ? 1 : 0, child:
                    HomeFavoriteButton(favorite: favorite, style: FavoriteIconStyle.Button, prompt: promptFavorite,)
                  ),
                ],),
                Row(children: [
                  Expanded(child:
                    Padding(padding: EdgeInsets.only(left: 16, right: 16), child:
                      Align(alignment: Alignment.centerRight, child:
                        SizedBox(width: 44, height: 44, child:
                          Align(alignment: Alignment.bottomRight, child:
                            Image.asset(iconAsset!)
                          ),
                        )
                      )
                    ),
                  ),
                ],),
              ],),
            ),
          ),
        ),
      ),
    );

  }
}
