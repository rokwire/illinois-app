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
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/academics/AcademicsHomePanel.dart';
import 'package:illinois/ui/explore/ExploreDisplayTypeHeader.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:illinois/ui/settings/SettingsNotificationsContentPanel.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentDetailPanel.dart';
import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:illinois/service/DeviceCalendar.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsArticlePanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/groups/GroupDetailPanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/BrowsePanel.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/polls/PollBubblePromptPanel.dart';
import 'package:illinois/ui/polls/PollBubbleResultPanel.dart';
import 'package:illinois/ui/widgets/CalendarSelectionDialog.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/popups/alerts.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widget_builders/actions.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/local_notifications.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum RootTab { Home, Favorites, Athletics, Explore, Browse, Maps, Academics, Wellness }

class RootPanel extends StatefulWidget {
  static final GlobalKey<_RootPanelState> stateKey = GlobalKey<_RootPanelState>();

  RootPanel() : super(key: stateKey);

  @override
  _RootPanelState createState()  => _RootPanelState();
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
      FirebaseMessaging.notifyGroupPostNotification,
      FirebaseMessaging.notifyHomeNotification,
      FirebaseMessaging.notifyInboxNotification,
      FirebaseMessaging.notifyCanvasAppDeepLinkNotification,
      FirebaseMessaging.notifyAppointmentNotification,
      LocalNotifications.notifyLocalNotificationTapped,
      Alerts.notifyAlert,
      ActionBuilder.notifyShowPanel,
      Events.notifyEventDetail,
      Sports.notifyGameDetail,
      Groups.notifyGroupDetail,
      Appointments.notifyAppointmentDetail,
      Guide.notifyGuideDetail,
      Guide.notifyGuideList,
      Localization.notifyStringsUpdated,
      FlexUI.notifyChanged,
      Styles.notifyChanged,
      Polls.notifyPresentVote,
      Polls.notifyPresentResult,
      DeviceCalendar.notifyPromptPopup,
      DeviceCalendar.notifyCalendarSelectionPopup,
      DeviceCalendar.notifyShowConsoleMessage,
      uiuc.TabBar.notifySelectionChanged,
      HomePanel.notifyCustomize,
      ExplorePanel.notifyMapSelect,
    ]);

    _tabs = _getTabs();
    _tabBarController = TabController(length: _tabs.length, vsync: this);
    _updatePanels(_tabs);

    Services().initUI();
    _showPresentPoll();
    _checkDidNotificationLaunch().then((action) {
      action?.call();
    });
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
    else if (name == Alerts.notifyAlert) {
      Alerts.handleNotification(context, param);
    }
    else if (name == ActionBuilder.notifyShowPanel) {
      _showPanel(param);
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
    else if (name == LocalNotifications.notifyLocalNotificationTapped) {
      _onLocalNotification(param);
    }
    else if (name == Events.notifyEventDetail) {
      _onFirebaseEventDetail(param);
    }
    else if (name == Sports.notifyGameDetail) {
      _onFirebaseGameDetail(param);
    }
    else if (name == Groups.notifyGroupDetail) {
      _onGroupDetail(param);
    }
    else if (name == Appointments.notifyAppointmentDetail) {
      _onAppointmentDetail(param);
    }
    else if (name == Guide.notifyGuideDetail) {
      _onGuideDetail(param);
    }
    else if (name == Guide.notifyGuideList) {
      _onGuideList(param);
    }
    else if (name == Localization.notifyStringsUpdated) {
      if (mounted) {
        setState(() { });
      }
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
    else if (name == FirebaseMessaging.notifyGroupPostNotification) {
      _onFirebaseGroupPostNotification(param);
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
    else if (name == FirebaseMessaging.notifyCanvasAppDeepLinkNotification) {
      _onFirebaseCanvasAppDeepLinkNotification(param);
    }
    else if (name == FirebaseMessaging.notifyAppointmentNotification) {
      _onFirebaseAppointmentNotification(param);
    }
    else if (name == HomePanel.notifyCustomize) {
      _onSelectHome();
    }
    else if (name == ExplorePanel.notifyMapSelect) {
      _onSelectMaps();
    }
    else if (name == uiuc.TabBar.notifySelectionChanged) {
      _onTabSelectionChanged(param);
    }
  }

  void _onTabSelectionChanged(int tabIndex) {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      _selectTab(tabIndex);
    }
  }

  void _onSelectHome() {
    int? homeIndex = _getIndexByRootTab(RootTab.Home) ?? _getIndexByRootTab(RootTab.Favorites);
    if (mounted && (homeIndex != null)) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      _selectTab(homeIndex);
    }
  }

  void _onSelectMaps() {
    int? mapsIndex = _getIndexByRootTab(RootTab.Maps);
    if (mounted && (mapsIndex != null)) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      _selectTab(mapsIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            bottomNavigationBar: uiuc.TabBar(tabController: _tabBarController),
            backgroundColor: Styles().colors!.background,
          ),
        ),
        onWillPop: _onWillPop);
  }

  
  void _selectTab(int tabIndex) {

    if ((tabIndex >= 0) && (tabIndex != _currentTabIndex)) {
      _tabBarController!.animateTo(tabIndex);

      Widget? tabPanel = _getTabPanelAtIndex(tabIndex);
      if (tabPanel != null) {
        Analytics().logPage(name:tabPanel.runtimeType.toString());
      }

      if (mounted) {
        setState(() {
          _currentTabIndex = tabIndex;
        });
      }
      else {
        _currentTabIndex = tabIndex;
      }
    }
  }

  RootTab? getRootTabByIndex(int index) {
    return ((0 <= index) && (index < _tabs.length)) ? _tabs[index] : null;
  }

  int? _getIndexByRootTab(RootTab? rootTab) {
    int index = (rootTab != null) ? _tabs.indexOf(rootTab) : -1;
    return (0 <= index) ? index : null;
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
      _selectTab(0);
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
                          Localization().getStringEx("app.title", "Illinois"),
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
                  "common.message.exit_app", "Are you sure you want to exit?"),
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
            'Do you want to save this event to your calendar?')),
        actions: <Widget>[
          TextButton(
              child:
              Text(Localization().getStringEx('dialog.yes.title', 'Yes')),
              onPressed: () {
                Navigator.of(context).pop();
                DeviceCalendar().placeEvent(data);
              }),
          TextButton(
              child: Text(Localization().getStringEx('dialog.no.title', 'No')),
              onPressed: () => Navigator.of(context).pop())
        ]);
  }

  void _showPanel(Map<String, dynamic> content) {
    switch (content['panel']) {
      case "GuideDetailPanel":
        _onGuideDetail(content);
    }
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
    PopupMessage.show(context: context,
      title: Localization().getStringEx("app.title", "Illinois"),
      message: JsonUtils.stringValue(content["display_text"]),
      buttonTitle: JsonUtils.stringValue(content["positive_button_text"]) ?? Localization().getStringEx("dialog.ok.title", "OK")
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

  void _onLocalNotification(dynamic param) {
    if (param is ActionData) {
      ActionBuilder.getAction(context, param)?.call();
    }
    /*else if (param is NotificationResponse) {
      // TBD
    }*/
  }

  Future<void> _onGroupDetail(Map<String, dynamic>? content) async {
    String? groupId = (content != null) ? JsonUtils.stringValue(content['group_id']) : null;
    _presentGroupDetailPanel(groupId: groupId);
  }

  Future<void> _onAppointmentDetail(Map<String, dynamic>? content) async {
    String? appointmentId = (content != null) ? JsonUtils.stringValue(content['appointment_id']) : null;
    if (StringUtils.isNotEmpty(appointmentId)) {
      Navigator.of(context).push(CupertinoPageRoute(builder: (context) => AppointmentDetailPanel(appointmentId: appointmentId)));
    }
  }

  Future<void> _onGuideDetail(Map<String, dynamic>? content) async {
    String? guideId = (content != null) ? JsonUtils.stringValue(content['guide_id']) : null;
    if (StringUtils.isNotEmpty(guideId)){
      WidgetsBinding.instance.addPostFrameCallback((_) { // Fix navigator.dart failed assertion line 5307
        Navigator.of(context).push(CupertinoPageRoute(builder: (context) =>
          GuideDetailPanel(guideEntryId: guideId,)));
      });
      if (mounted) {
        setState(() {}); // Force the postFrameCallback invokation.
      }
    }
  }

  Future<void> _onGuideList(Map<String, dynamic>? content) async {
    if (content != null) {
      String? guide = JsonUtils.stringValue(content['guide']);
      String? section = JsonUtils.stringValue(content['section']);
      String? category = JsonUtils.stringValue(content['category']);
      if ((guide != null) || (section != null) || (category != null)){
        WidgetsBinding.instance.addPostFrameCallback((_) { // Fix navigator.dart failed assertion line 5307
          Navigator.of(context).push(CupertinoPageRoute(builder: (context) =>
            GuideListPanel(guide: guide, category: category, section: GuideSection(name: section),)));
        });
        if (mounted) {
          setState(() {}); // Force the postFrameCallback invokation.
        }
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

  Future<Function?> _checkDidNotificationLaunch() async {
    ActionData? notificationResponseAction = await LocalNotifications().getNotificationResponseAction();
    return ActionBuilder.getAction(context, notificationResponseAction, dismissContext: context);
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
      
      RootTab? currentRootTab = getRootTabByIndex(_currentTabIndex);
      if (mounted) {
        setState(() {
          _tabs = tabs;
          _currentTabIndex = (currentRootTab != null) ? (_getIndexByRootTab(currentRootTab) ?? 0)  : 0;
          
          // Do not initialize _currentTabIndex as initialIndex because we get empty panel content.
          // Initialize TabController with initialIndex = 0 and then manually animate to desired tab index.
          _tabBarController = TabController(length: _tabs.length, vsync: this);
        });
        _tabBarController!.animateTo(_currentTabIndex);
      }
      else {
        _tabs = tabs;
        _currentTabIndex = (currentRootTab != null) ? (_getIndexByRootTab(currentRootTab) ?? 0)  : 0;
        _tabBarController = TabController(length: _tabs.length, vsync: this, initialIndex: _currentTabIndex);
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
    else if (rootTab == RootTab.Favorites) {
      return HomePanel();
    }
    else if (rootTab == RootTab.Athletics) {
      return AthleticsHomePanel(rootTabDisplay: true,);
    }
    else if (rootTab == RootTab.Explore) {
      return ExplorePanel(rootTabDisplay: true);
    }
    else if (rootTab == RootTab.Browse) {
      return BrowsePanel();
    }
    else if (rootTab == RootTab.Maps) {
      return ExplorePanel(rootTabDisplay: true, mapDisplayType: ListMapDisplayType.Map);
    }
    else if (rootTab == RootTab.Academics) {
      return AcademicsHomePanel(rootTabDisplay: true,);
    }
    else if (rootTab == RootTab.Wellness) {
      return WellnessHomePanel(rootTabDisplay: true,);
    }
    else {
      return null;
    }
  }

  void _onFirebaseGroupsNotification(param) {
    if (param is Map<String, dynamic>) {
      String? groupId = param["entity_id"];
      _presentGroupDetailPanel(groupId: groupId);
    }
  }

  void _onFirebaseGroupPostNotification(param) {
    if (param is Map<String, dynamic>) {
      String? groupId = param["entity_id"];
      String? groupPostId = param["post_id"];
      _presentGroupDetailPanel(groupId: groupId, groupPostId: groupPostId);
    }
  }

  void _presentGroupDetailPanel({String? groupId, String? groupPostId}) {
    if (StringUtils.isNotEmpty(groupId)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupDetailPanel(groupIdentifier: groupId, groupPostId: groupPostId)));
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
    _selectTab(0);
  }

  void _onFirebaseInboxNotification() {
    SettingsNotificationsContentPanel.present(context,
        content: (Inbox().unreadMessagesCount > 0) ? SettingsNotificationsContent.unread : SettingsNotificationsContent.all);
  }
  
  void _onFirebaseCanvasAppDeepLinkNotification(dynamic param) {
    if (param is Map<String, dynamic>) {
      String? deepLink = JsonUtils.stringValue(param['deep_link']);
      Canvas().openCanvasAppDeepLink(StringUtils.ensureNotEmpty(deepLink));
    }
  }

  void _onFirebaseAppointmentNotification(dynamic param) {
    if (param is Map<String, dynamic>) {
      String? appointmentId = JsonUtils.stringValue(param['appointment_id']);
      if (StringUtils.isNotEmpty(appointmentId)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentDetailPanel(appointmentId: appointmentId)));
      }
    }
  }
}

RootTab? rootTabFromString(String? value) {
  if (value != null) {
    if (value == 'home') {
      return RootTab.Home;
    }
    else if (value == 'favorites') {
      return RootTab.Favorites;
    }
    else if (value == 'athletics') {
      return RootTab.Athletics;
    }
    else if (value == 'explore') {
      return RootTab.Explore;
    }
    else if (value == 'browse') {
      return RootTab.Browse;
    }
    else if (value == 'maps') {
      return RootTab.Maps;
    }
    else if (value == 'academics') {
      return RootTab.Academics;
    }
    else if (value == 'wellness') {
      return RootTab.Wellness;
    }
  }
  return null;
}
