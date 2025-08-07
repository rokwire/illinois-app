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
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCourseCard extends StatefulWidget {
  final CanvasCourse course;
  final bool small;
  final bool embedded;

  CanvasCourseCard({required this.course, this.small = false, this.embedded = false});

  @override
  State<CanvasCourseCard> createState() => _CanvasCourseCardState();

  static double height(BuildContext context, {bool isSmall = false}) => MediaQuery.of(context).textScaler.scale(isSmall ? 65 : 92);
}

class _CanvasCourseCardState extends State<CanvasCourseCard> {

  @override
  Widget build(BuildContext context) {
    final double cardHeight = CanvasCourseCard.height(context, isSmall: widget.small);
    final double cardHorizontalPadding = 16;
    return Container(
        height: cardHeight,
        decoration: widget.embedded ? _embeddedDecoration : _defaultDecoration,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: cardHorizontalPadding, vertical: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(
                        child: Text(StringUtils.ensureNotEmpty(widget.course.name),
                            maxLines: (widget.small ? 2 : 3),
                            overflow: TextOverflow.ellipsis,
                            style: Styles().textStyles.getTextStyle('widget.canvas.card.title.regular')))
                  ]))),
          Visibility(visible: !widget.embedded, child: Padding(
              padding: EdgeInsets.only(right: cardHorizontalPadding),
              child: Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true)))
        ]));
  }

  BoxDecoration get _embeddedDecoration => BoxDecoration(
    color: Styles().colors.white,
  );

  BoxDecoration get _defaultDecoration =>
      HomeCard.boxDecoration;
  /*BoxDecoration(
    color: Styles().colors.white,
    borderRadius: BorderRadius.all(Radius.circular(10)),
    boxShadow: [BoxShadow(
      color: Styles().colors.blackTransparent018,
      spreadRadius: 1.0,
      blurRadius: 3.0,
      offset: Offset(0, 0)
    )]
  )*/
}
