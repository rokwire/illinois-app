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

import 'package:illinois/model/Appointment.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/model/Twitter.dart';
import 'package:illinois/model/wellness/WellnessToDo.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/utils/utils.dart';

// FeedItemType

enum FeedItemType { event, notification, appointment, studentCourse, campusReminder, sportNews, tweet, wellnessToDo, wellnessTip }

// FeedItem

class FeedItem {
  final FeedItemType type;
  final Object data;

  FeedItem({required this.type, required this.data});

  static FeedItem? fromJson(Map<String, dynamic>? json, { List<TweetsPage>? tweets }) {
    if (json != null) {
      FeedItemType? type = feedItemTypeFromString(JsonUtils.stringValue(json['type']));
      if (type != null) {
        Object? data = _dataFromJson(json['data'], type: type);
        if (data != null) {
          return FeedItem(type: type, data: data);
        }
      }
    }
    return null;
  }

  static Object? _dataFromJson(dynamic json, { required FeedItemType type, List<TweetsPage>? tweets }) {
    switch (type) {
      case FeedItemType.event:          return Event2.fromJson(JsonUtils.mapValue(json));
      case FeedItemType.notification:   return InboxMessage.fromJson(JsonUtils.mapValue(json));
      case FeedItemType.appointment:    return Appointment.fromJson(JsonUtils.mapValue(json));
      case FeedItemType.studentCourse:  return StudentCourse.fromJson(JsonUtils.mapValue(json));
      case FeedItemType.campusReminder: return JsonUtils.mapValue(json); // Student Guide Aricle Json
      case FeedItemType.sportNews:      return News.fromJson(JsonUtils.mapValue(json));
      case FeedItemType.tweet:          return TweetsPage.tweetFromList(tweets, id: JsonUtils.stringValue(json));
      case FeedItemType.wellnessToDo:   return WellnessToDoItem.fromJson(JsonUtils.mapValue(json));
      case FeedItemType.wellnessTip:    return JsonUtils.mapValue(json); // Wellness tip text
    }
  }

  static List<FeedItem>? listFromJson(List<dynamic>? jsonList, { List<TweetsPage>? tweets }) {
    List<FeedItem>? result;
    if (jsonList != null) {
      result = <FeedItem>[];
      for (dynamic json in jsonList) {
        ListUtils.add(result, FeedItem.fromJson(json, tweets: tweets));
      }
    }
    return result;
  }

  static List<FeedItem>? listFromResponseJson(Map<String, dynamic>? json) => (json != null) ? FeedItem.listFromJson(JsonUtils.listValue(json['result']),
    tweets: TweetsPage.listFromJson(JsonUtils.listValue(json['tweets']))
  ) : null;
}

// FeedItemType

FeedItemType? feedItemTypeFromString(String? value) {
  switch(value) {
    case 'event': return FeedItemType.event;
    case 'notification': return FeedItemType.notification;
    case 'appointment': return FeedItemType.appointment;
    case 'student_course': return FeedItemType.studentCourse;
    case 'campus_reminder': return FeedItemType.campusReminder;
    case 'sport_news': return FeedItemType.sportNews;
    case 'tweet': return FeedItemType.tweet;
    case 'wellness_todo': return FeedItemType.wellnessToDo;
    case 'wellness_tip': return FeedItemType.wellnessTip;
    default: return null;
  }
}