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

import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Connectivity.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/WellnessPanel.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/laundry/LaundryHomePanel.dart';
import 'package:illinois/ui/settings/SettingsIlliniCashPanel.dart';
import 'package:illinois/ui/widgets/LinkTileButton.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeCampusToolsWidget extends StatefulWidget {

  _HomeCampusToolsWidgetState createState() => _HomeCampusToolsWidgetState();
}

class _HomeCampusToolsWidgetState extends State<HomeCampusToolsWidget> implements NotificationsListener {

  List<dynamic> _contentListCodes;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      FlexUI.notifyChanged,
    ]);

    _contentListCodes = FlexUI()['campus_tools'] ?? [];
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  Widget _widgetFromCode(BuildContext context, String code, int countPerRow) {
    String label, hint, iconPath;
    GestureTapCallback onTap;
    if (code == 'events') {
      label = Localization().getStringEx('widget.home_campus_tools.button.events.title', 'Events');
      hint = Localization().getStringEx('widget.home_campus_tools.button.events.hint', '');
      iconPath = 'images/icon-campus-tools-events.png';
      onTap = _onTapEvents;
    }
    else if (code == 'dining') {
      label = Localization().getStringEx('widget.home_campus_tools.button.dining.title', 'Dining');
      hint = Localization().getStringEx('widget.home_campus_tools.button.dining.hint', '');
      iconPath = 'images/icon-campus-tools-dining.png';
      onTap = _onTapDining;
    }
    else if (code == 'athletics') {
      label = Localization().getStringEx('widget.home_campus_tools.button.athletics.title', 'Athletics');
      hint = Localization().getStringEx('widget.home_campus_tools.button.athletics.hint', '');
      iconPath = 'images/icon-campus-tools-athletics.png';
      onTap = _onTapAthletics;
    }
    else if (code == 'laundry') {
      label = Localization().getStringEx('widget.home_campus_tools.button.laundry.title', 'Laundry');
      hint = Localization().getStringEx('widget.home_campus_tools.button.laundry.hint', '');
      iconPath = 'images/icon-campus-tools-laundry.png';
      onTap = _onTapLaundry;
    }
    else if (code == 'illini_cash') {
      label = Localization().getStringEx('widget.home_campus_tools.button.illini_cash.title', 'Illini Cash');
      hint = Localization().getStringEx('widget.home_campus_tools.button.illini_cash.hint', '');
      iconPath = 'images/icon-campus-tools-illini-cash.png';
      onTap = _onTapIlliniCash;
    } else if (code == 'my_illini') {
      label = Localization().getStringEx('widget.home_campus_tools.button.my_illini.title', 'My Illini');
      hint = Localization().getStringEx('widget.home_campus_tools.button.my_illini.hint', '');
      iconPath = 'images/icon-campus-tools-my-illini.png';
      onTap = _onTapMyIllini;
    } else if (code == 'wellness') {
      label = Localization().getStringEx('widget.home_campus_tools.button.wellness.title', 'Wellness');
      hint = Localization().getStringEx('widget.home_campus_tools.button.wellness.hint', '');
      iconPath = 'images/icon-campus-tools-wellness.png';
      onTap = _onTapWellness;
     } else {
      return null;
    }

    if (countPerRow == 1) {
      return Expanded(child: LinkTileWideButton(label: label, hint: hint, iconPath: iconPath, onTap: onTap));
    }
    else {
      double width = (0 < countPerRow) ? (MediaQuery.of(context).size.width / countPerRow - 20) : 200;
      return LinkTileSmallButton(width: width, label: label, hint: hint, iconPath: iconPath, onTap: onTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    final int widgetsPerRow = 2;
    for (String code in _contentListCodes) {
      Widget widget = _widgetFromCode(context, code, widgetsPerRow);
      if (widget != null) {
        widgets.add(widget);
      }
    }
    int widgetsCount = widgets.length;
    if (widgetsCount == 0) {
      return Container();
    }
    int widgetsMod = (widgetsCount % widgetsPerRow);
    int rowsWholePart = widgetsCount ~/ widgetsPerRow;
    int rowsCount = (widgetsMod == 0) ? rowsWholePart : rowsWholePart + 1;
    List<Widget> rows = [];
    for (int i = 0; i < rowsCount; i++) {
      int startRowIndex = i * widgetsPerRow;
      int endIndex = min((startRowIndex + widgetsPerRow), widgetsCount);
      Row row = Row(children: widgets.sublist(startRowIndex, endIndex));
      rows.add(row);
    }
    return Column(
      children: <Widget>[
        SectionTitlePrimary(title: Localization().getStringEx('widget.home_campus_tools.label.campus_tools', 'Campus Resources'),
          iconPath: 'images/campus-tools.png',
          children: rows,),
        Container(height: 48,),
      ],
    );
  }

  void _updateContentListCodes() {
    List<dynamic> contentListCodes = FlexUI()['campus_tools'];
    if ((contentListCodes != null) ?? !DeepCollectionEquality().equals(_contentListCodes, contentListCodes)) {
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
    Analytics.instance.logSelect(target: "Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(initialTab: ExploreTab.Events, showHeaderBack: true,); } ));
  }
    
  void _onTapDining() {
    Analytics.instance.logSelect(target: "Dinings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(initialTab: ExploreTab.Dining, showHeaderBack: true,); } ));
  }

  void _onTapAthletics() {
    Analytics.instance.logSelect(target: "Athletics");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel()));
  }

  void _onTapLaundry() {
    Analytics.instance.logSelect(target: "Laundry");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel()));
  }

  void _onTapIlliniCash() {
    Analytics.instance.logSelect(target: "Illini Cash");
    Navigator.push(
        context, CupertinoPageRoute(settings: RouteSettings(name: SettingsIlliniCashPanel.routeName), builder: (context) => SettingsIlliniCashPanel()));
  }

  void _onTapMyIllini() {
    Analytics.instance.logSelect(target: "My Illini");
    if (Connectivity().isNotOffline && (Config().myIlliniUrl != null)) {
      String myIlliniPanelTitle = Localization().getStringEx(
          'widget.home_campus_tools.header.my_illini.title', 'My Illini');

      //
      // Until webview_flutter get fixed for the dropdowns we will continue using it as a webview plugin,
      // but we will open in an external browser all problematic pages.
      // The other plugin doesn't work with VoiceOver
      // Ref: https://github.com/rokwire/illinois-client/issues/284
      //      https://github.com/flutter/plugins/pull/2330
      //
      if (Platform.isAndroid) {
        launch(Config().myIlliniUrl);
      }
      else {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: Config().myIlliniUrl, title: myIlliniPanelTitle,)));
      }
    }
  }

  void _onTapWellness() {
    Analytics.instance.logSelect(target: "Wellness");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessPanel()));

  }
}

