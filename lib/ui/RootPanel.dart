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

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/main.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:illinois/service/DeviceCalendar.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/Groups.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/SavedPanel.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsArticlePanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/groups/GroupDetailPanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/BrowsePanel.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/inbox/InboxHomePanel.dart';
import 'package:illinois/ui/polls/PollBubblePromptPanel.dart';
import 'package:illinois/ui/polls/PollBubbleResultPanel.dart';
import 'package:illinois/ui/widgets/CalendarSelectionDialog.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/PopupDialog.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum RootTab { Home, Athletics, Explore, Wallet, Browse }

class _PanelData {
  _RootPanelState? _panelState;

  RootTab?         _rootTab;
  ExploreTab?      _exploreTab;
  ExploreFilter?   _exploreInitialFilter;
}

class RootPanel extends StatefulWidget {
  final _PanelData _data = _PanelData();

  void selectTab({RootTab? rootTab, ExploreTab? exploreTab, ExploreFilter? exploreInitialFilter, bool? showHeaderBack = false}) {
    if ((_data._panelState != null) && _data._panelState!.mounted && (rootTab != null)) {
      _data._panelState!.selectTab(rootTab: rootTab, exploreTab: exploreTab, exploreInitialFilter: exploreInitialFilter);
    }
    else {
      _data._rootTab = rootTab;
      _data._exploreTab = exploreTab;
      _data._exploreInitialFilter = exploreInitialFilter;
    }
  }

  @override
  _RootPanelState createState() {
    return _data._panelState = _RootPanelState();
  }

  _RootPanelState? get panelState {
    return _data._panelState;
  }
}

class _RootPanelState extends State<RootPanel> with TickerProviderStateMixin implements NotificationsListener {

  List<RootTab>  _tabs = [];
  Map<RootTab, Widget> _panels = {};

  TabController?  _tabBarController;
  int            _currentTabIndex = 0;

