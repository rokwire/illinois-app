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

//model
import 'package:illinois/service/AppDateTime.dart';

import 'UserData.dart';

class Reminder implements Favorite{
  final String id;
  final String label;
  final DateTime dateUtc;

  Reminder({this.id, this.label, this.dateUtc});

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      label: json['label'],
      dateUtc: AppDateTime().dateTimeFromString(json['date'], isUtc: true),
    );
  }

  toJson() {
    return {
      "id": id,
      "label": label,
      "date": AppDateTime().formatDateTime(dateUtc, ignoreTimeZone: true),
    };
  }

  String get displayDate {
    return AppDateTime().formatDateTime(dateUtc, format: 'MMM dd', ignoreTimeZone: true);
  }

  @override
  String get favoriteId => id;

  @override
  String get favoriteKey => favoriteKeyName;

  static String favoriteKeyName = "remindersIds";


}