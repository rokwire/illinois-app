
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Safety with Service implements NotificationsListener {

  static const String notifySafeWalkDetail = "edu.illinois.rokwire.safety.safewalk.detail";

  List<Uri>? _deepLinkUrisCache;

  // Singleton Factory

  static final Safety _instance = Safety._internal();

  factory Safety() => _instance;

  Safety._internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      DeepLink.notifyUri,
    ]);
    _deepLinkUrisCache = <Uri>[];
    super.createService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }


  @override
  void initServiceUI() {
    _processCachedDeepLinkUris();
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
    if (uri != null) {
      if (_deepLinkUrisCache != null) {
        _cacheDeepLinkUri(uri);
      } else {
        _processDeepLinkUri(uri);
      }
    }
  }

  void _processDeepLinkUri(Uri uri) {
    if (uri.matchDeepLinkUri(Uri.tryParse(_safeWalkDetailUrl))) {
      NotificationService().notify(notifySafeWalkDetail, uri.queryParameters.cast<String, dynamic>());
    }
  }

  void _cacheDeepLinkUri(Uri uri) {
    _deepLinkUrisCache?.add(uri);
  }

  void _processCachedDeepLinkUris() {
    if (_deepLinkUrisCache != null) {
      List<Uri> deepLinkUrisCache = _deepLinkUrisCache!;
      _deepLinkUrisCache = null;

      for (Uri deepLinkUri in deepLinkUrisCache) {
        _processDeepLinkUri(deepLinkUri);
      }
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(param);
    }
  }

}