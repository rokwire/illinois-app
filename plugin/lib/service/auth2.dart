import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';

import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Auth2 with Service, NetworkAuthProvider implements NotificationsListener {
  
  static const String notifyLoginStarted      = "edu.illinois.rokwire.auth2.login.started";
  static const String notifyLoginSucceeded    = "edu.illinois.rokwire.auth2.login.succeeded";
  static const String notifyLoginFailed       = "edu.illinois.rokwire.auth2.login.failed";
  static const String notifyLoginChanged      = "edu.illinois.rokwire.auth2.login.changed";
  static const String notifyLoginFinished     = "edu.illinois.rokwire.auth2.login.finished";
  static const String notifyLogout            = "edu.illinois.rokwire.auth2.logout";
  static const String notifyLinkChanged       = "edu.illinois.rokwire.auth2.link.changed";
  static const String notifyProfileChanged    = "edu.illinois.rokwire.auth2.profile.changed";
  static const String notifyPrefsChanged      = "edu.illinois.rokwire.auth2.prefs.changed";
  static const String notifyUserDeleted       = "edu.illinois.rokwire.auth2.user.deleted";
  static const String notifyPrepareUserDelete = "edu.illinois.rokwire.auth2.user.prepare.delete";

  static const String _deviceIdIdentifier     = 'edu.illinois.rokwire.device_id';

  _OidcLogin? _oidcLogin;
  bool? _oidcLink;
  List<Completer<bool?>>? _oidcAuthenticationCompleters;
  bool? _processingOidcAuthentication;
  Timer? _oidcAuthenticationTimer;

  final Map<String, Future<Response?>> _refreshTokenFutures = {};
  final Map<String, int> _refreshTonenFailCounts = {};

  Client? _updateUserPrefsClient;
  Timer? _updateUserPrefsTimer;
  
  Auth2Token? _token;
  Auth2Account? _account;

  String? _anonymousId;
  Auth2Token? _anonymousToken;
  Auth2UserPrefs? _anonymousPrefs;
  Auth2UserProfile? _anonymousProfile;
  
  String? _deviceId;
  
  DateTime? _pausedDateTime;

  // Singletone Factory

  static Auth2? _instance;

  static Auth2? get instance => _instance;
  
  @protected
  static set instance(Auth2? value) => _instance = value;

  factory Auth2() => _instance ?? (_instance = Auth2.internal());

  @protected
  Auth2.internal();

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
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _token = Storage().auth2Token;
    _account = Storage().auth2Account;

    _anonymousId = Storage().auth2AnonymousId;
    _anonymousToken = Storage().auth2AnonymousToken;
    _anonymousPrefs = Storage().auth2AnonymousPrefs;
    _anonymousProfile = Storage().auth2AnonymousProfile;

    _deviceId = await RokwirePlugin.getDeviceId(deviceIdIdentifier, deviceIdIdentifier2);

    if ((_account == null) && (_anonymousPrefs == null)) {
      Storage().auth2AnonymousPrefs = _anonymousPrefs = defaultAnonimousPrefs;
    }

    if ((_account == null) && (_anonymousProfile == null)) {
      Storage().auth2AnonymousProfile = _anonymousProfile = defaultAnonimousProfile;
    }

    if ((_anonymousId == null) || (_anonymousToken == null) || !_anonymousToken!.isValid) {
      if (!await authenticateAnonymously()) {
        throw ServiceError(
          source: this,
          severity: ServiceErrorSeverity.fatal,
          title: 'Authentication Initialization Failed',
          description: 'Failed to initialize anonymous authentication token.',
        );
      }
    }

    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Storage(), Config() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      onDeepLinkUri(param);
    }
    else if (name == Auth2UserPrefs.notifyChanged) {
      onUserPrefsChanged(param);
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      onAppLivecycleStateChanged(param);
    }
  }

  @protected
  void onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      createOidcAuthenticationTimerIfNeeded();

      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refreshAccountUserPrefs();
          _refreshAccountUserProfile();
        }
      }
    }
  }

  @protected
  String get oidcRedirectUrl => '${DeepLink().appUrl}/oidc-auth';

  @protected
  void onDeepLinkUri(Uri? uri) {
    if (uri != null) {
      Uri? redirectUri = Uri.tryParse(oidcRedirectUrl);
      if ((redirectUri != null) &&
          (redirectUri.scheme == uri.scheme) &&
          (redirectUri.authority == uri.authority) &&
          (redirectUri.path == uri.path))
      {
        handleOidcAuthentication(uri);
      }
    }
  }

  // NetworkAuthProvider

  @override
  Map<String, String>? get networkAuthHeaders {
    String? accessToken = token?.accessToken;
    if ((accessToken != null) && accessToken.isNotEmpty) {
      String? tokenType = token?.tokenType ?? 'Bearer';
      return { HttpHeaders.authorizationHeader : "$tokenType $accessToken" };
    }
    return null;
  }

  @override
  dynamic get networkAuthToken => token;
  
  @override
  Future<bool> refreshNetworkAuthTokenIfNeeded(BaseResponse? response, dynamic token) async {
    if ((response?.statusCode == 401) && (token is Auth2Token) && (this.token == token)) {
      return (await refreshToken(token) != null);
    }
    return false;
  }

  // Getters

  Auth2Token? get token => _token ?? _anonymousToken;
  Auth2Token? get userToken => _token;
  Auth2Token? get anonymousToken => _anonymousToken;
  Auth2Account? get account => _account;
  String? get deviceId => _deviceId;
  
  String? get accountId => _account?.id ?? _anonymousId;
  Auth2UserPrefs? get prefs => _account?.prefs ?? _anonymousPrefs;
  Auth2UserProfile? get profile => _account?.profile ?? _anonymousProfile;
  Auth2LoginType? get loginType => _account?.authType?.loginType;

  bool get isLoggedIn => (_account?.id != null);
  bool get isOidcLoggedIn => (_account?.authType?.loginType == Auth2LoginType.oidcIllinois);
  bool get isPhoneLoggedIn => (_account?.authType?.loginType == Auth2LoginType.phoneTwilio);
  bool get isEmailLoggedIn => (_account?.authType?.loginType == Auth2LoginType.email);

  bool get isOidcLinked => _account?.isAuthTypeLinked(Auth2LoginType.oidcIllinois) ?? false;
  bool get isPhoneLinked => _account?.isAuthTypeLinked(Auth2LoginType.phoneTwilio) ?? false;
  bool get isEmailLinked => _account?.isAuthTypeLinked(Auth2LoginType.email) ?? false;

  List<String> get linkedOidcIds => _account?.getLinkedIdsForAuthType(Auth2LoginType.oidcIllinois) ?? [];
  List<String> get linkedPhoneIds => _account?.getLinkedIdsForAuthType(Auth2LoginType.phoneTwilio) ?? [];
  List<String> get linkedEmailIds => _account?.getLinkedIdsForAuthType(Auth2LoginType.email) ?? [];

  bool get hasUin => (0 < (uin?.length ?? 0));
  String? get uin => _account?.authType?.uiucUser?.uin;
  String? get netId => _account?.authType?.uiucUser?.netId;

  String? get fullName => StringUtils.ensureNotEmpty(profile?.fullName, defaultValue: _account?.authType?.uiucUser?.fullName ?? '');
  String? get email => StringUtils.ensureNotEmpty(profile?.email, defaultValue: _account?.authType?.uiucUser?.email ?? '');
  String? get phone => StringUtils.ensureNotEmpty(profile?.phone, defaultValue: _account?.authType?.phone ?? '');

  bool get isEventEditor => hasRole("event approvers");
  bool get isStadiumPollManager => hasRole("stadium poll manager");
  bool get isDebugManager => hasRole("debug");
  bool get isGroupsAccess => hasRole("groups access");

  bool hasRole(String role) => _account?.hasRole(role) ?? false;

  bool isShibbolethMemberOf(String group) => _account?.authType?.uiucUser?.groupsMembership?.contains(group) ?? false;

  bool privacyMatch(int requredPrivacyLevel) => 
    (prefs?.privacyLevel == null) || (prefs?.privacyLevel == 0) || (prefs!.privacyLevel! >= requredPrivacyLevel);

  bool get canFavorite => privacyMatch(2);

  bool isFavorite(Favorite? favorite) => prefs?.isFavorite(favorite) ?? false;
  bool isListFavorite(List<Favorite>? favorites) => prefs?.isListFavorite(favorites) ?? false;

  bool get isVoterRegistered => prefs?.voter?.registeredVoter ?? false;
  bool? get isVoterByMail => prefs?.voter?.voterByMail;
  bool get didVote => prefs?.voter?.voted ?? false;
  String? get votePlace => prefs?.voter?.votePlace;
  
  // Overrides

  @protected
  Auth2UserPrefs get defaultAnonimousPrefs => Auth2UserPrefs.empty();

  @protected
  Auth2UserProfile get defaultAnonimousProfile => Auth2UserProfile.empty();

  @protected
  String? get deviceIdIdentifier => _deviceIdIdentifier;

  @protected
  String? get deviceIdIdentifier2 => null;

  // Anonymous Authentication

  Future<bool> authenticateAnonymously() async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (Config().rokwireApiKey != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.anonymous),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'device': _deviceInfo
      });
      
      Response? response = await Network().post(url, headers: headers, body: post);
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      if (responseJson != null) {
        Auth2Token? anonymousToken = Auth2Token.fromJson(JsonUtils.mapValue(responseJson['token']));
        Map<String, dynamic>? params = JsonUtils.mapValue(responseJson['params']);
        String? anonymousId = (params != null) ? JsonUtils.stringValue(params['anonymous_id']) : null;
        if ((anonymousToken != null) && anonymousToken.isValid && (anonymousId != null) && anonymousId.isNotEmpty) {
          _refreshTonenFailCounts.remove(_anonymousToken?.refreshToken);
          Storage().auth2AnonymousId = _anonymousId = anonymousId;
          Storage().auth2AnonymousToken = _anonymousToken = anonymousToken;
          _log("Auth2: anonymous auth succeeded: ${response?.statusCode}\n${response?.body}");
          return true;
        }
      }
      _log("Auth2: anonymous auth failed: ${response?.statusCode}\n${response?.body}");
    }
    return false;
  }

  // OIDC Authentication

  Future<bool?> authenticateWithOidc({bool? link}) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null)) {

      if (_oidcAuthenticationCompleters == null) {
        _oidcAuthenticationCompleters = <Completer<bool?>>[];
        NotificationService().notify(notifyLoginStarted, Auth2LoginType.oidcIllinois);

        _OidcLogin? oidcLogin = await getOidcData();
        if (oidcLogin?.loginUrl != null) {
          _oidcLogin = oidcLogin;
          _oidcLink = link;
          await _launchUrl(_oidcLogin?.loginUrl);
        }
        else {
          completeOidcAuthentication(false);
          return false;
        }
      }

      Completer<bool?> completer = Completer<bool?>();
      _oidcAuthenticationCompleters!.add(completer);
      return completer.future;
    }
    
    return false;
  }

  @protected
  Future<bool> handleOidcAuthentication(Uri uri) async {
    
    RokwirePlugin.dismissSafariVC();
    
    cancelOidcAuthenticationTimer();

    _processingOidcAuthentication = true;
    bool result = (_oidcLink == true) ?
      await linkAccountAuthType(Auth2LoginType.oidcIllinois, uri.toString(), _oidcLogin?.params) :
      await processOidcAuthentication(uri);
    _processingOidcAuthentication = false;

    completeOidcAuthentication(result);
    return result;
  }

  @protected
  Future<bool> processOidcAuthentication(Uri? uri) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.oidcIllinois),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'creds': uri?.toString(),
        'params': _oidcLogin?.params,
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': _deviceInfo,
      });
      _oidcLogin = null;

      Response? response = await Network().post(url, headers: headers, body: post);
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      bool result = await processLoginResponse(responseJson);
      _log(result ? "Auth2: login succeeded: ${response?.statusCode}\n${response?.body}" : "Auth2: login failed: ${response?.statusCode}\n${response?.body}");
      return result;
    }
    return false;
  }

  @protected
  Future<bool> processLoginResponse(Map<String, dynamic>? responseJson) async {
    if (responseJson != null) {
      Auth2Token? token = Auth2Token.fromJson(JsonUtils.mapValue(responseJson['token']));
      Auth2Account? account = Auth2Account.fromJson(JsonUtils.mapValue(responseJson['account']),
        prefs: _anonymousPrefs ?? Auth2UserPrefs.empty(),
        profile: _anonymousProfile ?? Auth2UserProfile.empty());

      if ((token != null) && token.isValid && (account != null) && account.isValid) {
        applyLogin(account, token, params: JsonUtils.mapValue(responseJson['params']));
        return true;
      }
    }
    return false;
  }

  @protected
  Future<void> applyLogin(Auth2Account account, Auth2Token token, { Map<String, dynamic>? params }) async {

    _refreshTonenFailCounts.remove(_token?.refreshToken);

    bool? prefsUpdated = account.prefs?.apply(_anonymousPrefs);
    bool? profileUpdated = account.profile?.apply(_anonymousProfile);
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

    NotificationService().notify(notifyProfileChanged);
    NotificationService().notify(notifyPrefsChanged);
    NotificationService().notify(notifyLoginChanged);
  }

  @protected
  Future<_OidcLogin?> getOidcData() async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null)) {

      String url = "${Config().coreUrl}/services/auth/login-url";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.oidcIllinois),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'redirect_uri': oidcRedirectUrl,
      });
      Response? response = await Network().post(url, headers: headers, body: post);
      return _OidcLogin.fromJson(JsonUtils.decodeMap(response?.body));
    }
    return null;
  }

  @protected
  void createOidcAuthenticationTimerIfNeeded() {
    if ((_oidcAuthenticationCompleters != null) && (_processingOidcAuthentication != true)) {
      if (_oidcAuthenticationTimer != null) {
        _oidcAuthenticationTimer!.cancel();
      }
      _oidcAuthenticationTimer = Timer(const Duration(milliseconds: 100), () {
        completeOidcAuthentication(null);
        _oidcAuthenticationTimer = null;
      });
    }
  }

  @protected
  void cancelOidcAuthenticationTimer() {
    if(_oidcAuthenticationTimer != null){
      _oidcAuthenticationTimer!.cancel();
      _oidcAuthenticationTimer = null;
    }
  }

  @protected
  void completeOidcAuthentication(bool? success) {
    
    _notifyLogin(Auth2LoginType.oidcIllinois, success);

    _oidcLogin = null;
    _oidcLink = null;

    if (_oidcAuthenticationCompleters != null) {
      List<Completer<bool?>> loginCompleters = _oidcAuthenticationCompleters!;
      _oidcAuthenticationCompleters = null;

      for(Completer<bool?> completer in loginCompleters){
        completer.complete(success);
      }
    }
  }

  // Phone Authentication

  Future<bool> authenticateWithPhone(String? phoneNumber) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (phoneNumber != null)) {
      NotificationService().notify(notifyLoginStarted, Auth2LoginType.phoneTwilio);

      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.phoneTwilio),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'creds': {
          "phone": phoneNumber,
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': _deviceInfo,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      return (response?.statusCode == 200);
    }
    return false;
  }

  Future<bool> handlePhoneAuthentication(String? phoneNumber, String? code) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (phoneNumber != null) && (code != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.phoneTwilio),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'creds': {
          "phone": phoneNumber,
          "code": code,
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': _deviceInfo,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      bool result = await processLoginResponse(responseJson);
      _notifyLogin(Auth2LoginType.phoneTwilio, result);
      return result;
    }
    return false;
  }

  // Email Authentication

  Future<Auth2EmailSignInResult> authenticateWithEmail(String? email, String? password) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (email != null) && (password != null)) {
      
      NotificationService().notify(notifyLoginStarted, Auth2LoginType.email);

      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.email),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'creds': {
          "email": email,
          "password": password
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': _deviceInfo,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        bool result = await processLoginResponse(JsonUtils.decodeMap(response?.body));
        _notifyLogin(Auth2LoginType.email, result);
        return result ? Auth2EmailSignInResult.succeded : Auth2EmailSignInResult.failed;
      }
      else {
        _notifyLogin(Auth2LoginType.email, false);
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'unverified') {
          return Auth2EmailSignInResult.failedNotActivated;
        }
        else if (error?.status == 'verification-expired') {
          return Auth2EmailSignInResult.failedActivationExpired;
        }
      }
    }
    return Auth2EmailSignInResult.failed;
  }

  Future<Auth2EmailSignUpResult> signUpWithEmail(String? email, String? password) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (email != null) && (password != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.email),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'creds': {
          "email": email,
          "password": password
        },
        'params': {
          "sign_up": true,
          "confirm_password": password
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': _deviceInfo,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        return Auth2EmailSignUpResult.succeded;
      }
      else if (Auth2Error.fromJson(JsonUtils.decodeMap(response?.body))?.status == 'already-exists') {
        return Auth2EmailSignUpResult.failedAccountExist;
      }
    }
    return Auth2EmailSignUpResult.failed;
  }

  Future<Auth2EmailAccountState?> checkEmailAccountState(String? email) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (email != null)) {
      String url = "${Config().coreUrl}/services/auth/account/exists";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.email),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'user_identifier': email,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        //TBD: handle Auth2EmailAccountState.unverified
        return JsonUtils.boolValue(JsonUtils.decode(response?.body))! ? Auth2EmailAccountState.verified : Auth2EmailAccountState.nonExistent;
      }
    }
    return null;
  }

  Future<bool> resetEmailPassword(String? email) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (email != null)) {
      String url = "${Config().coreUrl}/services/auth/credential/forgot/initiate";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.email),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'user_identifier': email,
        'identifier': email,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      return (response?.statusCode == 200);
    }
    return false;
  }

  Future<bool> resentActivationEmail(String? email) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (email != null)) {
      String url = "${Config().coreUrl}/services/auth/credential/send-verify";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.email),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'user_identifier': email,
        'identifier': email,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      return (response?.statusCode == 200);
    }
    return false;
  }

  // Notify Login

  void _notifyLogin(Auth2LoginType loginType, bool? result) {
    if (result != null) {
      NotificationService().notify(result ? notifyLoginSucceeded : notifyLoginFailed, loginType);
      NotificationService().notify(notifyLoginFinished, loginType);
    }
  }

  // Account Linking

  Future<bool> linkAccountAuthType(Auth2LoginType? loginType, dynamic creds, Map<String, dynamic>? params) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (loginType != null)) {
      String url = "${Config().coreUrl}/services/auth/account/auth-type/link";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(loginType),
        'app_type_identifier': Config().appPlatformId,
        'creds': creds,
        'params': params,
      });
      _oidcLink = null;

      Response? response = await Network().post(url, headers: headers, body: post, auth: Auth2());
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      List<Auth2Type>? authTypes = (responseJson != null) ? Auth2Type.listFromJson(JsonUtils.listValue(responseJson['auth_types'])) : null;
      if (authTypes != null) {
        Storage().auth2Account = _account = Auth2Account.fromOther(_account, authTypes: authTypes);
        NotificationService().notify(notifyLinkChanged);
        return true;
      }
    }
    return false;
  }

  Future<bool> unlinkAccountAuthType(Auth2LoginType? loginType, String identifier) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (loginType != null)) {
      String url = "${Config().coreUrl}/services/auth/account/auth-type/link";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? body = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(loginType),
        'app_type_identifier': Config().appPlatformId,
        'identifier': identifier,
      });

      Response? response = await Network().delete(url, headers: headers, body: body, auth: Auth2());
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      List<Auth2Type>? authTypes = (responseJson != null) ? Auth2Type.listFromJson(JsonUtils.listValue(responseJson['auth_types'])) : null;
      if (authTypes != null) {
        Storage().auth2Account = _account = Auth2Account.fromOther(_account, authTypes: authTypes);
        NotificationService().notify(notifyLinkChanged);
        return true;
      }
    }
    return false;
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

  void logout({ Auth2UserPrefs? prefs }) {
    if (_token != null) {
      _log("Auth2: logout");
      _refreshTonenFailCounts.remove(_token?.refreshToken);

      Storage().auth2AnonymousPrefs = _anonymousPrefs = prefs ?? _account?.prefs ?? Auth2UserPrefs.empty();
      Storage().auth2AnonymousProfile = _anonymousProfile = Auth2UserProfile.empty();
      Storage().auth2Token = _token = null;
      Storage().auth2Account = _account = null;

      _updateUserPrefsTimer?.cancel();
      _updateUserPrefsTimer = null;

      _updateUserPrefsClient?.close();
      _updateUserPrefsClient = null;

      NotificationService().notify(notifyProfileChanged);
      NotificationService().notify(notifyPrefsChanged);
      NotificationService().notify(notifyLoginChanged);
      NotificationService().notify(notifyLogout);
    }
  }

  // Delete

  Future<bool> deleteUser() async {
    NotificationService().notify(notifyPrepareUserDelete);
    if (await _deleteUserAccount()) {
      logout(prefs: Auth2UserPrefs.empty());
      NotificationService().notify(notifyUserDeleted);
      return true;
    }
    return false;
  }

  Future<bool> _deleteUserAccount() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account";
      Response? response = await Network().delete(url, auth: Auth2());
      return response?.statusCode == 200;
    }
    return false;
  }

  // Refresh

  Future<Auth2Token?> refreshToken(Auth2Token token) async {
    if ((Config().coreUrl != null) && (token.refreshToken != null)) {
      try {
        Future<Response?>? refreshTokenFuture = _refreshTokenFutures[token.refreshToken];

        if (refreshTokenFuture != null) {
          _log("Auth2: will await refresh token:\nSource Token: ${token.refreshToken}");
          Response? response = await refreshTokenFuture;
          Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
          Auth2Token? responseToken = (responseJson != null) ? Auth2Token.fromJson(JsonUtils.mapValue(responseJson['token'])) : null;
          _log("Auth2: did await refresh token: ${responseToken?.isValid}\nSource Token: ${token.refreshToken}");
          return ((responseToken != null) && responseToken.isValid) ? responseToken : null;
        }
        else {
          _log("Auth2: will refresh token:\nSource Token: ${token.refreshToken}");

          _refreshTokenFutures[token.refreshToken!] = refreshTokenFuture = _refreshToken(token.refreshToken);
          Response? response = await refreshTokenFuture;
          _refreshTokenFutures.remove(token.refreshToken);

          Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
          if (responseJson != null) {
            Auth2Token? responseToken = Auth2Token.fromJson(JsonUtils.mapValue(responseJson['token']));
            if ((responseToken != null) && responseToken.isValid) {
              _log("Auth2: did refresh token:\nResponse Token: ${responseToken.refreshToken}\nSource Token: ${token.refreshToken}");
              _refreshTonenFailCounts.remove(token.refreshToken);

              if (token == _token) {
                applyToken(responseToken, params: JsonUtils.mapValue(responseJson['params']));
                return responseToken;
              }
              else if (token == _anonymousToken) {
                Storage().auth2AnonymousToken = _anonymousToken = responseToken;
                return responseToken;
              }
            }
          }

          _log("Auth2: failed to refresh token: ${response?.statusCode}\n${response?.body}\nSource Token: ${token.refreshToken}");
          int refreshTonenFailCount  = (_refreshTonenFailCounts[token.refreshToken] ?? 0) + 1;
          if (((response?.statusCode == 400) || (response?.statusCode == 401)) || (Config().refreshTokenRetriesCount <= refreshTonenFailCount)) {
            if (token == _token) {
              logout();
            }
            else if (token == _anonymousToken) {
              await authenticateAnonymously();
            }
          }
          else {
            _refreshTonenFailCounts[token.refreshToken!] = refreshTonenFailCount;
          }
        }
      }
      catch(e) {
        debugPrint(e.toString());
        _refreshTokenFutures.remove(token.refreshToken); // make sure to clear this in case something went wrong.
      }
    }
    return null;
  }

  @protected
  void applyToken(Auth2Token token, { Map<String, dynamic>? params }) {
    Storage().auth2Token = _token = token;
  }

  static Future<Response?> _refreshToken(String? refreshToken) async {
    if ((Config().coreUrl != null) && (refreshToken != null)) {
      String url = "${Config().coreUrl}/services/auth/refresh";
      
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'api_key': Config().rokwireApiKey,
        'refresh_token': refreshToken
      });

      return Network().post(url, headers: headers, body: post);
    }
    return null;
  }

  // User Prefs

  @protected
  void onUserPrefsChanged(Auth2UserPrefs? prefs) {
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
      String url = "${Config().coreUrl}/services/account/preferences";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode(_account!.prefs);

      Client client = Client();
      _updateUserPrefsClient?.close();
      _updateUserPrefsClient = client;
      
      Response? response = await Network().put(url, auth: Auth2(), headers: headers, body: post, client: _updateUserPrefsClient);
      
      if (identical(client, _updateUserPrefsClient)) {
        if (response?.statusCode == 200) {
          _updateUserPrefsTimer?.cancel();
          _updateUserPrefsTimer = null;
        }
        else {
          _updateUserPrefsTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
            if (_updateUserPrefsClient == null) {
              _saveAccountUserPrefs();
            }
          });
        }
      }
      _updateUserPrefsClient = null;
    }
  }

  Future<Auth2UserPrefs?> _loadAccountUserPrefs() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account/preferences";
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? Auth2UserPrefs.fromJson(JsonUtils.decodeMap(response?.body)) : null;
    }
    return null;
  }

  Future<void> _refreshAccountUserPrefs() async {
    Auth2UserPrefs? prefs = await _loadAccountUserPrefs();
    if ((prefs != null) && (prefs != _account?.prefs)) {
      if (_account?.prefs?.apply(prefs, notify: true) ?? false) {
        Storage().auth2Account = _account;
        NotificationService().notify(notifyPrefsChanged);
      }
    }
  }

  // User Profile
  
  Future<Auth2UserProfile?> loadUserProfile() async {
    return await _loadAccountUserProfile();
  }

  Future<bool> saveAccountUserProfile(Auth2UserProfile? profile) async {
    if (await _saveAccountUserProfile(profile)) {
      if (_account?.profile?.apply(profile) ?? false) {
        Storage().auth2Account = _account;
        NotificationService().notify(notifyProfileChanged);
      }
      return true;
    }
    return false;
  }

  Future<Auth2UserProfile?> _loadAccountUserProfile() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account/profile";
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? Auth2UserProfile.fromJson(JsonUtils.decodeMap(response?.body)) : null;
    }
    return null;
  }

  Future<bool> _saveAccountUserProfile(Auth2UserProfile? profile) async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account/profile";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode(profile!.toJson());
      Response? response = await Network().put(url, auth: Auth2(), headers: headers, body: post);
      return (response?.statusCode == 200);
    }
    return false;
  }

  Future<void> _refreshAccountUserProfile() async {
    Auth2UserProfile? profile = await _loadAccountUserProfile();
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
      debugPrint(e.toString());
    }
  }

  static void _log(String message) {
    Log.d(message, lineLength: 996); // max line length of VS Code Debug Console
  }

}

class _OidcLogin {
  final String? loginUrl;
  final Map<String, dynamic>? params;
  
  _OidcLogin({this.loginUrl, this.params});

  static _OidcLogin? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? _OidcLogin(
      loginUrl: JsonUtils.stringValue(json['login_url']),
      params: JsonUtils.mapValue(json['params'])
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'login_url' : loginUrl,
      'params': params
    };
  }  

}

enum Auth2EmailAccountState {
  nonExistent,
  unverified,
  verified,
}

enum Auth2EmailSignUpResult {
  succeded,
  failed,
  failedAccountExist,
}

enum Auth2EmailSignInResult {
  succeded,
  failed,
  failedActivationExpired,
  failedNotActivated,
}
