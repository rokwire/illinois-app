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
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/firebase_messaging.dart' as rokwire;

import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class FirebaseMessaging extends rokwire.FirebaseMessaging implements NotificationsListener {

  static String get notifyToken                  => rokwire.FirebaseMessaging.notifyToken;
  static String get notifyForegroundMessage      => rokwire.FirebaseMessaging.notifyForegroundMessage;

  static const String notifyPopupMessage                   = "edu.illinois.rokwire.firebase.messaging.message.popup";
  static const String notifyScoreMessage                   = "edu.illinois.rokwire.firebase.messaging.message.score";
  static const String notifyConfigUpdate                   = "edu.illinois.rokwire.firebase.messaging.config.update";
  static const String notifyPollOpen                       = "edu.illinois.rokwire.firebase.messaging.poll.create";
  static const String notifyEventDetail                    = "edu.illinois.rokwire.firebase.messaging.event.detail";
  static const String notifyGameDetail                     = "edu.illinois.rokwire.firebase.messaging.game.detail";
  static const String notifyAthleticsGameStarted           = "edu.illinois.rokwire.firebase.messaging.athletics_game.started";
  static const String notifyAthleticsNewsUpdated           = "edu.illinois.rokwire.firebase.messaging.athletics.news.updated";
  static const String notifySettingUpdated                 = "edu.illinois.rokwire.firebase.messaging.setting.updated";
  static const String notifyGroupsNotification             = "edu.illinois.rokwire.firebase.messaging.groups.updated";
  static const String notifyGroupPostNotification          = "edu.illinois.rokwire.firebase.messaging.group.posts.updated";
  static const String notifyHomeNotification               = "edu.illinois.rokwire.firebase.messaging.home";
  static const String notifyInboxNotification              = "edu.illinois.rokwire.firebase.messaging.inbox";
  static const String notifyCanvasAppDeepLinkNotification  = "edu.illinois.rokwire.firebase.messaging.app.canvas.deeplink";
  static const String notifyAppointmentNotification        = "edu.illinois.rokwire.firebase.messaging.appointment";

  // Topic names
  static const List<String> _permanentTopics = [
    "config_update",
    "popup_message",
    "polls",
  ];

  // Settings entry : topic name
  static const Map<String, String> _notifySettingTopics = {
    _newAppointmentUpdatesNotificationSetting  : _newAppointmentUpdatesNotificationSetting,
    'event_reminders'  : 'event_reminders',
    'dining_specials'  : 'dinning_specials',
    _groupUpdatesPostsNotificationSetting : _groupUpdatesPostsNotificationSetting,
    _groupUpdatesInvitationsNotificationSetting : _groupUpdatesInvitationsNotificationSetting,
    _groupUpdatesEventsNotificationSetting : _groupUpdatesEventsNotificationSetting,
    _groupUpdatesPollsNotificationSetting : _groupUpdatesPollsNotificationSetting,
  };

  // Settings entry : setting name (User.prefs.setting name)
  static const Map<String, String> _notifySettingNames = {
    _newAppointmentUpdatesNotificationSetting   : 'edu.illinois.rokwire.settings.inbox.notification.new_appointment.enabled',
    _eventRemindersUpdatesNotificationSetting   : 'edu.illinois.rokwire.settings.inbox.notification.event_reminders.enabled',
    _diningSpecialsUpdatesNotificationSetting   : 'edu.illinois.rokwire.settings.inbox.notification.dining_specials.enabled',
    _groupUpdatesPostsNotificationSetting       : 'edu.illinois.rokwire.settings.inbox.notification.group.posts.enabled',
    _groupUpdatesPollsNotificationSetting       : 'edu.illinois.rokwire.settings.inbox.notification.group.polls.enabled',
    _groupUpdatesInvitationsNotificationSetting : 'edu.illinois.rokwire.settings.inbox.notification.group.invitations.enabled',
    _groupUpdatesEventsNotificationSetting      : 'edu.illinois.rokwire.settings.inbox.notification.group.events.enabled',
    _athleticsUpdatesStartNotificationSetting   : 'edu.illinois.rokwire.settings.inbox.notification.athletic_updates.start.enabled',
    _athleticsUpdatesEndNotificationSetting     : 'edu.illinois.rokwire.settings.inbox.notification.athletic_updates.end.enabled',
    _athleticsUpdatesNewsNotificationSetting    : 'edu.illinois.rokwire.settings.inbox.notification.athletic_updates.news.enabled',
    _athleticsUpdatesNotificationKey            : 'edu.illinois.rokwire.settings.inbox.notification.athletic_updates.main.notifications.enabled',
    _groupUpdatesNotificationKey                : 'edu.illinois.rokwire.settings.inbox.notification.group.main.notifications.enabled',
    _pauseNotificationKey                       : 'edu.illinois.rokwire.settings.inbox.notification.event_reminders.enabled',
  };

  static const Map<String, bool> _defaultNotificationSettings = {
    _pauseNotificationKey : false
  };

  //settingKeys
  static const String _newAppointmentUpdatesNotificationSetting = 'new_appointment';
  static const String _eventRemindersUpdatesNotificationSetting = 'event_reminders';
  static const String _diningSpecialsUpdatesNotificationSetting = 'dining_specials';
  static const String _pauseNotificationKey = 'pause_notifications';

  static const String _athleticsUpdatesNotificationKey = 'athletic_updates';
  static const String _groupUpdatesNotificationKey = 'group';

  // Athletics Notification updates
  static const String _athleticsStartNotificationKey = 'start';
  static const String _athleticsEndNotificationKey = 'end';
  static const String _athleticsNewsNotificationKey = 'news';

  static const List<String> _athleticsNotificationsKeyList = [_athleticsStartNotificationKey, _athleticsEndNotificationKey, _athleticsNewsNotificationKey];

  static const String _athleticsUpdatesStartNotificationSetting = '$_athleticsUpdatesNotificationKey.$_athleticsStartNotificationKey';
  static const String _athleticsUpdatesEndNotificationSetting = '$_athleticsUpdatesNotificationKey.$_athleticsEndNotificationKey';
  static const String _athleticsUpdatesNewsNotificationSetting = '$_athleticsUpdatesNotificationKey.$_athleticsNewsNotificationKey';

  // Group Notification updates
  static const String _groupPostsNotificationKey = 'posts';
  static const String _groupInvitationsNotificationKey = 'invitations';
  static const String _groupEventsNotificationKey = 'events';
  static const String _groupPollsNotificationKey = 'polls';

  static const List<String> _groupNotificationsKeyList = [_groupPostsNotificationKey, _groupInvitationsNotificationKey, _groupEventsNotificationKey, _groupPollsNotificationKey];

  static const String _groupUpdatesPostsNotificationSetting = '$_groupUpdatesNotificationKey.$_groupPostsNotificationKey';
  static const String _groupUpdatesInvitationsNotificationSetting = '$_groupUpdatesNotificationKey.$_groupInvitationsNotificationKey';
  static const String _groupUpdatesEventsNotificationSetting = '$_groupUpdatesNotificationKey.$_groupEventsNotificationKey';
  static const String _groupUpdatesPollsNotificationSetting = '$_groupUpdatesNotificationKey.$_groupPollsNotificationKey';

  // Payload types
  static const String payloadTypeConfigUpdate = 'config_update';
  static const String payloadTypePopupMessage = 'popup_message';
  static const String payloadTypeOpenPoll = 'poll_open';
  static const String payloadTypeEventDetail = 'event_detail';
  static const String payloadTypeGameDetail = 'game_detail';
  static const String payloadTypeAthleticsGameStarted = 'athletics_game_started';
  static const String payloadTypeAthleticsNewDetail = 'athletics_news_detail';
  static const String payloadTypeGroup = 'group';
  static const String payloadTypeHome = 'home';
  static const String payloadTypeInbox = 'inbox';
  static const String payloadTypeCanvasAppDeepLink = 'canvas_app_deeplink';
  static const String payloadTypeAppointment = 'appointment';

  DateTime? _pausedDateTime;
  
  // Singletone Factory

  @protected
  FirebaseMessaging.internal() : super.internal();

  factory FirebaseMessaging() => ((rokwire.FirebaseMessaging.instance is FirebaseMessaging) ? (rokwire.FirebaseMessaging.instance as FirebaseMessaging) : (rokwire.FirebaseMessaging.instance = FirebaseMessaging.internal()));

  // Service

  @override
  void createService() {
    super.createService();
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyRolesChanged,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2UserPrefs.notifyInterestsChanged,
      Auth2.notifyProfileChanged,
      Auth2.notifyUserDeleted,
      FlexUI.notifyChanged,
      AppLivecycle.notifyStateChanged,
      Inbox.notifyInboxUserInfoChanged
    ]);
  }

  @override
  void destroyService() {
    super.destroyService();
    NotificationService().unsubscribe(this);
  }

  @override
  Set<Service> get serviceDependsOn {
    Set<Service> services = super.serviceDependsOn;
    services.add(Auth2());
    return services;
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
    else if (name == FlexUI.notifyChanged) {
      _updateNotifySettingsSubscriptions();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param); 
    }
    else if (name == Inbox.notifyInboxUserInfoChanged) {
      _updateSubscriptions();
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateSubscriptions();
        }
      }
    }
  }

  // AndroidNotificationChannel

  @override
  AndroidNotificationChannel get androidNotificationChannel {
    return const AndroidNotificationChannel(
      "Notifications_Channel_ID", // id
      "Illinois", // name
      description: "Receive notifications",
      importance: Importance.high,
    );
  }

  // Token

  @override
  void applyToken(String? token) {
    super.applyToken(token);
    _updateSubscriptions();
  }

  // Message Processing

  @override
  void processDataMessage(Map<String, dynamic>? data) => _processDataMessage(data);

  void _processDataMessage(Map<String, dynamic>? data, {String? type} ) {
    
    if (type == null) {
      type = _getMessageType(data);
    }
    
    if (type == payloadTypeConfigUpdate) {
      _onConfigUpdate(data);
    }
    else if (type == payloadTypePopupMessage) {
      NotificationService().notify(notifyPopupMessage, data);
    }
    else if (type == payloadTypeOpenPoll) {
      NotificationService().notify(notifyPollOpen, data);
    }
    else if (type == payloadTypeEventDetail) {
      NotificationService().notify(notifyEventDetail, data);
    }
    else if (type == payloadTypeGameDetail) {
      NotificationService().notify(notifyGameDetail, data);
    }
    else if (type == payloadTypeAthleticsGameStarted) {
      NotificationService().notify(notifyAthleticsGameStarted, data);
    }
    else if (type == payloadTypeAthleticsNewDetail) {
      NotificationService().notify(notifyAthleticsNewsUpdated, data);
    }
    else if (type == payloadTypeGroup) {
      String? groupPostId = JsonUtils.stringValue(data?['post_id']);
      if (groupPostId != null) {
        NotificationService().notify(notifyGroupPostNotification, data);
      } else {
        NotificationService().notify(notifyGroupsNotification, data);
      }
    }
    else if (type == payloadTypeHome) {
      NotificationService().notify(notifyHomeNotification, data);
    }
    else if (type == payloadTypeInbox) {
      NotificationService().notify(notifyInboxNotification, data);
    }
    else if (type == payloadTypeCanvasAppDeepLink) {
      NotificationService().notify(notifyCanvasAppDeepLinkNotification, data);
    }
    else if (type == payloadTypeAppointment) {
      NotificationService().notify(notifyAppointmentNotification, data);
    }
    else if (_isScoreTypeMessage(type)) {
      NotificationService().notify(notifyScoreMessage, data);
    }
    else {
      Log.d("FCM: unknown message type: ${JsonUtils.encode(data)}");
    }
  }

  static String? _getMessageType(Map<String, dynamic>? data) {
    if (data == null)
      return null;

    //1. check type
    String? type = data["type"];
    if (type != null)
      return type;

    //2. check Type - deprecated!
    String? type2 = data["Type"];
    if (type2 != null)
      return type2;

    //3. check Path - deprecated!
    String? path = data["Path"];
    if (path != null) {
      String? gameId = data['GameId'];
      dynamic hasStarted = data['HasStarted'];
      // Handle 'Game Started / Ended' notification which does not contain key 'HasStarted'
      if (StringUtils.isNotEmpty(gameId) && (hasStarted == null)) {
        return 'athletics_game_started';
      } else {
        return path;
      }
    }

    //treat everything else as config update - the backend gives it without "type"!
    return "config_update";
  }

  bool _isScoreTypeMessage(String? type) {
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

  void _onConfigUpdate(Map<String, dynamic>? data) {
    int interval = 5 * 60; // 5 minutes
    var rng = new Random();
    int delay = rng.nextInt(interval);
    Log.d("FCM: Scheduled config update after ${delay.toString()} seconds");
    Timer(Duration(seconds: delay), () {
      Log.d("FCM: Perform config update");
      NotificationService().notify(notifyConfigUpdate, data);
    });
  }

  void processDataMessageEx(Map<String, dynamic>? data, { Set<String>? allowedPayloadTypes }) {
    String? messageType;
    if ((allowedPayloadTypes == null) || (allowedPayloadTypes.contains(messageType = _getMessageType(data)))) {
      _processDataMessage(data, type: messageType);
    }
  }

  // Settings topics

  bool? get notifyNewAppointment               { return _getNotifySetting('new_appointment'); } 
       set notifyNewAppointment(bool? value)   { _setNotifySetting('new_appointment', value); }

  bool? get notifyEventReminders               { return _getNotifySetting('event_reminders'); } 
       set notifyEventReminders(bool? value)   { _setNotifySetting('event_reminders', value); }

  bool? get notifyAthleticsUpdates             { return _getNotifySetting(_athleticsUpdatesNotificationKey); }
       set notifyAthleticsUpdates(bool? value) { _setNotifySetting(_athleticsUpdatesNotificationKey, value); }

  bool? get notifyStartAthleticsUpdates              { return _getNotifySetting(_athleticsUpdatesStartNotificationSetting); }
       set notifyStartAthleticsUpdates(bool? value)  { _setNotifySetting(_athleticsUpdatesStartNotificationSetting, value); }

  bool? get notifyEndAthleticsUpdates                { return _getNotifySetting(_athleticsUpdatesEndNotificationSetting); }
       set notifyEndAthleticsUpdates(bool? value)    { _setNotifySetting(_athleticsUpdatesEndNotificationSetting, value); }

  bool? get notifyNewsAthleticsUpdates               { return _getNotifySetting(_athleticsUpdatesNewsNotificationSetting); }
       set notifyNewsAthleticsUpdates(bool? value)   { _setNotifySetting(_athleticsUpdatesNewsNotificationSetting, value); }

  bool? get notifyGroupUpdates             { return _getNotifySetting(_groupUpdatesNotificationKey); }
  set notifyGroupUpdates(bool? value) { _setNotifySetting(_groupUpdatesNotificationKey, value); }

  bool? get notifyGroupPostUpdates              { return _getNotifySetting(_groupUpdatesPostsNotificationSetting); }
  set notifyGroupPostUpdates(bool? value)  { _setNotifySetting(_groupUpdatesPostsNotificationSetting, value); }

  bool? get notifyGroupInvitationsUpdates                { return _getNotifySetting(_groupUpdatesInvitationsNotificationSetting); }
  set notifyGroupInvitationsUpdates(bool? value)    { _setNotifySetting(_groupUpdatesInvitationsNotificationSetting, value); }

  bool? get notifyGroupPollsUpdates                { return _getNotifySetting(_groupUpdatesPollsNotificationSetting); }
  set notifyGroupPollsUpdates(bool? value)    { _setNotifySetting(_groupUpdatesPollsNotificationSetting, value); }

  bool? get notifyGroupEventsUpdates               { return _getNotifySetting(_groupUpdatesEventsNotificationSetting); }
  set notifyGroupEventsUpdates(bool? value)   { _setNotifySetting(_groupUpdatesEventsNotificationSetting, value); }

  bool? get notifyDiningSpecials               { return _getNotifySetting('dining_specials'); } 
       set notifyDiningSpecials(bool? value)   { _setNotifySetting('dining_specials', value); }

  set notificationsPaused(bool? value)   {_setNotifySetting(_pauseNotificationKey, value);}

  bool? get notificationsPaused {return _getStoredSetting(_pauseNotificationKey,);}

  bool get _notifySettingsAvailable  {
    return FlexUI().isNotificationsAvailable;
  }

  bool? _getNotifySetting(String name) {
    if (_notifySettingsAvailable) {
      return _getStoredSetting(name);
    }
    else {
      return false;
    }
  }

  void _setNotifySetting(String name, bool? value) {
    if (_notifySettingsAvailable && (_getNotifySetting(name) != value)) {
      _storeSetting(name, value);
      NotificationService().notify(notifySettingUpdated, name);

      if (name == _athleticsUpdatesNotificationKey) {
        _processAthleticsSubscriptions(subscribedTopics: currentTopics);
      } else if (name == _athleticsUpdatesStartNotificationSetting) {
        _processAthleticsSingleSubscription(_athleticsStartNotificationKey);
      } else if (name == _athleticsUpdatesEndNotificationSetting) {
        _processAthleticsSingleSubscription(_athleticsEndNotificationKey);
      } else if (name == _athleticsUpdatesNewsNotificationSetting) {
        _processAthleticsSingleSubscription(_athleticsNewsNotificationKey);
      } else if (name == _groupUpdatesNotificationKey) {
        _processGroupsSubscriptions(subscribedTopics: currentTopics);
      } else if (name == _pauseNotificationKey) {
        Inbox().applySettingNotificationsEnabled(value);
      } else {
        _processNotifySettingSubscription(topic: _notifySettingTopics[name], value: value, subscribedTopics: currentTopics);
      }

    }
  }

  // Subscription Management

  void _updateSubscriptions(){
    if (hasToken) {
      Set<String?>? subscribedTopics = currentTopics;
      _processPermanentSubscriptions(subscribedTopics: subscribedTopics);
      _processRolesSubscriptions(subscribedTopics: subscribedTopics);
      _processNotifySettingsSubscriptions(subscribedTopics: subscribedTopics);
      _processAthleticsSubscriptions(subscribedTopics: subscribedTopics);
      _processGroupsSubscriptions(subscribedTopics: subscribedTopics);
    }
  }

  void _updateRolesSubscriptions(){
    if (hasToken) {
      _processRolesSubscriptions(subscribedTopics: currentTopics);
    }
  }

  void _updateNotifySettingsSubscriptions(){
    if (hasToken) {
      _processNotifySettingsSubscriptions(subscribedTopics: currentTopics);
    }
  }

  void _updateAthleticsSubscriptions(){
    if (hasToken) {
      _processAthleticsSubscriptions(subscribedTopics: currentTopics);
    }
  }

  void _processPermanentSubscriptions({Set<String?>? subscribedTopics}) {
    for (String permanentTopic in _permanentTopics) {
      if ((subscribedTopics == null) || !subscribedTopics.contains(permanentTopic)) {
        subscribeToTopic(permanentTopic);
      }
    }
  }

  void _processRolesSubscriptions({Set<String?>? subscribedTopics}) {
    Set<UserRole>? roles = Auth2().prefs?.roles;
    for (UserRole role in UserRole.values) {
      String roleTopic = role.toString();
      bool roleSubscribed = (subscribedTopics != null) && subscribedTopics.contains(roleTopic);
      bool roleSelected = (roles != null) && roles.contains(role);
      if (roleSelected && !roleSubscribed) {
        subscribeToTopic(roleTopic);
      }
      else if (!roleSelected && roleSubscribed) {
        unsubscribeFromTopic(roleTopic);
      }
    }
  }
  
  void _processNotifySettingsSubscriptions({Set<String?>? subscribedTopics}) {
    _notifySettingTopics.forEach((String setting, String topic) {
      bool? value = _getNotifySetting(setting);
      _processNotifySettingSubscription(topic: topic, value: value, subscribedTopics: subscribedTopics);
    });
  }

  void _processNotifySettingSubscription({String? topic, bool? value, Set<String?>? subscribedTopics}) {
    if (topic != null) {
      bool itemSubscribed = (subscribedTopics != null) && subscribedTopics.contains(topic);
      if (value! && !itemSubscribed) {
        subscribeToTopic(topic);
      }
      else if (!value && itemSubscribed) {
        unsubscribeFromTopic(topic);
      }
    }
  }

  void _processAthleticsSubscriptions({Set<String?>? subscribedTopics}) {
    bool? notifyAthletics = notifyAthleticsUpdates;
    List<SportDefinition>? sportDefs = Sports().sports;
    if (sportDefs != null) {
      for (SportDefinition sportDef in sportDefs) {
        String? sport = sportDef.shortName;
        for (String key in _athleticsNotificationsKeyList) {
          _processAthleticsSubscriptionForSport(notifyAllowed: notifyAthletics, athleticsKey: key, sport: sport, subscribedTopics: subscribedTopics);
        }
      }
    }
  }

  void _processAthleticsSingleSubscription(String athleticsKey) {
    List<SportDefinition>? sports = Sports().sports;
    if (CollectionUtils.isNotEmpty(sports)) {
      Set<String?>? subscribedTopics = currentTopics;
      for (SportDefinition sport in sports!) {
        _processAthleticsSubscriptionForSport(notifyAllowed: true, athleticsKey: athleticsKey, sport: sport.shortName, subscribedTopics: subscribedTopics);
      }
    }
  }

  void _processAthleticsSubscriptionForSport({bool? notifyAllowed, String? athleticsKey, String? sport, Set<String?>? subscribedTopics}) {
    if (StringUtils.isNotEmpty(sport)) {
      bool notify = notifyAllowed! && _getNotifySetting('$_athleticsUpdatesNotificationKey.$athleticsKey')!;
      bool sportSelected = Auth2().prefs?.sportsInterests?.contains(sport) ?? false;
      bool subscriptionValue = notify && sportSelected;
      String topic = 'athletics.$sport.notification.$athleticsKey';
      bool subscribed = subscribedTopics?.contains(topic) ?? false;
      if (subscriptionValue && !subscribed) {
        FirebaseMessaging().subscribeToTopic(topic);
      } else if (!subscriptionValue && subscribed) {
        FirebaseMessaging().unsubscribeFromTopic(topic);
      }
    }
  }

  void _processGroupsSubscriptions({Set<String?>? subscribedTopics}) {
    bool? groupSettingsAvailable  = notifyGroupUpdates;
    if (groupSettingsAvailable  != null) {
      for (String key in _groupNotificationsKeyList) {
        String topic = "$_groupUpdatesNotificationKey.$key";
        bool subscribed = subscribedTopics?.contains(topic) ?? false;
        bool value = true;
        try{value = _getNotifySetting(topic) ?? false;} catch (e){print(e);}
        if ((!groupSettingsAvailable || !value) && subscribed){
          FirebaseMessaging().unsubscribeFromTopic(topic);
        }
        if(groupSettingsAvailable && value  && !subscribed){
          FirebaseMessaging().subscribeToTopic(topic);
        }
      }
    }
  }

  bool? _getStoredSetting(String name){
    bool defaultValue = _defaultNotificationSettings[name] ?? true; //true by default
    if(name == _pauseNotificationKey){ // settings depending on userInfo
      if(Auth2().isLoggedIn && Inbox().userInfo != null){
        return Inbox().userInfo?.notificationsDisabled ?? false; //This is the only setting stored in the userInfo
      }
    }
    if(Auth2().isLoggedIn){ // Logged user choice stored in the UserPrefs
      return  Auth2().prefs?.getBoolSetting(_notifySettingNames[name] ?? name, defaultValue: defaultValue);
    }
    return Storage().getNotifySetting(_notifySettingNames[name] ?? name) ?? defaultValue;
  }

  void _storeSetting(String name, bool? value) {
    //// Logged user choice stored in the UserPrefs
    if (Auth2().isLoggedIn) {
      Auth2().prefs?.applySetting(_notifySettingNames[name] ?? name, value);
    } else {
      Storage().setNotifySetting(_notifySettingNames[name] ?? name, value);
    }
  }

  static Map<String, dynamic>? get storedSettings {
    Map<String, dynamic>? result;
    _notifySettingNames.forEach((String storageKey, String profileKey) {
      bool? value = Storage().getNotifySetting(storageKey) ?? Storage().getNotifySetting(profileKey);
      if (value != null) {
        if (result != null) {
          result![profileKey] = value;
        }
        else {
          result = { profileKey : value };
        }
      }
    });
    return result;
  }

  Set<String?>? get currentTopics{
    Set<String?>? subscribedTopics = Storage().inboxFirebaseMessagingSubscriptionTopics;
    if(Auth2().isLoggedIn){
      subscribedTopics = (Inbox().userInfo)?.topics;
    }

    return subscribedTopics;
  }
}
