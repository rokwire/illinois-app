
import 'dart:ui';

import 'package:illinois/model/Wordle.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension WordleLetterStatusUi on WordleLetterStatus {
  Color get color {
    switch (this) {
      case WordleLetterStatus.inPlace: return Styles().colors.getColor('illordle.green') ?? const Color(0xFF21AA57);
      case WordleLetterStatus.inUse: return Styles().colors.getColor('illordle.yellow') ?? const Color(0xFFE5B22E);
      case WordleLetterStatus.outOfUse: return Styles().colors.getColor('illordle.gray') ?? const Color(0xFF7A7A7A);
    }
  }
}

extension WordleString on String {
  bool get isWordleAlpha => (length == 1) && (toUpperCase() != toLowerCase());
}

