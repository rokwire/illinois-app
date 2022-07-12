import 'dart:ui';

import 'package:illinois/model/Laundry.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension LaundryRoomExt on LaundryRoom {
  
  Color? get uiColor => Styles().colors?.accentColor2;

}