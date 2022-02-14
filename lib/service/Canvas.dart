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
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:http/http.dart' as http;

import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/deep_link.dart';

class Canvas with Service implements NotificationsListener{
  static const String notifyCanvasEventDetail = "edu.illinois.rokwire.canvas.event.detail";
  List<Map<String, dynamic>>? _canvasEventDetailCache;
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


  @override
  void createService() {
    super.createService();
    NotificationService().subscribe(this,[
      DeepLink.notifyUri,
    ]);
    _canvasEventDetailCache = [];
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  void initServiceUI() {
    _processCachedDeepLinkDetails();
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

  Future<List<CanvasCalendarEvent>?> loadCalendarEvents({required int courseId, DateTime? startDate, DateTime? endDate}) async {
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

  Future<CanvasCalendarEvent?> loadCalendarEvent(int eventId) async {
    if (!_available) {
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/calendar_events/$eventId';
    http.Response? response = await Network().get(url, headers: _authHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      CanvasCalendarEvent? event = CanvasCalendarEvent.fromJson(JsonUtils.decode(responseString));
      return event;
    } else {
      Log.w('Failed to load canvas calendar event with id {$eventId}. Response:\n$responseCode: $responseString');
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
      List<CanvasAccountNotification>? notifications = CanvasAccountNotification.listFromJson(JsonUtils.decodeList(responseString));
      return notifications;
    } else {
      Log.w('Failed to load canvas user notifications. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Modules

  Future<List<CanvasModule>?> loadModules(int courseId) async {
    if (!_available) {
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/courses/$courseId/modules';
    http.Response? response = await Network().get(url, headers: _authHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasModule>? modules = CanvasModule.listFromJson(JsonUtils.decodeList(responseString));

      // Sort by position
      if (CollectionUtils.isNotEmpty(modules)) {
        modules!.sort((CanvasModule first, CanvasModule second) {
          int firstPosition = first.position ?? 0;
          int secondPosition = second.position ?? 0;
          return firstPosition.compareTo(secondPosition);
        });
      }

      return modules;
    } else {
      Log.w('Failed to load canvas modules for course {$courseId}. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<List<CanvasModuleItem>?> loadModuleItems({required int courseId, required int moduleId}) async {
    if (!_available) {
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/courses/$courseId/modules/$moduleId/items';
    http.Response? response = await Network().get(url, headers: _authHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasModuleItem>? moduleItems = CanvasModuleItem.listFromJson(JsonUtils.decodeList(responseString));

      // Sort by position
      if (CollectionUtils.isNotEmpty(moduleItems)) {
        moduleItems!.sort((CanvasModuleItem first, CanvasModuleItem second) {
          int firstPosition = first.position ?? 0;
          int secondPosition = second.position ?? 0;
          return firstPosition.compareTo(secondPosition);
        });
      }

      return moduleItems;
    } else {
      Log.w('Failed to load canvas module items for course {$courseId} and module {$moduleId}. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Error Reports

  Future<bool> reportError({required String subject, String? description}) async {
    if (!_available) {
      return false;
    }
    if (StringUtils.isEmpty(subject)) {
      Log.w('Please, provide error subject');
      return false;
    }
    CanvasErrorReport report = CanvasErrorReport(subject: subject);
    if (StringUtils.isNotEmpty(description)) {
      report.comments = description;
    }
    report.email = Auth2().email;
    String? errorBody = JsonUtils.encode(report.toJson());
    String url = '${Config().canvasUrl}/api/v1/error_reports';
    http.Response? response = await Network().post(url, headers: _authHeaders, body: errorBody);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Log.d('Canvas: Successfully reported error.');
      return true;
    } else {
      Log.w('Failed to report error. Response:\n$responseCode: $responseString');
      return false;
    }
  }

  // Assignments

  Future<List<CanvasAssignmentGroup>?> loadAssignmentGroups(int courseId) async {
    if (!_available) {
      return null;
    }
    String url = '${Config().canvasUrl}/api/v1/courses/$courseId/assignment_groups?include[]=assignments';
    http.Response? response = await Network().get(url, headers: _authHeaders);
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

  // Deep Links

  String get canvasEventDetailUrl => '${DeepLink().appUrl}/canvas_event_detail';

  void _onDeepLinkUri(Uri? uri) {
    if (uri != null) {
      Uri? eventUri = Uri.tryParse(canvasEventDetailUrl);
      if ((eventUri != null) && (eventUri.scheme == uri.scheme) && (eventUri.authority == uri.authority) && (eventUri.path == uri.path)) {
        try {
          _handleDetail(uri.queryParameters.cast<String, dynamic>());
        } catch (e) {
          print(e.toString());
        }
      }
    }
  }

  void _handleDetail(Map<String, dynamic>? params) {
    if ((params != null) && params.isNotEmpty) {
      if (_canvasEventDetailCache != null) {
        _cacheCanvasEventDetail(params);
      } else {
        _processDetail(params);
      }
    }
  }

  void _processDetail(Map<String, dynamic> params) {
    NotificationService().notify(notifyCanvasEventDetail, params);
  }

  void _cacheCanvasEventDetail(Map<String, dynamic> params) {
    _canvasEventDetailCache?.add(params);
  }

  void _processCachedDeepLinkDetails() {
    if (_canvasEventDetailCache != null) {
      List<Map<String, dynamic>> gameDetailsCache = _canvasEventDetailCache!;
      _canvasEventDetailCache = null;

      for (Map<String, dynamic> gameDetail in gameDetailsCache) {
        _processDetail(gameDetail);
      }
    }
  }

  // Notifications

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(param);
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
    return StringUtils.isNotEmpty(Config().canvasTokenType) &&
        StringUtils.isNotEmpty(Config().canvasToken) &&
        StringUtils.isNotEmpty(Auth2().netId);
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