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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as Http;

import 'package:collection/collection.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/UserData.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Assets.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class FlexUI with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.flexui.changed";

  static const String _flexUIName   = "flexUI.json";

  Map<String, dynamic> _content;
  Set<dynamic>         _features;
  Http.Client          _httpClient;
  String               _dataVersion;
  File                 _cacheFile;
  DateTime             _pausedDateTime;

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
      User.notifyUserUpdated,
      User.notifyRolesUpdated,
      User.notifyPrivacyLevelChanged,
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
    _dataVersion = AppVersion.majorVersion(Config().appVersion, 2);
    _cacheFile = await _getCacheFile();
    _content = await _loadContentFromCache();
    if (_content == null) {
      await _initFromNet();
    }
    else {
      _features = _buildFeatures(_content);
      _updateFromNet();
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config(), User(), Auth2(), IlliniCash(), Assets()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == User.notifyUserUpdated) ||
        (name == User.notifyRolesUpdated) ||
        (name == User.notifyPrivacyLevelChanged) ||
        (name == Auth2.notifyLoginChanged) ||
        (name == Auth2.notifyCardChanged) || 
        (name == IlliniCash.notifyBallanceUpdated))
    {
      _updateFromNet();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
     _onAppLivecycleStateChanged(param); 
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateFromNet();
        }
      }
    }
  }

  // Flex UI

  Future<File> _getCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _flexUIName);
    return File(cacheFilePath);
  }

  Future<String> _loadContentStringFromCache() async {
    return ((_cacheFile != null) && await _cacheFile.exists()) ? await _cacheFile.readAsString() : null;
  }

  Future<void> _saveContentStringToCache(String contentString) async {
    await _cacheFile?.writeAsString(contentString ?? '', flush: true);
  }

  Future<Map<String, dynamic>> _loadContentFromCache() async {
    return _contentFromJsonString(await _loadContentStringFromCache());
  }

  Future<String> _loadContentStringFromNet() async {

    //TMP: try { return AppJson.encode(await _localBuild()); } catch (e) { print(e.toString()); }

    Http.Client httpClient;
    
    if (_httpClient != null) {
      _httpClient.close();
      _httpClient = null;
    }

    String url = '${Config().talentChooserUrl}/ui-content?data-version=$_dataVersion';
    
    Map<String, dynamic> post = {
      'user': User().data?.toShortJson(),
      //'auth_token': Auth2().uiucToken?.toJson(),
      'auth_token': Auth2Token.fromOther(Auth2().uiucToken, refreshToken: Auth2().uiucToken?.accessToken).toJson(),
      'auth_user': Auth2().user?.uiucAccount?.toJson(),
      'card': Auth2().authCard?.toShortJson(),
      'pii': Auth2().user?.pii?.toShortJson(),
      'illini_cash': IlliniCash().ballance?.toJson(),
      'platform': platformJson,
    };
    
    try {
      String body = json.encode(post);
      _httpClient = httpClient = Http.Client();
      Http.Response response = await Network().get(url, body:body, auth: NetworkAuth.App, client: _httpClient);
      int responseCode = response?.statusCode ?? -1;
      String responseBody = response?.body;
      Log.d('FlexUI: GET $url\n$body\nResponse $responseCode:\n$responseBody\n');
      return ((response != null) && (responseCode == 200)) ? responseBody : null;
    } catch (e) {
      print(e.toString());
    }
    finally {
      if (_httpClient == httpClient) {
        _httpClient = null;
      }
    }

    return null;
  }

  Future<void> _initFromNet() async {
    String jsonString = await _loadContentStringFromNet();
    Map<String, dynamic> content = _contentFromJsonString(jsonString);

    if (content == null) {
      content = await _localBuild();
      jsonString = AppJson.encode(content);
    }

    if (content != null) {
      _content = content;
      _saveContentStringToCache(jsonString);

      _features = _buildFeatures(_content);
      NotificationService().notify(notifyChanged, null);
    }
  }

  Future<void> _updateFromNet() async {
    String jsonString = await _loadContentStringFromNet();
    Map<String, dynamic> content = _contentFromJsonString(jsonString);

    //NB: This is not good to go in app release.
    if (content == null) {
      content = await _localBuild();
      jsonString = AppJson.encode(content);
    }

    if ((content != null) && ((_content == null) || !DeepCollectionEquality().equals(_content, content))) {
      _content = content;
      _saveContentStringToCache(jsonString);

      _features = _buildFeatures(_content);
      NotificationService().notify(notifyChanged, null);
    }
  }

  static Map<String, dynamic> _contentFromJsonString(String jsonString) {
    return AppJson.decode(jsonString);
  }

  static Set<dynamic> _buildFeatures(Map<String, dynamic> content) {
    dynamic featuresList = (content != null) ? content['features'] : null;
    return (featuresList is Iterable) ? Set.from(featuresList) : null;
  }

  static Map<String, dynamic> get platformJson {
    return {
        'os': Platform.operatingSystem,
    };
  }

  // Content

  Map<String, dynamic> get content {
    return _content;
  }

  dynamic operator [](dynamic key) {
    return (_content != null) ? _content[key] : null;
  }

  Set<dynamic> get features {
    return _features;
  }

  bool hasFeature(String feature) {
    return (_features == null) || _features.contains(feature);
  }

  Future<void> update() async {
    return _updateFromNet();
  }

