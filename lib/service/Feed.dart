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
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Survey.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/surveys.dart';
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
      await _buildFeed(currentDateTime);
    }
    else {
      await Future.delayed(Duration(milliseconds: 1500));
    }

    return ListUtils.range(_feed, offset: offset, limit: limit);
  }

  Future<void> _buildFeed(DateTime currentDateTime) async {

    // List<FeedItem>?
    List<List<FeedItem>?> typedFeeds = await Future.wait(<Future<List<FeedItem>?>>[
      _loadEventsFeed(currentDateTime),
      _loadNotificationsFeed(currentDateTime),
      _loadGroupsPostsFeed(currentDateTime),
    ]);

    List<FeedItem>? feed;
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

    _feed = feed;
    _feedDateTime = (feed != null) ? currentDateTime : null;
  }

  // Events

  Future<List<FeedItem>?> _loadEventsFeed(DateTime currentDateTime) async {
    List<Event2>? events = await Events2().loadEventsList(Events2Query(
      timeFilter: Event2TimeFilter.customRange,
      customStartTimeUtc: currentDateTime.subtract(Duration(seconds: Config().feedPastDuration)).toUtc(),
      customEndTimeUtc: currentDateTime.add(Duration(seconds: Config().feedFutureDuration)).toUtc(),
      adjustCustomTime: false,
    ));

    Map<String, FeedEventInfo>? eventInfos = ((events != null) && Auth2().isLoggedIn) ? await _loadEventsInfo(events) : null;
    if ((events != null) && (eventInfos != null)) {
      List<FeedItem> eventsFeed = <FeedItem>[];
      for (Event2 event in events) {
        FeedEventInfo? eventInfo = eventInfos[event.id];
        eventsFeed.add((eventInfo != null) ? FeedItem.fromEventInfo(eventInfo) : FeedItem.fromEvent(event));
      }
      return eventsFeed;
    }

    return FeedItem.listFromData(events, type: FeedItemType.event);
  }

  Future<Map<String, FeedEventInfo>> _loadEventsInfo(List<Event2> events) async {
    Map<String, FeedEventInfo> eventInfos = <String, FeedEventInfo>{};

    List<Future<FeedEventInfo?>> futures = <Future<FeedEventInfo?>>[];
    for (Event2 event in events) {
      if (event.hasSurvey) {
        futures.add(_loadEventInfo(event));
      }
    }

    if (futures.isNotEmpty) {
      List<FeedEventInfo?> responses = await Future.wait(futures);

      for (FeedEventInfo? eventInfo in responses) {
        String? eventId = eventInfo?.event.id;
        if ((eventInfo != null) && (eventId != null)) {
          eventInfos[eventId] = eventInfo;
        }
      }
    }

    return eventInfos;
  }

  Future<FeedEventInfo?> _loadEventInfo(Event2 event) async {
    String? eventId = event.id;
    if (eventId != null) {
      List<dynamic> responseList = await Future.wait([
        Surveys().loadEvent2Survey(eventId),
        Events2().loadEventPeople(eventId),
      ]);
      Survey? survey = responseList[0];
      Event2PersonsResult? persons = responseList[1];
      String? surveyId = survey?.id;
      bool isAttendee = (persons?.attendees?.indexWhere((person) => person.identifier?.accountId == Auth2().accountId) ?? -1) > -1;
      if ((survey != null) && (surveyId != null) && isAttendee) {
        List<SurveyResponse>? surveyResponses = await Surveys().loadUserSurveyResponses(surveyIDs: [surveyId]);
        return FeedEventInfo(survey: survey, event: event, persons: persons, surveyResponses: surveyResponses);
      }
    }
    return null;
  }

  // Notifications

  Future<List<FeedItem>?> _loadNotificationsFeed(DateTime currentDateTime) async =>
    Auth2().isLoggedIn ? FeedItem.listFromData(await Inbox().loadMessages(
      startDate: currentDateTime.subtract(Duration(seconds: Config().feedPastDuration)).toUtc(),
      endDate: currentDateTime.add(Duration(seconds: Config().feedFutureDuration)).toUtc(),
    ), type: FeedItemType.notification) : null;

  // Group Posts

  Future<List<FeedItem>?> _loadGroupsPostsFeed(DateTime currentDateTime) async {
    List<FeedItem>? feed;
    List<Group>? userGroups = Auth2().isLoggedIn ? Groups().userGroups : null;
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
    int offset = 0;
    final int pageSize = 16;
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
            if ((groupPosts.length == pageSize) && ((index + 1) == groupPosts.length)) {
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