  _RootPanelState();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      FirebaseMessaging.notifyForegroundMessage,
      FirebaseMessaging.notifyPopupMessage,
      FirebaseMessaging.notifyEventDetail,
      FirebaseMessaging.notifyAthleticsGameStarted,
      FirebaseMessaging.notifyAthleticsNewsUpdated,
      FirebaseMessaging.notifyGroupsNotification,
      FirebaseMessaging.notifyHomeNotification,
      FirebaseMessaging.notifyInboxNotification,
      ExploreService.notifyEventDetail,
      Sports.notifyGameDetail,
      Groups.notifyGroupDetail,
      Guide.notifyGuideDetail,
      Localization.notifyStringsUpdated,
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
      Styles.notifyChanged,
      Polls.notifyPresentVote,
      Polls.notifyPresentResult,
      DeviceCalendar.notifyPromptPopup,
      DeviceCalendar.notifyCalendarSelectionPopup,
      DeviceCalendar.notifyShowConsoleMessage,
    ]);

    _tabs = _getTabs();
    _initTabBarController();
    _updatePanels(_tabs);

    if (widget._data._rootTab != null) {
      int tabIndex = _getIndexByRootTab(widget._data._rootTab);
      if ((0 <= tabIndex) && (tabIndex < _tabs.length)) {
        _currentTabIndex = tabIndex;
      }

      if (widget._data._rootTab == RootTab.Explore) {
        ExplorePanel? explorePanel = _panels[RootTab.Explore] as ExplorePanel?;
        explorePanel?.selectTab(widget._data._exploreTab, initialFilter: widget._data._exploreInitialFilter);
      }

      widget.selectTab(rootTab: null, exploreTab: null, exploreInitialFilter: null, showHeaderBack: null);
    }

    Services().initUI();
    _showPresentPoll();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeviceCalendar.notifyPromptPopup) {
      _onCalendarPromptMessage(param);
    }
    else if (name == DeviceCalendar.notifyCalendarSelectionPopup) {
      _promptCalendarSelection(param);
    }
    else if (name == DeviceCalendar.notifyShowConsoleMessage) {
      _showConsoleMessage(param);
    }
    else if (name == FirebaseMessaging.notifyForegroundMessage){
      _onFirebaseForegroundMessage(param);
    }
    else if (name == FirebaseMessaging.notifyPopupMessage) {
      _onFirebasePopupMessage(param);
    }
    else if (name == FirebaseMessaging.notifyEventDetail) {
      _onFirebaseEventDetail(param);
    }
    else if (name == FirebaseMessaging.notifyGameDetail) {
      _onFirebaseGameDetail(param);
    }
    else if(name == FirebaseMessaging.notifyAthleticsGameStarted) {
      _showAthleticsGameDetail(param);
    }
    else if (name == ExploreService.notifyEventDetail) {
      _onFirebaseEventDetail(param);
    }
    else if (name == Sports.notifyGameDetail) {
      _onFirebaseGameDetail(param);
    }
    else if (name == Groups.notifyGroupDetail) {
      _onGroupDetail(param);
    }
    else if (name == Guide.notifyGuideDetail) {
      _onGuideDetail(param);
    }
    else if (name == Localization.notifyStringsUpdated) {
      if (mounted) {
        setState(() { });
      }
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _FavoritesSavedDialog.show(context);
    }
    else if (name == FlexUI.notifyChanged) {
      _updateContent();
    }
    else if (name == Styles.notifyChanged) {
      if (mounted) {
        setState(() { });
      }
    }
    else if (name == Polls.notifyPresentVote) {
      _presentPollVote(param);
    }
    else if (name == Polls.notifyPresentResult) {
      _presentPollResult(param);
    }
    else if (name == FirebaseMessaging.notifyGroupsNotification) {
      _onFirebaseGroupsNotification(param);
    }
    else if (name == FirebaseMessaging.notifyAthleticsNewsUpdated) {
      _onFirebaseAthleticsNewsNotification(param);
    }
    else if (name == FirebaseMessaging.notifyHomeNotification) {
      _onFirebaseHomeNotification();
    }
    else if (name == FirebaseMessaging.notifyInboxNotification) {
      _onFirebaseInboxNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    App.instance.homeContext = context;
    Analytics().accessibilityState = MediaQuery.of(context).accessibleNavigation;

    List<Widget> panels = [];
    for (RootTab? rootTab in _tabs) {
      panels.add(_panels[rootTab] ?? Container());
    }

    return WillPopScope(
        child: Container(
          color: Colors.white,
          child: Scaffold(
            body: TabBarView(
                controller: _tabBarController,
                physics: NeverScrollableScrollPhysics(), //disable scrolling
                children: panels,
              ),
              bottomNavigationBar: TabBarWidget(tabController: _tabBarController),
              backgroundColor: Styles().colors!.background,
            ),
        ),
        onWillPop: _onWillPop);
  }

  ///Public interface
  void selectTab({RootTab? rootTab, ExploreTab? exploreTab, ExploreFilter? exploreInitialFilter}) {

    int newTabIndex = _getIndexByRootTab(rootTab);
    if ((newTabIndex >= 0) && (newTabIndex != _currentTabIndex)) {
      _tabBarController!.animateTo(newTabIndex);
      _selectTabAtIndex(newTabIndex);
    }
  }

  void _initTabBarController() {
    _tabBarController = TabController(length: _tabs.length, vsync: this, initialIndex: _tabBarController?.index ?? 0);
  }

  void _selectTabAtIndex(int index) {
    if (_currentTabIndex != index) {

      Widget? tabPanel = _getTabPanelAtIndex(index);
      if (tabPanel != null) {
        Analytics().logPage(name:tabPanel.runtimeType.toString());
      }

      if (mounted) {
        setState(() {
          _currentTabIndex = index;
        });
      }
      else {
        _currentTabIndex = index;
      }
    }
  }

  RootTab? getRootTabByIndex(int index) {
    return ((0 <= index) && (index < _tabs.length)) ? _tabs[index] : null;
  }

  int _getIndexByRootTab(RootTab? rootTab) {
    return (rootTab != null) ? _tabs.indexOf(rootTab) : -1;
  }

  Widget? _getTabPanelAtIndex(int index) {
    RootTab? rootTab = getRootTabByIndex(index);
    return (rootTab != null) ? _panels[rootTab] : null;
  }

  Widget? get currentTabPanel {
    return _getTabPanelAtIndex(_currentTabIndex);
  }

  Future<bool> _onWillPop() async {
    if (_currentTabIndex != 0) {
      selectTab(rootTab: RootTab.Home);
      return Future.value(false);
    }
    bool? result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildExitDialog(context);
      },
    );
    return result ?? false;
  }

  Widget _buildExitDialog(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    color: Styles().colors!.fillColorPrimary,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          Localization().getStringEx("app.title", "Illinois")!,
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(height: 26,),
            Text(
              Localization().getStringEx(
                  "app.exit_dialog.message", "Are you sure you want to exit?")!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: Styles().fontFamilies!.bold,
                  fontSize: 16,
                  color: Colors.black),
            ),
            Container(height: 26,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RoundedButton(
                      onTap: () {
                        Analytics().logAlert(
                            text: "Exit", selection: "Yes");
                        Navigator.of(context).pop(true);
                      },
                      backgroundColor: Colors.transparent,
                      borderColor: Styles().colors!.fillColorSecondary,
                      textColor: Styles().colors!.fillColorPrimary,
                      label: Localization().getStringEx("dialog.yes.title", 'Yes')),
                  Container(height: 10,),
                  RoundedButton(
                      onTap: () {
                        Analytics().logAlert(
                            text: "Exit", selection: "No");
                        Navigator.of(context).pop(false);
                      },
                      backgroundColor: Colors.transparent,
                      borderColor: Styles().colors!.fillColorSecondary,
                      textColor: Styles().colors!.fillColorPrimary,
                      label: Localization().getStringEx("dialog.no.title", 'No'))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _promptCalendarSelection(dynamic data){
      CalendarSelectionDialog.show(context: context,
          onContinue:( selectedCalendar) {
            Navigator.of(context).pop();
//            data["calendar"] = selectedCalendar;
            //Store the selection even if the event is not stored
            if(selectedCalendar!=null){
              DeviceCalendar().calendar = selectedCalendar;
            }
            NotificationService().notify(
                DeviceCalendar.notifyPromptPopup, data);
          }
      );
  }

  void _onCalendarPromptMessage(dynamic data) {
        AppAlert.showCustomDialog(
        context: context,
        contentWidget: Text(Localization().getStringEx(
            'prompt.device_calendar.msg.add_event',
            'Do you want to save this event to your calendar?')!),
        actions: <Widget>[
          TextButton(
              child:
              Text(Localization().getStringEx('dialog.yes.title', 'Yes')!),
              onPressed: () {
                Navigator.of(context).pop();
                  NotificationService().notify(
                      DeviceCalendar.notifyPlaceEvent, data);
              }),
          TextButton(
              child: Text(Localization().getStringEx('dialog.no.title', 'No')!),
              onPressed: () => Navigator.of(context).pop())
        ]);
  }

  void _onFirebaseForegroundMessage(Map<String, dynamic> content) {
    String? body = content["body"];
    Function? completion = content["onComplete"];
    AppAlert.showDialogResult(context, body).then((value){
      if(completion != null){
        completion();
      }
    });
  }

  void _onFirebasePopupMessage(Map<String, dynamic> content) {
    String? displayText = content["display_text"];
    String? positiveButtonText = content["positive_button_text"];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopupDialog(displayText: displayText, positiveButtonText: positiveButtonText);
      },
    );
  }

  Future<void> _onFirebaseEventDetail(Map<String, dynamic>? content) async {
    String? eventId = (content != null) ? JsonUtils.stringValue(content['event_id']) : null;
    if (StringUtils.isNotEmpty(eventId)) {
      ExplorePanel.presentDetailPanel(context, eventId: eventId);
    }
  }

  
  Future<void> _onFirebaseGameDetail(Map<String, dynamic>? content) async {
    String? gameId = (content != null) ? JsonUtils.stringValue(content['game_id']) : null;
    String? sport = (content != null) ? JsonUtils.stringValue(content['sport']) : null;
    if (StringUtils.isNotEmpty(gameId) && StringUtils.isNotEmpty(sport)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(sportName: sport, gameId: gameId,)));
    }
  }

  Future<void> _onGroupDetail(Map<String, dynamic>? content) async {
    String? groupId = (content != null) ? JsonUtils.stringValue(content['group_id']) : null;
    _presentGroupDetailPanel(groupId);
  }

  Future<void> _onGuideDetail(Map<String, dynamic>? content) async {
    String? guideId = (content != null) ? JsonUtils.stringValue(content['guide_id']) : null;
    if(StringUtils.isNotEmpty(guideId)){
      WidgetsBinding.instance!.addPostFrameCallback((_) { // Fix navigator.dart failed assertion line 5307
        Navigator.of(context).push(CupertinoPageRoute(builder: (context) =>
          GuideDetailPanel(guideEntryId: guideId,)));
      });
      if (mounted) {
        setState(() {}); // Force the postFrameCallback invokation.
      }
    }
  }

  void _showAthleticsGameDetail(Map<String, dynamic>? athleticsGameDetails) {
    if (athleticsGameDetails == null) {
      return;
    }
    String? sportShortName = athleticsGameDetails["Path"];
    String? gameId = athleticsGameDetails["GameId"];
    if (StringUtils.isEmpty(sportShortName) || StringUtils.isEmpty(gameId)) {
      return;
    }
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(sportName: sportShortName, gameId: gameId,)));
  }
  
  void _showPresentPoll() {
    Poll? presentingPoll = Polls().presentingPoll;
    if (presentingPoll != null) {
      Timer(Duration(milliseconds: 500), (){
        if (presentingPoll.status == PollStatus.opened) {
          _presentPollVote(presentingPoll.pollId);
        }
        else if (presentingPoll.status == PollStatus.closed) {
          _presentPollResult(presentingPoll.pollId);
        }
      });
    }
  }

  void _presentPollVote(String? pollId) {
    Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => PollBubblePromptPanel(pollId: pollId)));
  }

  void _presentPollResult(String? pollId) {
    Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => PollBubbleResultPanel(pollId: pollId)));
  }

  void _showConsoleMessage(message){
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: Text(message??""),
        actions: <Widget>[
          TextButton(
              child:
              Text("Ok"),
              onPressed: () => Navigator.of(context).pop()),
          TextButton(
              child: Text("Copy"),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message)).then((_){
                  AppToast.show("Text data has been copied to the clipboard!");
                });
              } )
        ]);
  }

  static List<String>? _getTabbarCodes() {
    try {
      dynamic tabsList = FlexUI()['tabbar'];
      return (tabsList is List) ? tabsList.cast<String>() : null;
    }
    catch(e) {
      print(e.toString());
    }
    return null;
  }

  void _updateContent() {
    List<RootTab> tabs = _getTabs();
    if (!DeepCollectionEquality().equals(_tabs, tabs)) {
      _updatePanels(tabs);
      if (mounted) {
        setState(() {
          _tabs = tabs;
          _initTabBarController();
        });
      }
      else {
        _tabs = tabs;
        _initTabBarController();
      }
    }
  }

  void _updatePanels(List<RootTab> tabs) {
    for (RootTab rootTab in tabs) {
      if (_panels[rootTab] == null) {
        Widget? panel = _createPanelForTab(rootTab);
        if (panel != null) {
          _panels[rootTab] = panel;
        }
      }
    }
  }

  static List<RootTab> _getTabs() {
    List<RootTab> tabs = [];
    List<String>? codes = _getTabbarCodes();
    if (codes != null) {
      for (String code in codes) {
        ListUtils.add(tabs, rootTabFromString(code));
      }
    }
    return tabs;
  }

  static Widget? _createPanelForTab(RootTab? rootTab) {
    if (rootTab == RootTab.Home) {
      return HomePanel();
    }
    else if (rootTab == RootTab.Athletics) {
      return AthleticsHomePanel(showTabBar: false,);
    }
    else if (rootTab == RootTab.Explore) {
      return ExplorePanel(showHeaderBack: false, showTabBar: false,);
    }
    else if (rootTab == RootTab.Wallet) {
      return null;
    }
    else if (rootTab == RootTab.Browse) {
      return BrowsePanel();
    }
    else {
      return null;
    }
  }

  void _onFirebaseGroupsNotification(param) {
    if (param is Map<String, dynamic>) {
      String? groupId = param["entity_id"];
      _presentGroupDetailPanel(groupId);
    }
  }

  void _presentGroupDetailPanel(String? groupId) {
    if (StringUtils.isNotEmpty(groupId)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupDetailPanel(groupIdentifier: groupId)));
    } else {
      AppAlert.showDialogResult(context, Localization().getStringEx("panel.group_detail.label.error_message", "Failed to load group data."));
    }
  }

  void _onFirebaseAthleticsNewsNotification(param) {
    if (param is Map<String, dynamic>) {
      String? newsId = param["news_id"];
      if (StringUtils.isNotEmpty(newsId)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsNewsArticlePanel(articleId: newsId)));
      }
    }
  }

  void _onFirebaseHomeNotification() {
    // Pop to Home Panel and select the first tab
    Navigator.of(context).popUntil((route) => route.isFirst);
    selectTab(rootTab: RootTab.Home);
  }

  void _onFirebaseInboxNotification() {
    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => InboxHomePanel()));
  }
}

