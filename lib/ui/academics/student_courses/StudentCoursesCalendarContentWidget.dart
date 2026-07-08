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
import 'package:illinois/ui/academics/StudentCourses.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:timezone/timezone.dart';

// Weekly calendar grid content for StudentCoursesHomePanel. Courses without a `section.startTime`
// are not shown here (the backend does not provide a real class duration, only a start time, so
// every block uses a fixed 1-hour height). Courses meeting at overlapping times on the same day are
// laid out side by side, splitting the day column width evenly between them.
class StudentCoursesCalendarContentWidget extends StatefulWidget {
  final List<StudentCourse>? courses;
  final Map<String, Color>? courseColors;
  final AnalyticsFeature? analyticsFeature;

  StudentCoursesCalendarContentWidget({super.key, this.courses, this.courseColors, this.analyticsFeature});

  @override
  State<StudentCoursesCalendarContentWidget> createState() => _StudentCoursesCalendarContentWidgetState();
}

class _StudentCoursesCalendarContentWidgetState extends State<StudentCoursesCalendarContentWidget> {

  static const double _hourHeight = 60;
  static const double _timeColumnWidth = 44;
  static const int _initialVisibleHour = 7;
  static const int _fixedDurationMinutes = 60; // backend provides no real class duration

  // Column order matches the "S M T W T F S" header in the design.
  static const List<int> _weekdayOrder = <int>[
    DateTime.sunday, DateTime.monday, DateTime.tuesday, DateTime.wednesday,
    DateTime.thursday, DateTime.friday, DateTime.saturday,
  ];

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: _initialVisibleHour * _hourHeight);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TZDateTime now = DateTimeUni.nowUniOrLocal();
    Map<int, List<_CourseBlock>> blocksByWeekday = _buildBlocksByWeekday();

    return Column(children: <Widget>[
      _buildDayHeaderRow(todayWeekday: now.weekday),
      Expanded(child:
        SingleChildScrollView(controller: _scrollController, child:
          SizedBox(height: 24 * _hourHeight, child:
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              _buildTimeColumn(),
              ..._weekdayOrder.map((int weekday) => Expanded(child:
                _buildDayColumn(
                  blocks: blocksByWeekday[weekday] ?? <_CourseBlock>[],
                  isToday: (weekday == now.weekday),
                  nowMinutes: (now.hour * 60) + now.minute,
                ),
              )),
            ]),
          ),
        ),
      ),
    ]);
  }

  // Data prep

  Map<int, List<_CourseBlock>> _buildBlocksByWeekday() {
    Map<int, List<_CourseBlock>> blocksByWeekday = <int, List<_CourseBlock>>{};
    for (StudentCourse course in widget.courses ?? <StudentCourse>[]) {
      int? startMinutes = course.section?.startTimeMinutes;
      if (startMinutes != null) {
        for (int weekday in course.section?.weekdays ?? <int>[]) {
          blocksByWeekday.putIfAbsent(weekday, () => <_CourseBlock>[]).add(
            _CourseBlock(course: course, startMinutes: startMinutes, durationMinutes: _fixedDurationMinutes)
          );
        }
      }
    }
    blocksByWeekday.forEach((_, List<_CourseBlock> blocks) => _layoutOverlappingBlocks(blocks));
    return blocksByWeekday;
  }

  // Sorts a day's blocks by start time and assigns each one a `column` / `columnCount` so that
  // blocks overlapping in time are laid out side by side with equal width, like a typical calendar.
  void _layoutOverlappingBlocks(List<_CourseBlock> blocks) {
    blocks.sort((_CourseBlock block1, _CourseBlock block2) => block1.startMinutes.compareTo(block2.startMinutes));

    int groupStart = 0;
    int groupEndMinutes = -1;
    for (int i = 0; i < blocks.length; i++) {
      if ((groupEndMinutes >= 0) && (blocks[i].startMinutes >= groupEndMinutes)) {
        _assignColumns(blocks, groupStart, i);
        groupStart = i;
        groupEndMinutes = -1;
      }
      groupEndMinutes = (groupEndMinutes < 0) ? blocks[i].endMinutes : math.max(groupEndMinutes, blocks[i].endMinutes);
    }
    if (blocks.isNotEmpty) {
      _assignColumns(blocks, groupStart, blocks.length);
    }
  }

  // Greedy column assignment (like Google/Outlook calendar day views) for one group of
  // consecutively-overlapping blocks: reuse the first column whose previous block already ended,
  // otherwise open a new column.
  void _assignColumns(List<_CourseBlock> blocks, int fromIndex, int toIndex) {
    List<int> columnEndMinutes = <int>[];
    for (int i = fromIndex; i < toIndex; i++) {
      _CourseBlock block = blocks[i];
      int column = columnEndMinutes.indexWhere((int endMinutes) => (endMinutes <= block.startMinutes));
      if (column < 0) {
        column = columnEndMinutes.length;
        columnEndMinutes.add(block.endMinutes);
      }
      else {
        columnEndMinutes[column] = block.endMinutes;
      }
      block.column = column;
    }
    for (int i = fromIndex; i < toIndex; i++) {
      blocks[i].columnCount = columnEndMinutes.length;
    }
  }

  // Day header row (S M T W T F S), with the current day circled.

  Widget _buildDayHeaderRow({required int todayWeekday}) {
    return Row(children: <Widget>[
      SizedBox(width: _timeColumnWidth),
      ..._weekdayOrder.map((int weekday) => Expanded(child:
        _buildDayHeaderCell(weekday: weekday, isToday: (weekday == todayWeekday)),
      )),
    ]);
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
      Stack(children: List<Widget>.generate(24, (int hour) =>
        Positioned(top: (hour * _hourHeight) - 7, left: 0, right: 4, child:
          Text(_hourLabel(hour), textAlign: TextAlign.right, style: Styles().textStyles.getTextStyle('widget.message.tiny')),
        )
      )),
    );
  }

  String _hourLabel(int hour) {
    if (hour == 0) {
      return Localization().getStringEx('panel.student_courses.calendar.hour.midnight.label', '12 AM');
    }
    else if (hour < 12) {
      return '$hour AM';
    }
    else if (hour == 12) {
      return Localization().getStringEx('panel.student_courses.calendar.hour.noon.label', '12 PM');
    }
    else {
      return '${hour - 12} PM';
    }
  }

  Widget _buildDayColumn({required List<_CourseBlock> blocks, required bool isToday, required int nowMinutes}) {
    return Container(
      decoration: BoxDecoration(border: Border(left: BorderSide(color: Styles().colors.surfaceAccent, width: 1))),
      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) =>
        Stack(children: <Widget>[
          _buildHourLines(),
          ...blocks.map((_CourseBlock block) => _buildCourseBlock(block, dayWidth: constraints.maxWidth)),
          if (isToday) _buildNowLine(nowMinutes: nowMinutes),
        ]),
      ),
    );
  }

  Widget _buildHourLines() {
    return Column(children: List<Widget>.generate(24, (_) =>
      Container(height: _hourHeight, decoration: BoxDecoration(border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1))))
    ));
  }

  Widget _buildCourseBlock(_CourseBlock block, {required double dayWidth}) {
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
              color: widget.courseColors?[block.course.number] ?? Styles().colors.background,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(block.course.shortName ?? (block.course.title ?? ''),
              maxLines: 3, overflow: TextOverflow.ellipsis,
              style: Styles().textStyles.getTextStyle('widget.card.title.tiny.fat'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNowLine({required int nowMinutes}) {
    return Positioned(top: (nowMinutes / 60.0) * _hourHeight, left: 0, right: 0, child:
      Container(height: 2, color: Styles().colors.getColor('alert') ?? const Color(0xFFFF0000)),
    );
  }

  void _onTapCourse(StudentCourse course) {
    Analytics().logSelect(target: "Student Course: ${course.title}");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentCourseDetailPanel(course: course, analyticsFeature: widget.analyticsFeature)));
  }
}

class _CourseBlock {
  final StudentCourse course;
  final int startMinutes;
  final int durationMinutes;
  int column = 0;
  int columnCount = 1;

  _CourseBlock({required this.course, required this.startMinutes, required this.durationMinutes});

  int get endMinutes => startMinutes + durationMinutes;
}
