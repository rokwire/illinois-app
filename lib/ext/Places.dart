
import 'dart:ui';

import 'package:rokwire_plugin/model/places.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension PlaceExt on Place {
  Color? get uiColor => Styles().colors.mtdColor;
  Color? get mapMarkerBorderColor => Styles().colors.fillColorSecondary;
  Color? get mapMarkerTextColor => Styles().colors.surface;
}