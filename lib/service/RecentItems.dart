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
import 'package:flutter/foundation.dart';
import 'package:illinois/service/Config.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Storage.dart';

import 'package:illinois/model/RecentItem.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:universal_io/io.dart';

class RecentItems with Service, NotificationsListener {
  
  static const String notifyChanged  = "edu.illinois.rokwire.recentitems.changed";
  static const String notifySettingChanged  = "edu.illinois.rokwire.recentitems.setting.changed";

  static const String _cacheFileName = "recentItems.json";

  static final RecentItems _logic = new RecentItems._internal();
  factory RecentItems() {
    return _logic;
  }
  RecentItems._internal();

  late bool _recentItemsEnabled;
  Queue<RecentItem> _recentItems = Queue<RecentItem>();

  Queue<RecentItem> get recentItems => _recentItemsEnabled ? _recentItems : Queue<RecentItem>();

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Auth2.notifyUserDeleted,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _recentItemsEnabled = (Storage().recentItemsEnabled != false);
    _recentItems = await _loadRecentItems() ?? Queue<RecentItem>();
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyUserDeleted) {
      clearRecentItems();
    }
  }

  // Implementation

  void addRecentItem(RecentItem? item) {
    if ((_recentItemsEnabled) && (item != null)) {
      _recentItems.removeWhere((recentItem) => recentItem.contentId == item.contentId);

      _recentItems.addFirst(item);

      while (_recentItems.length > Config().recentItemsCount) {
        _recentItems.removeLast();
      }
      _saveRecentItems(_recentItems);
      NotificationService().notify(notifyChanged, null);
    }
  }

  void clearRecentItems({bool notify = true}) {
    if (_recentItems.isNotEmpty) {
      _recentItems.clear();
      _saveRecentItems(_recentItems);
      if (notify) {
        NotificationService().notify(notifyChanged, null);
      }
    }
  }

  bool get recentItemsEnabled => _recentItemsEnabled;

  set recentItemsEnabled(bool value) {
    if (_recentItemsEnabled != value) {
      Storage().recentItemsEnabled = _recentItemsEnabled = value;

      if (!_recentItemsEnabled) {
        clearRecentItems();
      }

      NotificationService().notify(notifySettingChanged, null);
    }
  }

  static Future<File?> get _recentItemsFile async {
    Directory? appDocDir = kIsWeb ? null : await getApplicationDocumentsDirectory();
    String? cacheFilePath = (appDocDir != null) ? join(appDocDir.path, _cacheFileName) : null;
    return (cacheFilePath != null) ? File(cacheFilePath) : null;
  }

  static Future<String?> _loadRecentItemsSource() async {
    File? cacheFile = await _recentItemsFile;
    if (await cacheFile?.exists() == true) {
      String jsonString = await cacheFile!.readAsString();
      return jsonString;
    }
    else {
      // backward compatability
      return Storage().recentItemsSource;
    }
  }

  static Future<Queue<RecentItem>?> _loadRecentItems() async {
    return RecentItem.queueFromJson(JsonUtils.decodeList(await _loadRecentItemsSource()));
  }

  static Future<void> _saveRecentItems(Queue<RecentItem>? recentItems) async {
    File? cacheFile = await _recentItemsFile;
    String? jsonString = JsonUtils.encode(RecentItem.queueToJson(recentItems));
    await cacheFile?.writeAsString(jsonString ?? '', flush: true);

  }
}
