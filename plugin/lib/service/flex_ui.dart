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

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart';

import 'package:collection/collection.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:path/path.dart';

class FlexUI with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.flexui.changed";

  static const String _flexUIName   = "flexUI.json";

  Map<String, dynamic>? _content;
  Map<String, dynamic>? _contentSource;
  Set<dynamic>?         _features;
  File?                 _cacheFile;
  DateTime?             _pausedDateTime;

  // Singletone Factory

  static FlexUI? _instance;

  static FlexUI? get instance => _instance;
  
  @protected
  static set instance(FlexUI? value) => _instance = value;

  factory FlexUI() => _instance ?? (_instance = FlexUI.internal());

  @protected
  FlexUI.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this,[
      Auth2.notifyPrefsChanged,
      Auth2.notifyUserDeleted,
      Auth2UserPrefs.notifyRolesChanged,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2.notifyLoginChanged,
      Auth2.notifyLinkChanged,
//    Auth2.notifyCardChanged,
//    IlliniCash.notifyBallanceUpdated,
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _cacheFile = await getCacheFile();
    _contentSource = await loadContentSource();
    _content = buildContent(_contentSource);
    _features = buildFeatures(_content);
    if (_content != null) {
      await super.initService();
      updateContentSourceFromNet();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.fatal,
        title: 'FlexUI Initialization Failed',
        description: 'Failed to initialize FlexUI content.',
      );
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Config(), Auth2() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == Auth2.notifyPrefsChanged) ||
        (name == Auth2.notifyUserDeleted) ||
        (name == Auth2UserPrefs.notifyRolesChanged) ||
        (name == Auth2UserPrefs.notifyPrivacyLevelChanged) ||
        (name == Auth2.notifyLoginChanged) ||
        (name == Auth2.notifyLinkChanged))
    {
      updateContent();
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
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          updateContentSourceFromNet();
        }
      }
    }
  }

  // Flex UI

  @protected
  String get cacheFileName => _flexUIName;

  @protected
  Future<File?> getCacheFile() async {
    Directory? assetsDir = Config().assetsCacheDir!;
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    String cacheFilePath = join(assetsDir.path, cacheFileName);
    return File(cacheFilePath);
  }

  @protected
  Future<String?> loadContentSourceStringFromCache() async {
    return ((_cacheFile != null) && await _cacheFile!.exists()) ? await _cacheFile!.readAsString() : null;
  }

  @protected
  Future<void> saveContentSourceStringToCache(String? contentString) async {
    if (contentString != null) {
      await _cacheFile?.writeAsString(contentString, flush: true);
    }
    else if ((_cacheFile != null) && (await _cacheFile!.exists())) {
      try { _cacheFile!.delete(); } catch(e) { debugPrint(e.toString()); }
    }
  }

  @protected
  Future<Map<String, dynamic>?> loadContentSourceFromCache() async {
    return JsonUtils.decodeMap(await loadContentSourceStringFromCache());
  }

  @protected
  String get resourceAssetsKey => 'assets/$_flexUIName';

  @protected
  Future<Map<String, dynamic>?> loadContentSourceFromAssets() async {
    try { return JsonUtils.decodeMap(await rootBundle.loadString(resourceAssetsKey)); }
    catch(e) { debugPrint(e.toString());}
    return null;
  }

  @protected
  Future<Map<String, dynamic>?> loadContentSource() async {
    Map<String, dynamic>? conentSource;
    if (isValidContentSource(conentSource = await loadContentSourceFromCache())) {
      return conentSource;
    }
    else if (isValidContentSource(conentSource = await loadContentSourceFromAssets())) {
      return conentSource;
    }
    else {
      return null;
    }
  }

  @protected
  String get networkAssetName => _flexUIName;

  @protected
  Future<String?> loadContentSourceStringFromNet() async {
    Response? response = (Config().assetsUrl != null) ? await Network().get("${Config().assetsUrl}/$networkAssetName") : null;
    return ((response != null) && (response.statusCode == 200)) ? response.body : null;
  }

  @protected
  Future<void> updateContentSourceFromNet() async {
    String? contentSourceString = await loadContentSourceStringFromNet();
    if (contentSourceString != null) { // request succeeded
      
      Map<String, dynamic>? contentSource = JsonUtils.decodeMap(contentSourceString);
      if (!isValidContentSource(contentSource) && (_cacheFile != null) && await _cacheFile!.exists()) { // empty JSON content
        try { _cacheFile!.delete(); }                          // clear cached content source
        catch(e) { debugPrint(e.toString()); }
        contentSource = await loadContentSourceFromAssets(); // load content source from assets
        contentSourceString = null;                           // do not store this content source
      }

      if (isValidContentSource(contentSource) && ((_contentSource == null) || !const DeepCollectionEquality().equals(_contentSource, contentSource))) {
        _contentSource = contentSource;
        saveContentSourceStringToCache(contentSourceString);
        updateContent();
      }
    }
  }

  @protected
  void updateContent() {
    Map<String, dynamic>? content = buildContent(_contentSource);
    if ((content != null) && ((_content == null) || !const DeepCollectionEquality().equals(_content, content))) {
      _content = content;
      _features = buildFeatures(_content);
      NotificationService().notify(notifyChanged, null);
    }
  }

  @protected
  Set<dynamic>? buildFeatures(Map<String, dynamic>? content) {
    dynamic featuresList = (content != null) ? content['features'] : null;
    return (featuresList is Iterable) ? Set.from(featuresList) : null;
  }

  @protected
  bool isValidContentSource(Map<String, dynamic>? contentSource) {
    return (contentSource != null) && (contentSource['content'] is Map) && (contentSource['rules'] is Map);
  }

  // Content

  Map<String, dynamic>? get content {
    return _content;
  }

  dynamic operator [](dynamic key) {
    return (_content != null) ? _content![key] : null;
  }

  Set<dynamic>? get features {
    return _features;
  }

  bool hasFeature(String feature) {
    return (_features == null) || _features!.contains(feature);
  }

  Future<void> update() async {
    return updateContent();
  }

