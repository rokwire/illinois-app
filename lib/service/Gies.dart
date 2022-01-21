import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Gies with Service implements NotificationsListener{

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
  void createService() {
    NotificationService().subscribe(this,[

    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async{
    await super.initService();
    _navigationPages = Storage().giesNavPages ?? [];
    _completedPages = Storage().giesCompletedPages ?? Set<String>();

    AppBundle.loadString('assets/gies2.json').then((String? assetsContentString) {
        _pages = JsonUtils.decodeList(assetsContentString);
        _buildProgressSteps();
        _ensureNavigationPages();
    });
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config(), Auth2()]); //TBD check
  }

  @override
  void onNotification(String name, dynamic param) {
    //TBD Notifications
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

  bool isProgressStepCompleted(int? progressStep) {
    Set<String>? progressPages = _progressPages[progressStep];
    return (progressPages == null) || _completedPages!.containsAll(progressPages);
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

  String? get currentPageId {
    Map<String, dynamic> page = _pages?[1] ?? {};
    return page["id"];
    // return (_navigationPages?.isNotEmpty?? false) ? _navigationPages!.last : null;// TBD Implement properly
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

  //Utils
  static bool _pageCanComplete(Map? page) {
    List<dynamic>? buttons = (page != null) ? JsonUtils.listValue(page['buttons']) : null;
    if (buttons != null) {
      for (dynamic button in buttons) {
        if ((button is Map) && _pageButtonCompletes(button)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _pageButtonCompletes(Map button) {
    return JsonUtils.boolValue(button['completes']) == true;
  }

  static int? getPageProgress(Map<String, dynamic>? page) {
    return (page != null) ? (JsonUtils.intValue(page['progress']) ?? JsonUtils.intValue(page['progress-possition'])) : null;
  }

  //TBD Notify when data changed
}