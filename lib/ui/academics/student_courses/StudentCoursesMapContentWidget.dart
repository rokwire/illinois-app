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

// Map view content for StudentCoursesHomePanel.
// TODO (Step 6): State to extend Map2BasePanelState, mirroring Map2LocationPanel's StudentCourses case
// (trimmed of building-search/pin-drop), fed with the already-loaded `courses` list (no duplicate network
// fetch), rendering the map + Map2TraySheet for the bottom list.
class StudentCoursesMapContentWidget extends StatefulWidget {
  final List<StudentCourse>? courses;

  StudentCoursesMapContentWidget({super.key, this.courses});

  @override
  State<StudentCoursesMapContentWidget> createState() => _StudentCoursesMapContentWidgetState();
}

class _StudentCoursesMapContentWidgetState extends State<StudentCoursesMapContentWidget> {

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Map View'));
  }
}
