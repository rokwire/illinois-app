
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Safety with Service, NotificationsListener {

  static const String notifySafeWalkDetail = "edu.illinois.rokwire.safety.safewalk.detail";
  static const String safeWalkRequestAction = "edu.illinois.rokwire.safety.safewalk.request";

  // Singleton Factory

  static final Safety _instance = Safety._internal();

  factory Safety() => _instance;

  Safety._internal();

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

  static String get _safeWalkDetailUrl => '${DeepLink().appUrl}/safety/safewalk/detail';

  static String safeWalkDetailUrl(Map<String, String?> params) {
    String urlParams = "";
    for (String key in params.keys) {
      String? value = params[key];
      if (value != null) {
        urlParams += urlParams.isEmpty ? '?' : '&';
        urlParams += '$key=${Uri.encodeComponent(value)}';
      }
    }
    return _safeWalkDetailUrl + urlParams;
  }

  void _onDeepLinkUri(Uri? uri) {
    if ((uri != null) && uri.matchDeepLinkUri(Uri.tryParse(_safeWalkDetailUrl))) {
      try { NotificationService().notify(notifySafeWalkDetail, uri.queryParameters.cast<String, dynamic>()); }
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
