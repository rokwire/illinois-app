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
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/ribbon_button.dart' as rokwire;

class RibbonButton extends rokwire.RibbonButton {
  RibbonButton({
    super.key,
    super.title,
    super.description,
    super.onTap,
    super.backgroundColor,
    super.padding,

    super.textWidget,
    super.textStyle,
    super.textColor,
    super.fontFamily,
    super.fontSize                  = 16.0,
    super.textAlign                 = TextAlign.left,

    super.descriptionWidget,
    super.descriptionTextStyle,
    super.descriptionTextColor,
    super.descriptionFontFamily,
    super.descriptionFontSize  = 14,
    super.descriptionTextAlign = TextAlign.left,
    super.descriptionPadding   = const EdgeInsets.only(top: 2),

    super.leftIcon,
    super.leftIconKey,
    super.leftIconPadding  = const EdgeInsets.only(right: 8),
  
    super.rightIcon,
    super.rightIconKey     = 'chevron-right-bold',
    super.rightIconPadding = const EdgeInsets.only(left: 8),

    super.border,
    super.borderRadius,
    super.borderShadow,

    super.progress,
    super.progressColor,
    super.progressSize,
    super.progressStrokeWidth,
    super.progressPadding   = const EdgeInsets.symmetric(horizontal: 12),
    super.progressAlignment = Alignment.centerRight,
    super.progressHidesIcon = true,

    super.semanticsLabel,
    super.semanticsHint,
    super.semanticsValue,
  });
}

class ToggleRibbonButton extends rokwire.ToggleRibbonButton {

  ToggleRibbonButton({
    super.key,
    super.title,
    super.description,
    super.onTap,
    super.backgroundColor,
    super.padding,

    super.textWidget,
    super.textStyle,
    super.textColor,
    super.fontFamily,
    super.fontSize   = 16.0,
    super.textAlign  = TextAlign.left,

    super.descriptionWidget,
    super.descriptionTextStyle,
    super.descriptionTextColor,
    super.descriptionFontFamily,
    super.descriptionFontSize = 14,
    super.descriptionTextAlign = TextAlign.left,
    super.descriptionPadding = const EdgeInsets.only(top: 2),

    super.leftIcon,
    super.leftIconKey,
    super.leftIconPadding  = const EdgeInsets.only(right: 8),
    
    super.rightIcon,
    super.rightIconKey,
    super.rightIconPadding = const EdgeInsets.only(left: 8),

    super.border,
    super.borderRadius,
    super.borderShadow,

    super.progress,
    super.progressColor,
    super.progressSize = 24,
    super.progressStrokeWidth,
    super.progressPadding = const EdgeInsets.symmetric(horizontal: 12),
    super.progressAlignment = Alignment.centerRight,
    super.progressHidesIcon = true,

    super.semanticsLabel,
    String? semanticsHint,
    super.semanticsValue,

    super.toggled = false,
    super.enabled,
    super.leftIcons,
    super.leftIconKeys,

    super.rightIcons,
    super.rightIconKeys = defaultRightIconKeys,

    super.semanticsValues,

    String? semanticsSubject,
  }) : super(
    semanticsHint: semanticsHint ?? AppSemantics.toggleHint(toggled, enabled: enabled != false, subject: semanticsSubject ?? semanticsLabel ?? title ?? ''),
  );

  static const Map<bool, String> defaultRightIconKeys = {
    true: 'toggle-on',
    false: 'toggle-off',
  };

  static Map<bool, String> _semanticsValues = {
    true: AppSemantics.toggleValue(true),
    false: AppSemantics.toggleValue(false),
  };

  @override
  Map<bool, String>? get semanticsValues => _semanticsValues;

  @override
  Widget? get disabledRightIcon {
    String? toggleOffKey = (rightIconKeys != null) ? rightIconKeys![false] : null;
    return (toggleOffKey != null) ? Styles().images.getImage(toggleOffKey,
      color: Styles().colors.fillColorPrimaryTransparent03,
      colorBlendMode: BlendMode.dstIn,
    ) : null;
  }
}

