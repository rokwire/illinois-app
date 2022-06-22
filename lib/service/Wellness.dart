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
import 'package:illinois/model/wellness/ToDo.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:http/http.dart' as http;

import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Wellness with Service {
  static const String notifyToDoCategoryCreated = "edu.illinois.rokwire.wellness.todo.category.created";
  static const String notifyToDoCategoryUpdated = "edu.illinois.rokwire.wellness.todo.category.updated";
  static const String notifyToDoCategoryDeleted = "edu.illinois.rokwire.wellness.todo.category.deleted";
  static const String notifyToDoItemCreated = "edu.illinois.rokwire.wellness.todo.item.created";

  // Singleton Factory

  static final Wellness _instance = Wellness._internal();
  Wellness._internal();
  factory Wellness() => _instance;

  // Service

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config()]);
  }

  // APIs

  // ToDo List

  Future<List<ToDoCategory>?> loadToDoCategories() async {
    if (isEnabled) {
      Log.w('Failed to load wellness todo categories. Missing wellness url.');
      return null;
    }
    String url = '${Config().wellnessUrl}/todo/categories';
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

  Future<bool> createToDoCategory(ToDoCategory category) async {
    if (isEnabled) {
      Log.w('Failed to create wellness todo category. Missing wellness url.');
      return false;
    }
    String url = '${Config().wellnessUrl}/todo/categories';
    String? categoryJson = JsonUtils.encode(category);
    http.Response? response = await Network().post(url, auth: Auth2(), body: categoryJson);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Log.i('Wellness todo category created successfully.');
      NotificationService().notify(notifyToDoCategoryCreated);
      return true;
    } else {
      Log.w('Failed to create wellness todo category. Response:\n$responseCode: $responseString');
      return false;
    }
  }

  Future<bool> updateToDoCategory(ToDoCategory category) async {
    if (isEnabled) {
      Log.w('Failed to update wellness todo category. Missing wellness url.');
      return false;
    }
    String url = '${Config().wellnessUrl}/todo/categories/${category.id}';
    String? categoryJson = JsonUtils.encode(category);
    http.Response? response = await Network().put(url, auth: Auth2(), body: categoryJson);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Log.i('Wellness todo category updated successfully.');
      NotificationService().notify(notifyToDoCategoryUpdated);
      return true;
    } else {
      Log.w('Failed to update wellness todo category. Response:\n$responseCode: $responseString');
      return false;
    }
  }

  Future<bool> deleteToDoCategory(String categoryId) async {
    if (isEnabled) {
      Log.w('Failed to delete wellness todo category. Missing wellness url.');
      return false;
    }
    String url = '${Config().wellnessUrl}/todo/categories/$categoryId';
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
    if (isEnabled) {
      Log.w('Failed to create wellness todo item. Missing wellness url.');
      return false;
    }
    String url = '${Config().wellnessUrl}/todo/items';
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

  Future<List<ToDoItem>?> loadToDoItems() async {
    if (isEnabled) {
      Log.w('Failed to load wellness todo items. Missing wellness url.');
      return null;
    }
    String url = '${Config().wellnessUrl}/todo/items';
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

  // Getters

  bool get isEnabled => StringUtils.isNotEmpty(Config().wellnessUrl);
}
