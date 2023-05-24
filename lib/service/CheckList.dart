import 'package:http/http.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

abstract class CheckList with Service implements NotificationsListener, ContentItemCategoryClient {
  static const String notifyPageChanged  = "edu.illinois.rokwire.gies.service.page.changed";
  static const String notifyPageCompleted  = "edu.illinois.rokwire.gies.service.page.completed";
  static const String notifySwipeToPage  = "edu.illinois.rokwire.gies.service.action.swipe.page";
  static const String notifyContentChanged  = "edu.illinois.rokwire.gies.service.content.changed";
  static const String notifyExecuteCustomWidgetAction  = "edu.illinois.rokwire.gies.service.content.execute.widget.action";

  //Custom actions
  static const String widgetActionRequestGroup  = "edu.illinois.rokwire.checklist.gies.widget.action.request.group";

  static const String giesOnboarding = "gies_onboarding";
  static const String uiucOnboarding = "uiuc_onboarding";

  // Singleton instance wrapper
  factory CheckList(String serviceName){
    switch (serviceName){
      case giesOnboarding : return _GiesCheckListInstanceWrapper();
      case uiucOnboarding : return _StudentCheckListInstanceWrapper();
    }
    return _GiesCheckListInstanceWrapper(); //default
  }

  CheckList.fromName(this._contentName);

  final String _contentName;

  List<dynamic>? _pages;
  List<String>?  _navigationPages;

  Map<int, Set<String>>? _progressPages;

  Set<String>? _completedPages;
  Set<String> _verifiedPages = <String>{};
  Set<String> _pagesRequireVerification = <String> {};
  List<int>? _progressSteps;

  // String checklistName();

  // Service
  @override
  void createService() {
    super.createService();
    NotificationService().subscribe(this, [
      Content.notifyContentItemsChanged,
      Groups.notifyUserMembershipUpdated,
      Groups.notifyGroupUpdated,
      Groups.notifyUserGroupsUpdated,
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

    _pages = Content().contentListItem(_contentCategory);
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
    return {Storage(), Content(), Groups()};
  }
  
  @override
  String get debugDisplayName => "CheckList('$_contentName')";

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == Content.notifyContentItemsChanged) {
      _onContentItemsChanged(param);
    }
    else if (name == Groups.notifyUserMembershipUpdated ||
        name == Groups.notifyGroupUpdated ||
        name == Groups.notifyUserGroupsUpdated) {
      _loadPageVerification(notify: true);
    }
  }

  void _onContentItemsChanged(Set<String>? categoriesDiff) {
    if (categoriesDiff?.contains(_contentCategory) == true) {
      _onContentChanged();
    }
  }

  // ContentItemCategoryClient

  @override
  List<String> get contentItemCategory => <String>[_contentCategory];

  // Implementation

  String get _contentCategory => '${_contentName}_checklists';

  void _onContentChanged() {
    _pages = Content().contentListItem(_contentCategory);
    _buildProgressSteps();
    _loadPageVerification();
    _ensureNavigationPages();
      NotificationService().notify(notifyContentChanged, {_contentName: ""});
  }

  Future<dynamic> loadUserInfo() async {
    if(_contentName != giesOnboarding){
      return null;
    }
    if (StringUtils.isEmpty(Config().gatewayUrl)) {
      Log.e('Missing gateway url.');
      return null;
    }
    String? url = "${Config().gatewayUrl}/person/contactinfo?id=${Auth2().uin}";
    String? analyticsUrl = "${Config().gatewayUrl}/person/contactinfo?id=${Analytics.LogAnonymousUin}";
    // contactInfoUrl+="123456789"; //Workaround to return dummy data

    Response? response = await Network().get(url, auth: Auth2(), headers: Gateway().externalAuthorizationHeader, analyticsUrl: analyticsUrl);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    Log.d("Contact Info Request: ${response?.request.toString()}  Response: $responseCode : $responseString");
    if (responseCode == 200) {
      dynamic jsonResponse = JsonUtils.decode(responseString);
      return jsonResponse;
    } else {
      Log.e('Failed to load Contact Info. Response code: $responseCode, Response:\n$responseString');
      return null;
    }
  }

  Future<List<dynamic>?> loadCourses() async {
    if(_contentName != giesOnboarding){
      return null;
    }
    if (StringUtils.isEmpty(Config().gatewayUrl)) {
      Log.e('Missing gateway url.');
      return null;
    }

    String? url = "${Config().gatewayUrl}/courses/giescourses?id=${Auth2().uin}";
    String? analyticsUrl = "${Config().gatewayUrl}/courses/giescourses?id=${Analytics.LogAnonymousUin}";
    Response? response = await Network().get(url, auth: Auth2(), headers: Gateway().externalAuthorizationHeader, analyticsUrl: analyticsUrl);

    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    Log.d("Student Courses Request: ${response?.request.toString()}  Response: $responseCode : $responseString");

    if (responseCode == 200) {
      return JsonUtils.decodeList(responseString);
    } else {
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
    
    Groups().searchGroups(groupName, includeHidden: true ).then((foundGroups){
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
}

// Singleton instance wrappers
class _GiesCheckListInstanceWrapper extends CheckList{
  static final _GiesCheckListInstanceWrapper _instance = _GiesCheckListInstanceWrapper._internal();

  factory _GiesCheckListInstanceWrapper() => _instance;

  _GiesCheckListInstanceWrapper._internal() : super.fromName(CheckList.giesOnboarding);
}

class _StudentCheckListInstanceWrapper extends CheckList{
  static final _StudentCheckListInstanceWrapper _instance = _StudentCheckListInstanceWrapper._internal();

  factory _StudentCheckListInstanceWrapper() => _instance;

  _StudentCheckListInstanceWrapper._internal() : super.fromName(CheckList.uiucOnboarding);
}