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

class LiveGame {
  String? gameId;
  String? path;
  bool? hasStarted;
  bool? isComplete;
  int? clockSeconds;
  int? period;
  int? homeScore;
  int? visitingScore;
  dynamic custom;

  LiveGame(
      {this.gameId,
      this.path,
      this.hasStarted,
      this.isComplete,
      this.clockSeconds,
      this.period,
      this.homeScore,
      this.visitingScore,
      this.custom});

  static LiveGame fromJson(Map<String, dynamic> json) {
    return LiveGame(
        gameId: json['GameId'],
        path: json['Path'],
        hasStarted: json['HasStarted'] == 'true',
        isComplete: json['IsComplete'] == 'true',
        clockSeconds: int.parse(json['ClockSeconds']),
        period: int.parse(json['Period']),
        homeScore: int.parse(json['HomeScore']),
        visitingScore: int.parse(json['VisitingScore']),
        custom: json["Custom"]
        );
  }
}
