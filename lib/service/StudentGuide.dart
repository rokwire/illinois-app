import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class StudentGuide with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.student.guide.changed";

  static const String _cacheFileName = "student.guide.json";

  List<dynamic> _contentList;

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

  // Content

  List<dynamic> get contentList {
    return _contentList;
  }

  void _applyContentList(List<dynamic> value) {
    if ((value != null) && !DeepCollectionEquality().equals(_contentList, value)) {
      _contentList = value;
      NotificationService().notify(notifyChanged);
    }
  }


  Map<String, dynamic> entryById(String id) {
    if (_contentList != null) {
      for (dynamic entry in _contentList) {
        if ((entry is Map) && (AppJson.stringValue(entry['id']) == id)) {
          try { return entry.cast<String, dynamic>(); }
          catch(e) { print(e?.toString()); }
        }
      }
    }
    return null;
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