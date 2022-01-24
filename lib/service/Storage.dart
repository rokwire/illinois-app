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
import 'package:flutter/foundation.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/Inbox.dart';
import 'package:illinois/model/illinicash/IlliniCashBallance.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/storage.dart' as rokwire_storage;
import 'package:rokwire_plugin/utils/utils.dart';

class Storage extends rokwire_storage.Storage {

  // Singletone Factory

  @protected
  Storage.internal() : super.internal();

  factory Storage() {
    return ((rokwire_storage.Storage.instance is Storage) ? (rokwire_storage.Storage.instance as Storage) : (rokwire_storage.Storage.instance = Storage.internal()));
  }

  static String get notifySettingChanged => rokwire_storage.Storage.notifySettingChanged;


  // User: readonly, backward compatability only.

  static const String _userKey  = 'user';

  Map<String, dynamic>? get userProfile {
    return JsonUtils.decodeMap(getStringWithName(_userKey));
  }

  // Dining: readonly, backward compatability only.

  static const String excludedFoodIngredientsPrefsKey  = 'excluded_food_ingredients_prefs';

  Set<String>? get excludedFoodIngredientsPrefs {
    List<String>? list = getStringListWithName(excludedFoodIngredientsPrefsKey);
    return (list != null) ? Set.from(list) : null;
  }

  static const String includedFoodTypesPrefsKey  = 'included_food_types_prefs';

  Set<String>? get includedFoodTypesPrefs {
    List<String>? list = getStringListWithName(includedFoodTypesPrefsKey);
    return (list != null) ? Set.from(list) : null;
  }

  // Notifications

  bool? getNotifySetting(String name) {
    return getBoolWithName(name, defaultValue: null);
  }

  void setNotifySetting(String name, bool? value) {
    return setBoolWithName(name, value);
  }

  /////////////
  // Polls

  static const String selectedPollTypeKey  = 'selected_poll_type';

  int? get selectedPollType {
    return getIntWithName(selectedPollTypeKey);
  }

  set selectedPollType(int? value) {
    setIntWithName(selectedPollTypeKey, value);
  }

  ///////////////
  // On Boarding

  static const String onBoardingPassedKey  = 'on_boarding_passed';
  static const String onBoardingExploreChoiceKey  = 'on_boarding_explore_campus';
  static const String onBoardingPersonalizeChoiceKey  = 'on_boarding_personalize';
  static const String onBoardingImproveChoiceKey  = 'on_boarding_improve';

  bool? get onBoardingPassed {
    return getBoolWithName(onBoardingPassedKey, defaultValue: false);
  }

  set onBoardingPassed(bool? showOnBoarding) {
    setBoolWithName(onBoardingPassedKey, showOnBoarding);
  }

  set onBoardingExploreCampus(bool? exploreCampus) {
    setBoolWithName(onBoardingExploreChoiceKey, exploreCampus);
  }

  bool? get onBoardingExploreCampus {
    return getBoolWithName(onBoardingExploreChoiceKey, defaultValue: true);
  }

  set onBoardingPersonalizeChoice(bool? personalize) {
    setBoolWithName(onBoardingPersonalizeChoiceKey, personalize);
  }

  bool? get onBoardingPersonalizeChoice {
    return getBoolWithName(onBoardingPersonalizeChoiceKey, defaultValue: true);
  }

  set onBoardingImproveChoice(bool? personalize) {
    setBoolWithName(onBoardingImproveChoiceKey, personalize);
  }

  bool? get onBoardingImproveChoice {
    return getBoolWithName(onBoardingImproveChoiceKey, defaultValue: true);
  }

  ////////////////
  // Upgrade

  static const String reportedUpgradeVersionsKey  = 'reported_upgrade_versions';

  Set<String> get reportedUpgradeVersions {
    List<String>? list = getStringListWithName(reportedUpgradeVersionsKey);
    return (list != null) ? Set.from(list) : Set<String>();
  }

  set reportedUpgradeVersion(String? version) {
    if (version != null) {
      Set<String> versions = reportedUpgradeVersions;
      versions.add(version);
      setStringListWithName(reportedUpgradeVersionsKey, versions.toList());
    }
  }

  ////////////////////////////
  // Privacy Update Version

  static const String privacyUpdateVersionKey  = 'privacy_update_version';

  String? get privacyUpdateVersion {
    return getStringWithName(privacyUpdateVersionKey);
  }

  set privacyUpdateVersion(String? value) {
    setStringWithName(privacyUpdateVersionKey, value);
  }

  ////////////////////////////
  // Upgrade Message Version

  static const String _userLoginVersionKey = 'user_login_version';

  String? get userLoginVersion {
    return getStringWithName(_userLoginVersionKey);
  }

  set userLoginVersion(String? value) {
    setStringWithName(_userLoginVersionKey, value);
  }

