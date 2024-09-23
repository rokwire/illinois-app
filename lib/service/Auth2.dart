
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:neom/model/Auth2.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/FirebaseMessaging.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:neom/service/Storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart' as rokwire;
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:universal_io/io.dart';


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
  static String get notifyUserDeleted       => rokwire.Auth2.notifyUserDeleted;
  static String get notifyPrepareUserDelete => rokwire.Auth2.notifyPrepareUserDelete;

  static const String notifyCardChanged             = "edu.illinois.rokwire.auth2.card.changed";
  static const String notifyPictureChanged          = "edu.illinois.rokwire.auth2.picture.changed";
  static const String notifyVoiceRecordChanged = "edu.illinois.rokwire.auth2.voice.record.changed";

  static const String _authCardName             = "idCard.json";
  static const String _authPictureName          = "profilePicture.small.bin";
  static const String _authVoiceRecordName = "profileVoiceRecord.bin";

  Auth2Token? _uiucToken;

  AuthCard?  _authCard;
  File? _authCardCacheFile;

  Uint8List? _authPicture;
  File? _authPictureCacheFile;

  Uint8List? _authVoiceRecord;
  File? _authVoiceRecordCacheFile;

  DateTime?      _pausedDateTime;

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
      Content.notifyUserProfileVoiceRecordChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this, [
      FlexUI.notifyChanged,
      Content.notifyUserProfilePictureChanged,
      Content.notifyUserProfileVoiceRecordChanged,
    ]);
    super.destroyService();
  }

  @override
  Future<void> initService() async {
    _uiucToken = Storage().auth2UiucToken;

    _authCardCacheFile = await _getAuthCardCacheFile();
    _authCard = await _loadAuthCardFromCache();

    _authPictureCacheFile = await _getAuthPictureCacheFile();
    _authPicture = await _loadAuthPictureFromCache();

    _authVoiceRecordCacheFile = await _getAuthVoiceRecordCacheFile();
    _authVoiceRecord = await _loadAuthVoiceRecordFromCache();

    await super.initService();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    super.onNotification(name, param);
    if (name == FlexUI.notifyChanged) {
      _checkEnabled();
    }
    else if (name == Content.notifyUserProfilePictureChanged) {
      _refreshAuthPicture();
    }

    else if (name == Content.notifyUserProfileVoiceRecordChanged) {
      _refreshAuthVoiceRecord();
    }
  }

  void _checkEnabled() {
    if (isLoggedIn && !FlexUI().isAuthenticationAvailable) {
      onUserPrefsChanged(account?.prefs).then((_) {
        logout();
      });
    }
  }

  void _onAppLifecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      //TMP: _convertFile('student.guide.import.json', 'Illinois_Student_Guide_Final.json');
      //Log.d("UIUC Token: ${JsonUtils.encode(_uiucToken?.toJson())}", lineLength: 512);

      _refreshAuthCardIfNeeded();

      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refreshAuthPicture();
          _refreshAuthVoiceRecord();
        }
      }
    }
  }

  // Getters
  
  AuthCard? get authCard => _authCard;
  
  Auth2Token? get uiucToken => _uiucToken;

  Uint8List? get authPicture => _authPicture;

  Uint8List? get authVoiceRecord => _authVoiceRecord;

  bool get canFavorite => FlexUI().isPersonalizationAvailable;

  // Overrides

  @override
  void onAppLifecycleStateChanged(AppLifecycleState? state) {
    super.onAppLifecycleStateChanged(state);
    _onAppLifecycleStateChanged(state);
  }

  @override
  Future<void> applyLogin(Auth2Account account, Auth2Token token, { Auth2AccountScope? scope, Map<String, dynamic>? params }) async {

    Auth2Token? uiucToken = (params != null) ? Auth2Token.fromJson(JsonUtils.mapValue(params['oidc_token'])) : null;
    Storage().auth2UiucToken = _uiucToken = ((uiucToken != null) && uiucToken.isValidUiuc) ? uiucToken : null;

    String? authCardString = (StringUtils.isNotEmpty(account.authType?.uiucUser?.uin) && StringUtils.isNotEmpty(uiucToken?.accessToken)) ?
      await _loadAuthCardStringFromNet(uin: account.authType?.uiucUser?.uin, accessToken: uiucToken?.accessToken) : null;
    _authCard = AuthCard.fromJson(JsonUtils.decodeMap(authCardString));
    Storage().auth2CardTime = (_authCard != null) ? DateTime.now().millisecondsSinceEpoch : null;
    await _saveAuthCardStringToCache(authCardString);

    _authPicture = StringUtils.isNotEmpty(account.id) && StringUtils.isNotEmpty(token.accessToken) ?
      await _loadAuthPictureFromNet(accountId: account.id, token: token) : null;
    await _saveAuthPictureToCache(_authPicture);

    if (Config().authVoiceRecordEnabled) {
      _authVoiceRecord = StringUtils.isNotEmpty(account.id) && StringUtils.isNotEmpty(token.accessToken) ?
      await _loadAuthVoiceRecordFromNet(accountId: account.id, token: token) : null;
      await _saveAuthVoiceRecordToCache(_authVoiceRecord);
    }

    await super.applyLogin(account, token, scope: scope, params: params);
    
    NotificationService().notify(notifyCardChanged);
    NotificationService().notify(notifyPictureChanged);
    NotificationService().notify(notifyVoiceRecordChanged);
  }

  @override
  Future<void> applyToken(Auth2Token token, { Map<String, dynamic>? params }) async {
    await super.applyToken(token, params: params);

    Auth2Token? uiucToken = (params != null) ? Auth2Token.fromJson(JsonUtils.mapValue(params['oidc_token'])) : null;
    Storage().auth2UiucToken = _uiucToken = ((uiucToken != null) && uiucToken.isValidUiuc) ? uiucToken : null;
  }

  @override
  Future<void> logout({ Auth2UserPrefs? prefs }) async {
    if (_uiucToken != null) {
      Storage().auth2UiucToken = _uiucToken = null;
    }

    if (_authCard != null) {
      _authCard = null;
      _saveAuthCardStringToCache(null);
      Storage().auth2CardTime = null;
      NotificationService().notify(notifyCardChanged);
    }

    if (_authPicture != null) {
      _authPicture = null;
      _saveAuthPictureToCache(null);
      NotificationService().notify(notifyPictureChanged);
    }

    if (_authVoiceRecord != null) {
      _authVoiceRecord = null;
      _saveAuthPictureToCache(null);
      NotificationService().notify(notifyVoiceRecordChanged);
    }

    await super.logout(prefs: prefs);
  }

  // Overrides

  @override
  String? get deviceIdIdentifier => 'deviceUUID';

  @override
  String? get deviceIdIdentifier2 => 'deviceUUID';

  @override
  Auth2UserPrefs get defaultAnonymousPrefs => Auth2UserPrefs.fromStorage(
    profile: Storage().userProfile,
    includedFoodTypes: Storage().includedFoodTypesPrefs,
    excludedFoodIngredients: Storage().excludedFoodIngredientsPrefs,
    settings: FirebaseMessaging.storedSettings,
  );

  // Auth Card

  String get authCardName => _authCardName;

  Future<File?> _getAuthCardCacheFile() async {
    Directory? appDocDir = kIsWeb ? null : await getApplicationDocumentsDirectory();
    String? cacheFilePath = (appDocDir != null) ? join(appDocDir.path, authCardName) : null;
    return (cacheFilePath != null) ? File(cacheFilePath) : null;
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

  Future<Response?> loadAuthCardResponse() async =>
    _loadAuthCardFromNetEx(uin: account?.authType?.uiucUser?.uin, accessToken : uiucToken?.accessToken);

  Future<Response?> _loadAuthCardFromNetEx({String? uin, String? accessToken}) async =>
    (StringUtils.isNotEmpty(Config().iCardUrl) &&  StringUtils.isNotEmpty(uin) && StringUtils.isNotEmpty(accessToken)) ?
      Network().post(Config().iCardUrl, headers: {
        'UIN': uin,
        'access_token': accessToken
      }) : null;

  Future<String?> _loadAuthCardStringFromNet({String? uin, String? accessToken}) async {
    Response? response = await _loadAuthCardFromNetEx(uin: uin, accessToken: accessToken);
    return (response?.statusCode == 200) ? response?.body : null;
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
      Log.d('Auth Card Refreshed');
      NotificationService().notify(notifyCardChanged);
    }
    return authCard;
  }


  // Auth Picture

  String get authPictureName => _authPictureName;

  Future<File?> _getAuthPictureCacheFile() async {
    Directory? appDocDir = kIsWeb ? null : await getApplicationDocumentsDirectory();
    String? cacheFilePath = (appDocDir != null) ? join(appDocDir.path, authPictureName) : null;
    return (cacheFilePath != null) ? File(cacheFilePath) : null;
  }

  Future<Uint8List?> _loadAuthPictureFromCache() async {
    try {
      if ((_authPictureCacheFile != null) && await _authPictureCacheFile!.exists()) {
        String? base64 = Storage().decrypt(await _authPictureCacheFile!.readAsString());
        return (base64 != null) ? base64Decode(base64) : null;
      }
    }
    on Exception catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<void> _saveAuthPictureToCache(Uint8List? value) async {
    try {
      if (_authPictureCacheFile != null) {
        if (value != null) {
          await _authPictureCacheFile!.writeAsString(Storage().encrypt(base64Encode(value)) ?? '', flush: true);
        }
        else if (await _authPictureCacheFile!.exists()) {
          await _authPictureCacheFile!.delete();
        }
      }
    }
    on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<Uint8List?> _loadAuthPictureFromNet({String? accountId, Auth2Token? token}) async {
    String? url = Content().getUserProfileImage(accountId: accountId, type: UserProfileImageType.small);
    String? accessToken = token?.accessToken;
    if (StringUtils.isNotEmpty(url) &&  StringUtils.isNotEmpty(accountId) && StringUtils.isNotEmpty(accessToken)) {
      String? tokenType = token?.tokenType ?? 'Bearer';
      Response? response = await Network().get(url, headers: {
        HttpHeaders.authorizationHeader : "$tokenType $accessToken"
      });
      return (response?.statusCode == 200) ? response?.bodyBytes : null;
    }
    return null;
  }

  Future<Uint8List?> _refreshAuthPicture() async {
    Uint8List? authPicture = StringUtils.isNotEmpty(Auth2().account?.id) ? await Content().loadUserProfileImage(UserProfileImageType.small, accountId: Auth2().account?.id) : null;
    if (authPicture != _authPicture) {
      _authPicture = authPicture;
      await _saveAuthPictureToCache(authPicture);
      NotificationService().notify(notifyPictureChanged);
    }
    return authPicture;
  }

  // Auth Voice Record

  String get authVoiceRecordName => _authVoiceRecordName;

  Future<File?> _getAuthVoiceRecordCacheFile() async {
    Directory? appDocDir = kIsWeb ? null : await getApplicationDocumentsDirectory();
    String? cacheFilePath = (appDocDir != null) ? join(appDocDir.path, authVoiceRecordName) : null;
    return (cacheFilePath != null) ? File(cacheFilePath) : null;
  }

  Future<Uint8List?> _loadAuthVoiceRecordFromCache() async {
    try {
      if ((_authVoiceRecordCacheFile != null) && await _authVoiceRecordCacheFile!.exists()) {
        String? base64 = Storage().decrypt(await _authVoiceRecordCacheFile!.readAsString());
        return (base64 != null) ? base64Decode(base64) : null;
      }
    }
    on Exception catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<void> _saveAuthVoiceRecordToCache(Uint8List? value) async {
    try {
      if (_authVoiceRecordCacheFile != null) {
        if (value != null) {
          await _authVoiceRecordCacheFile!.writeAsString(Storage().encrypt(base64Encode(value)) ?? '', flush: true);
        }
        else if (await _authVoiceRecordCacheFile!.exists()) {
          await _authVoiceRecordCacheFile!.delete();
        }
      }
    }
    on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<Uint8List?> _loadAuthVoiceRecordFromNet({String? accountId, Auth2Token? token}) async {
    Map<String, String>? authHeaders;
    String? accessToken = token?.accessToken;
    if (StringUtils.isNotEmpty(accountId) && StringUtils.isNotEmpty(accessToken)) {
      String? tokenType = token?.tokenType ?? 'Bearer';
      authHeaders = {HttpHeaders.authorizationHeader: "$tokenType $accessToken"};
    }
    AudioResult? voiceRecordResponse = await Content().retrieveVoiceRecord(authHeaders: authHeaders);
    return (voiceRecordResponse?.resultType == AudioResultType.succeeded ) ? voiceRecordResponse?.getDataAs<Uint8List>() : null;
  }

  Future<Uint8List?> _refreshAuthVoiceRecord() async {
    Uint8List? authVoiceRecord = await _loadAuthVoiceRecordFromNet();
    if (authVoiceRecord != _authVoiceRecord) {
      _authVoiceRecord = authVoiceRecord;
      await _saveAuthVoiceRecordToCache(authVoiceRecord);
      NotificationService().notify(notifyVoiceRecordChanged);
    }
    return authVoiceRecord;
  }

  // Admin

  Future<dynamic> filterAccountsBy({List<String>? netIds, List<String>? accountIds}) async {
    if (Config().coreUrl == null) {
      String msg = 'Failed to filter accounts - missing url.';
      print(msg);
      return msg;
    }
    Map<String, dynamic> filter = {};
    if (CollectionUtils.isNotEmpty(netIds)) {
      filter['external_ids.net_id'] = netIds;
    }
    if (CollectionUtils.isNotEmpty(accountIds)) {
      filter['id'] = accountIds;
    }
    String? postBody = filter.isNotEmpty ? JsonUtils.encode(filter) : null;
    Map<String, String> headers = {'Content-Type': 'application/json'};
    String url = "${Config().coreUrl}/admin/application/filter/accounts";
    Response? response = await Network().post(url, auth: Auth2(), headers: headers, body: postBody);
    String? responseBody = response?.body;
    int? responseCode = response?.statusCode;
    if (responseCode == 200) {
      List<dynamic>? responseJson = JsonUtils.decodeList(responseBody);
      return Auth2Account.listFromJson(responseJson);
    } else {
      String msg = 'Failed to filter accounts. Reason: $responseCode, $responseBody';
      print(msg);
      return msg;
    }
  }
}
