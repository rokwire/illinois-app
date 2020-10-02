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
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:http/http.dart' as http;
import 'package:illinois/utils/Utils.dart';
import 'package:path/path.dart';

class Localization with Service implements NotificationsListener {
  
  // Notifications
  static const String notifyLocaleChanged   = "edu.illinois.rokwire.localization.locale.updated";
  static const String notifyStringsUpdated  = "edu.illinois.rokwire.localization.strings.updated";

  // Singleton Factory
  static final Localization _logic = Localization._internal();

  factory Localization() {
    return _logic;
  }

  Localization._internal();

  // Multilanguage support
  final List<String> supportedLanguages = ['en', 'es','zh'];
  Iterable<Locale> supportedLocales() => supportedLanguages.map<Locale>((language) => Locale(language, ""));  

  // Data
  Directory _assetsDir;
  
  Locale _defaultLocale;
  Map<String,dynamic> _defaultStrings;
  Map<String,dynamic> _defaultAssetsStrings;
  Map<String,dynamic> _defaultCachedStrings;
  
  Locale _currentLocale;
  Map<String,dynamic> _localeStrings;
  Map<String,dynamic> _localeAssetsStrings;
  Map<String,dynamic> _localeCachedStrings;

  DateTime  _pausedDateTime;

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, AppLivecycle.notifyStateChanged);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {

    _assetsDir = await _getAssetsDir();
    
    String defaultLanguage = supportedLanguages[0];
    _defaultLocale = Locale.fromSubtags(languageCode : defaultLanguage);
    await _initDefaultStirngs(defaultLanguage);

    String curentLanguage = Storage().currentLanguage;
    if (curentLanguage != null) {
      _currentLocale = Locale.fromSubtags(languageCode : curentLanguage);
      _initLocaleStirngs(curentLanguage);
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Config() ]);
  }

  // Locale

  Locale get currentLocale {
    return _currentLocale ?? _defaultLocale;
  }

  set currentLocale(Locale value)  {
    if ((value == null) || (value.languageCode == _defaultLocale.languageCode)) {
      // use default
      _currentLocale = null;
      _localeStrings = _localeAssetsStrings = _localeCachedStrings = null;
      Storage().currentLanguage = null;
      //Notyfy when we change the locale (valid change)
      NotificationService().notify(notifyLocaleChanged, null);
    }
    else if ((_currentLocale == null) || (_currentLocale.languageCode != value.languageCode)) {
      _currentLocale = value;
      Storage().currentLanguage = value.languageCode;
      _initLocaleStirngs(value.languageCode);
      //Notyfy when we change the locale (valid change)
      NotificationService().notify(notifyLocaleChanged, null);
    }
  }

  // Load / Update

  Future<Directory> _getAssetsDir() async {
    Directory assetsDir = Config().assetsCacheDir;
    if ((assetsDir != null) && !await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    return assetsDir;
  }

  Future<void> _initDefaultStirngs(String language) async {
    _defaultStrings = _buildStrings(
      asset: _defaultAssetsStrings = await _loadAssetsStrings(language),
      cache: _defaultCachedStrings = await _loadCachedStrings(language));
    _updateDefaultStrings();
  }

  Future<void> _initLocaleStirngs(String language) async {
    _localeStrings = _buildStrings(
      asset: _localeAssetsStrings = await _loadAssetsStrings(language),
      cache: _localeCachedStrings = await _loadCachedStrings(language));
    _updateLocaleStrings();
  }

  Future<Map<String,dynamic>> _loadAssetsStrings(String language) async {
    dynamic jsonData;
    try {
      String jsonString = await rootBundle.loadString('assets/strings.$language.json');
      jsonData = AppJson.decode(jsonString);
    }
    catch (e) { print(e?.toString()); }
    return ((jsonData != null) && (jsonData is Map<String,dynamic>)) ? jsonData : null;
  }

  Future<Map<String,dynamic>> _loadCachedStrings(String language) async {
    dynamic jsonData;
    try { 
      String cacheFilePath = (_assetsDir != null) ? join(_assetsDir.path, 'strings.$language.json') : null;
      File cacheFile = (cacheFilePath != null) ? File(cacheFilePath) : null;
      
      String jsonString = ((cacheFile != null) && await cacheFile.exists()) ? await cacheFile.readAsString() : null;
      jsonData = AppJson.decode(jsonString);
    } catch (e) { print(e?.toString()); }
    return ((jsonData != null) && (jsonData is Map<String,dynamic>)) ? jsonData : null;
  }

  void _updateDefaultStrings() {
    if (_defaultLocale != null) {
      _updateStringsFromNet(_defaultLocale.languageCode, cache: _defaultCachedStrings).then((Map<String,dynamic> update) {
        if (update != null) {
          _localeStrings = _buildStrings(asset: _defaultAssetsStrings, cache: _defaultCachedStrings = update);
          NotificationService().notify(notifyStringsUpdated, null);
        }
      });
    }
  }

  void _updateLocaleStrings() {
    if (_currentLocale != null) {
      _updateStringsFromNet(_currentLocale.languageCode, cache: _localeCachedStrings).then((Map<String,dynamic> update) {
        if (update != null) {
          _localeStrings = _buildStrings(asset: _localeAssetsStrings, cache: _localeCachedStrings = update);
          NotificationService().notify(notifyStringsUpdated, null);
        }
      });
    }
  }
  Future<Map<String,dynamic>> _updateStringsFromNet(String language, { Map<String, dynamic> cache }) async {
    Map<String, dynamic> jsonData;
    try {
      String assetName = 'strings.$language.json';
      http.Response response = (Config().assetsUrl != null) ? await Network().get("${Config().assetsUrl}/$assetName") : null;
      String jsonString = ((response != null) && (response.statusCode == 200)) ? response.body : null;
      jsonData = (jsonString != null) ? AppJson.decode(jsonString) : null;
      if ((jsonData != null) && ((cache == null) || !DeepCollectionEquality().equals(jsonData, cache))) {
        String cacheFilePath = (_assetsDir != null) ? join(_assetsDir.path, assetName) : null;
        File cacheFile = (cacheFilePath != null) ? File(cacheFilePath) : null;
        if (cacheFile != null) {
          await cacheFile.writeAsString(jsonString, flush: true);
        }
      }
    } catch (e) {
      print(e.toString());
    }
    return jsonData;
  }

  static Map<String, dynamic> _buildStrings({Map<String, dynamic> asset, Map<String, dynamic> cache}) {
    Map<String, dynamic> strings = Map<String, dynamic>();
    if ((asset != null) && (0 < asset.length)) {
      strings.addAll(asset);
    }
    if ((cache != null) && (0 < cache.length)) {
      strings.addAll(cache);
    }
    return strings;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateDefaultStrings();
          _updateLocaleStrings();
        }
      }
    }
  }

  // Strings 

  String getString(String key, {String defaults, String language}) {
    String value;
    if ((value == null) && (_localeStrings != null) && ((language == null) || (language == _currentLocale?.languageCode))) {
      value = _localeStrings[key];
    }
    if ((value == null) && (_defaultStrings != null) && ((language == null) || (language == _defaultLocale?.languageCode))) {
      value = _defaultStrings[key];
    }
    return ((value != null) && (value is String)) ? value : defaults;
  }

  String getStringEx(String key, String defaults)  {
    return getString(key, defaults: defaults);
  }

  String getStringFromMapping(String text, Map<String, dynamic> stringsMap) {
    if ((text != null) && (stringsMap != null)) {
      String entry;
      if ((entry = _getStringFromLanguageMapping(text, stringsMap[_currentLocale?.languageCode])) != null) {
        return entry;
      }
      if ((entry = _getStringFromLanguageMapping(text, stringsMap[_defaultLocale?.languageCode])) != null) {
        return entry;
      }
    }
    return text;
  }

  String getStringFromKeyMapping(String key, Map<String, dynamic> stringsMap, {String defaults = ''}) {
    String text;
    if (AppString.isStringNotEmpty(key)) {
      //1. Get text value from assets
      text = Localization().getStringFromMapping(key, stringsMap); // returns 'key' if text is not found
      //2. If there is no text for this key then get text value from strings
      if (AppString.isStringEmpty(text) || text == key) {
        text = Localization().getStringEx(key, defaults);
      }
    }
    return AppString.getDefaultEmptyString(value: text, defaultValue: defaults);
  }

  static String _getStringFromLanguageMapping(String text, Map<String, dynamic> languageMap) {
    if (languageMap is Map) {
      String languageTextEntry = languageMap[text];
      if (languageTextEntry is String) {
        return languageTextEntry;
      }
    }
    return null;
  }

}

class AppLocalizations {
  Locale locale;
  
  AppLocalizations(Locale locale) {
    Localization().currentLocale = this.locale = locale;
  }
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {

  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return Localization().supportedLanguages.contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) {
    return true;
  }
}