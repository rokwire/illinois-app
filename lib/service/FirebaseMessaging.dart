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
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as firebase_messaging;
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FirebaseService.dart';
import 'package:illinois/service/Inbox.dart';

import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/Utils.dart';

const String _channelId = "Notifications_Channel_ID";


//
// This may require more handling, because the App may not be fully initialized in the moment of invocation.
// It is not invoked as it's designed and document - however it's good start for now.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  await FirebaseService().initFirebase();
  print("Handling a background message: ${message.toString()}");
  FirebaseMessaging()._onFirebaseMessage(message);
}

class FirebaseMessaging with Service implements NotificationsListener {


  static const String notifyToken                 = "edu.illinois.rokwire.firebase.messaging.token";
  static const String notifyForegroundMessage     = "edu.illinois.rokwire.firebase.messaging.message.foreground";
  static const String notifyPopupMessage          = "edu.illinois.rokwire.firebase.messaging.message.popup";
  static const String notifyScoreMessage          = "edu.illinois.rokwire.firebase.messaging.message.score";
  static const String notifyConfigUpdate          = "edu.illinois.rokwire.firebase.messaging.config.update";
  static const String notifyPollOpen              = "edu.illinois.rokwire.firebase.messaging.poll.create";
  static const String notifyEventDetail           = "edu.illinois.rokwire.firebase.messaging.event.detail";
  static const String notifyGameDetail            = "edu.illinois.rokwire.firebase.messaging.game.detail";
  static const String notifyAthleticsGameStarted  = "edu.illinois.rokwire.firebase.messaging.athletics_game.started";
  static const String notifySettingUpdated        = "edu.illinois.rokwire.firebase.messaging.setting.updated";
  static const String notifyGroupsNotification         = "edu.illinois.rokwire.firebase.messaging.groups.updated";

  // Topic names
  static const List<String> _permanentTopis = [
    "config_update",
    "popup_message",
    "polls",
  ];

  // Settings entry : topic name
  static const Map<String, String> _notifySettingTopics = {
    'event_reminders'  : 'event_reminders',
    'athletic_updates' : 'athletic_updates',
    'dining_specials'  : 'dinning_specials',
  };

