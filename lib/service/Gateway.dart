import 'package:http/http.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Gateway /* with Service */ {

  // Singleton Factory

  static final Gateway _instance = Gateway._internal();
  factory Gateway() => _instance;
  Gateway._internal();
  
  // External Authorization Header

  final String externalAuthorizationHeaderKey = "External-Authorization";
  String? get externalAuthorizationHeaderValue => Auth2().uiucToken?.accessToken;
  Map<String, String?> get externalAuthorizationHeader => { externalAuthorizationHeaderKey: externalAuthorizationHeaderValue };

  // Wayfinding

  Future<List<Building>?> loadBuildings() async {
    if (StringUtils.isNotEmpty(Config().gatewayUrl)) {
      Response? response = await Network().get("${Config().gatewayUrl}/wayfinding/buildings", auth: Auth2(), headers: externalAuthorizationHeader);
      return (response?.statusCode == 200) ? Building.listFromJson( JsonUtils.decodeList(response?.body)) : null;
    }
    return null;
  }
}