import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension DiningExt on Dining {
  
  Map<String, dynamic>? get analyticsAttributes => {
        Analytics.LogAttributeDiningId:   id,
        Analytics.LogAttributeDiningName: title,
        Analytics.LogAttributeLocation : location?.analyticsValue,
  };

  Color? get uiColor => Styles().colors.diningColor;

}

extension DiningFilter on Dining {
  bool matchSearchTextLowerCase(String searchLowerCase) =>
    (searchLowerCase.isNotEmpty && (
      (title?.toLowerCase().contains(searchLowerCase) == true) ||
      (diningType?.toLowerCase().contains(searchLowerCase) == true) ||
      (description?.toLowerCase().contains(searchLowerCase) == true) ||
      (location?.matchSearchTextLowerCase(searchLowerCase) == true)
    ));
}

extension DiningScheduleFilter on DiningSchedule {
  bool matchSearchTextLowerCase(String searchLowerCase) =>
    (searchLowerCase.isNotEmpty && (
      (meal?.toLowerCase().contains(searchLowerCase) == true)
    ));
}

extension DiningSchedulesFilter on Iterable<DiningSchedule> {
  bool matchSearchTextLowerCase(String searchLowerCase) =>
    firstWhereOrNull((DiningSchedule diningSchedule) => diningSchedule.matchSearchTextLowerCase(searchLowerCase)) != null;
}

extension PaymentTypeImpl on PaymentType {
  String get displayTitle => PaymentTypeHelper.paymentTypeToDisplayString(this) ?? '';
}
