import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/log.dart';
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
  static const String notifyStudentInfoChanged  = "edu.illinois.rokwire.gies.service.content.student_info.changed";
  static const String notifyExecuteCustomWidgetAction  = "edu.illinois.rokwire.gies.service.content.execute.widget.action";

  //Custom actions
  static const String widgetActionRequestGroup  = "edu.illinois.rokwire.checklist.gies.widget.action.request.group";

  // Singleton instance wrapper
  factory CheckList(String serviceName){
    switch (serviceName){
      case "gies" : return _GiesCheckListInstanceWrapper();
      case "new_student" : return _StudentCheckListInstanceWrapper();
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

  //custom widgets data
  Map<String, dynamic>? _studentInfo;

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
      Auth2.notifyLoginSucceeded
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
    _refreshUserInfo();
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
  
  @override
  String get debugDisplayName => "CheckList('$_contentName')";

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
    //TMP: load from app assets
    // if(_contentName == "new_student"){
    //   return AppBundle.loadString('assets/newStudent.json');
    // } else if(_contentName == "gies"){
    //   return AppBundle.loadString('assets/gies.json');
    // }

    try {
      List<dynamic> result;
      String contentItemCategory = _contentName + '_checklist';
      Response? response = await Network().get("${Config().contentUrl}/content_items", body: JsonUtils.encode({'categories': [contentItemCategory]}), auth: Auth2());
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
      NotificationService().notify(notifyContentChanged, {_contentName: ""});
    }
  }

  // ignore: unused_element
  Future<List<dynamic>?> _loadFromAssets() async{
    return JsonUtils.decodeList(await AppBundle.loadString('assets/gies.json'));
  }

  Future<void> _refreshUserInfo() async{
    _loadUserInfo().then((value){
      if(_studentInfo != value) {
        _studentInfo = value;
        NotificationService().notify(notifyStudentInfoChanged, {_contentName: ""});
      }
    });
  }

  Future<dynamic> _loadUserInfo() async {
    if(_contentName != "gies"){
      return null;
    }
    if (StringUtils.isEmpty(Config().gatewayUrl)) {
      Log.e('Missing gateway url.');
      return null;
    }
    String? contactInfoUrl = "${Config().gatewayUrl}/person/contactinfo?id=";
        contactInfoUrl+="${Auth2().uin}";
        // contactInfoUrl+="123456789"; //Workaround to return dummy data
    String? token = Auth2().uiucToken?.accessToken;

    Response? response = await Network().get(contactInfoUrl, auth: Auth2(), headers: {"External-Authorization":token});
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    Log.d("Contact Info Request: ${response?.request.toString()}  Response: $responseCode : $responseString");
    if (responseCode == 200) {
      dynamic jsonResponse = JsonUtils.decode(responseString);
      return jsonResponse;
    } else {
      //TBD remove
      // return JsonUtils.decode(_mocContactInfoResponse);
      Log.e('Failed to load Contact Info. Response code: $responseCode, Response:\n$responseString');
      return null;
    }
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
      NotificationService().notify(notifyPageChanged, {_contentName: pushPageId});
    }
  }

  void popPage() {
    if (1 < _navigationPages!.length) {
      _navigationPages!.removeLast();
      Storage().setCheckListNavPages(_contentName,  _navigationPages);
      NotificationService().notify(notifyPageChanged, {_contentName: ""});
    }
  }

  void processButtonPage(Map<String, dynamic> button, {String? callerPageId}) {
    String? pageId = callerPageId ?? currentPageId;

    Map<String, dynamic>? widgetCustomAction = JsonUtils.mapValue(button["widget_action"]);
    if(widgetCustomAction!=null){
      String? actionName = widgetCustomAction["name"];
      Map<String, dynamic>? params = JsonUtils.mapValue(widgetCustomAction["params"]);
      if(actionName!=null)
        _processWidgetAction(actionName, params);
      NotificationService().notify(notifyExecuteCustomWidgetAction, {_contentName: widgetCustomAction});
    }

    if (pageButtonCompletes(button)) {
      if ((pageId != null) && pageId.isNotEmpty) {
        if(!(_completedPages?.contains(pageId) ?? false)){
          _completedPages!.add(pageId);
          Storage().setChecklistCompletedPages(_contentName, _completedPages);
        }
        _verifyPage(pageId);
        NotificationService().notify(notifyPageCompleted, {_contentName: pageId});
      }
    }

    String? swipeToId = JsonUtils.stringValue(button["swipe_page"]); //This is _StepsHorizontalListWidget action
    if(swipeToId!=null) {
      NotificationService().notify(notifySwipeToPage, {_contentName: swipeToId});
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

  void _processWidgetAction(String actionName, Map<String, dynamic>? params){
    switch(actionName){
      case widgetActionRequestGroup : {
        _joinApprovalGroup(params);
        break;
      }
    }
  }

  void _joinApprovalGroup(Map<String, dynamic>? params) async{
    String? groupName = JsonUtils.stringValue(params?["group_name"]);
    if(groupName == null){
      Log.d("Unable to Join approval group: missing group name");
      return;
    }
    
    Groups().searchGroups(groupName).then((foundGroups){
      if(CollectionUtils.isEmpty(foundGroups)){
        Log.d("Unable to Join approval group: Unable to find group with name $groupName");
      }
      var group;
      try {
        group = foundGroups?.firstWhere((element) => element.title == groupName);
      } catch (e){print(e);}
      String? groupId = group?.id;
      if(StringUtils.isEmpty(groupId)){
        Log.d("Unable to Join approval group: Unable to find group with id $groupId");
      }
      
      Groups().requestMembership(group, []).then((value){
        Log.d("Requesting group finished with status: ${value? "Success": "Failed"}");
      });
    });
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
          NotificationService().notify(notifyPageCompleted, {_contentName: page});
        }
      }
    } else {
      if(_verifiedPages.contains(page)){
        _verifiedPages.remove(page);
        if(notify){
          NotificationService().notify(notifyPageCompleted, {_contentName: page});
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

  Map<String, dynamic>? get studentInfo{
    return _studentInfo;
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

  //TBD remove
  // ignore: unused_element
  String get _mocContactInfoResponse{
    return "{\r\n   "
        "\"uin\":\"657427043\",\r\n   "
        "\"firstName\":\"Clint\",\r\n   "
        "\"lastName\":\"Stearns\",\r\n   "
        "\"preferred\":\"\",\r\n  "
        " \"mailingAddress\":{\r\n      "
          "\"Type\":\"MA\",\r\n      "
          "\"Street1\":\"207EMichiganAve\",\r\n      "
          "\"City\":\"Urbana\",\r\n     "
          "\"StateAbbr\":\"IL\",\r\n      "
          "\"StateName\":\"Illinois\",\r\n      "
          "\"ZipCode\":\"61801-5028\",\r\n      "
          "\"County\":\"Champaign\",\r\n     "
          " \"Phone\":{\r\n         "
            "\"AreaCode\":\"217\",\r\n         "
            "\"Number\":\"3676260\"\r\n      "
          "}\r\n   "
        "},\r\n   "
        "\"permanentAddress\":{\r\n     "
          "\"Type\":\"PR\",\r\n      "
          "\"Street1\":\"207EMichiganAve\",\r\n      "
          "\"City\":\"Urbana\",\r\n      "
          "\"StateAbbr\":\"IL\",\r\n      "
          "\"StateName\":\"Illinois\",\r\n      "
          "\"ZipCode\":\"61801-5028\",\r\n      "
          "\"County\":\"Champaign\",\r\n      "
          "\"Phone\":{\r\n         "
            "\"AreaCode\":\"217\",\r\n         "
            "\"Number\":\"3676260\"\r\n      "
          "}\r\n   "
        "},\r\n   "
        "\"emergencycontacts\":[\r\n      "
          "{\r\n         "
            "\"Priority\":\"1\",\r\n        "
            "\"RelationShip\":{\r\n            "
              "\"Code\":\"I\",\r\n            "
              "\"Name\":\"Spouse\"\r\n         "
            "},\r\n         "
            "\"FirstName\":\"Michelle\",\r\n         "
            "\"LastName\":\"Stearns\",\r\n         "
            "\"Address\":{\r\n           "
              " \"Type\":\"ECA\",\r\n            "
              "\"Street1\":\"207EMichiganAve\",\r\n            "
              "\"City\":\"Urbana\",\r\n            "
              "\"StateAbbr\":\"IL\",\r\n            "
              "\"StateName\":\"Illinois\",\r\n            "
              "\"ZipCode\":\"61801\",\r\n            "
              "\"County\":\"\",\r\n           "
              " \"Phone\":{\r\n               "
                "\"AreaCode\":\"217\",\r\n               "
                "\"Number\":\"3676260\"\r\n            "
              "}\r\n         "
            "}\r\n      "
          "}\r\n   "
        "]\r"
        "\n}";
  }

  @override
  void onNotification(String name, param) {
    if (name == Groups.notifyUserMembershipUpdated ||
        name == Groups.notifyGroupUpdated ||
        // name == Groups.notifyGroupCreated ||
        name == Groups.notifyUserGroupsUpdated) {
      _loadPageVerification(notify: true);
    }
    else if (name == Auth2.notifyLoginSucceeded) {
      _refreshUserInfo();
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

  _StudentCheckListInstanceWrapper._internal() : super.fromName("new_student");
}