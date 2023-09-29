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
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/model/wellness/ToDo.dart';
import 'package:illinois/model/wellness/WellnessBuilding.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:http/http.dart' as http;

import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Wellness with Service implements NotificationsListener, ContentItemCategoryClient {
  static const String notifyToDoCategoryChanged = "edu.illinois.rokwire.wellness.todo.category.changed";
  static const String notifyToDoCategoryDeleted = "edu.illinois.rokwire.wellness.todo.category.deleted";
  static const String notifyToDoItemCreated = "edu.illinois.rokwire.wellness.todo.item.created";
  static const String notifyToDoItemUpdated = "edu.illinois.rokwire.wellness.todo.item.updated";
  static const String notifyToDoItemsDeleted = "edu.illinois.rokwire.wellness.todo.items.deleted";

  static const String notifyResourcesContentChanged = "edu.illinois.rokwire.wellness.content.resources.changed";
  static const String notifyTipsContentChanged = "edu.illinois.rokwire.wellness.content.tops.changed";
  static const String notifyDailyTipChanged = "edu.illinois.rokwire.wellness.daily_tip.changed";

  static final String _userAccessedToDoListSetting = 'edu.illinois.rokwire.settings.wellness.todo.list.accessed';
  static final String _userAccessedRingsSetting = 'edu.illinois.rokwire.settings.wellness.rings.accessed';

  static const String _tipsContentCategory = "wellness_tips";
  static const String _resourcesContentCategory = "wellness_resources";

  Map<String, dynamic>? _tipsContent;
  Map<String, dynamic>? _resourcesContent;

  String? _dailyTipId;
  DateTime? _dailyTipTime;

  // Singleton Factory

  static final Wellness _instance = Wellness._internal();
  Wellness._internal();
  factory Wellness() => _instance;

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Content.notifyContentItemsChanged,
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  Future<void> initService() async {

    _tipsContent = Content().contentItem(_tipsContentCategory);
    _resourcesContent = Content().contentItem(_resourcesContentCategory);
    
    _dailyTipId = Storage().wellnessDailyTipId;
    _dailyTipTime = DateTime.fromMillisecondsSinceEpoch(Storage().wellnessDailyTipTime ?? 0);
    _updateDailyTip(notify: false);

    if ((_tipsContent != null) && (_resourcesContent != null)) {
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
    return Set.from([Storage(), Content()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Content.notifyContentItemsChanged) {
      _onContentItemsChanged(param);
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onContentItemsChanged(Set<String>? categoriesDiff) {
    if (categoriesDiff?.contains(_tipsContentCategory) == true) {
      _tipsContent = Content().contentItem(_tipsContentCategory);
      NotificationService().notify(notifyTipsContentChanged);
      _updateDailyTip();
    }
    if (categoriesDiff?.contains(_resourcesContentCategory) == true) {
      _resourcesContent = Content().contentItem(_resourcesContentCategory);
      NotificationService().notify(notifyResourcesContentChanged);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.resumed) {
      _updateDailyTip();
    }
  }

  // ContentItemCategoryClient

  @override
  List<String> get contentItemCategory => <String>[_tipsContentCategory, _resourcesContentCategory];

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

  Future<ToDoItem?> loadToDoItem(String? itemId) async {
    if (StringUtils.isEmpty(itemId)) {
      Log.w('Failed to load wellness todo item. Missing id.');
      return null;
    }
    if (!isEnabled) {
      Log.w('Failed to load wellness todo item. Missing wellness url.');
      return null;
    }
    String url = '${Config().wellnessUrl}/user/todo_entries/$itemId';
    http.Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      ToDoItem? item = ToDoItem.fromJson(JsonUtils.decodeMap(responseString));
      return item;
    } else {
      Log.w('Failed to load wellness todo item. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  // Tips

  String? get dailyTip => _tipString(tipId: _dailyTipId);

  void refreshDailyTip() => _updateDailyTip(force: true);

  //Map<String, dynamic>? tipsContent = (_contentMap != null) ? JsonUtils.mapValue(_contentMap![_tipsContentCategory]) : null

  String? get _randomTipId {
    List<dynamic>? entries = (_tipsContent != null) ? JsonUtils.listValue(_tipsContent!['entries']) : null;
    if ((entries != null) && (0 < entries.length)) {
      int entryIndex = Random().nextInt(entries.length);
      Map<String, dynamic>? entry = JsonUtils.mapValue(entries[entryIndex]);
      return (entry != null) ? JsonUtils.stringValue(entry['id']) : null;
    }
    return null;
  }

  String? _tipString({String? tipId}) {
    Map<String, dynamic>? strings = (_tipsContent != null) ? JsonUtils.mapValue(_tipsContent!['strings']) : null;
    return Localization().getContentString(strings, tipId);
  }

  bool _hasTip({String? tipId}) {
    List<dynamic>? entries = (_tipsContent != null) ? JsonUtils.listValue(_tipsContent!['entries']) : null;
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

  // Resources

  Map<String, dynamic>? get resources => _resourcesContent;

  Map<String, dynamic>? getResource({ String? resourceId }) {
    List<dynamic>? commands = (_resourcesContent != null) ? JsonUtils.listValue(_resourcesContent!['commands']) : null;
    if (commands != null) {
      for (dynamic entry in commands) {
        Map<String, dynamic>? command = JsonUtils.mapValue(entry);
        if (command != null) {
          String? id = JsonUtils.stringValue(command['id']);
          if (id == resourceId) {
            return command;
          }
        }
      }
    }
    return null;
  }

  String? getResourceUrl({ String? resourceId }) {
    Map<String, dynamic>? resource = getResource(resourceId: resourceId);
    return (resource != null) ? JsonUtils.stringValue(resource['url']) : null;
  }

  // Mental Health

  Future<List<WellnessBuilding>?> loadMentalHealthBuildings() async {
    List<WellnessBuilding>? result;
    List<Building>? buildings = await Gateway().loadBuildings();
    List<dynamic>? guideEntries = Guide().contentList;
    if ((buildings != null) && (guideEntries != null)) {
      result = <WellnessBuilding>[];
      for(Map<String, dynamic> guideEntry in guideEntries) {
        if (Guide().isEntryMentalHeatlh(guideEntry)) {
          Building? building = Building.findInList(buildings, id: JsonUtils.stringValue(Guide().entryValue(guideEntry, 'map_building_id')));
          if (building != null) {
            result.add(WellnessBuilding(building: building, guideEntry: guideEntry));
          }
        }
      }
    }
    return result;
  }

  // Common User Settings

  bool? get isToDoListAccessed {
    return _getUserBoolSetting(_userAccessedToDoListSetting);
  }

  void toDoListAccessed(bool accessed) {
    _applyUserSetting(settingName: _userAccessedToDoListSetting, settingValue: accessed);
  }

  bool? get isRingsAccessed {
    return _getUserBoolSetting(_userAccessedRingsSetting);
  }

  void ringsAccessed(bool accessed) {
    _applyUserSetting(settingName: _userAccessedRingsSetting, settingValue: accessed);
  }

  bool? _getUserBoolSetting(String settingName) {
    return Auth2().prefs?.getBoolSetting(settingName);
  }

  void _applyUserSetting({required String settingName, dynamic settingValue}) {
    Auth2().prefs?.applySetting(settingName, settingValue);
  }

  // Getters

  bool get isEnabled => StringUtils.isNotEmpty(Config().wellnessUrl);
}
