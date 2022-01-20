
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RokwirePlugin {
  static const MethodChannel _channel = MethodChannel('edu.illinois.rokwire/plugin');

  static Future<String?> get platformVersion async {
    String? result;
    try {
      result = await _channel.invokeMethod('getPlatformVersion');
    }
    catch(e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
    return result;
  }

  static Future<String?> queryLocationServicesStatus() async {
    String? result;
    try {
      result = await _channel.invokeMethod('locationServices.queryStatus');
    }
    catch(e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
    return result;
  }

  static Future<String?> requestLocationServicesPermisions() async {
    String? result;
    try {
      result = await _channel.invokeMethod('locationServices.requestPermision');
    }
    catch(e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
    return result;
  }
}
