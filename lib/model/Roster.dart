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

//////////////////////////////
/// Roster

class Roster {
  String id;
  String name;
  String position;
  String numberString;
  String height;
  String weight;
  String year;
  String hometown;
  String highSchool;
  String major;
  String htmlBio;
  Map<String,dynamic> jsonData;

  // Parses the number. If the parse thorws error return -1
  int get number{
    try {
      return int.parse(numberString);
    } on Exception catch(e){
      print(e);
      return -1;
    }
  }

  Roster({
    this.id,
    this.name,
    this.position,
    this.numberString,
    this.height,
    this.weight,
    this.year,
    this.hometown,
    this.highSchool,
    this.major,
    this.htmlBio,
    this.jsonData,
  });

  String get rosterPhotoUrl{
    String fullSizeUrl = _rosterPhotoUrlWithType('headshot', 'fullsize');
    return  AppString.isStringNotEmpty(fullSizeUrl) ? '$fullSizeUrl?width=256' : "";
  }

  String get rosterFullSizePhotoUrl{
    return _rosterPhotoUrlWithType('headshot', 'fullsize');
  }

  String _rosterPhotoUrlWithType(String type, String subType){
    String photoUrl;

    if(AppString.isStringNotEmpty(type) && AppString.isStringNotEmpty(subType)) {
      List<dynamic> photos = jsonData['photos'];
      for (Map<String, dynamic> photoEntry in photos) {
        if(type == photoEntry['type']){
          return photoEntry.containsKey(subType)? photoEntry[subType] : "";
        }
      }
    }
    return photoUrl;
  }

  factory Roster.fromJson(Map<String, dynamic> json) {
    Map<String,dynamic> info = json['playerinfo'] != null ? json['playerinfo'] : Map();
    //Map<String,dynamic> info = json['playerinfo'];
    return Roster(
      id: !AppString.isStringEmpty(json['rp_id']) ? json['rp_id'] : "",
      name: !AppString.isStringEmpty(json['name']) ? json['name'] : "",
      position: !AppString.isStringEmpty(info['pos_short']) ? info['pos_short'] : "",
        numberString: !AppString.isStringEmpty(info['uni']) ? info['uni'] : "",
      height: !AppString.isStringEmpty(info['height']) ? info['height'] : "",
      weight: !AppString.isStringEmpty(info['weight']) ? info['weight'] : "",
      year: !AppString.isStringEmpty(info['year_long']) ? info['year_long'] : "",
      hometown: !AppString.isStringEmpty(info['hometown']) ? info['hometown'] : "",
      highSchool: !AppString.isStringEmpty(info['highschool']) ? info['highschool'] : "",
      major: !AppString.isStringEmpty(info['major']) ? info['major'] : "",
      htmlBio: !AppString.isStringEmpty(json['bio']) ? json['bio'] : "",
        jsonData: json);

  }

  bool get hasPosition{
    return AppString.isStringNotEmpty(position);
  }

  bool get hasNumber{
    return AppString.isStringNotEmpty(numberString);
  }

}