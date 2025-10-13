
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Map2 with Service, NotificationsListener {

  static const String notifySelect = "edu.illinois.rokwire.map2.select";

  // Singleton Factory

  static final Map2 _instance = Map2._internal();

  factory Map2() => _instance;

  Map2._internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      DeepLink.notifyUiUri,
    ]);
    super.createService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }


  @override
  Set<Service> get serviceDependsOn {
    return { DeepLink() };
  }

  // DeepLinks

  static String get _selectUrl => '${DeepLink().appUrl}/map2/select';

  static String selectUrl(Map<String, String?> params) {
    String urlParams = "";
    for (String key in params.keys) {
      String? value = params[key];
      if (value != null) {
        urlParams += urlParams.isEmpty ? '?' : '&';
        urlParams += '$key=${Uri.encodeComponent(value)}';
      }
    }
    return _selectUrl + urlParams;
  }

  void _onDeepLinkUri(Uri? uri) {
    if ((uri != null) && uri.matchDeepLinkUri(Uri.tryParse(_selectUrl))) {
      try { NotificationService().notify(notifySelect, Map2DeepLinkSelectParam(uri.queryParameters)); }
      catch (e) { print(e.toString()); }
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUiUri) {
      _onDeepLinkUri(JsonUtils.cast(param));
    }
  }

}

class Map2DeepLinkSelectParam {
  final Map<String, String?> params;
  Map2DeepLinkSelectParam(this.params);
}
