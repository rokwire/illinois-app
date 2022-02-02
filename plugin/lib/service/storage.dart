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

import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/crypt.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Storage with Service {

  static const String notifySettingChanged  = 'edu.illinois.rokwire.setting.changed';
  
  static const String _ecryptionKeyId  = 'edu.illinois.rokwire.encryption.storage.key';
  static const String _encryptionIVId  = 'edu.illinois.rokwire.encryption.storage.iv';

  SharedPreferences? _sharedPreferences;
  String? _encryptionKey;
  String? _encryptionIV;

  // Singletone Factory

  static Storage? _instance;

  static Storage? get instance => _instance;
  
  @protected
  static set instance(Storage? value) => _instance = value;

  factory Storage() => _instance ?? (_instance = Storage.internal());

  @protected
  Storage.internal();

  // Service 

  @override
  Future<void> initService() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    _encryptionKey = await RokwirePlugin.getEncryptionKey(identifier: encryptionKeyId, size: AESCrypt.kCCBlockSizeAES128);
    _encryptionIV = await RokwirePlugin.getEncryptionKey(identifier: encryptionIVId, size: AESCrypt.kCCBlockSizeAES128);
    
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

  // Encryption

  String  get encryptionKeyId => _ecryptionKeyId;
  String? get encryptionKey => _encryptionKey;
  
  String  get encryptionIVId => _encryptionIVId;
  String? get encryptionIV => _encryptionIV;

  String? encrypt(String? value) {
    return ((value != null) && (_encryptionKey != null) && (_encryptionIV != null)) ?
      AESCrypt.encrypt(value, key: _encryptionKey, iv: _encryptionIV) : null;
  }

  String? decrypt(String? value) {
    return ((value != null) && (_encryptionKey != null) && (_encryptionIV != null)) ?
      AESCrypt.decrypt(value, key: _encryptionKey, iv: _encryptionIV) : null;
  }

  // Utilities

  String? getStringWithName(String name, {String? defaultValue}) {
    return _sharedPreferences?.getString(name) ?? defaultValue;
  }

  void setStringWithName(String name, String? value) {
    if (value != null) {
      _sharedPreferences?.setString(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  String? getEncryptedStringWithName(String name, {String? defaultValue}) {
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

  void setEncryptedStringWithName(String name, String? value) {
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

  List<String>? getStringListWithName(String name, {List<String>? defaultValue}) {
    return _sharedPreferences?.getStringList(name) ?? defaultValue;
  }

  void setStringListWithName(String name, List<String>? value) {
    if (value != null) {
      _sharedPreferences?.setStringList(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  bool? getBoolWithName(String name, {bool? defaultValue}) {
    return _sharedPreferences?.getBool(name) ?? defaultValue;
  }

  void setBoolWithName(String name, bool? value) {
    if(value != null) {
      _sharedPreferences?.setBool(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  int? getIntWithName(String name, {int? defaultValue}) {
    return _sharedPreferences?.getInt(name) ?? defaultValue;
  }

  void setIntWithName(String name, int? value) {
    if (value != null) {
      _sharedPreferences?.setInt(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  double? getDoubleWithName(String name, {double? defaultValue}) {
    return _sharedPreferences?.getDouble(name) ?? defaultValue;
  }

  void setDoubleWithName(String name, double? value) {
    if (value != null) {
      _sharedPreferences?.setDouble(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }


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

  void deleteEverything(){
    if (_sharedPreferences != null) {
      for(String key in _sharedPreferences!.getKeys()){
        _sharedPreferences!.remove(key);
      }
    }
  }

  // Config

  String get configEnvKey => 'edu.illinois.rokwire.config_environment';
  String? get configEnvironment => getStringWithName(configEnvKey);
  set configEnvironment(String? value) => setStringWithName(configEnvKey, value);

  // Upgrade

  String get reportedUpgradeVersionsKey  => 'edu.illinois.rokwire.reported_upgrade_versions';

  Set<String> get reportedUpgradeVersions {
    List<String>? list = getStringListWithName(reportedUpgradeVersionsKey);
    return (list != null) ? Set.from(list) : <String>{};
  }

  set reportedUpgradeVersion(String? version) {
    if (version != null) {
      Set<String> versions = reportedUpgradeVersions;
      versions.add(version);
      setStringListWithName(reportedUpgradeVersionsKey, versions.toList());
    }
  }

  // Auth2
  
  String get auth2AnonymousIdKey => 'edu.illinois.rokwire.auth2.anonymous.id';
  String? get auth2AnonymousId => getStringWithName(configEnvKey);
  set auth2AnonymousId(String? value) => setStringWithName(configEnvKey, value);

  String get auth2AnonymousTokenKey => 'edu.illinois.rokwire.auth2.anonymous.token';
  Auth2Token? get auth2AnonymousToken => Auth2Token.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(auth2AnonymousTokenKey)));
  set auth2AnonymousToken(Auth2Token? value) => setEncryptedStringWithName(auth2AnonymousTokenKey, JsonUtils.encode(value?.toJson()));

  String get auth2AnonymousPrefsKey => 'edu.illinois.rokwire.auth2.anonymous.prefs';
  Auth2UserPrefs? get auth2AnonymousPrefs => Auth2UserPrefs.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(auth2AnonymousPrefsKey)));
  set auth2AnonymousPrefs(Auth2UserPrefs? value) => setEncryptedStringWithName(auth2AnonymousPrefsKey, JsonUtils.encode(value?.toJson()));

  String get auth2AnonymousProfileKey => 'edu.illinois.rokwire.auth2.anonymous.profile';
  Auth2UserProfile? get auth2AnonymousProfile =>  Auth2UserProfile.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(auth2AnonymousProfileKey)));
  set auth2AnonymousProfile(Auth2UserProfile? value) => setEncryptedStringWithName(auth2AnonymousProfileKey, JsonUtils.encode(value?.toJson()));

  String get auth2TokenKey => 'edu.illinois.rokwire.auth2.token';
  Auth2Token? get auth2Token => Auth2Token.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(auth2TokenKey)));
  set auth2Token(Auth2Token? value) => setEncryptedStringWithName(auth2TokenKey, JsonUtils.encode(value?.toJson()));

  String get auth2AccountKey => 'edu.illinois.rokwire.auth2.account';
  Auth2Account? get auth2Account => Auth2Account.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(auth2AccountKey)));
  set auth2Account(Auth2Account? value) => setEncryptedStringWithName(auth2AccountKey, JsonUtils.encode(value?.toJson()));

  // Http Proxy
  String get httpProxyEnabledKey =>  'edu.illinois.rokwire.http_proxy.enabled';
  bool? get httpProxyEnabled => getBoolWithName(httpProxyEnabledKey);
  set httpProxyEnabled(bool? value) => setBoolWithName(httpProxyEnabledKey, value);

  String get httpProxyHostKey => 'edu.illinois.rokwire.http_proxy.host';
  String? get httpProxyHost => getStringWithName(httpProxyHostKey);
  set httpProxyHost(String? value) =>  setStringWithName(httpProxyHostKey, value);
  
  String get httpProxyPortKey => 'edu.illinois.rokwire.http_proxy.port';
  String? get httpProxyPort => getStringWithName(httpProxyPortKey);
  set httpProxyPort(String? value) => setStringWithName(httpProxyPortKey, value);

  // Language
  String get currentLanguageKey => 'edu.illinois.rokwire.current_language';
  String? get currentLanguage => getStringWithName(currentLanguageKey);
  set currentLanguage(String? value) => setStringWithName(currentLanguageKey, value);

  // Styles
  String get stylesContentModeKey => 'edu.illinois.rokwire.styles.content_mode';
  String? get stylesContentMode => getStringWithName(stylesContentModeKey);
  set stylesContentMode(String? value) => setStringWithName(stylesContentModeKey, value);

  // Inbox
  String get inboxFirebaseMessagingTokenKey => 'edu.illinois.rokwire.inbox.firebase_messaging.token';
  String? get inboxFirebaseMessagingToken => getStringWithName(inboxFirebaseMessagingTokenKey);
  set inboxFirebaseMessagingToken(String? value) => setStringWithName(inboxFirebaseMessagingTokenKey, value);

  String get inboxFirebaseMessagingUserIdKey => 'edu.illinois.rokwire.inbox.firebase_messaging.user_id';
  String? get inboxFirebaseMessagingUserId => getStringWithName(inboxFirebaseMessagingUserIdKey);
  set inboxFirebaseMessagingUserId(String? value) => setStringWithName(inboxFirebaseMessagingUserIdKey, value);

  String get inboxUserInfoKey => 'edu.illinois.rokwire.inbox.user_info';
  InboxUserInfo? get inboxUserInfo => InboxUserInfo.fromJson(JsonUtils.decode(getStringWithName(inboxUserInfoKey)));
  set inboxUserInfo(InboxUserInfo? value) => setStringWithName(inboxUserInfoKey, JsonUtils.encode(value?.toJson()));

  // Firebase
  String get inboxFirebaseMessagingSubscriptionTopicsKey => 'edu.illinois.rokwire.inbox.firebase_messaging.subscription_topis';
  Set<String>? get inboxFirebaseMessagingSubscriptionTopics => SetUtils.from(getStringListWithName(inboxFirebaseMessagingSubscriptionTopicsKey));
  set inboxFirebaseMessagingSubscriptionTopics(Set<String>? value) => setStringListWithName(inboxFirebaseMessagingSubscriptionTopicsKey, ListUtils.from(value));

  void addInboxFirebaseMessagingSubscriptionTopic(String? value) {
    if (value != null) {
      Set<String> topics = inboxFirebaseMessagingSubscriptionTopics ?? {};
      topics.add(value);
      inboxFirebaseMessagingSubscriptionTopics = topics;
    }
  }

  void removeInboxFirebaseMessagingSubscriptionTopic(String? value) {
    if (value != null) {
      Set<String>? topics = inboxFirebaseMessagingSubscriptionTopics;
      topics?.remove(value);
      inboxFirebaseMessagingSubscriptionTopics = topics;
    }
  }

  // Debug
  String get debugGeoFenceRegionRadiusKey  => 'edu.illinois.rokwire.debug.geo_fence.region_radius';
  int? get debugGeoFenceRegionRadius => getIntWithName(debugGeoFenceRegionRadiusKey);
  set debugGeoFenceRegionRadius(int? value) => setIntWithName(debugGeoFenceRegionRadiusKey, value);

  // Polls
  String get activePollsKey  => 'edu.illinois.rokwire.polls.active_polls';
  String? get activePolls => getStringWithName(activePollsKey);
  set activePolls(String? value) => setStringWithName(activePollsKey, value);

  // Calendar

  String get calendarEventsTableKey => 'edu.illinois.rokwire.calendar.events_table';
  Map<String, String>? get calendarEventsTable {
    try { return JsonUtils.decodeMap(getStringWithName(calendarEventsTableKey))?.cast<String, String>(); }
    catch(e) { debugPrint(e.toString()); return null; }
  }
  set calendarEventsTable(Map<String, String>? table) => setStringWithName(calendarEventsTableKey, JsonUtils.encode(table));

  String get calendarEnableSaveKey => 'edu.illinois.rokwire.calendar.save_enabled';
  bool? get calendarEnabledToSave => getBoolWithName(calendarEnableSaveKey, defaultValue: true);
  set calendarEnabledToSave(bool? value) => setBoolWithName(calendarEnableSaveKey, value);

  String get calendarEnablePromptKey => 'edu.illinois.rokwire.calendar.prompt_enabled';
  bool? get calendarCanPrompt => getBoolWithName(calendarEnablePromptKey, defaultValue: false);
  set calendarCanPrompt(bool? value) => setBoolWithName(calendarEnablePromptKey, value);
}
