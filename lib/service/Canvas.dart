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
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:http/http.dart' as http;

import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class Canvas with Service implements NotificationsListener {

  static const String notifyCoursesUpdated  = "edu.illinois.rokwire.canvas.courses.updated";

  static const String _canvasCoursesCacheFileName = "canvasCourses.json";

  List<CanvasCourse>? _courses;

  File? _cacheFile;
  DateTime? _pausedDateTime;
  
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
  void createService() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Auth2.notifyLoginChanged,
      Connectivity.notifyStatusChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config(), Auth2()]);
  }

  @override
  Future<void> initService() async {
    _cacheFile = await _getCacheFile();
    _courses = await _loadCoursesFromCache();
    if (_courses != null) {
      updateCourses();
    } else {
      String? jsonString = await _loadCoursesStringFromNet();
      _courses = _loadCoursesFromString(jsonString);
      if (_courses != null) {
        _saveCoursesStringToCache(jsonString);
      }
    }
    await super.initService();
  }

  // Accessories

  List<CanvasCourse>? get courses => _courses;

  bool get _available => StringUtils.isNotEmpty(Config().lmsUrl);

  // Courses

  Future<void> updateCourses() async {
    String? jsonString = await _loadCoursesStringFromNet();
    List<CanvasCourse>? canvasCourses = _loadCoursesFromString(jsonString);
    if ((canvasCourses != null) && !DeepCollectionEquality().equals(_courses, canvasCourses)) {
      _courses = canvasCourses;
      _saveCoursesStringToCache(jsonString);
      NotificationService().notify(notifyCoursesUpdated);
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

  // Handle Canvas app deep link

  Future<void> openCanvasAppDeepLink(String deepLink) async {
    bool? appLaunched = await RokwirePlugin.launchApp({"deep_link": deepLink});
    if (appLaunched != true) {
      String? canvasStoreUrl = Config().canvasStoreUrl;
      if ((canvasStoreUrl != null) && await url_launcher.canLaunch(canvasStoreUrl)) {
        await url_launcher.launch(canvasStoreUrl, forceSafariVC: false);
      }
    }
  }

  // Caching

  Future<void> _saveCoursesStringToCache(String? regionsString) async {
    await _cacheFile?.writeAsString(regionsString ?? '', flush: true);
  }

  Future<List<CanvasCourse>?> _loadCoursesFromCache() async {
    String? cachedString = await _loadCoursesStringFromCache();
    return _loadCoursesFromString(cachedString);
  }

  Future<String?> _loadCoursesStringFromCache() async {
    return ((_cacheFile != null) && await _cacheFile!.exists()) ? await _cacheFile!.readAsString() : null;
  }

  Future<File> _getCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _canvasCoursesCacheFileName);
    return File(cacheFilePath);
  }

  List<CanvasCourse>? _loadCoursesFromString(String? coursesString) {
    List<dynamic>? coursesJson = JsonUtils.decodeList(coursesString);
    if (coursesJson == null) {
      return null;
    }
    List<CanvasCourse> courses = <CanvasCourse>[];
    for (dynamic courseJson in coursesJson) {
      CanvasCourse? course = CanvasCourse.fromJson(courseJson);
      // Do not load course if it's null or its access is restricted by date
      if ((course != null) && (course.accessRestrictedByDate != true)) {
        ListUtils.add(courses, course);
      }
    }
    return courses;
  }

  Future<String?> _loadCoursesStringFromNet() async {
    if (!Auth2().isOidcLoggedIn) {
      debugPrint('Canvas courses: the user is not signed in with oidc');
      return null;
    }
    String? url = '${Config().lmsUrl}/courses';
    http.Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      return responseString;
    } else {
      debugPrint('Failed to load canvas courses from net. Reason: $responseCode $responseString');
      return null;
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    } else if (name == Auth2.notifyLoginChanged) {
      updateCourses();
    } else if (name == Connectivity.notifyStatusChanged) {
      if (Connectivity().isNotOffline) {
        updateCourses();
      }
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          updateCourses();
        }
      }
    }
  }
}