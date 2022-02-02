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

import 'dart:core';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class Assets with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.assets.changed";

  static const String _assetsName      = "assets.json";

  Map<String, dynamic>? _internalContent;
  Map<String, dynamic>? _externalContent;
  File?      _cacheFile;
  DateTime?  _pausedDateTime;


  // Singletone Factory

  static Assets? _instance;

  static Assets? get instance => _instance;
  
  @protected
  static set instance(Assets? value) => _instance = value;

  factory Assets() => _instance ?? (_instance = Assets.internal());

  @protected
  Assets.internal();

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
    _cacheFile = await getCacheFile();
    _internalContent = await loadFromAssets();
    _externalContent = await loadFromCache();

    if (_internalContent != null) {
      await super.initService();
      updateFromNet();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'Assets Initialization Failed',
        description: 'Failed to initialize application assets content.',
      );
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return {Config()};
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
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
          updateFromNet();
        }
      }
    }
  }

  // data

  @protected Map<String, dynamic>? get internalContent => _internalContent;
  @protected Map<String, dynamic>? get externalContent => _externalContent;
  @protected File? get cacheFile => _cacheFile;
  @protected DateTime? get pausedDateTime => _pausedDateTime;

  // Assets

  dynamic operator [](dynamic key) {
    return MapPathKey.entry(_externalContent, key) ?? MapPathKey.entry(_internalContent, key);
  }

  String? randomStringFromListWithKey(dynamic key) {
    dynamic list = this[key];
    dynamic entry = ((list != null) && (list is List) && list.isNotEmpty) ? list[Random().nextInt(list.length)] : null;
    return ((entry != null) && (entry is String)) ? entry : null;
  }

  // Implementation
  @protected
  String get cacheFileName => _assetsName;

  @protected
  Future<File?> getCacheFile() async {
    Directory? assetsDir = Config().assetsCacheDir;
    if ((assetsDir != null) && !await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    String? cacheFilePath = (assetsDir != null) ? join(assetsDir.path, cacheFileName) : null;
    return (cacheFilePath != null) ? File(cacheFilePath) : null;
  }

  @protected
  Future<Map<String, dynamic>?> loadFromCache() async {
    try {
      String? assetsContent = ((_cacheFile != null) && await _cacheFile!.exists()) ? await _cacheFile!.readAsString() : null;
      return JsonUtils.decodeMap(assetsContent);
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  @protected
  String get resourceAssetsKey => 'assets/$_assetsName';

  @protected
  Future<String> loadResourceAssetsJsonString() => rootBundle.loadString(resourceAssetsKey);

  @protected
  Future<Map<String, dynamic>?> loadFromAssets() async {
    try {
      String assetsContent = await loadResourceAssetsJsonString();
      return JsonUtils.decodeMap(assetsContent);
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  @protected
  String get networkAssetName => _assetsName;

  @protected
  Future<String?> loadContentStringFromNet() async {
    try {
      http.Response? response = (Config().assetsUrl != null) ? await Network().get("${Config().assetsUrl}/$networkAssetName") : null;
      return ((response != null) && (response.statusCode == 200)) ? response.body : null;
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  @protected
  Future<void> updateFromNet() async {
    try {
      String? externalContentString = await loadContentStringFromNet();
      Map<String, dynamic>? externalContent = JsonUtils.decodeMap(externalContentString);
      if ((externalContent != null) && !const DeepCollectionEquality().equals(_externalContent, externalContent)) {
        if (externalContent.isNotEmpty) {
          _externalContent = externalContent;
          await _cacheFile?.writeAsString(externalContentString!, flush: true);
        }
        else {
          _externalContent = null;
          await _cacheFile?.delete();
        }
        NotificationService().notify(notifyChanged);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
