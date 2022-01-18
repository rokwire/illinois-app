
import 'dart:async';

import 'package:flutter/services.dart';

class RokwirePlugin {
  static const MethodChannel _channel = MethodChannel('edu.illinois.rokwire/plugin');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
