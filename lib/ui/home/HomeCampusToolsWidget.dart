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
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/WellnessPanel.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/laundry/LaundryHomePanel.dart';
import 'package:illinois/ui/settings/SettingsIlliniCashPanel.dart';
import 'package:rokwire_plugin/ui/widgets/tile_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

import 'HomeWidgets.dart';

class HomeCampusToolsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<void>? refreshController;
  final HomeScrollableDragging? scrollableDragging;


  HomeCampusToolsWidget({Key? key, this.favoriteId, this.refreshController, this.scrollableDragging}) : super(key: key);

  _HomeCampusToolsWidgetState createState() => _HomeCampusToolsWidgetState();
}

class _HomeCampusToolsWidgetState extends State<HomeCampusToolsWidget> implements NotificationsListener {

  List<dynamic>? _contentListCodes;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      FlexUI.notifyChanged,
    ]);

    _contentListCodes = FlexUI()['home.campus_tools'] ?? [];
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  Widget? _widgetFromCode(BuildContext context, String code, int countPerRow) {
    String? title, hint, iconAsset;
    GestureTapCallback onTap;
    if (code == 'events') {
      title = Localization().getStringEx('widget.home_campus_tools.button.events.title', 'Events');
      hint = Localization().getStringEx('widget.home_campus_tools.button.events.hint', '');
      iconAsset = 'images/icon-campus-tools-events.png';
      onTap = _onTapEvents;
    }
    else if (code == 'dining') {
      title = Localization().getStringEx('widget.home_campus_tools.button.dining.title', 'Dining');
      hint = Localization().getStringEx('widget.home_campus_tools.button.dining.hint', '');
      iconAsset = 'images/icon-campus-tools-dining.png';
      onTap = _onTapDining;
    }
    else if (code == 'athletics') {
      title = Localization().getStringEx('widget.home_campus_tools.button.athletics.title', 'Athletics');
      hint = Localization().getStringEx('widget.home_campus_tools.button.athletics.hint', '');
      iconAsset = 'images/icon-campus-tools-athletics.png';
      onTap = _onTapAthletics;
    }
    else if (code == 'laundry') {
      title = Localization().getStringEx('widget.home_campus_tools.button.laundry.title', 'Laundry');
      hint = Localization().getStringEx('widget.home_campus_tools.button.laundry.hint', '');
      iconAsset = 'images/icon-campus-tools-laundry.png';
      onTap = _onTapLaundry;
    }
    else if (code == 'illini_cash') {
      title = Localization().getStringEx('widget.home_campus_tools.button.illini_cash.title', 'Illini Cash');
      hint = Localization().getStringEx('widget.home_campus_tools.button.illini_cash.hint', '');
      iconAsset = 'images/icon-campus-tools-illini-cash.png';
      onTap = _onTapIlliniCash;
    } else if (code == 'my_illini') {
      title = Localization().getStringEx('widget.home_campus_tools.button.my_illini.title', 'My Illini');
      hint = Localization().getStringEx('widget.home_campus_tools.button.my_illini.hint', '');
      iconAsset = 'images/icon-campus-tools-my-illini.png';
      onTap = _onTapMyIllini;
    } else if (code == 'wellness') {
      title = Localization().getStringEx('widget.home_campus_tools.button.wellness.title', 'Wellness');
      hint = Localization().getStringEx('widget.home_campus_tools.button.wellness.hint', '');
      iconAsset = 'images/icon-campus-tools-wellness.png';
      onTap = _onTapWellness;
    } else if (code == 'crisis_help') {
      title = Localization().getStringEx('widget.home_campus_tools.button.crisis_help.title', 'Crisis Help');
      hint = Localization().getStringEx('widget.home_campus_tools.button.crisis_help.hint', '');
      iconAsset = 'images/icon-campus-tools-crisis.png';
      onTap = _onTapCrisisHelp;
     } else {
      return null;
    }

    return (countPerRow == 1) ?
      TileWideButton(title: title, hint: hint, iconAsset: iconAsset, onTap: onTap) :
      TileButton(title: title, hint: hint, iconAsset: iconAsset, onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    final int widgetsPerRow = 2;
    if (_contentListCodes != null) {
      for (String code in _contentListCodes!) {
        Widget? widget = _widgetFromCode(context, code, widgetsPerRow);
        if (widget != null) {
          widgets.add(Expanded(child: widget),);
        }
      }
    }
    if (widgets.length == 0) {
      return Container();
    }
    while(0 < (widgets.length % widgetsPerRow)) {
      widgets.add(Expanded(child: Container(),));
    }
    int widgetsCount = widgets.length;
    int rowsCount = widgetsCount ~/ widgetsPerRow;
    List<Widget> rows = [];
    for (int i = 0; i < rowsCount; i++) {
      int startRowIndex = i * widgetsPerRow;
      int endIndex = min((startRowIndex + widgetsPerRow), widgetsCount);
      Row row = Row(children: widgets.sublist(startRowIndex, endIndex));
      rows.add(row);
    }

    rows.add(Container(height: 48,),);

    return HomeDropTargetWidget(favoriteId: widget.favoriteId, child:
      HomeSlantWidget(favoriteId: widget.favoriteId, scrollableDragging: widget.scrollableDragging,
        title: Localization().getStringEx('widget.home_campus_tools.label.campus_tools', 'Campus Resources'),
        child: Column(children: rows,
      ),
    ),);
  }

  void _updateContentListCodes() {
    List<dynamic>? contentListCodes = FlexUI()['home.campus_tools'];
    if ((contentListCodes != null) && !DeepCollectionEquality().equals(_contentListCodes, contentListCodes)) {
      setState(() {
        _contentListCodes = contentListCodes;
      });
    }
  }

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == Connectivity.notifyStatusChanged) {
      _updateContentListCodes();
    }
    else if (name == FlexUI.notifyChanged) {
      _updateContentListCodes();
    }
  }

  void _onTapEvents() {
    Analytics().logSelect(target: "Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(initialTab: ExploreTab.Events); } ));
  }
    
  void _onTapDining() {
    Analytics().logSelect(target: "Dining");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(initialTab: ExploreTab.Dining); } ));
  }

  void _onTapAthletics() {
    Analytics().logSelect(target: "Athletics");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel()));
  }

  void _onTapLaundry() {
    Analytics().logSelect(target: "Laundry");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel()));
  }

  void _onTapIlliniCash() {
    Analytics().logSelect(target: "Illini Cash");
    Navigator.push(
        context, CupertinoPageRoute(settings: RouteSettings(name: SettingsIlliniCashPanel.routeName), builder: (context) => SettingsIlliniCashPanel()));
  }

  void _onTapMyIllini() {
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
      //       'widget.home_campus_tools.header.my_illini.title', 'My Illini');
      //   Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: Config().myIlliniUrl, title: myIlliniPanelTitle,)));
      // }
    }
  }

  void _onTapWellness() {
    Analytics().logSelect(target: "Wellness");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessPanel()));

  }
  void _onTapCrisisHelp() {
    Analytics().logSelect(target: "Crisis Help");
    String? url = Config().crisisHelpUrl;
    if (StringUtils.isNotEmpty(url)) {
      launch(url!);
    } else {
      Log.e("Missing Config().crisisHelpUrl");
    }
  }
}

