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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/wallet/WalletSheet.dart';
import 'package:rokwire_plugin/service/styles.dart';

class TabBarWidget extends StatefulWidget {

  static const String notifySelectionChanged = "edu.illinois.rokwire.tabbar_widget.selection.changed";

  final TabController? tabController;
  final bool? walletExpanded;

  TabBarWidget({this.tabController, this.walletExpanded});

  _TabBarWidgetState createState() => _TabBarWidgetState();
}

class _TabBarWidgetState extends State<TabBarWidget>  implements NotificationsListener {

  List<dynamic>? _contentListCodes;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, FlexUI.notifyChanged);
    widget.tabController?.addListener(_onTabControllerChanged);
    _contentListCodes = _getContentListCodes();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
    widget.tabController?.removeListener(_onTabControllerChanged);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateContentListCodes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(decoration: BoxDecoration(color: backgroundColor, border: border), child:
        SafeArea(child:
            Row(children: 
              _buildTabs(),
            ),
        ),
      ),
    ],);
  }

  @protected
  Color? get backgroundColor {
    switch(Config().configEnvironment) {
      case ConfigEnvironment.dev:        return Colors.yellowAccent;
      case ConfigEnvironment.test:       return Colors.lightGreenAccent;
      case ConfigEnvironment.production: return Colors.white;
      default:                           return Colors.white;
    }
  }

  @protected
  BoxBorder? get border => Border(top: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1, style: BorderStyle.solid));

  List<Widget> _buildTabs() {
    List<Widget> tabs = [];
    int tabsCount = (_contentListCodes != null) ? _contentListCodes!.length : 0;
    for (int tabIndex = 0; tabIndex < tabsCount; tabIndex++) {
      String code = _contentListCodes![tabIndex];
      if ((code == 'home') || (code == 'athletics')) {
        tabs.add(Expanded(
          child: TabWidget(
            label: Localization().getStringEx('tabbar.home.title', 'Home'),
            hint: Localization().getStringEx('tabbar.home.hint', ''),
            iconAsset: 'images/tab-home.png',
            selectedIconAsset: 'images/tab-home-selected.png',
            selected: (widget.tabController?.index == tabIndex),
            onTap: (TabWidget tabWidget) => _onSwitchTab(tabIndex, tabWidget),
          ),
        ));
      }
      else if (code == 'explore') {
        tabs.add(Expanded(
          child: TabWidget(
            label: Localization().getStringEx('tabbar.explore.title', 'Explore'),
            hint: Localization().getStringEx('tabbar.explore.hint', ''),
            iconAsset: 'images/tab-explore.png',
            selectedIconAsset: 'images/tab-explore-selected.png',
            selected: (widget.tabController?.index == tabIndex),
            onTap: (TabWidget tabWidget) => _onSwitchTab(tabIndex, tabWidget),
          )
        ));
      }
      else if (code == 'wallet') {
        if (widget.walletExpanded != true) {
          tabs.add(Expanded(
            child: TabWidget(
              label: Localization().getStringEx('tabbar.wallet.title', 'Wallet'),
              hint: Localization().getStringEx('tabbar.wallet.hint', ''),
              iconAsset: 'images/tab-wallet.png',
              selected: false,
              onTap: (TabWidget tabWidget) => _onShowWalletSheet(tabWidget),
            )
          ));
        }
        else {
          tabs.add(Expanded(
            child: TabCloseWidget(
              label: Localization().getStringEx('panel.wallet.button.close.title', 'close'),
              hint: Localization().getStringEx('panel.wallet.button.close.hint', ''),
              iconAsset: 'images/icon-close-big.png',
              onTap: _onCloseWalletSheet,
            )
          ));
        }
      }
      else if (code == 'browse') {
        tabs.add(Expanded(
          child: TabWidget(
            label: Localization().getStringEx('tabbar.browse.title', 'Browse'),
            hint: Localization().getStringEx('tabbar.browse.hint', ''),
            iconAsset: 'images/tab-browse.png',
            selectedIconAsset: 'images/tab-browse-selected.png',
            selected: (widget.tabController?.index == tabIndex),
            onTap: (TabWidget tabWidget) => _onSwitchTab(tabIndex, tabWidget),
          ),
        ));
      }
    }
    return tabs;
  }

  void _onTabControllerChanged(){
    setState(() {});
  }

  void _onSwitchTab(int tabIndex, TabWidget tabWidget) {
    Analytics().logSelect(target: tabWidget.label);
    NotificationService().notify(TabBarWidget.notifySelectionChanged, tabIndex);
  }

  void _onShowWalletSheet(TabWidget tabWidget) {
    Analytics().logSelect(target: tabWidget.label);
    showModalBottomSheet(context: context,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        builder: (context){
          return WalletSheet();
        }
    );
  }

  void _onCloseWalletSheet(TabCloseWidget tabCloseWidget) {
    Analytics().logSelect(target: tabCloseWidget.label);
    Navigator.pop(context);
  }

  List<String>? _getContentListCodes() {
    try {
      dynamic tabsList = FlexUI()['tabbar'];
      return (tabsList is List) ? tabsList.cast<String>() : null;
    }
    catch(e) {
      print(e.toString());
    }
    return null;
  }

  void _updateContentListCodes() {
    List<String>? contentListCodes = _getContentListCodes();
    if ((contentListCodes != null) && !DeepCollectionEquality().equals(_contentListCodes, contentListCodes)) {
      if (mounted) {
        setState(() {
          _contentListCodes = contentListCodes;
        });
      }
    }
  }
}

