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

class SuccessTeamMember {
  final String firstName;
  final String lastName;
  final String email;
  final String image;
  final String? department;
  final String? title;
  final String? externalLink;
  final String? externalLinkText;
  final String? teamMemberId;

  SuccessTeamMember({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.image,
    this.department,
    this.title,
    this.externalLink,
    this.externalLinkText,
    this.teamMemberId
  });
}
