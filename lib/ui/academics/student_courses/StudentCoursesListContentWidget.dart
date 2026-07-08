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
import 'package:illinois/ui/academics/StudentCourses.dart';

// List view content for StudentCoursesHomePanel — reuses the existing StudentCourseCard
// (lib/ui/academics/StudentCourses.dart) unchanged. Term selection lives in the host's filter bar,
// so this widget only renders the course cards.
class StudentCoursesListContentWidget extends StatelessWidget {
  final List<StudentCourse>? courses;
  final AnalyticsFeature? analyticsFeature;

  StudentCoursesListContentWidget({super.key, this.courses, this.analyticsFeature});

  @override
  Widget build(BuildContext context) {
    List<Widget> courseWidgets = <Widget>[];
    for (StudentCourse course in courses ?? <StudentCourse>[]) {
      courseWidgets.add(Padding(padding: EdgeInsets.only(top: courseWidgets.isNotEmpty ? 8 : 0), child:
        StudentCourseCard(course: course, analyticsFeature: analyticsFeature),
      ));
    }

    return SingleChildScrollView(child:
      Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
        Column(children: courseWidgets),
      ),
    );
  }
}
