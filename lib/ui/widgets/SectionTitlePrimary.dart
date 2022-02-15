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
  final String? subTitle;
  final String? iconPath;
  final List<Widget>? children;
  final EdgeInsetsGeometry? listPadding;
  final String slantImageRes;
  final Color? backgroundColor;
  final Color? slantColor;
  final Color? textColor;
  final String? rightIconPath;
  final String? rightIconLabel;
  final void Function()? rightIconAction;

  SectionTitlePrimary({this.title, this.subTitle, this.iconPath, this.rightIconPath, this.children, this.listPadding,
    this.slantImageRes = "", this.slantColor, this.backgroundColor, this.textColor, this.rightIconAction, this.rightIconLabel});

  @override
  Widget build(BuildContext context) {
    bool hasSubTitle = StringUtils.isNotEmpty(subTitle);
    bool useImageSlant = StringUtils.isNotEmpty(slantImageRes);
    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              color: slantColor ?? Styles().colors!.fillColorPrimary,
              height: 40,
            ),

            Visibility(visible:useImageSlant,child:Container(
              height: 112,
              width: double.infinity,
              child: Image.asset(slantImageRes, excludeFromSemantics: true, color: slantColor ?? Styles().colors!.fillColorPrimary, fit: BoxFit.fill),
              )
            ),
            Visibility(visible:!useImageSlant,child:
              Container(
               color:  slantColor ?? Styles().colors!.fillColorPrimary,
               height: 45,
              ),
            ),
            Visibility(visible:!useImageSlant,child:
              Container(
                color:  slantColor ?? Styles().colors!.fillColorPrimary,
                child:CustomPaint(
                  painter: TrianglePainter(painterColor: backgroundColor ?? Styles().colors!.background, horzDir: TriangleHorzDirection.rightToLeft),
                  child: Container(
                    height: 67,
                  ),
                ))),
          ],
        ),
        Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 16, top: 16),
              child: Row(
                children: <Widget>[
                  iconPath != null ? Padding(
                    padding: EdgeInsets.only(
                        right: 16),
                    child: Image.asset(
                        iconPath!, excludeFromSemantics: true,),
                  ) : Container(),
                  Expanded(child:
                    Semantics(label:title, header: true, excludeSemantics: true, child:
                      Text(
                        title!,
                        style: TextStyle(
                          color: textColor ?? Styles().colors!.textColorPrimary,
                          fontSize: 20),
                      )
                    )
                  ),
                  rightIconPath != null ?
                  Semantics(
                    button: true,
                    label: rightIconLabel,
                    child: GestureDetector(
                      onTap: rightIconAction,
                      child: Container(
                        padding: EdgeInsets.only(
                            left: 16, right: 16, top: 8, bottom: 2),
                        child: Image.asset(
                          rightIconPath!, excludeFromSemantics: true,),
                      ))): Container(),
                ],
              ),
            ),
            Visibility(visible: hasSubTitle,
                child: Semantics(
                  label: StringUtils.ensureNotEmpty(subTitle),
                  header: true,
                  excludeSemantics: true,
                  child: Padding(
                    padding: EdgeInsets.only(left: 50, right: 16),
                    child: Row(children: <Widget>[
                      Text(StringUtils.ensureNotEmpty(subTitle),
                        style: TextStyle(fontSize: 16,
                            color: Colors.white,
                            fontFamily: Styles().fontFamilies!.regular),),
                      Expanded(child: Container(),)
                    ],),),)),
            Padding(
              padding: listPadding ?? EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: children!,
              ),
            )
          ],
        )
      ],
    );
  }
}