
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/MTD.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension MTDStopExt on MTDStop {
  Color? get uiColor => Styles().colors.mtdColor;

  bool _isFavorite(LinkedHashSet<String> favStopIds) {
    if (favStopIds.contains(id)) {
      return true;
    } else if ((points != null) && (points?.isNotEmpty == true)) {
      for (MTDStop point in points ?? []) {
        if (point._isFavorite(favStopIds)) {
          return true;
        }
      }
      return false;
    } else {
      return false;
    }
  }
}

extension MTDStopFilter on MTDStop {

  bool matchSearchTextLowerCase(String searchLowerCase) =>
    (searchLowerCase.isNotEmpty && (
      (name?.toLowerCase().contains(searchLowerCase) == true) ||
      (code?.toLowerCase().contains(searchLowerCase) == true)
    ));
}


extension MTDFavs on MTD {
  List<MTDStop>? get favoriteStops {
    List<MTDStop>? stops = MTD().stops?.stops;
    LinkedHashSet<String>? favStopIds = Auth2().account?.prefs?.getFavorites(MTDStop.favoriteKeyName);
    if ((stops != null) && stops.isNotEmpty && (favStopIds != null) && favStopIds.isNotEmpty) {
      List<MTDStop> favStops = <MTDStop>[];
      for (MTDStop stop in stops) {
        if (stop._isFavorite(favStopIds)) {
          favStops.add(stop);
        }
      }
      return favStops;
    } else {
      return null;
    }
    //MTD().stopsByIds(Auth2().account?.prefs?.getFavorites(MTDStop.favoriteKeyName) ?? LinkedHashSet<String>());
  }
}