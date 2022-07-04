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
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/model/wellness/ToDo.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:http/http.dart' as http;

import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Wellness with Service implements NotificationsListener {
  static const String notifyToDoCategoryChanged = "edu.illinois.rokwire.wellness.todo.category.changed";
  static const String notifyToDoCategoryDeleted = "edu.illinois.rokwire.wellness.todo.category.deleted";
  static const String notifyToDoItemCreated = "edu.illinois.rokwire.wellness.todo.item.created";
  static const String notifyToDoItemUpdated = "edu.illinois.rokwire.wellness.todo.item.updated";
  static const String notifyToDoItemsDeleted = "edu.illinois.rokwire.wellness.todo.items.deleted";

  static const String notifyContentChanged = "edu.illinois.rokwire.wellness.content.changed";
  static const String notifyDailyTipChanged = "edu.illinois.rokwire.wellness.daily_tip.changed";

  static const String _contentCacheFileName = "wellness.content.json";
  static const String _tipsContentCategoty = "wellness.tips";
  static const List<String> _contentCategories = [_tipsContentCategoty];

  File? _contentCacheFile;
  Map<String, dynamic>? _contentMap;

  String? _dailyTipId;
  DateTime? _dailyTipTime;

  DateTime? _pausedDateTime;

  // Singleton Factory

  static final Wellness _instance = Wellness._internal();
  Wellness._internal();
  factory Wellness() => _instance;

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  Future<void> initService() async {
    _contentCacheFile = await _getContentCacheFile();
    _contentMap = await _loadContentMapFromCache();
    if (_contentMap != null) {
      _updateContentMapFromNet();
    }
    else {
      _contentMap = await _loadContentMapFromNet();
      if (_contentMap != null) {
        await _saveContentMapToCache(_contentMap);
      }
    }

    _dailyTipId = Storage().wellnessDailyTipId;
    _dailyTipTime = DateTime.fromMillisecondsSinceEpoch(Storage().wellnessDailyTipTime ?? 0);
    _updateDailyTip(notify: false);

    if (_contentMap != null) {
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'Wellness Initialization Failed',
        description: 'Failed to initialize Wellness service.',
      );
    }
  }
  
  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config(), Auth2()]);
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
          _updateContentMapFromNet();
          _updateDailyTip();
        }
      }
    }
  }

  // APIs

  // ToDo List

  Future<List<ToDoCategory>?> loadToDoCategories() async {
    if (!isEnabled) {
      Log.w('Failed to load wellness todo categories. Missing wellness url.');
      return null;
    }
    String url = '${Config().wellnessUrl}/user/todo_categories';
    http.Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<ToDoCategory>? categories = ToDoCategory.listFromJson(JsonUtils.decodeList(responseString));
      return categories;
    } else {
      Log.w('Failed to load wellness todo categories. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<bool> saveToDoCategory(ToDoCategory category) async {
    if (!isEnabled) {
      Log.w('Failed to save wellness todo category. Missing wellness url.');
      return false;
    }
    String? id = category.id;
    bool createNew = StringUtils.isEmpty(id);
    String url = createNew ? '${Config().wellnessUrl}/user/todo_categories' : '${Config().wellnessUrl}/user/todo_categories/${category.id}';
    String? categoryJson = JsonUtils.encode(category);
    http.Response? response;
    if (createNew) {
      response = await Network().post(url, auth: Auth2(), body: categoryJson);
    } else {
      response = await Network().put(url, auth: Auth2(), body: categoryJson);
    }
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Log.i('Wellness todo category saved successfully.');
      NotificationService().notify(notifyToDoCategoryChanged);
      return true;
    } else {
      Log.w('Failed to save wellness todo category. Response:\n$responseCode: $responseString');
      return false;
    }
  }

  Future<bool> deleteToDoCategory(String categoryId) async {
    if (!isEnabled) {
      Log.w('Failed to delete wellness todo category. Missing wellness url.');
      return false;
    }
    String url = '${Config().wellnessUrl}/user/todo_categories/$categoryId';
    http.Response? response = await Network().delete(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Log.i('Wellness todo category deleted successfully.');
      NotificationService().notify(notifyToDoCategoryDeleted);
      return true;
    } else {
      Log.w('Failed to delete wellness todo category. Response:\n$responseCode: $responseString');
      return false;
    }
  }

  Future<bool> createToDoItem(ToDoItem item) async {
    if (!isEnabled) {
      Log.w('Failed to create wellness todo item. Missing wellness url.');
      return false;
    }
    String url = '${Config().wellnessUrl}/user/todo_entries';
    String? itemJson = JsonUtils.encode(item);
    http.Response? response = await Network().post(url, auth: Auth2(), body: itemJson);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Log.i('Wellness todo item created successfully.');
      NotificationService().notify(notifyToDoItemCreated);
      return true;
    } else {
      Log.w('Failed to create wellness todo item. Response:\n$responseCode: $responseString');
      return false;
    }
  }

  Future<bool> updateToDoItem(ToDoItem item) async {
    if (!isEnabled) {
      Log.w('Failed to update wellness todo item. Missing wellness url.');
      return false;
    }
    String url = '${Config().wellnessUrl}/user/todo_entries/${item.id}';
    String? itemJson = JsonUtils.encode(item);
    http.Response? response = await Network().put(url, auth: Auth2(), body: itemJson);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Log.i('Wellness todo item updated successfully.');
      NotificationService().notify(notifyToDoItemCreated);
      return true;
    } else {
      Log.w('Failed to update wellness todo item. Response:\n$responseCode: $responseString');
      return false;
    }
  }

  Future<bool> deleteToDoItem(String itemId) async {
    if (!isEnabled) {
      Log.w('Failed to delete wellness todo item. Missing wellness url.');
      return false;
    }
    String url = '${Config().wellnessUrl}/user/todo_entries/$itemId';
    http.Response? response = await Network().delete(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Log.i('Wellness todo item deleted successfully.');
      NotificationService().notify(notifyToDoItemCreated);
      return true;
    } else {
      Log.w('Failed to delete wellness todo item. Response:\n$responseCode: $responseString');
      return false;
    }
  }

    Future<bool> deleteToDoItems(List<String>? idList) async {
    if (CollectionUtils.isEmpty(idList)) {
      return false;
    }
    String? body = JsonUtils.encode(idList!);
    String url = '${Config().wellnessUrl}/user/todo_entries/clear_completed_entries';
    http.Response? response = await Network().delete(url, auth: Auth2(), body: body);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Log.i('Wellness todo items deleted successfully.');
      NotificationService().notify(notifyToDoItemCreated);
      return true;
    } else {
      Log.w('Failed to delete wellness todo items. Response:\n$responseCode: $responseString');
      return false;
    }
  }

  Future<List<ToDoItem>?> loadToDoItems() async {
    if (!isEnabled) {
      Log.w('Failed to load wellness todo items. Missing wellness url.');
      return null;
    }
    String url = '${Config().wellnessUrl}/user/todo_entries';
    http.Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<ToDoItem>? items = ToDoItem.listFromJson(JsonUtils.decodeList(responseString));
      return items;
    } else {
      Log.w('Failed to load wellness todo items. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Tips

  String? get dailyTip => _tipString(tipId: _dailyTipId);

  void refreshDailyTip() => _updateDailyTip(force: true);

  String? get _randomTipId {
    Map<String, dynamic>? tipsContent = (_contentMap != null) ? _contentMap![_tipsContentCategoty] : null;
    List<dynamic>? entries = (tipsContent != null) ? JsonUtils.listValue(tipsContent['entries']) : null;
    if ((entries != null) && (0 < entries.length)) {
      int entryIndex = Random().nextInt(entries.length);
      Map<String, dynamic>? entry = JsonUtils.mapValue(entries[entryIndex]);
      return (entry != null) ? JsonUtils.stringValue(entry['id']) : null;
    }
    return null;
  }

  String? _tipString({String? tipId}) {
    Map<String, dynamic>? tipsContent = (_contentMap != null) ? _contentMap![_tipsContentCategoty] : null;
    Map<String, dynamic>? strings = (tipsContent != null) ? JsonUtils.mapValue(tipsContent['strings']) : null;
    return _getContentString(strings, tipId);
  }

  bool _hasTip({String? tipId}) {
    Map<String, dynamic>? tipsContent = (_contentMap != null) ? _contentMap![_tipsContentCategoty] : null;
    List<dynamic>? entries = (tipsContent != null) ? JsonUtils.listValue(tipsContent['entries']) : null;
    if ((entries != null) && (0 < entries.length)) {
      for (dynamic entry in entries) {
        Map<String, dynamic>? entryTip = JsonUtils.mapValue(entry);
        String? entryTipId = (entryTip != null) ? JsonUtils.stringValue(entryTip['id']) : null;
        if (entryTipId == tipId) {
          return true;
        }
      }
    }
    return false;
  }

  static String? _getContentString(Map<String, dynamic>? strings,  String? key, {String? languageCode}) {
    if ((strings != null) && (key != null)) {
      Map<String, dynamic>? mapping =
        JsonUtils.mapValue(strings[languageCode]) ??
        JsonUtils.mapValue(strings[Localization().currentLocale?.languageCode]) ??
        JsonUtils.mapValue(strings[Localization().defaultLocale?.languageCode]);
      if (mapping != null) {
        return JsonUtils.stringValue(mapping[key]);
      }
    }
    return null;
  }


  bool get _needsDailyTipUpdate =>
    ((_dailyTipId == null) || (_dailyTipTime == null)|| !_hasTip(tipId: _dailyTipId)  || (DateTimeUtils.midnight(_dailyTipTime)!.compareTo(DateTimeUtils.midnight(DateTime.now())!) < 0));

  void _updateDailyTip({bool notify = true, bool force = false}) {
    if (force || _needsDailyTipUpdate) {
      String? tipId = _randomTipId;
      if (tipId != null) {
        Storage().wellnessDailyTipId = _dailyTipId = tipId;
        Storage().wellnessDailyTipTime = (_dailyTipTime = DateTime.now()).millisecondsSinceEpoch;
        if (notify) {
          NotificationService().notify(notifyDailyTipChanged);
        }
      }
    }
  }

  // Getters

  bool get isEnabled => StringUtils.isNotEmpty(Config().wellnessUrl);

  // Content

  Future<File> _getContentCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _contentCacheFileName);
    return File(cacheFilePath);
  }

  Future<String?> _loadContentMapStringFromCache() async {
    return (await _contentCacheFile?.exists() == true) ? await _contentCacheFile?.readAsString() : null;
  }

  Future<void> _saveContentMapStringToCache(String? value) async {
    try {
      if (value != null) {
        await _contentCacheFile?.writeAsString(value, flush: true);
      }
      else {
        await _contentCacheFile?.delete();
      }
    }
    catch(e) { print(e.toString()); }
  }

  Future<Map<String, dynamic>?> _loadContentMapFromCache() async {
    return JsonUtils.decodeMap(await _loadContentMapStringFromCache());
  }

  Future<void> _saveContentMapToCache(Map<String, dynamic>? value) async {
    await _saveContentMapStringToCache(JsonUtils.encode(value));
  }

  Future<Map<String, dynamic>?> _loadContentMapFromNet() async {
    //return { '$_tipsContentCategoty': JsonUtils.mapValue(Assets()['wellness.tips']) } ;
    Map<String, dynamic>? result;
    if (Config().contentUrl != null) {
      Response? response = await Network().get("${Config().contentUrl}/content_items", body: JsonUtils.encode({'categories': _contentCategories}), auth: Auth2());
      List<dynamic>? responseList = (response?.statusCode == 200) ? JsonUtils.decodeList(response?.body)  : null;
      if (responseList != null) {
        result = <String, dynamic>{};
        for (dynamic responseEntry in responseList) {
          Map<String, dynamic>? contentItem = JsonUtils.mapValue(responseEntry);
          if (contentItem != null) {
            String? category = JsonUtils.stringValue(contentItem['category']);
            dynamic data = contentItem['data'];
            if ((category != null) && (data != null)) {
              result[category] ??= data;
            }
          }
        }
      }
    }
    return result;
  }

  Future<void> _updateContentMapFromNet() async {
    Map<String, dynamic>? contentMap = await _loadContentMapFromNet();
    if ((contentMap != null) && !DeepCollectionEquality().equals(_contentMap, contentMap)) {
      _contentMap = contentMap;
      await _saveContentMapToCache(contentMap);
      NotificationService().notify(notifyContentChanged);
      _updateDailyTip();
    }
  }
}
