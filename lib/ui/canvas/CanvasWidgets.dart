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
import 'package:illinois/model/Canvas.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCourseCard extends StatelessWidget {
  final CanvasCourse course;
  final bool isSmall;

  CanvasCourseCard({required this.course, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    final Color defaultColor = Colors.black;
    final double cardHeight = (MediaQuery.of(context).textScaleFactor * 130);
    double cardInnerPadding = 10;
    final double? cardWidth = isSmall ? (MediaQuery.of(context).textScaleFactor * 200) : null;
    const double borderRadiusValue = 6;
    Color? mainColor = StringUtils.isNotEmpty(course.courseColor) ? UiColors.fromHex(course.courseColor!) : defaultColor;
    if (mainColor == null) {
      mainColor = defaultColor;
    }
    return Container(
        height: (isSmall ? cardHeight : null),
        width: cardWidth,
        decoration: BoxDecoration(
            borderRadius: (isSmall ? BorderRadius.circular(borderRadiusValue) : null),
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              height: (cardHeight / 2),
              decoration: BoxDecoration(
                  color: mainColor, borderRadius: (isSmall ? BorderRadius.vertical(top: Radius.circular(borderRadiusValue)) : null))),
          Container(
              decoration: BoxDecoration(
                  color: Styles().colors!.white,
                  borderRadius: (isSmall ? BorderRadius.vertical(bottom: Radius.circular(borderRadiusValue)) : null)),
              child: Padding(
                  padding: EdgeInsets.all(cardInnerPadding),
                  child: Row(children: [
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(StringUtils.ensureNotEmpty(course.name),
                          maxLines: (isSmall ? 2 : 5),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: mainColor, fontSize: 18, fontFamily: Styles().fontFamilies!.extraBold))
                    ]))
                  ])))
        ]));
  }
}
