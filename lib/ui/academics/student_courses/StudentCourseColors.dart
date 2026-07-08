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

// Predefined pale color palette for Calendar view course blocks.
// Colors are assigned client-side (neither color nor duration is provided by the backend).
class StudentCourseColors {

  static const List<Color> palette = <Color>[
    Color(0xFFEFEECE), // Pale Yellow
    Color(0xFFF4E5CE), // Pale Orange
    Color(0xFFF6E6E2), // Pale Red
    Color(0xFFEDE3F4), // Pale Purple
    Color(0xFFD2E6EC), // Pale Blue
    Color(0xFFE1EED4), // Pale Green
  ];

  // TODO (Step 4): assign a stable color per unique course (keyed by course number), without repeating
  // a color between different courses until the palette is exhausted (more than palette.length courses).
  static Map<String, Color> assign(List<StudentCourse>? courses) {
    return const <String, Color>{};
  }
}
