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

  // Courses

  Future<List<CanvasCourse>?> loadCourses() async {
    if (!_available) {
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/courses';
    http.Response? response = await Network().get(url, headers: _authHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasCourse>? courses = CanvasCourse.listFromJson(JsonUtils.decodeList(responseString));
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

  // Announcements

  Future<List<CanvasDiscussionTopic>?> loadAnnouncementsForCourse(int courseId) async {
    if (!_available) {
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/courses/$courseId/discussion_topics?only_announcements=true';
    http.Response? response = await Network().get(url, headers: _authHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasDiscussionTopic>? announcements = CanvasDiscussionTopic.listFromJson(JsonUtils.decodeList(responseString));
      return announcements;
    } else {
      Log.w('Failed to load canvas course announcements. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Files and Folders

  Future<List<CanvasFileSystemEntity>?> loadFileSystemEntities({int? courseId, int? folderId}) async {
    if (!_available) {
      return null;
    }
    if ((courseId == null) && (folderId == null)) {
      Log.w('Please, specify just one parameter of {courseId} or {folderId} in order to load FS entities.');
      return null;
    }
    if (courseId != null) {
      CanvasFolder? folder = await _loadRootFolder(courseId);
      folderId = folder?.id;
    }
    if (folderId != null) {
      List<CanvasFileSystemEntity> fsEntities = [];
      List<CanvasFolder>? folders = await _loadSubFolders(folderId);
      if (CollectionUtils.isNotEmpty(folders)) {
        fsEntities.addAll(folders!);
      }
      List<CanvasFile>? files = await _loadFiles(folderId);
      if (CollectionUtils.isNotEmpty(files)) {
        fsEntities.addAll(files!);
      }

      // Sort by name
      if (CollectionUtils.isNotEmpty(fsEntities)) {
        fsEntities.sort((CanvasFileSystemEntity first, CanvasFileSystemEntity second) {
          String? firstName = first.entityName;
          String? secondName = second.entityName;
          if (firstName != null && secondName != null) {
            return firstName.toLowerCase().compareTo(secondName.toLowerCase());
          } else if (firstName != null) {
            return -1;
          } else if (secondName != null) {
            return 1;
          } else {
            return 0;
          }
        });
      }
      return fsEntities;
    } else {
      Log.w('Missing canvas folderId.');
      return null;
    }
  }

  Future<CanvasFolder?> _loadRootFolder(int courseId) async {
    if (!_available) {
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/courses/$courseId/folders/by_path';
    http.Response? response = await Network().get(url, headers: _authHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasFolder>? folders = CanvasFolder.listFromJson(JsonUtils.decodeList(responseString));
      return CollectionUtils.isNotEmpty(folders) ? folders!.first : null;
    } else {
      Log.w('Failed to load canvas root folder for course {$courseId}. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<List<CanvasFolder>?> _loadSubFolders(int folderId) async {
    if (!_available) {
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/folders/$folderId/folders';
    http.Response? response = await Network().get(url, headers: _authHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasFolder>? folders = CanvasFolder.listFromJson(JsonUtils.decodeList(responseString));
      return folders;
    } else {
      Log.w('Failed to load canvas folders for folder {$folderId}. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<List<CanvasFile>?> _loadFiles(int folderId) async {
    if (!_available) {
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/folders/$folderId/files';
    http.Response? response = await Network().get(url, headers: _authHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasFile>? files = CanvasFile.listFromJson(JsonUtils.decodeList(responseString));
      return files;
    } else {
      Log.w('Failed to load canvas files for folder {$folderId}. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Collaborations

  Future<List<CanvasCollaboration>?> loadCollaborations(int courseId) async {
    if (!_available) {
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/courses/$courseId/collaborations';
    http.Response? response = await Network().get(url, headers: _authHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasCollaboration>? collaborations = CanvasCollaboration.listFromJson(JsonUtils.decodeList(responseString));
      return collaborations;
    } else {
      Log.w('Failed to load canvas collaborations. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Calendar

  Future<List<CanvasCalendarEvent>?> loadCalendarEvents(int courseId, {DateTime? startDate, DateTime? endDate}) async {
    if (!_available) {
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/calendar_events?context_codes[]=course_$courseId&per_page=50';
    if (startDate != null) {
      DateTime startDateUtc = startDate.toUtc();
      String? formattedDate = DateTimeUtils.utcDateTimeToString(startDateUtc);
      if (StringUtils.isNotEmpty(formattedDate)) {
        url += '&start_date=$formattedDate';
      }
    }
    if (endDate != null) {
      DateTime endDateUtc = endDate.toUtc();
      String? formattedDate = DateTimeUtils.utcDateTimeToString(endDateUtc);
      if (StringUtils.isNotEmpty(formattedDate)) {
        url += '&end_date=$formattedDate';
      }
    }
    http.Response? response = await Network().get(url, headers: _authHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasCalendarEvent>? calendarEvents = CanvasCalendarEvent.listFromJson(JsonUtils.decodeList(responseString));
      return calendarEvents?.where((element) => (element.hidden == false)).toList();
    } else {
      Log.w('Failed to load canvas calendar events for course {$courseId}. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Account Notifications

  Future<List<CanvasAccountNotification>?> loadAccountNotifications() async {
    if (!_available) {
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/accounts/2/users/self/account_notifications';
    http.Response? response = await Network().get(url, headers: _authHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasAccountNotification>? calendarEvents = CanvasAccountNotification.listFromJson(JsonUtils.decodeList(responseString));
      return calendarEvents;
    } else {
      Log.w('Failed to load canvas user notifications. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Helpers

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