RootTab? rootTabFromString(String? value) {
  if (value != null) {
    if (value == 'home') {
      return RootTab.Home;
    }
    else if (value == 'athletics') {
      return RootTab.Athletics;
    }
    else if (value == 'explore') {
      return RootTab.Explore;
    }
    else if (value == 'wallet') {
      return RootTab.Wallet;
    }
    else if (value == 'browse') {
      return RootTab.Browse;
    }
  }
  return null;
}

class _FavoritesSavedDialog extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FavoritesSavedDialogState();
  }

  static void show(BuildContext? context) {
    bool favoriteDialogWasShown = (Storage().favoritesDialogWasVisible == true);
    if (favoriteDialogWasShown || context == null) {
      return;
    }

    Storage().favoritesDialogWasVisible = true;
    showDialog(
        context: context,
        builder: (_) => Material(
              type: MaterialType.transparency,
              child: _FavoritesSavedDialog(),
            ));
  }
}

class _FavoritesSavedDialogState extends State<_FavoritesSavedDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      Container(
        height: 50,
      ),
      Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Container(
              decoration: BoxDecoration(
                color: Styles().colors!.fillColorPrimary,
                border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 2.0),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
                      Expanded(
                          flex: 5,
                          child: Text(
                            Localization().getStringEx('widget.favorites_saved_dialog.title', 'This starred item has been added to your saved list')!
                                + (DeviceCalendar().canAddToCalendar? Localization().getStringEx("widget.favorites_saved_dialog.calendar.title", " and if it is an event, also your calendar")! :"") + ".",
                            style: TextStyle(
                              color: Styles().colors!.white,
                              fontSize: 16,
                              fontFamily: Styles().fontFamilies!.bold,
                            ),
                          )),
                      InkWell(onTap: _onTapClose, child:
                        Semantics(button: true, label: Localization().getStringEx("dialog.close.title","Close"), child:
                          Image.asset('images/close-white.png', excludeFromSemantics: true,)))
                    ]),
                    Semantics(button: true, child:
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: GestureDetector(
                        onTap: _onViewAll,
                        child: Text(
                          Localization().getStringEx("widget.favorites_saved_dialog.button.view", "View")!,
                          style: TextStyle(
                              color: Styles().colors!.white,
                              fontSize: 14,
                              fontFamily: Styles().fontFamilies!.medium,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1,
                              decorationColor: Styles().colors!.fillColorSecondary),
                        ),
                      ),
                    ))
                  ]))))
    ]));
  }

  void _onTapClose() {
    Analytics().logAlert(text: "Event Saved", selection: "close");
    Navigator.pop(context, "");
  }

  void _onViewAll() {
    Analytics().logAlert(text: "Event Saved", selection: "View All");
    Navigator.pop(context, "");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SavedPanel()));
  }
}
