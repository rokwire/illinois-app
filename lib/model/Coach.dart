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

class Coach {
  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String title;
  final String email;
  final String phone;
  final String fullSizePhotoUrl;
  final String thumbPhotoUrl;
  final String htmlBio;

  Coach({this.id, this.name, this.firstName, this.lastName, this.title, this.email, this.phone, this.htmlBio, this.fullSizePhotoUrl, this.thumbPhotoUrl});

  static Coach fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return null;
    }
    Map<String, dynamic> photosJson = json['photos'];
    String fullSizePhotoUrl = photosJson != null ? photosJson['fullsize'] : null;
    String thumbPhotoUrl = photosJson != null ? photosJson['thumbnail'] : null;
    return Coach(
        id: json['id'],
        name: json['name'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        email: json['email'],
        phone: json['phone'],
        title: json['title'],
        htmlBio: json['bio'],
        fullSizePhotoUrl: fullSizePhotoUrl,
        thumbPhotoUrl: thumbPhotoUrl);
  }
}
