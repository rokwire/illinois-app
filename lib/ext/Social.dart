/*
 * Copyright 2024 Board of Trustees of the University of Illinois.
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

import 'package:collection/collection.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension PostExt on Post {
  PostType get type =>
      (authorizationContext?.items?.firstWhereOrNull((item) => item.members?.type == ContextItemMembersType.listed_accounts) != null)
          ? PostType.direct_message
          : PostType.post;

  bool get isPost => (type == PostType.post);
  bool get isMessage => (type == PostType.direct_message);
  bool get isScheduled => (status == PostStatus.draft);

  int get commentsCount => (details?.commentsCount ?? 0);

  String? get displayDateTime {
    DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateCreatedUtc);
    return (deviceDateTime != null) ? AppDateTimeUtils.timeAgoSinceDate(deviceDateTime) : null;
  }

  String? get displayScheduledTime {
    DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateActivatedUtc);
    if (deviceDateTime != null) {
      return DateFormat("MMM dd, HH:mm").format(deviceDateTime);
    }
    return null;
  }

  DateTime? get dateActivatedLocal => dateActivatedUtc?.toLocalTZ();

  String? get creatorName => creator?.name;
  String? get creatorId => creator?.accountId;
  bool get createdByUser => creatorId == Auth2().accountId;
}

extension CommentExt on Comment {
  String? get displayDateTime {
    DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateCreatedUtc);
    return (deviceDateTime != null) ? AppDateTimeUtils.timeAgoSinceDate(deviceDateTime) : null;
  }

  String? get creatorName => creator?.name;
  String? get creatorId => creator?.accountId;
}

extension ReactionExt on Reaction {
  String? get engagerName => engager?.name;
  String? get engagerId => engager?.accountId;
  bool get isCurrentUserReacted => (Auth2().accountId == engagerId);
  String? get emoji => data?["emoji_source"];
  String? get emojiName => data?["emoji_name"];

  /// Returns Key: Emoji.emoji and Value: List of all Reactions with this emoji
  static   Map<String, List<Reaction>>?  extractSameEmojiReactions(List<Reaction>? reactions){
    return reactions?.fold(<String, List<Reaction>>{}, (map, element) {
      if(element.type == ReactionType.emoji &&  element.data != null){
        List<Reaction>? collection = map?[element.emoji];
        if(collection == null){
          map?[element.emoji!] = collection = <Reaction>[];
        }
        collection?.add(element);
      }
      return map;
    });
  }

  static  List<Reaction>? extractUsersReactions(Iterable<Reaction>? reactions, {String? emoji}) =>
      reactions?.where((Reaction reaction) =>
          (emoji == null || reaction.emoji == emoji) &&
          reaction.isCurrentUserReacted
      ).toList();
}

extension MessageExt on Message {
  DateTime? get dateSentLocal =>  AppDateTime().getDeviceTimeFromUtcTime(dateSentUtc);
  String? get dateSentLocalString => DateTimeUtils.localDateTimeToString(dateSentLocal, format: 'MMMM dd, yyyy');
}

extension ConversationExt on Conversation {
  String? get displayDateTime {
    DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(lastActivityTimeUtc);
    if (deviceDateTime != null) {
      DateTime now = DateTime.now();
      if (deviceDateTime.compareTo(now) < 0) {
        Duration difference = DateTime.now().difference(deviceDateTime);
        if (difference.inSeconds < 60) {
          return Localization().getStringEx("generic.time.now", "now");
        }
        else if (difference.inMinutes < 60) {
          return "${difference.inMinutes} ${difference.inMinutes > 1 ? Localization().getStringEx("generic.time.minutes", "minutes") : Localization().getStringEx("generic.time.minute", "minute")}";
        }
        else if (difference.inHours < 24) {
          return "${difference.inHours} ${difference.inHours > 1 ? Localization().getStringEx("generic.time.hours", "hours") : Localization().getStringEx("generic.time.hour", "hour")}";
        }
        else if (difference.inDays < 30) {
          return "${difference.inDays} ${difference.inDays > 1 ? Localization().getStringEx("generic.time.days", "days") : Localization().getStringEx("generic.time.day", "day")}";
        }
        else {
          int differenceInMonths = difference.inDays ~/ 30;
          if (differenceInMonths < 12) {
            return "$differenceInMonths ${differenceInMonths > 1 ? Localization().getStringEx("generic.time.months", "months") : Localization().getStringEx("generic.time.month", "month")}";
          }
        }
      }
      return DateFormat("MMM dd, yyyy").format(deviceDateTime);
    }
    return null;
  }
}

extension CreatorExt on Creator{
  Member? findAsMember({List<Member>? groupMembers}){
    Iterable<Member>? creators = groupMembers?.where((Member member) =>
      member.userId == accountId
    );
    return CollectionUtils.isNotEmpty(creators) ? creators!.first : null;
  }
}