  final AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId, // id
    "Illinois",
    "Receive notifications",
    importance: Importance.high,
  );


  String   _token;
  String   _projectID;
  DateTime _pausedDateTime;
  
  List<firebase_messaging.RemoteMessage> _messagesCache;

  // Singletone instance

  FirebaseMessaging._internal();
  static final FirebaseMessaging _firebase = FirebaseMessaging._internal();
  final FlutterLocalNotificationsPlugin _firebaseMessaging = FlutterLocalNotificationsPlugin();

  factory FirebaseMessaging() {
    return _firebase;
  }

  static FirebaseMessaging get instance {
    return _firebase;
  }

  // Public getters

  String get token => _token;
  String get projectID => _projectID;
  bool get hasToken => AppString.isStringNotEmpty(_token);

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyRolesChanged,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2UserPrefs.notifyInterestsChanged,
      Auth2.notifyProfileChanged,
      Auth2.notifyUserDeleted,
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    // Cache messages until UI is displayed
    _messagesCache = [];

    firebase_messaging.FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _firebaseMessaging.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_channel);

    await firebase_messaging.FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    firebase_messaging.FirebaseMessaging.onMessage.listen((firebase_messaging.RemoteMessage message) {
      print('A new onMessage event was published!');
      _onFirebaseMessage(message);
    });

    firebase_messaging.FirebaseMessaging.onMessageOpenedApp.listen((firebase_messaging.RemoteMessage message) {
       print('A new onMessageOpenedApp event was published!');
      _onFirebaseMessage(message);
    });

   // firebase_messaging.FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);


    firebase_messaging.FirebaseMessaging.instance.getToken().then((String token) {
      _token = token;
      Log.d('FCM: token: $token');
      NotificationService().notify(notifyToken, null);
      _updateSubscriptions();
    });
    
    //The project id is not given via the lib so we need to get it via NativeCommunicator
    NativeCommunicator().queryFirebaseInfo().then((String info) {
      _projectID = info;
    });
  }

  @override
  void initServiceUI() {
    _processCachedMessages();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([FirebaseService(), Storage(), Config(), Auth2()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyRolesChanged) {
      _updateRolesSubscriptions();
    }
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      _updateNotifySettingsSubscriptions();
    }
    else if (name == Auth2UserPrefs.notifyInterestsChanged) {
      _updateAthleticsSubscriptions();
    }
    else if (name == Auth2.notifyProfileChanged) {
      _updateSubscriptions();
    }
    else if (name == Auth2.notifyUserDeleted) {
      _updateSubscriptions();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param); 
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateSubscriptions();
        }
      }
    }
  }

  // Subscription APIs

  Future<bool> subscribeToTopic(String topic) async {
    if (await Inbox().subscribeToTopic(topic: topic, token: _token)) {
      Storage().addFirebaseMessagingSubscriptionTopic(topic);
      return true;
    }
    return false;
  }

  Future<bool> unsubscribeFromTopic(String topic) async {
    if (await Inbox().unsubscribeFromTopic(topic: topic, token: _token)) {
      Storage().removeFirebaseMessagingSubscriptionTopic(topic);
      return true;
    }
    return false;
  }

  // Message Processing

  Future<dynamic> _onFirebaseMessage(firebase_messaging.RemoteMessage message) async {
    Log.d("FCM: onFirebaseMessage");
    _onMessageProcess(message);
  }

  ///We need to process Android and iOS differently as the plugin gives different format for the both platforms.

  ///Android
  ///{
  ///    notification: {title: null, body: null},
  ///    data: {Period: 1, VisitingScore: 20, HomeScore: 14, Path: football, Type: football, IsComplete: false, ClockSeconds: -1, Custom: {"Possession":"","LastPlay":"","Clock":"","Phase":"Pregame"}, GameId: 16692, HasStarted: false}
  ///}

  ///iOS
  ///{GameId: 16692, IsComplete: false, gcm.message_id: 1572250193655080, VisitingScore: 20, HomeScore: 14, Custom: {"Possession":"","LastPlay":"","Clock":"","Phase":"Pregame"}, Type: football, Path: football, aps: {content-available: 1}, ClockSeconds: -1, HasStarted: false, Period: 1}
  void _onMessageProcess(firebase_messaging.RemoteMessage message) {
    if (message != null) {
      if (_messagesCache != null) {
        Log.d("FCM: cacheMessage: $message");
        _messagesCache.add(message);
      }
      else {
        _processMessage(message);
      }
    }
  }

  void _processMessage(firebase_messaging.RemoteMessage message) {
    Log.d("FCM: onMessageProcess: $message");
    if (message?.data != null) {
      try {
        if(AppLivecycle.instance.state == AppLifecycleState.resumed &&
          AppString.isStringNotEmpty(message.notification?.title) &&
            AppString.isStringNotEmpty(message.notification?.body)
        ){
          NotificationService().notify(notifyForegroundMessage, {
            "title": message.notification.title,
            "body": message.notification.body,
            "onComplete": (){
              _processDataMessage(message.data);
            }
          });
        } else {
          _processDataMessage(message.data);
        }
      }
      catch(e) {
        print(e.toString());
      }
    }
  }

  void _processDataMessage(Map<String, dynamic> data) {
    String type = _getMessageType(data);
    if (type == "config_update") {
      _onConfigUpdate(data);
    }
    else if (type == "popup_message") {
      NotificationService().notify(notifyPopupMessage, data);
    }
    else if (type == "poll_open") {
      NotificationService().notify(notifyPollOpen, data);
    }
    else if (type == "event_detail") {
      NotificationService().notify(notifyEventDetail, data);
    }
    else if (type == "game_detail") {
      NotificationService().notify(notifyGameDetail, data);
    }
    else if (type == "athletics_game_started") {
      NotificationService().notify(notifyAthleticsGameStarted, data);
    }
    else if (_isScoreTypeMessage(type)) {
      NotificationService().notify(notifyScoreMessage, data);
    }
    else if (type == "group") {
      NotificationService().notify(notifyGroupsNotification, data);
    }
    else {
      Log.d("FCM: unknown message type: $type");
    }
  }

  String _getMessageType(Map<String, dynamic> data) {
    if (data == null)
      return null;

    //1. check type
    String type = data["type"];
    if (type != null)
      return type;

    //2. check Type - deprecated!
    String type2 = data["Type"];
    if (type2 != null)
      return type2;

    //3. check Path - deprecated!
    String path = data["Path"];
    if (path != null) {
      String gameId = data['GameId'];
      dynamic hasStarted = data['HasStarted'];
      // Handle 'Game Started / Ended' notification which does not contain key 'HasStarted'
      if (AppString.isStringNotEmpty(gameId) && (hasStarted == null)) {
        return 'athletics_game_started';
      } else {
        return path;
      }
    }

    //treat everything else as config update - the backend gives it without "type"!
    return "config_update";
  }

  bool _isScoreTypeMessage(String type) {
    return type == "football" ||
        type == "mbball" ||
        type == "wbball" ||
        type == "mvball" ||
        type == "wvball" ||
        type == "mtennis" ||
        type == "wtennis" ||
        type == "baseball" ||
        type == "softball" ||
        type == "wsoc";
  }

  void _onConfigUpdate(Map<String, dynamic> data) {
    int interval = 5 * 60; // 5 minutes
    var rng = new Random();
    int delay = rng.nextInt(interval);
    Log.d("FCM: Scheduled config update after ${delay.toString()} seconds");
    Timer(Duration(seconds: delay), () {
      Log.d("FCM: Perform config update");
      NotificationService().notify(notifyConfigUpdate, data);
    });
  }

  void _processCachedMessages() {
    if (_messagesCache != null) {
      List<firebase_messaging.RemoteMessage> messagesCache = _messagesCache;
      _messagesCache = null;

      for (firebase_messaging.RemoteMessage message in messagesCache) {
        _processMessage(message);
      }
    }
  }

  // Settings topics

  bool get notifyEventReminders               { return _getNotifySetting('event_reminders'); } 
       set notifyEventReminders(bool value)   { _setNotifySetting('event_reminders', value); }

  bool get notifyAthleticsUpdates             { return _getNotifySetting('athletic_updates'); } 
       set notifyAthleticsUpdates(bool value) { _setNotifySetting('athletic_updates', value); }

  bool get notifyDiningSpecials               { return _getNotifySetting('dining_specials'); } 
       set notifyDiningSpecials(bool value)   { _setNotifySetting('dining_specials', value); }

  bool get _notifySettingsAvailable  {
    return Auth2().privacyMatch(4);
  }

  bool _getNotifySetting(String name) {
    if (_notifySettingsAvailable) {
      return Storage().getNotifySetting(name) ?? true;
    }
    else {
      return false;
    }
  } 

  void _setNotifySetting(String name, bool value) {
    if (_notifySettingsAvailable && (_getNotifySetting(name) != value)) {
      Storage().setNotifySetting(name, value);
      NotificationService().notify(notifySettingUpdated, name);

      Set<String> subscribedTopis = Storage().firebaseMessagingSubscriptionTopis;
      _processNotifySettingSubscription(topic: _notifySettingTopics[name], value: value, subscribedTopis: subscribedTopis);
      if (name == 'athletic_updates') {
        _processAthleticsSubscriptions(subscribedTopis: subscribedTopis);
      }
    }
  }

  // Subscription Management

  void _updateSubscriptions() {
    if (hasToken) {
      Set<String> subscribedTopis = Storage().firebaseMessagingSubscriptionTopis;
      _processPermanentSubscriptions(subscribedTopis: subscribedTopis);
      _processRolesSubscriptions(subscribedTopis: subscribedTopis);
      _processNotifySettingsSubscriptions(subscribedTopis: subscribedTopis);
      _processAthleticsSubscriptions(subscribedTopis: subscribedTopis);
    }
  }

  void _updateRolesSubscriptions() {
    if (hasToken) {
      _processRolesSubscriptions(subscribedTopis: Storage().firebaseMessagingSubscriptionTopis);
    }
  }

  void _updateNotifySettingsSubscriptions() {
    if (hasToken) {
      _processNotifySettingsSubscriptions(subscribedTopis: Storage().firebaseMessagingSubscriptionTopis);
    }
  }

  void _updateAthleticsSubscriptions() {
    if (hasToken) {
      _processAthleticsSubscriptions(subscribedTopis: Storage().firebaseMessagingSubscriptionTopis);
    }
  }

  void _processPermanentSubscriptions({Set<String> subscribedTopis}) {
    for (String permanentTopic in _permanentTopis) {
      if ((subscribedTopis == null) || !subscribedTopis.contains(permanentTopic)) {
        subscribeToTopic(permanentTopic);
      }
    }
  }

  void _processRolesSubscriptions({Set<String> subscribedTopis}) {
    Set<UserRole> roles = Auth2().prefs?.roles;
    for (UserRole role in UserRole.values) {
      String roleTopic = role.toString();
      bool roleSubscribed = (subscribedTopis != null) && subscribedTopis.contains(roleTopic);
      bool roleSelected = (roles != null) && roles.contains(role);
      if (roleSelected && !roleSubscribed) {
        subscribeToTopic(roleTopic);
      }
      else if (!roleSelected && roleSubscribed) {
        unsubscribeFromTopic(roleTopic);
      }
    }
  }
  
  void _processNotifySettingsSubscriptions({Set<String> subscribedTopis}) {
    _notifySettingTopics.forEach((String setting, String topic) {
      bool value = _getNotifySetting(setting);
      _processNotifySettingSubscription(topic: topic, value: value, subscribedTopis: subscribedTopis);
    });
  }

  void _processNotifySettingSubscription({String topic, bool value, Set<String> subscribedTopis}) {
    if (topic != null) {
      bool itemSubscribed = (subscribedTopis != null) && subscribedTopis.contains(topic);
      if (value && !itemSubscribed) {
        subscribeToTopic(topic);
      }
      else if (!value && itemSubscribed) {
        unsubscribeFromTopic(topic);
      }
    }
  }

  void _processAthleticsSubscriptions({Set<String> subscribedTopis}) {
    bool notifyAthletics = notifyAthleticsUpdates;
    Set<String> selectedSports = Auth2().prefs?.sportsInterests;
    List<SportDefinition> sportDefs = Sports().sports;
    if (sportDefs != null) {
      for (SportDefinition sportDef in sportDefs) {
        String sport = sportDef.shortName;
        bool sportSelected = (selectedSports != null) && selectedSports.contains(sport);
        bool sportSubscribstionValue = notifyAthletics && sportSelected;

        String sportTopic = '${sport}_notification';
        bool sportSubscribed = (subscribedTopis != null) && subscribedTopis.contains(sportTopic);

        if (sportSubscribstionValue && !sportSubscribed) {
          FirebaseMessaging().subscribeToTopic(sportTopic);
        }
        else if (!sportSubscribstionValue && sportSubscribed) {
          FirebaseMessaging().unsubscribeFromTopic(sportTopic);
        }
      }
    }
  }

}
