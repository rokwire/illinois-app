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
import 'package:illinois/service/Storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
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
      AppLifecycle.notifyStateChanged,
      Auth2.notifyLoginChanged,
      Connectivity.notifyStatusChanged,
      Storage.notifySettingChanged,
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
      _updateCourses();
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

  bool get _isAvailable => ((_useCanvasApi && _isCanvasAvailable) || _isLmsAvailable);
  
  bool get _isLmsAvailable => StringUtils.isNotEmpty(Config().lmsUrl);

  bool get _isCanvasAvailable =>
      StringUtils.isNotEmpty(Auth2().netId) &&
      StringUtils.isNotEmpty(Config().canvasUrl) &&
      StringUtils.isNotEmpty(Config().canvasToken) &&
      StringUtils.isNotEmpty(Config().canvasTokenType);

  bool get _useCanvasApi => (Storage().debugUseCanvasLms == true);

  Map<String, String>? get _canvasAuthHeaders => _isCanvasAvailable
      ? {HttpHeaders.authorizationHeader: "${Config().canvasTokenType} ${Config().canvasToken}"}
      : null;

  // Courses

  Future<void> _updateCourses() async {
    String? jsonString = await _loadCoursesStringFromNet();
    List<CanvasCourse>? canvasCourses = _loadCoursesFromString(jsonString);
    if ((canvasCourses != null) && !DeepCollectionEquality().equals(_courses, canvasCourses)) {
      _courses = canvasCourses;
      _saveCoursesStringToCache(jsonString);
      NotificationService().notify(notifyCoursesUpdated);
    }
  }

  Future<CanvasCourse?> loadCourse(int? courseId) async {
    if (!_isAvailable) {
      return null;
    }
    if (courseId == null) {
      Log.d('Failed to load canvas course - missing course id.');
      return null;
    }
    String? url;
    http.Response? response;
    if (_useCanvasApi) {
      url = '${Config().canvasUrl}/api/v1/courses/$courseId';
      response = await Network().get(url, headers: _canvasAuthHeaders);
    } else {
      url = '${Config().lmsUrl}/courses/$courseId';
      response = await Network().get(url, auth: Auth2());
    }
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
    if (!_isAvailable) {
      return null;
    }
    String? url;
    http.Response? response;
    if (_useCanvasApi) {
      url = _masquerade('${Config().canvasUrl}/api/v1/courses/$courseId/assignment_groups?include[]=assignments');
      response = await Network().get(url, headers: _canvasAuthHeaders);
    } else {
      url = '${Config().lmsUrl}/courses/$courseId/assignment-groups?include=assignments';
      response = await Network().get(url, auth: Auth2());
    }
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
    if (!_isAvailable) {
      return null;
    }
    String? url;
    http.Response? response;
    if (_useCanvasApi) {
      url = _masquerade('${Config().canvasUrl}/api/v1/courses/$courseId/users/self?include[]=enrollments&include[]=current_grading_period_scores');
      response = await Network().get(url, headers: _canvasAuthHeaders);
    } else {
      url = '${Config().lmsUrl}/courses/$courseId/users?include=enrollments,scores';
      response = await Network().get(url, auth: Auth2());
    }
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
    if (!_isAvailable) {
      return null;
    }
    String? url;
    http.Response? response = await Network().get(url, auth: Auth2());
    if (_useCanvasApi) {
      url = _masquerade('${Config().canvasUrl}/api/v1/users/self');
      response = await Network().get(url, headers: _canvasAuthHeaders);
    } else {
      url = '${Config().lmsUrl}/users/self';
      response = await Network().get(url, auth: Auth2());
    }
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
      Uri? storeUri = StringUtils.isNotEmpty(canvasStoreUrl) ? Uri.tryParse(canvasStoreUrl!) : null;
      if ((storeUri != null) && await url_launcher.canLaunchUrl(storeUri)) {
        await url_launcher.launchUrl(storeUri);
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
    String? url;
    http.Response? response;
    if (_useCanvasApi) {
      url = _masquerade('${Config().canvasUrl}/api/v1/courses');
      response = await Network().get(url, headers: _canvasAuthHeaders);
    } else {
      url = '${Config().lmsUrl}/courses';
      response = await Network().get(url, auth: Auth2());
    }
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      return responseString;
    } else {
      debugPrint('Failed to load canvas courses from net. Reason: $url $responseCode $responseString');
      return null;
    }
  }

  ///
  /// Do not return a value if the user is not able to masquerade with Net id
  /// returns masqueraded url if succeeded, null - otherwise
  ///
  String? _masquerade(String url) {
    if (StringUtils.isEmpty(url)) {
      return null;
    }
    String? userNetId = Auth2().netId;
    if (StringUtils.isEmpty(userNetId)) {
      return null;
    }
    String querySymbol = url.contains('?') ? '&' : '?';
    return '$url${querySymbol}as_user_id=sis_user_id:$userNetId';
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
    } else if (name == Auth2.notifyLoginChanged) {
      _updateCourses();
    } else if (name == Connectivity.notifyStatusChanged) {
      if (Connectivity().isNotOffline) {
        _updateCourses();
      }
    } else if (name == Storage.notifySettingChanged) {
      if (param == Storage.debugUseCanvasLmsKey) {
        _updateCourses();
      }
    }
  }

  void _onAppLifecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateCourses();
        }
      }
    }
  }
}