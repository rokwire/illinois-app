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

class LinkTileWideButton extends StatelessWidget {
  final String? title;
  final Color? titleTextColor;
  final String? titleFontFamilly;
  final double titleFontSize;
  final TextStyle? titleTextStyle;
  
  final String? iconAsset;

  final Border? border;
  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? borderShadow;

  final String? hint;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final GestureTapCallback? onTap;

  LinkTileWideButton({
    this.title, 
    this.titleTextColor,
    this.titleFontFamilly,
    this.titleFontSize = 20,
    this.titleTextStyle,

    this.iconAsset,
    
    this.border,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 2.0,
    this.borderShadow,

    this.hint,
    this.margin = const EdgeInsets.all(2),
    this.padding = const EdgeInsets.symmetric(vertical:16),
    this.onTap
  });

  TextStyle get _titleTextStyle => titleTextStyle ?? TextStyle(
    color: titleTextColor ?? Styles().colors?.fillColorPrimary,
    fontFamily: titleFontFamilly ?? Styles().fontFamilies?.bold,
    fontSize: titleFontSize
  );

  Color get _borderColor => borderColor ?? Styles().colors?.white ?? const Color(0x00FFFFFF);
  BorderRadiusGeometry get _borderRadius => borderRadius ?? BorderRadius.circular(4);
  Border get _border => border ?? Border.all(color: _borderColor, width: borderWidth);
  List<BoxShadow> get _borderShadow => borderShadow ?? [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))];
  Decoration get _decoration => BoxDecoration(color: _borderColor, borderRadius: _borderRadius, border: _border, boxShadow: _borderShadow);

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];
    if (title != null) {
      contentList.add(Text(title!, textAlign: TextAlign.center, style: _titleTextStyle));
    } 
    if (iconAsset != null) {
      contentList.add(Image.asset(iconAsset!));
    }

    return GestureDetector(onTap: onTap, child:
      Semantics(label: title, hint:hint, button: true, child:
        Padding(padding: margin, child:
          Container(decoration: _decoration, child:
            Padding(padding: padding, child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, mainAxisSize: MainAxisSize.max, children: contentList,),
            ),
          ),
        ),
      ),
    );
  }
}

class LinkTileSmallButton extends StatelessWidget {
  final String? title;
  final Color? titleTextColor;
  final String? titleFontFamilly;
  final double titleFontSize;
  final TextStyle? titleTextStyle;

  final String? iconAsset;

  final Border? border;
  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? borderShadow;

  final String? hint;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double verticalSpacing;
  final GestureTapCallback? onTap;

  LinkTileSmallButton({
    this.title, 
    this.titleTextColor,
    this.titleFontFamilly,
    this.titleFontSize = 20,
    this.titleTextStyle,

    this.iconAsset, 

    this.border,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 2.0,
    this.borderShadow,

    this.hint,
    this.margin = const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    this.verticalSpacing = 26,
    this.onTap, 
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];
    if (iconAsset != null) {
      contentList.add(Image.asset(iconAsset!));
    }
    if ((title != null) && (iconAsset != null)) {
      contentList.add(Container(height: verticalSpacing));
    } 
    if (title != null) {
      contentList.add(Text(title!, textAlign: TextAlign.center, style: _titleTextStyle));
    } 

    return GestureDetector(onTap: onTap, child:
      Semantics(label: title, hint: hint, button: true, excludeSemantics: true, child:
        Padding(padding: margin, child:
          Container(decoration: _decoration, child:
            Padding(padding: padding, child:
              Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: contentList,),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle get _titleTextStyle => titleTextStyle ?? TextStyle(
    color: titleTextColor ?? Styles().colors?.fillColorPrimary,
    fontFamily: titleFontFamilly ?? Styles().fontFamilies?.bold,
    fontSize: titleFontSize
  );

  Color get _borderColor => borderColor ?? Styles().colors?.white ?? const Color(0x00FFFFFF);
  BorderRadiusGeometry get _borderRadius => borderRadius ?? BorderRadius.circular(4);
  Border get _border => border ?? Border.all(color: _borderColor, width: borderWidth);
  List<BoxShadow> get _borderShadow => borderShadow ?? [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))];
  Decoration get _decoration => BoxDecoration(color: _borderColor, borderRadius: _borderRadius, border: _border, boxShadow: _borderShadow);

}