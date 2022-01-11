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
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/Inbox.dart';
import 'package:illinois/model/illinicash/IlliniCashBallance.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/utils/Crypt.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Storage with Service {

  static const String notifySettingChanged  = "edu.illinois.rokwire.setting.changed";

  static final Storage _appStore = new Storage._internal();

  factory Storage() {
    return _appStore;
  }

  Storage._internal();

  SharedPreferences? _sharedPreferences;
  String? _encryptionKey;
  String? _encryptionIV;

  @override
  Future<void> initService() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    _encryptionKey = await NativeCommunicator().encryptionKey(identifier: 'edu.illinois.rokwire.encryption.storage.key', size: AESCrypt.kCCBlockSizeAES128);
    _encryptionIV = await NativeCommunicator().encryptionKey(identifier: 'edu.illinois.rokwire.encryption.storage.iv', size: AESCrypt.kCCBlockSizeAES128);
    
    if (_sharedPreferences == null) {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.fatal,
        title: 'Storage Initialization Failed',
        description: 'Failed to initialize application preferences storage.',
      );
    }
    else if ((_encryptionKey == null) || (_encryptionIV == null)) {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.fatal,
        title: 'Storage Initialization Failed',
        description: 'Failed to initialize encryption keys.',
      );
    }
    else {
      await super.initService();
    }
  }

  String? get encryptionKey => _encryptionKey;
  String? get encryptionIV => _encryptionIV;

  String? encrypt(String? value) {
    return ((value != null) && (_encryptionKey != null) && (_encryptionIV != null)) ?
      AESCrypt.encrypt(value, key: _encryptionKey, iv: _encryptionIV) : null;
  }

  String? decrypt(String? value) {
    return ((value != null) && (_encryptionKey != null) && (_encryptionIV != null)) ?
      AESCrypt.decrypt(value, key: _encryptionKey, iv: _encryptionIV) : null;
  }

  void deleteEverything(){
    if (_sharedPreferences != null) {
      for(String key in _sharedPreferences!.getKeys()){
        if(key != _configEnvKey){  // skip selected environment
          _sharedPreferences!.remove(key);
        }
      }
    }
  }

  String? _getStringWithName(String name, {String? defaultValue}) {
    return _sharedPreferences?.getString(name) ?? defaultValue;
  }

  void _setStringWithName(String name, String? value) {
    if (value != null) {
      _sharedPreferences?.setString(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  String? _getEncryptedStringWithName(String name, {String? defaultValue}) {
    String? value = _sharedPreferences?.getString(name);
    if (value != null) {
      if ((_encryptionKey != null) && (_encryptionIV != null)) {
        value = decrypt(value);
      }
      else {
        value = null;
      }
    }
    return value ?? defaultValue;
  }

  void _setEncryptedStringWithName(String name, String? value) {
    if (value != null) {
      if ((_encryptionKey != null) && (_encryptionIV != null)) {
        value = encrypt(value);
        _sharedPreferences?.setString(name, value!);
      }
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  List<String>? _getStringListWithName(String name, {List<String>? defaultValue}) {
    return _sharedPreferences?.getStringList(name) ?? defaultValue;
  }

  void _setStringListWithName(String name, List<String>? value) {
    if (value != null) {
      _sharedPreferences?.setStringList(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  bool? _getBoolWithName(String name, {bool? defaultValue = false}) {
    return _sharedPreferences?.getBool(name) ?? defaultValue;
  }

  void _setBoolWithName(String name, bool? value) {
    if(value != null) {
      _sharedPreferences?.setBool(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  int? _getIntWithName(String name, {int? defaultValue = 0}) {
    return _sharedPreferences?.getInt(name) ?? defaultValue;
  }

  void _setIntWithName(String name, int? value) {
    if (value != null) {
      _sharedPreferences?.setInt(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  /*double _getDoubleWithName(String name, {double defaultValue = 0.0}) {
    return _sharedPreferences?.getDouble(name) ?? defaultValue;
  }

  void _setDoubleWithName(String name, double value) {
    if (value != null) {
      _sharedPreferences?.setDouble(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }*/


  dynamic operator [](String name) {
    return _sharedPreferences?.get(name);
  }

  void operator []=(String key, dynamic value) {
    if (value is String) {
      _sharedPreferences?.setString(key, value);
    }
    else if (value is int) {
      _sharedPreferences?.setInt(key, value);
    }
    else if (value is double) {
      _sharedPreferences?.setDouble(key, value);
    }
    else if (value is bool) {
      _sharedPreferences?.setBool(key, value);
    }
    else if (value is List) {
      _sharedPreferences?.setStringList(key, value.cast<String>());
    }
    else if (value == null) {
      _sharedPreferences?.remove(key);
    }
  }

  // User: readonly, backward compatability only.

  static const String _userKey  = 'user';

  Map<String, dynamic>? get userProfile {
    return AppJson.decodeMap(_getStringWithName(_userKey));
  }

  // Dining: readonly, backward compatability only.

  static const String excludedFoodIngredientsPrefsKey  = 'excluded_food_ingredients_prefs';

  Set<String>? get excludedFoodIngredientsPrefs {
    List<String>? list = _getStringListWithName(excludedFoodIngredientsPrefsKey);
    return (list != null) ? Set.from(list) : null;
  }

  static const String includedFoodTypesPrefsKey  = 'included_food_types_prefs';

  Set<String>? get includedFoodTypesPrefs {
    List<String>? list = _getStringListWithName(includedFoodTypesPrefsKey);
    return (list != null) ? Set.from(list) : null;
  }

  // Notifications

  bool? getNotifySetting(String name) {
    return _getBoolWithName(name, defaultValue: null);
  }

  void setNotifySetting(String name, bool? value) {
    return _setBoolWithName(name, value);
  }

  /////////////
  // Polls

  static const String selectedPollTypeKey  = 'selected_poll_type';

  int? get selectedPollType {
    return _getIntWithName(selectedPollTypeKey);
  }

  set selectedPollType(int? value) {
    _setIntWithName(selectedPollTypeKey, value);
  }

  ///////////////
  // On Boarding

  static const String onBoardingPassedKey  = 'on_boarding_passed';
  static const String onBoardingExploreChoiceKey  = 'on_boarding_explore_campus';
  static const String onBoardingPersonalizeChoiceKey  = 'on_boarding_personalize';
  static const String onBoardingImproveChoiceKey  = 'on_boarding_improve';

  bool? get onBoardingPassed {
    return _getBoolWithName(onBoardingPassedKey, defaultValue: false);
  }

  set onBoardingPassed(bool? showOnBoarding) {
    _setBoolWithName(onBoardingPassedKey, showOnBoarding);
  }

  set onBoardingExploreCampus(bool? exploreCampus) {
    _setBoolWithName(onBoardingExploreChoiceKey, exploreCampus);
  }

  bool? get onBoardingExploreCampus {
    return _getBoolWithName(onBoardingExploreChoiceKey, defaultValue: true);
  }

  set onBoardingPersonalizeChoice(bool? personalize) {
    _setBoolWithName(onBoardingPersonalizeChoiceKey, personalize);
  }

  bool? get onBoardingPersonalizeChoice {
    return _getBoolWithName(onBoardingPersonalizeChoiceKey, defaultValue: true);
  }

  set onBoardingImproveChoice(bool? personalize) {
    _setBoolWithName(onBoardingImproveChoiceKey, personalize);
  }

  bool? get onBoardingImproveChoice {
    return _getBoolWithName(onBoardingImproveChoiceKey, defaultValue: true);
  }

  ////////////////
  // Upgrade

  static const String reportedUpgradeVersionsKey  = 'reported_upgrade_versions';

  Set<String> get reportedUpgradeVersions {
    List<String>? list = _getStringListWithName(reportedUpgradeVersionsKey);
    return (list != null) ? Set.from(list) : Set<String>();
  }

  set reportedUpgradeVersion(String? version) {
    if (version != null) {
      Set<String> versions = reportedUpgradeVersions;
      versions.add(version);
      _setStringListWithName(reportedUpgradeVersionsKey, versions.toList());
    }
  }

  ////////////////////////////
  // Privacy Update Version

  static const String privacyUpdateVersionKey  = 'privacy_update_version';

  String? get privacyUpdateVersion {
    return _getStringWithName(privacyUpdateVersionKey);
  }

  set privacyUpdateVersion(String? value) {
    _setStringWithName(privacyUpdateVersionKey, value);
  }

  ////////////////////////////
  // Upgrade Message Version

  static const String _userLoginVersionKey = 'user_login_version';

  String? get userLoginVersion {
    return _getStringWithName(_userLoginVersionKey);
  }

  set userLoginVersion(String? value) {
    _setStringWithName(_userLoginVersionKey, value);
  }

  ////////////////////////////
  // Last Run Version

  static const String lastRunVersionKey  = 'last_run_version';

  String? get lastRunVersion {
    return _getStringWithName(lastRunVersionKey);
  }

  set lastRunVersion(String? value) {
    _setStringWithName(lastRunVersionKey, value);
  }

  ////////////////
  // IlliniCash

  static const String illiniCashBallanceKey  = '_illinicash_ballance';

  IlliniCashBallance? get illiniCashBallance {
    return IlliniCashBallance.fromJson(AppJson.decodeMap(_getEncryptedStringWithName(illiniCashBallanceKey)));
  }

  set illiniCashBallance(IlliniCashBallance? value) {
    _setEncryptedStringWithName(illiniCashBallanceKey, value != null ? json.encode(value.toJson()) : null);
  }

  /////////////////////
  // Date offset

  static const String offsetDateKey  = 'settings_offset_date';

  set offsetDate(DateTime? value) {
    _setStringWithName(offsetDateKey, AppDateTime().formatDateTime(value, ignoreTimeZone: true));
  }

  DateTime? get offsetDate {
    String? dateString = _getStringWithName(offsetDateKey);
    return AppString.isStringNotEmpty(dateString) ? AppDateTime()
        .dateTimeFromString(dateString) : null;
  }

  /////////////////
  // Language

  static const String currentLanguageKey  = 'current_language';

  String? get currentLanguage {
    return _getStringWithName(currentLanguageKey);
  }

  set currentLanguage(String? value) {
    _setStringWithName(currentLanguageKey, value);
  }

  //////////////////
  // Favorites

  static const String favoritesDialogWasVisibleKey  = 'favorites_dialog_was_visible';

  bool? get favoritesDialogWasVisible {
    return _getBoolWithName(favoritesDialogWasVisibleKey);
  }

  set favoritesDialogWasVisible(bool? value) {
    _setBoolWithName(favoritesDialogWasVisibleKey, value);
  }

  //////////////
  // Recent Items

  static const String recentItemsKey  = '_recent_items_json_string';
  
  List<dynamic>? get recentItems {
    final String? jsonString = _getStringWithName(recentItemsKey);
    return AppJson.decode(jsonString);
  }

  set recentItems(List<dynamic>? recentItems) {
    _setStringWithName(recentItemsKey, recentItems != null ? json.encode(recentItems) : null);
  }

  //////////////
  // Local Date/Time

  static const String useDeviceLocalTimeZoneKey  = 'use_device_local_time_zone';

  bool? get useDeviceLocalTimeZone {
    return _getBoolWithName(useDeviceLocalTimeZoneKey, defaultValue: true);
  }

  set useDeviceLocalTimeZone(bool? value) {
    _setBoolWithName(useDeviceLocalTimeZoneKey, value);
  }


  //////////////
  // Debug

  static const String debugMapThresholdDistanceKey  = 'debug_map_threshold_distance';

  int? get debugMapThresholdDistance {
    return _getIntWithName(debugMapThresholdDistanceKey, defaultValue: 200);
  }

  set debugMapThresholdDistance(int? value) {
    _setIntWithName(debugMapThresholdDistanceKey, value);
  }

  static const String debugGeoFenceRegionRadiusKey  = 'debug_geo_fence_region_radius';

  int? get debugGeoFenceRegionRadius {
    return _getIntWithName(debugGeoFenceRegionRadiusKey, defaultValue: null);
  }

  set debugGeoFenceRegionRadius(int? value) {
    _setIntWithName(debugGeoFenceRegionRadiusKey, value);
  }

  static const String debugDisableLiveGameCheckKey  = 'debug_disable_live_game_check';

  bool? get debugDisableLiveGameCheck {
    return _getBoolWithName(debugDisableLiveGameCheckKey);
  }

  set debugDisableLiveGameCheck(bool? value) {
    _setBoolWithName(debugDisableLiveGameCheckKey, value);
  }

  static const String debugMapLocationProviderKey  = 'debug_map_location_provider';

  bool? get debugMapLocationProvider {
    return _getBoolWithName(debugMapLocationProviderKey, defaultValue: false);
  }

  set debugMapLocationProvider(bool? value) {
    _setBoolWithName(debugMapLocationProviderKey, value);
  }

  static const String debugMapHideLevelsKey  = 'debug_map_hide_levels';

  bool? get debugMapHideLevels {
    return _getBoolWithName(debugMapHideLevelsKey, defaultValue: false);
  }

  set debugMapHideLevels(bool? value) {
    _setBoolWithName(debugMapHideLevelsKey, value);
  }

  static const String debugLastInboxMessageKey  = 'debug_last_inbox_message';

  String? get debugLastInboxMessage {
    return _getStringWithName(debugLastInboxMessageKey);
  }

  set debugLastInboxMessage(String? value) {
    _setStringWithName(debugLastInboxMessageKey, value);
  }

  //////////////
  // Firebase

// static const String firebaseMessagingSubscriptionTopisKey  = 'firebase_subscription_topis';
// Replacing "firebase_subscription_topis" with "firebase_messaging_subscription_topis" key ensures that
// all subsciptions will be applied again through Notifications BB APIs
  static const String firebaseMessagingSubscriptionTopicsKey  = 'firebase_messaging_subscription_topis';
  
  Set<String>? get firebaseMessagingSubscriptionTopics {
    List<String>? topicsList = _getStringListWithName(firebaseMessagingSubscriptionTopicsKey);
    return (topicsList != null) ? Set.from(topicsList) : null;
  }

  set firebaseMessagingSubscriptionTopics(Set<String>? value) {
    List<String>? topicsList = (value != null) ? List.from(value) : null;
    _setStringListWithName(firebaseMessagingSubscriptionTopicsKey, topicsList);
  }

  void addFirebaseMessagingSubscriptionTopic(String? value) {
    if (value != null) {
      Set<String> topics = firebaseMessagingSubscriptionTopics ?? Set();
      topics.add(value);
      firebaseMessagingSubscriptionTopics = topics;
    }
  }

  void removeFirebaseMessagingSubscriptionTopic(String? value) {
    if (value != null) {
      Set<String>? topics = firebaseMessagingSubscriptionTopics;
      topics?.remove(value);
      firebaseMessagingSubscriptionTopics = topics;
    }
  }

  static const String inboxFirebaseMessagingTokenKey  = 'inbox_firebase_messaging_token';

  String? get inboxFirebaseMessagingToken {
    return _getStringWithName(inboxFirebaseMessagingTokenKey);
  }

  set inboxFirebaseMessagingToken(String? value) {
    _setStringWithName(inboxFirebaseMessagingTokenKey, value);
  }

  static const String inboxFirebaseMessagingUserIdKey  = 'inbox_firebase_messaging_user_id';

  String? get inboxFirebaseMessagingUserId {
    return _getStringWithName(inboxFirebaseMessagingUserIdKey);
  }

  set inboxFirebaseMessagingUserId(String? value) {
    _setStringWithName(inboxFirebaseMessagingUserIdKey, value);
  }

  static const String inboxUserInfoKey  = 'inbox_user_info';

  InboxUserInfo? get inboxUserInfo {
    try {
      String? jsonString = _getStringWithName(inboxUserInfoKey);
      dynamic jsonData = AppJson.decode(jsonString);
      return (jsonData != null) ? InboxUserInfo.fromJson(jsonData) : null;
    } on Exception catch (e) { print(e.toString()); }
    return null;
  }

  set inboxUserInfo(InboxUserInfo? value) {
    _setStringWithName(inboxUserInfoKey, value != null ? json.encode(value.toJson()) : null);
  }

  //////////////
  // Polls

  static const String activePollsKey  = 'active_polls';

  String? get activePolls {
    return _getStringWithName(activePollsKey);
  }

  set activePolls(String? value) {
    _setStringWithName(activePollsKey, value);
  }

  /////////////
  // Config

  static const String _configEnvKey = 'config_environment';

  String? get configEnvironment {
    return _getStringWithName(_configEnvKey);
  }

  set configEnvironment(String? value) {
    _setStringWithName(_configEnvKey, value);
  }

  /////////////
  // Styles

  static const String _stylesContentModeKey = 'styles_content_mode';

  String? get stylesContentMode {
    return _getStringWithName(_stylesContentModeKey);
  }

  set stylesContentMode(String? value) {
    _setStringWithName(_stylesContentModeKey, value);
  }

  /////////////
  // Voter

  static const String _voterHiddenForPeriodKey = 'voter_hidden_for_period';

  bool? get voterHiddenForPeriod {
    return _getBoolWithName(_voterHiddenForPeriodKey);
  }

  set voterHiddenForPeriod(bool? value) {
    _setBoolWithName(_voterHiddenForPeriodKey, value);
  }

  /////////////
  // Http Proxy

  static const String _httpProxyEnabledKey = 'http_proxy_enabled';

  bool? get httpProxyEnabled {
    return _getBoolWithName(_httpProxyEnabledKey, defaultValue: false);
  }

  set httpProxyEnabled(bool? value) {
    _setBoolWithName(_httpProxyEnabledKey, value);
  }

  static const String _httpProxyHostKey = 'http_proxy_host';

  String? get httpProxyHost {
    return _getStringWithName(_httpProxyHostKey);
  }

  set httpProxyHost(String? value) {
    _setStringWithName(_httpProxyHostKey, value);
  }

  static const String _httpProxyPortKey = 'http_proxy_port';

  String? get httpProxyPort {
    return _getStringWithName(_httpProxyPortKey);
  }

  set httpProxyPort(String? value) {
    _setStringWithName(_httpProxyPortKey, value);
  }

  //////////////////
  // Guide

  static const String _guideContentSourceKey = 'guide_content_source';

  String? get guideContentSource {
    return _getStringWithName(_guideContentSourceKey);
  }

  set guideContentSource(String? value) {
    _setStringWithName(_guideContentSourceKey, value);
  }

  //////////////////
  // Auth2

  static const String _auth2AnonymousIdKey = 'auth2AnonymousId';

  String? get auth2AnonymousId {
    return _getStringWithName(_auth2AnonymousIdKey);
  }

  set auth2AnonymousId(String? value) {
    _setStringWithName(_auth2AnonymousIdKey, value);
  }

  static const String _auth2AnonymousTokenKey = 'auth2AnonymousToken';

  Auth2Token? get auth2AnonymousToken {
    return Auth2Token.fromJson(AppJson.decodeMap(_getEncryptedStringWithName(_auth2AnonymousTokenKey)));
  }

  set auth2AnonymousToken(Auth2Token? value) {
    _setEncryptedStringWithName(_auth2AnonymousTokenKey, AppJson.encode(value?.toJson()));
  }

  static const String _auth2AnonymousPrefsKey = 'auth2AnonymousPrefs';

  Auth2UserPrefs? get auth2AnonymousPrefs {
    return Auth2UserPrefs.fromJson(AppJson.decodeMap(_getEncryptedStringWithName(_auth2AnonymousPrefsKey)));
  }

  set auth2AnonymousPrefs(Auth2UserPrefs? value) {
    _setEncryptedStringWithName(_auth2AnonymousPrefsKey, AppJson.encode(value?.toJson()));
  }

  static const String _auth2AnonymousProfileKey = 'auth2AnonymousProfile';

  Auth2UserProfile? get auth2AnonymousProfile {
    return Auth2UserProfile.fromJson(AppJson.decodeMap(_getEncryptedStringWithName(_auth2AnonymousProfileKey)));
  }

  set auth2AnonymousProfile(Auth2UserProfile? value) {
    _setEncryptedStringWithName(_auth2AnonymousProfileKey, AppJson.encode(value?.toJson()));
  }

  static const String _auth2TokenKey = 'auth2Token';

  Auth2Token? get auth2Token {
    return Auth2Token.fromJson(AppJson.decodeMap(_getEncryptedStringWithName(_auth2TokenKey)));
  }

  set auth2Token(Auth2Token? value) {
    _setEncryptedStringWithName(_auth2TokenKey, AppJson.encode(value?.toJson()));
  }

  static const String _auth2UiucTokenKey = 'auth2UiucToken';

  Auth2Token? get auth2UiucToken {
    return Auth2Token.fromJson(AppJson.decodeMap(_getEncryptedStringWithName(_auth2UiucTokenKey)));
  }

  set auth2UiucToken(Auth2Token? value) {
    _setEncryptedStringWithName(_auth2UiucTokenKey, AppJson.encode(value?.toJson()));
  }

  static const String _auth2AccountKey = 'auth2Account';

  Auth2Account? get auth2Account {
    return Auth2Account.fromJson(AppJson.decodeMap(_getEncryptedStringWithName(_auth2AccountKey)));
  }

  set auth2Account(Auth2Account? value) {
    _setEncryptedStringWithName(_auth2AccountKey, AppJson.encode(value?.toJson()));
  }

  static const String auth2CardTimeKey  = 'auth2CardTime';

  int? get auth2CardTime {
    return _getIntWithName(auth2CardTimeKey);
  }

  set auth2CardTime(int? value) {
    _setIntWithName(auth2CardTimeKey, value);
  }

  //////////////////
  // Calendar

  static const String _calendarEventsTableKey = 'calendar_events_table';

  Map<String, String>? get calendarEventsTable {
    String? jsonString = _getStringWithName(_calendarEventsTableKey);
    try { return (AppJson.decode(jsonString) as Map?)?.cast<String, String>(); }
    catch(e) { print(e.toString()); }
    return null;
  }

  set calendarEventsTable(Map<String, String>? table) {
    String? tableToString = (table != null) ? json.encode(table) : null;
    _setStringWithName(_calendarEventsTableKey, tableToString);
  }

  static const String _calendarEnableSaveKey = 'calendar_enabled_to_save';

  bool? get calendarEnabledToSave{
    return _getBoolWithName(_calendarEnableSaveKey, defaultValue: true);
  }

  set calendarEnabledToSave(bool? value){
    _setBoolWithName(_calendarEnableSaveKey, value);
  }

  static const String _calendarEnablePromptKey = 'calendar_enabled_to_prompt';

  bool? get calendarCanPrompt{
    return _getBoolWithName(_calendarEnablePromptKey);
  }

  set calendarCanPrompt(bool? value){
    _setBoolWithName(_calendarEnablePromptKey, value);
  }

  //////////////////
  // GIES

  static const String _giesNavPagesKey  = 'gies_nav_pages';

  List<String>? get giesNavPages {
    return _getStringListWithName(_giesNavPagesKey);
  }

  set giesNavPages(List<String>? value) {
    _setStringListWithName(_giesNavPagesKey, value);
  }

  static const String _giesCompletedPagesKey  = 'gies_completed_pages';

  
  Set<String>? get giesCompletedPages {
    List<String>? pagesList = _getStringListWithName(_giesCompletedPagesKey);
    return (pagesList != null) ? Set.from(pagesList) : null;
  }

  set giesCompletedPages(Set<String>? value) {
    List<String>? pagesList = (value != null) ? List.from(value) : null;
    _setStringListWithName(_giesCompletedPagesKey, pagesList);
  }

  static const String _giesNotesKey = 'gies_notes';

  String? get giesNotes {
    return _getStringWithName(_giesNotesKey);
  }

  set giesNotes(String? value) {
    _setStringWithName(_giesNotesKey, value);
  }
}
