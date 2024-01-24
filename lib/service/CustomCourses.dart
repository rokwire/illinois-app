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
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:http/http.dart' as http;

import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CustomCourses with Service implements NotificationsListener {

  static const String notifyCoursesUpdated  = "edu.illinois.rokwire.canvas.courses.updated";

  static const String _canvasCoursesCacheFileName = "canvasCourses.json";

  List<Course>? _courses;

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
      AppLivecycle.notifyStateChanged,
      Auth2.notifyLoginChanged,
      Connectivity.notifyStatusChanged,
      Storage.notifySettingChanged,
      DeepLink.notifyUri,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config(), Auth2()]);
  }

  // Accessories

  bool get _isLmsAvailable => StringUtils.isNotEmpty(Config().lmsUrl);

  List<Course>? get courses => _courses;

  // Courses

  Future<List<Course>?> loadCourses() async {
    if (_courses == null) {
      if (Auth2().isLoggedIn &&  _isLmsAvailable) {
        String? url = '${Config().lmsUrl}/custom/courses';
        http.Response? response = await Network().get(url, auth: Auth2());
        String? responseString = response?.statusCode == 200 ? response?.body : null;
        List<dynamic>? courseList = JsonUtils.decodeList(responseString);

        if (courseList != null) {
          _courses?.clear();
          _courses ??= [];
          _courses!.addAll(Course.listFromJson(courseList));
          return _courses;
        } else {
          debugPrint('Failed to load custom courses from net. Reason: $url ${response?.statusCode} $responseString');
        }
      }
      return null;
    }
    return _courses;
  }

  // UserCourses



  // UserUnits

  // Event Detail Deep Links

  void _onDeepLinkUri(Uri? uri) {
    //TODO
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    // if (name == AppLivecycle.notifyStateChanged) {
    //   _onAppLivecycleStateChanged(param);
    // } else if (name == Auth2.notifyLoginChanged) {
    //   _updateCourses();
    // } else if (name == Connectivity.notifyStatusChanged) {
    //   if (Connectivity().isNotOffline) {
    //     _updateCourses();
    //   }
    // } else if (name == Storage.notifySettingChanged) {
    //   if (param == Storage.debugUseCanvasLmsKey) {
    //     _updateCourses();
    //   }
    // } else if (name == DeepLink.notifyUri) {
    //   _onDeepLinkUri(param);
    // }
  }

  // void _onAppLivecycleStateChanged(AppLifecycleState? state) {
  //   if (state == AppLifecycleState.paused) {
  //     _pausedDateTime = DateTime.now();
  //   }
  //   else if (state == AppLifecycleState.resumed) {
  //     if (_pausedDateTime != null) {
  //       Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
  //       if (Config().refreshTimeout < pausedDuration.inSeconds) {
  //         _updateCourses();
  //       }
  //     }
  //   }
  // }
}
