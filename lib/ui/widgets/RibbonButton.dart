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
  void Function()? onTap,
  Color? backgroundColor,
  EdgeInsetsGeometry padding          = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

  Widget? textWidget,
  TextStyle? textStyle,
  Color? textColor,
  String? fontFamily,
  double fontSize                     = 16.0,
  TextAlign textAlign                 = TextAlign.left,

  Widget? leftIcon,
  String? leftIconAsset,
  EdgeInsetsGeometry leftIconPadding  = const EdgeInsets.only(right: 8),
  
  Widget? rightIcon,
  String? rightIconAsset              = 'images/chevron-right.png',
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
    onTap: onTap,
    backgroundColor: backgroundColor,
    padding: padding,

    textWidget: textWidget,
    textStyle: textStyle,
    textColor: textColor,
    fontFamily: fontFamily,
    fontSize: fontSize,
    textAlign: textAlign,

    leftIcon: leftIcon,
    leftIconAsset: leftIconAsset,
    leftIconPadding: leftIconPadding,
    
    rightIcon: rightIcon,
    rightIconAsset: rightIconAsset,
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

  static const Map<bool, String> _rightIconAssets = {
    true: 'images/switch-on.png',
    false: 'images/switch-off.png',
  };

  final Map<bool, String> _semanticsValues = {
    true: Localization().getStringEx("toggle_button.status.checked", "checked",),
    false: Localization().getStringEx("toggle_button.status.unchecked", "unchecked"),
  };

  ToggleRibbonButton({
    Key? key,
    String? label,
    void Function()? onTap,
    Color? backgroundColor,
    EdgeInsetsGeometry padding          = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

    Widget? textWidget,
    TextStyle? textStyle,
    Color? textColor,
    String? fontFamily,
    double fontSize                     = 16.0,
    TextAlign textAlign                 = TextAlign.left,

    Widget? leftIcon,
    String? leftIconAsset,
    EdgeInsetsGeometry leftIconPadding  = const EdgeInsets.only(right: 8),
    
    Widget? rightIcon,
    String? rightIconAsset,
    EdgeInsetsGeometry rightIconPadding = const EdgeInsets.only(left: 8),

    BoxBorder? border,
    BorderRadius? borderRadius,
    List<BoxShadow>? borderShadow,

    String? hint,
    String? semanticsValue,

    bool toggled = false,
    Map<bool, Widget>? leftIcons,
    Map<bool, String>? leftIconAssets,

    Map<bool, Widget>? rightIcons,
    Map<bool, String>? rightIconAssets = _rightIconAssets,

    Map<bool, String>? semanticsValues,
  }) : super(
    key: key,
    label: label,
    onTap: onTap,
    backgroundColor: backgroundColor,
    padding: padding,

    textWidget: textWidget,
    textStyle: textStyle,
    textColor: textColor,
    fontFamily: fontFamily,
    fontSize: fontSize,
    textAlign: textAlign,

    leftIcon: leftIcon,
    leftIconAsset: leftIconAsset,
    leftIconPadding: leftIconPadding,
    
    rightIcon: rightIcon,
    rightIconAsset: rightIconAsset,
    rightIconPadding: rightIconPadding,

    border: border,
    borderRadius: borderRadius,
    borderShadow: borderShadow,

    hint: hint,
    semanticsValue: semanticsValue,

    toggled: toggled,
    leftIcons: leftIcons,
    leftIconAssets: leftIconAssets,

    rightIcons: rightIcons,
    rightIconAssets: rightIconAssets,

    semanticsValues : semanticsValues,
  );

  @override
  Map<bool, String>? get semanticsValues => _semanticsValues;

}

