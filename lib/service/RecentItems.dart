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

import 'dart:collection';
import 'dart:io';
import 'package:illinois/service/Config.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Storage.dart';

import 'package:illinois/model/RecentItem.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class RecentItems with Service implements NotificationsListener {
  
  static const String notifyChanged  = "edu.illinois.rokwire.recentitems.changed";

  static const String _cacheFileName = "recentItems.json";

  static final RecentItems _logic = new RecentItems._internal();
  factory RecentItems() {
    return _logic;
  }
  RecentItems._internal();

  Queue<RecentItem> _recentItems = Queue<RecentItem>();

  Queue<RecentItem> get recentItems => _recentItems;

  @override
  void createService() {
    NotificationService().subscribe(this, Auth2.notifyUserDeleted);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _recentItems = await _loadRecentItems() ?? Queue<RecentItem>();
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage()]);
  }

  void addRecentItem(RecentItem? item) {

    if ((item != null) && !_recentItems.contains(item)) {
      _recentItems.addFirst(item);
      
      while (_recentItems.length > Config().recentItemsCount) {
        _recentItems.removeLast();
      }
      _saveRecentItems(_recentItems);
      NotificationService().notify(notifyChanged, null);
    }
  }

  void _clearRecentItems() {
    if (_recentItems.isNotEmpty) {
      _recentItems.clear();
      _saveRecentItems(_recentItems);
      NotificationService().notify(notifyChanged, null);
    }
  }

  static Future<File> get _recentItemsFile async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _cacheFileName);
    return File(cacheFilePath);
  }

  static Future<Queue<RecentItem>?> _loadRecentItems() async {
    File cacheFile = await _recentItemsFile;
    if (await cacheFile.exists()) {
      String jsonString = await cacheFile.readAsString();
      return RecentItem.queueFromJson(JsonUtils.decodeList(jsonString));
    }
    // backward compatability
    return RecentItem.queueFromJson(Storage().recentItems);
  }

  static Future<void> _saveRecentItems(Queue<RecentItem>? recentItems) async {
    File cacheFile = await _recentItemsFile;
    String? jsonString = JsonUtils.encode(RecentItem.queueToJson(recentItems));
    await cacheFile.writeAsString(jsonString ?? '', flush: true);

  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyUserDeleted) {
      _clearRecentItems();
    }
  }
}
