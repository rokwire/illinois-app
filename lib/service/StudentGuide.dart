import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/utils/Utils.dart';

class StudentGuide with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.student.guide.changed";

  List<dynamic> _contentList;
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
    _contentList = await _loadContentJsonFromAssets();
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
          _loadContentJsonFromAssets().then((List<dynamic> result) {
            contentList = result;
          });
        }
      }
    }
  }

  // Implementation

  Future<List<dynamic>> _loadContentJsonFromAssets() async {
    String jsonContent;
    try { jsonContent = await rootBundle.loadString('assets/student.guide.json'); }
    catch (e) { print(e?.toString()); }
    return AppJson.decodeList(jsonContent);
  }

  // Content

  List<dynamic> get contentList {
    return _contentList;
  }

  set contentList(List<dynamic> value) {
    if (!DeepCollectionEquality().equals(_contentList, value)) {
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

}