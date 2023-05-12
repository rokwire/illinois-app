
import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/service/Storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class StudentCourses with Service implements NotificationsListener {

  static const String notifyTermsChanged = 'edu.illinois.rokwire.student_courses.terms.changed';
  static const String notifySelectedTermChanged = 'edu.illinois.rokwire.student_courses.selected.term.changed';
  static const String notifyCachedCoursesChanged = 'edu.illinois.rokwire.student_courses.cache.changed';

  static const String _courseTermsName = "course.terms.json";
  static const String _courseDebugContentName = "course.debug.content.json";
  static const String _requireAdaSetting = 'edu.illinois.rokwire.settings.student_course.require_ada';

  late Directory _appDocDir;
  
  List<StudentCourseTerm>? _terms;
  List<StudentCourse>? _debugCourses;
  int _lastTermsCheckTime = 0;
  String? _selectedTermId;

  Map<String, List<StudentCourse>> _courses = <String, List<StudentCourse>>{};
  Set<Completer<List<StudentCourse>?>>? _loadCoursesCompleters;
  DateTime? _pausedDateTime;

  // Singleton Factory

  static final StudentCourses _instance = StudentCourses._internal();
  factory StudentCourses() => _instance;
  StudentCourses._internal();

  // Service

  void createService() {
    NotificationService().subscribe(this,[
      Auth2.notifyLoginChanged,
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
    _selectedTermId = Storage().selectedCourseTermId;
    
    // Init terms
    if (_canLoadTerms) {
      _terms = await _loadTermsFromCache();
      if (_terms != null) {
        _updateTerms();
      }
      else {
        String? termsJsonString = await _loadTermsStringFromNet();
        _terms = StudentCourseTerm.listFromJson(JsonUtils.decodeList(termsJsonString));
        if (_terms != null) {
          _saveTermsStringToCache(termsJsonString);
        }
      }
    }

    // Init debug courses
    _debugCourses = useDebugCoursesContent ? StudentCourse.listFromJson(JsonUtils.decodeList(await getDebugCoursesRawContent())) : null;

    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Config(), Auth2()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      _onLoginChanged();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onLoginChanged() {
    _updateCourses();
    _updateTerms();
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateCourses(true);
        }
      }
      _updateTermsIfNeeded();
    }
  }

  // Terms

  List<StudentCourseTerm>? get terms => _terms;

  File _getTermsCacheFile() => File(join(_appDocDir.path, _courseTermsName));

  Future<String?> _loadTermsStringFromCache() async {
    File termsFile = _getTermsCacheFile();
    return await termsFile.exists() ? await termsFile.readAsString() : null;
  }

  Future<void> _saveTermsStringToCache(String? regionsString) async {
    await _getTermsCacheFile().writeAsString(regionsString ?? '', flush: true);
  }

  Future<List<StudentCourseTerm>?> _loadTermsFromCache() async {
    return StudentCourseTerm.listFromJson(JsonUtils.decodeList(await _loadTermsStringFromCache()));
  }

  bool get _canLoadTerms =>
    StringUtils.isNotEmpty(Config().gatewayUrl) && (Gateway().externalAuthorizationHeaderValue != null);

  Future<String?> _loadTermsStringFromNet() async {
    if (_canLoadTerms) {
      Response? response = await Network().get("${Config().gatewayUrl}/termsessions/listcurrent", auth: Auth2(), headers: Gateway().externalAuthorizationHeader);
      return (response?.statusCode == 200) ? response?.body : null;
    }
    return null;
  }

  Future<void> _updateTermsIfNeeded() async {
    if (_canLoadTerms) {
      DateTime? lastCheckMidnight = (0 < _lastTermsCheckTime) ? DateTimeUtils.midnight(DateTime.fromMillisecondsSinceEpoch(_lastTermsCheckTime)) : null;

      DateTime now = DateTime.now();
      DateTime todayMidnight = DateTimeUtils.midnight(now)!;

      // Do it one a week
      if ((_terms == null) || (lastCheckMidnight == null) || (todayMidnight.difference(lastCheckMidnight).inDays >= 7)) {
        _lastTermsCheckTime = now.millisecondsSinceEpoch;
        await _updateTerms();
      }
    }
    else if (terms != null) {
      _applyTerms(null);
    }
  }

  Future<void> _updateTerms() async {
    if (_canLoadTerms) {
      String? termsJsonString = await _loadTermsStringFromNet();
      List<StudentCourseTerm>? terms = StudentCourseTerm.listFromJson(JsonUtils.decodeList(termsJsonString));
      if ((terms != null) && !const DeepCollectionEquality().equals(_terms, terms)) {
        _applyTerms(terms, termsJsonString);
      }
    }
    else if (_terms != null) {
      _applyTerms(null);
    }
  }

  void _applyTerms(List<StudentCourseTerm>? terms, [ String? termsJsonString ]) {
    _terms = terms;
    _saveTermsStringToCache(termsJsonString);
    NotificationService().notify(notifyTermsChanged);
    _updateSelectedTermId();
  }

  // Selected Term

  String? get selectedTermId => _selectedTermId;

  set selectedTermId(String? value) {
    if ((value != null) && (value == _currentTermId)) {
      value = null;
    }
    if (_selectedTermId != value) {
      Storage().selectedCourseTermId = _selectedTermId = value;
      NotificationService().notify(notifySelectedTermChanged);
    }
  }

  StudentCourseTerm? get _selectedTerm => (_selectedTermId != null) ? StudentCourseTerm.findInList(_terms, id: _selectedTermId) : null;

  String? get displayTermId => _selectedTermId ?? _currentTermId ?? _anyTermId;
  StudentCourseTerm? get displayTerm => _selectedTerm ?? _currentTerm ?? _anyTerm;

  StudentCourseTerm? get _anyTerm => (_terms?.isNotEmpty ?? false) ? _terms?.first : null;
  String? get _anyTermId => _anyTerm?.id;

  StudentCourseTerm? get _currentTerm => StudentCourseTerm.findInList(_terms, isCurrent: true);
  String? get _currentTermId => _currentTerm?.id;


  void _updateSelectedTermId() {
    if ((_selectedTermId != null) && (StudentCourseTerm.findInList(_terms, id: _selectedTermId) == null)) {
      Storage().selectedCourseTermId = _selectedTermId = null;
      NotificationService().notify(notifySelectedTermChanged);
    }
  }

  // StudentCourses

  bool get _canLoadCourses =>
    StringUtils.isNotEmpty(Config().gatewayUrl) && (Gateway().externalAuthorizationHeaderValue != null) && StringUtils.isNotEmpty(Auth2().uin);

  Future<List<StudentCourse>?> loadCourses({required String termId, bool forceLoad = false}) async {
    if (_debugCourses != null) {
      return _debugCourses;
    }
    else if (_canLoadCourses) {
      bool coursesRefreshed = false;
      List<StudentCourse>? cachedCourses = _courses[termId];
      if (((cachedCourses == null) || forceLoad) && StringUtils.isNotEmpty(termId)) {
        if (_loadCoursesCompleters == null) {
          _loadCoursesCompleters = <Completer<List<StudentCourse>?>>{};
          
          String url = "${Config().gatewayUrl}/courses/studentcourses?id=${Auth2().uin}&termid=$termId";
          String analyticsUrl = "${Config().gatewayUrl}/courses/studentcourses?id=${Analytics.LogAnonymousUin}&termid=$termId";
          Position? position = await _userLocation;
          if (position != null) {
            url += "&lat=${position.latitude}&long=${position.longitude}";
            if (requireAda) {
              url += "&adaOnly=true";
            }
          }
          Response? response = await Network().get(url, auth: Auth2(), headers: Gateway().externalAuthorizationHeader, analyticsUrl: analyticsUrl);
          String? responseString = (response?.statusCode == 200) ? response?.body : null;
          /* TMP String? responseString = '''[
            {"coursetitle":"Thesis Research","courseshortname":"TAM 599","coursenumber":"25667","instructionmethod":"IND","coursesection":{"days":"","meeting_dates_or_range":"08/22/2022 - 12/07/2022","room":"","buildingname":"","buildingid":"","instructiontype":"IND","instructor":"Johnson, Harley","start_time":"","endtime":"","building":{"ID":"","Name":"","Number":"","FullAddress":"","Address1":"","Address2":"","City":"","State":"","ZipCode":"","ImageURL":"","MailCode":"","Entrances":null,"Latitude":0,"Longitude":0}}},
            {"coursetitle":"Atomic Scale Simulations","courseshortname":"CSE 485","coursenumber":"64706","instructionmethod":"LCD","coursesection":{"days":"Tu,Th","meeting_dates_or_range":"08/22/2022 - 12/07/2022","room":"305","buildingname":"Materials Science & Eng Bld","buildingid":"0034","instructiontype":"LCD","instructor":"Wagner, Lucas","start_time":"0930","endtime":"0930","building":{"ID":"3bb21766-3ad4-47e0-a472-d3c6cdbb07d0","Name":"Materials Science and Engineering Building","Number":"","FullAddress":"1304 W Green St  Urbana, IL 61801","Address1":"1304 W Green St","Address2":"","City":"Urbana","State":"IL","ZipCode":"61801","ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultBuildingImage.png","MailCode":"","Entrances":[{"ID":"d0564da7-66d6-452e-9198-65c860a57594","Name":"matscience_north","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.11109,"Longitude":-88.22594},{"ID":"1c1e1e4a-33f1-416f-8ccc-c5f990f347f7","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.111046,"Longitude":-88.22625},{"ID":"7d41bd0d-7b62-44e4-88ff-c27b3845bcdd","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.11115,"Longitude":-88.22617},{"ID":"0e9046ab-eeeb-44e5-81c3-6bdd635a3b59","Name":"matscience_south","ADACompliant":true,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.11071,"Longitude":-88.22608},{"ID":"41e5ef8a-6ed3-4229-a8e7-8f234e670900","Name":"matscience_west","ADACompliant":true,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.11078,"Longitude":-88.22641},{"ID":"ef2e8b18-2130-4512-982f-3c77ebc833b8","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.11079,"Longitude":-88.22575}],"Latitude":40.1109,"Longitude":-88.22608}}},
            {"coursetitle":"Advanced Continuum Mechanics","courseshortname":"TAM 545","coursenumber":"39105","instructionmethod":"LCD","coursesection":{"days":"M,W","meeting_dates_or_range":"08/22/2022 - 12/07/2022","room":"1047","buildingname":"Sidney Lu Mech Engr Bldg","buildingid":"0112","instructiontype":"LCD","instructor":"Starzewski, Martin","start_time":"1300","endtime":"1300","building":{"ID":"f96efb1f-8973-40d4-b602-c0a680897ad3","Name":"Sidney Lu Mechanical Engineering Building","Number":"","FullAddress":"1206 W Green St  Urbana, IL 61801","Address1":"1206 W Green St","Address2":"","City":"Urbana","State":"IL","ZipCode":"61801","ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultBuildingImage.png","MailCode":"","Entrances":[{"ID":"2b5f7e7f-ad33-4bff-a132-1aec7248a68d","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.111217,"Longitude":-88.22483},{"ID":"a5c9fdaa-3527-4fe7-a606-cbe62d6b419d","Name":"mechengbldg_north","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.11129,"Longitude":-88.22523},{"ID":"322f1204-8f34-4bd6-aac5-a0fae69e971f","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.111195,"Longitude":-88.225334},{"ID":"52844aac-1e27-471b-b7df-ee34f8dfe8e0","Name":"mechengbldg_west","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.110783,"Longitude":-88.225296},{"ID":"612c26ba-71ac-4b7a-be61-2459711ba589","Name":"mechengbldg_south","ADACompliant":true,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.110718,"Longitude":-88.22477},{"ID":"fee42e83-fcce-4344-aa9c-6806a2584961","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.11088,"Longitude":-88.22482},{"ID":"f7516216-53dd-4abe-b607-fc0ac698f043","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.111053,"Longitude":-88.22482},{"ID":"8c2ff914-ee51-4666-b468-02f73d567029","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.110867,"Longitude":-88.2241}],"Latitude":40.11095,"Longitude":-88.224884}}},
            {"coursetitle":"Seminar","courseshortname":"TAM 500","coursenumber":"30964","instructionmethod":"LCD","coursesection":{"days":"Tu,Th","meeting_dates_or_range":"08/22/2022 - 12/07/2022","room":"2035","buildingname":"Campus Instructional Facility","buildingid":"1545","instructiontype":"LCD","instructor":"Sofronis, Petros","start_time":"1600","endtime":"1600","building":{"ID":"","Name":"","Number":"","FullAddress":"","Address1":"","Address2":"","City":"","State":"","ZipCode":"","ImageURL":"","MailCode":"","Entrances":null,"Latitude":0,"Longitude":0}}},
            {"coursetitle":"Seminar","courseshortname":"TAM 500","coursenumber":"30964","instructionmethod":"LCD","coursesection":{"days":"Tu,Th","meeting_dates_or_range":"08/22/2022 - 12/07/2022","room":"2035","buildingname":"Campus Instructional Facility","buildingid":"1545","instructiontype":"LCD","instructor":"Sofronis, Petros","start_time":"1600","endtime":"1600","building":{"ID":"","Name":"","Number":"","FullAddress":"","Address1":"","Address2":"","City":"","State":"","ZipCode":"","ImageURL":"","MailCode":"","Entrances":null,"Latitude":0,"Longitude":0}}},
            {"coursetitle":"Digi-Mat Prof Dev. Seminar","courseshortname":"ME 590","coursenumber":"32259","instructionmethod":"LEC","coursesection":{"days":"F","meeting_dates_or_range":"08/22/2022 - 12/07/2022","room":"208","buildingname":"Seitz Materials Research Lab","buildingid":"0066","instructiontype":"LEC","instructor":"Trinkle, Dallas","start_time":"1500","endtime":"1500","building":{"ID":"621521ed-6162-490a-8068-5111f988121c","Name":"Frederick Seitz Materials Research Laboratory","Number":"","FullAddress":"104 S Goodwin Ave  Urbana, IL 61801","Address1":"104 S Goodwin Ave","Address2":"","City":"Urbana","State":"IL","ZipCode":"61801","ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultBuildingImage.png","MailCode":"","Entrances":[{"ID":"2149dd06-b870-45af-a872-a4d1b31a1ef6","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.111664,"Longitude":-88.2234},{"ID":"a0a95c63-f3f8-42ce-80d6-17886b98d011","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.111828,"Longitude":-88.223404},{"ID":"b6e4747d-8c08-4648-ae4f-a84c6359c068","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.11146,"Longitude":-88.223175},{"ID":"e08032ac-de42-4dd8-a618-1e1239920dd0","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.11153,"Longitude":-88.22274},{"ID":"45ef53a5-36af-442d-928d-232b7c51d7a2","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.11179,"Longitude":-88.22275},{"ID":"7e6bfb00-be71-4d2d-ad2e-7a9283f9e803","Name":"","ADACompliant":false,"Available":true,"ImageURL":"https://images.ccf.virtual.illinois.edu/DefaultEntranceImage.jpg","Latitude":40.11186,"Longitude":-88.22294}],"Latitude":40.111607,"Longitude":-88.22307}}}
          ]''';*/
          List<StudentCourse>? courses = StudentCourse.listFromJson(JsonUtils.decodeList(responseString));
          if (courses != null) {
            coursesRefreshed = (cachedCourses != null) && !DeepCollectionEquality().equals(courses, cachedCourses);
            _courses[termId] = cachedCourses = courses;
          }
          
          Set<Completer<List<StudentCourse>?>> loadCoursesCompleters = _loadCoursesCompleters!;
          _loadCoursesCompleters = null;
          for (Completer<List<StudentCourse>?> completer in loadCoursesCompleters) {
            completer.complete(courses);
          }
        }
        else {
          Completer<List<StudentCourse>?> completer = Completer<List<StudentCourse>?>();
          _loadCoursesCompleters!.add(completer);
          return completer.future;
        }
      }
      if (coursesRefreshed) {
        NotificationService().notify(notifyCachedCoursesChanged, termId);
      }
      return cachedCourses;
    }
    else {
      return null;
    }
  }

  void _updateCourses([bool forceClear = false]) {
    if (forceClear || (!_canLoadCourses && _courses.isNotEmpty)) {
      _courses.clear();
    }
  }
  
  Future<String?> getDebugCoursesRawContent() async {
    File rawContentFile = File(join(_appDocDir.path, _courseDebugContentName));
    return await rawContentFile.exists() ? await rawContentFile.readAsString() : null;
  }

  Future<void> setDebugCoursesRawContent(String? value) async{
    File rawContentFile = File(join(_appDocDir.path, _courseDebugContentName));
    if ((value != null) && value.isNotEmpty) {
      await rawContentFile.writeAsString(value, flush: true);
    }
    else {
      await rawContentFile.delete();
    }
    if (useDebugCoursesContent) {
      _applyDebugCourseRawContent(value);
    }
  }

  bool get useDebugCoursesContent => (Storage().debugUseStudentCoursesContent == true);

  set useDebugCoursesContent(bool value) {
    if (value != useDebugCoursesContent) {
      Storage().debugUseStudentCoursesContent = value;
      if (value) {
        getDebugCoursesRawContent().then((String? value) {
          _applyDebugCourseRawContent(value);
        });
      }
      else {
        _applyDebugCourseRawContent(null);
      }
    }
  }

  void _applyDebugCourseRawContent(String? rawContent) {
    List<StudentCourse>? debugCourses = ((rawContent != null) && rawContent.isNotEmpty) ? StudentCourse.listFromJson(JsonUtils.decodeList(rawContent)) : null;
    if (!DeepCollectionEquality().equals(_debugCourses, debugCourses)) {
        _debugCourses = debugCourses;
        NotificationService().notify(notifyCachedCoursesChanged);
    }
  }

  // Settings

  bool get requireAda => (Auth2().prefs?.getBoolSetting(_requireAdaSetting) == true);
  set requireAda(bool value) => Auth2().prefs?.applySetting(_requireAdaSetting, value);

  // User Location

  Future<bool> get _userLocationEnabled async => FlexUI().isLocationServicesAvailable && (await LocationServices().status == LocationServicesStatus.permissionAllowed);
  Future<Position?> get _userLocation async => await _userLocationEnabled ? await LocationServices().location : null;
}