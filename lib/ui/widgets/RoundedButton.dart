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
import 'package:illinois/service/Styles.dart';

class RoundedButton extends StatelessWidget {
  final String? label;
  final String? hint;
  final Color? backgroundColor;
  final Function? onTap;
  final Color? textColor;
  final TextAlign textAlign;
  final String? fontFamily;
  final double fontSize;
  final TextStyle? textStyle;
  final Color? borderColor;
  final double borderWidth;
  final Color? secondaryBorderColor;
  final List<BoxShadow>? shadow;
  final EdgeInsetsGeometry padding;
  final bool enabled;
  final double height;
  final double? width;
  final Image? leftIcon;
  final Image? rightIcon;

  RoundedButton(
      {this.label = '',
      this.hint = '',
      this.backgroundColor,
      this.textColor = Colors.white,
      this.textAlign = TextAlign.center,
      this.fontFamily,
      this.fontSize = 20.0,
      this.textStyle,
      this.padding = const EdgeInsets.all(0),
      this.enabled = true,
      this.borderColor,
      this.borderWidth = 2.0,
      this.secondaryBorderColor,
      this.onTap,
      this.height = 48,
      this.width,
      this.leftIcon,
      this.rightIcon,
      this.shadow});

  @override
  Widget build(BuildContext context) {
    return Semantics(
        label: label,
        hint: hint,
        button: true,
//        excludeSemantics: true,
        enabled: enabled,
        child: InkWell(
          onTap: onTap as void Function()?,
          child: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: (backgroundColor ?? Styles().colors!.fillColorPrimary),
              border: Border.all(
                  color: (borderColor != null) ? borderColor! : (backgroundColor ?? Styles().colors!.fillColorPrimary!),
                  width: borderWidth),
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: this.shadow
            ),
            child: Container(
              height: (height - 2),
              decoration: BoxDecoration(
                  color: (backgroundColor ?? Styles().colors!.fillColorPrimary),
                  border: Border.all(
                      color: (secondaryBorderColor != null)
                          ? secondaryBorderColor!
                          : (backgroundColor ?? Styles().colors!.fillColorPrimary!),
                      width: borderWidth),
                  borderRadius: BorderRadius.circular(height / 2)),
              child: Padding(
                  padding: padding,
                  child: Semantics( excludeSemantics: true,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                    (leftIcon != null) ? Padding(padding: EdgeInsets.only(right: 5), child: leftIcon,) : Container(height: 0, width: 0),
                    Text(label!, textAlign: textAlign,
                      style: textStyle ?? TextStyle(
                        fontFamily: fontFamily ?? Styles().fontFamilies!.bold,
                        fontSize: fontSize,
                        color: textColor,
                      ),
                    ),
                    (rightIcon != null) ?  Padding(padding: EdgeInsets.only(left: 5), child: rightIcon,) : Container(height: 0, width: 0),
                    /*Visibility(visible: showAdd, child:
                      Padding(padding: EdgeInsets.only(left: 5), child:
                        Image.asset('images/icon-add-20x18.png'),
                    )),*/
                  ],))),
            ),
          ),
        ));
  }
}

class SmallRoundedButton extends StatelessWidget {
  final String? label;
  final String? hint;
  final GestureTapCallback? onTap;
  final bool showChevron;
  final Color? borderColor;

  SmallRoundedButton({required this.label, this.hint = '', this.onTap, this.showChevron = true, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: Semantics(
          label: label,
          hint: hint,
          button: true,
          excludeSemantics: true,
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor ?? Styles().colors!.fillColorSecondary!, width: 2.0),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label!,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies!.bold,
                        fontSize: 16,
                        color: Styles().colors!.fillColorPrimary),
                  ),
                  Visibility(
                      visible: showChevron,
                      child: Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Image.asset('images/chevron-right.png'),
                      ))
                ],
              ),
            ),
          ),
        ));
  }
}