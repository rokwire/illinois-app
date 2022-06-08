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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/groups/GroupsHomePanel.dart';
import 'package:illinois/ui/guide/CampusGuidePanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/polls/PollsHomePanel.dart';
import 'package:illinois/ui/settings/SettingsNotificationsContentPanel.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
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
import 'package:rokwire_plugin/ui/widgets/tile_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

import 'HomeWidgets.dart';

class HomeCampusResourcesWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeCampusResourcesWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: Localization().getStringEx('widget.home.campus_resources.label.campus_tools', 'Campus Resources'),
    );

  _HomeCampusResourcesWidgetState createState() => _HomeCampusResourcesWidgetState();
}

class _HomeCampusResourcesWidgetState extends State<HomeCampusResourcesWidget> implements NotificationsListener {

  List<String>? _displayCodes;
  Set<String>? _availableCodes;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
    ]);

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
    List<Widget> contentList = _buildContentList();
    return contentList.isNotEmpty ? HomeSlantWidget(favoriteId: widget.favoriteId,
        title: Localization().getStringEx('widget.home.campus_resources.label.campus_tools', 'Campus Resources'),
        titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
        child: Column(children: contentList,),
    ) : Container();
  }

  List<Widget> _buildContentList() {
    final int widgetsPerRow = 2;
    List<Widget> contentList = <Widget>[];
    if (_displayCodes != null) {
      List<Widget> currentRow = <Widget>[];
      for (String code in _displayCodes!.reversed) {
        if ((_availableCodes == null) || _availableCodes!.contains(code)) {
          Widget? contentEntry = _widgetFromCode(code);
          if (contentEntry != null) {
            currentRow.add(Expanded(child: contentEntry));
            if (widgetsPerRow <= currentRow.length) {
              contentList.add(Row(children: List.from(currentRow)));
              currentRow.clear();
            }
          }
        }
      }
      if (0 < currentRow.length) {
        while (currentRow.length < widgetsPerRow) {
          currentRow.add(Expanded(child: Container()));
        }
        contentList.add(Row(children: List.from(currentRow)));
        currentRow.clear();
      }
    }
    if (0 < contentList.length) {
      contentList.add(Container(height: 24,),);
    }
    return contentList;
  }

  Widget? _widgetFromCode(String code) {
    if (code == 'events') {
      return TileButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.events.title', 'Events'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.events.hint', ''),
        iconAsset: 'images/icon-campus-tools-events.png',
        onTap: _onTapEvents,);
    }
    else if (code == 'dining') {
      return TileButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.dining.title', 'Dining'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.dining.hint', ''),
        iconAsset: 'images/icon-campus-tools-dining.png',
        onTap: _onTapDining,);
    }
    else if (code == 'athletics') {
      return TileButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.athletics.title', 'Athletics'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.athletics.hint', ''),
        iconAsset: 'images/icon-campus-tools-athletics.png',
        onTap: _onTapAthletics);
    }
    else if (code == 'illini_cash') {
      return TileButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.illini_cash.title', 'Illini Cash'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.illini_cash.hint', ''),
        iconAsset: 'images/icon-campus-tools-illini-cash.png',
        onTap: _onTapIlliniCash);
    }
    else if (code == 'laundry') {
      return TileButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.laundry.title', 'Laundry'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.laundry.hint', ''),
        iconAsset: 'images/icon-campus-tools-laundry.png',
        onTap: _onTapLaundry);
    }
    else if (code == 'my_illini') {
      return TileButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.my_illini.title', 'My Illini'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.my_illini.hint', ''),
        iconAsset: 'images/icon-campus-tools-my-illini.png',
        onTap: _onTapMyIllini);
    }
    else if (code == 'wellness') {
      return TileButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.wellness.title', 'Wellness'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.wellness.hint', ''),
        iconAsset: 'images/icon-campus-tools-wellness.png',
        onTap: _onTapWellness);
    }
    else if ((code == 'crisis_help') && _canCrisisHelp) {
      return TileButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.crisis_help.title', 'Crisis Help'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.crisis_help.hint', ''),
        iconAsset: 'images/icon-campus-tools-crisis.png',
        onTap: _onTapCrisisHelp);
    }
    else if (code == 'groups') {
      return TileButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.groups.title', 'Groups'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.groups.hint', ''),
        iconAsset: 'images/icon-campus-tools-groups.png',
        onTap: _onTapGroups,
      );
    }
    else if (code == 'quick_polls') {
      return TileButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.quick_polls.title', 'Quick Polls'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.quick_polls.hint', ''),
        iconAsset: 'images/icon-campus-tools-quick-polls.png',
        onTap: _onTapQuickPolls,
      );
    }
    else if (code == 'campus_guide') {
      return TileButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.campus_guide.title', 'Campus Guide'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.campus_guide.hint', ''),
        iconAsset: 'images/icon-campus-tools-campus-guide.png',
        onTap: _onTapCampusGuide,
      );
    }
    else if (code == 'inbox') {
      return TileButton(
        title: Localization().getStringEx('widget.home.campus_resources.button.inbox.title', 'Notifications'),
        hint: Localization().getStringEx('widget.home.campus_resources.button.inbox.hint', ''),
        iconAsset: 'images/icon-campus-tools-inbox.png',
        onTap: _onTapInbox,
      );
    }
    else {
      return null;
    }
  }

  Set<String>? _buildAvailableCodes() => JsonUtils.setStringsValue(FlexUI()['home.campus_resources']);

  void _updateAvailableCodes() {
    Set<String>? availableCodes = JsonUtils.setStringsValue(FlexUI()['home.campus_resources']);
    if ((availableCodes != null) && !DeepCollectionEquality().equals(_availableCodes, availableCodes)) {
      setState(() {
        _availableCodes = availableCodes;
      });
    }
  }

  List<String> _buildDisplayCodes() {
    LinkedHashSet<String>? favorites = Auth2().prefs?.getFavorites(HomeCampusResourcesFavorite.favoriteKeyName);
    if (favorites == null) {
      // Build a default set of favorites
      List<String>? fullContent = JsonUtils.listStringsValue(FlexUI().contentSourceEntry('home.campus_resources'));
      if (fullContent != null) {
        Auth2().prefs?.setFavorites(HomeCampusResourcesFavorite.favoriteKeyName, favorites = LinkedHashSet<String>.from(fullContent.reversed));
      }
    }
    
    return (favorites != null) ? List.from(favorites) : <String>[];
  }

  void _updateDisplayCodes() {
    List<String> displayCodes = _buildDisplayCodes();
    if (displayCodes.isNotEmpty && !DeepCollectionEquality().equals(_displayCodes, displayCodes)) {
      setState(() {
        _displayCodes = displayCodes;
      });
    }
  }

  void _onTapEvents() {
    Analytics().logSelect(target: "Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(initialItem: ExploreItem.Events); } ));
  }
    
  void _onTapDining() {
    Analytics().logSelect(target: "Dining");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(initialItem: ExploreItem.Dining); } ));
  }

  void _onTapAthletics() {
    Analytics().logSelect(target: "Athletics");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel()));
  }

  void _onTapIlliniCash() {
    Analytics().logSelect(target: "Illini Cash");
    Navigator.push(
        context, CupertinoPageRoute(settings: RouteSettings(name: SettingsIlliniCashPanel.routeName), builder: (context) => SettingsIlliniCashPanel()));
  }

  void _onTapLaundry() {
    Analytics().logSelect(target: "Laundry");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel()));
  }

  void _onTapMyIllini() {
    Analytics().logSelect(target: "My Illini");
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('widget.home.campus_resources.label.my_illini.offline', 'My Illini not available while offline.'));
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

  void _onTapWellness() {
    Analytics().logSelect(target: "Wellness");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel()));
  }

  bool get _canCrisisHelp => StringUtils.isNotEmpty(Config().crisisHelpUrl);
  
  void _onTapCrisisHelp() {
    Analytics().logSelect(target: "Crisis Help");
    String? url = Config().crisisHelpUrl;
    if (StringUtils.isNotEmpty(url)) {
      launch(url!);
    } else {
      Log.e("Missing Config().crisisHelpUrl");
    }
  }

  void _onTapGroups() {
    Analytics().logSelect(target: "Groups");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsHomePanel()));
  }

  void _onTapQuickPolls() {
    Analytics().logSelect(target: "Quick Polls");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
  }

  void _onTapCampusGuide() {
    Analytics().logSelect(target: "Campus Guide");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
  }

  void _onTapInbox() {
    Analytics().logSelect(target: "Inbox");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsNotificationsContentPanel(content: SettingsNotificationsContent.inbox)));
  }
}


// HomeCampusResourcesFavorite

class HomeCampusResourcesFavorite implements Favorite {
  final String? id;
  HomeCampusResourcesFavorite(this.id);

  bool operator == (o) => o is HomeCampusResourcesFavorite && o.id == id;

  int get hashCode => (id?.hashCode ?? 0);

  static const String favoriteKeyName = "homeCampusResourcesWidgetIds";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => id;
}
