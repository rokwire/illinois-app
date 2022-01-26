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

  // APIs

  Future<List<CanvasCourse>?> loadCourses() async {
    if (!_available) {
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/courses';
    http.Response? response = await Network().get(url, headers: _authHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasCourse>? courses = CanvasCourse.fromJsonList(JsonUtils.decodeList(responseString));
      return courses;
    } else {
      Log.w('Failed to load canvas courses. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<CanvasCourse?> loadCourse(int? courseId, {CanvasIncludeInfo? includeInfo}) async {
    if (!_available) {
      return null;
    }
    if (courseId == null) {
      Log.d('Failed to load canvas course - missing course id.');
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/courses/$courseId';
    String? includeValue = _includeInfoToString(includeInfo);
    if (includeValue != null) {
      url += '?include[]=$includeValue';
    }
    http.Response? response = await Network().get(url, headers: _authHeaders);
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

  Map<String, String>? get _authHeaders {
    if (!_available) {
      return null;
    }
    return {HttpHeaders.authorizationHeader: "${Config().canvasTokenType} ${Config().canvasToken}"};
  }

  bool get _available {
    return StringUtils.isNotEmpty(Config().canvasTokenType) && StringUtils.isNotEmpty(Config().canvasToken) && StringUtils.isNotEmpty(Auth2().netId);
  }

  static String? _includeInfoToString(CanvasIncludeInfo? include) {
    switch (include) {
      case CanvasIncludeInfo.syllabus:
        return 'syllabus_body';
      default:
        return null;
    }
  }
}

enum CanvasIncludeInfo { syllabus }