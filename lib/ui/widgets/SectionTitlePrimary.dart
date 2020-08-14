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
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class SectionTitlePrimary extends StatelessWidget{
  final String title;
  final String subTitle;
  final String iconPath;
  final List<Widget> children;
  final String slantImageRes;
  final Color backgroundColor;
  final Color slantColor;
  final Color textColor;

  SectionTitlePrimary({this.title, this.subTitle, this.iconPath, this.children,
    this.slantImageRes = "", this.slantColor, this.backgroundColor, this.textColor});

  @override
  Widget build(BuildContext context) {
    bool hasSubTitle = AppString.isStringNotEmpty(subTitle);
    bool useImageSlant = AppString.isStringNotEmpty(slantImageRes);
    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              color: slantColor ?? Styles().colors.fillColorPrimary,
              height: 40,
            ),

            Visibility(visible:useImageSlant,child:Container(
              height: 112,
              width: double.infinity,
              child: Image.asset(slantImageRes, color: slantColor ?? Styles().colors.fillColorPrimary, fit: BoxFit.fill),
              )
            ),
            Visibility(visible:!useImageSlant,child:
              Container(
               color:  slantColor ?? Styles().colors.fillColorPrimary,
               height: 45,
              ),
            ),
            Visibility(visible:!useImageSlant,child:
              Container(
                color:  slantColor ?? Styles().colors.fillColorPrimary,
                child:CustomPaint(
                  painter: TrianglePainter(painterColor: backgroundColor ?? Styles().colors.background, left : true),
                  child: Container(
                    height: 67,
                  ),
                ))),
          ],
        ),
        Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 2),
              child: Semantics(label:title, header: true, excludeSemantics: true, child:Row(
                children: <Widget>[
                  iconPath != null ? Padding(
                    padding: EdgeInsets.only(
                        right: 16),
                    child: Image.asset(
                        iconPath),
                  ) : Container(),
                  Text(
                    title,
                    style: TextStyle(
                        color: textColor ?? Styles().colors.textColorPrimary,
                        fontSize: 20),
                  ),
                ],
              )),
            ),
            Visibility(visible: hasSubTitle,
                child: Semantics(
                  label: AppString.getDefaultEmptyString(value: subTitle),
                  header: true,
                  excludeSemantics: true,
                  child: Padding(
                    padding: EdgeInsets.only(left: 50, right: 16),
                    child: Row(children: <Widget>[
                      Text(AppString.getDefaultEmptyString(value: subTitle),
                        style: TextStyle(fontSize: 16,
                            color: Colors.white,
                            fontFamily: Styles().fontFamilies.regular),),
                      Expanded(child: Container(),)
                    ],),),)),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: children,
              ),
            )
          ],
        )
      ],
    );
  }
}