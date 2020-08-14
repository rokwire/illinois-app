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
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/utils/Utils.dart';

class Assets with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.assets.changed";

  static const String _assetsName      = "assets.json";

  File      _cacheFile;
  DateTime  _pausedDateTime;

  // Singleton Factory

  Assets._internal();
  static final Assets _instance = Assets._internal();

  factory Assets() {
    return _instance;
  }

  Assets get instance {
    return _instance;
  }

  // Assets

  Map<String, dynamic> _assets;

  dynamic operator [](dynamic key) {
    return AppMapPathKey.entry(_assets, key);
  }

  String randomStringFromListWithKey(dynamic key) {
    dynamic list = AppMapPathKey.entry(_assets, key);
    dynamic entry = ((list != null) && (list is List) && (0 < list.length)) ? list[Random().nextInt(list.length)] : null;
    return ((entry != null) && (entry is String)) ? entry : null;
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
    await _getCacheFile();
    await _loadFromCache();
    if (_assets == null) {
      await _loadFromAssets();
    }
    _loadFromNet();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config()]);
  }

  Future<void> _getCacheFile() async {
    Directory assetsDir = Config().assetsCacheDir;
    if ((assetsDir != null) && !await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    String cacheFilePath = (assetsDir != null) ? join(assetsDir.path, _assetsName) : null;
    _cacheFile = (cacheFilePath != null) ? File(cacheFilePath) : null;
  }

  Future<void> _loadFromCache() async {
    try {
      String assetsContent = ((_cacheFile != null) && await _cacheFile.exists()) ? await _cacheFile.readAsString() : null;
      await _applyAssetsContent(assetsContent);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _loadFromAssets() async {
    try {
      String assetsContent = await rootBundle.loadString('assets/$_assetsName');
      await _applyAssetsContent(assetsContent);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _loadFromNet() async {
    try {
      http.Response response = (Config().assetsUrl != null) ? await Network().get("${Config().assetsUrl}/$_assetsName") : null;
      String assetsContent =  ((response != null) && (response.statusCode == 200)) ? response.body : null;
      await _applyAssetsContent(assetsContent, cacheContent: true, notifyUpdate: true);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _applyAssetsContent(String assetsContent, {bool cacheContent = false, bool notifyUpdate = false}) async {
    try {
      Map<String, dynamic> assets = (assetsContent != null) ? AppJson.decode(assetsContent) : null;
      if ((assets != null) && assets.isNotEmpty) {
        if ((_assets == null) || !DeepCollectionEquality().equals(_assets, assets)) {
          _assets = assets;
          if (notifyUpdate) {
            NotificationService().notify(notifyChanged, null);
          }
          if ((_cacheFile != null) && cacheContent) {
            await _cacheFile.writeAsString(assetsContent, flush: true);
          }
        }
      }
    } catch (e) {
      print(e.toString());
    }
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
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _loadFromNet();
        }
      }
    }
  }
}
