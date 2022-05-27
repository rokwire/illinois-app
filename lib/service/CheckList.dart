import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/service/Storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'Config.dart';

abstract class CheckList with Service implements NotificationsListener{
  static const String notifyPageChanged  = "edu.illinois.rokwire.gies.service.page.changed";
  static const String notifyPageCompleted  = "edu.illinois.rokwire.gies.service.page.completed";
  static const String notifySwipeToPage  = "edu.illinois.rokwire.gies.service.action.swipe.page";
  static const String notifyContentChanged  = "edu.illinois.rokwire.gies.service.content.changed";

  // Singleton instance wrapper
  factory CheckList(String serviceName){
    switch (serviceName){
      case "gies" : return _GiesCheckListInstanceWrapper();
      case "uiuc_student" : return _StudentCheckListInstanceWrapper();
    }
    return _GiesCheckListInstanceWrapper(); //default
  }

  CheckList.fromName(this._contentName);

  final String _contentName;

  File? _cacheFile;

  List<dynamic>? _pages;
  List<String>?  _navigationPages;

  Map<int, Set<String>>? _progressPages;

  Set<String>? _completedPages;
  Set<String> _verifiedPages = <String>{};
  Set<String> _pagesRequireVerification = <String> {};
  List<int>? _progressSteps;

  DateTime? _pausedDateTime;

  // String checklistName();

  // Service
  @override
  void createService() {
    super.createService();
    NotificationService().subscribe(this, [
      Groups.notifyUserMembershipUpdated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupCreated,
      Groups.notifyUserGroupsUpdated,
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
    _navigationPages = Storage().getCheckListNavPages(_contentName) ?? [];
    _completedPages = Storage().getChecklistCompletedPages(_contentName) ?? Set<String>();
    _cacheFile = await _getCacheFile();
    _pages = await _loadContentJsonFromCache();
    if (_pages != null) {
      _updateContentFromNet();
    }
    else {
      String? contentString = await _loadContentStringFromNet();
      _pages = JsonUtils.decodeList(contentString);
      if (_pages != null) {
        _saveContentStringToCache(contentString);
      }
    }

    _buildProgressSteps();
    _loadPageVerification();
    _ensureNavigationPages();

    if (_pages != null) {
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'GIES Initialization Failed',
        description: 'Failed to initialize GIES content.',
      );
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Config(), Groups()]);
  }
  
  // Implementation

