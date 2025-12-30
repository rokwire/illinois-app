import 'package:flutter/foundation.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:screen_brightness/screen_brightness.dart';

class BrightnessHighlight {
  final Set<String>? objectives;
  final double? value;
  
  BrightnessHighlight({this.value, this.objectives});
  
  static BrightnessHighlight? fromJson(Map<String, dynamic>? json) => (json != null) ? BrightnessHighlight(
    objectives: JsonUtils.setStringsValue(json['objectives']),
    value: JsonUtils.doubleValue(json['value']),
  ) : null;
  
  static BrightnessHighlight? fromAppConfig() =>
    fromJson(Config().brightnessHighlight);

  static BrightnessHighlight? forObjective(String? objective) {
    BrightnessHighlight? brightnessHighlight = (objective != null) ? BrightnessHighlight.fromAppConfig() : null;
    return (brightnessHighlight?.isHighlightObjective(objective) == true) ? brightnessHighlight : null;
  }

  bool isHighlightObjective(String? objective) =>
    (objective != null) && (objectives?.contains(objective) == true);

  Future<void> setAppBrightness() async {
    if (value != null) {
      try { return ScreenBrightness.instance.setApplicationScreenBrightness(value ?? 1); }
      catch (e) { debugPrint(e.toString()); }
    }
  }

  Future<void> restoreAppBrightness() async {
    if (value != null) {
      try { return ScreenBrightness.instance.resetApplicationScreenBrightness(); }
      catch (e) { debugPrint(e.toString()); }
    }
  }
}