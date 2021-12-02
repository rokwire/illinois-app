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

import 'package:illinois/utils/Utils.dart';

class Roster {
  final String? id;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? position;
  final String? numberString;
  final String? height;
  final String? weight;
  final String? gender;
  final String? year;
  final String? hometown;
  final String? highSchool;
  final String? htmlBio;
  final String? fullSizePhotoUrl;
  final String? thumbPhotoUrl;

  Roster(
      {this.id,
      this.name,
      this.firstName,
      this.lastName,
      this.position,
      this.numberString,
      this.height,
      this.weight,
      this.gender,
      this.year,
      this.hometown,
      this.highSchool,
      this.htmlBio,
      this.fullSizePhotoUrl,
      this.thumbPhotoUrl});

  static Roster? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    Map<String, dynamic>? photosJson = json['photos'];
    String? fullSizePhotoUrl;
    String? thumbPhotoUrl;
    if (photosJson != null) {
      fullSizePhotoUrl = photosJson['fullsize'];
      thumbPhotoUrl = photosJson['thumbnail'];
    }
    return Roster(
        id: json['id'],
        name: json['name'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        numberString: json['uni'],
        position: json['pos_short'],
        height: json['height'],
        weight: json['weight'],
        gender: json['gender'],
        year: json['year_long'],
        hometown: json['hometown'],
        highSchool: json['highschool'],
        htmlBio: json['bio'],
        fullSizePhotoUrl: fullSizePhotoUrl,
        thumbPhotoUrl: thumbPhotoUrl);
  }

  bool get hasPosition {
    return AppString.isStringNotEmpty(position);
  }

  bool get hasNumber {
    return AppString.isStringNotEmpty(numberString);
  }

  int get number {
    try {
      return int.parse(numberString!);
    } on Exception catch (e) {
      print(e);
      return -1;
    }
  }
}
