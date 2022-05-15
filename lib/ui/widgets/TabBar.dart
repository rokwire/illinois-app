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
  static const String notifyWalletShow = "edu.illinois.rokwire.tabbar_widget.wallet.show";
  static const String notifyWalletClose = "edu.illinois.rokwire.tabbar_widget.wallet.close";

  final bool? walletExpanded;

  TabBar({Key? key, TabController? tabController, this.walletExpanded}) : super(key: key, tabController: tabController);

  @override
  Widget? buildTab(BuildContext context, String code, int index) {
    if ((code == 'home') || (code == 'athletics')) {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.home.title', 'Home'),
        hint: Localization().getStringEx('tabbar.home.hint', ''),
        iconAsset: 'images/tab-home.png',
        selectedIconAsset: 'images/tab-home-selected.png',
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
    else if (code == 'wallet') {
      return (walletExpanded != true) ?
        rokwire.TabWidget(
          label: Localization().getStringEx('tabbar.wallet.title', 'Wallet'),
          hint: Localization().getStringEx('tabbar.wallet.hint', ''),
          iconAsset: 'images/tab-wallet.png',
          selected: false,
          onTap: (rokwire.TabWidget tabWidget) => _onShowWalletSheet(context, tabWidget),
        ) :
        rokwire.TabCloseWidget(
          label: Localization().getStringEx('panel.wallet.button.close.title', 'close'),
          hint: Localization().getStringEx('panel.wallet.button.close.hint', ''),
          iconAsset: 'images/icon-close-big.png',
          onTap: (rokwire.TabCloseWidget tabCloseWidget) => _onCloseWalletSheet(context, tabCloseWidget),
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
    else if (code == 'favorites') {
      return rokwire.TabWidget(
        label: Localization().getStringEx('tabbar.favorites.title', 'Favorites'),
        hint: Localization().getStringEx('tabbar.favorites.hint', ''),
        iconAsset: 'images/tab-saved.png',
        selectedIconAsset: 'images/tab-saved-selected.png',
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

  void _onShowWalletSheet(BuildContext context, rokwire.TabWidget tabWidget) {
    Analytics().logSelect(target: tabWidget.label);
    NotificationService().notify(TabBar.notifyWalletShow);
  }

  void _onCloseWalletSheet(BuildContext context, rokwire.TabCloseWidget tabCloseWidget) {
    Analytics().logSelect(target: tabCloseWidget.label);
    NotificationService().notify(TabBar.notifyWalletClose);
  }
}
