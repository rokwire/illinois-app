
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RokwirePlugin {
  static const MethodChannel _channel = MethodChannel('edu.illinois.rokwire/plugin');

  static Future<String?> get platformVersion async {
    try { return await _channel.invokeMethod('getPlatformVersion'); }
    catch(e) { debugPrint(e.toString()); }
    return null;
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
