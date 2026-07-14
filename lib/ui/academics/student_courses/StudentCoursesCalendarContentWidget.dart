/*
 * Copyright 2026 Board of Trustees of the University of Illinois.
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

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/StudentCourse.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/academics/student_courses/StudentCourseDetailPanel.dart';
import 'package:illinois/ui/academics/student_courses/StudentCoursesCalendarLayout.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:timezone/timezone.dart';

class StudentCoursesCalendarContentWidget extends StatefulWidget {
  final List<StudentCourse>? courses;
  final AnalyticsFeature? analyticsFeature;

  StudentCoursesCalendarContentWidget({super.key, this.courses, this.analyticsFeature});

  @override
  State<StudentCoursesCalendarContentWidget> createState() => _StudentCoursesCalendarContentWidgetState();
}

class _StudentCoursesCalendarContentWidgetState extends State<StudentCoursesCalendarContentWidget> {

  static const double _minHourHeight = 40;
  static const double _timeColumnWidth = 64;
  static const int _initialVisibleHour = 7;

  static const double _dayHeaderRowHeight = 44;
  static const double _dayHeaderDividerHeight = 8;
  static const double _gridTopGap = 20;
  static const double _hourLabelRightMargin = 24;
  static const double _hourLineLength = 20;
  static const double _hourLineRightOvershoot = 4;
  static const double _closingRowHeight = 20;

  static const List<int> _weekdayOrder = <int>[
    DateTime.sunday, DateTime.monday, DateTime.tuesday, DateTime.wednesday,
    DateTime.thursday, DateTime.friday, DateTime.saturday,
  ];

  late final ScrollController _scrollController;

  double _hourHeight = _minHourHeight;
  bool _initialScrollApplied = false;

  late final List<Color> _coursePalette;
  Map<String, Color> _courseColors = <String, Color>{};

  Map<int, List<StudentCourseBlock>> _blocksByWeekday = <int, List<StudentCourseBlock>>{};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _coursePalette = StudentCoursesCalendarLayout.defaultPalette;
    _updateCourseColors();
    _updateBlocksByWeekday();
  }

  @override
  void didUpdateWidget(StudentCoursesCalendarContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.courses, oldWidget.courses)) {
      _updateCourseColors();
      _updateBlocksByWeekday();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _applyInitialScrollOffsetIfNeeded() {
    if (!_initialScrollApplied && _scrollController.hasClients) {
      _initialScrollApplied = true;
      _scrollController.jumpTo(_gridTopGap + (_initialVisibleHour * _hourHeight));
    }
  }

  @override
  Widget build(BuildContext context) {
    TZDateTime now = DateTimeUni.nowUniOrLocal();

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      double dayColumnWidth = (constraints.maxWidth - _timeColumnWidth) / _weekdayOrder.length;
      _hourHeight = math.max(dayColumnWidth, _minHourHeight);
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialScrollOffsetIfNeeded());

      return Stack(children: <Widget>[
        Column(children: <Widget>[
          SizedBox(height: _dayHeaderRowHeight),
          Expanded(child:
            SingleChildScrollView(controller: _scrollController, child:
              Padding(padding: EdgeInsets.only(top: _gridTopGap), child:
                SizedBox(height: (24 * _hourHeight) + _closingRowHeight, child:
                  Stack(clipBehavior: Clip.none, children: <Widget>[
                    Positioned(top: 0, left: 0, right: 0, height: 24 * _hourHeight, child:
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        _buildTimeColumn(),
                        ..._weekdayOrder.map((int weekday) => Expanded(child:
                          _buildDayColumn(blocks: _blocksByWeekday[weekday] ?? <StudentCourseBlock>[]),
                        )),
                      ]),
                    ),
                    Positioned(top: 24 * _hourHeight, left: 0, right: 0, child: _buildClosingHourRow()),
                    _buildNowLine(nowMinutes: (now.hour * 60) + now.minute, todayWeekday: now.weekday),
                  ]),
                ),
              ),
            ),
          ),
        ]),
        Positioned(top: 0, left: 0, right: 0, child: _buildDayHeaderRow(todayWeekday: now.weekday)),
      ]);
    });
  }

  // Data prep

  void _updateBlocksByWeekday() {
    Map<int, List<StudentCourseBlock>> blocksByWeekday = <int, List<StudentCourseBlock>>{};
    for (StudentCourse course in widget.courses ?? <StudentCourse>[]) {
      int? startMinutes = course.section?.startTimeMinutes;
      if (startMinutes != null) {
        for (int weekday in course.section?.weekdays ?? <int>[]) {
          blocksByWeekday.putIfAbsent(weekday, () => <StudentCourseBlock>[]).add(
            StudentCourseBlock(course: course, startMinutes: startMinutes, durationMinutes: StudentCoursesCalendarLayout.fixedDurationMinutes)
          );
        }
      }
    }
    blocksByWeekday.forEach((_, List<StudentCourseBlock> blocks) => StudentCoursesCalendarLayout.layoutOverlappingBlocks(blocks));
    _blocksByWeekday = blocksByWeekday;
  }

  void _updateCourseColors() {
    _courseColors = StudentCoursesCalendarLayout.computeCourseColors(widget.courses, _coursePalette);
  }

  Widget _buildDayHeaderRow({required int todayWeekday}) {
    return Container(
      height: _dayHeaderRowHeight,
      decoration: BoxDecoration(
        color: Styles().colors.white,
        border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
        boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(children: <Widget>[
        SizedBox(width: _timeColumnWidth),
        ..._weekdayOrder.map((int weekday) => Expanded(child:
          Stack(children: <Widget>[
            _buildDayHeaderCell(weekday: weekday, isToday: (weekday == todayWeekday)),
            Positioned(left: 0, bottom: 0, child: _buildDayHeaderDivider()),
          ]),
        )),
      ]),
    );
  }

  Widget _buildDayHeaderDivider() {
    return Container(width: 1, height: _dayHeaderDividerHeight, color: Styles().colors.surfaceAccent);
  }

  Widget _buildDayHeaderCell({required int weekday, required bool isToday}) {
    String letter = _weekdayLetter(weekday);
    return Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
      Center(child: isToday ?
        Container(width: 28, height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors.fillColorPrimary),
          child: Center(child: Text(letter, style: Styles().textStyles.getTextStyle('widget.heading.small.fat'))),
        ) :
        Text(letter, style: Styles().textStyles.getTextStyle('widget.card.detail.small.fat'))
      ),
    );
  }

  String _weekdayLetter(int weekday) {
    switch (weekday) {
      case DateTime.sunday: return Localization().getStringEx('panel.student_courses.calendar.day.sunday.letter', 'S');
      case DateTime.monday: return Localization().getStringEx('panel.student_courses.calendar.day.monday.letter', 'M');
      case DateTime.tuesday: return Localization().getStringEx('panel.student_courses.calendar.day.tuesday.letter', 'T');
      case DateTime.wednesday: return Localization().getStringEx('panel.student_courses.calendar.day.wednesday.letter', 'W');
      case DateTime.thursday: return Localization().getStringEx('panel.student_courses.calendar.day.thursday.letter', 'T');
      case DateTime.friday: return Localization().getStringEx('panel.student_courses.calendar.day.friday.letter', 'F');
      case DateTime.saturday: return Localization().getStringEx('panel.student_courses.calendar.day.saturday.letter', 'S');
      default: return '';
    }
  }

  // Hour grid + course blocks + current-time indicator.

  Widget _buildTimeColumn() {
    return SizedBox(width: _timeColumnWidth, height: 24 * _hourHeight, child:
      Stack(clipBehavior: Clip.none, children: <Widget>[
        ...List<Widget>.generate(24, (int hour) =>
          Positioned(top: hour * _hourHeight, right: -_hourLineRightOvershoot, width: _hourLineLength, child:
            Container(height: 1, color: Styles().colors.surfaceAccent),
          )
        ),
        ...List<Widget>.generate(24, (int hour) =>
          Positioned(top: (hour * _hourHeight) - 7, left: 0, right: _hourLabelRightMargin, child:
            Text(StudentCoursesCalendarLayout.hourLabel(hour), textAlign: TextAlign.right, style: Styles().textStyles.getTextStyle('widget.message.tiny')),
          )
        ),
      ]),
    );
  }

  Widget _buildClosingHourRow() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      SizedBox(width: _timeColumnWidth, height: _closingRowHeight, child:
        Stack(clipBehavior: Clip.none, children: <Widget>[
          Positioned(top: 0, right: -_hourLineRightOvershoot, width: _hourLineLength, child:
            Container(height: 1, color: Styles().colors.surfaceAccent),
          ),
          Positioned(top: -7, left: 0, right: _hourLabelRightMargin, child:
            Text(StudentCoursesCalendarLayout.hourLabel(0), textAlign: TextAlign.right, style: Styles().textStyles.getTextStyle('widget.message.tiny')),
          ),
        ]),
      ),
      Expanded(child: Container(height: 1, color: Styles().colors.surfaceAccent)),
    ]);
  }

  Widget _buildDayColumn({required List<StudentCourseBlock> blocks}) {
    return Container(
      decoration: BoxDecoration(border: Border(left: BorderSide(color: Styles().colors.surfaceAccent, width: 1))),
      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) =>
        Stack(children: <Widget>[
          _buildHourLines(),
          ...blocks.map((StudentCourseBlock block) => _buildCourseBlock(block, dayWidth: constraints.maxWidth)),
        ]),
      ),
    );
  }

  Widget _buildHourLines() {
    return Column(children: List<Widget>.generate(24, (_) =>
      Container(height: _hourHeight, decoration: BoxDecoration(border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1))))
    ));
  }

  Widget _buildCourseBlock(StudentCourseBlock block, {required double dayWidth}) {
    double columnWidth = dayWidth / block.columnCount;
    return Positioned(
      top: (block.startMinutes / 60.0) * _hourHeight,
      left: block.column * columnWidth,
      width: columnWidth,
      height: (block.durationMinutes / 60.0) * _hourHeight,
      child: Padding(padding: EdgeInsets.all(1), child:
        InkWell(onTap: () => _onTapCourse(block.course), child:
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _courseColors[block.course.shortName] ?? Styles().colors.background,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(block.course.shortName ?? (block.course.title ?? ''),
              maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: Styles().textStyles.getTextStyle('widget.message.tiny.fat'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNowLine({required int nowMinutes, required int todayWeekday}) {
    int todayIndex = _weekdayOrder.indexOf(todayWeekday);
    if (todayIndex < 0) {
      return Container();
    }

    double columnLeft = _timeColumnWidth + (todayIndex * _hourHeight); // _hourHeight doubles as the square day-column width
    double lineTop = (nowMinutes / 60.0) * _hourHeight;

    return Positioned.fill(child:
      Stack(clipBehavior: Clip.none, children: <Widget>[
        Positioned(top: lineTop, left: columnLeft, width: _hourHeight, child:
          Container(height: 2, color: _nowLineColor),
        ),
        _buildNowLineDot(top: lineTop, centerX: columnLeft),
        _buildNowLineDot(top: lineTop, centerX: columnLeft + _hourHeight),
      ]),
    );
  }

  Widget _buildNowLineDot({required double top, required double centerX}) {
    const double dotSize = 4;
    return Positioned(top: top + 1 - (dotSize / 2), left: centerX - (dotSize / 2), width: dotSize, height: dotSize, child:
      Container(decoration: BoxDecoration(shape: BoxShape.circle, color: _nowLineColor)),
    );
  }

  Color get _nowLineColor => Styles().colors.getColor('alert') ?? const Color(0xFFFF0000);

  void _onTapCourse(StudentCourse course) {
    Analytics().logSelect(target: "Student Course: ${course.title}");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentCourseDetailPanel(course: course, analyticsFeature: widget.analyticsFeature)));
  }
}
