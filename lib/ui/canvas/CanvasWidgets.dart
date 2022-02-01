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
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCourseCard extends StatelessWidget {
  final CanvasCourse course;
  final bool isSmall;

  CanvasCourseCard({required this.course, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    final Color defaultColor = Colors.black;
    const double cardHeight = 166;
    double cardInnerPadding = 10;
    final double? cardWidth = isSmall ? 200 : null;
    const double borderRadiusValue = 6;
    //TBD: check from which field to take this value
    String completionPercentage = _formatDecimalValue(0);
    Color? mainColor = StringUtils.isNotEmpty(course.courseColor) ? UiColors.fromHex(course.courseColor!) : defaultColor;
    if (mainColor == null) {
      mainColor = defaultColor;
    }
    return Container(
        height: cardHeight,
        width: cardWidth,
        decoration: BoxDecoration(
          borderRadius: (isSmall ? BorderRadius.circular(borderRadiusValue) : null),
          boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Container(decoration: BoxDecoration(color: mainColor, borderRadius: (isSmall ? BorderRadius.vertical(top: Radius.circular(borderRadiusValue)) : null)), child: Padding(
                  padding: EdgeInsets.only(left: cardInnerPadding, top: cardInnerPadding),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Styles().colors!.white),
                        child:
                        Text('$completionPercentage%', style: TextStyle(color: mainColor, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)))
                  ])))),
          Expanded(
              child: Container(decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: (isSmall ? BorderRadius.vertical(bottom: Radius.circular(borderRadiusValue)) : null)), child: Padding(
                  padding: EdgeInsets.all(cardInnerPadding),
                  child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(StringUtils.ensureNotEmpty(course.name),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: mainColor, fontSize: 18, fontFamily: Styles().fontFamilies!.extraBold)),
                    Text(StringUtils.ensureNotEmpty(course.courseCode),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Styles().colors!.textSurface, fontSize: 16, fontFamily: Styles().fontFamilies!.bold))
                  ]))]))))
        ]));
  }

  String _formatDecimalValue(double num, {int minimumFractionDigits = 0, int maximumFractionDigits = 2}) {
    NumberFormat numFormatter = NumberFormat();
    numFormatter.minimumFractionDigits = minimumFractionDigits;
    numFormatter.maximumFractionDigits = maximumFractionDigits;
    return numFormatter.format(num);
  }
}
