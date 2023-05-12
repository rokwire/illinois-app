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
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class SmallRoundedButton extends RoundedButton {
  SmallRoundedButton({
    required String label,
    required void Function() onTap,
    Color? backgroundColor               = Colors.transparent,
    EdgeInsetsGeometry padding           = const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
  
    double contentWeight                 = 0.0,
    MainAxisAlignment conentAlignment    = MainAxisAlignment.center,

    TextStyle? textStyle,
    Color? textColor,
    String? fontFamily,
    double? fontSize,
    TextAlign? textAlign,

    Widget? leftIcon,
    EdgeInsetsGeometry? leftIconPadding  = const EdgeInsets.only(right: 15),
  
    Widget? rightIcon,
    EdgeInsetsGeometry? rightIconPadding = const EdgeInsets.only(right: 15),

    double iconPadding                   = 8,

    String? hint,
    bool enabled                         = true,

    Border? border,
    Color? borderColor,
    double borderWidth                   = 2.0,
    List<BoxShadow>? borderShadow,
    double? maxBorderRadius = 24.0,

    Border? secondaryBorder,
    Color? secondaryBorderColor,
    double? secondaryBorderWidth,

    bool? progress,
    Color? progressColor,
    double? progressSize,
    double? progressStrokeWidth,

  }) : super(
    label: label,
    onTap: onTap,
    backgroundColor: backgroundColor,
    padding: padding,

    contentWeight: contentWeight,
    conentAlignment: conentAlignment,
  
    textStyle : textStyle,
    textColor : textColor,
    fontFamily : fontFamily,
    fontSize: fontSize ?? 16,
    textAlign: textAlign ?? TextAlign.left,

    leftIcon: leftIcon,
    leftIconPadding: leftIconPadding,
  
    rightIcon: rightIcon ?? Styles().images?.getImage('chevron-right-bold', excludeFromSemantics: true),
    rightIconPadding: rightIconPadding,

    iconPadding: iconPadding,

    hint: hint,
    enabled: enabled,

    border: border,
    borderColor: borderColor,
    borderWidth: borderWidth,
    borderShadow: borderShadow,
    maxBorderRadius: maxBorderRadius,

    secondaryBorder: secondaryBorder,
    secondaryBorderColor: secondaryBorderColor,
    secondaryBorderWidth: secondaryBorderWidth,

    progress: progress,
    progressColor: progressColor,
    progressSize: progressSize,
    progressStrokeWidth: progressStrokeWidth,
  );

}
