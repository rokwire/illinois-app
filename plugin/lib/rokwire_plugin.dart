
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RokwirePlugin {
  static const MethodChannel _channel = MethodChannel('edu.illinois.rokwire/plugin');

  static Future<String?> get platformVersion async {
    try { return await _channel.invokeMethod('getPlatformVersion'); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  static Future<bool?> createAndroidNotificationChannel(AndroidNotificationChannel channel) async {
    try { return await _channel.invokeMethod('createAndroidNotificationChannel', {
      'id': channel.id,
      'name': channel.name,
      'description': channel.description,
      'sound': channel.playSound,
      'importance': channel.importance.value,
    }); }
    catch(e) { debugPrint(e.toString()); }
  }

  static Future<bool?> showNotification({ String? title, String? subtitle, String? body, bool sound = true }) async {
    try { return await _channel.invokeMethod('showNotification', {
      'title': title,
      'subtitle': subtitle,
      'body': body,
      'sound': sound,
    }); }
    catch(e) { debugPrint(e.toString()); }
  }

  static Future<String?> getDeviceId([String? identifier, String? identifier2]) async {
    try { return await _channel.invokeMethod('getDeviceId', {
      'identifier': identifier,
      'identifier2': identifier2
    }); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  static Future<String?> getEncryptionKey({String? identifier, int? size}) async {
    try { return await _channel.invokeMethod('getEncryptionKey', {
      'identifier': identifier,
      'size': size,
    }); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  static Future<bool?> dismissSafariVC() async {
    try { return await _channel.invokeMethod('dismissSafariVC'); }
    catch(e) { debugPrint(e.toString()); }
  }

  static Future<String?> queryLocationServicesStatus() async {
    try { return await _channel.invokeMethod('locationServices.queryStatus'); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  static Future<String?> requestLocationServicesPermisions() async {
    try { return await _channel.invokeMethod('locationServices.requestPermision'); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }
}