  ////////////////////////////
  // Last Run Version

  static const String lastRunVersionKey  = 'last_run_version';

  String? get lastRunVersion {
    return getStringWithName(lastRunVersionKey);
  }

  set lastRunVersion(String? value) {
    setStringWithName(lastRunVersionKey, value);
  }

  ////////////////
  // IlliniCash

  static const String illiniCashBallanceKey  = '_illinicash_ballance';

  IlliniCashBallance? get illiniCashBallance {
    return IlliniCashBallance.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(illiniCashBallanceKey)));
  }

  set illiniCashBallance(IlliniCashBallance? value) {
    setEncryptedStringWithName(illiniCashBallanceKey, value != null ? json.encode(value.toJson()) : null);
  }

  /////////////////////
  // Date offset

  static const String offsetDateKey  = 'settings_offset_date';

  set offsetDate(DateTime? value) {
    setStringWithName(offsetDateKey, AppDateTime().formatDateTime(value, ignoreTimeZone: true));
  }

  DateTime? get offsetDate {
    String? dateString = getStringWithName(offsetDateKey);
    return StringUtils.isNotEmpty(dateString) ? DateTimeUtils.dateTimeFromString(dateString) : null;
  }

  /////////////////
  // Language

  static const String currentLanguageKey  = 'current_language';

  String? get currentLanguage {
    return getStringWithName(currentLanguageKey);
  }

  set currentLanguage(String? value) {
    setStringWithName(currentLanguageKey, value);
  }

  //////////////////
  // Favorites

  static const String favoritesDialogWasVisibleKey  = 'favorites_dialog_was_visible';

  bool? get favoritesDialogWasVisible {
    return getBoolWithName(favoritesDialogWasVisibleKey);
  }

  set favoritesDialogWasVisible(bool? value) {
    setBoolWithName(favoritesDialogWasVisibleKey, value);
  }

  //////////////
  // Recent Items

  static const String recentItemsKey  = '_recent_items_json_string';
  
  List<dynamic>? get recentItems {
    final String? jsonString = getStringWithName(recentItemsKey);
    return JsonUtils.decode(jsonString);
  }

  set recentItems(List<dynamic>? recentItems) {
    setStringWithName(recentItemsKey, recentItems != null ? json.encode(recentItems) : null);
  }

  //////////////
  // Local Date/Time

  static const String useDeviceLocalTimeZoneKey  = 'use_device_local_time_zone';

  bool? get useDeviceLocalTimeZone {
    return getBoolWithName(useDeviceLocalTimeZoneKey, defaultValue: true);
  }

  set useDeviceLocalTimeZone(bool? value) {
    setBoolWithName(useDeviceLocalTimeZoneKey, value);
  }


  //////////////
  // Debug

  static const String debugMapThresholdDistanceKey  = 'debug_map_threshold_distance';

  int? get debugMapThresholdDistance {
    return getIntWithName(debugMapThresholdDistanceKey, defaultValue: 200);
  }

  set debugMapThresholdDistance(int? value) {
    setIntWithName(debugMapThresholdDistanceKey, value);
  }

  static const String debugGeoFenceRegionRadiusKey  = 'debug_geo_fence_region_radius';

  int? get debugGeoFenceRegionRadius {
    return getIntWithName(debugGeoFenceRegionRadiusKey, defaultValue: null);
  }

  set debugGeoFenceRegionRadius(int? value) {
    setIntWithName(debugGeoFenceRegionRadiusKey, value);
  }

  static const String debugDisableLiveGameCheckKey  = 'debug_disable_live_game_check';

  bool? get debugDisableLiveGameCheck {
    return getBoolWithName(debugDisableLiveGameCheckKey);
  }

  set debugDisableLiveGameCheck(bool? value) {
    setBoolWithName(debugDisableLiveGameCheckKey, value);
  }

  static const String debugMapLocationProviderKey  = 'debug_map_location_provider';

  bool? get debugMapLocationProvider {
    return getBoolWithName(debugMapLocationProviderKey, defaultValue: false);
  }

  set debugMapLocationProvider(bool? value) {
    setBoolWithName(debugMapLocationProviderKey, value);
  }

  static const String debugMapHideLevelsKey  = 'debug_map_hide_levels';

  bool? get debugMapHideLevels {
    return getBoolWithName(debugMapHideLevelsKey, defaultValue: false);
  }

  set debugMapHideLevels(bool? value) {
    setBoolWithName(debugMapHideLevelsKey, value);
  }

  static const String debugLastInboxMessageKey  = 'debug_last_inbox_message';

  String? get debugLastInboxMessage {
    return getStringWithName(debugLastInboxMessageKey);
  }

  set debugLastInboxMessage(String? value) {
    setStringWithName(debugLastInboxMessageKey, value);
  }

  //////////////
  // Firebase

