import 'dart:ui';

import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension GameExt on Game {
  
  String? get typeDisplayString {
    return Localization().getStringEx('panel.explore_detail.event_type.in_person', "In-person event");
  }

  Map<String, dynamic>? get analyticsAttributes => {
    Analytics.LogAttributeGameId: exploreId,
    Analytics.LogAttributeGameName: exploreTitle,
    Analytics.LogAttributeLocation : location?.location,
  };

  Color? get uiColor => Styles().colors?.fillColorPrimary;

}