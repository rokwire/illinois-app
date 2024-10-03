import 'package:http/http.dart';
import 'package:neom/model/StudentCourse.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/DeepLink.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Gateway with Service implements NotificationsListener {

  static const String notifyBuildingDetail = "edu.illinois.rokwire.gateway.building.detail";

  List<Uri>? _deepLinkUrisCache;

  // Singleton Factory

  static final Gateway _instance = Gateway._internal();
  factory Gateway() => _instance;
  Gateway._internal();
  
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

  // External Authorization Header

  final String externalAuthorizationHeaderKey = "External-Authorization";
  String? get externalAuthorizationHeaderValue => Auth2().uiucToken?.accessToken;
  Map<String, String?> get externalAuthorizationHeader => { externalAuthorizationHeaderKey: externalAuthorizationHeaderValue };

  // Wayfinding

  Future<List<Building>?> loadBuildings() async {
    if (StringUtils.isNotEmpty(Config().gatewayUrl)) {
      Response? response = await Network().get("${Config().gatewayUrl}/wayfinding/buildings", auth: Auth2(), headers: externalAuthorizationHeader);
      return (response?.statusCode == 200) ? Building.listFromJson(JsonUtils.decodeList(response?.body)) : null;
    }
    return null;
  }

  Future<Building?> loadBuilding({String? buildingNumber}) async {
    if (StringUtils.isNotEmpty(Config().gatewayUrl) && (buildingNumber != null)) {
      String requestUrl = UrlUtils.buildWithQueryParameters("${Config().gatewayUrl}/wayfinding/building", {
        'id': buildingNumber,
      });
      Response? response = await Network().get(requestUrl, auth: Auth2(), headers: externalAuthorizationHeader);
      return (response?.statusCode == 200) ? Building.fromJson(JsonUtils.decodeMap(response?.body)) : null;
    }
    return null;
  }

  Future<List<Building>?> searchBuildings({required String text}) async {
    if (StringUtils.isNotEmpty(Config().gatewayUrl)) {
      String requestUrl = UrlUtils.buildWithQueryParameters("${Config().gatewayUrl}/wayfinding/searchbuildings", {
        'name': text,
        'v': '2'
      });
      Response? response = await Network().get(requestUrl, auth: Auth2(), headers: externalAuthorizationHeader);
      return (response?.statusCode == 200) ? Building.listFromJsonMap(JsonUtils.decodeMap(response?.body)) : null;
    }
    return null;
  }

  // DeepLinks

  static String get buildingDetailUrl => '${DeepLink().appUrl}/gateway/building_detail';

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
    if (uri.matchDeepLinkUri(Uri.tryParse(buildingDetailUrl))) {
      NotificationService().notify(notifyBuildingDetail, uri.queryParameters.cast<String, dynamic>());
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