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
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';

extension PostExt on Post {

  PostType get type =>
      (authorizationContext?.items?.firstWhereOrNull((item) => item.members?.type == ContextItemMembersType.listed_accounts) != null)
          ? PostType.direct_message
          : PostType.post;
  bool get isPost => (type == PostType.post);
  bool get isMessage => (type == PostType.direct_message);
  bool get isScheduled => (status == PostStatus.draft);

  String? get displayDateTime {
    DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateCreatedUtc);
    if (deviceDateTime != null) {
      DateTime now = DateTime.now();
      if (deviceDateTime.compareTo(now) <= 0) {
        Duration difference = now.difference(deviceDateTime);
        if (difference.inSeconds < 60) {
          return Localization().getStringEx('generic.time.now', 'now');
        }
        else if (difference.inMinutes < 60) {
          return "${difference.inMinutes} ${Localization().getStringEx("generic.time.minutes", "minutes")}";
        }
        else if (difference.inHours < 24) {
          return "${difference.inHours} ${Localization().getStringEx("generic.time.hours", "hours")}";
        }
        else if (difference.inDays < 30) {
          return "${difference.inDays} ${Localization().getStringEx("generic.time.days", "days")}";
        }
        else {
          int differenceInMonths = difference.inDays ~/ 30;
          if (differenceInMonths < 12) {
            return "$differenceInMonths ${Localization().getStringEx("generic.time.months", "months")}";
          }
        }
      }
      return DateFormat("MMM dd, yyyy").format(deviceDateTime);
    }
    return null;
  }

  String? get displayScheduledTime {
    DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateActivatedUtc);
    if(deviceDateTime != null){
      return DateFormat("MMM dd, HH:mm").format(deviceDateTime);
    }
    return null;
  }

  DateTime? get dateActivatedLocal => dateActivatedUtc?.toLocalTZ();

  String? get creatorName => creator?.name;
  String? get creatorId => creator?.accountId;
}