// Local Build

  @protected
  Map<String, dynamic>? buildContent(Map<String, dynamic>? contentSource) {
    Map<String, dynamic>? result;
    if (contentSource != null) {
      Map<String, dynamic> contents = contentSource['content'];
      Map<String, dynamic>? rules = contentSource['rules'];

      result = {};
      contents.forEach((String key, dynamic list) {
        if (list is List) {
          List<String> resultList = <String>[];
          for (String entry in list) {
            if (localeIsEntryAvailable(entry, group: key, rules: rules!)) {
              resultList.add(entry);
            }
          }
          result![key] = resultList;
        }
        else {
          result![key] = list;
        }
      });
    }
    return result;
  }

  @protected
  bool localeIsEntryAvailable(String entry, { String? group, required Map<String, dynamic> rules }) {

    String? pathEntry = (group != null) ? '$group.$entry' : null;

    Map<String, dynamic>? roleRules = rules['roles'];
    dynamic roleRule = (roleRules != null) ? (((pathEntry != null) ? roleRules[pathEntry] : null) ?? roleRules[entry]) : null;
    if ((roleRule != null) && !localeEvalRoleRule(roleRule)) {
      return false;
    }

    Map<String, dynamic>? privacyRules = rules['privacy'];
    dynamic privacyRule = (privacyRules != null) ? (((pathEntry != null) ? privacyRules[pathEntry] : null) ?? privacyRules[entry]) : null;
    if ((privacyRule != null) && !localeEvalPrivacyRule(privacyRule)) {
      return false;
    }
    
    Map<String, dynamic>? authRules = rules['auth'];
    dynamic authRule = (authRules != null) ? (((pathEntry != null) ? authRules[pathEntry] : null) ?? authRules[entry])  : null;
    if ((authRule != null) && !localeEvalAuthRule(authRule)) {
      return false;
    }
    
    Map<String, dynamic>? platformRules = rules['platform'];
    dynamic platformRule = (platformRules != null) ? (((pathEntry != null) ? platformRules[pathEntry] : null) ?? platformRules[entry])  : null;
    if ((platformRule != null) && !localeEvalPlatformRule(platformRule)) {
      return false;
    }

    Map<String, dynamic>? enableRules = rules['enable'];
    dynamic enableRule = (enableRules != null) ? (((pathEntry != null) ? enableRules[pathEntry] : null) ?? enableRules[entry])  : null;
    if ((enableRule != null) && !_localeEvalEnableRule(enableRule)) {
      return false;
    }
    
    return true;
  }

  @protected
  bool localeEvalRoleRule(dynamic roleRule) {
    return BoolExpr.eval(roleRule, (String? argument) {
      if (argument != null) {
        bool? not, all, any;
        if (not = argument.startsWith('~')) {
          argument = argument.substring(1);
        }
        if (all = argument.endsWith('!')) {
          argument = argument.substring(0, argument.length - 1);
        }
        else if (any = argument.endsWith('?')) {
          argument = argument.substring(0, argument.length - 1);
        }
        
        Set<UserRole>? userRoles = localeEvalRoleParam(argument);
        if (userRoles != null) {
          if (not == true) {
            userRoles = Set.from(UserRole.values).cast<UserRole>().difference(userRoles);
          }

          if (all == true) {
            return const DeepCollectionEquality().equals(Auth2().prefs?.roles, userRoles);
          }
          else if (any == true) {
            return Auth2().prefs?.roles?.intersection(userRoles).isNotEmpty ?? false;
          }
          else {
            return Auth2().prefs?.roles?.containsAll(userRoles) ?? false;
          }
        }
      }
      return null;
    });
  }

  @protected
  Set<UserRole>? localeEvalRoleParam(String? roleParam) {
    if (roleParam != null) {
      if (RegExp("{.+}").hasMatch(roleParam)) {
        Set<UserRole> roles = <UserRole>{};
        String rolesStr = roleParam.substring(1, roleParam.length - 1);
        List<String> rolesStrList = rolesStr.split(',');
        for (String roleStr in rolesStrList) {
          UserRole? role = UserRole.fromString(roleStr.trim());
          if (role != null) {
            roles.add(role);
          }
        }
        return roles;
      }
      else {
        UserRole? userRole = UserRole.fromString(roleParam);
        return (userRole != null) ? { userRole } : null;
      }
    }
    return null;
  }

  @protected
  bool localeEvalPrivacyRule(dynamic privacyRule) {
    return (privacyRule is int) ? Auth2().privacyMatch(privacyRule) : true; // allow everything that is not defined or we do not understand
  }

  @protected
  bool localeEvalAuthRule(dynamic authRule) {
    bool result = true;  // allow everything that is not defined or we do not understand
    if (authRule is Map) {
      authRule.forEach((dynamic key, dynamic value) {
        if (key is String) {
          if ((key == 'loggedIn') && (value is bool)) {
            result = result && (Auth2().isLoggedIn == value);
          }
          else if ((key == 'shibbolethLoggedIn') && (value is bool)) {
            result = result && (Auth2().isOidcLoggedIn == value);
          }
          else if ((key == 'phoneLoggedIn') && (value is bool)) {
            result = result && (Auth2().isPhoneLoggedIn == value);
          }
          else if ((key == 'emailLoggedIn') && (value is bool)) {
            result = result && (Auth2().isEmailLoggedIn == value);
          }
          else if ((key == 'phoneOrEmailLoggedIn') && (value is bool)) {
            result = result && ((Auth2().isPhoneLoggedIn || Auth2().isEmailLoggedIn) == value) ;
          }
          else if ((key == 'shibbolethLinked') && (value is bool)) {
            result = result && (Auth2().isOidcLinked == value);
          }
          else if ((key == 'phoneLinked') && (value is bool)) {
            result = result && (Auth2().isPhoneLinked == value);
          }
          else if ((key == 'emailLinked') && (value is bool)) {
            result = result && (Auth2().isEmailLinked == value);
          }
          else if ((key == 'accountRole') && (value is String)) {
            result = result && Auth2().hasRole(value);
          }
          else if ((key == 'shibbolethMemberOf') && (value is String)) {
            result = result && Auth2().isShibbolethMemberOf(value);
          }
          else if ((key == 'eventEditor') && (value is bool)) {
            result = result && (Auth2().isEventEditor == value);
          }
          else if ((key == 'stadiumPollManager') && (value is bool)) {
            result = result && (Auth2().isStadiumPollManager == value);
          }
        }
      });
    }
    return result;
  }

  @protected
  static bool localeEvalPlatformRule(dynamic platformRule) {
    bool result = true;  // allow everything that is not defined or we do not understand
    if (platformRule is Map) {
      platformRule.forEach((dynamic key, dynamic value) {
        if (key is String) {
          String? target;
          if (key == 'os') {
            target = Platform.operatingSystem;
          }
          else if (key == 'envirnment') {
            target = configEnvToString(Config().configEnvironment);
          }
          else if (key == 'build') {
            if (kReleaseMode) {
              target = 'release';
            }
            else if (kProfileMode) {
              target = 'profile';
            }
            else if (kDebugMode) {
              target = 'debug';
            }
          }

          if (target != null) {
            if (value is List) {
              result = result && value.contains(target);
            }
            else if (value is String) {
              result = result && (value == target);
            }
          }
        }
      });
    }
    return result;
  }

  static bool _localeEvalEnableRule(dynamic enableRule) {
    return (enableRule is bool) ? enableRule : true; // allow everything that is not defined or we do not understand
  }
}