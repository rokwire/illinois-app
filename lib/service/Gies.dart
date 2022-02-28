import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Gies with Service{
  static const String notifyPageChanged  = "edu.illinois.rokwire.gies.service.page.changed";
  static const String notifyPageCompleted  = "edu.illinois.rokwire.gies.service.page.completed";
  static const String notifySwipeToPage  = "edu.illinois.rokwire.gies.service.action.swipe.page";

  List<dynamic>? _pages;
  List<String>?  _navigationPages;

  late Map<int, Set<String>> _progressPages;
  Set<String>? _completedPages;
  List<int>? _progressSteps;

  // Singletone instance
  static final Gies _instance = Gies._internal();

  factory Gies() {
    return _instance;
  }

  Gies._internal();

  // Service
  @override
  Future<void> initService() async{
    await super.initService();
    _navigationPages = Storage().giesNavPages ?? [];
    _completedPages = Storage().giesCompletedPages ?? Set<String>();

    AppBundle.loadString('assets/gies.json').then((String? assetsContentString) {
        _pages = JsonUtils.decodeList(assetsContentString);
        _buildProgressSteps();
        _ensureNavigationPages();
    });
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage()]);
  }

  void _buildProgressSteps() {
    _progressPages = Map<int, Set<String>>();
    if ((_pages != null) && _pages!.isNotEmpty) {
      for (dynamic page in _pages!) {
        if (page is Map) {
          int? pageProgress = JsonUtils.intValue(page['progress']);
          if (pageProgress != null) {
            String? pageId = JsonUtils.stringValue(page['id']);
            if ((pageId != null) && pageId.isNotEmpty && _pageCanComplete(page)) {
              Set<String>? progressPages = _progressPages[pageProgress];
              if (progressPages == null) {
                _progressPages[pageProgress] = progressPages = Set<String>();
              }
              progressPages.add(pageId);
            }
          }
        }
      }
      _progressSteps = List.from(_progressPages.keys);
      _progressSteps!.sort();
    }
  }

  void _ensureNavigationPages() {
    if (_navigationPages!.isEmpty) {
      String? rootPageId = _navigationRootPageId;
      if ((rootPageId != null) && rootPageId.isNotEmpty) {
        Storage().giesNavPages = _navigationPages = [rootPageId];
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
      Storage().giesNavPages = _navigationPages;
      NotificationService().notify(notifyPageChanged, pushPageId);
    }
  }

  void popPage() {
    if (1 < _navigationPages!.length) {
      _navigationPages!.removeLast();
      Storage().giesNavPages = _navigationPages;
      NotificationService().notify(notifyPageChanged);
    }
  }

  void processButtonPage(Map<String, dynamic> button, {String? callerPageId}) {
    String? pageId = callerPageId ?? Gies().currentPageId;
    if (Gies().pageButtonCompletes(button)) {
      if ((pageId != null) && pageId.isNotEmpty && !Gies().completedPages!.contains(pageId)) {
          _completedPages!.add(pageId);
        Storage().giesCompletedPages = _completedPages;
        NotificationService().notify(notifyPageCompleted, pageId);
      }
    }

    String? swipeToId = JsonUtils.stringValue(button["swipe_page"]); //This is _StepsHorizontalListWidget action
    if(swipeToId!=null) {
      NotificationService().notify(notifySwipeToPage, swipeToId);
    }

    String? pushPageId = JsonUtils.stringValue(button['page']);
    if ((pushPageId != null) && pushPageId.isNotEmpty) {
      int? currentPageProgress = Gies().getPageProgress(currentPage);

      Map<String, dynamic>? pushPage = Gies().getPage(id: pushPageId);
      int? pushPageProgress = Gies().getPageProgress(pushPage);

      if ((currentPageProgress != null) && (pushPageProgress != null) && (currentPageProgress < pushPageProgress)) {
        while (Gies().isProgressStepCompleted(pushPageProgress)) {
          int nextPushPageProgress = pushPageProgress! + 1;
          Map<String, dynamic>? nextPushPage = Gies().getPage(progress: nextPushPageProgress);
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

      Gies().pushPage(pushPage);
    }
  }

  bool isProgressStepCompleted(int? progressStep) {
    Set<String>? progressPages = _progressPages[progressStep];
    return (progressPages == null) || _completedPages!.containsAll(progressPages);
  }

  String? setCurrentNotes(List<dynamic>? notes, String? pageId) {

    Map<String, dynamic>? currentPage =pageId!=null? Gies().getPage(id: pageId): Gies().currentPage;
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

      // String title = "${JsonUtils.intValue(currentPage!['progress'])}${JsonUtils.stringValue(currentPage['tab_index'])??""} ${JsonUtils.stringValue(currentPage['title'])}";
      // String title = "${JsonUtils.stringValue(currentPage!['title'])}";
      String title = "${JsonUtils.stringValue(currentPage!["step_title"])}: ${JsonUtils.stringValue(currentPage['title'])}";
      notes.add({
        'id': currentPageId,
        'title': title,
      });
    }

    return currentPageId;
  }

  List<dynamic>? get pages{
    return _pages;
  }

  Set<String>? get completedPages{
    return _completedPages;
  }

  List<dynamic>? get navigationPages{
    return _navigationPages;
  }

  Map<int, Set<String>> get progressPages{
    return _progressPages;
  }

  List<int>? get progressSteps{
    return _progressSteps;
  }

  Map<String, dynamic>? get currentPage{
    return getPage(id: currentPageId);
  }

  String? get currentPageId {
    return (_navigationPages?.isNotEmpty?? false) ? _navigationPages!.last : null;
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

  int get completedStepsCount{
    int count = 0;
    for(int progress in _progressSteps!){
      if(isProgressStepCompleted(progress)){
        count++;
      }
    }

    return count;
  }

  bool get supportNotes{
    return false; //Remove Notes buttons if we don't support them anymore. Hide for now
  }

  //Utils
  bool _pageCanComplete(Map? page) {
    List<dynamic>? buttons = (page != null) ? JsonUtils.listValue(page['buttons']) : null;
    if (buttons != null) {
      for (dynamic button in buttons) {
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