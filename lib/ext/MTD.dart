
import 'package:flutter/material.dart';
import 'package:neom/model/MTD.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension MTDStopExt on MTDStop {
  Color? get uiColor => Styles().colors.mtdColor;
}
