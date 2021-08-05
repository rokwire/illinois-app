import 'package:http/http.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Auth2 with Service implements NotificationsListener {
  
  static const String REDIRECT_URI         = 'edu.illinois.rokwire://rokwire.illinois.edu/oidc-auth';

  static const String notifyLoginStarted   = "edu.illinois.rokwire.auth2.login.started";
  static const String notifyLoginSucceeded = "edu.illinois.rokwire.auth2.login.finished";
  static const String notifyLoginFailed    = "edu.illinois.rokwire.auth2.login.finished";
  static const String notifyLoginChanged   = "edu.illinois.rokwire.auth2.login.finished";
  static const String notifyLoginFinished   = "edu.illinois.rokwire.auth2.login.finished";
  static const String notifyLogout         = "edu.illinois.rokwire.auth2.logout";

  _OidcLogin _oidcLogin;
  
  Auth2Token _token;
  Auth2User _user;

  // Singletone instance

  Auth2._internal();
  static final Auth2 _instance = Auth2._internal();

  factory Auth2() {
    return _instance;
  }

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      DeepLink.notifyUri,
    ]);
  }

  @override
  Future<void> initService() async {
    _token = Storage().auth2Token;
    _user = Storage().auth2User;
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Config() ]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(param);
    }
  }

  void _onDeepLinkUri(Uri uri) {
    Uri redirectUri = (_oidcLogin?.redirectUrl != null) ? Uri.tryParse(_oidcLogin.redirectUrl) : null;
    if ((redirectUri != null) && (uri != null) &&
        (redirectUri.scheme == uri.scheme) &&
        (redirectUri.authority == uri.authority) &&
        (redirectUri.path == uri.path))
    {
      _handleOidcAuthentication(uri);
    }
  }

  // Implementation

  Future<bool> authenticateWithOidc() async {
    _OidcLogin oidcLogin = await _getOidcData();
    if (oidcLogin?.loginUrl != null) {
      _oidcLogin = oidcLogin;
      _launchUrl(_oidcLogin?.loginUrl);
      return true;
    }
    else {
      return false;
    }
  }

  Future<void> _handleOidcAuthentication(Uri uri) async {
    if ((Config().coreUrl != null) && (Config().appId != null) && (Config().orgId != null)) {
      String url = "${Config().coreUrl}/login";
      String post = AppJson.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.oidc),
        'org_id': Config().orgId,
        'app_id': Config().appId,
        'creds': uri?.toString(),
        'params': _oidcLogin?.params
      });
      _oidcLogin = null;
      
      NotificationService().notify(notifyLoginStarted);
      
      Response response = await Network().post(url, body: post);
      Map<String, dynamic> responseJson = (response?.statusCode == 200) ? AppJson.decodeMap(response?.body) : null;
      Auth2Token token = (responseJson != null) ? Auth2Token.fromJson(responseJson) : null;
      Auth2User user = (responseJson != null) ? Auth2User.fromJson(AppJson.mapValue(responseJson['user'])) : null;
      if ((token != null) && token.isValid && (user != null) && user.isValid) {
        Storage().auth2Token = _token = token;
        Storage().auth2User = _user = user;
        NotificationService().notify(notifyLoginSucceeded);
        NotificationService().notify(notifyLoginChanged);
      }
      else {
        NotificationService().notify(notifyLoginFailed);
      }

      NotificationService().notify(notifyLoginFinished);
    }
  }

  Future<_OidcLogin> _getOidcData() async {
    if ((Config().coreUrl != null) && (Config().appId != null) && (Config().orgId != null)) {

      String url = "${Config().coreUrl}/login-url";
      String redirectUrl = "$REDIRECT_URI/${DateTime.now().millisecondsSinceEpoch}";
      String post = AppJson.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.oidc),
        'org_id': Config().orgId,
        'app_id': Config().appId,
        'redirect_uri': redirectUrl,
      });
      Response response = await Network().post(url, body: post);
      _OidcLogin oidcLogin = (response?.statusCode == 200) ? _OidcLogin.fromJson(AppJson.decodeMap(response?.body)) : null;
      return (oidcLogin != null) ? _OidcLogin.fromOther(oidcLogin, redirectUrl: redirectUrl) : null;
    }
    return null;
  }

  void _launchUrl(urlStr) async {
    try {
      if (await canLaunch(urlStr)) {
        await launch(urlStr);
      }
    }
    catch(e) {
      print(e);
    }
  }

  void logout() {
    if ((_token != null) || (_user != null)) {
      _token = null;
      _user = null;
      NotificationService().notify(notifyLogout);
      NotificationService().notify(notifyLoginChanged);
    }
  }

}

class _OidcLogin {
  final String loginUrl;
  final String redirectUrl;
  final Map<String, dynamic> params;
  
  _OidcLogin({this.loginUrl, this.redirectUrl, this.params});

  factory _OidcLogin.fromOther(_OidcLogin value, { String loginUrl, String redirectUrl, Map<String, dynamic> params}) {
    return _OidcLogin(
      loginUrl: loginUrl ?? value?.loginUrl,
      redirectUrl: redirectUrl ?? value?.redirectUrl,
      params: params ?? value?.params
    );
  }

  factory _OidcLogin.fromJson(Map<String, dynamic> json) {
    return (json != null) ? _OidcLogin(
      loginUrl: AppJson.stringValue(json['url']),
      params: AppJson.mapValue(json['params'])
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'url' : loginUrl,
      'params': params
    };
  }  

}

