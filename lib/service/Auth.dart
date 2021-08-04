/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:io';
import 'dart:convert' as json;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as Http;
import 'package:http/http.dart';
import 'package:illinois/model/Auth.dart';
import 'package:illinois/model/UserData.dart';
import 'package:illinois/model/UserPiiData.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'package:illinois/service/User.dart';
import 'package:illinois/utils/Utils.dart';



class Auth with Service implements NotificationsListener {

  static const String REDIRECT_URI = 'edu.illinois.rokwire://rokwire.illinois.edu/shib-auth';

  static const String notifyStarted  = "edu.illinois.rokwire.auth.started";
  static const String notifyAuthTokenChanged  = "edu.illinois.rokwire.auth.authtoken.changed";
  static const String notifyLoggedOut  = "edu.illinois.rokwire.auth.logged_out";
  static const String notifyLoginSucceeded  = "edu.illinois.rokwire.auth.login_succeeded";
  static const String notifyLoginFailed  = "edu.illinois.rokwire.auth.login_failed";
  static const String notifyLoginChanged  = "edu.illinois.rokwire.auth.login_changed";
  static const String notifyInfoChanged  = "edu.illinois.rokwire.auth.info.changed";
  static const String notifyUserPiiDataChanged  = "edu.illinois.rokwire.auth.pii.changed";
  static const String notifyCardChanged  = "edu.illinois.rokwire.auth.card.changed";

  static const String _authCardName   = "idCard.json";
  static const String _userPiiFileName   = "piiData.json";

  static final Auth _auth = Auth._internal();

  final List<Completer<bool>> _loginCompleters = [];
  Timer _loginTimer;

  AuthToken _authToken;
  AuthToken get authToken{ return _authToken; }

  ShibbolethToken get shibbolethToken{ return _authToken is ShibbolethToken ? _authToken : null; }
  PhoneToken get phoneToken{ return _authToken is PhoneToken ? _authToken : null; }

  AuthInfo _authInfo;
  AuthInfo get authInfo{ return _authInfo; }

  UserPiiData _userPiiData;
  UserPiiData get userPiiData{ return _userPiiData; }
  File _userPiiCacheFile;

  AuthCard _authCard;
  AuthCard get authCard{ return _authCard; }
  File _authCardCacheFile;

  Future<Http.Response> _refreshTokenFuture;

  Future<Uint8List> get photoImageBytes async{
    Uint8List bytes;
    if(Auth().isShibbolethLoggedIn){
      bytes = await Auth().authCard.photoBytes;
    }
    else if(Auth().isPhoneLoggedIn){
      bytes = await Auth().userPiiData.photoBytes;
    }
    return bytes;
  }

  factory Auth() {
    return _auth;
  }

  Auth._internal();

  @override
  void createService() {
    NotificationService().subscribe(this, [
      DeepLink.notifyUri,
      AppLivecycle.notifyStateChanged,
      User.notifyPrivacyLevelChanged,
      User.notifyUserDeleted,
    ]);
  }

