
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/firebase_messaging.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Inbox with Service implements NotificationsListener {

  static const String notifyInboxUserInfoChanged   = "edu.illinois.rokwire.inbox.user.info.changed";

  String?   _fcmToken;
  String?   _fcmUserId;
  bool?     _isServiceInitialized;
  DateTime? _pausedDateTime;
  
  InboxUserInfo? _userInfo;

  // Singletone Factory

  static Inbox? _instance;

  static Inbox? get instance => _instance;
  
  @protected
  static set instance(Inbox? value) => _instance = value;

  factory Inbox() => _instance ?? (_instance = Inbox.internal());

  @protected
  Inbox.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      FirebaseMessaging.notifyToken,
      Auth2.notifyLoginChanged,
      Auth2.notifyPrepareUserDelete,
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _fcmToken = Storage().inboxFirebaseMessagingToken;
    _fcmUserId = Storage().inboxFirebaseMessagingUserId;
    _userInfo = Storage().inboxUserInfo;
    _isServiceInitialized = true;
    _processFcmToken();
    _loadUserInfo();
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Storage(), Config(), Auth2(), FirebaseMessaging() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FirebaseMessaging.notifyToken) {
      _processFcmToken();
    }
    else if (name == Auth2.notifyLoginChanged) {
      _processFcmToken();
      _loadUserInfo();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param); 
    } else if (name == Auth2.notifyPrepareUserDelete){
      _deleteUser();
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
          _processFcmToken();
          _loadUserInfo();
        }
      }
    }
  }

  // Inbox APIs

  Future<List<InboxMessage>?> loadMessages({DateTime? startDate, DateTime? endDate, String? category, Iterable? messageIds, int? offset, int? limit }) async {
    
    String urlParams = "";
    
    if (offset != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "offset=$offset";
    }
    
    if (limit != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "limit=$limit";
    }

    if (startDate != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "start_date=${startDate.millisecondsSinceEpoch}";
    }

    if (endDate != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "end_date=${endDate.millisecondsSinceEpoch}";
    }

    if (urlParams.isNotEmpty) {
      urlParams = "?$urlParams";
    }

    dynamic body = (messageIds != null) ? JsonUtils.encode({ "ids": List.from(messageIds) }) : null;

    String? url = (Config().notificationsUrl != null) ? "${Config().notificationsUrl}/api/messages$urlParams" : null;
    Response? response = await Network().get(url, body: body, auth: Auth2());
    return (response?.statusCode == 200) ? (InboxMessage.listFromJson(JsonUtils.decodeList(response?.body)) ?? []) : null;
  }

  Future<bool> deleteMessages(Iterable? messageIds) async {
    String? url = (Config().notificationsUrl != null) ? "${Config().notificationsUrl}/api/messages" : null;
    String? body = JsonUtils.encode({
      "ids": (messageIds != null) ? List.from(messageIds) : null
    });

    Response? response = await Network().delete(url, body: body, auth: Auth2());
    return (response?.statusCode == 200);
  }

  Future<bool> sendMessage(InboxMessage? message) async {
    String? url = (Config().notificationsUrl != null) ? "${Config().notificationsUrl}/api/message" : null;
    String? body = JsonUtils.encode(message?.toJson());

    Response? response = await Network().post(url, body: body, auth: Auth2());
    return (response?.statusCode == 200);
  }

  Future<bool> subscribeToTopic({String? topic, String? token}) async {
    _storeTopic(topic); // Store first, otherwise we have delay
    bool result = await _manageFCMSubscription(topic: topic, token: token, action: 'subscribe');
    if (!result){
      //if failed and not already stored remove
      Log.e("Unable to subscribe to topic: $topic");
    }

    return result;
  }

  Future<bool> unsubscribeFromTopic({String? topic, String? token}) async {
    _removeStoredTopic(topic); //StoreFist, otherwise we have visual delay
    bool result = await _manageFCMSubscription(topic: topic, token: token, action: 'unsubscribe');
    if (!result){
      //if failed //TBD
      Log.e("Unable to unsubscribe from topic: $topic");
    }

    return result;
  }

  Future<bool> _manageFCMSubscription({String? topic, String? token, String? action}) async {
    if ((Config().notificationsUrl != null) && (topic != null) && (token != null) && (action != null)) {
      String url = "${Config().notificationsUrl}/api/topic/$topic/$action";
      String? body = JsonUtils.encode({
        'token': token
      });
      Response? response = await Network().post(url, body: body, auth: Auth2());
      //Log.d("FCMTopic_$action($topic) => ${(response?.statusCode == 200) ? 'Yes' : 'No'}");
      return (response?.statusCode == 200);
    }
    return false;
  }

  // FCM Token

  void _processFcmToken() {
    // We call _processFcmToken when FCM token changes or when user logs in/out.
    if (_isServiceInitialized == true) {
      String? fcmToken = FirebaseMessaging().token;
      String? userId = Auth2().accountId;
      if ((fcmToken != null) && (fcmToken != _fcmToken)) {
        _updateFCMToken(token: fcmToken, previousToken: _fcmToken).then((bool result) {
          if (result) {
            Storage().inboxFirebaseMessagingToken = _fcmToken = fcmToken;
          }
        });
      }
      else if (userId != _fcmUserId) {
        _updateFCMToken(token: fcmToken).then((bool result) {
          if (result) {
            Storage().inboxFirebaseMessagingUserId = _fcmUserId = userId;
          }
        });
      }
    }
  }

  Future<bool> _updateFCMToken({String? token, String? previousToken}) async {
    if ((Config().notificationsUrl != null) && ((token != null) || (previousToken != null))) {
      String url = "${Config().notificationsUrl}/api/token";
      String? body = JsonUtils.encode({
        'token': token,
        'previous_token': previousToken,
        'app_platform': Platform.operatingSystem,
        'app_version': Config().appVersion,
      });
      Response? response = await Network().post(url, body: body, auth: Auth2());
      //Log.d("FCMToken_update(${(token != null) ? 'token' : 'null'}, ${(previousToken != null) ? 'token' : 'null'}) / UserId: '${Auth2().accountId}'  => ${(response?.statusCode == 200) ? 'Yes' : 'No'}");
      return (response?.statusCode == 200);
    }
    return false;
  }

  // Topics storage
  void _storeTopic(String? topic) {
    if (!Auth2().isLoggedIn) {
      Storage().addInboxFirebaseMessagingSubscriptionTopic(topic);
    }
    else if (userInfo != null) {
      _userInfo?.topics ??= <String>{};
      userInfo?.topics?.add(topic);
    }
  }

  void _removeStoredTopic(String? topic) {
    if (!Auth2().isLoggedIn) {
      Storage().removeInboxFirebaseMessagingSubscriptionTopic(topic);
    }
    else if (userInfo?.topics != null) {
      userInfo?.topics?.remove(topic);
    }
  }

  //UserInfo
  Future<void> _loadUserInfo() async {
    try {
      Response? response = (Auth2().isLoggedIn && Config().notificationsUrl != null) ? await Network().get("${Config().notificationsUrl}/api/user", auth: Auth2()) : null;
      if (response?.statusCode == 200) {
        Map<String, dynamic>? jsonData = JsonUtils.decode(response?.body);
        InboxUserInfo? userInfo = InboxUserInfo.fromJson(jsonData);
        _applyUserInfo(userInfo);
      }
    } catch (e) {
      Log.e('Failed to load inbox user info');
      Log.e(e.toString());
    }
  }

  Future<bool> _putUserInfo(InboxUserInfo? userInfo) async {
    if (Auth2().isLoggedIn && Config().notificationsUrl != null && userInfo != null){
      String? body = JsonUtils.encode(userInfo.toJson()); // Update user API do not receive topics. Only update enable/disable notifications for now
      Response? response = await Network().put("${Config().notificationsUrl}/api/user", auth: Auth2(), body: body);
      if (response?.statusCode == 200) {
        Map<String, dynamic>? jsonData = JsonUtils.decode(response?.body);
        InboxUserInfo? userInfo = InboxUserInfo.fromJson(jsonData);
        _applyUserInfo(userInfo);
        return true;
      }
    }
    return false;
  }

  Future<bool> applySettingNotificationsEnabled(bool? value) async{
    if (_userInfo != null && value!=null){
      userInfo!.notificationsDisabled = value;
      return _putUserInfo(InboxUserInfo(userId: _userInfo!.userId, notificationsDisabled: value));
    }
    return false;
  }
  
  void _applyUserInfo(InboxUserInfo? userInfo){
    if (_userInfo != userInfo){
      Storage().inboxUserInfo = _userInfo = userInfo;
      NotificationService().notify(notifyInboxUserInfoChanged);
    } //else it's the same
  }

  //Delete User
  void _deleteUser() async {
    try {
      String? body = JsonUtils.encode({
        'notifications_disabled': true,
      });
      Response? response = (Auth2().isLoggedIn && Config().notificationsUrl != null) ? await Network().delete("${Config().notificationsUrl}/api/user", auth: Auth2(), body: body) : null;
      if (response?.statusCode == 200) {
        _applyUserInfo(null);
      }
    } catch (e) {
      Log.e('Failed to delete inbox user info');
      Log.e(e.toString());
    }
  }

  InboxUserInfo? get userInfo{
    return _userInfo;
  }
}