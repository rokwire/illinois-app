
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';

class RokwirePlugin {
  static final MethodChannel _channel = _createChannel('edu.illinois.rokwire/plugin', _handleChannelCall);

  static MethodChannel _createChannel(String name, Future<dynamic> Function(MethodCall call)? handler) {
    MethodChannel channel = MethodChannel(name);
    channel.setMethodCallHandler(handler);
    return channel;
  }

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
    return false;
  }

  static Future<bool?> launchApp(Map<String, dynamic> params) async {
    try { return await _channel.invokeMethod('launchApp', params); }
    catch(e) { debugPrint(e.toString()); }
    return false;
  }

  static Future<bool?> launchAppSettings() async {
    try { return await _channel.invokeMethod('launchAppSettings'); }
    catch(e) { debugPrint(e.toString()); }
    return false;
  }

  // Compound APIs

  static Future<dynamic> locationServices(String method, [dynamic arguments]) async {
    try { return await _channel.invokeMethod('locationServices.$method', arguments); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  static Future<dynamic> trackingServices(String method, [dynamic arguments]) async {
    try { return await _channel.invokeMethod('trackingServices.$method', arguments); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  static Future<dynamic> geoFence(String method, [dynamic arguments]) async {
    try { return await _channel.invokeMethod('geoFence.$method', arguments); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  // Channel call handler

  static Future<dynamic> _handleChannelCall(MethodCall call) async {
    
    String? firstMethodComponent = call.method, nextMethodComponents;
    int position = call.method.indexOf('.');
    if (0 <= position) {
      firstMethodComponent = call.method.substring(0, position);
      nextMethodComponents = call.method.substring(position + 1, call.method.length - position - 1);
    }

    if (firstMethodComponent == 'geoFence') {
      GeoFence().onPluginNotification(nextMethodComponents, call.arguments);
    }
  }
}
