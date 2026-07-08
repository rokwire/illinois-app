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
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/ui/academics/student_courses/StudentCoursesListContentWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

// TODO (Step 7): introduce a private `_StudentCoursesViewType { calendar, list, map }` enum here
// (+ a `_StudentCoursesViewTypeExt` extension at the bottom of this file for pillTitle/displayTitle),
// backing a RibbonButton dropdown overlay + Storage persistence, once it is actually wired in.

// Host/container panel for the new "My Courses" experience: owns the header, the filter bar
// (term + view-type dropdowns), course/term loading state, and switches between the Calendar,
// List and Map content widgets. Built up incrementally:
//   Step 1: skeleton scaffold.
//   Step 2 (this): List content widget wired in, with a minimal one-off course load for preview.
//   Step 3: full loading/error/term-change state machine + filter bar.
//   Step 7: view-type selector + full switch between content widgets.
//
// NOTE: temporarily reachable only via the Debug panel while it is being built out; the production
// entry points (AcademicsHomePanel, StudentCoursesListPanel push sites) keep using the existing
// lib/ui/academics/StudentCourses.dart until Step 8.
class StudentCoursesHomePanel extends StatefulWidget with AnalyticsInfo {
  StudentCoursesHomePanel();

  @override
  State<StudentCoursesHomePanel> createState() => _StudentCoursesHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.AcademicsStudentCourses;
}

class _StudentCoursesHomePanelState extends State<StudentCoursesHomePanel> {

  // Step 2 temporary: one-off load just to preview StudentCoursesListContentWidget in isolation.
  // Step 3 replaces this with the full loading/error/term-change state machine.
  List<StudentCourse>? _courses;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    String? termId = StudentCourses().displayTermId;
    if (termId != null) {
      _loading = true;
      StudentCourses().loadCourses(termId: termId).then((List<StudentCourse>? courses) {
        setStateIfMounted(() {
          _courses = courses;
          _loading = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.student_courses.header.title', 'My Courses')),
      body: Column(children: <Widget>[
        _buildFilterBar(),
        Expanded(child: _buildContent()),
      ]),
      backgroundColor: Styles().colors.white,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  // TODO (Step 3): term pill dropdown; (Step 7): view-type RibbonButton dropdown overlay.
  Widget _buildFilterBar() {
    return Container();
  }

  // TODO (Step 3): offline / not-logged-in / empty states.
  // TODO (Step 7): switch between Calendar / List / Map content widgets.
  Widget _buildContent() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary)));
    }
    return StudentCoursesListContentWidget(courses: _courses, analyticsFeature: widget.analyticsFeature);
  }
}