// static const String firebaseMessagingSubscriptionTopisKey  = 'firebase_subscription_topis';
// Replacing "firebase_subscription_topis" with "firebase_messaging_subscription_topis" key ensures that
// all subsciptions will be applied again through Notifications BB APIs
  static const String firebaseMessagingSubscriptionTopicsKey  = 'firebase_messaging_subscription_topis';
  
  Set<String>? get firebaseMessagingSubscriptionTopics {
    List<String>? topicsList = getStringListWithName(firebaseMessagingSubscriptionTopicsKey);
    return (topicsList != null) ? Set.from(topicsList) : null;
  }

  set firebaseMessagingSubscriptionTopics(Set<String>? value) {
    List<String>? topicsList = (value != null) ? List.from(value) : null;
    setStringListWithName(firebaseMessagingSubscriptionTopicsKey, topicsList);
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
    return getStringWithName(inboxFirebaseMessagingTokenKey);
  }

  set inboxFirebaseMessagingToken(String? value) {
    setStringWithName(inboxFirebaseMessagingTokenKey, value);
  }

  static const String inboxFirebaseMessagingUserIdKey  = 'inbox_firebase_messaging_user_id';

  String? get inboxFirebaseMessagingUserId {
    return getStringWithName(inboxFirebaseMessagingUserIdKey);
  }

  set inboxFirebaseMessagingUserId(String? value) {
    setStringWithName(inboxFirebaseMessagingUserIdKey, value);
  }

  static const String inboxUserInfoKey  = 'inbox_user_info';

  InboxUserInfo? get inboxUserInfo {
    try {
      String? jsonString = getStringWithName(inboxUserInfoKey);
      dynamic jsonData = JsonUtils.decode(jsonString);
      return (jsonData != null) ? InboxUserInfo.fromJson(jsonData) : null;
    } on Exception catch (e) { print(e.toString()); }
    return null;
  }

  set inboxUserInfo(InboxUserInfo? value) {
    setStringWithName(inboxUserInfoKey, value != null ? json.encode(value.toJson()) : null);
  }

  //////////////
  // Polls

  static const String activePollsKey  = 'active_polls';

  String? get activePolls {
    return getStringWithName(activePollsKey);
  }

  set activePolls(String? value) {
    setStringWithName(activePollsKey, value);
  }

  /////////////
  // Config

  static const String _configEnvKey = 'config_environment';

  String? get configEnvironment {
    return getStringWithName(_configEnvKey);
  }

  set configEnvironment(String? value) {
    setStringWithName(_configEnvKey, value);
  }

  /////////////
  // Styles

  static const String _stylesContentModeKey = 'styles_content_mode';

  String? get stylesContentMode {
    return getStringWithName(_stylesContentModeKey);
  }

  set stylesContentMode(String? value) {
    setStringWithName(_stylesContentModeKey, value);
  }

  /////////////
  // Voter

  static const String _voterHiddenForPeriodKey = 'voter_hidden_for_period';

  bool? get voterHiddenForPeriod {
    return getBoolWithName(_voterHiddenForPeriodKey);
  }

  set voterHiddenForPeriod(bool? value) {
    setBoolWithName(_voterHiddenForPeriodKey, value);
  }

  /////////////
  // Http Proxy

  static const String _httpProxyEnabledKey = 'http_proxy_enabled';

  bool? get httpProxyEnabled {
    return getBoolWithName(_httpProxyEnabledKey, defaultValue: false);
  }

  set httpProxyEnabled(bool? value) {
    setBoolWithName(_httpProxyEnabledKey, value);
  }

  static const String _httpProxyHostKey = 'http_proxy_host';

  String? get httpProxyHost {
    return getStringWithName(_httpProxyHostKey);
  }

  set httpProxyHost(String? value) {
    setStringWithName(_httpProxyHostKey, value);
  }

  static const String _httpProxyPortKey = 'http_proxy_port';

  String? get httpProxyPort {
    return getStringWithName(_httpProxyPortKey);
  }

  set httpProxyPort(String? value) {
    setStringWithName(_httpProxyPortKey, value);
  }

  //////////////////
  // Guide

  static const String _guideContentSourceKey = 'guide_content_source';

  String? get guideContentSource {
    return getStringWithName(_guideContentSourceKey);
  }

  set guideContentSource(String? value) {
    setStringWithName(_guideContentSourceKey, value);
  }

  //////////////////
  // Auth2

  static const String _auth2AnonymousIdKey = 'auth2AnonymousId';

  String? get auth2AnonymousId {
    return getStringWithName(_auth2AnonymousIdKey);
  }

  set auth2AnonymousId(String? value) {
    setStringWithName(_auth2AnonymousIdKey, value);
  }

  static const String _auth2AnonymousTokenKey = 'auth2AnonymousToken';

  Auth2Token? get auth2AnonymousToken {
    return Auth2Token.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(_auth2AnonymousTokenKey)));
  }

  set auth2AnonymousToken(Auth2Token? value) {
    setEncryptedStringWithName(_auth2AnonymousTokenKey, JsonUtils.encode(value?.toJson()));
  }

  static const String _auth2AnonymousPrefsKey = 'auth2AnonymousPrefs';

  Auth2UserPrefs? get auth2AnonymousPrefs {
    return Auth2UserPrefs.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(_auth2AnonymousPrefsKey)));
  }

  set auth2AnonymousPrefs(Auth2UserPrefs? value) {
    setEncryptedStringWithName(_auth2AnonymousPrefsKey, JsonUtils.encode(value?.toJson()));
  }

  static const String _auth2AnonymousProfileKey = 'auth2AnonymousProfile';

  Auth2UserProfile? get auth2AnonymousProfile {
    return Auth2UserProfile.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(_auth2AnonymousProfileKey)));
  }

  set auth2AnonymousProfile(Auth2UserProfile? value) {
    setEncryptedStringWithName(_auth2AnonymousProfileKey, JsonUtils.encode(value?.toJson()));
  }

  static const String _auth2TokenKey = 'auth2Token';

  Auth2Token? get auth2Token {
    return Auth2Token.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(_auth2TokenKey)));
  }

  set auth2Token(Auth2Token? value) {
    setEncryptedStringWithName(_auth2TokenKey, JsonUtils.encode(value?.toJson()));
  }

  static const String _auth2UiucTokenKey = 'auth2UiucToken';

  Auth2Token? get auth2UiucToken {
    return Auth2Token.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(_auth2UiucTokenKey)));
  }

  set auth2UiucToken(Auth2Token? value) {
    setEncryptedStringWithName(_auth2UiucTokenKey, JsonUtils.encode(value?.toJson()));
  }

  static const String _auth2AccountKey = 'auth2Account';

  Auth2Account? get auth2Account {
    return Auth2Account.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(_auth2AccountKey)));
  }

  set auth2Account(Auth2Account? value) {
    setEncryptedStringWithName(_auth2AccountKey, JsonUtils.encode(value?.toJson()));
  }

  static const String auth2CardTimeKey  = 'auth2CardTime';

  int? get auth2CardTime {
    return getIntWithName(auth2CardTimeKey);
  }

  set auth2CardTime(int? value) {
    setIntWithName(auth2CardTimeKey, value);
  }

  //////////////////
  // Calendar

  static const String _calendarEventsTableKey = 'calendar_events_table';

  Map<String, String>? get calendarEventsTable {
    String? jsonString = getStringWithName(_calendarEventsTableKey);
    try { return (JsonUtils.decode(jsonString) as Map?)?.cast<String, String>(); }
    catch(e) { print(e.toString()); }
    return null;
  }

  set calendarEventsTable(Map<String, String>? table) {
    String? tableToString = (table != null) ? json.encode(table) : null;
    setStringWithName(_calendarEventsTableKey, tableToString);
  }

  static const String _calendarEnableSaveKey = 'calendar_enabled_to_save';

  bool? get calendarEnabledToSave{
    return getBoolWithName(_calendarEnableSaveKey, defaultValue: true);
  }

  set calendarEnabledToSave(bool? value){
    setBoolWithName(_calendarEnableSaveKey, value);
  }

  static const String _calendarEnablePromptKey = 'calendar_enabled_to_prompt';

  bool? get calendarCanPrompt{
    return getBoolWithName(_calendarEnablePromptKey);
  }

  set calendarCanPrompt(bool? value){
    setBoolWithName(_calendarEnablePromptKey, value);
  }

  //////////////////
  // GIES

  static const String _giesNavPagesKey  = 'gies_nav_pages';

  List<String>? get giesNavPages {
    return getStringListWithName(_giesNavPagesKey);
  }

  set giesNavPages(List<String>? value) {
    setStringListWithName(_giesNavPagesKey, value);
  }

  static const String _giesCompletedPagesKey  = 'gies_completed_pages';

  
  Set<String>? get giesCompletedPages {
    List<String>? pagesList = getStringListWithName(_giesCompletedPagesKey);
    return (pagesList != null) ? Set.from(pagesList) : null;
  }

  set giesCompletedPages(Set<String>? value) {
    List<String>? pagesList = (value != null) ? List.from(value) : null;
    setStringListWithName(_giesCompletedPagesKey, pagesList);
  }

  static const String _giesNotesKey = 'gies_notes';

  String? get giesNotes {
    return getStringWithName(_giesNotesKey);
  }

  set giesNotes(String? value) {
    setStringWithName(_giesNotesKey, value);
  }
}
