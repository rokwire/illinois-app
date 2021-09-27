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

import 'dart:convert';
import 'package:illinois/model/Auth.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/illinicash/IlliniCashBallance.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/model/UserData.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Storage with Service {

  static const String notifySettingChanged  = "edu.illinois.rokwire.setting.changed";

  static final Storage _appStore = new Storage._internal();

  factory Storage() {
    return _appStore;
  }

  Storage._internal();

  SharedPreferences _sharedPreferences;

  @override
  Future<void> initService() async {
    Log.d("Init Storage");
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  void deleteEverything(){
    for(String key in _sharedPreferences.getKeys()){
      if(key != _configEnvKey){  // skip selected environment
        _sharedPreferences.remove(key);
      }
    }
  }

  String _getStringWithName(String name, {String defaultValue}) {
    return _sharedPreferences.getString(name) ?? defaultValue;
  }

  void _setStringWithName(String name, String value) {
    if(value != null) {
      _sharedPreferences.setString(name, value);
    } else {
      _sharedPreferences.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  List<String> _getStringListWithName(String name, {List<String> defaultValue}) {
    return _sharedPreferences.getStringList(name) ?? defaultValue;
  }

  void _setStringListWithName(String name, List<String> value) {
    if(value != null) {
      _sharedPreferences.setStringList(name, value);
    } else {
      _sharedPreferences.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  bool _getBoolWithName(String name, {bool defaultValue = false}) {
    return _sharedPreferences.getBool(name) ?? defaultValue;
  }

  void _setBoolWithName(String name, bool value) {
    if(value != null) {
      _sharedPreferences.setBool(name, value);
    } else {
      _sharedPreferences.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  int _getIntWithName(String name, {int defaultValue = 0}) {
    return _sharedPreferences.getInt(name) ?? defaultValue;
  }

  void _setIntWithName(String name, int value) {
    if(value != null) {
      _sharedPreferences.setInt(name, value);
    } else {
      _sharedPreferences.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  double _getDoubleWithName(String name, {double defaultValue = 0.0}) {
    return _sharedPreferences.getDouble(name) ?? defaultValue;
  }

  void _setDoubleWithName(String name, double value) {
    if(value != null) {
      _sharedPreferences.setDouble(name, value);
    } else {
      _sharedPreferences.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }


  dynamic operator [](String name) {
    return _sharedPreferences.get(name);
  }

  void operator []=(String key, dynamic value) {
    if (value is String) {
      _sharedPreferences.setString(key, value);
    }
    else if (value is int) {
      _sharedPreferences.setInt(key, value);
    }
    else if (value is double) {
      _sharedPreferences.setDouble(key, value);
    }
    else if (value is bool) {
      _sharedPreferences.setBool(key, value);
    }
    else if (value is List) {
      _sharedPreferences.setStringList(key, value.cast<String>());
    }
    else if (value == null) {
      _sharedPreferences.remove(key);
    }
  }

  // Dining

  static const String excludedFoodIngredientsPrefsKey  = 'excluded_food_ingredients_prefs';

  List<String> get excludedFoodIngredientsPrefs {
    return _getStringListWithName(excludedFoodIngredientsPrefsKey, defaultValue: []);
  }

  set excludedFoodIngredientsPrefs(List<String> value) {
    _setStringListWithName(excludedFoodIngredientsPrefsKey, value);
  }

  static const String includedFoodTypesPrefsKey  = 'included_food_types_prefs';

  List<String> get includedFoodTypesPrefs {
    return _getStringListWithName(includedFoodTypesPrefsKey, defaultValue: []);
  }

  set includedFoodTypesPrefs(List<String> value) {
    _setStringListWithName(includedFoodTypesPrefsKey, value);
  }

  // Notifications

  bool getNotifySetting(String name) {
    return _getBoolWithName(name, defaultValue: null);
  }

  void setNotifySetting(String name, bool value) {
    return _setBoolWithName(name, value);
  }

  /////////////
  // User

  static const String userKey  = 'user';

  UserData get userData {
    final String userToString = _getStringWithName(userKey);
    final Map<String, dynamic> userToJson = AppJson.decode(userToString);
    return (userToJson != null) ? UserData.fromJson(userToJson) : null;
  }

  set userData(UserData user) {
    String userToString = (user != null) ? json.encode(user) : null;
    _setStringWithName(userKey, userToString);
  }

  /////////////
  // UserRoles

  static const String userRolesKey  = 'user_roles';

  List<dynamic> get userRolesJson {
    final String userRolesToString = _getStringWithName("user_roles");
    return AppJson.decode(userRolesToString);
  }

  Set<UserRole> get userRoles {
    final List<dynamic> userRolesToJson = userRolesJson;
    return (userRolesToJson != null) ? Set.from(userRolesToJson.map((value)=>UserRole.fromString(value))) : null;
  }

  set userRoles(Set<UserRole> userRoles) {
    String userRolesToString = (userRoles != null) ? json.encode(userRoles.toList()) : null;
    _setStringWithName(userRolesKey, userRolesToString);
  }

  static const String phoneNumberKey  = 'user_phone_number';

  String get phoneNumber {
    return _getStringWithName(phoneNumberKey);
  }

  set phoneNumber(String phoneNumber) {
    _setStringWithName(phoneNumberKey, phoneNumber);
  }

  /////////////
  // UserPII

  static const String userPidKey  = 'user_pid';

  String get userPid {
    return _getStringWithName(userPidKey);
  }

  set userPid(String userPid) {
    _setStringWithName(userPidKey, userPid);
  }

  static const String userPiiDataTimeKey  = '_user_pii_data_time';

  int get userPiiDataTime {
    return _getIntWithName(userPiiDataTimeKey);
  }

  set userPiiDataTime(int value) {
    _setIntWithName(userPiiDataTimeKey, value);
  }

  /////////////
  // Polls

  static const String selectedPollTypeKey  = 'selected_poll_type';

  int get selectedPollType {
    return _getIntWithName(selectedPollTypeKey);
  }

  set selectedPollType(int value) {
    _setIntWithName(selectedPollTypeKey, value);
  }

  ///////////////
  // On Boarding

  static const String onBoardingPassedKey  = 'on_boarding_passed';
  static const String onBoardingExploreChoiceKey  = 'on_boarding_explore_campus';
  static const String onBoardingPersonalizeChoiceKey  = 'on_boarding_personalize';
  static const String onBoardingImproveChoiceKey  = 'on_boarding_improve';

  bool get onBoardingPassed {
    return _getBoolWithName(onBoardingPassedKey, defaultValue: false);
  }

  set onBoardingPassed(bool showOnBoarding) {
    _setBoolWithName(onBoardingPassedKey, showOnBoarding);
  }

  set onBoardingExploreCampus(bool exploreCampus) {
    _setBoolWithName(onBoardingExploreChoiceKey, exploreCampus);
  }

  bool get onBoardingExploreCampus {
    return _getBoolWithName(onBoardingExploreChoiceKey, defaultValue: true);
  }

  set onBoardingPersonalizeChoice(bool personalize) {
    _setBoolWithName(onBoardingPersonalizeChoiceKey, personalize);
  }

  bool get onBoardingPersonalizeChoice {
    return _getBoolWithName(onBoardingPersonalizeChoiceKey, defaultValue: true);
  }

  set onBoardingImproveChoice(bool personalize) {
    _setBoolWithName(onBoardingImproveChoiceKey, personalize);
  }

  bool get onBoardingImproveChoice {
    return _getBoolWithName(onBoardingImproveChoiceKey, defaultValue: true);
  }

  ////////////////
  // Upgrade

  static const String reportedUpgradeVersionsKey  = 'reported_upgrade_versions';

  Set<String> get reportedUpgradeVersions {
    List<String> list = _getStringListWithName(reportedUpgradeVersionsKey);
    return (list != null) ? Set.from(list) : Set<String>();
  }

  set reportedUpgradeVersion(String version) {
    if (version != null) {
      Set<String> versions = reportedUpgradeVersions;
      versions.add(version);
      _setStringListWithName(reportedUpgradeVersionsKey, versions.toList());
    }
  }

  ////////////////////////////
  // Privacy Update Version

  static const String privacyUpdateVersionKey  = 'privacy_update_version';

  String get privacyUpdateVersion {
    return _getStringWithName(privacyUpdateVersionKey);
  }

  set privacyUpdateVersion(String value) {
    _setStringWithName(privacyUpdateVersionKey, value);
  }

  ////////////////////////////
  // User Relogin Version

  static const String userRefreshPiiVersionKey  = 'user_refresh_pii_version';

  String get userRefreshPiiVersion {
    return _getStringWithName(userRefreshPiiVersionKey);
  }

  set userRefreshPiiVersion(String value) {
    _setStringWithName(userRefreshPiiVersionKey, value);

  }

  ////////////////////////////
  // Upgrade Message Version

  static const String _userLoginVersionKey = 'user_login_version';

  String get userLoginVersion {
    return _getStringWithName(_userLoginVersionKey);
  }

  set userLoginVersion(String value) {
    _setStringWithName(_userLoginVersionKey, value);
  }

  ////////////////////////////
  // Last Run Version

  static const String lastRunVersionKey  = 'last_run_version';

  String get lastRunVersion {
    return _getStringWithName(lastRunVersionKey);
  }

  set lastRunVersion(String value) {
    _setStringWithName(lastRunVersionKey, value);
  }

  ////////////////
  // Auth

  static const String authTokenKey  = '_auth_token';

  AuthToken get authToken {
    try {
      String jsonString = _getStringWithName(authTokenKey);
      dynamic jsonData = AppJson.decode(jsonString);
      return (jsonData != null) ? AuthToken.fromJson(jsonData) : null;
    } on Exception catch (e) { print(e.toString()); }
    return null;
  }

  set authToken(AuthToken value) {
    _setStringWithName(authTokenKey, value != null ? json.encode(value.toJson()) : null);
  }

  static const String authInfoKey  = '_auth_info';

  AuthInfo get authInfo {
    final String authInfoToString = _getStringWithName(authInfoKey);
    AuthInfo authInfo = AuthInfo.fromJson(AppJson.decode(authInfoToString));
    return authInfo;
  }

  set authInfo(AuthInfo value) {
    _setStringWithName(authInfoKey, value != null ? json.encode(value.toJson()) : null);
  }

  static const String authCardTimeKey  = '_auth_card_time';

  int get authCardTime {
    return _getIntWithName(authCardTimeKey);
  }

  set authCardTime(int value) {
    _setIntWithName(authCardTimeKey, value);
  }

  ////////////////
  // IlliniCash

  static const String illiniCashBallanceKey  = '_illinicash_ballance';

  IlliniCashBallance get illiniCashBallance {
    try {
      String jsonString = _getStringWithName(illiniCashBallanceKey);
      dynamic jsonData = AppJson.decode(jsonString);
      return (jsonData != null) ? IlliniCashBallance.fromJson(jsonData) : null;
    } on Exception catch (e) { print(e.toString()); }
    return null;
  }

  set illiniCashBallance(IlliniCashBallance value) {
    _setStringWithName(illiniCashBallanceKey, value != null ? json.encode(value.toJson()) : null);
  }

  /////////////////////
  // Date offset

  static const String offsetDateKey  = 'settings_offset_date';

  set offsetDate(DateTime value) {
    _setStringWithName(offsetDateKey, AppDateTime().formatDateTime(value, ignoreTimeZone: true));
  }

  DateTime get offsetDate {
    String dateString = _getStringWithName(offsetDateKey);
    return AppString.isStringNotEmpty(dateString) ? AppDateTime()
        .dateTimeFromString(dateString) : null;
  }

  ////////////////
  // Privacy level

  static const String privacyLevelKey  = 'illinois_privacy_level';

  set privacyLevel(int value) {
     _setDoubleWithName(privacyLevelKey, value?.toDouble());
  }

  int get privacyLevel {
    return _getDoubleWithName(privacyLevelKey, defaultValue: 5)?.toInt();
  }
  

  /////////////////
  // Face id

  static const String toggleFaceIdKey  = 'toggle_faceid';

  bool get toggleFaceId {
    return _getBoolWithName(toggleFaceIdKey);
  }

  set toggleFaceId(bool value) {
    _setBoolWithName(toggleFaceIdKey, value);
  }

  /////////////////
  // Language

  static const String currentLanguageKey  = 'current_language';

  String get currentLanguage {
    return _getStringWithName(currentLanguageKey);
  }

  set currentLanguage(String value) {
    _setStringWithName(currentLanguageKey, value);
  }

  //////////////////
  // Favorites

  static const String favoritesKey  = 'user_favorites_list';

  List<Object> get favorites{
    List<String> storedValue = _sharedPreferences.getStringList(favoritesKey);
    return storedValue?? [];
  }

  set favorites(List<Object> favorites){
    List<String> storeValue = favorites.map((Object e){return e.toString();}).toList();
    _sharedPreferences.setStringList(favoritesKey, storeValue);
  }

  static const String favoritesDialogWasVisibleKey  = 'favorites_dialog_was_visible';

  bool get favoritesDialogWasVisible {
    return _getBoolWithName(favoritesDialogWasVisibleKey);
  }

  set favoritesDialogWasVisible(bool value) {
    _setBoolWithName(favoritesDialogWasVisibleKey, value);
  }

  //////////////
  // Sport Social Media

  static const String sportSocialMediaListKey  = 'sport_social_media';
  
  List<dynamic> get sportSocialMediaList {
    final String jsonString = _getStringWithName(sportSocialMediaListKey);
    return AppJson.decode(jsonString);
  }

  set sportSocialMediaList(List<dynamic> sportSocialMedia) {
    _setStringWithName(sportSocialMediaListKey, sportSocialMedia != null ? json.encode(sportSocialMedia) : null);
  }

  //////////////
  // Recent Items

  static const String recentItemsKey  = '_recent_items_json_string';
  
  List<dynamic> get recentItems {
    final String jsonString = _getStringWithName(recentItemsKey);
    return AppJson.decode(jsonString);
  }

  set recentItems(List<dynamic> recentItems) {
    _setStringWithName(recentItemsKey, recentItems != null ? json.encode(recentItems) : null);
  }

  //////////////
  // Local Date/Time

  static const String useDeviceLocalTimeZoneKey  = 'use_device_local_time_zone';

  bool get useDeviceLocalTimeZone {
    return _getBoolWithName(useDeviceLocalTimeZoneKey, defaultValue: true);
  }

  set useDeviceLocalTimeZone(bool value) {
    _setBoolWithName(useDeviceLocalTimeZoneKey, value);
  }


  //////////////
  // Debug

  static const String debugMapThresholdDistanceKey  = 'debug_map_threshold_distance';

  int get debugMapThresholdDistance {
    return _getIntWithName(debugMapThresholdDistanceKey, defaultValue: 200);
  }

  set debugMapThresholdDistance(int value) {
    _setIntWithName(debugMapThresholdDistanceKey, value);
  }

  static const String debugGeoFenceRegionRadiusKey  = 'debug_geo_fence_region_radius';

  int get debugGeoFenceRegionRadius {
    return _getIntWithName(debugGeoFenceRegionRadiusKey, defaultValue: null);
  }

  set debugGeoFenceRegionRadius(int value) {
    _setIntWithName(debugGeoFenceRegionRadiusKey, value);
  }

  static const String debugDisableLiveGameCheckKey  = 'debug_disable_live_game_check';

  bool get debugDisableLiveGameCheck {
    return _getBoolWithName(debugDisableLiveGameCheckKey);
  }

  set debugDisableLiveGameCheck(bool value) {
    _setBoolWithName(debugDisableLiveGameCheckKey, value);
  }

  static const String debugMapLocationProviderKey  = 'debug_map_location_provider';

  bool get debugMapLocationProvider {
    return _getBoolWithName(debugMapLocationProviderKey, defaultValue: false);
  }

  set debugMapLocationProvider(bool value) {
    _setBoolWithName(debugMapLocationProviderKey, value);
  }

  static const String debugMapHideLevelsKey  = 'debug_map_hide_levels';

  bool get debugMapHideLevels {
    return _getBoolWithName(debugMapHideLevelsKey, defaultValue: false);
  }

  set debugMapHideLevels(bool value) {
    _setBoolWithName(debugMapHideLevelsKey, value);
  }

  static const String debugLastInboxMessageKey  = 'debug_last_inbox_message';

  String get debugLastInboxMessage {
    return _getStringWithName(debugLastInboxMessageKey);
  }

  set debugLastInboxMessage(String value) {
    _setStringWithName(debugLastInboxMessageKey, value);
  }

  //////////////
  // Firebase

// static const String firebaseMessagingSubscriptionTopisKey  = 'firebase_subscription_topis';
// Replacing "firebase_subscription_topis" with "firebase_messaging_subscription_topis" key ensures that
// all subsciptions will be applied again through Notifications BB APIs
  static const String firebaseMessagingSubscriptionTopisKey  = 'firebase_messaging_subscription_topis';
  
  Set<String> get firebaseMessagingSubscriptionTopis {
    List<String> topicsList = _getStringListWithName(firebaseMessagingSubscriptionTopisKey);
    return (topicsList != null) ? Set.from(topicsList) : null;
  }

  set firebaseMessagingSubscriptionTopis(Set<String> value) {
    List<String> topicsList = (value != null) ? List.from(value) : null;
    _setStringListWithName(firebaseMessagingSubscriptionTopisKey, topicsList);
  }

  void addFirebaseMessagingSubscriptionTopic(String value) {
    Set<String> topis = firebaseMessagingSubscriptionTopis ?? Set();
    topis.add(value);
    firebaseMessagingSubscriptionTopis = topis;
  }

  void removeFirebaseMessagingSubscriptionTopic(String value) {
    Set<String> topis = firebaseMessagingSubscriptionTopis;
    if (topis != null) {
      topis.remove(value);
      firebaseMessagingSubscriptionTopis = topis;
    }
  }

  static const String inboxFirebaseMessagingTokenKey  = 'inbox_firebase_messaging_token';

  String get inboxFirebaseMessagingToken {
    return _getStringWithName(inboxFirebaseMessagingTokenKey);
  }

  set inboxFirebaseMessagingToken(String value) {
    _setStringWithName(inboxFirebaseMessagingTokenKey, value);
  }

  //////////////
  // Polls

  static const String activePollsKey  = 'active_polls';

  String get activePolls {
    return _getStringWithName(activePollsKey);
  }

  set activePolls(String value) {
    _setStringWithName(activePollsKey, value);
  }

  /////////////
  // Config

  static const String _configEnvKey = 'config_environment';

  String get configEnvironment {
    return _getStringWithName(_configEnvKey);
  }

  set configEnvironment(String value) {
    _setStringWithName(_configEnvKey, value);
  }

  /////////////
  // Styles

  static const String _stylesContentModeKey = 'styles_content_mode';

  String get stylesContentMode {
    return _getStringWithName(_stylesContentModeKey);
  }

  set stylesContentMode(String value) {
    _setStringWithName(_stylesContentModeKey, value);
  }

  /////////////
  // Voter

  static const String _voterHiddenForPeriodKey = 'voter_hidden_for_period';

  bool get voterHiddenForPeriod {
    return _getBoolWithName(_voterHiddenForPeriodKey);
  }

  set voterHiddenForPeriod(bool value) {
    _setBoolWithName(_voterHiddenForPeriodKey, value);
  }

  /////////////
  // Http Proxy

  static const String _httpProxyEnabledKey = 'http_proxy_enabled';

  bool get httpProxyEnabled {
    return _getBoolWithName(_httpProxyEnabledKey, defaultValue: false);
  }

  set httpProxyEnabled(bool value) {
    _setBoolWithName(_httpProxyEnabledKey, value);
  }

  static const String _httpProxyHostKey = 'http_proxy_host';

  String get httpProxyHost {
    return _getStringWithName(_httpProxyHostKey);
  }

  set httpProxyHost(String value) {
    _setStringWithName(_httpProxyHostKey, value);
  }

  static const String _httpProxyPortKey = 'http_proxy_port';

  String get httpProxyPort {
    return _getStringWithName(_httpProxyPortKey);
  }

  set httpProxyPort(String value) {
    _setStringWithName(_httpProxyPortKey, value);
  }

  //////////////////
  // Student Guide

  static const String _studentGuideContentSourceKey = 'student_guide_content_source';

  String get studentGuideContentSource {
    return _getStringWithName(_studentGuideContentSourceKey);
  }

  set studentGuideContentSource(String value) {
    _setStringWithName(_studentGuideContentSourceKey, value);
  }

  //////////////////
  // Auth2

  static const String _auth2TokenKey = 'auth2Token';

  Auth2Token get auth2Token {
    return Auth2Token.fromJson(AppJson.decodeMap(_getStringWithName(_auth2TokenKey)));
  }

  set auth2Token(Auth2Token value) {
    _setStringWithName(_auth2TokenKey, AppJson.encode(value?.toJson()));
  }

  static const String _auth2UiucTokenKey = 'auth2UiucToken';

  Auth2Token get auth2UiucToken {
    return Auth2Token.fromJson(AppJson.decodeMap(_getStringWithName(_auth2UiucTokenKey)));
  }

  set auth2UiucToken(Auth2Token value) {
    _setStringWithName(_auth2UiucTokenKey, AppJson.encode(value?.toJson()));
  }

  static const String _auth2AccountKey = 'auth2Account';

  Auth2Account get auth2Account {
    return Auth2Account.fromJson(AppJson.decodeMap(_getStringWithName(_auth2AccountKey)));
  }

  set auth2Account(Auth2Account value) {
    _setStringWithName(_auth2AccountKey, AppJson.encode(value?.toJson()));
  }

  static const String _auth2UserPrefsKey = 'auth2UserPrefs';

  Auth2UserPrefs get auth2UserPrefs {
    return Auth2UserPrefs.fromJson(AppJson.decodeMap(_getStringWithName(_auth2UserPrefsKey)));
  }

  set auth2UserPrefs(Auth2UserPrefs value) {
    _setStringWithName(_auth2UserPrefsKey, AppJson.encode(value?.toJson()));
  }

  /////////////

  static const String _calendarEventsTableKey = 'calendar_events_table';
  static const String _calendarEnableSaveKey = 'calendar_enabled_to_save';
  static const String _calendarEnablePromptKey = 'calendar_enabled_to_prompt';

  dynamic get calendarEventsTable {
    String jsonString = _getStringWithName(_calendarEventsTableKey);
    dynamic jsonData = AppJson.decode(jsonString);
    return jsonData;
  }

  set calendarEventsTable(dynamic table) {
    String tableToString = (table != null) ? json.encode(table) : null;
    _setStringWithName(_calendarEventsTableKey, tableToString);
  }

  bool get calendarEnabledToSave{
    return _getBoolWithName(_calendarEnableSaveKey, defaultValue: true);
  }

  set calendarEnabledToSave(bool value){
    _setBoolWithName(_calendarEnableSaveKey, value);
  }

  bool get calendarCanPrompt{
    return _getBoolWithName(_calendarEnablePromptKey);
  }

  set calendarCanPrompt(bool value){
    _setBoolWithName(_calendarEnablePromptKey, value);
  }

}
