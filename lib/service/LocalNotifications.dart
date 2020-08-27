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

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Log.dart';

class LocalNotifications with Service {

  static const String notifySelected   = "edu.illinois.rokwire.localnotifications.selected";
  
  static final LocalNotifications _instance = new LocalNotifications._internal();

  factory LocalNotifications() {
    return _instance;
  }

  LocalNotifications._internal();

  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  @override
  void createService() {
  }

  @override
  void destroyService() {
  }

  @override
  Future<void> initService() async {
    initPlugin();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([NativeCommunicator()]);
  }

  void initPlugin() {
    if (_flutterLocalNotificationsPlugin == null) {
      //int privacyLevel = Storage().getPrivacyLevel()?.toInt();
      //if ((privacyLevel != null) && (privacyLevel >= 4))
      if (Platform.isIOS) {
        NativeCommunicator().queryNotificationsAuthorization("query").then((bool notificationsAuthorized) {
          if (notificationsAuthorized) {
            _initPlugin();
          }
        });
      }
      else {
        _initPlugin();
      }
    }
  }

  void _initPlugin() {
    _flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings(onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
    var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: _onSelectNotification);
  }

  Future _onSelectNotification(String payload) async {
    Log.d('Android: on select local notification: ' + payload);
    NotificationService().notify(notifySelected, payload);
  }

  Future _onDidReceiveLocalNotification(int id, String title, String body, String payload) async {
    Log.d('iOS: on did receive local notification: ' + payload);
  }

  Future showNotification({String title, String message, String payload = ''}) async {
    if (_flutterLocalNotificationsPlugin != null) {
      var androidPlatformChannelSpecifics = AndroidNotificationDetails('1000', 'DEFAULT_CHANNEL', 'It is default channel', importance: Importance.Max, priority: Priority.High);
      var iOSPlatformChannelSpecifics = IOSNotificationDetails(presentAlert: true, presentSound: true,);
      var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
      await _flutterLocalNotificationsPlugin.show(0, title, message, platformChannelSpecifics, payload: payload, );
    }
  }

}
