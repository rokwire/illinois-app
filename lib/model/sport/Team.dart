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

class TeamRecord {
  String overallPercentage;
  String overallRecordUnformatted;
  String conferenceRecord;
  String conferencePercentage;
  String conferencePoints;
  String streak;
  String homeRecord;
  String awayRecord;
  String neutralRecord;

  TeamRecord(
      {this.overallPercentage,
      this.overallRecordUnformatted,
      this.conferenceRecord,
      this.conferencePercentage,
      this.conferencePoints,
      this.streak,
      this.homeRecord,
      this.awayRecord,
      this.neutralRecord});

  factory TeamRecord.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return TeamRecord(
      overallPercentage: json['overall_percentage'],
      overallRecordUnformatted: json['overall_record_unformatted'],
      conferenceRecord: json['conference_record'],
      conferencePercentage: json['conference_percentage'],
      conferencePoints: json['conference_points'],
      streak: json['streak'],
      homeRecord: json['home_record'],
      awayRecord: json['away_record'],
      neutralRecord: json['neutral_record'],
    );
  }
}

class TeamSchedule {
  List<Game> games;
  TeamRecord record;

  TeamSchedule({this.games, this.record});

  factory TeamSchedule.fromJson(Map<String, dynamic> json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    List<dynamic> scheduleJson = json['schedule'];
    List<Game> games = (scheduleJson != null) ? scheduleJson.map((value) => Game.fromJson(value)).toList() : null;
    return TeamSchedule(games: games, record: TeamRecord.fromJson(json['record']));
  }
}
