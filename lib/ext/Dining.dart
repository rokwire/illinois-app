import 'dart:ui';

import 'package:illinois/model/Dining.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/gen/styles.dart' as illinois;

extension DiningExt on Dining {
  
  Map<String, dynamic>? get analyticsAttributes => {
        Analytics.LogAttributeDiningId:   id,
        Analytics.LogAttributeDiningName: title,
        Analytics.LogAttributeLocation : location?.analyticsValue,
  };

  Color? get uiColor => illinois.AppColors.diningColor;

}