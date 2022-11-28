
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart' as rokwire;
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class Auth2 extends rokwire.Auth2 {

  static String get notifyLoginStarted      => rokwire.Auth2.notifyLoginStarted;
  static String get notifyLoginSucceeded    => rokwire.Auth2.notifyLoginSucceeded;
  static String get notifyLoginFailed       => rokwire.Auth2.notifyLoginFailed;
  static String get notifyLoginChanged      => rokwire.Auth2.notifyLoginChanged;
  static String get notifyLoginFinished     => rokwire.Auth2.notifyLoginFinished;
  static String get notifyLogout            => rokwire.Auth2.notifyLogout;
  static String get notifyAccountChanged    => rokwire.Auth2.notifyAccountChanged;
  static String get notifyProfileChanged    => rokwire.Auth2.notifyProfileChanged;
  static String get notifyPrefsChanged      => rokwire.Auth2.notifyPrefsChanged;
  static String get notifyUserDeleted       => rokwire.Auth2.notifyUserDeleted;
  static String get notifyPrepareUserDelete => rokwire.Auth2.notifyPrepareUserDelete;

  static const String notifyCardChanged     = "edu.illinois.rokwire.auth2.card.changed";

  static const String _authCardName         = "idCard.json";

  Auth2Token? _uiucToken;

  AuthCard?  _authCard;
  File? _authCardCacheFile;

  // Singletone Factory

  @protected
  Auth2.internal() : super.internal();

  factory Auth2() => ((rokwire.Auth2.instance is Auth2) ? (rokwire.Auth2.instance as Auth2) : (rokwire.Auth2.instance = Auth2.internal()));

  // Service

  @override
  void createService() {
    super.createService();
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this, [
      FlexUI.notifyChanged,
    ]);
    super.destroyService();
  }

  @override
  Future<void> initService() async {
    _uiucToken = Storage().auth2UiucToken;

    _authCardCacheFile = await _getAuthCardCacheFile();
    _authCard = await _loadAuthCardFromCache();

    await super.initService();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    super.onNotification(name, param);
    if (name == FlexUI.notifyChanged) {
      _checkEnabled();
    }
  }

  void _checkEnabled() {
    if (isLoggedIn && !FlexUI().isAuthenticationAvailable) {
      logout();
    }
  }

  // Getters
  AuthCard? get authCard => _authCard;
  Auth2Token? get uiucToken => _uiucToken;
  bool get canFavorite => FlexUI().isPersonalizationAvailable;

  // Overrides

  @override
  void onAppLivecycleStateChanged(AppLifecycleState? state) {
    super.onAppLivecycleStateChanged(state);
    if (state == AppLifecycleState.resumed) {
      //TMP: Log.d('Core Access Token: ${token?.accessToken}', lineLength: 512);
      //TMP: Log.d('UIUC Access Token: ${uiucToken?.accessToken}', lineLength: 512);
      _refreshAuthCardIfNeeded();
    }
  }

  @override
  Future<void> applyLogin(Auth2Account account, Auth2Token token, { Map<String, dynamic>? params }) async {
    await super.applyLogin(account, token, params: params);

    Auth2Token? uiucToken = (params != null) ? Auth2Token.fromJson(JsonUtils.mapValue(params['oidc_token'])) : null;
    Storage().auth2UiucToken = _uiucToken = ((uiucToken != null) && uiucToken.isValidUiuc) ? uiucToken : null;

    String? authCardString = (StringUtils.isNotEmpty(account.authType?.uiucUser?.uin) && StringUtils.isNotEmpty(uiucToken?.accessToken)) ?
      await _loadAuthCardStringFromNet(uin: account.authType?.uiucUser?.uin, accessToken: uiucToken?.accessToken) : null;
    _authCard = AuthCard.fromJson(JsonUtils.decodeMap(authCardString));
    Storage().auth2CardTime = (_authCard != null) ? DateTime.now().millisecondsSinceEpoch : null;
    await _saveAuthCardStringToCache(authCardString);

    NotificationService().notify(notifyCardChanged);
  }

  @override
  void applyToken(Auth2Token token, { Map<String, dynamic>? params }) {
    super.applyToken(token, params: params);

    Auth2Token? uiucToken = (params != null) ? Auth2Token.fromJson(JsonUtils.mapValue(params['oidc_token'])) : null;
    Storage().auth2UiucToken = _uiucToken = ((uiucToken != null) && uiucToken.isValidUiuc) ? uiucToken : null;
  }

  @override
  void logout({ Auth2UserPrefs? prefs }) {
    if (_uiucToken != null) {
      Storage().auth2UiucToken = _uiucToken = null;
    }

    if (_authCard != null) {
      _authCard = null;
      _saveAuthCardStringToCache(null);
      Storage().auth2CardTime = null;
      NotificationService().notify(notifyCardChanged);
    }

    super.logout(prefs: prefs);
  }

  // Overrides

  @override
  String? get deviceIdIdentifier => 'deviceUUID';

  @override
  String? get deviceIdIdentifier2 => 'deviceUUID';

  @override
  Auth2UserPrefs get defaultAnonimousPrefs => Auth2UserPrefs.fromStorage(
    profile: Storage().userProfile,
    includedFoodTypes: Storage().includedFoodTypesPrefs,
    excludedFoodIngredients: Storage().excludedFoodIngredientsPrefs,
    settings: FirebaseMessaging.storedSettings,
  );

  // Auth Card

  String get authCardName => _authCardName;

  Future<File> _getAuthCardCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, authCardName);
    return File(cacheFilePath);
  }

  Future<String?> _loadAuthCardStringFromCache() async {
    try {
      return ((_authCardCacheFile != null) && await _authCardCacheFile!.exists()) ? Storage().decrypt(await _authCardCacheFile!.readAsString()) : null;
    }
    on Exception catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<void> _saveAuthCardStringToCache(String? value) async {
    try {
      if (_authCardCacheFile != null) {
        if (value != null) {
          await _authCardCacheFile!.writeAsString(Storage().encrypt(value)!, flush: true);
        }
        else if (await _authCardCacheFile!.exists()) {
          await _authCardCacheFile!.delete();
        }
      }
    }
    on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<AuthCard?> _loadAuthCardFromCache() async {
    return AuthCard.fromJson(JsonUtils.decodeMap(await _loadAuthCardStringFromCache()));
  }

  Future<String?> _loadAuthCardStringFromNet({String? uin, String? accessToken}) async {
    String? url = Config().iCardUrl;
    if (StringUtils.isNotEmpty(url) &&  StringUtils.isNotEmpty(uin) && StringUtils.isNotEmpty(accessToken)) {
      Response? response = await Network().post(url, headers: {
        'UIN': uin,
        'access_token': accessToken
      });
      return (response?.statusCode == 200) ? response!.body : null;
    }
    return null;
  }

  Future<void> _refreshAuthCardIfNeeded() async {
    int? lastCheckTime = Storage().auth2CardTime;
    DateTime? lastCheckDate = (lastCheckTime != null) ? DateTime.fromMillisecondsSinceEpoch(lastCheckTime) : null;
    DateTime? lastCheckMidnight = DateTimeUtils.midnight(lastCheckDate);

    DateTime now = DateTime.now();
    DateTime? todayMidnight = DateTimeUtils.midnight(now);

    // Do it one per day
    if ((lastCheckMidnight == null) || (lastCheckMidnight.compareTo(todayMidnight!) < 0)) {
      if (await _refreshAuthCard() != null) {
        Storage().auth2CardTime = now.millisecondsSinceEpoch;
      }
    }
  }

  Future<AuthCard?> _refreshAuthCard() async {
    String? authCardString = await _loadAuthCardStringFromNet(uin: account?.authType?.uiucUser?.uin, accessToken : uiucToken?.accessToken);
    AuthCard? authCard = AuthCard.fromJson(JsonUtils.decodeMap((authCardString)));
    if ((authCard != null) && (authCard != _authCard)) {
      _authCard = authCard;
      await _saveAuthCardStringToCache(authCardString);
      NotificationService().notify(notifyCardChanged);
    }
    return authCard;
  }
}