class TabWidget extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? iconAsset;
  final String? selectedIconAsset;
  final bool selected;
  final void Function(TabWidget tabWidget) onTap;

  TabWidget(
      {this.label,
      this.iconAsset,
      this.selectedIconAsset,
      this.hint,
      this.selected = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () => onTap(this), behavior: HitTestBehavior.translucent, child:
      Stack(children: <Widget>[
        buildTab(context),
        selected ? buildSelectedIndicator(context) : Container(),
        ],
      ),
    );
  }

  // Tab

  @protected
  Widget buildTab(BuildContext context) => Center(child:
    Semantics(label: label, hint: hint, excludeSemantics: true, child:
      Padding(padding: tabPadding, child:
        Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Padding(padding: tabIconPadding, child:
            getTabIcon(context)
          ),
          Padding(padding: tabTextPadding, child:
            getTabText(context)
          ),
        ],),
      ),
    ),
  );

  @protected
  EdgeInsetsGeometry get tabPadding => EdgeInsets.only(top: 10);

  @protected
  EdgeInsetsGeometry get tabIconPadding => EdgeInsets.only(bottom: 4);

  @protected
  EdgeInsetsGeometry get tabTextPadding => EdgeInsets.all(0);

  @protected
  TextAlign get tabTextAlign => TextAlign.center;

  @protected
  TextStyle get tabTextStyle => TextStyle(fontFamily: Styles().fontFamilies!.bold, color: selected ? Styles().colors!.fillColorSecondary : Styles().colors!.mediumGray, fontSize: 12);

  @protected
  double getTextScaleFactor(BuildContext context) => min(MediaQuery.of(context).textScaleFactor, 2);

  @protected
  Widget getTabText(BuildContext context) => Row(children: [
    Expanded(child:
      Text(label ?? '', textScaleFactor: getTextScaleFactor(context), textAlign: tabTextAlign, style: tabTextStyle,),
    )
  ]);

  @protected
  Widget getTabIcon(BuildContext context)  {
    String? asset = selected ? (selectedIconAsset ?? iconAsset) : iconAsset;
    return (asset != null) ? Image.asset(asset, width: tabIconSize.width, height: tabIconSize.height) : Container(width: tabIconSize.width, height: tabIconSize.height);
  }

  @protected
  Size get tabIconSize => Size(20, 20);

  // Selected Indicator

  @protected
  Widget buildSelectedIndicator(BuildContext context) => Positioned.fill(child:
    Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
      Container(height: selectedIndicatorHeight, color: selectedIndicatorColor)
    ],),
  );

  @protected
  double get selectedIndicatorHeight => 4;

  @protected
  Color? get selectedIndicatorColor => Styles().colors?.fillColorSecondary;

}

class TabCloseWidget extends StatelessWidget {
  final String? label;
  final String? hint;
  final String iconAsset;
  final void Function(TabCloseWidget tabWidget) onTap;

  TabCloseWidget({
    this.label,
    this.hint,
    required this.iconAsset,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(label: label, hint: hint, button: true, child:
      GestureDetector(onTap: () => onTap(this), behavior: HitTestBehavior.translucent, child:
        Center(child:
          Image.asset(iconAsset, excludeFromSemantics: true,),
        ),
      )
    );
  }

}