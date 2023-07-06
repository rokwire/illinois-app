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
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
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
        iconKey: 'home-gray',
        selectedIconKey: 'home',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else if (code == 'favorites') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.favorites.title', 'Favorites'),
        hint: Localization().getStringEx('tabbar.favorites.hint', ''),
        iconKey: 'star-outline-gray',
        selectedIconKey: 'star-filled',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else if (code == 'explore') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.explore.title', 'Explore'),
        hint: Localization().getStringEx('tabbar.explore.hint', ''),
        iconKey: 'compass-gray',
        selectedIconKey: 'compass',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else if (code == 'browse') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.browse.title', 'Browse'),
        hint: Localization().getStringEx('tabbar.browse.hint', ''),
        iconKey: 'campus-tools-outline-gray',
        selectedIconKey: 'campus-tools-filled',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else if (code == 'maps') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.map.title', 'Map'),
        hint: Localization().getStringEx('tabbar.map.hint', 'Map Page'),
        iconKey: 'location-outline-gray',
        selectedIconKey: 'location',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else if (code == 'assistant') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.assistant.title', 'Assistant'),
        hint: Localization().getStringEx('tabbar.assistant.hint', 'Illinois Assistant Page'),
        iconKey: 'search-outline-gray',
        selectedIconKey: 'search',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else if (code == 'academics') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.academics.title', 'Academics'),
        hint: Localization().getStringEx('tabbar.academics.hint', ''),
        iconKey: 'academics-gray',
        selectedIconKey: 'academics',
        selected: (tabController?.index == index),
        onTap: (rokwire.TabWidget tabWidget) => _onSwitchTab(index, tabWidget),
      );
    }
    else if (code == 'wellness') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.wellness.title', 'Wellness'),
        hint: Localization().getStringEx('tabbar.wellness.hint', ''),
        iconKey: 'wellness-gray',
        selectedIconKey: 'wellness',
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
}
