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

import 'package:flutter/material.dart';
import 'package:illinois/model/StudentCourse.dart';

// Weekly calendar grid content for StudentCoursesHomePanel.
// TODO (Step 5): day header row (S-M-T-W-T-F-S) with current-day highlight, scrollable 24h hour grid
// (7AM-8PM initial viewport), fixed 1-hour course blocks colored via courseColors (only for courses with
// a non-empty section.startTime), current-time indicator line, tap-to-detail navigation.
class StudentCoursesCalendarContentWidget extends StatefulWidget {
  final List<StudentCourse>? courses;
  final Map<String, Color>? courseColors;

  StudentCoursesCalendarContentWidget({super.key, this.courses, this.courseColors});

  @override
  State<StudentCoursesCalendarContentWidget> createState() => _StudentCoursesCalendarContentWidgetState();
}

class _StudentCoursesCalendarContentWidgetState extends State<StudentCoursesCalendarContentWidget> {

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Calendar View'));
  }
}
