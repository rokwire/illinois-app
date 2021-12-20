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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as Http;

import 'package:collection/collection.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:path/path.dart';

class FlexUI with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.flexui.changed";

  static const String _flexUIName   = "flexUI.json";

  Map<String, dynamic>? _content;
  Map<String, dynamic>? _contentSource;
  Set<dynamic>?         _features;
  File?                 _cacheFile;
  DateTime?             _pausedDateTime;

  // Singleton Factory

  FlexUI._internal();
  static final FlexUI _instance = FlexUI._internal();

  factory FlexUI() {
    return _instance;
  }

  FlexUI get instance {
    return _instance;
  }

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this,[
      Auth2.notifyPrefsChanged,
      Auth2.notifyUserDeleted,
      Auth2UserPrefs.notifyRolesChanged,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2.notifyLoginChanged,
      Auth2.notifyCardChanged,
      IlliniCash.notifyBallanceUpdated,
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _cacheFile = await _getCacheFile();
    _contentSource = await _loadContentSource();
    _content = _buildContent(_contentSource);
    _features = _buildFeatures(_content);
    if (_content != null) {
      await super.initService();
      _updateContentSourceFromNet();
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
    return Set.from([Config(), Auth2(), IlliniCash()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == Auth2.notifyPrefsChanged) ||
        (name == Auth2.notifyUserDeleted) ||
        (name == Auth2UserPrefs.notifyRolesChanged) ||
        (name == Auth2UserPrefs.notifyPrivacyLevelChanged) ||
        (name == Auth2.notifyLoginChanged) ||
        (name == Auth2.notifyCardChanged) || 
        (name == IlliniCash.notifyBallanceUpdated))
    {
      _updateContent();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
     _onAppLivecycleStateChanged(param); 
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateContentSourceFromNet();
        }
      }
    }
  }

  // Flex UI

  Future<File?> _getCacheFile() async {
    Directory? assetsDir = Config().assetsCacheDir!;
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    String cacheFilePath = join(assetsDir.path, _flexUIName);
    return File(cacheFilePath);
  }

  Future<String?> _loadContentSourceStringFromCache() async {
    return ((_cacheFile != null) && await _cacheFile!.exists()) ? await _cacheFile!.readAsString() : null;
  }

  Future<void> _saveContentSourceStringToCache(String? contentString) async {
    if (contentString != null) {
      await _cacheFile?.writeAsString(contentString, flush: true);
    }
    else if ((_cacheFile != null) && (await _cacheFile!.exists())) {
      try { _cacheFile!.delete(); } catch(e) { print(e.toString()); }
    }
  }

  Future<Map<String, dynamic>?> _loadContentSourceFromCache() async {
    return AppJson.decodeMap(await _loadContentSourceStringFromCache());
  }

  Future<Map<String, dynamic>?> _loadContentSourceFromAssets() async {
    try { return AppJson.decodeMap(await rootBundle.loadString('assets/$_flexUIName')); }
    catch(e) {print(e.toString());}
    return null;
  }

  Future<Map<String, dynamic>?> _loadContentSource() async {
    Map<String, dynamic>? conentSource;
    if (_isValidContentSource(conentSource = await _loadContentSourceFromCache())) {
      return conentSource;
    }
    else if (_isValidContentSource(conentSource = await _loadContentSourceFromAssets())) {
      return conentSource;
    }
    else {
      return null;
    }
  }

  Future<String?> _loadContentSourceStringFromNet() async {
    Http.Response? response = (Config().assetsUrl != null) ? await Network().get("${Config().assetsUrl}/$_flexUIName") : null;
    return ((response != null) && (response.statusCode == 200)) ? response.body : null;
  }

  Future<void> _updateContentSourceFromNet() async {
    String? contentSourceString = await _loadContentSourceStringFromNet();
    if (contentSourceString != null) { // request succeeded
      
      Map<String, dynamic>? contentSource = AppJson.decodeMap(contentSourceString);
      if (!_isValidContentSource(contentSource) && (_cacheFile != null) && await _cacheFile!.exists()) { // empty JSON content
        try { _cacheFile!.delete(); }                          // clear cached content source
        catch(e) { print(e.toString()); }
        contentSource = await _loadContentSourceFromAssets(); // load content source from assets
        contentSourceString = null;                           // do not store this content source
      }

      if (_isValidContentSource(contentSource) && ((_contentSource == null) || !DeepCollectionEquality().equals(_contentSource, contentSource))) {
        _contentSource = contentSource;
        _saveContentSourceStringToCache(contentSourceString);
        _updateContent();
      }
    }
  }

  void _updateContent() {
    Map<String, dynamic>? content = _buildContent(_contentSource);
    if ((content != null) && ((_content == null) || !DeepCollectionEquality().equals(_content, content))) {
      _content = content;
      _features = _buildFeatures(_content);
      NotificationService().notify(notifyChanged, null);
    }
  }

  static Set<dynamic>? _buildFeatures(Map<String, dynamic>? content) {
    dynamic featuresList = (content != null) ? content['features'] : null;
    return (featuresList is Iterable) ? Set.from(featuresList) : null;
  }

  static bool _isValidContentSource(Map<String, dynamic>? contentSource) {
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
    return _updateContent();
  }

