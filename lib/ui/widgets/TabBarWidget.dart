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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/main.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/RootPanel.dart';
import 'package:illinois/ui/wallet/WalletSheet.dart';
import 'package:illinois/service/Styles.dart';

class TabBarWidget extends StatefulWidget {

  static double tabBarHeight = 60;
  static double tabTextSize = 12;

  final TabController? tabController;

  TabBarWidget({this.tabController});

  _TabBarWidgetState createState() => _TabBarWidgetState();
}

class _TabBarWidgetState extends State<TabBarWidget>  implements NotificationsListener {

  List<dynamic>? _contentListCodes;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, FlexUI.notifyChanged);

    if(widget.tabController != null) {
      widget.tabController!.addListener(_onTabControllerChanged);
    }

    _contentListCodes = _getContentListCodes();
  }

  @override
  void dispose() {
    super.dispose();

    NotificationService().unsubscribe(this);

    if(widget.tabController != null) {
      widget.tabController!.removeListener(_onTabControllerChanged);
    }
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
    double height = 35 + (TabBarWidget.tabTextSize * MediaQuery.of(context).textScaleFactor); // 35 is icon height + paddings
    if(TabBarWidget.tabBarHeight < height){
      TabBarWidget.tabBarHeight = height;
    }


    Color? backgroundColor;
    switch(Config().configEnvironment) {
      case ConfigEnvironment.dev:        backgroundColor = Colors.yellowAccent; break;
      case ConfigEnvironment.test:       backgroundColor = Colors.lightGreenAccent; break;
      case ConfigEnvironment.production: backgroundColor = Colors.white; break;
      default: break;
    }
    return Container(
      decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(top: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1, style: BorderStyle.solid))),
      child: SafeArea(
        child: Container(
          height: TabBarWidget.tabBarHeight,
          child: Row(
            children: _buildTabs(),
          ),
        ),
      ),
    );
  }

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
            iconResource: 'images/tab-home.png',
            iconResourceSelected: 'images/tab-home-selected.png',
            selected: (widget.tabController != null) && (widget.tabController!.index == tabIndex),
            onTap: ()=>_onSwitchTab(tabIndex, 'Home'),
          ),
        ));
      }
      else if (code == 'explore') {
        tabs.add(Expanded(
          child: TabWidget(
            label: Localization().getStringEx('tabbar.explore.title', 'Explore'),
            hint: Localization().getStringEx('tabbar.explore.hint', ''),
            iconResource: 'images/tab-explore.png',
            iconResourceSelected: 'images/tab-explore-selected.png',
            selected: (widget.tabController != null) && (widget.tabController!.index == tabIndex),
            onTap: ()=>_onSwitchTab(tabIndex, 'Explore'),
          )
        ));
      }
      else if (code == 'wallet') {
        tabs.add(Expanded(
          child: TabWidget(
            label: Localization().getStringEx('tabbar.wallet.title', 'Wallet'),
            hint: Localization().getStringEx('tabbar.wallet.hint', ''),
            iconResource: 'images/tab-wallet.png',
            selected: false,
            onTap: ()=>_onShowWalletSheet('Wallet'),
          )
        ));
      }
      else if (code == 'browse') {
        tabs.add(Expanded(
          child: TabWidget(
            label: Localization().getStringEx('tabbar.browse.title', 'Browse'),
            hint: Localization().getStringEx('tabbar.browse.hint', ''),
            iconResource: 'images/tab-browse.png',
            iconResourceSelected: 'images/tab-browse-selected.png',
            selected: (widget.tabController != null) && (widget.tabController!.index == tabIndex),
            onTap: ()=>_onSwitchTab(tabIndex, 'Browse'),
          ),
        ));
      }
    }
    return tabs;
  }

  void _onTabControllerChanged(){
    setState(() {});
  }

  void _onSwitchTab(int tabIndex, String tabName){
    Analytics().logSelect(target: tabName);

    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    RootPanel? rootPanel = App.instance?.panelState?.rootPanel;
    RootTab? tab = rootPanel?.panelState?.getRootTabByIndex(tabIndex);
    rootPanel?.selectTab(rootTab: tab);
  }

  void _onShowWalletSheet(String tabName){
    Analytics().logSelect(target: tabName);
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
  final String? iconResource;
  final String? iconResourceSelected;
  final bool selected;
  final GestureTapCallback onTap;

  TabWidget(
      {this.label,
      this.iconResource,
      this.iconResourceSelected,
      this.hint = '',
      this.selected = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    double scaleFactor = MediaQuery.of(context).textScaleFactor;
    scaleFactor = scaleFactor > 2 ? 2 : scaleFactor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: <Widget>[
          Center(
            child: Semantics(
                label: label,
                hint: hint,
                excludeSemantics: true,
                child: Container(
                  padding: EdgeInsets.only(top: 10),
                  height: TabBarWidget.tabBarHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Image(
                              image: (selected
                                  ? AssetImage(iconResourceSelected!)
                                  : AssetImage(iconResource!)),
                              width: 20.0,
                              height: 20.0)),
                      Expanded(child:
                      Text(
                        label!,
                        textScaleFactor: scaleFactor,
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies!.bold,
                            color: selected ? Styles().colors!.fillColorSecondary : Styles().colors!.mediumGray,
                            fontSize: TabBarWidget.tabTextSize),
                      )
                      )
                    ],
                  ),
                )),
          ),
          selected ? Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(height: 4, color: Styles().colors!.fillColorSecondary,)
              ],
            ),
          ) : Container(),
        ],
      ),
    );
  }
}
