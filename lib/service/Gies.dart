import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Giess with Service implements NotificationsListener{

  List<dynamic>? _pages;
  Set<String>? _completedPages;

  // Singletone instance
  static final Giess _instance = Giess._internal();

  factory Giess() {
    return _instance;
  }

  Giess._internal();

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
    _completedPages = Storage().giesCompletedPages ?? Set<String>();

    AppBundle.loadString('assets/gies.json').then((String? assetsContentString) {
        _pages = JsonUtils.decodeList(assetsContentString);
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

  List<dynamic>? get pages{
    return _pages;
  }

  Set<String>? get completedPages{
    return _completedPages;
  }

}