import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:illinois/model/UserData.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class StudentGuide with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.student.guide.changed";

  static const String _cacheFileName = "student.guide.json";

  List<dynamic> _contentList;
  LinkedHashMap<String, Map<String, dynamic>> _contentMap;

  File          _cacheFile;
  DateTime      _pausedDateTime;

  static final StudentGuide _service = StudentGuide._internal();
  StudentGuide._internal();

  factory StudentGuide() {
    return _service;
  }

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _cacheFile = await _getCacheFile();
    _contentList = await _loadContentJsonFromCache() ?? await _loadContentJsonFromAssets();
    _contentMap = _buildContentMap(_contentList);
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          //TBD: refresh
        }
      }
    }
  }

  // Implementation

  Future<File> _getCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _cacheFileName);
    return File(cacheFilePath);
  }

  Future<String> _loadContentStringFromCache() async {
    return (await _cacheFile?.exists() == true) ? await _cacheFile.readAsString() : null;
  }

  Future<void> _saveContentStringToCache(String value) async {
    try {
      if (value != null) {
        await _cacheFile?.writeAsString(value, flush: true);
      }
      else {
        await _cacheFile?.delete();
      }
    }
    catch(e) { print(e?.toString()); }
  }

  Future<List<dynamic>> _loadContentJsonFromCache() async {
    return AppJson.decodeList(await _loadContentStringFromCache());
  }

  Future<String> _loadContentStringFromAssets() async {
    try { return await rootBundle.loadString('assets/student.guide.json'); }
    catch (e) { print(e?.toString()); }
    return null;
  }

  Future<List<dynamic>> _loadContentJsonFromAssets() async {
    return AppJson.decodeList(await _loadContentStringFromAssets());
  }

  static LinkedHashMap<String, Map<String, dynamic>> _buildContentMap(List<dynamic> contentList) {
    LinkedHashMap<String, Map<String, dynamic>> contentMap;
    if (contentList != null) {
      contentMap = LinkedHashMap<String, Map<String, dynamic>>();
      for (dynamic contentEntry in contentList) {
        Map<String, dynamic> mapEntry = AppJson.mapValue(contentEntry);
        String id = (mapEntry != null) ? AppJson.stringValue(mapEntry['id']) : null;
        if (id != null) {
          contentMap[id] = mapEntry;
        }
      }
    }
    return contentMap;
  }

  // Content

  List<dynamic> get contentList {
    return _contentList;
  }

  void _applyContentList(List<dynamic> value) {
    if ((value != null) && !DeepCollectionEquality().equals(_contentList, value)) {
      _contentList = value;
      _contentMap = _buildContentMap(value);
      NotificationService().notify(notifyChanged);
    }
  }

  Map<String, dynamic> entryById(String id) {
    return (_contentMap != null) ? _contentMap[id] : null;
  }

  dynamic entryValue(Map<String, dynamic> entry, String key) {
    while (entry != null) {
      dynamic value = entry[key];
      if (value != null) {
        return value;
      }
      entry = entryById(AppJson.stringValue(entry['content_ref']));
    }
    return null;
  }

  List<dynamic> get promotedList {
    if (_contentList != null) {
      List<dynamic> promotedList = <dynamic>[];
      for (dynamic entry in _contentList) {
        if (_isEntryPromoted(AppJson.mapValue(entry))) {
          promotedList.add(entry);
        }
      }
      return promotedList;
    }
    return null;
  }

  bool _isEntryPromoted(Map<String, dynamic> entry) {
    Map<String, dynamic> promotion = (entry != null) ? AppJson.mapValue(entryValue(entry, 'promotion')) : null;
    return (promotion != null) ?
      _checkPromotionInterval(promotion) &&
      _checkPromotionRoles(promotion) &&
      _checkPromotionCard(promotion) :
    false;
  }

  static bool _checkPromotionInterval(Map<String, dynamic> promotion) {
    Map<String, dynamic> interval = (promotion != null) ? AppJson.mapValue(promotion['interval']) : null;
    if (interval != null) {
      DateTime now = DateTime.now().toUtc();
      
      String startString = AppJson.stringValue(interval['start']);
      DateTime startTime = (startString != null) ? DateTime.tryParse(startString)?.toUtc() : null;
      if ((startTime != null) && now.isBefore(startTime)) {
        return false;
      }
      
      String endString = AppJson.stringValue(interval['end']);
      DateTime endTime = (endString != null) ? DateTime.tryParse(endString)?.toUtc() : null;
      if ((endTime != null) && now.isAfter(endTime)) {
        return false;
      }
    }
    return true;
  }

  static bool _checkPromotionRoles(Map<String, dynamic> promotion) {
    dynamic roles = (promotion != null) ? promotion['roles'] : null;
    return (roles != null) ? AppBoolExpr.eval(roles, (String argument) {
      UserRole userRole = UserRole.fromString(argument);
      return (userRole != null) ? (User().roles?.contains(userRole) ?? false) : null;
    }) : true; 
  }

  static bool _checkPromotionCard(Map<String, dynamic> promotion) {
    Map<String, dynamic> card = (promotion != null) ? AppJson.mapValue(promotion['card']) : null;
    if (card != null) {
      dynamic cardRole = card['role'];
      if ((cardRole != null) && !AppBoolExpr.eval(cardRole, (String role) { return Auth().authCard?.role?.toLowerCase() == role?.toLowerCase(); })) {
        return false;
      }

      dynamic cardStudentLevel = card['student_level'];
      if ((cardStudentLevel != null) && !AppBoolExpr.eval(cardStudentLevel, (String studentLevel) { return Auth().authCard?.studentLevel?.toLowerCase() == studentLevel?.toLowerCase(); })) {
        return false;
      }
    }
    return true;
  }

  // Debug

  Future<String> getContentString() async {
    return await _loadContentStringFromCache() ?? await _loadContentStringFromAssets();
  }

  Future<String> setContentString(String value) async {
    if (value != null) {
      List<dynamic> contentList = AppJson.decodeList(value);
      if (contentList != null) {
        await _saveContentStringToCache(value);
        _applyContentList(contentList);
        return value;
      }
      else {
        return null;
      }
    }
    else {
      await _saveContentStringToCache(null);
      value = await _loadContentStringFromAssets();
      _applyContentList(AppJson.decodeList(value));
      return value;
    }
  }
}