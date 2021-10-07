import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Auth2 with Service implements NotificationsListener {
  
  static const String REDIRECT_URI         = 'edu.illinois.rokwire://rokwire.illinois.edu/oidc-auth';

  static const String notifyLoginStarted   = "edu.illinois.rokwire.auth2.login.started";
  static const String notifyLoginSucceeded = "edu.illinois.rokwire.auth2.login.succeeded";
  static const String notifyLoginFailed    = "edu.illinois.rokwire.auth2.login.failed";
  static const String notifyLoginChanged   = "edu.illinois.rokwire.auth2.login.changed";
  static const String notifyLoginFinished  = "edu.illinois.rokwire.auth2.login.finished";
  static const String notifyLogout         = "edu.illinois.rokwire.auth2.logout";
  static const String notifyProfileChanged = "edu.illinois.rokwire.auth2.profile.changed";
  static const String notifyPrefsChanged   = "edu.illinois.rokwire.auth2.prefs.changed";
  static const String notifyCardChanged    = "edu.illinois.rokwire.auth2.card.changed";
  static const String notifyUserDeleted    = "edu.illinois.rokwire.auth2.user.deleted";

  static const String analyticsUin         = 'UINxxxxxx';
  static const String analyticsFirstName   = 'FirstNameXXXXXX';
  static const String analyticsLastName    = 'LastNameXXXXXX';

  static const String _authCardName        = "idCard.json";

  _OidcLogin _oidcLogin;
  List<Completer<bool>> _oidcAuthenticationCompleters;
  bool _processingOidcAuthentication;
  Timer _oidcAuthenticationTimer;

  Future<Response> _refreshTokenFuture;
  
  Client _updateUserPrefsClient;
  Timer _updateUserPrefsTimer;
  
  Auth2Token _token;
  Auth2Token _uiucToken;
  Auth2Account _account;

  String _anonymousId;
  Auth2Token _anonymousToken;
  Auth2UserPrefs _anonymousPrefs;
  Auth2UserProfile _anonymousProfile;
  

  AuthCard  _authCard;
  File _authCardCacheFile;

  String _deviceId;
  
  DateTime _pausedDateTime;

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
      AppLivecycle.notifyStateChanged,
      Auth2UserPrefs.notifyChanged,
    ]);
  }

  @override
  Future<void> initService() async {
    _token = Storage().auth2Token;
    _uiucToken = Storage().auth2UiucToken;
    _account = Storage().auth2Account;

    _anonymousId = Storage().auth2AnonymousId;
    _anonymousToken = Storage().auth2AnonymousToken;
    _anonymousPrefs = Storage().auth2AnonymousPrefs;
    _anonymousProfile = Storage().auth2AnonymousProfile;

    _authCardCacheFile = await _getAuthCardCacheFile();
    _authCard = await _loadAuthCardFromCache();

    _deviceId = await NativeCommunicator().getDeviceId();

    if ((_anonymousId == null) || (_anonymousToken == null) || !_anonymousToken.isValidAnonymous) {
      if (!await authenticateAnonymously()) {
        Log.d("Anonymous Authentication Failed");
      }
    }
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Config(), NativeCommunicator() ]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(param);
    }
    else if (name == Auth2UserPrefs.notifyChanged) {
      _onUserPrefsChanged(param);
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      _refreshAuthCardIfNeeded();
      _createOidcAuthenticationTimerIfNeeded();

      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refreshAccountUserPrefs();
          _refreshAccountUserProfile();
        }
      }
    }
  }

  void _onDeepLinkUri(Uri uri) {
    if (uri != null) {
      Uri redirectUri = Uri.tryParse(REDIRECT_URI);
      if ((redirectUri != null) &&
          (redirectUri.scheme == uri.scheme) &&
          (redirectUri.authority == uri.authority) &&
          (redirectUri.path == uri.path))
      {
        _handleOidcAuthentication(uri);
      }
    }
  }

  // Getters

  Auth2Token get token => _token ?? _anonymousToken;
  Auth2Token get uiucToken => _uiucToken;
  Auth2Account get account => _account;
  AuthCard get authCard => _authCard;
  
  String get accountId => _account?.id ?? _anonymousId;
  Auth2UserPrefs get prefs => _account?.prefs ?? _anonymousPrefs;
  Auth2UserProfile get profile => _account?.profile ?? _anonymousProfile;

  bool get isLoggedIn => (_account?.id != null);
  bool get isOidcLoggedIn => (_account?.authType?.uiucUser != null);
  bool get isPhoneLoggedIn => (_account?.authType?.phoneUser != null);

  bool get hasUin => (0 < uin?.length ?? 0);
  String get uin => _account?.authType?.uiucUser?.uin;
  String get netId => _account?.authType?.uiucUser?.identifier;

  String get fullName => AppString.isStringNotEmpty(profile?.fullName) ? profile?.fullName : _account?.authType?.uiucUser?.fullName;
  String get email => AppString.isStringNotEmpty(profile?.email) ? profile?.email : _account?.authType?.uiucUser?.email;
  String get phone => AppString.isStringNotEmpty(profile?.phone) ? profile?.phone : _account?.authType?.phoneUser?.phone;

  bool get isEventEditor => isMemberOf('urn:mace:uiuc.edu:urbana:authman:app-rokwire-service-policy-rokwire event approvers');
  bool get isStadiumPollManager => isMemberOf('urn:mace:uiuc.edu:urbana:authman:app-rokwire-service-policy-rokwire stadium poll manager');
  bool get isDebugManager => isMemberOf('urn:mace:uiuc.edu:urbana:authman:app-rokwire-service-policy-rokwire debug');
  bool get isGroupsAccess => isMemberOf('urn:mace:uiuc.edu:urbana:authman:app-rokwire-service-policy-rokwire groups access');

  bool isMemberOf(String group) => _account?.authType?.uiucUser?.groupsMembership?.contains(group) ?? false;

  bool privacyMatch(int requredPrivacyLevel) => 
    (prefs?.privacyLevel == null) || (prefs?.privacyLevel == 0) || (prefs.privacyLevel >= requredPrivacyLevel);

  bool get canFavorite => privacyMatch(2);

  bool isFavorite(Favorite favorite) => prefs?.isFavorite(favorite) ?? false;
  bool isListFavorite(List<Favorite> favorites) => prefs?.isListFavorite(favorites) ?? false;

  bool get isVoterRegistered => prefs?.voter?.registeredVoter ?? false;
  bool get isVoterByMail => prefs?.voter?.voterByMail ?? false;
  bool get didVote => prefs?.voter?.voted ?? false;
  String get votePlace => prefs?.voter?.votePlace;
  
  // Anonymous Authentication

  Future<bool> authenticateAnonymously() async {
    if ((Config().coreUrl != null) && (Config().appCanonicalId != null) && (Config().coreOrgId != null) && (Config().rokwireApiKey != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String post = AppJson.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.apiKey),
        'org_id': Config().coreOrgId,
        'app_type_identifier': Config().appCanonicalId,
        'creds': Config().rokwireApiKey,
        'device': _deviceInfo
      });
      
      Response response = await Network().post(url, headers: headers, body: post);
      Map<String, dynamic> responseJson = (response?.statusCode == 200) ? AppJson.decodeMap(response?.body) : null;
      if (responseJson != null) {
        Auth2Token anonymousToken = Auth2Token.fromJson(AppJson.mapValue(responseJson['token']));
        Map<String, dynamic> params = AppJson.mapValue(responseJson['params']);
        String anonymousId = (params != null) ? AppJson.stringValue(params['anonymous_id']) : null;
        if ((anonymousToken != null) && anonymousToken.isValidAnonymous && (anonymousId != null) && anonymousId.isNotEmpty) {
          Storage().auth2AnonymousId = _anonymousId = anonymousId;
          Storage().auth2AnonymousToken = _anonymousToken = anonymousToken;
          Storage().auth2AnonymousPrefs = _anonymousPrefs = Auth2UserPrefs.empty();
          Storage().auth2AnonymousProfile = _anonymousProfile = Auth2UserProfile.empty();
          return true;
        }
      }
    }
    return false;
  }

  // OIDC Authentication

  Future<bool> authenticateWithOidc() async {
    if ((Config().coreUrl != null) && (Config().appCanonicalId != null) && (Config().coreOrgId != null)) {

      NotificationService().notify(notifyLoginStarted);
      
      if (_oidcAuthenticationCompleters == null) {

        _OidcLogin oidcLogin = await _getOidcData();
        if (oidcLogin?.loginUrl != null) {
          _oidcLogin = oidcLogin;
          await _launchUrl(_oidcLogin?.loginUrl);
        }
        else {
          NotificationService().notify(notifyLoginFailed);
          NotificationService().notify(notifyLoginFinished);
          return false;
        }

        _oidcAuthenticationCompleters = <Completer<bool>>[];
      }

      Completer<bool> completer = Completer<bool>();
      _oidcAuthenticationCompleters.add(completer);
      return completer.future;
    }
    
    return false;
  }

  Future<bool> _handleOidcAuthentication(Uri uri) async {
    
    NativeCommunicator().dismissSafariVC();
    
    _cancelOidcAuthenticationTimer();
    _processingOidcAuthentication = true;
    
    bool result = await _processOidcAuthentication(uri);

    Analytics().logAuth(action: Analytics.LogAuthLoginNetIdActionName, result: result);

    _processingOidcAuthentication = false;
    _completeOidcAuthentication(result);

    return result;
  }

  Future<bool> _processOidcAuthentication(Uri uri) async {
    if ((Config().coreUrl != null) && (Config().appCanonicalId != null) && (Config().coreOrgId != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String post = AppJson.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.oidcIllinois),
        'org_id': Config().coreOrgId,
        'app_type_identifier': Config().appCanonicalId,
        'creds': uri?.toString(),
        'params': _oidcLogin?.params,
//      'anonymous_id': _anonymousId,
//      'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': _deviceInfo,
      });
      _oidcLogin = null;
      
      Response response = await Network().post(url, headers: headers, body: post);
      Map<String, dynamic> responseJson = (response?.statusCode == 200) ? AppJson.decodeMap(response?.body) : null;
      if (responseJson != null) {
        Auth2Token token = Auth2Token.fromJson(AppJson.mapValue(responseJson['token']));
        Auth2Account account = Auth2Account.fromJson(AppJson.mapValue(responseJson['account']),
          prefs: _anonymousPrefs ?? Auth2UserPrefs.empty(),
          profile: _anonymousProfile ?? Auth2UserProfile.empty());

        if ((token != null) && token.isValid && (account != null) && account.isValid) {
          
          bool prefsUpdated = account.prefs?.apply(_anonymousPrefs);
          bool profileUpdated = account.profile?.apply(_anonymousProfile);
          Storage().auth2Token = _token = token;
          Storage().auth2Account = _account = account;
          Storage().auth2AnonymousPrefs = _anonymousPrefs = null;
          Storage().auth2AnonymousProfile = _anonymousProfile = null;

          if (prefsUpdated == true) {
            _saveAccountUserPrefs();
          }

          if (profileUpdated == true) {
            _saveAccountUserProfile(account.profile);
          }

          Map<String, dynamic> params = AppJson.mapValue(responseJson['params']);
          Auth2Token uiucToken = (params != null) ? Auth2Token.fromJson(AppJson.mapValue(params['oidc_token'])) : null;
          Storage().auth2UiucToken = _uiucToken = ((uiucToken != null) && uiucToken.isValidUiuc) ? uiucToken : null;

          NotificationService().notify(notifyProfileChanged);
          NotificationService().notify(notifyPrefsChanged);

          String authCardString = await _loadAuthCardStringFromNet();
          _authCard = AuthCard.fromJson(AppJson.decodeMap((authCardString)));
          Storage().auth2CardTime = (_authCard != null) ? DateTime.now().millisecondsSinceEpoch : null;
          await _saveAuthCardStringToCache(authCardString);
          NotificationService().notify(notifyCardChanged);

          NotificationService().notify(notifyLoginChanged);
          return true;
        }
      }
    }
    return false;
  }

  Future<_OidcLogin> _getOidcData() async {
    if ((Config().coreUrl != null) && (Config().appCanonicalId != null) && (Config().coreOrgId != null)) {

      String url = "${Config().coreUrl}/services/auth/login-url";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String post = AppJson.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.oidcIllinois),
        'org_id': Config().coreOrgId,
        'app_type_identifier': Config().appCanonicalId,
        'redirect_uri': REDIRECT_URI,
      });
      Response response = await Network().post(url, headers: headers, body: post);
      return _OidcLogin.fromJson(AppJson.decodeMap(response?.body));
    }
    return null;
  }

  void _createOidcAuthenticationTimerIfNeeded() {
    if ((_oidcAuthenticationCompleters != null) && (_processingOidcAuthentication != true)) {
      if (_oidcAuthenticationTimer != null) {
        _oidcAuthenticationTimer.cancel();
      }
      _oidcAuthenticationTimer = Timer(Duration(milliseconds: 100), () {
        _completeOidcAuthentication(null);
        _oidcAuthenticationTimer = null;
      });
    }
  }

  void _cancelOidcAuthenticationTimer() {
    if(_oidcAuthenticationTimer != null){
      _oidcAuthenticationTimer.cancel();
      _oidcAuthenticationTimer = null;
    }
  }

  void _completeOidcAuthentication(bool success) {
    
    if (success == true) {
      NotificationService().notify(notifyLoginSucceeded);
    }
    else if (success == false) {
      NotificationService().notify(notifyLoginFailed);
    }
    NotificationService().notify(notifyLoginFinished);

    if (_oidcAuthenticationCompleters != null) {
      List<Completer<bool>> loginCompleters = _oidcAuthenticationCompleters;
      _oidcAuthenticationCompleters = null;

      for(Completer<void> completer in loginCompleters){
        completer.complete(success);
      }
    }
  }

  // Phone Authentication

  Future<bool> authenticateWithPhone(String phoneNumber) async {
    if ((Config().coreUrl != null) && (Config().appCanonicalId != null) && (Config().coreOrgId != null) && (phoneNumber != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String post = AppJson.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.phoneTwilio),
        'org_id': Config().coreOrgId,
        'app_type_identifier': Config().appCanonicalId,
        'creds': {
          "phone": phoneNumber,
        },
//      'anonymous_id': _anonymousId,
//      'profile': _anonymousProfile?.toJson(),
//      'preferences': _anonymousPrefs?.toJson(),
//      'device': _deviceInfo,
      });

      Response response = await Network().post(url, headers: headers, body: post);
      return (response?.statusCode == 200);
    }
    return false;
  }

  Future<bool> handlePhoneAuthentication(String phoneNumber, String code) async {
    if ((Config().coreUrl != null) && (Config().appCanonicalId != null) && (Config().coreOrgId != null) && (phoneNumber != null) && (code != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String post = AppJson.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.phoneTwilio),
        'org_id': Config().coreOrgId,
        'app_type_identifier': Config().appCanonicalId,
        'creds': {
          "phone": phoneNumber,
          "code": code,
        },
//      'anonymous_id': _anonymousId,
//      'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': _deviceInfo,
      });

      Response response = await Network().post(url, headers: headers, body: post);
      Map<String, dynamic> responseJson = (response?.statusCode == 200) ? AppJson.decodeMap(response?.body) : null;
      if (responseJson != null) {
        Auth2Token token = Auth2Token.fromJson(AppJson.mapValue(responseJson['token']));
        Map<String, dynamic> accountJson = AppJson.mapValue(responseJson['account']);
        _applyPhoneUserToAccountJson(accountJson, Auth2PhoneUser(phone: phoneNumber));
        Auth2Account account = Auth2Account.fromJson(accountJson,
          prefs: _anonymousPrefs ?? Auth2UserPrefs.empty(),
          profile: _anonymousProfile ?? Auth2UserProfile.empty());

        if ((token != null) && token.isValid && (account != null) && account.isValid) {
          
          bool prefsUpdated = account.prefs?.apply(_anonymousPrefs);
          bool profileUpdated = account.profile?.apply(_anonymousProfile);
          Storage().auth2Token = _token = token;
          Storage().auth2Account = _account = account;
          Storage().auth2AnonymousPrefs = _anonymousPrefs = null;
          Storage().auth2AnonymousProfile = _anonymousProfile = null;

          if (prefsUpdated == true) {
            _saveAccountUserPrefs();
          }

          if (profileUpdated == true) {
            _saveAccountUserProfile(account.profile);
          }

          Map<String, dynamic> params = AppJson.mapValue(responseJson['params']);
          Auth2Token uiucToken = (params != null) ? Auth2Token.fromJson(AppJson.mapValue(params['phone_token'])) : null;
          Storage().auth2UiucToken = _uiucToken = ((uiucToken != null) && uiucToken.isValidUiuc) ? uiucToken : null;

          NotificationService().notify(notifyProfileChanged);
          NotificationService().notify(notifyPrefsChanged);
          NotificationService().notify(notifyLoginChanged);
          return true;
        }
      }
    }
    return false;
  }

  void _applyPhoneUserToAccountJson(Map<String, dynamic> accountJson, Auth2PhoneUser phoneUser) {
    List<dynamic> authTypes = (accountJson != null) ? AppJson.listValue(accountJson['auth_types']) : null;
    if (authTypes == null) {
      accountJson['auth_types'] = authTypes = [];
    }
    Map<String, dynamic> authType = (0 < authTypes.length) ? AppJson.mapValue(authTypes[0]) : null;
    if (authType == null) {
      authTypes.add(authType = {});
    }
    Map<String, dynamic> params = AppJson.mapValue(authType['params']);
    if (params == null) {
      authType['params'] = params = {};
    }
    params['phone_user'] = phoneUser?.toJson();
  }

  // Device Info

  Map<String, dynamic> get _deviceInfo {
    return {
      'type': "mobile",
      'device_id': _deviceId,
      'os': Platform.operatingSystem,
    };
  }

  // Logout

  void logout() {
    if ((_token != null) || (_account != null)) {
      Storage().auth2AnonymousPrefs = _anonymousPrefs = _account?.prefs ?? Auth2UserPrefs.empty();
      Storage().auth2AnonymousProfile = _anonymousProfile = Auth2UserProfile.empty();
      Storage().auth2Token = _token = null;
      Storage().auth2Account = _account = null;
      Storage().auth2UiucToken = _uiucToken = null;
      
      _updateUserPrefsTimer?.cancel();
      _updateUserPrefsTimer = null;

      _updateUserPrefsClient?.close();
      _updateUserPrefsClient = null;

      _authCard = null;
      _saveAuthCardStringToCache(null);
      Storage().auth2CardTime = null;

      Analytics().logAuth(action: Analytics.LogAuthLogoutActionName);
      
      NotificationService().notify(notifyCardChanged);
      NotificationService().notify(notifyProfileChanged);
      NotificationService().notify(notifyPrefsChanged);
      NotificationService().notify(notifyLoginChanged);
      NotificationService().notify(notifyLogout);
    }
  }

  // Delete

  Future<bool> deleteUser() async {
    if (await _deleteUserAccount()) {
      logout();
      NotificationService().notify(notifyUserDeleted);
      return true;
    }
    return false;
  }

  Future<bool> _deleteUserAccount() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account";
      Response response = await Network().delete(url, auth: NetworkAuth.Auth2);
      return response?.statusCode == 200;
    }
    return false;
  }

  // Refresh

  Future<Auth2Token> refreshToken() async {
    if ((Config().coreUrl != null) && (_token?.refreshToken != null)) {
      if (_refreshTokenFuture != null){
        Log.d("Auth2: will await refresh token");
        await _refreshTokenFuture;
        Log.d("Auth2: did await refresh token");
      }
      else {
        try {
          Log.d("Auth2: will refresh token");

          String url = "${Config().coreUrl}/services/auth/refresh";
          Map<String, String> headers = {
            'Content-Type': 'text/plain'
          };

          _refreshTokenFuture = Network().post(url, headers: headers, body: _token?.refreshToken);
          Response refreshTokenResponse = await _refreshTokenFuture;
          _refreshTokenFuture = null;

          if (refreshTokenResponse?.statusCode == 200) {
            Map<String, dynamic> responseJson = AppJson.decodeMap(refreshTokenResponse?.body);
            Auth2Token token = (responseJson != null) ? Auth2Token.fromJson(AppJson.mapValue(responseJson['token'])) : null;
            if ((token != null) && token.isValid) {
              Log.d("Auth: did refresh token: ${token?.accessToken}");
              Storage().auth2Token = _token = token;

              Map<String, dynamic> params = (responseJson != null) ? AppJson.mapValue(responseJson['params']) : null;
              Auth2Token uiucToken = (params != null) ? Auth2Token.fromJson(AppJson.mapValue(params['oidc_token'])) : null;
              Storage().auth2UiucToken = _uiucToken = ((uiucToken != null) && uiucToken.isValidUiuc) ? uiucToken : null;

              return token;
            }
            else {
              Log.d("Auth: failed to refresh token: ${refreshTokenResponse?.body}");
            }
          }
          else if(refreshTokenResponse?.statusCode == 400 || refreshTokenResponse?.statusCode == 401 || refreshTokenResponse?.statusCode == 403) {
            logout(); // Logout only on 400, 401 or 403. Do not do anything else for the rest of scenarios
          }
        }
        catch(e) {
          print(e.toString());
          _refreshTokenFuture = null; // make sure to clear this in case something went wrong.
        }
      }
    }
    return null;
  }

  // Auth Card

  Future<File> _getAuthCardCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _authCardName);
    return File(cacheFilePath);
  }

  Future<String> _loadAuthCardStringFromCache() async {
    try {
      return ((_authCardCacheFile != null) && await _authCardCacheFile.exists()) ? await _authCardCacheFile.readAsString() : null;
    }
    on Exception catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<void> _saveAuthCardStringToCache(String value) async {
    try {
      if (_authCardCacheFile != null) {
        if (value != null) {
          await _authCardCacheFile.writeAsString(value, flush: true);
        }
        else if (await _authCardCacheFile.exists()) {
          await _authCardCacheFile.delete();
        }
      }
    }
    on Exception catch (e) {
      print(e.toString());
    }
  }

  Future<AuthCard> _loadAuthCardFromCache() async {
    return AuthCard.fromJson(AppJson.decodeMap(await _loadAuthCardStringFromCache()));
  }

  Future<String> _loadAuthCardStringFromNet() async {
    String url = Config().iCardUrl;
    String uin = _account?.authType?.uiucUser?.uin;
    String accessToken = _uiucToken?.accessToken;

    if (AppString.isStringNotEmpty(url) &&  AppString.isStringNotEmpty(uin) && AppString.isStringNotEmpty(accessToken)) {
      Response response = await Network().post(url, headers: {
        'UIN': uin,
        'access_token': accessToken
      });
      return (response?.statusCode == 200) ? response.body : null;
    }
    return null;
  }

  Future<void> _refreshAuthCardIfNeeded() async {
    int lastCheckTime = Storage().auth2CardTime;
    DateTime lastCheckDate = (lastCheckTime != null) ? DateTime.fromMillisecondsSinceEpoch(lastCheckTime) : null;
    DateTime lastCheckMidnight = AppDateTime.midnight(lastCheckDate);

    DateTime now = DateTime.now();
    DateTime todayMidnight = AppDateTime.midnight(now);

    // Do it one per day
    if ((lastCheckMidnight == null) || (lastCheckMidnight.compareTo(todayMidnight) < 0)) {
      if (await _refreshAuthCard() != null) {
        Storage().auth2CardTime = now.millisecondsSinceEpoch;
      }
    }
  }

  Future<AuthCard> _refreshAuthCard() async {
    String authCardString = await _loadAuthCardStringFromNet();
    AuthCard authCard = AuthCard.fromJson(AppJson.decodeMap((authCardString)));
    if ((authCard != null) && (authCard != _authCard)) {
      _authCard = authCard;
      await _saveAuthCardStringToCache(authCardString);
      NotificationService().notify(notifyCardChanged);
    }
    return authCard;
  }

  // User Prefs

  void _onUserPrefsChanged(Auth2UserPrefs prefs) {
    if (identical(prefs, _anonymousPrefs)) {
      Storage().auth2AnonymousPrefs = _anonymousPrefs;
      NotificationService().notify(notifyPrefsChanged);
    }
    else if (identical(prefs, _account?.prefs)) {
      Storage().auth2Account = _account;
      NotificationService().notify(notifyPrefsChanged);
      _saveAccountUserPrefs();
    }
  }

  Future<void> _saveAccountUserPrefs() async {
    if ((Config().coreUrl != null) && (_account?.prefs != null)) {
      String url = "${Config().coreUrl}/services/preferences";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String post = AppJson.encode(_account.prefs);

      Client client = Client();
      _updateUserPrefsClient?.close();
      _updateUserPrefsClient = client;
      
      Response response = await Network().put(url, auth: NetworkAuth.Auth2, headers: headers, body: post, client: _updateUserPrefsClient);
      
      if (identical(client, _updateUserPrefsClient)) {
        if (response?.statusCode == 200) {
          _updateUserPrefsTimer?.cancel();
          _updateUserPrefsTimer = null;
        }
        else if (_updateUserPrefsTimer == null) {
          _updateUserPrefsTimer = Timer.periodic(Duration(seconds: 3), (_) {
            if (_updateUserPrefsClient == null) {
              _saveAccountUserPrefs();
            }
          });
        }
      }
      _updateUserPrefsClient = null;
    }
  }

  Future<Auth2UserPrefs> _loadAccountUserPrefs() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/preferences";
      Response response = await Network().get(url, auth: NetworkAuth.Auth2);
      return (response?.statusCode == 200) ? Auth2UserPrefs.fromJson(AppJson.decodeMap(response?.body)) : null;
    }
    return null;
  }

  Future<void> _refreshAccountUserPrefs() async {
    Auth2UserPrefs prefs = await _loadAccountUserPrefs();
    if ((prefs != null) && (prefs != _account?.prefs)) {
      if (_account?.prefs?.apply(prefs, notify: true) ?? false) {
        Storage().auth2Account = _account;
        NotificationService().notify(notifyPrefsChanged);
      }
    }
  }

  // User Profile
  
  Future<Auth2UserProfile> loadUserProfile() async {
    return await _loadAccountUserProfile();
  }

  Future<bool> saveAccountUserProfile(Auth2UserProfile profile) async {
    if (await _saveAccountUserProfile(profile)) {
      if (_account?.profile?.apply(profile) ?? false) {
        Storage().auth2Account = _account;
        NotificationService().notify(notifyProfileChanged);
      }
      return true;
    }
    return false;
  }

  Future<Auth2UserProfile> _loadAccountUserProfile() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/profile";
      Response response = await Network().get(url, auth: NetworkAuth.Auth2);
      return (response?.statusCode == 200) ? Auth2UserProfile.fromJson(AppJson.decodeMap(response?.body)) : null;
    }
    return null;
  }

  Future<bool> _saveAccountUserProfile(Auth2UserProfile profile) async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/profile";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String post = AppJson.encode(profile.toJson());
      Response response = await Network().put(url, auth: NetworkAuth.Auth2, headers: headers, body: post);
      return (response?.statusCode == 200);
    }
    return false;
  }

  Future<void> _refreshAccountUserProfile() async {
    Auth2UserProfile profile = await _loadAccountUserProfile();
    if ((profile != null) && (profile != _account?.profile)) {
      if (_account?.profile?.apply(profile) ?? false) {
        Storage().auth2Account = _account;
        NotificationService().notify(notifyProfileChanged);
      }
    }
  }

  // Helpers

  static Future<void> _launchUrl(urlStr) async {
    try {
      if (await canLaunch(urlStr)) {
        await launch(urlStr);
      }
    }
    catch(e) {
      print(e);
    }
  }

}

class _OidcLogin {
  final String loginUrl;
  final Map<String, dynamic> params;
  
  _OidcLogin({this.loginUrl, this.params});

  factory _OidcLogin.fromJson(Map<String, dynamic> json) {
    return (json != null) ? _OidcLogin(
      loginUrl: AppJson.stringValue(json['login_url']),
      params: AppJson.mapValue(json['params'])
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'login_url' : loginUrl,
      'params': params
    };
  }  

}

