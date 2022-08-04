
import 'dart:core';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/model/Courses.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Courses with Service implements NotificationsListener {

  static const String notifyTermsChanged = 'edu.illinois.rokwire.courses.terms.changed';

  static const String ExternalAuthorizationHeader = "External-Authorization";
  
  static const String _courseTermsName = "course.terms.json";

  late Directory _appDocDir;
  
  List<CourseTerm>? _terms;
  int _lastTermsCheckTime = 0;

  // Singleton Factory

  static final Courses _instance = Courses._internal();
  factory Courses() => _instance;
  Courses._internal();

  // Service

  void createService() {
    NotificationService().subscribe(this,[
      AppLivecycle.notifyStateChanged,
    ]);
    super.createService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Future<void> initService() async {
    _appDocDir = await getApplicationDocumentsDirectory();
    
    // Init terms
    _terms = await _loadTermsFromCache();
    if (_terms != null) {
      _updateTerms();
    }
    else {
      String? termsJsonString = await _loadTermsStringFromNet();
      _terms = CourseTerm.listFromJson(JsonUtils.decodeList(termsJsonString));
      if (_terms != null) {
        _saveTermsStringToCache(termsJsonString);
      }
    }

    await super.initService();
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

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.resumed) {
      _updateTermsIfNeeded();
    }
  }

  // Terms

  List<CourseTerm>? get terms => _terms;

  CourseTerm? get currentTerm => CourseTerm.currentFromList(_terms);

  File _getTermsCacheFile() => File(join(_appDocDir.path, _courseTermsName));

  Future<String?> _loadTermsStringFromCache() async {
    File termsFile = _getTermsCacheFile();
    return await termsFile.exists() ? await termsFile.readAsString() : null;
  }

  Future<void> _saveTermsStringToCache(String? regionsString) async {
    await _getTermsCacheFile().writeAsString(regionsString ?? '', flush: true);
  }

  Future<List<CourseTerm>?> _loadTermsFromCache() async {
    return CourseTerm.listFromJson(JsonUtils.decodeList(await _loadTermsStringFromCache()));
  }

  Future<String?> _loadTermsStringFromNet() async {
    if (StringUtils.isNotEmpty(Config().gatewayUrl)) {
      Response? response = await Network().get("${Config().gatewayUrl}/termsessions/listcurrent", auth: Auth2(), headers: { ExternalAuthorizationHeader: Auth2().uiucToken?.accessToken });
      return (response?.statusCode == 200) ? response?.body : null;
    }
  }

  Future<void> _updateTerms() async {
    String? termsJsonString = await _loadTermsStringFromNet();
    List<CourseTerm>? terms = CourseTerm.listFromJson(JsonUtils.decodeList(termsJsonString));
    if ((terms != null) && !const DeepCollectionEquality().equals(_terms, terms)) {
      _terms = terms;
      _saveTermsStringToCache(termsJsonString);
      NotificationService().notify(notifyTermsChanged);
    }
  }

  Future<void> _updateTermsIfNeeded() async {
    DateTime? lastCheckMidnight = (0 < _lastTermsCheckTime) ? DateTimeUtils.midnight(DateTime.fromMillisecondsSinceEpoch(_lastTermsCheckTime)) : null;

    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTimeUtils.midnight(now)!;

    // Do it one a week
    if ((lastCheckMidnight == null) || (todayMidnight.difference(lastCheckMidnight).inDays >= 7)) {
      _lastTermsCheckTime = now.millisecondsSinceEpoch;
      await _updateTerms();
    }
  }

  // Courses

  Future<List<Course>?> loadCourses({required String term}) async {
    if (StringUtils.isNotEmpty(Config().gatewayUrl) && StringUtils.isNotEmpty(term) && StringUtils.isNotEmpty(Auth2().uin)) {
      Response? response = await Network().get("${Config().gatewayUrl}/courses/courselist?id=${Auth2().uin}&term=$term", auth: Auth2(), headers: { ExternalAuthorizationHeader: Auth2().uiucToken?.accessToken });
      return Course.listFromJson(JsonUtils.decodeList((response?.statusCode == 200) ? response?.body : null));
    }
 }
}