  Future<File> _getCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _cacheFileName);
    return File(cacheFilePath);
  }

  Future<String?> _loadContentStringFromCache() async {
    return (await _cacheFile?.exists() == true) ? await _cacheFile?.readAsString() : null;
  }

  Future<void> _saveContentStringToCache(String? value) async {
    try {
      if (value != null) {
        await _cacheFile?.writeAsString(value, flush: true);
      }
      else {
        await _cacheFile?.delete();
      }
    }
    catch(e) { print(e.toString()); }
  }

  Future<List<dynamic>?> _loadContentJsonFromCache() async {
    return JsonUtils.decodeList(await _loadContentStringFromCache());
  }

  Future<String?> _loadContentStringFromNet() async {
    //TBD REMOVE
    //TMP:
    if(_contentName == "uiuc_student"){
      return AppBundle.loadString('assets/uiucStudent.json');
    }

    try {
      List<dynamic> result;
      Response? response = await Network().get("${Config().contentUrl}/content_items", body: JsonUtils.encode({'categories': [_contentName]}), auth: Auth2());
      List<dynamic>? responseList = (response?.statusCode == 200) ? JsonUtils.decodeList(response?.body)  : null;
      if (responseList != null) {
        result = [];
        for (dynamic responseEntry in responseList) {
          Map<String, dynamic>? responseMap = JsonUtils.mapValue(responseEntry);
          List<dynamic>? responseData = (responseMap != null) ? JsonUtils.listValue(responseMap['data']) : null;
          if (responseData != null) {
            result.addAll(responseData);
          }
        }
        return JsonUtils.encode(result);
      }
    }
    catch (e) { print(e.toString()); }
    return null;
  }

  Future<void> _updateContentFromNet() async {
    String? contentString = await _loadContentStringFromNet();
    List<dynamic>? contentList = JsonUtils.decodeList(contentString);
    if ((contentList != null) && !DeepCollectionEquality().equals(_pages, contentList)) {
      _pages = contentList;
      _buildProgressSteps();
      _loadPageVerification();
      _ensureNavigationPages();
      _saveContentStringToCache(contentString);
      NotificationService().notify(notifyContentChanged);
    }
  }

  // ignore: unused_element
  Future<List<dynamic>?> _loadFromAssets() async{
    return JsonUtils.decodeList(await AppBundle.loadString('assets/gies.json'));
  }

  void _buildProgressSteps() {
    _progressPages = Map<int, Set<String>>();
    if ((_pages != null) && _pages!.isNotEmpty) {
      for (dynamic page in _pages!) {
        if (page is Map) {
          int? pageProgress = JsonUtils.intValue(page['progress']);
          if (pageProgress != null) {
            String? pageId = JsonUtils.stringValue(page['id']);
            if(JsonUtils.stringValue(page['group_name']) != null && pageId != null){
              _pagesRequireVerification.add(pageId);
            }
            if ((pageId != null) && pageId.isNotEmpty && _pageCanComplete(page)) {
              Set<String>? progressPages = _progressPages![pageProgress];
              if (progressPages == null) {
                _progressPages![pageProgress] = progressPages = Set<String>();
              }
              progressPages.add(pageId);
            }
          }
        }
      }
      _progressSteps = List.from(_progressPages!.keys);
      _progressSteps!.sort();
    }
  }

  void _ensureNavigationPages() {
    if (_navigationPages!.isEmpty) {
      String? rootPageId = _navigationRootPageId;
      if ((rootPageId != null) && rootPageId.isNotEmpty) {
        Storage().setCheckListNavPages(_contentName, _navigationPages = [rootPageId]);
      }
    }
  }

  bool _hasPage({String? id}) {
    return getPage(id: id) != null;
  }

  Map<String, dynamic>? getPage({String? id, int? progress}) {
    if (_pages != null) {
      for (dynamic page in _pages!) {
        if (page is Map) {
          if (((id == null) || (id == JsonUtils.stringValue(page['id']))) &&
              ((progress == null) || (progress == (JsonUtils.intValue(page['progress']) ?? JsonUtils.intValue(page['progress-possition'])))))
          {
            try { return page.cast<String, dynamic>(); }
            catch(e) { print(e.toString()); }
          }
        }
      }
    }
    return null;
  }

  void pushPage(Map<String, dynamic>? pushPage) {
    String? pushPageId = (pushPage != null) ? JsonUtils.stringValue(pushPage['id']) : null;
    if ((pushPageId != null) && pushPageId.isNotEmpty && _hasPage(id: pushPageId)) {
      int? currentPageProgress = getPageProgress(currentPage);
      int? pushPageProgress = getPageProgress(pushPage);
      if (currentPageProgress == pushPageProgress) {
        _navigationPages!.add(pushPageId);
      }
      else {
        _navigationPages = [pushPageId];
      }
      Storage().setCheckListNavPages(_contentName, _navigationPages);
      NotificationService().notify(notifyPageChanged, pushPageId);
    }
  }

  void popPage() {
    if (1 < _navigationPages!.length) {
      _navigationPages!.removeLast();
      Storage().setCheckListNavPages(_contentName,  _navigationPages);
      NotificationService().notify(notifyPageChanged);
    }
  }

  void processButtonPage(Map<String, dynamic> button, {String? callerPageId}) {
    String? pageId = callerPageId ?? currentPageId;
    if (pageButtonCompletes(button)) {
      if ((pageId != null) && pageId.isNotEmpty) {
        if(!(_completedPages?.contains(pageId) ?? false)){
          _completedPages!.add(pageId);
          Storage().setChecklistCompletedPages(_contentName, _completedPages);
        }
        _verifyPage(pageId);
        NotificationService().notify(notifyPageCompleted, pageId);
      }
    }

    String? swipeToId = JsonUtils.stringValue(button["swipe_page"]); //This is _StepsHorizontalListWidget action
    if(swipeToId!=null) {
      NotificationService().notify(notifySwipeToPage, swipeToId);
    }

    String? pushPageId = JsonUtils.stringValue(button['page']);
    if ((pushPageId != null) && pushPageId.isNotEmpty) {
      int? currentPageProgress = getPageProgress(currentPage);

      Map<String, dynamic>? pushPage = getPage(id: pushPageId);
      int? pushPageProgress = getPageProgress(pushPage);

      if ((currentPageProgress != null) && (pushPageProgress != null) && (currentPageProgress < pushPageProgress)) {
        while (isProgressStepCompleted(pushPageProgress)) {
          int nextPushPageProgress = pushPageProgress! + 1;
          Map<String, dynamic>? nextPushPage = getPage(progress: nextPushPageProgress);
          String? nextPushPageId = (nextPushPage != null) ? JsonUtils.stringValue(nextPushPage['id']) : null;
          if ((nextPushPageId != null) && nextPushPageId.isNotEmpty) {
            pushPage = nextPushPage;
            pushPageId = nextPushPageId;
            pushPageProgress = nextPushPageProgress;
          }
          else {
            break;
          }
        }
      }

      this.pushPage(pushPage);
    }
  }

  bool isProgressStepCompleted(int? progressStep) {
    Set<String>? progressPages = (_progressPages != null) ? _progressPages![progressStep] : null;
    return (progressPages == null) ||
        _verifiedPages.containsAll(progressPages) ||
        (!_stepNeedVerification(progressStep) && (_completedPages?.containsAll(progressPages) ?? false)); //All steps should request verification (no mix of verification and completion) for inner steps TBD implement mix here if needed
  }

  bool _stepNeedVerification(int? step){
    if(step == null) {return false;}

    Set<String>? progressPages = (_progressPages != null) ? _progressPages![step] : null;
    return (progressPages == null) ||
        _doPagesNeedVerification(progressPages);
  }

  String? setCurrentNotes(List<dynamic>? notes, String? pageId) {

    Map<String, dynamic>? currentPage =pageId!=null? this.getPage(id: pageId): this.currentPage;
    String? currentPageId = (currentPage != null) ? JsonUtils.stringValue(currentPage['id']) : null;
    if ((notes != null) && (currentPageId != null)) {
      for (dynamic note in notes) {
        if (note is Map) {
          String? noteId = JsonUtils.stringValue(note['id']);
          if (noteId == currentPageId) {
            return currentPageId;
          }
        }
      }

      String title = "${JsonUtils.stringValue(currentPage!["step_title"])}: ${JsonUtils.stringValue(currentPage['title'])}";
      notes.add({
        'id': currentPageId,
        'title': title,
      });
    }

    return currentPageId;
  }

  void _loadPageVerification({bool notify = false}){
    if((_progressPages != null) && _progressPages!.isNotEmpty){
      for(Set<String> steps in _progressPages!.values){
        if(steps.isNotEmpty){
          for(String pageId in steps){
            _verifyPage(pageId);
          }
        }
      }
    }
  }

  void _verifyPage(String? page, {bool notify = true}){
    if(page == null) {
      return;
    }

    if(_isPageGroupMembershipApproved(page)){
      if(!_verifiedPages.contains(page)) {
        _verifiedPages.add(page);
        if(notify){
          NotificationService().notify(notifyPageCompleted);
        }
      }
    } else {
      if(_verifiedPages.contains(page)){
        _verifiedPages.remove(page);
        if(notify){
          NotificationService().notify(notifyPageCompleted);
        }
      }
    }
  }

  bool _isPageGroupMembershipApproved(String? pageId){
    if(StringUtils.isEmpty(pageId))
      return false;

    dynamic pageData = getPage(id: pageId);
    String? groupName = pageData is Map ?  JsonUtils.stringValue(pageData["group_name"]) : null;
    Set<String>? groupsNames = Groups().userGroupNames;

    return groupName != null &&
        (groupsNames?.contains(groupName) ?? false);
  }

  bool _isPageVerified(String? pageId){
    return pageId != null && _verifiedPages.contains(pageId);
  }

  bool _doPagesNeedVerification(Set<String?> pageIds){
    return _pagesRequireVerification.containsAll(pageIds);
  }

  bool isPageCompleted(String? pageId){
    if(StringUtils.isEmpty(pageId)){ return false;}

    if(_doPagesNeedVerification({pageId})){
      return _isPageVerified(pageId);
    } else {
      return _completedPages?.contains(pageId) ?? false;
    }
  }

  List<dynamic>? get pages{
    return _pages;
  }

  List<dynamic>? get navigationPages{
    return _navigationPages;
  }

  Map<int, Set<String>>? get progressPages{
    return _progressPages;
  }

  List<int>? get progressSteps{
    return _progressSteps;
  }

  Map<String, dynamic>? get currentPage{
    return getPage(id: currentPageId);
  }

  String? get currentPageId {
    return (_navigationPages?.isNotEmpty?? false) ? _navigationPages?.last : null;
  }

  String? get _navigationRootPageId {
    if ((_pages != null) && _pages!.isNotEmpty) {
      for (dynamic page in _pages!) {
        if (page is Map) {
          String? pageId = JsonUtils.stringValue(page['id']);
          if (pageId != null) {
            return pageId;
          }
        }
      }
    }
    return null;
  }

  int get completedStepsCount {
    int count = 0;
    if (progressSteps != null) {
      for (int progress in _progressSteps!) {
        if (isProgressStepCompleted(progress)) {
          count++;
        }
      }

      return count;
    }

    return 0;
  }

  bool get isLoading{
    return false;
  }

  bool get supportNotes{
    return false; //Remove Notes buttons if we don't support them anymore. Hide for now
  }

  String get _cacheFileName => "$_contentName.json";
  //Utils
  bool _pageCanComplete(Map? page) {
    if(StringUtils.isNotEmpty(JsonUtils.stringValue(page?["group_name"]))){
      return true;
    }

    List<dynamic>? buttons = (page != null) ? JsonUtils.listValue(page['buttons']) : null;
    List<dynamic>? bnavigationButtons = (page != null) ? JsonUtils.listValue(page['navigation_buttons']) : null;

    if (buttons != null) {
      for (dynamic button in buttons) {
        if ((button is Map) && pageButtonCompletes(button)) {
          return true;
        }
      }
    } else if (bnavigationButtons!=null){
      for (dynamic button in bnavigationButtons) {
        if ((button is Map) && pageButtonCompletes(button)) {
          return true;
        }
      }
    }
    return false;
  }

  bool pageButtonCompletes(Map button) {
    return JsonUtils.boolValue(button['completes']) == true;
  }

  int? getPageProgress(Map<String, dynamic>? page) {
    return (page != null) ? (JsonUtils.intValue(page['progress']) ?? JsonUtils.intValue(page['progress-possition'])) : null;
  }

  @override
  void onNotification(String name, param) {
    if (name == Groups.notifyUserMembershipUpdated ||
        name == Groups.notifyGroupUpdated ||
        // name == Groups.notifyGroupCreated ||
        name == Groups.notifyUserGroupsUpdated) {
      _loadPageVerification(notify: true);
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        //TMP: test
      }
     }
  }

  void onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateContentFromNet();
        }
      }
    }
  }
}

// Singleton instance wrappers
class _GiesCheckListInstanceWrapper extends CheckList{
  static final _GiesCheckListInstanceWrapper _instance = _GiesCheckListInstanceWrapper._internal();

  factory _GiesCheckListInstanceWrapper() => _instance;

  _GiesCheckListInstanceWrapper._internal() : super.fromName("gies");
}

class _StudentCheckListInstanceWrapper extends CheckList{
  static final _StudentCheckListInstanceWrapper _instance = _StudentCheckListInstanceWrapper._internal();

  factory _StudentCheckListInstanceWrapper() => _instance;

  _StudentCheckListInstanceWrapper._internal() : super.fromName("uiuc_student");
}