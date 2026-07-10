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

  static const double _minHourHeight = 40; // floor, in case the measured day-column width is tiny
  static const double _timeColumnWidth = 64;
  static const int _initialVisibleHour = 7;
  static const int _fixedDurationMinutes = 60; // backend provides no real class duration

  // Day header row: Padding(vertical: 8) + the 28-diameter "today" circle + Padding(vertical: 8).
  static const double _dayHeaderRowHeight = 44;
  // Small vertical tick between adjacent day letters (S | M | T ...), bottom-aligned against the
  // header's own bottom border, shorter than the letter row.
  static const double _dayHeaderDividerHeight = 8;
  // Gap between the day header's bottom border/shadow and the first (12 AM) hour line when scrolled
  // to top. Also doubles as headroom so the vertically-centered "12 AM" label (which straddles its
  // gridline same as every other hour label) has room to render without being clipped.
  static const double _gridTopGap = 20;
  // Hour gridline "tick" in the time-label column: the hour text stops _hourLabelRightMargin from
  // the column's right edge, then the tick itself (_hourLineLength long) starts a visible gap after
  // that and extends a little (_hourLineRightOvershoot) past the vertical line separating the time
  // labels from the grid.
  static const double _hourLabelRightMargin = 24;
  static const double _hourLineLength = 20;
  static const double _hourLineRightOvershoot = 4;
  // Extra sliver below the 24-hour grid for the closing "12 AM" (next day) line/label.
  static const double _closingRowHeight = 20;

  // Column order matches the "S M T W T F S" header in the design.
  static const List<int> _weekdayOrder = <int>[
    DateTime.sunday, DateTime.monday, DateTime.tuesday, DateTime.wednesday,
    DateTime.thursday, DateTime.friday, DateTime.saturday,
  ];

  late final ScrollController _scrollController;

  // Cells are square: the hour row height matches the (measured, so responsive) day-column width,
  // rather than a fixed height. Recomputed on every build via the LayoutBuilder in build() below;
  // starts at the floor value until the first layout pass measures the real width.
  double _hourHeight = _minHourHeight;
  bool _initialScrollApplied = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Runs once, right after the first frame where a real (measured) _hourHeight is known, to scroll
  // to _initialVisibleHour. Can't be done at controller-creation time (initState), since the day
  // column width - and hence the square _hourHeight - isn't known until the first layout pass.
  void _applyInitialScrollOffsetIfNeeded() {
    if (!_initialScrollApplied && _scrollController.hasClients) {
      _initialScrollApplied = true;
      _scrollController.jumpTo(_gridTopGap + (_initialVisibleHour * _hourHeight));
    }
  }

  @override
  Widget build(BuildContext context) {
    TZDateTime now = DateTimeUni.nowUniOrLocal();
    Map<int, List<_CourseBlock>> blocksByWeekday = _buildBlocksByWeekday();

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      // Square cells: the hour row height matches the (measured) day-column width, rather than a
      // fixed height, so it responds to the actual available screen width like the design.
      double dayColumnWidth = (constraints.maxWidth - _timeColumnWidth) / _weekdayOrder.length;
      _hourHeight = math.max(dayColumnWidth, _minHourHeight);
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialScrollOffsetIfNeeded());

      // The day header is painted as a Stack sibling on top of the scrollable grid (rather than a
      // plain Column sibling above it) so its drop shadow can fall over the grid as it scrolls
      // underneath, instead of being hidden behind the grid's opaque background.
      return Stack(children: <Widget>[
        Column(children: <Widget>[
          SizedBox(height: _dayHeaderRowHeight),
          Expanded(child:
            SingleChildScrollView(controller: _scrollController, child:
              Padding(padding: EdgeInsets.only(top: _gridTopGap), child:
                // Extra `_closingRowHeight` below the 24-hour grid for a closing "12 AM" line/label
                // (the next day's midnight boundary) - reserved as a separate sliver, not part of the
                // day columns themselves, so their vertical borders stop exactly at the grid's own
                // bottom edge instead of continuing alongside the closing line.
                SizedBox(height: (24 * _hourHeight) + _closingRowHeight, child:
                  Stack(clipBehavior: Clip.none, children: <Widget>[
                    Positioned(top: 0, left: 0, right: 0, height: 24 * _hourHeight, child:
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        _buildTimeColumn(),
                        ..._weekdayOrder.map((int weekday) => Expanded(child:
                          _buildDayColumn(blocks: blocksByWeekday[weekday] ?? <_CourseBlock>[]),
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

  // Day header row (S M T W T F S), with the current day circled. Opaque white + a drop shadow,
  // since it now floats (via Positioned in build()) on top of the scrollable grid below it.
  //
  // Each day cell (including the first, S - matching the grid's own day-column-0 left border at the
  // boundary with the time-label gutter) carries its own left-edge divider, instead of inserting
  // separate 1px-wide divider widgets between Expanded cells: the latter would shrink every cell by
  // a fraction of those extra widgets' width relative to the grid's day columns below (which have no
  // such siblings), drifting the header's dividers out of alignment with the grid's own column
  // borders further right along the row. Matching the grid's own approach (each day column paints
  // its own left border) keeps both rows' cell widths - and so the divider/border positions -
  // pixel-identical.
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
      // The "12 AM" label straddles its gridline the same as every other hour label (top: -7), which
      // pokes a few pixels above this Stack's own top edge (y=0). Without Clip.none, Stack's default
      // hardEdge clip cuts that overflow off, so only the label's bottom half showed. _gridTopGap
      // above provides the actual blank space for it to render into.
      Stack(clipBehavior: Clip.none, children: <Widget>[
        // Ticks poking out past the time column's own right edge (negative `right`), so each hour
        // gridline visually overshoots the vertical line separating the time labels from the grid.
        // Clip.none on this Stack (see below) is what allows that overshoot to actually render.
        ...List<Widget>.generate(24, (int hour) =>
          Positioned(top: hour * _hourHeight, right: -_hourLineRightOvershoot, width: _hourLineLength, child:
            Container(height: 1, color: Styles().colors.surfaceAccent),
          )
        ),
        ...List<Widget>.generate(24, (int hour) =>
          Positioned(top: (hour * _hourHeight) - 7, left: 0, right: _hourLabelRightMargin, child:
            Text(_hourLabel(hour), textAlign: TextAlign.right, style: Styles().textStyles.getTextStyle('widget.message.tiny')),
          )
        ),
      ]),
    );
  }

  // Closing "12 AM" (next day's midnight) line + label under the 24-hour grid: same two-part
  // treatment as every other hour line in _buildTimeColumn() (a short overshooting tick in the
  // time-label gutter, plus the full-width line across), but with no per-day vertical borders below
  // it, since the day columns above already end at this exact y.
  Widget _buildClosingHourRow() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      SizedBox(width: _timeColumnWidth, height: _closingRowHeight, child:
        Stack(clipBehavior: Clip.none, children: <Widget>[
          Positioned(top: 0, right: -_hourLineRightOvershoot, width: _hourLineLength, child:
            Container(height: 1, color: Styles().colors.surfaceAccent),
          ),
          Positioned(top: -7, left: 0, right: _hourLabelRightMargin, child:
            Text(_hourLabel(0), textAlign: TextAlign.right, style: Styles().textStyles.getTextStyle('widget.message.tiny')),
          ),
        ]),
      ),
      Expanded(child: Container(height: 1, color: Styles().colors.surfaceAccent)),
    ]);
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

  Widget _buildDayColumn({required List<_CourseBlock> blocks}) {
    return Container(
      decoration: BoxDecoration(border: Border(left: BorderSide(color: Styles().colors.surfaceAccent, width: 1))),
      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) =>
        Stack(children: <Widget>[
          _buildHourLines(),
          ...blocks.map((_CourseBlock block) => _buildCourseBlock(block, dayWidth: constraints.maxWidth)),
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

class _CourseBlock {
  final StudentCourse course;
  final int startMinutes;
  final int durationMinutes;
  int column = 0;
  int columnCount = 1;

  _CourseBlock({required this.course, required this.startMinutes, required this.durationMinutes});

  int get endMinutes => startMinutes + durationMinutes;
}
