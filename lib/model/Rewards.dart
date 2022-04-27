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

import 'package:illinois/service/AppDateTime.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class RewardHistoryEntry {
  final String? id;
  final int? amount;
  final String? description;
  final String? displayName;
  final String? type;
  final String? userId;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;

  RewardHistoryEntry({this.id, this.amount, this.description, this.displayName, this.type, this.userId, this.dateCreated, 
    this.dateUpdated});

  static RewardHistoryEntry? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return RewardHistoryEntry(
        id: JsonUtils.stringValue(json['id']),
        amount: JsonUtils.intValue(json['amount']),
        description: JsonUtils.stringValue(json['description']),
        displayName: JsonUtils.stringValue(json['display_name']),
        type: JsonUtils.stringValue(json['reward_type']),
        userId: JsonUtils.stringValue(json['user_id']),
        dateCreated: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_created']), isUtc: true),
        dateUpdated: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_updated']), isUtc: true));
  }

  DateTime? get dateCreatedLocal {
    return AppDateTime().getDeviceTimeFromUtcTime(dateCreated);
  }

  String? get displayDate {
    return AppDateTime().formatDateTime(dateCreatedLocal, format: 'MM-dd-yy h:mm a');
  }

  String? get displayDescription {
    return StringUtils.isNotEmpty(description) ? description : displayName;
  }

  static List<RewardHistoryEntry>? listFromJson(List<dynamic>? jsonList) {
    List<RewardHistoryEntry>? items;
    if (CollectionUtils.isNotEmpty(jsonList)) {
      items = <RewardHistoryEntry>[];
      for (dynamic jsonEntry in jsonList!) {
        ListUtils.add(items, RewardHistoryEntry.fromJson(jsonEntry));
      }
    }
    return items;
  }
}
