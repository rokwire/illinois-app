import 'dart:ui';

import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension LaundryRoomExt on LaundryRoom {
  Color? get uiColor => Styles().colors.accentColor2;
}

extension LaundryRoomFilter on LaundryRoom {

  bool matchSearchTextLowerCase(String searchLowerCase) =>
    (searchLowerCase.isNotEmpty && (
      (name?.toLowerCase().contains(searchLowerCase) == true) ||
      (location?.matchSearchTextLowerCase(searchLowerCase) == true)
    ));
}
