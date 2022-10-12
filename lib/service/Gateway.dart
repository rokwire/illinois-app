import 'package:illinois/service/Auth2.dart';

class Gateway /* with Service */ {

  // Singleton Factory

  static final Gateway _instance = Gateway._internal();
  factory Gateway() => _instance;
  Gateway._internal();
  
  // External Authorization Header

  static const String ExternalAuthorizationHeaderKey = "External-Authorization";

  Map<String, String?> get externalAuthorizationHeader => { ExternalAuthorizationHeaderKey: Auth2().uiucToken?.accessToken };
}