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

import 'package:flutter/material.dart';
import 'package:illinois/model/StudentCourse.dart';

class StudentCourseBlock {
  final StudentCourse course;
  final int startMinutes;
  final int durationMinutes;
  int column = 0;
  int columnCount = 1;

  StudentCourseBlock({required this.course, required this.startMinutes, required this.durationMinutes});

  int get endMinutes => startMinutes + durationMinutes;
}

class StudentCoursesCalendarLayout {

  static void layoutOverlappingBlocks(List<StudentCourseBlock> blocks) {
    blocks.sort((StudentCourseBlock block1, StudentCourseBlock block2) => block1.startMinutes.compareTo(block2.startMinutes));

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

  static void _assignColumns(List<StudentCourseBlock> blocks, int fromIndex, int toIndex) {
    List<int> columnEndMinutes = <int>[];
    for (int i = fromIndex; i < toIndex; i++) {
      StudentCourseBlock block = blocks[i];
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

  ///
  /// Requirement:
  ///  - "It's important that the same color is not used for two separate classes (unless the user is taking more than 6 classes that semester)."
  ///  - "... that example is one course based on the course short name so it would use the same color ..."
  ///
  static Map<String, Color> computeCourseColors(List<StudentCourse>? courses, List<Color> palette) {
    List<String> courseKeys = <String>[];
    for (StudentCourse course in courses ?? <StudentCourse>[]) {
      String? courseKey = course.shortName;
      if ((courseKey != null) && !courseKeys.contains(courseKey)) {
        courseKeys.add(courseKey);
      }
    }

    List<Color> shuffledPalette = List<Color>.from(palette)..shuffle(math.Random(courseKeys.join(',').hashCode));

    Map<String, Color> courseColors = <String, Color>{};
    for (int index = 0; index < courseKeys.length; index++) {
      courseColors[courseKeys[index]] = shuffledPalette[index % shuffledPalette.length];
    }
    return courseColors;
  }
}
