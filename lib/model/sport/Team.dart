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

import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/utils/Utils.dart';

class TeamRecord {
  final String? overallRecordUnformatted;
  final String? conferenceRecord;
  final String? streak;
  final String? homeRecord;
  final String? awayRecord;
  final String? neutralRecord;

  TeamRecord({this.overallRecordUnformatted, this.conferenceRecord, this.streak, this.homeRecord, this.awayRecord, this.neutralRecord});

  static TeamRecord? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return TeamRecord(
      overallRecordUnformatted: json['overall_record_unformatted'],
      conferenceRecord: json['conference_record'],
      streak: json['streak'],
      homeRecord: json['home_record'],
      awayRecord: json['away_record'],
      neutralRecord: json['neutral_record'],
    );
  }
}

class TeamSchedule {
  final List<Game>? games;
  final String? label;

  TeamSchedule({this.games, this.label});

  static TeamSchedule? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TeamSchedule(
      games: Game.listFromJson(AppJson.listValue(json['games'])),
      label: AppJson.stringValue(json['label'])) : null;
  }
}
