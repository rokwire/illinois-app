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

import 'dart:core';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:http/http.dart' as http;

import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Canvas with Service {
  
  // Singleton Factory
  Canvas._internal();
  static final Canvas _instance = Canvas._internal();

  factory Canvas() {
    return _instance;
  }

  Canvas get instance {
    return _instance;
  }

  // Service

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config(), Auth2()]);
  }

  // Courses

  Future<List<CanvasCourse>?> loadCourses() async {
    if (!_available) {
      return null;
    }
    String? url = '${Config().lmsUrl}/courses';
    http.Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<dynamic>? coursesJson = JsonUtils.decodeList(responseString);
      List<CanvasCourse>? courses;
      if (coursesJson != null) {
        courses = <CanvasCourse>[];
        for (dynamic json in coursesJson) {
          CanvasCourse? course = CanvasCourse.fromJson(json);
          // Do not load course if it's null or its access is restricted by date
          if ((course != null) && (course.accessRestrictedByDate != true)) {
            courses.add(course);
          }
        }
      }
      return courses;
    } else {
      Log.w('Failed to load canvas courses. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<CanvasCourse?> loadCourse(int? courseId) async {
    if (!_available) {
      return null;
    }
    if (courseId == null) {
      Log.d('Failed to load canvas course - missing course id.');
      return null;
    }
    String? url = '${Config().lmsUrl}/courses/$courseId';
    http.Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? courseJson = JsonUtils.decodeMap(responseString);
      return CanvasCourse.fromJson(courseJson);
    } else {
      Log.w('Failed to load canvas course. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Assignments

  Future<List<CanvasAssignmentGroup>?> loadAssignmentGroups(int courseId) async {
    if (!_available) {
      return null;
    }
    String? url = '${Config().lmsUrl}/courses/$courseId/assignment-groups?include=assignments';
    http.Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasAssignmentGroup>? assignmentGroups = CanvasAssignmentGroup.listFromJson(JsonUtils.decodeList(responseString));
      return assignmentGroups;
    } else {
      Log.w('Failed to load canvas assignment groups. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Grades

  Future<double?> loadCourseGradeScore(int courseId) async {
    if (!_available) {
      return null;
    }
    String? url = '${Config().lmsUrl}/courses/$courseId/users?include=enrollments,scores';
    http.Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      CanvasUser? user = CanvasUser.fromJson(JsonUtils.decodeMap(responseString));
      List<CanvasEnrollment>? enrollments = user?.enrollments;
      double? currentScore;
      if (CollectionUtils.isNotEmpty(enrollments)) {
        for (CanvasEnrollment enrollment in enrollments!) {
          if (enrollment.type == CanvasEnrollmentType.student) {
            CanvasGrade? grade = enrollment.grade;
            currentScore = grade?.currentScore;
            break;
          }
        }
      }
      return currentScore;
    } else {
      Log.w('Failed to load canvas user with enrollments. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Canvas Self User

  Future<Map<String, dynamic>?> loadSelfUser() async {
    if (!_available) {
      return null;
    }
    String? url = '${Config().lmsUrl}/users/self';
    http.Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      return JsonUtils.decodeMap(responseString);
    } else {
      Log.w('Failed to load canvas self user. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Helpers

  bool get _available {
    return StringUtils.isNotEmpty(Config().lmsUrl);
  }
}