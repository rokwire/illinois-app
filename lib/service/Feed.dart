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

import 'package:flutter/material.dart';
import 'package:illinois/model/Feed.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rokwire_plugin/utils/utils.dart';

class Feed {

  // Singletone Factory

  Feed._internal();
  factory Feed() => _instance;
  static final Feed _instance = Feed._internal();

  // Service

  Future<List<FeedItem>?> loadFeed({int? offset, int? limit}) async {
    List<FeedItem>? items;
    try { items = FeedItem.listFromResponseJson(JsonUtils.decodeMap(await rootBundle.loadString('assets/extra/feed.json'))); }
    catch(e) { debugPrint(e.toString()); }
    return (offset != null) ? items?.sublist(offset, limit) : items;
  }
}

