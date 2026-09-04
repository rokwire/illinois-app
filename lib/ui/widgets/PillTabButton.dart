/*
 * Copyright 2026 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class PillTabButton extends StatelessWidget {
  final String title;
  final bool selected;
  final PillTabButtonPosition position;
  final bool uppercase;
  final void Function()? onTap;

  final String? semanticsLabel;
  final String? semanticsHint;

  PillTabButton(this.title, {super.key,
    this.selected = false, this.position = PillTabButtonPosition.middle,
    this.uppercase = true,
    this.semanticsLabel, this.semanticsHint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(label: _semanticsLabel, hint: _semanticsHint, selected: selected, button: true, excludeSemantics: true, child:
    InkWell(splashColor: Colors.transparent, onTap: onTap, child:
      Container(
        decoration: BoxDecoration(color: _frameColor, border: _frameBorder, borderRadius: _frameBorderRadius,),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Center(child:
          Text(_displayTitle, style: _textStyle, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,)
        ),
      )
    )
  );

  String get _displayTitle => uppercase ? title.toUpperCase() : title;

  Color get _frameColor => selected ? Styles().colors.surface : Styles().colors.background;
  TextStyle? get _textStyle => Styles().textStyles.getTextStyle(selected ? 'widget.button.title.small.fat.spaced' : 'widget.button.title.small.spaced');

  BoxBorder get _frameBorder => (position != PillTabButtonPosition.last) ?
    Border(left: _frameBorderSide, top: _frameBorderSide, bottom: _frameBorderSide) :
    Border.fromBorderSide(_frameBorderSide);

  BorderRadiusGeometry get _frameBorderRadius {
    switch (position) {
      case PillTabButtonPosition.first: return BorderRadius.horizontal(left: _frameRadius);
      case PillTabButtonPosition.last: return BorderRadius.horizontal(right: _frameRadius);
      default: return BorderRadius.zero;
    }
  }

  BorderSide get _frameBorderSide => BorderSide(color: Styles().colors.surfaceAccent2);
  Radius get _frameRadius => Radius.circular(24);

  String get _semanticsLabel => semanticsLabel ?? title;
  String get _semanticsHint => semanticsHint ?? AppSemantics.selectHint(subject: _semanticsLabel);
}

enum PillTabButtonPosition { first, middle, last }

extension PillTabButtonPositionImpl on PillTabButtonPosition {
  static PillTabButtonPosition fromIndex(int index, int length) {
    if (index == 0) {
      return PillTabButtonPosition.first;
    } else if ((index + 1) == length) {
      return PillTabButtonPosition.last;
    }
    else {
      return PillTabButtonPosition.middle;
    }
  }
}
