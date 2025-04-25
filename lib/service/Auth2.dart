
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/log.dart';
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
  static String get notifyLinkChanged       => rokwire.Auth2.notifyLinkChanged;
  static String get notifyAccountChanged    => rokwire.Auth2.notifyAccountChanged;
  static String get notifyProfileChanged    => rokwire.Auth2.notifyProfileChanged;
  static String get notifyPrefsChanged      => rokwire.Auth2.notifyPrefsChanged;
  static String get notifyPrivacyChanged    => rokwire.Auth2.notifyPrivacyChanged;
  static String get notifyUserDeleted       => rokwire.Auth2.notifyUserDeleted;

  static const String notifyCardChanged     = "edu.illinois.rokwire.auth2.card.changed";
  static const String notifyProfilePictureChanged  = "edu.illinois.rokwire.auth2.profile.picture.changed";
  static const String notifyProfileNamePronunciationChanged = "edu.illinois.rokwire.auth2.profile.name.pronunciation.changed";

  static const String _iCardFileName             = "idCard.json";
  static const String _profilePictureFileName      = "profilePicture.small.bin";

  Auth2Token? _uiucToken;

  AuthCard? _iCard;
  File? _iCardCacheFile;

  Uint8List? _profilePicture;
  File? _profilePictureCacheFile;

  DateTime? _pausedDateTime;

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
      Content.notifyUserProfilePictureChanged,
      Auth2.notifyAccountChanged,
      Auth2.notifyProfileChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this, [
      FlexUI.notifyChanged,
      Content.notifyUserProfilePictureChanged,
      Auth2.notifyAccountChanged,
      Auth2.notifyProfileChanged,
    ]);
    super.destroyService();
  }

  @override
  Future<void> initService() async {
    _uiucToken = Storage().auth2UiucToken;

    Future.wait([
      _initICardFromCache(),
      _initProfilePictureFromCache(),
    ]);

    await super.initService();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    super.onNotification(name, param);
    if (name == FlexUI.notifyChanged) {
      _checkEnabled();
    }
    else if (name == Content.notifyUserProfilePictureChanged ||
        name == Auth2.notifyAccountChanged ||
        name == Auth2.notifyProfileChanged) {
      _refreshProfilePicture();
    }
  }

  void _checkEnabled() {
    if (isLoggedIn && !FlexUI().isAuthenticationAvailable) {
      onUserPrefsChanged(account?.prefs).then((_) {
        logout();
      });
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      //TMP: _convertFile('student.guide.import.json', 'Illinois_Student_Guide_Final.json');
      //Log.d("UIUC Token: ${JsonUtils.encode(_uiucToken?.toJson())}", lineLength: 512);

      _refreshICardIfNeeded();

      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refreshProfilePicture();
        }
      }
    }
  }

  // Getters
  
  Auth2Token? get uiucToken => _uiucToken;

  AuthCard? get iCard => _iCard;

  Uint8List? get profilePicture => _profilePicture;

  bool get canFavorite => FlexUI().isPersonalizationAvailable;

  // Overrides

  @override
  void onAppLivecycleStateChanged(AppLifecycleState? state) {
    super.onAppLivecycleStateChanged(state);
    _onAppLivecycleStateChanged(state);
  }

  @override
  Future<void> applyLogin(Auth2Account account, Auth2Token token, { Auth2AccountScope? scope, Map<String, dynamic>? params }) async {

    Auth2Token? uiucToken = (params != null) ? Auth2Token.fromJson(JsonUtils.mapValue(params['oidc_token'])) : null;
    Storage().auth2UiucToken = _uiucToken = ((uiucToken != null) && uiucToken.isValidUiuc) ? uiucToken : null;

    Future.wait([
      _initICardOnLogin(account, token),
      _initProfilePictureOnLogin(account, token),
    ]);

    await super.applyLogin(account, token, scope: scope, params: params);
    
    NotificationService().notify(notifyCardChanged);
    NotificationService().notify(notifyProfilePictureChanged);
    NotificationService().notify(notifyProfileNamePronunciationChanged);
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

    if (_iCard != null) {
      _iCard = null;
      _saveICardStringToCache(null);
      Storage().auth2CardTime = null;
      NotificationService().notify(notifyCardChanged);
    }

    if (_profilePicture != null) {
      _profilePicture = null;
      _saveProfilePictureToCache(null);
      NotificationService().notify(notifyProfilePictureChanged);
    }

    super.logout(prefs: prefs);
  }

  @protected
  void onUserAccountProfileChanged(Auth2UserProfile? profile) {
    _refreshProfilePicture();
  }

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

  // iCard

  String get iCardFileName => _iCardFileName;

  Future<File?> _getICardCacheFile() async {
    Directory? appDocDir = kIsWeb ? null : await getApplicationDocumentsDirectory();
    String? cacheFilePath = (appDocDir != null) ? join(appDocDir.path, iCardFileName) : null;
    return (cacheFilePath != null) ? File(cacheFilePath) : null;
  }

  Future<String?> _loadICardStringFromCache() async {
    try {
      return ((_iCardCacheFile != null) && await _iCardCacheFile!.exists()) ? Storage().decrypt(await _iCardCacheFile!.readAsString()) : null;
    }
    on Exception catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<void> _saveICardStringToCache(String? value) async {
    try {
      if (_iCardCacheFile != null) {
        if (value != null) {
          await _iCardCacheFile!.writeAsString(Storage().encrypt(value)!, flush: true);
        }
        else if (await _iCardCacheFile!.exists()) {
          await _iCardCacheFile!.delete();
        }
      }
    }
    on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<AuthCard?> _loadICardFromCache() async {
    return AuthCard.fromJson(JsonUtils.decodeMap(await _loadICardStringFromCache()));
  }

  Future<void> _initICardFromCache() async {
    _iCardCacheFile = await _getICardCacheFile();
    _iCard = await _loadICardFromCache();
  }

  Future<void> _initICardOnLogin(Auth2Account account, Auth2Token token) async {
    String? iCardString = (StringUtils.isNotEmpty(account.authType?.uiucUser?.uin) && StringUtils.isNotEmpty(uiucToken?.accessToken)) ?
      await _loadICardStringFromNet(uin: account.authType?.uiucUser?.uin, accessToken: uiucToken?.accessToken) : null;
    _iCard = AuthCard.fromJson(JsonUtils.decodeMap(iCardString));
    Storage().auth2CardTime = (_iCard != null) ? DateTime.now().millisecondsSinceEpoch : null;
    await _saveICardStringToCache(iCardString);
  }

  Future<Response?> _loadICardFromNetEx({String? uin, String? accessToken}) async =>
      (StringUtils.isNotEmpty(Config().iCardUrl) &&  StringUtils.isNotEmpty(uin) && StringUtils.isNotEmpty(accessToken)) ?
      Network().post(Config().iCardUrl, headers: {
        'UIN': uin,
        'access_token': accessToken
      }, auth: rokwire.Auth2Csrf()) : null;

  Future<String?> _loadICardStringFromNet({String? uin, String? accessToken}) async {
    Response? response = await _loadICardFromNetEx(uin: uin, accessToken: accessToken);
    return (response?.statusCode == 200) ? response?.body : null;
  }

  Future<void> _refreshICardIfNeeded() async {
    int? lastCheckTime = Storage().auth2CardTime;
    DateTime? lastCheckDate = (lastCheckTime != null) ? DateTime.fromMillisecondsSinceEpoch(lastCheckTime) : null;
    DateTime? lastCheckMidnight = DateTimeUtils.midnight(lastCheckDate);

    DateTime now = DateTime.now();
    DateTime? todayMidnight = DateTimeUtils.midnight(now);

    // Do it one per day
    if ((lastCheckMidnight == null) || (lastCheckMidnight.compareTo(todayMidnight!) < 0)) {
      if (await _refreshICard() != null) {
        Storage().auth2CardTime = now.millisecondsSinceEpoch;
      }
    }
  }

  Future<AuthCard?> _refreshICard() async {
    String? iCardString = await _loadICardStringFromNet(uin: account?.authType?.uiucUser?.uin, accessToken : uiucToken?.accessToken);
    AuthCard? iCard = AuthCard.fromJson(JsonUtils.decodeMap((iCardString)));
    if ((iCard != null) && (iCard != _iCard)) {
      _iCard = iCard;
      await _saveICardStringToCache(iCardString);
      Log.d('iCard Refreshed');
      NotificationService().notify(notifyCardChanged);
    }
    return iCard;
  }

  Future<Response?> loadICardResponse() async =>
    _loadICardFromNetEx(uin: account?.authType?.uiucUser?.uin, accessToken : uiucToken?.accessToken);


  // Auth Picture

  String get profilePictureFileName => _profilePictureFileName;

  Future<File?> _getProfilePictureCacheFile() async {
    Directory? appDocDir = kIsWeb ? null : await getApplicationDocumentsDirectory();
    String? cacheFilePath = (appDocDir != null) ? join(appDocDir.path, profilePictureFileName) : null;
    return (cacheFilePath != null) ? File(cacheFilePath) : null;
  }

  Future<Uint8List?> _loadProfilePictureFromCache() async {
    try {
      if ((_profilePictureCacheFile != null) && await _profilePictureCacheFile!.exists()) {
        String? base64 = Storage().decrypt(await _profilePictureCacheFile!.readAsString());
        return (base64 != null) ? base64Decode(base64) : null;
      }
    }
    on Exception catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<void> _saveProfilePictureToCache(Uint8List? value) async {
    try {
      if (_profilePictureCacheFile != null) {
        if (value != null) {
          await _profilePictureCacheFile!.writeAsString(Storage().encrypt(base64Encode(value)) ?? '', flush: true);
        }
        else if (await _profilePictureCacheFile!.exists()) {
          await _profilePictureCacheFile!.delete();
        }
      }
    }
    on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _initProfilePictureFromCache() async {
    _profilePictureCacheFile = await _getProfilePictureCacheFile();
    _profilePicture = await _loadProfilePictureFromCache();
  }

  Future<void> _initProfilePictureOnLogin(Auth2Account account, Auth2Token token) async {
    _profilePicture = StringUtils.isNotEmpty(account.id) && StringUtils.isNotEmpty(account.profile?.photoUrl) && StringUtils.isNotEmpty(token.accessToken) ?
      await _loadProfilePictureFromNet(accountId: account.id, token: token) : null;
    await _saveProfilePictureToCache(_profilePicture);
  }

  Future<Uint8List?> _loadProfilePictureFromNet({String? accountId, Auth2Token? token}) async {
    String? accessToken = token?.accessToken;
    String? url = Content().getUserPhotoUrl(type: UserProfileImageType.small);
    if (StringUtils.isNotEmpty(url) &&  StringUtils.isNotEmpty(accountId) && StringUtils.isNotEmpty(accessToken)) {
      String? tokenType = token?.tokenType ?? 'Bearer';
      Response? response = await Network().get(url, headers: {
        HttpHeaders.authorizationHeader : "$tokenType $accessToken"
      });
      return (response?.statusCode == 200) ? response?.bodyBytes : null;
    }
    else {
      return null;
    }
  }

  Future<void> _refreshProfilePicture() async {
    Uint8List? profilePicture = _profilePicture;
    if (StringUtils.isNotEmpty(Auth2().account?.id) && StringUtils.isNotEmpty(Auth2().account?.profile?.photoUrl)) {
      ImagesResult? result = await Content().loadUserPhoto(type: UserProfileImageType.small);
      if ((result != null) && (result.resultType == ImagesResultType.succeeded)) {
        profilePicture = result.imageData;
      }
    }
    else {
      profilePicture = null;
    }

    if (!listEquals(_profilePicture, profilePicture)) {
      _profilePicture = profilePicture;
      await _saveProfilePictureToCache(profilePicture);
      NotificationService().notify(notifyProfilePictureChanged);
    }
  }
}
