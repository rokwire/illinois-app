/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
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
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/ui/widgets/expandable_text.dart' as rokwire;

class ExpandableText extends rokwire.ExpandableText {
  const ExpandableText(String text, {
    Key? key,
    TextStyle? textStyle,

    int trimLinesCount = 3,

    Color? splitterColor,
    double splitterHeight = 1.0,
    EdgeInsetsGeometry splitterMargin = const EdgeInsets.symmetric(vertical: 5),

    TextStyle? readMoreStyle,

    Widget? readMoreIcon,
    String? readMoreIconAsset = 'images/icon-down-orange.png',
    EdgeInsetsGeometry readMoreIconPadding = const EdgeInsets.only(left: 7),

    Widget? footerWidget,
  }) : super(text,
    key: key,
    textStyle: textStyle,

    trimLinesCount: trimLinesCount,

    splitterColor: splitterColor,
    splitterHeight: splitterHeight,
    splitterMargin: splitterMargin,

    readMoreStyle: readMoreStyle,
    
    readMoreIcon: readMoreIcon,
    readMoreIconAsset: readMoreIconAsset,
    readMoreIconPadding: readMoreIconPadding,

    footerWidget: footerWidget,
  );

  @override
  String get trimSuffix => '...';

  @override
  String get readMoreText => Localization().getStringEx('common.label.read_more', 'Read more');
}