  @override
  Future<void> initService() async {
    _authToken = Storage().authToken;
    _authInfo = Storage().authInfo;

    _authCardCacheFile = await _getAuthCardCacheFile();
    _authCard = await _loadAuthCardFromCache();

    _userPiiCacheFile = await _getUserPiiCacheFile();
    _userPiiData = await _loadUserPiiDataFromCache();

    _syncProfilePiiDataIfNeed(); // No need for await
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage()]);
  }

  bool get isLoggedIn {
    return _authToken != null;
  }

  bool get isShibbolethLoggedIn {
    return shibbolethToken != null;
  }

  bool get isPhoneLoggedIn {
    return phoneToken != null;
  }

  bool get hasUIN {
    return (0 < (authInfo?.uin?.length ?? 0));
  }

  bool get isEventEditor {
    return authInfo?.userGroupMembership?.contains('urn:mace:uiuc.edu:urbana:authman:app-rokwire-service-policy-rokwire event approvers') ?? false;
  }

  bool get isStadiumPollManager {
    return authInfo?.userGroupMembership?.contains('urn:mace:uiuc.edu:urbana:authman:app-rokwire-service-policy-rokwire stadium poll manager') ?? false;
  }

  bool get isDebugManager {
    return authInfo?.userGroupMembership?.contains('urn:mace:uiuc.edu:urbana:authman:app-rokwire-service-policy-rokwire debug') ?? false;
  }

  bool get isGroupsAccess {
    return authInfo?.userGroupMembership?.contains('urn:mace:uiuc.edu:urbana:authman:app-rokwire-service-policy-rokwire groups access') ?? false;
  }

  bool isMemberOf(String groupName) {
    return authInfo?.userGroupMembership?.contains(groupName) ?? false;
  }

  void logout(){
    _clear(true);
  }

  void _clear([bool notify = false]){
    _authToken = null;
    _authInfo = null;
    _authCard = null;

    _applyUserPiiData(null, null);

    _saveAuthToken();
    _saveAuthInfo();
    _clearAuthCard();

    if(notify) {
      _notifyAuthInfoChanged();
      _notifyAuthCardChanged();
      _notifyAuthTokenChanged();
      _notifyAuthLoggedOut();
    }
  }

  ////////////////////////
  // Shibboleth Oauth

  Future<bool> authenticateWithShibboleth() async{

    if (_loginCompleters.isEmpty && (Config().shibbolethOauthHostUrl != null) && (Config().shibbolethOauthPathUrl != null) && (Config().shibbolethClientId != null)) {
      Uri uri = Uri.https(
        Config().shibbolethOauthHostUrl,
        Config().shibbolethOauthPathUrl,
        {
          'scope': "openid profile email offline_access",
          'response_type': 'code',
          'redirect_uri': REDIRECT_URI,
          'client_id': Config().shibbolethClientId,
          'claims': json.jsonEncode({
            'userinfo': {
              'uiucedu_uin': {'essential': true},
            },
          }),
        },
      );
      var uriStr = uri.toString();
      _launchUrl(uriStr);
    }

    return _createLoginCompleter();
  }

  Future<bool> _handleShibbolethAuthentication(code) async {

    _notifyAuthStarted();

    NativeCommunicator().dismissSafariVC();

    // 1. Request Tokens 
    AuthToken newAuthToken = await _loadShibbolethAuthTokenWithCode(code);
    if(newAuthToken == null){
      _notifyAuthLoginFailed(analyticsAction: Analytics.LogAuthLoginNetIdActionName);
      _completeLoginWithResult(false);
      return false;
    }

    // 2. Request AuthInfo
    AuthInfo newAuthInfo = await _loadAuthInfo(optAuthToken: newAuthToken);
    if(newAuthInfo == null){
      _notifyAuthLoginFailed(analyticsAction: Analytics.LogAuthLoginNetIdActionName);
      _completeLoginWithResult(false);
      return false;
    }

    // 3. Request User Pii Pid
    String newUserPiiPid = await _loadPidWithShibbolethAuth(email: newAuthInfo?.email, optAuthToken: newAuthToken);
    if(newUserPiiPid == null){
      _notifyAuthLoginFailed(analyticsAction: Analytics.LogAuthLoginNetIdActionName);
      _completeLoginWithResult(false);
      return false;
    }

    // 4. Request UserPiiData
    String newUserPiiDataString = await _loadUserPiiDataStringFromNet(pid: newUserPiiPid, optAuthToken: newAuthToken);
    UserPiiData newUserPiiData = _userPiiDataFromJsonString(newUserPiiDataString);
    if(newUserPiiData == null || AppCollection.isCollectionEmpty(newUserPiiData?.uuidList)){
      _notifyAuthLoginFailed(analyticsAction: Analytics.LogAuthLoginNetIdActionName);
      _completeLoginWithResult(false);
      return false;
    }

    // 5. Request UserData
    UserData newUserData;
    try {
      newUserData = await User().requestUser(newUserPiiData.uuidList.first);
    } on UserNotFoundException catch (_) {}
    if(newUserData == null){
      _notifyAuthLoginFailed(analyticsAction: Analytics.LogAuthLoginNetIdActionName);
      _completeLoginWithResult(false);
      return false;
    }
    
    // 6. Load Auth Card
    String jsonString = ((0 < (newAuthInfo?.uin?.length ?? 0))) ? await _loadAuthCardStringFromNet(optAuthToken: newAuthToken, optAuthInfo: newAuthInfo) : null;
    AuthCard authCard = _authCardFromJsonString(jsonString);

    // Everything is fine - cleanup and store new tokens and data
    // 7. Clear everything before proceed further. Notification is not required at this stage
    _clear(false);

    // 8. Store everythong and notify everyone
    // 8.1 AuthToken
    _authToken = newAuthToken;
    _saveAuthToken();
    _notifyAuthTokenChanged();

    // 8.2 AuthInfo
    _authInfo = newAuthInfo;
    _saveAuthInfo();
    _notifyAuthInfoChanged();

    // 8.3 UserPiiData
    _applyUserPiiData(newUserPiiData, newUserPiiDataString);

    // 8.4 UserData
    User().applyUserData(newUserData, applyCachedSettings: true);

    // 6.2 Update UserPiiData if need and then apply
    if(newUserPiiData.updateFromAuthInfo(newAuthInfo)){
      storeUserPiiData(newUserPiiData);
    }
    else {
      _applyUserPiiData(newUserPiiData, newUserPiiDataString);
    }

    // 8.5 AuthCard
    _applyAuthCard(authCard, jsonString);

    // Set last user login version
    Storage().userLoginVersion = Config().appVersion;

    _notifyAuthLoginSucceeded(analyticsAction: Analytics.LogAuthLoginNetIdActionName);

    _completeLoginWithResult(true);
    return true;
  }

  Future<void> _syncProfilePiiDataIfNeed() async {
    if (isShibbolethLoggedIn) {
      UserPiiData piiData = userPiiData;
      if ((piiData != null) && piiData.updateFromAuthInfo(authInfo)) {
        storeUserPiiData(piiData);
      }
    }
  }

  Future<AuthToken> _loadShibbolethAuthTokenWithCode(String code) async{
    String tokenUriStr = Config().shibbolethAuthTokenUrl
        .replaceAll("{shibboleth_client_id}", Config().shibbolethClientId)
        .replaceAll("{shibboleth_client_secret}", Config().shibbolethClientSecret);
    Map<String,dynamic> bodyData = {
      'code': code,
      'grant_type': 'authorization_code',
      'redirect_uri': REDIRECT_URI,
    };
    Http.Response response;
    try {
      response = await Network().post(tokenUriStr,body: bodyData);
      String responseBody = (response != null && response.statusCode == 200) ? response.body : null;
      Map<String,dynamic> jsonData = AppString.isStringNotEmpty(responseBody) ? AppJson.decode(responseBody) : null;
      if(jsonData != null){
        return ShibbolethToken.fromJson(jsonData);
      }
    }catch(e){}
    finally{
      Analytics().logHttpResponse(response, requestMethod: 'POST', requestUrl: tokenUriStr);
    }
    return null;
  }

  Future<AuthInfo> _loadAuthInfo({AuthToken optAuthToken}) async{
    optAuthToken = (optAuthToken != null) ? optAuthToken : _authToken;
    if (Config().userAuthUrl != null) {
      try {
        Http.Response userDataResp = await Network().get(Config().userAuthUrl, headers: {HttpHeaders.authorizationHeader : "${optAuthToken?.tokenType} ${optAuthToken?.accessToken}"});
        String responseBody = ((userDataResp != null) && (userDataResp.statusCode == 200)) ? userDataResp.body : null;
        if ((responseBody != null) && (userDataResp.statusCode == 200)) {
          var userDataMap = (responseBody != null) ? AppJson.decode(responseBody) : null;
          return (userDataMap != null) ? AuthInfo.fromJson(userDataMap) : null;
        }
      }
      catch(e) { print(e.toString()); }
    }
    return null;
  }

  void _launchUrl(urlStr) async {
    try {
      if (await url_launcher.canLaunch(urlStr)) {
        await url_launcher.launch(urlStr);
      }
    }
    catch(e) {
      print(e);
    }
  }

  //Phone verification

  ///Returns 'true' if code was send, otherwise - false
  Future<bool> initiatePhoneNumber(String phoneNumberCandidate, VerificationMethod verifyMethod) async {
    if (AppString.isStringEmpty(phoneNumberCandidate) || verifyMethod == null || AppString.isStringEmpty(Config().rokwireAuthUrl)) {
      return false;
    }
    String channel = (verifyMethod == VerificationMethod.call) ? 'call' : 'sms';
    String phoneInitiateBody = '{"phoneNumber":"$phoneNumberCandidate", "channel":"$channel"}';
    var headers = {
      "Content-Type": "application/json"
    };
    final response = await Network().post(
        '${Config().rokwireAuthUrl}/phone-initiate', body: phoneInitiateBody, headers: headers, auth: NetworkAuth.App);
    if (response != null) {
      return (response.statusCode >= 200 && response.statusCode <= 300);
    }
    else {
      return false;
    }
  }

  ///Returns 'true' if phone number was validate successfully, otherwise - false
  Future<bool> validatePhoneNumber(String code, String phoneNumber) async {

    _notifyAuthStarted();

    if (AppString.isStringEmpty(phoneNumber) || AppString.isStringEmpty(code) || AppString.isStringEmpty(Config().rokwireAuthUrl)) {
      _notifyAuthLoginFailed(analyticsAction: Analytics.LogAuthLoginPhoneActionName);
      return false;
    }

    // 1. Validate phone and code
    AuthToken newAuthToken = await _validatePhoneCode(phone: phoneNumber, code: code);
    if(newAuthToken == null) {
      _notifyAuthLoginFailed(analyticsAction: Analytics.LogAuthLoginPhoneActionName);
      return false;
    }

    // 2. Pii Pid
    String newUserPiiPid = await _loadPidWithPhoneAuth(phone: phoneNumber, optAuthToken: newAuthToken);
    if(newUserPiiPid == null) {
      _notifyAuthLoginFailed(analyticsAction: Analytics.LogAuthLoginPhoneActionName);
      return false;
    }

    // 3. UserPiiData
    String newUserPiiDataString = await _loadUserPiiDataStringFromNet(pid: newUserPiiPid, optAuthToken: newAuthToken);
    UserPiiData newUserPiiData = _userPiiDataFromJsonString(newUserPiiDataString);
    if(newUserPiiData == null || AppCollection.isCollectionEmpty(newUserPiiData?.uuidList)){
      _notifyAuthLoginFailed(analyticsAction: Analytics.LogAuthLoginPhoneActionName);
      return false;
    }

    // 4. UserData
    UserData newUserData;
    try {
      newUserData = await User().requestUser(newUserPiiData.uuidList.first);
    } on UserNotFoundException catch (_) {}
    if(newUserData == null){
      _notifyAuthLoginFailed(analyticsAction: Analytics.LogAuthLoginPhoneActionName);
      return false;
    }

    // Everything is fine - cleanup and store new tokens and data
    // 5. Clear everything before proceed further. Notification is not required at this stage
    _clear(false);

    // 6. Store everything and notify everyone
    // 6.1 AuthToken
    _authToken = newAuthToken;
    _saveAuthToken();
    _notifyAuthTokenChanged();

    // 6.2 UserPiiData
    _applyUserPiiData(newUserPiiData, newUserPiiDataString);

    // 6.3 apply UserData
    User().applyUserData(newUserData, applyCachedSettings: true);

    // 6.4 notifyLoggedIn event
    _notifyAuthLoginSucceeded(analyticsAction: Analytics.LogAuthLoginPhoneActionName);

    return true;
  }

  Future<AuthToken> _validatePhoneCode({String phone, String code}) async{
    String phoneVerifyBody = '{"phoneNumber":"$phone", "code":"$code"}';
    var headers = {
      "Content-Type": "application/json"
    };
    final response = await Network().post(
        '${Config().rokwireAuthUrl}/phone-verify', body: phoneVerifyBody, headers: headers, auth: NetworkAuth.App);
    if ((response != null) &&
        (response.statusCode >= 200 && response.statusCode <= 300)) {
      Map<String, dynamic> jsonData = AppJson.decode(response.body);
      if (jsonData != null) {
        bool succeeded = jsonData['success'];
        if (succeeded && jsonData.containsKey("id_token")) {
          return PhoneToken(phone: phone, idToken:jsonData["id_token"]);
        }
      }
    }
    return null;
  }

  /// UserPIIData

  Future<String> _loadPidWithPhoneAuth({String phone, AuthToken optAuthToken}) async {
    return await _loadPidWithData(
      data:{'uuid' : User().uuid, 'phone': phone},
      optAuthToken: optAuthToken
    );
  }

  Future<String> _loadPidWithShibbolethAuth({String email, AuthToken optAuthToken}) async {
    return await _loadPidWithData(
        data:{'uuid' : User().uuid, 'email': email,},
        optAuthToken: optAuthToken
    );
  }

  Future<String> _loadPidWithData({Map<String,String> data, AuthToken optAuthToken}) async {
    String url = (Config().userProfileUrl != null) ? '${Config().userProfileUrl}/pii' : null;
    optAuthToken = (optAuthToken != null) ? optAuthToken : authToken;

    final response = await Network().post(url,
        headers: {'Content-Type':'application/json', HttpHeaders.authorizationHeader: "${optAuthToken?.tokenType} ${optAuthToken?.idToken}"},
        body: json.jsonEncode(data),
    );
    String responseBody = ((response != null) && (response.statusCode == 200)) ? response.body : null;
    Map<String, dynamic> jsonData = (responseBody != null) ? AppJson.decode(responseBody) : null;
    String userPid = (jsonData != null) ? jsonData['pid'] : null;
    return userPid;
  }

  Future<UserPiiData> storeUserPiiData(UserPiiData piiData) async {
    if(piiData != null) {
      String url = (Config().userProfileUrl != null) ? '${Config().userProfileUrl}/pii/${piiData.pid}' : null;
      String body = json.jsonEncode(piiData.toJson());
      final response = await Network().put(url,
          headers: {'Content-Type':'application/json'},
          body: body,
          auth: NetworkAuth.User
      );

      String responseBody = ((response != null) && (response.statusCode == 200)) ? response.body : null;
      Map<String, dynamic> jsonData = (responseBody != null) ? AppJson.decode(responseBody) : null;
      UserPiiData userPiiData = (jsonData != null) ? UserPiiData.fromJson(jsonData) : null;
      if(userPiiData != null) {
        _applyUserPiiData(userPiiData, responseBody);
        return userPiiData;
      } else {
        // This is a kind of workaround if the backend fails - still to save the data locally
        _applyUserPiiData(piiData, json.jsonEncode(piiData.toJson()));
        return piiData;
      }

    }
    return null;
  }

  Future<bool> deleteUserPiiData() async {
    if (Config().userProfileUrl != null) {
      String url = '${Config().userProfileUrl}/pii/${Storage().userPid}';

      try {
        Response response = await Network().delete(url, headers: {'Content-Type': 'application/json'}, auth: NetworkAuth.User);
        if(response?.statusCode == 200) {
          _applyUserPiiData(null, null);
          return true;
        }
      } catch(error){
        Log.e(error);
      }
    }
    return false;
  }

  void _applyUserPiiData(UserPiiData userPiiData, String userPiiDataString, [bool notify = true]) {
    if (_userPiiData != userPiiData) {
      _userPiiData = userPiiData;
      Storage().userPid = userPiiData?.pid;
      _saveUserPiiDataStringToCache(userPiiDataString);
      if(notify) {
        _notifyAuthUserPiiDataChanged();
      }
    }
  }

  Future<File> _getUserPiiCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _userPiiFileName);
    return File(cacheFilePath);
  }

  Future<String> _loadUserPiiDataStringFromCache() async {
    try {
      return ((_userPiiCacheFile != null) && await _userPiiCacheFile.exists()) ? await _userPiiCacheFile.readAsString() : null;
    }
    on Exception catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<void> _saveUserPiiDataStringToCache(String value) async {
    try {
      if (_userPiiCacheFile != null) {
        if (value != null) {
          await _userPiiCacheFile.writeAsString(value, flush: true);
        }
        else if (await _userPiiCacheFile.exists()) {
          await _userPiiCacheFile.delete();
        }
      }
    }
    on Exception catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<UserPiiData> _loadUserPiiDataFromCache() async {
    return _userPiiDataFromJsonString(await _loadUserPiiDataStringFromCache());
  }

  Future<String> _loadUserPiiDataStringFromNet({String pid, AuthToken optAuthToken}) async {
    pid = (pid != null) ? pid : Storage().userPid;
    optAuthToken = (optAuthToken != null) ? optAuthToken : authToken;
    try {
      String url = (Config().userProfileUrl != null) ? '${Config().userProfileUrl}/pii/$pid' : null;
      final response = await Network().get(url, headers: {
        HttpHeaders.authorizationHeader: "${optAuthToken?.tokenType} ${optAuthToken?.idToken}"
      });
      return ((response != null) && (response.statusCode == 200)) ? response.body : null;
    }
    catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<void> _reloadUserPiiDataIfNeeded() async {
    if (this.isLoggedIn) {
      DateTime now = DateTime.now();
      int timeUpdate = Storage().userPiiDataTime;
      DateTime dateUpdate = (0 < timeUpdate) ? DateTime.fromMillisecondsSinceEpoch(timeUpdate) : null;
      if (!kReleaseMode || (dateUpdate == null) || (now.difference(dateUpdate).inSeconds < (3600 * 24))) {
        await reloadUserPiiData();
        Storage().userPiiDataTime = now.millisecondsSinceEpoch;
      }
    }
  }

  Future<UserPiiData> reloadUserPiiData({String pid, AuthToken optAuthToken}) async {
    String jsonString = await _loadUserPiiDataStringFromNet(pid: pid, optAuthToken: optAuthToken);
    UserPiiData userPiiData = _userPiiDataFromJsonString(jsonString);
    if(userPiiData != null && userPiiData != _userPiiData) { // Redo: Ensure the request is not failed - do not remove it!!!!
      _applyUserPiiData(userPiiData, jsonString);
    }
    return _userPiiData;
  }

  UserPiiData _userPiiDataFromJsonString(String jsonString) {
    try {
      Map<String, dynamic> jsonData = (jsonString != null) ? AppJson.decode(jsonString) : null;
      return (jsonData != null) ? UserPiiData.fromJson(jsonData) : null;
    } on Exception catch (e) {
      print(e.toString());
    }
    return null;
  }

  // Auth Card

  void _applyAuthCard(AuthCard authCard, String authCardJson) {
    _authCard = authCard;
    _saveAuthCardStringToCache(authCardJson);
    _notifyAuthCardChanged();
  }

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
    return null;
  }

  Future<AuthCard> _loadAuthCardFromCache() async {
    return _authCardFromJsonString(await _loadAuthCardStringFromCache());
  }

  Future<String> _loadAuthCardStringFromNet({AuthToken optAuthToken, AuthInfo optAuthInfo}) async {
    optAuthToken = (optAuthToken != null) ? optAuthToken : authToken;
    optAuthInfo = (optAuthInfo != null) ? optAuthInfo : authInfo;
    try {
      String url = Config().iCardUrl;
      Map<String, String> headers = {
        'UIN': optAuthInfo?.uin,
        'access_token': optAuthToken?.accessToken
      };
      Response response = (url != null) ? await Network().post(url, headers: headers) : null;
      return (response != null) && (response.statusCode == 200) ? response.body : null;
    }
    catch(e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> _reloadAuthCardIfNeeded() async {
    if (this.hasUIN) {
      DateTime now = DateTime.now();
      int timeUpdate = Storage().authCardTime;
      DateTime dateUpdate = (0 < timeUpdate) ? DateTime.fromMillisecondsSinceEpoch(timeUpdate) : null;
      if (!kReleaseMode || (dateUpdate == null) || (now.difference(dateUpdate).inSeconds > (3600 * 24))) {
        await _reloadAuthCard();
        Storage().authCardTime = now.millisecondsSinceEpoch;
      }
    }
  }

  Future<void> _reloadAuthCard() async {
    String jsonString = await _loadAuthCardStringFromNet();
    AuthCard authCard = _authCardFromJsonString(jsonString);
    if(authCard != null && _authCard != authCard) { // Redo: Ensure the request is not failed - do not remove it!!!!
      _applyAuthCard(authCard, jsonString);
    }
  }

  AuthCard _authCardFromJsonString(String jsonString) {
    try {
      Map<String, dynamic> jsonData = (jsonString != null) ? AppJson.decode(jsonString) : null;
      return (jsonData != null) ? AuthCard.fromJson(jsonData) : null;
    } on Exception catch (e) {
      print(e.toString());
    }
    return null;
  }

  // Refresh Token

  Future<void> doRefreshToken() async {

    if(!isShibbolethLoggedIn){
      return; // Execute only if the user is loggedin
    }

    if((Config().shibbolethAuthTokenUrl == null) || (Config().shibbolethClientId == null) || (Config().shibbolethClientSecret == null)) {
      return;
    }

    if(_refreshTokenFuture != null){
      await Future.wait([_refreshTokenFuture]);
      return;
    }

    Log.d("Auth: will refresh token");

    String tokenUriStr = Config().shibbolethAuthTokenUrl
        .replaceAll("{shibboleth_client_id}", Config().shibbolethClientId)
        .replaceAll("{shibboleth_client_secret}", Config().shibbolethClientSecret);
    Map<String, String> body = {
      "refresh_token": authToken?.refreshToken,
      "grant_type": "refresh_token",
    };
    _refreshTokenFuture = Network().post(
        tokenUriStr, body: body, refreshToken: false)
        .then((tokenResponse){
      _refreshTokenFuture = null;
      try {
        if((tokenResponse?.body != null) && (tokenResponse.statusCode == 200)){
          String tokenResponseBody =  tokenResponse.body;
          var bodyMap = (tokenResponseBody != null) ? AppJson.decode(tokenResponseBody) : null;
          _authToken = ShibbolethToken.fromJson(bodyMap);
          if(authToken?.idToken != null) {
            Log.d("Auth: did refresh token: ${authToken?.idToken}");
            _saveAuthToken();
            _notifyAuthTokenChanged();
          }
        }
        else if(tokenResponse.statusCode == 400 || tokenResponse.statusCode == 401 || tokenResponse.statusCode == 403){
          logout(); // Logout only on 400, 401 or 403. Do not do anything else for the rest of scenarios
        }
      }
      catch(e) {
        print(e.toString());
      }

      return;
    });
    return _refreshTokenFuture;
  }

  // Utils

  void _saveAuthToken() {
    Storage().authToken = authToken;
  }

  void _saveAuthInfo() {
    Storage().authInfo = authInfo;
  }

  void _clearAuthCard(){
    if (_authCard != null) {
      _authCard = null;
      _saveAuthCardStringToCache(null);
    }
  }

  ////////
  // AuthListeners

  void _notifyAuthStarted(){
    NotificationService().notify(notifyStarted, null);
  }

  void _notifyAuthTokenChanged(){
    NotificationService().notify(notifyAuthTokenChanged, null);
  }

  void _notifyAuthInfoChanged(){
    NotificationService().notify(notifyInfoChanged, null);
  }

  void _notifyAuthCardChanged(){
    NotificationService().notify(notifyCardChanged, null);
  }

  void _notifyAuthLoginSucceeded({String analyticsAction}){
    if (analyticsAction != null) {
      Analytics().logAuth(action: analyticsAction, result: true);
    }
    NotificationService().notify(notifyLoginSucceeded, null);
    _notifyAuthLoginChanged();
  }

  void _notifyAuthLoggedOut(){
    Analytics().logAuth(action: Analytics.LogAuthLogoutActionName);
    NotificationService().notify(notifyLoggedOut, null);
    _notifyAuthLoginChanged();
  }

  void _notifyAuthLoginFailed({String analyticsAction}){
    if (analyticsAction != null) {
      Analytics().logAuth(action: analyticsAction, result: false);
    }
    NotificationService().notify(notifyLoginFailed, null);
  }

  void _notifyAuthLoginChanged(){
    NotificationService().notify(notifyLoginChanged, null);
  }

  void _notifyAuthUserPiiDataChanged(){
    NotificationService().notify(notifyUserPiiDataChanged, null);
  }

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(param);
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        _reloadAuthCardIfNeeded();
        _reloadUserPiiDataIfNeeded();
      }
    }
    else if (name == User.notifyPrivacyLevelChanged) {
      _onPrivacyLevelChanged();
    }
    else if (name == User.notifyUserDeleted) {
      logout();
    }
  }

  void _onDeepLinkUri(Uri uri) {
    if (uri != null) {
      Uri shibbolethRedirectUri;
      try { shibbolethRedirectUri = Uri.parse(REDIRECT_URI); }
      catch(e) { print(e?.toString()); }

      var code = uri.queryParameters['code'];
      if ((shibbolethRedirectUri != null) &&
          (shibbolethRedirectUri.scheme == uri.scheme) &&
          (shibbolethRedirectUri.authority == uri.authority) &&
          (shibbolethRedirectUri.path == uri.path) &&
          ((code != null) && code.isNotEmpty))
      {
        _handleShibbolethAuthentication(code);
      }
    }
  }

  void _onPrivacyLevelChanged() {
    if (this.isLoggedIn && !User().privacyMatch(4)) {
      logout();
    }
  }

  void _createLoginTimer(){
    if(_loginTimer != null){
      _loginTimer.cancel();
    }
    _loginTimer = Timer(Duration(minutes: 10), (){
      _completeLoginWithResult(false);
      _loginTimer = null;
    });
  }

  void _cancelLoginTimer(){
    if(_loginTimer != null){
      _loginTimer.cancel();
    }
    _loginTimer = null;
  }

  Future<bool> _createLoginCompleter(){
    Completer<bool> completer = Completer<bool>();
    _loginCompleters.add(completer);
    _createLoginTimer();
    return completer.future;
  }

  void _completeLoginWithResult(bool success){
    for(Completer<void> completer in _loginCompleters){
      completer.complete(success);
    }
    _cancelLoginTimer();
    _loginCompleters.clear();
  }

}

enum VerificationMethod { call, sms }