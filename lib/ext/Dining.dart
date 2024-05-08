import 'dart:ui';

import 'package:neom/model/Dining.dart';
import 'package:neom/service/Analytics.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension DiningExt on Dining {
  
  Map<String, dynamic>? get analyticsAttributes => {
        Analytics.LogAttributeDiningId:   id,
        Analytics.LogAttributeDiningName: title,
        Analytics.LogAttributeLocation : location?.analyticsValue,
  };

  Color? get uiColor => Styles().colors.diningColor;

}