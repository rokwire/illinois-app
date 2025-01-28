
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/MTD.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension MTDStopExt on MTDStop {
  Color? get uiColor => Styles().colors.mtdColor;
}
extension MTDFavs on MTD {
  List<MTDStop>? get favoriteStops =>
    MTD().stopsByIds(Auth2().account?.prefs?.getFavorites(MTDStop.favoriteKeyName) ?? LinkedHashSet<String>());
}