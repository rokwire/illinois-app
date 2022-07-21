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
import 'package:illinois/service/Canvas.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCourseCard extends StatefulWidget {
  final CanvasCourse course;
  final bool isSmall;

  CanvasCourseCard({required this.course, this.isSmall = false});

  @override
  State<CanvasCourseCard> createState() => _CanvasCourseCardState();

  static double height(BuildContext context, { bool isSmall = false }) =>
    MediaQuery.of(context).textScaleFactor * (isSmall ? 130 : 86);
}

class _CanvasCourseCardState extends State<CanvasCourseCard> {
  double? _currentScore;
  bool _scoreLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCourseScore();
  }

  void _loadCourseScore() {
    _setScoreLoading(true);
    Canvas().loadCourseGradeScore(widget.course.id!).then((score) {
      _currentScore = score;
      _setScoreLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color defaultColor = Colors.black;
    final double cardHeight = CanvasCourseCard.height(context, isSmall: widget.isSmall);
    final double cardInnerPadding = 10;
    const double borderRadiusValue = 6;
    return Container(
        height: cardHeight,
        decoration: BoxDecoration(
            borderRadius: (widget.isSmall ? BorderRadius.circular(borderRadiusValue) : null),
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))]),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Column(children: [
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        color: defaultColor,
                        borderRadius: (widget.isSmall ? BorderRadius.horizontal(left: Radius.circular(borderRadiusValue)) : null)),
                    child: Center(
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: cardInnerPadding),
                            child: Container(
                                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Styles().colors!.white),
                                child: _buildGradeScoreWidget(courseColor: defaultColor))))))
          ]),
          Expanded(
              child: Column(children: [
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        color: Styles().colors!.white,
                        borderRadius: (widget.isSmall ? BorderRadius.horizontal(right: Radius.circular(borderRadiusValue)) : null)),
                    child: Padding(
                        padding: EdgeInsets.all(cardInnerPadding),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          Expanded(
                              child: Text(StringUtils.ensureNotEmpty(widget.course.name),
                                  maxLines: (widget.isSmall ? 5 : 3),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: defaultColor, fontSize: 18, fontFamily: Styles().fontFamilies!.extraBold)))
                        ]))))
          ]))
        ]));
  }

  Widget _buildGradeScoreWidget({required Color courseColor}) {
    if (_scoreLoading) {
      double indicatorSize = 22;
      return SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: Padding(padding: EdgeInsets.all(5), child: CircularProgressIndicator(strokeWidth: 1, color: courseColor)));
    } else {
      return Text(_formattedGradeScore, style: TextStyle(color: courseColor, fontSize: 16, fontFamily: Styles().fontFamilies!.bold));
    }
  }

  String get _formattedGradeScore {
    if (_currentScore == null) {
      return 'N/A';
    }
    NumberFormat numFormatter = NumberFormat();
    numFormatter.minimumFractionDigits = 0;
    numFormatter.maximumFractionDigits = 2;
    return numFormatter.format(_currentScore) + '%';
  }

  void _setScoreLoading(bool loading) {
    _scoreLoading = loading;
    if (mounted) {
      setState(() {});
    }
  }
}
