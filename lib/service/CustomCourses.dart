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
import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:http/http.dart' as http;

import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CustomCourses with Service implements NotificationsListener {
  Map<String, Course>? _courses;
  Map<String, UserCourse>? _userCourses;
  Map<String, List<UserUnit>>? _userUnits;
  late String _timezoneName;
  late int _timezoneOffset;

  DateTime? _pausedDateTime;
  
  // Singleton Factory
  CustomCourses._internal();
  static final CustomCourses _instance = CustomCourses._internal();

  factory CustomCourses() {
    return _instance;
  }

  CustomCourses get instance {
    return _instance;
  }

  // Service

  @override
  void createService() {
    super.createService();
    NotificationService().subscribe(this, [
      AppLifecycle.notifyStateChanged,
    ]);
  }

  @override
  Future<void> initService() async {
    _getTimezoneInfo();
    await super.initService();
  }

  @override
  void destroyService() {
    _courses?.clear();
    _userCourses?.clear();
    _userUnits?.clear();
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config(), Auth2()]);
  }

  // Accessories

  bool get _isLmsAvailable => StringUtils.isNotEmpty(Config().lmsUrl);

  Map<String, Course>? get courses => _courses;
  Map<String, UserCourse>? get userCourses => _userCourses;
  Map<String, List<UserUnit>>? get userCourseUnits => _userUnits;

  // Courses

  Future<Course?> loadCourse(String key) async {
    if (Auth2().isLoggedIn && _isLmsAvailable) {
      String? url = '${Config().lmsUrl}/custom/courses/$key';
      http.Response? response = await Network().get(url, auth: Auth2());
      String? responseString = response?.statusCode == 200 ? response?.body : null;
      Map<String, dynamic>? responseJson = JsonUtils.decodeMap(responseString);
      if (responseJson != null) {
        Course? course = Course.fromJson(responseJson);
        if (course != null) {
          _courses ??= {};
          _courses![key] = course;
        }
        return course;
      }

      if (response?.statusCode != 200) {
        debugPrint('Failed to load custom course $key from net. Reason: $url ${response?.statusCode} $responseString');
      }
    }
    return null;
  }

  Future<List<Course>?> loadCourses() async {
    if (Auth2().isLoggedIn && _isLmsAvailable) {
      String? url = '${Config().lmsUrl}/custom/courses';
      http.Response? response = await Network().get(url, auth: Auth2());
      String? responseString = response?.statusCode == 200 ? response?.body : null;
      List<dynamic>? courseList = JsonUtils.decodeList(responseString);

      if (courseList != null) {
        List<Course> courses = Course.listFromJson(courseList);
        _courses ??= {};
        for (Course course in courses) {
          if (course.key != null) {
            _courses![course.key!] = course;
          }
        }
        return courses;
      }

      debugPrint('Failed to load courses from net. Reason: $url ${response?.statusCode} $responseString');
    }
    return null;
  }

	// UserCourses

  Future<http.Response?> _loadUserCoursesResponse({List<String>? ids, List<String>? names, List<String>? keys}) async {
    if (Auth2().isLoggedIn && _isLmsAvailable) {
      Map<String, String> queryParams = {};
      if (CollectionUtils.isNotEmpty(ids)) {
        queryParams['ids'] = ids!.join(',');
      }
      if (CollectionUtils.isNotEmpty(names)) {
        queryParams['names'] = names!.join(',');
      }
      if (CollectionUtils.isNotEmpty(keys)) {
        queryParams['keys'] = keys!.join(',');
      }

      String url = '${Config().lmsUrl}/users/courses';
      if (queryParams.isNotEmpty) {
        url = UrlUtils.addQueryParameters(url, queryParams);
      }
      return Network().get(url, auth: Auth2());
    }
    return null;
  }

  Future<List<UserCourse>?> loadUserCourses({List<String>? ids, List<String>? names, List<String>? keys}) async {
    http.Response? response = await _loadUserCoursesResponse(ids: ids, names: names, keys: keys);
    String? responseString = response?.statusCode == 200 ? response?.body : null;
    List<dynamic>? userCourseList = JsonUtils.decodeList(responseString);

    if (userCourseList != null) {
      List<UserCourse> userCourses = UserCourse.listFromJson(userCourseList);
      _userCourses ??= {};
      for (UserCourse uc in userCourses) {
        if (uc.course?.key != null) {
          _userCourses![uc.course!.key!] = uc;
        }
      }
      return userCourses;
    }

    debugPrint('Failed to load user courses from net. Reason: ${response?.request?.url.toString()} ${response?.statusCode} $responseString');
    return null;
  }

  Future<UserCourse?> loadUserCourse(String key) async {
    if (Auth2().isLoggedIn && _isLmsAvailable) {
      String? url = '${Config().lmsUrl}/users/courses/$key';
      http.Response? response = await Network().get(url, auth: Auth2());
      String? responseString = response?.statusCode == 200 ? response?.body : null;
      Map<String, dynamic>? responseJson = JsonUtils.decodeMap(responseString);
      if (responseJson != null) {
        UserCourse? userCourse = UserCourse.fromJson(responseJson);
        if (userCourse != null) {
          _userCourses ??= {};
          _userCourses![key] = userCourse;
        }
        return userCourse;
      }

      if (response?.statusCode != 200) {
        debugPrint('Failed to load user course for key $key from net. Reason: $url ${response?.statusCode} $responseString');
      }
    }
    return null;
  }

  Future<UserCourse?> createUserCourse(String key) async {
    if (Auth2().isLoggedIn && _isLmsAvailable) {
      String? url = '${Config().lmsUrl}/users/courses/$key';
      String? post = JsonUtils.encode({
        'timezone_name': _timezoneName,
        'timezone_offset': _timezoneOffset,
      });
      http.Response? response = await Network().post(url, auth: Auth2(), body: post);
      String? responseString = response?.statusCode == 200 ? response?.body : null;
      Map<String, dynamic>? responseJson = JsonUtils.decodeMap(responseString);
      if (responseJson != null) {
        return UserCourse.fromJson(responseJson);
      }

      debugPrint('Failed to create user course for key $key. Reason: $url ${response?.statusCode} $responseString');
    }
    return null;
  }

  Future<bool?> deleteUserCourse(String key) async {
    if (Auth2().isLoggedIn && _isLmsAvailable) {
      String? url = '${Config().lmsUrl}/users/courses/$key';
      http.Response? response = await Network().delete(url, auth: Auth2());
      if (response?.statusCode == 200) {
        _userCourses?.removeWhere((courseKey, course) => courseKey == key);
        _userUnits?.removeWhere((courseKey, userUnits) => courseKey == key);
        return true;
      }

      debugPrint('Failed to delete user course for key $key. Reason: $url ${response?.statusCode} ${response?.body}');
      return false;
    }
    return null;
  }

  Future<bool?> dropUserCourse(String key) async {
    if (Auth2().isLoggedIn && _isLmsAvailable) {
      String? url = '${Config().lmsUrl}/users/courses/$key?drop=true';
      http.Response? response = await Network().put(url, auth: Auth2());
      if (response?.statusCode == 200) {
        return true;
      }

      debugPrint('Failed to drop user course for key $key. Reason: $url ${response?.statusCode} ${response?.body}');
      return false;
    }
    return null;
  }

  // UserUnits

  Future<UserUnit?> updateUserCourseProgress(UserResponse userResponse, {required String courseKey, required String moduleKey}) async {
    if (Auth2().isLoggedIn && _isLmsAvailable) {
      String? url = '${Config().lmsUrl}/users/courses/$courseKey/modules/$moduleKey';
      String? post = JsonUtils.encode({
        'timezone_name': _timezoneName,
        'timezone_offset': _timezoneOffset,
        'unit_key': userResponse.unitKey,
        'content_key': userResponse.contentKey,
        'response': userResponse.response,
      });
      http.Response? response = await Network().put(url, auth: Auth2(), body: post);
      String? responseString = response?.statusCode == 200 ? response?.body : null;
      Map<String, dynamic>? responseJson = JsonUtils.decodeMap(responseString);
      if (responseJson != null) {
        return UserUnit.fromJson(responseJson);
      }

      debugPrint('Failed to update user course progress for course $courseKey module $moduleKey. Reason: $url ${response?.statusCode} $responseString');
    }
    return null;
  }

  Future<List<UserUnit>?> loadUserCourseUnits(String courseKey) async {
    if (Auth2().isLoggedIn && _isLmsAvailable) {
      String? url = '${Config().lmsUrl}/users/units/$courseKey';
      http.Response? response = await Network().get(url, auth: Auth2());
      String? responseString = response?.statusCode == 200 ? response?.body : null;
      List<dynamic>? userUnitList = JsonUtils.decodeList(responseString);

      if (userUnitList != null) {
        List<UserUnit> userUnits = UserUnit.listFromJson(userUnitList);
        _userUnits ??= {};
        _userUnits![courseKey] = userUnits;
        return userUnits;
      }

      debugPrint('Failed to load user units for course key $courseKey from net. Reason: $url ${response?.statusCode} $responseString');
    }
    return null;
  }

  // CourseConfig

  // use this to load information about rewards, pauses, and task schedule timing
  Future<CourseConfig?> loadCourseConfig(String key) async {
    if (Auth2().isLoggedIn && _isLmsAvailable) {
      String? url = '${Config().lmsUrl}/custom/course-configs/$key';
      http.Response? response = await Network().get(url, auth: Auth2());
      String? responseString = response?.statusCode == 200 ? response?.body : null;
      Map<String, dynamic>? responseJson = JsonUtils.decodeMap(responseString);
      if (responseJson != null) {
        return CourseConfig.fromJson(responseJson);
      }

      debugPrint('Failed to load course config for course $key from net. Reason: $url ${response?.statusCode} $responseString');
    }
    return null;
  }

  // User history

  // use this to load user content history items
  Future<http.Response?> _loadUserContentHistoryResponse({List<String>? ids}) async {
    if (Auth2().isLoggedIn && _isLmsAvailable) {
      Map<String, String> queryParams = {};
      if (CollectionUtils.isNotEmpty(ids)) {
        queryParams['ids'] = ids!.join(',');
      }
      String? url = '${Config().lmsUrl}/users/contents';
      if (queryParams.isNotEmpty) {
        url = UrlUtils.addQueryParameters(url, queryParams);
      }
      return Network().get(url, auth: Auth2());
    }
    return null;
  }

  Future<List<UserContent>?> loadUserContentHistory({List<String>? ids}) async {
    http.Response? response = await _loadUserContentHistoryResponse(ids:ids);
    return (response?.statusCode == 200) ? UserContent.listFromJson(JsonUtils.decodeList(response?.body)) : null;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
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
          _getTimezoneInfo();
        }
      }
    }
  }

  void _getTimezoneInfo() {
    DateTime now = DateTime.now();
    _timezoneName = now.timeZoneName;
    _timezoneOffset = now.timeZoneOffset.inSeconds;
  }
}
