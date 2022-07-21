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
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/tab_bar.dart' as rokwire;

class TabBar extends rokwire.TabBar {

  static const String notifySelectionChanged = "edu.illinois.rokwire.tabbar_widget.selection.changed";

  TabBar({Key? key, TabController? tabController}) : super(key: key, tabController: tabController);

  @override
  Widget? buildTab(BuildContext context, String code, int index) {
    if (code == 'home') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.home.title', 'Home'),
        hint: Localization().getStringEx('tabbar.home.hint', ''),
        iconAsset: 'images/tab-home.png',
        selectedIconAsset: 'images/tab-home-selected.png',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else if (code == 'favorites') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.favorites.title', 'Favorites'),
        hint: Localization().getStringEx('tabbar.favorites.hint', ''),
        iconAsset: 'images/tab-favorites.png',
        selectedIconAsset: 'images/tab-favorites-selected.png',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else if (code == 'explore') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.explore.title', 'Explore'),
        hint: Localization().getStringEx('tabbar.explore.hint', ''),
        iconAsset: 'images/tab-explore.png',
        selectedIconAsset: 'images/tab-explore-selected.png',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else if (code == 'browse') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.browse.title', 'Browse'),
        hint: Localization().getStringEx('tabbar.browse.hint', ''),
        iconAsset: 'images/tab-browse.png',
        selectedIconAsset: 'images/tab-browse-selected.png',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else if (code == 'maps') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.map.title', 'Map'),
        hint: Localization().getStringEx('tabbar.map.hint', 'Map Page'),
        iconAsset: 'images/tab-navigate.png',
        selectedIconAsset: 'images/tab-navigate-selected.png',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else if (code == 'academics') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.academics.title', 'Academics'),
        hint: Localization().getStringEx('tabbar.academics.hint', ''),
        iconAsset: 'images/tab-academics.png',
        selectedIconAsset: 'images/tab-academics-selected.png',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else if (code == 'wellness') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.wellness.title', 'Wellness'),
        hint: Localization().getStringEx('tabbar.wellness.hint', ''),
        iconAsset: 'images/tab-wellness.png',
        selectedIconAsset: 'images/tab-wellness-selected.png',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else {
      return null;
    }
  }

  void _onSwitchTab(int tabIndex, rokwire.TabWidget tabWidget) {
    Analytics().logSelect(target: tabWidget.label);
    NotificationService().notify(TabBar.notifySelectionChanged, tabIndex);
  }


  // 1.1.1 Can you make the Nav bar white please for Dev builds for now. I'll let you know when we can go back to yellow.
  // (https://github.com/rokwire/illinois-app/issues/1852)
  @override
  Color? get backgroundColor {
    switch(Config().configEnvironment) {
      case ConfigEnvironment.test:       return Colors.lightGreenAccent;
      case ConfigEnvironment.dev:        //return Colors.yellowAccent;
      case ConfigEnvironment.production: return Styles().colors?.surface ?? Colors.white;
      default:                           return Colors.white;
    }
  }
}
