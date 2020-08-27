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

class Coach{
  final int id;
  final String name;
  final String title;
  final String email;
  final String phone;
  final String htmlBio;
  final Map<String,dynamic> jsonData;

  Coach({this.id, this.name, this.title, this.email, this.phone, this.htmlBio, this.jsonData});

  String get photoUrl{
    String fullSizeUrl = _photoUrlWithKey("fullsize");
    return AppString.isStringNotEmpty(fullSizeUrl) ? '$fullSizeUrl?width=256' : "";
  }

  String get fullSizePhotoUrl{
    return _photoUrlWithKey("fullsize");
  }

  String _photoUrlWithKey(String key){
    if(AppString.isStringNotEmpty(key)){
      List<dynamic> photos = jsonData['photos'];

      if(photos != null && photos.isNotEmpty){
        return photos.first[key] != null ? photos.first[key] : "";
      }
    }
    return null;
  }

  factory Coach.fromJson(Map<String, dynamic> json) {
    Map<String,dynamic> staffInfo = json['staffinfo'];
    return Coach(
      id: json['id'],
      name: AppString.isStringNotEmpty(json['name']) ? json['name'] : "",
      title: AppString.isStringNotEmpty(staffInfo['title']) ? staffInfo['title'] : "",
      email: AppString.isStringNotEmpty(staffInfo['email']) ? staffInfo['email'] : "",
      phone: AppString.isStringNotEmpty(staffInfo['phone']) ? staffInfo['phone'] : "",
      htmlBio: AppString.isStringNotEmpty(json['bio']) ? json['bio'] : "",
      jsonData: json,
    );

  }
}