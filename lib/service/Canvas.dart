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
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
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
  static const String notifyCanvasEventDetail = "edu.illinois.rokwire.canvas.event.detail";

  static const String _canvasCoursesCacheFileName = "canvasCourses.json";

  List<CanvasCourse>? _courses;
  List<Map<String, dynamic>>? _canvasEventDetailCache;

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
    super.createService();
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Auth2.notifyLoginChanged,
      Connectivity.notifyStatusChanged,
      Storage.notifySettingChanged,
      DeepLink.notifyUri,
    ]);
    _canvasEventDetailCache = <Map<String, dynamic>>[];
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

  @override
  void initServiceUI() {
    _processCachedDeepLinkDetails();
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

  List<int>? get _medicineCoursesAccountIds => Config().canvasMedicineCoursesAccountIds;

  List<CanvasCourse>? get courses => _courses;

  List<CanvasCourse>? get medicineCourses {
    List<CanvasCourse>? medicineCourses;
    if (CollectionUtils.isNotEmpty(courses) && CollectionUtils.isNotEmpty(_medicineCoursesAccountIds)) {
      medicineCourses = <CanvasCourse>[];
      for (CanvasCourse course in courses!) {
        int? courseAccountId = course.accountId;
        if ((courseAccountId != null) && _medicineCoursesAccountIds!.contains(courseAccountId)) {
          medicineCourses.add(course);
        }
      }
    }
    return medicineCourses;
  }

  List<CanvasCourse>? get giesCourses {
    List<CanvasCourse>? giesCourses;
    if (CollectionUtils.isNotEmpty(courses)) {
      giesCourses = <CanvasCourse>[];
      for (CanvasCourse course in courses!) {
        int? courseAccountId = course.accountId;
        if ((courseAccountId == null) ||
            CollectionUtils.isEmpty(_medicineCoursesAccountIds) ||
            !_medicineCoursesAccountIds!.contains(courseAccountId)) {
          giesCourses.add(course);
        }
      }
    }
    return giesCourses;
  }

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

  Future<CanvasCourse?> loadCourse(int? courseId, {CanvasIncludeInfo? includeInfo}) async {
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
      String? includeValue = _includeInfoToString(includeInfo);
      if (includeValue != null) {
        url += '?include[]=$includeValue';
      }
      url = _masquerade(url);
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
      Log.w('Failed to load canvas course. Response from $url:\n$responseCode: $responseString');
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
      url = _masquerade('${Config().canvasUrl}/api/v1/courses/$courseId/assignment_groups?include[]=assignments&include[]=submission');
      response = await Network().get(url, headers: _canvasAuthHeaders);
    } else {
      url = '${Config().lmsUrl}/courses/$courseId/assignment-groups?include=assignments,submission';
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

  // Announcements

  Future<List<CanvasDiscussionTopic>?> loadAnnouncementsForCourse(int courseId) async {
    if (!_useCanvasApi) { // Load this entities only when we use canvas API directly from app
      return null;
    }
    String? url = _masquerade('${Config().canvasUrl}/api/v1/courses/$courseId/discussion_topics?only_announcements=true');
    if (StringUtils.isEmpty(url)) {
      Log.w('Failed to masquerade a canvas user - missing net id.');
      return null;
    }
    http.Response? response = await Network().get(url, headers: _canvasAuthHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasDiscussionTopic>? announcements = CanvasDiscussionTopic.listFromJson(JsonUtils.decodeList(responseString));
      return announcements;
    } else {
      Log.w('Failed to load canvas course announcements ($url). Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Files and Folders

  Future<List<CanvasFileSystemEntity>?> loadFileSystemEntities({int? courseId, int? folderId}) async {
    if (!_useCanvasApi) { // Load this entities only when we use canvas API directly from app
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
      List<CanvasFileSystemEntity> fsEntities = <CanvasFileSystemEntity>[];
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
    if (!_useCanvasApi) { // Load this entities only when we use canvas API directly from app
      return null;
    }
    String? url = _masquerade('${Config().canvasUrl}/api/v1/courses/$courseId/folders/by_path');
    if (StringUtils.isEmpty(url)) {
      Log.w('Failed to masquerade a canvas user - missing net id.');
      return null;
    }
    http.Response? response = await Network().get(url, headers: _canvasAuthHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasFolder>? folders = CanvasFolder.listFromJson(JsonUtils.decodeList(responseString));
      return CollectionUtils.isNotEmpty(folders) ? folders!.first : null;
    } else {
      Log.w('Failed to load canvas root folder for course {$courseId} ($url). Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<List<CanvasFolder>?> _loadSubFolders(int folderId) async {
    if (!_useCanvasApi) { // Load this entities only when we use canvas API directly from app
      return null;
    }
    String? url = _masquerade('${Config().canvasUrl}/api/v1/folders/$folderId/folders');
    if (StringUtils.isEmpty(url)) {
      Log.w('Failed to masquerade a canvas user - missing net id.');
      return null;
    }
    http.Response? response = await Network().get(url, headers: _canvasAuthHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasFolder>? folders = CanvasFolder.listFromJson(JsonUtils.decodeList(responseString));
      return folders;
    } else {
      Log.w('Failed to load canvas folders for folder {$folderId} ($url). Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<List<CanvasFile>?> _loadFiles(int folderId) async {
    if (!_useCanvasApi) { // Load this entities only when we use canvas API directly from app
      return null;
    }
    String? url = _masquerade('${Config().canvasUrl}/api/v1/folders/$folderId/files');
    if (StringUtils.isEmpty(url)) {
      Log.w('Failed to masquerade a canvas user - missing net id.');
      return null;
    }
    http.Response? response = await Network().get(url, headers: _canvasAuthHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasFile>? files = CanvasFile.listFromJson(JsonUtils.decodeList(responseString));
      return files;
    } else {
      Log.w('Failed to load canvas files for folder {$folderId} ($url). Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Collaborations

  Future<List<CanvasCollaboration>?> loadCollaborations(int courseId) async {
    if (!_useCanvasApi) { // Load this entities only when we use canvas API directly from app
      return null;
    }
    String? url = _masquerade('${Config().canvasUrl}/api/v1/courses/$courseId/collaborations');
    if (StringUtils.isEmpty(url)) {
      Log.w('Failed to masquerade a canvas user - missing net id.');
      return null;
    }
    http.Response? response = await Network().get(url, headers: _canvasAuthHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasCollaboration>? collaborations = CanvasCollaboration.listFromJson(JsonUtils.decodeList(responseString));
      return collaborations;
    } else {
      Log.w('Failed to load canvas collaborations ($url). Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Calendar

  Future<List<CanvasCalendarEvent>?> loadCalendarEvents(
      {required int courseId, CanvasCalendarEventType? type, DateTime? startDate, DateTime? endDate}) async {
    if (!_useCanvasApi) { // Load this entities only when we use canvas API directly from app
      return null;
    }
    String? url = '${Config().canvasUrl}/api/v1/calendar_events?context_codes[]=course_$courseId&per_page=50';
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
    String? typeKeyString = CanvasCalendarEvent.typeToKeyString(type);
    if (StringUtils.isNotEmpty(typeKeyString)) {
      url += '&type=$typeKeyString';
    }
    url = _masquerade(url);
    if (StringUtils.isEmpty(url)) {
      Log.w('Failed to masquerade a canvas user - missing net id.');
      return null;
    }
    http.Response? response = await Network().get(url, headers: _canvasAuthHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasCalendarEvent>? calendarEvents = CanvasCalendarEvent.listFromJson(JsonUtils.decodeList(responseString));
      return calendarEvents?.where((element) => ((element.hidden == false) || (element.hidden == null))).toList();
    } else {
      Log.w('Failed to load canvas calendar events for course {$courseId} ($url). Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<CanvasCalendarEvent?> loadCalendarEvent(int eventId) async {
    if (!_useCanvasApi) { // Load this entities only when we use canvas API directly from app
      return null;
    }
    String? url = _masquerade('${Config().canvasUrl}/api/v1/calendar_events/$eventId');
    if (StringUtils.isEmpty(url)) {
      Log.w('Failed to masquerade a canvas user - missing net id.');
      return null;
    }
    http.Response? response = await Network().get(url, headers: _canvasAuthHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      CanvasCalendarEvent? event = CanvasCalendarEvent.fromJson(JsonUtils.decode(responseString));
      return event;
    } else {
      Log.w('Failed to load canvas calendar event with id {$eventId} ($url). Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Account Notifications

  Future<List<CanvasAccountNotification>?> loadAccountNotifications() async {
    if (!_useCanvasApi) { // Load this entities only when we use canvas API directly from app
      return null;
    }
    String? url = _masquerade('${Config().canvasUrl}/api/v1/accounts/2/users/self/account_notifications');
    if (StringUtils.isEmpty(url)) {
      Log.w('Failed to masquerade a canvas user - missing net id.');
      return null;
    }
    http.Response? response = await Network().get(url, headers: _canvasAuthHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<CanvasAccountNotification>? notifications = CanvasAccountNotification.listFromJson(JsonUtils.decodeList(responseString));
      return notifications;
    } else {
      Log.w('Failed to load canvas user notifications ($url). Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Modules

  Future<List<CanvasModule>?> loadModules(int courseId) async {
    if (!_useCanvasApi) { // Load this entities only when we use canvas API directly from app
      return null;
    }
    String? url = _masquerade('${Config().canvasUrl}/api/v1/courses/$courseId/modules');
    if (StringUtils.isEmpty(url)) {
      Log.w('Failed to masquerade a canvas user - missing net id.');
      return null;
    }
    http.Response? response = await Network().get(url, headers: _canvasAuthHeaders);
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
      Log.w('Failed to load canvas modules for course {$courseId} ($url). Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<List<CanvasModuleItem>?> loadModuleItems({required int courseId, required int moduleId}) async {
    if (!_useCanvasApi) { // Load this entities only when we use canvas API directly from app
      return null;
    }
    String? url = _masquerade('${Config().canvasUrl}/api/v1/courses/$courseId/modules/$moduleId/items');
    if (StringUtils.isEmpty(url)) {
      Log.w('Failed to masquerade a canvas user - missing net id.');
      return null;
    }
    http.Response? response = await Network().get(url, headers: _canvasAuthHeaders);
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
      Log.w('Failed to load canvas module items for course {$courseId} and module {$moduleId} ($url). Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Error Reports

  Future<bool> reportError({required String subject, String? description}) async {
    if (!_useCanvasApi) { // Load this entities only when we use canvas API directly from app
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
    String? url = _masquerade('${Config().canvasUrl}/api/v1/error_reports');
    if (StringUtils.isEmpty(url)) {
      Log.w('Failed to masquerade a canvas user - missing net id.');
      return false;
    }
    http.Response? response = await Network().post(url, body: errorBody, headers: _canvasAuthHeaders);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Log.d('Canvas: Successfully reported error.');
      return true;
    } else {
      Log.w('Failed to report error ($url). Response:\n$responseCode: $responseString');
      return false;
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

  // Event Detail Deep Links

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

  static String? _includeInfoToString(CanvasIncludeInfo? include) {
    switch (include) {
      case CanvasIncludeInfo.syllabus:
        return 'syllabus_body';
      default:
        return null;
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
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
    } else if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(param);
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
          _updateCourses();
        }
      }
    }
  }
}

enum CanvasIncludeInfo { syllabus }