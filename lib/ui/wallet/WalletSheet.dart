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
import 'package:illinois/main.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/RootPanel.dart';
import 'package:illinois/ui/wallet/WalletPanel.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/service/Styles.dart';

class WalletSheet extends StatelessWidget{

  static const String initialRouteName = "initial";

  final String? ensureVisibleCard;

  WalletSheet({Key? key, this.ensureVisibleCard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ClipRRect(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24),),
        child: Container(
          color: Styles().colors!.surface,
          child: DraggableScrollableSheet(
              maxChildSize: 0.95,
              initialChildSize: 0.95,
              expand: false,
              builder: (context, scrollController){
                return Column(
                  children: <Widget>[
                    Container(height: 16,),
                    Container(
                        height: 2,
                        width: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(3.5)),
                          color: Styles().colors!.mediumGray,
                        )
                    ),
                    Expanded(
                      child:WalletPanel(scrollController: scrollController, ensureVisibleCard: ensureVisibleCard),
                    ),
                    _WalletTabBarWidget(),
                    //CloseSheetButton(onTap: ()=>Navigator.of(context, rootNavigator: true).pop(),),
                  ],
                );
              }
          ),
        ),
      ),
    );
  }
}

class _WalletTabBarWidget extends StatefulWidget{

  //static const double tabBarHeight = 60;

  final TabController? tabController;

  _WalletTabBarWidget({this.tabController});

  _WalletTabBarWidgetState createState() => _WalletTabBarWidgetState();
}

class _WalletTabBarWidgetState extends State<_WalletTabBarWidget> implements NotificationsListener {

  List<dynamic>? _contentListCodes;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, FlexUI.notifyChanged);
    _contentListCodes = _getContentListCodes();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
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
    return SafeArea(
      child: Container(
        height: TabBarWidget.tabBarHeight,
        decoration: BoxDecoration(
            color: (Config().configEnvironment == ConfigEnvironment.dev) ? Colors.yellow : Colors.white,
            border: Border(top: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1, style: BorderStyle.solid))),
        child: Row(
          children: _buildTabs(),
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
            onTap: ()=>_onSwitchTab(context, tabIndex),
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
            onTap: ()=>_onSwitchTab(context, tabIndex),
          )
        ));
      }
      else if (code == 'wallet') {
        tabs.add(Expanded(
            child: Semantics(button: true,label: Localization().getStringEx("panel.wallet.button.close.title", "close"), child:
              GestureDetector(
                onTap: (){
                  Analytics().logSelect(target: 'Close');
                  Navigator.pop(context);
                },
                behavior: HitTestBehavior.translucent,
                child: Center(
                  child: Image.asset('images/icon-close-big.png', excludeFromSemantics: true,),
                ),
              )
            ),
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
            onTap: ()=>_onSwitchTab(context, tabIndex),
          ),
        ));
      }
    }
    return tabs;
  }

  void _onSwitchTab(BuildContext context, int tabIndex){
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    var rootPanel = App.instance?.panelState?.rootPanel;
    if (rootPanel != null) {
      RootTab? tab = rootPanel.panelState?.getRootTabByIndex(tabIndex);
      rootPanel.selectTab(rootTab: tab);
    }
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
      setState(() {
        _contentListCodes = contentListCodes;
      });
    }
  }
}