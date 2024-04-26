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
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Feed {

  // Singletone Factory

  Feed._internal();
  factory Feed() => _instance;
  static final Feed _instance = Feed._internal();

  // Data

  List<FeedItem>? _feed;
  DateTime? _feedDateTime;


  // Service

  Future<List<FeedItem>?> load(DateTime currentDateTime, {int offset = 0, int? limit}) async {
    if ((_feed == null) || (currentDateTime != _feedDateTime)) {
      _feed = await _buildFeed(currentDateTime);
      _feedDateTime = (_feed != null) ? currentDateTime : null;
    }
    else {
      await Future.delayed(Duration(milliseconds: 1500));
    }
    return ListUtils.range(_feed, offset: offset, limit: limit);
  }

  Future<List<FeedItem>?> _buildFeed(DateTime currentDateTime) async {
    List<FeedItem>? feed;

    List<List<FeedItem>?> typedFeeds = await Future.wait(<Future<List<FeedItem>?>>[
      _loadEventsFeed(currentDateTime),
      _loadNotificationsFeed(currentDateTime),
      _loadGroupsPostsFeed(currentDateTime),
    ]);

    for (List<FeedItem>? typedFeed in typedFeeds) {
      if (typedFeed != null) {
        (feed ??= <FeedItem>[]).addAll(typedFeed);
      }
    }

    DateTime rangeCurrentTimeUtc = currentDateTime.toUtc();
    DateTime rangeStartTimeUtc = currentDateTime.subtract(Duration(seconds: Config().feedPastDuration)).toUtc();
    DateTime rangeEndTimeUtc = currentDateTime.add(Duration(seconds: Config().feedFutureDuration)).toUtc();
    feed?.sort((feedItem1, feedItem2) => SortUtils.compare(
      feedItem2.dateTimeUtc(rangeStartTimeUtc: rangeStartTimeUtc, rangeEndTimeUtc: rangeEndTimeUtc, rangeCurrentTimeUtc: rangeCurrentTimeUtc),
      feedItem1.dateTimeUtc(rangeStartTimeUtc: rangeStartTimeUtc, rangeEndTimeUtc: rangeEndTimeUtc, rangeCurrentTimeUtc: rangeCurrentTimeUtc),
    ));

    return feed;
  }

  // Events

  Future<List<FeedItem>?> _loadEventsFeed(DateTime currentDateTime) async =>
    FeedItem.listFromData(await Events2().loadEventsList(Events2Query(
      timeFilter: Event2TimeFilter.customRange,
      customStartTimeUtc: currentDateTime.subtract(Duration(seconds: Config().feedPastDuration)).toUtc(),
      customEndTimeUtc: currentDateTime.add(Duration(seconds: Config().feedFutureDuration)).toUtc(),
    )), type: FeedItemType.event);

  // Notifications

  Future<List<FeedItem>?> _loadNotificationsFeed(DateTime currentDateTime) async =>
    FeedItem.listFromData(await Inbox().loadMessages(
      startDate: currentDateTime.subtract(Duration(seconds: Config().feedPastDuration)).toUtc(),
      endDate: currentDateTime.add(Duration(seconds: Config().feedFutureDuration)).toUtc(),
    ), type: FeedItemType.notification);

  // Group Posts

  Future<List<FeedItem>?> _loadGroupsPostsFeed(DateTime currentDateTime) async {
    List<FeedItem>? feed;
    List<Group>? userGroups = Groups().userGroups;
    if (userGroups != null) {
      List<Future<List<FeedItem>?>> futures = <Future<List<FeedItem>?>>[];
      for (Group group in userGroups) {
        futures.add(_loadGroupPostsFeed(currentDateTime, group));
      }

      List<List<FeedItem>?> results = await Future.wait(futures);

      for (List<FeedItem>? groupPosts in results) {
        if (groupPosts != null) {
          (feed ??= <FeedItem>[]).addAll(groupPosts);
        }
      }
    }
    return feed;
  }

  Future<List<FeedItem>?> _loadGroupPostsFeed(DateTime currentDateTime, Group group) async {
    int offset = 0, pageSize = 16;
    DateTime startDateTimeUtc = currentDateTime.subtract(Duration(seconds: Config().feedPastDuration)).toUtc();
    DateTime endDateTimeUtc = currentDateTime.add(Duration(seconds: Config().feedFutureDuration)).toUtc();
    List<FeedItem>? feed;
    do {
      List<GroupPost>? groupPosts = await Groups().loadGroupPosts(group.id, offset: offset, limit: pageSize, order: GroupSortOrder.desc);
      if (groupPosts != null) {
        feed ??= <FeedItem>[];
        for (int index = 0; index < groupPosts.length; index++) {
          GroupPost groupPost = groupPosts[index];
          DateTime? groupPostDateTimeUtc = groupPost.dateCreatedUtc;
          if ((groupPostDateTimeUtc != null) && groupPostDateTimeUtc.isAfter(startDateTimeUtc) && groupPostDateTimeUtc.isBefore(endDateTimeUtc)) {
            feed.add(FeedItem.fromGroupPost(groupPost, group: group));
            if ((index + 1) == groupPosts.length) {
              offset += pageSize;
              continue;
            }
          }
        }
      }
    }
    while(false);
    return feed;
  }

  // Sample

  Future<List<FeedItem>?> loadSample({int offset = 0, int? limit}) async {
    await Future.delayed(Duration(milliseconds: 1500));
    try { return ListUtils.range(FeedItem.listFromResponseJson(JsonUtils.decodeMap(await rootBundle.loadString('assets/extra/feed2.json'))), offset: offset, limit: limit); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }
}