// Local Build

  static Map<String, dynamic>? _buildContent(Map<String, dynamic>? contentSource) {
    Map<String, dynamic>? result;
    if (contentSource != null) {
      Map<String, dynamic> contents = contentSource['content'];
      Map<String, dynamic>? rules = contentSource['rules'];

      result = Map();
      contents.forEach((String key, dynamic list) {
        if (list is List) {
          List<String> resultList = <String>[];
          for (String entry in list as Iterable<String>) {
            if (_localeIsEntryAvailable(entry, group: key, rules: rules!)) {
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

  static bool _localeIsEntryAvailable(String entry, { String? group, required Map<String, dynamic> rules }) {

    String? pathEntry = (group != null) ? '$group.$entry' : null;

    Map<String, dynamic>? roleRules = rules['roles'];
    dynamic roleRule = (roleRules != null) ? (((pathEntry != null) ? roleRules[pathEntry] : null) ?? roleRules[entry]) : null;
    if ((roleRule != null) && !_localeEvalRoleRule(roleRule)) {
      return false;
    }

    Map<String, dynamic>? privacyRules = rules['privacy'];
    dynamic privacyRule = (privacyRules != null) ? (((pathEntry != null) ? privacyRules[pathEntry] : null) ?? privacyRules[entry]) : null;
    if ((privacyRule != null) && !_localeEvalPrivacyRule(privacyRule)) {
      return false;
    }
    
    Map<String, dynamic>? authRules = rules['auth'];
    dynamic authRule = (authRules != null) ? (((pathEntry != null) ? authRules[pathEntry] : null) ?? authRules[entry])  : null;
    if ((authRule != null) && !_localeEvalAuthRule(authRule)) {
      return false;
    }
    
    Map<String, dynamic>? platformRules = rules['platform'];
    dynamic platformRule = (platformRules != null) ? (((pathEntry != null) ? platformRules[pathEntry] : null) ?? platformRules[entry])  : null;
    if ((platformRule != null) && !_localeEvalPlatformRule(platformRule)) {
      return false;
    }

    Map<String, dynamic>? illiniCashRules = rules['illini_cash'];
    dynamic illiniCashRule = (illiniCashRules != null) ? (((pathEntry != null) ? illiniCashRules[pathEntry] : null) ?? illiniCashRules[entry])  : null;
    if ((illiniCashRule != null) && !_localeEvalIlliniCashRule(illiniCashRule)) {
      return false;
    }
    
    Map<String, dynamic>? enableRules = rules['enable'];
    dynamic enableRule = (enableRules != null) ? (((pathEntry != null) ? enableRules[pathEntry] : null) ?? enableRules[entry])  : null;
    if ((enableRule != null) && !_localeEvalEnableRule(enableRule)) {
      return false;
    }
    
    return true;
  }

  static bool _localeEvalRoleRule(dynamic roleRule) {
    return AppBoolExpr.eval(roleRule, (String? argument) {
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
        
        Set<UserRole>? userRoles = _localeEvalRoleParam(argument);
        if (userRoles != null) {
          if (not == true) {
            userRoles = Set.from(UserRole.values).cast<UserRole>().difference(userRoles);
          }

          if (all == true) {
            return DeepCollectionEquality().equals(Auth2().prefs?.roles, userRoles);
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

  static Set<UserRole>? _localeEvalRoleParam(String? roleParam) {
    if (roleParam != null) {
      if (RegExp("{.+}").hasMatch(roleParam)) {
        Set<UserRole> roles = Set<UserRole>();
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
        return (userRole != null) ? Set.from([userRole]) : null;
      }
    }
    return null;
  }

  static bool _localeEvalIlliniCashRule(dynamic illiniCashRule) {
    bool result = true;  // allow everything that is not defined or we do not understand
    if (illiniCashRule is Map) {
      illiniCashRule.forEach((dynamic key, dynamic value) {
        if ((key is String) && (key == 'housingResidenceStatus') && (value is bool)) {
           result = result && (IlliniCash().ballance?.housingResidenceStatus ?? false);
        }
      });
    }
    return result;
  }

  static bool _localeEvalPrivacyRule(dynamic privacyRule) {
    return (privacyRule is int) ? Auth2().privacyMatch(privacyRule) : true; // allow everything that is not defined or we do not understand
  }

  static bool _localeEvalAuthRule(dynamic authRule) {
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
          
          else if ((key == 'iCard') && (value is bool)) {
            result = result && ((Auth2().authCard != null) == value);
          }
          else if ((key == 'iCardNum') && (value is bool)) {
            result = result && ((0 < (Auth2().authCard?.cardNumber?.length ?? 0)) == value);
          }
          else if ((key == 'iCardLibraryNum') && (value is bool)) {
            result = result && ((0 < (Auth2().authCard?.libraryNumber?.length ?? 0)) == value);
          }
        }
      });
    }
    return result;
  }

  static bool _localeEvalPlatformRule(dynamic platformRule) {
    bool result = true;  // allow everything that is not defined or we do not understand
    if (platformRule is Map) {
      platformRule.forEach((dynamic key, dynamic value) {
        if (key is String) {
          if (key == 'os') {
            if (value is List) {
              result = result && value.contains(Platform.operatingSystem);
            }
            else if (value is String) {
              result = result && (value == Platform.operatingSystem);
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