// Local Build

  static Future<Map<String, dynamic>> _localBuild() async {
    String flexUIString = await rootBundle.loadString('assets/$_flexUIName');
    Map<String, dynamic> flexUI = AppJson.decodeMap(flexUIString);
    Map<String, dynamic> contents = flexUI['content'];
    Map<String, dynamic> rules = flexUI['rules'];

    Map<String, dynamic> result = Map();
    contents.forEach((String key, dynamic list) {
      List<String> resultList = [];
      for (String entry in list) {
        if (_localeIsEntryAvailable(entry, group: key, rules: rules)) {
          resultList.add(entry);
        }
      }
      result[key] = resultList;
    });

    return result;
  }

  static bool _localeIsEntryAvailable(String entry, { String group, Map<String, dynamic> rules }) {

    if (rules == null) {
      rules = Assets()['flex_ui.rules'];
    }

    String pathEntry = (group != null) ? '$group.$entry' : null;

    Map<String, dynamic> roleRules = rules['roles'];
    dynamic roleRule = (roleRules != null) ? (((pathEntry != null) ? roleRules[pathEntry] : null) ?? roleRules[entry]) : null;
    if ((roleRule != null) && !_localeEvalRoleRule(roleRule)) {
      return false;
    }

    Map<String, dynamic> privacyRules = rules['privacy'];
    dynamic privacyRule = (privacyRules != null) ? (((pathEntry != null) ? privacyRules[pathEntry] : null) ?? privacyRules[entry]) : null;
    if ((privacyRule != null) && !_localeEvalPrivacyRule(privacyRule)) {
      return false;
    }
    
    Map<String, dynamic> authRules = rules['auth'];
    dynamic authRule = (authRules != null) ? (((pathEntry != null) ? authRules[pathEntry] : null) ?? authRules[entry])  : null;
    if ((authRule != null) && !_localeEvalAuthRule(authRule)) {
      return false;
    }
    
    Map<String, dynamic> platformRules = rules['platform'];
    dynamic platformRule = (platformRules != null) ? (((pathEntry != null) ? platformRules[pathEntry] : null) ?? platformRules[entry])  : null;
    if ((platformRule != null) && !_localeEvalPlatformRule(platformRule)) {
      return false;
    }

    Map<String, dynamic> illiniCashRules = rules['illini_cash'];
    dynamic illiniCashRule = (illiniCashRules != null) ? (((pathEntry != null) ? illiniCashRules[pathEntry] : null) ?? illiniCashRules[entry])  : null;
    if ((illiniCashRule != null) && !_localeEvalIlliniCashRule(illiniCashRule)) {
      return false;
    }
    
    Map<String, dynamic> enableRules = rules['enable'];
    dynamic enableRule = (enableRules != null) ? (((pathEntry != null) ? enableRules[pathEntry] : null) ?? enableRules[entry])  : null;
    if ((enableRule != null) && !_localeEvalEnableRule(enableRule)) {
      return false;
    }
    
    return true;
  }

  static bool _localeEvalRoleRule(dynamic roleRule) {
    return AppBoolExpr.eval(roleRule, (String argument) {
      UserRole userRole = UserRole.fromString(argument);
      return (userRole != null) ? (User().roles?.contains(userRole) ?? false) : null;
    });
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
    return (privacyRule is int) ? User().privacyMatch(privacyRule) : true; // allow everything that is not defined or we do not understand
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
          
          else if ((key == 'shibbolethMemberOf') && (value is String)) {
            result = result && Auth2().isMemberOf(value);
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