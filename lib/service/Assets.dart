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
import 'package:flutter/services.dart' show rootBundle;
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/utils/Utils.dart';

class Assets with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.assets.changed";

  static const String _assetsName      = "assets.json";

  Map<String, dynamic>? _internalContent;
  Map<String, dynamic>? _externalContent;
  File?      _cacheFile;
  DateTime?  _pausedDateTime;


  // Singleton Factory

  Assets._internal();
  static final Assets _instance = Assets._internal();

  factory Assets() {
    return _instance;
  }

  Assets get instance {
    return _instance;
  }

  // Initialization

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
    _cacheFile = await _getCacheFile();
    _internalContent = await _loadFromAssets();
    _externalContent = await _loadFromCache();

    if (_internalContent != null) {
      await super.initService();
      _updateFromNet();
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
    return Set.from([Config()]);
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
          _updateFromNet();
        }
      }
    }
  }

  // Assets

  dynamic operator [](dynamic key) {
    return AppMapPathKey.entry(_externalContent, key) ?? AppMapPathKey.entry(_internalContent, key);
  }

  String? randomStringFromListWithKey(dynamic key) {
    dynamic list = this[key];
    dynamic entry = ((list != null) && (list is List) && (0 < list.length)) ? list[Random().nextInt(list.length)] : null;
    return ((entry != null) && (entry is String)) ? entry : null;
  }

  // Implementation

  Future<File?> _getCacheFile() async {
    Directory? assetsDir = Config().assetsCacheDir;
    if ((assetsDir != null) && !await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    String? cacheFilePath = (assetsDir != null) ? join(assetsDir.path, _assetsName) : null;
    return (cacheFilePath != null) ? File(cacheFilePath) : null;
  }

  Future<Map<String, dynamic>?> _loadFromCache() async {
    try {
      String? assetsContent = ((_cacheFile != null) && await _cacheFile!.exists()) ? await _cacheFile!.readAsString() : null;
      return AppJson.decodeMap(assetsContent);
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<Map<String, dynamic>?> _loadFromAssets() async {
    try {
      String assetsContent = await rootBundle.loadString('assets/$_assetsName');
      return AppJson.decodeMap(assetsContent);
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<String?> _loadContentStringFromNet() async {
    try {
      http.Response? response = (Config().assetsUrl != null) ? await Network().get("${Config().assetsUrl}/$_assetsName") : null;
      return ((response != null) && (response.statusCode == 200)) ? response.body : null;
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<void> _updateFromNet() async {
    try {
      String? externalContentString = await _loadContentStringFromNet();
      Map<String, dynamic>? externalContent = AppJson.decodeMap(externalContentString);
      if ((externalContent != null) && !DeepCollectionEquality().equals(_externalContent, externalContent)) {
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
      print(e.toString());
    }
  }
}
