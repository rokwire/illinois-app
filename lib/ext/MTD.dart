
import 'package:flutter/material.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/gen/styles.dart' as illinois;

extension MTDStopExt on MTDStop {
  Color? get uiColor => illinois.AppColors.mtdColor;
}
