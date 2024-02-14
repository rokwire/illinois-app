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

import 'package:rokwire_plugin/utils/utils.dart';

class SuccessTeamMember {
  final String firstName;
  final String lastName;
  final String image;
  final String? email;
  final String? department;
  final String? title;
  final String? externalLink;
  final String? externalLinkText;
  final String? teamMemberId;

  SuccessTeamMember({
    required this.firstName,
    required this.lastName,
    required this.image,
    this.email,
    this.department,
    this.title,
    this.externalLink,
    this.externalLinkText,
    this.teamMemberId
  });

  static SuccessTeamMember? fromJson(Map<String, dynamic>? json) {
    String? firstName = JsonUtils.stringValue(json?['first_name']);
    String? lastName = JsonUtils.stringValue(json?['last_name']);
    String? image = JsonUtils.stringValue(json?['image']);
    return ((firstName != null) && (lastName != null) && (image != null)) ? SuccessTeamMember(
      firstName: firstName,
      lastName: lastName,
      image: image,
    ) : null;
  }
}
