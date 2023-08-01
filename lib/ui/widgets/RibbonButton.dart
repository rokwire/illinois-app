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
import 'package:rokwire_plugin/ui/widgets/ribbon_button.dart' as rokwire;

class RibbonButton extends rokwire.RibbonButton {
  RibbonButton({
  Key? key,
  String? label,
  String? description,
  void Function()? onTap,
  Color? backgroundColor,
  EdgeInsetsGeometry? padding,

  Widget? textWidget,
  TextStyle? textStyle,
  Color? textColor,
  String? fontFamily,
  double fontSize                     = 16.0,
  TextAlign textAlign                 = TextAlign.left,

  Widget? descriptionWidget,
  TextStyle? descriptionTextStyle,
  Color? descriptionTextColor,
  String? descriptionFontFamily,
  double descriptionFontSize = 14,
  TextAlign descriptionTextAlign = TextAlign.left,
  EdgeInsetsGeometry descriptionPadding = const EdgeInsets.only(top: 2),

  Widget? leftIcon,
  String? leftIconKey,
  EdgeInsetsGeometry leftIconPadding  = const EdgeInsets.only(right: 8),
  
  Widget? rightIcon,
  String? rightIconKey              = 'chevron-right-bold',
  EdgeInsetsGeometry rightIconPadding = const EdgeInsets.only(left: 8),

  BoxBorder? border,
  BorderRadius? borderRadius,
  List<BoxShadow>? borderShadow,

  bool? progress,
  Color? progressColor,
  double? progressSize,
  double? progressStrokeWidth,
  EdgeInsetsGeometry progressPadding  = const EdgeInsets.symmetric(horizontal: 12),
  AlignmentGeometry progressAlignment = Alignment.centerRight,
  bool progressHidesIcon              = true,

  String? hint,
  String? semanticsValue,
  }): super(
    key: key,
    label: label,
    description: description,
    onTap: onTap,
    backgroundColor: backgroundColor,
    padding: padding,

    textWidget: textWidget,
    textStyle: textStyle,
    textColor: textColor,
    fontFamily: fontFamily,
    fontSize: fontSize,
    textAlign: textAlign,

    descriptionWidget: descriptionWidget,
    descriptionTextStyle: descriptionTextStyle,
    descriptionTextColor: descriptionTextColor,
    descriptionFontFamily: descriptionFontFamily,
    descriptionFontSize: descriptionFontSize,
    descriptionTextAlign: descriptionTextAlign,
    descriptionPadding: descriptionPadding,

    leftIcon: leftIcon,
    leftIconKey: leftIconKey,
    leftIconPadding: leftIconPadding,
    
    rightIcon: rightIcon,
    rightIconKey: rightIconKey,
    rightIconPadding: rightIconPadding,

    border: border,
    borderRadius: borderRadius,
    borderShadow: borderShadow,

    progress: progress,
    progressColor: progressColor,
    progressSize: progressSize,
    progressStrokeWidth: progressStrokeWidth,
    progressPadding: progressPadding,
    progressAlignment: progressAlignment,
    progressHidesIcon: progressHidesIcon,

    hint: hint,
    semanticsValue: semanticsValue,
  );
}

class ToggleRibbonButton extends rokwire.ToggleRibbonButton {

  static const Map<bool, String> _rightIconKeys = {
    true: 'toggle-on',
    false: 'toggle-off',
  };

  final Map<bool, String> _semanticsValues = {
    true: Localization().getStringEx("toggle_button.status.checked", "checked",),
    false: Localization().getStringEx("toggle_button.status.unchecked", "unchecked"),
  };

  ToggleRibbonButton({
    Key? key,
    String? label,
    String? description,
    void Function()? onTap,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,

    Widget? textWidget,
    TextStyle? textStyle,
    Color? textColor,
    String? fontFamily,
    double fontSize                     = 16.0,
    TextAlign textAlign                 = TextAlign.left,

    Widget? descriptionWidget,
    TextStyle? descriptionTextStyle,
    Color? descriptionTextColor,
    String? descriptionFontFamily,
    double descriptionFontSize = 14,
    TextAlign descriptionTextAlign = TextAlign.left,
    EdgeInsetsGeometry descriptionPadding = const EdgeInsets.only(top: 2),

    Widget? leftIcon,
    String? leftIconKey,
    EdgeInsetsGeometry leftIconPadding  = const EdgeInsets.only(right: 8),
    
    Widget? rightIcon,
    String? rightIconKey,
    EdgeInsetsGeometry rightIconPadding = const EdgeInsets.only(left: 8),

    BoxBorder? border,
    BorderRadius? borderRadius,
    List<BoxShadow>? borderShadow,

    String? hint,
    String? semanticsValue,

    bool toggled = false,
    Map<bool, Widget>? leftIcons,
    Map<bool, String>? leftIconKeys,

    Map<bool, Widget>? rightIcons,
    Map<bool, String>? rightIconKeys = _rightIconKeys,

    Map<bool, String>? semanticsValues,

    bool? progress,
    Color? progressColor,
    double? progressSize = 24,
    double? progressStrokeWidth,
    EdgeInsetsGeometry progressPadding = const EdgeInsets.symmetric(horizontal: 12),
    AlignmentGeometry progressAlignment = Alignment.centerRight,
    bool progressHidesIcon = true,

  }) : super(
    key: key,
    label: label,
    description: description,
    onTap: onTap,
    backgroundColor: backgroundColor,
    padding: padding,

    textWidget: textWidget,
    textStyle: textStyle,
    textColor: textColor,
    fontFamily: fontFamily,
    fontSize: fontSize,
    textAlign: textAlign,

    descriptionWidget: descriptionWidget,
    descriptionTextStyle: descriptionTextStyle,
    descriptionTextColor: descriptionTextColor,
    descriptionFontFamily: descriptionFontFamily,
    descriptionFontSize: descriptionFontSize,
    descriptionTextAlign: descriptionTextAlign,
    descriptionPadding: descriptionPadding,

    leftIcon: leftIcon,
    leftIconKey: leftIconKey,
    leftIconPadding: leftIconPadding,
    
    rightIcon: rightIcon,
    rightIconKey: rightIconKey,
    rightIconPadding: rightIconPadding,

    border: border,
    borderRadius: borderRadius,
    borderShadow: borderShadow,

    hint: hint,
    semanticsValue: semanticsValue,

    toggled: toggled,
    leftIcons: leftIcons,
    leftIconKeys: leftIconKeys,

    rightIcons: rightIcons,
    rightIconKeys: rightIconKeys,

    semanticsValues : semanticsValues,

    progress: progress,
    progressColor: progressColor,
    progressSize: progressSize,
    progressStrokeWidth: progressStrokeWidth,
    progressPadding: progressPadding,
    progressAlignment: progressAlignment,
    progressHidesIcon: progressHidesIcon,
  );

  @override
  Map<bool, String>? get semanticsValues => _semanticsValues;

}

