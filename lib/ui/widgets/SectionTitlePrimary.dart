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
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class SectionTitlePrimary extends StatelessWidget{
  final String? title;
  final Color? titleTextColor;
  final String? titleFontFamilly;
  final double titleFontSize;
  final TextStyle? titleTextStyle;
  final EdgeInsetsGeometry titlePadding;
  
  final String? subTitle;
  final Color? subTitleTextColor;
  final String? subTitleFontFamilly;
  final double subTitleFontSize;
  final TextStyle? subTitleTextStyle;
  final EdgeInsetsGeometry subTitlePadding;
  
  final String? titleIconAsset;
  final EdgeInsetsGeometry titleIconPadding;

  final Color? backgroundColor;

  final Color? slantColor;
  final double slantPainterHeadingHeight;
  final double slantPainterHeight;

  final String? slantImageAsset;
  final double slantImageHeadingHeight;
  final double slantImageHeight;

  final String? rightIconLabel;
  final String? rightIconAsset;
  final void Function()? rightIconAction;
  final EdgeInsetsGeometry rightIconPadding;

  final List<Widget>? children;
  final EdgeInsetsGeometry childrenPadding;

  SectionTitlePrimary({
    Key? key,

    this.title,
    this.titleTextColor,
    this.titleFontFamilly,
    this.titleFontSize = 20,
    this.titleTextStyle,
    this.titlePadding = const EdgeInsets.only(left: 16, top: 16),

    this.subTitle,
    this.subTitleTextColor,
    this.subTitleFontFamilly,
    this.subTitleFontSize = 16,
    this.subTitleTextStyle,
    this.subTitlePadding = const EdgeInsets.only(left: 50, right: 16),

    this.titleIconAsset,
    this.titleIconPadding = const EdgeInsets.only(right: 16),

    this.backgroundColor, 
    
    this.slantColor,
    this.slantPainterHeadingHeight = 85,
    this.slantPainterHeight = 67,
    
    this.slantImageAsset,
    this.slantImageHeadingHeight = 40,
    this.slantImageHeight = 112,
    
    this.rightIconLabel,
    this.rightIconAsset,
    this.rightIconAction,
    this.rightIconPadding = const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 2),
    
    this.children,
    this.childrenPadding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    // Build Stack layer 1
    List<Widget> layer1List = <Widget>[];
    if (StringUtils.isNotEmpty(slantImageAsset)) {
      layer1List.addAll([
        Container(color: _slantColor, height: slantImageHeadingHeight,),
        Row(children:[Expanded(child:
          Container(height: slantImageHeight, child:
            Image.asset(slantImageAsset!, excludeFromSemantics: true, color: _slantColor, fit: BoxFit.fill),
          ),
        )]),
      ]);
    }
    else {
      layer1List.addAll([
        Container(color: _slantColor, height: slantPainterHeadingHeight,),
        Container(color: _slantColor, child:
          CustomPaint(painter: TrianglePainter(painterColor: backgroundColor ?? Styles().colors!.background, horzDir: TriangleHorzDirection.rightToLeft), child:
            Container(height: slantPainterHeight,),
          ),
        ),
      ]);
    }

    // Build Title Row
    List<Widget> titleList = <Widget>[];
    if (titleIconAsset != null) {
      titleList.add(
        Padding(padding: titleIconPadding, child:
          Image.asset(titleIconAsset!, excludeFromSemantics: true,),
        )
      );
    }
    
    titleList.add(
      Expanded(child:
        Semantics(label: title, header: true, excludeSemantics: true, child:
          Text(title ?? '', style: _titleTextStyle,)
        )
      ),
    );
    
    if (rightIconAsset != null) {
      titleList.add(
        Semantics(label: rightIconLabel, button: true, child:
          GestureDetector(onTap: rightIconAction, child:
            Container(padding: rightIconPadding, child:
              Image.asset(rightIconAsset!, excludeFromSemantics: true,),
            )
          )
        ),
      );
    }

    // Build Stack layer 2
    List<Widget> layer2List = <Widget>[
      Padding(padding: titlePadding, child:
        Row(children: titleList,),
      ),
    ];

    if (StringUtils.isNotEmpty(subTitle)) {
      layer2List.add(
        Semantics(label: subTitle, header: true, excludeSemantics: true, child:
          Padding(padding: subTitlePadding, child:
            Row(children: <Widget>[
              Expanded(child:
                Text(subTitle ?? '', style: _subTitleTextStyle,),
              ),
            ],),
          ),
        ),
      );
    }

    layer2List.add(
      Padding(padding: childrenPadding, child:
        Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: children ?? [],),
      )
    );

    return Stack(alignment: Alignment.topCenter, children: <Widget>[
      Column(children: layer1List,),
      Column(children: layer2List,),
    ],);

    
  }

  Color? get _slantColor => slantColor ?? Styles().colors?.fillColorPrimary;

  TextStyle get _titleTextStyle => titleTextStyle ?? TextStyle(
    color: titleTextColor ?? Styles().colors?.textColorPrimary,
    fontFamily: titleFontFamilly ?? Styles().fontFamilies?.extraBold,
    fontSize: titleFontSize
  );

  TextStyle get _subTitleTextStyle => subTitleTextStyle ?? TextStyle(
    color: subTitleTextColor ?? Styles().colors?.textColorPrimary,
    fontFamily: subTitleFontFamilly ?? Styles().fontFamilies?.regular,
    fontSize: subTitleFontSize
  );
}