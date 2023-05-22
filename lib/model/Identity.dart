/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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

class MobileCredential {
  final List<String>? schemas;
  final UserInvitation? invitation;
  final Credential? credential;

  MobileCredential({this.schemas, this.invitation, this.credential});

  static MobileCredential? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return MobileCredential(
        schemas: JsonUtils.stringListValue(json['schemas']),
        invitation: UserInvitation.fromJson(JsonUtils.mapValue(json['user_invitation'])),
        credential: Credential.fromJson(JsonUtils.mapValue(json['credential'])));
  }
}

class Credential {
  final int? id;
  final String? partNumber;
  final String? partNumberFriendlyName;
  final String? status;
  final String? credentialType;
  final String? cardNumber;

  Credential({this.id, this.partNumber, this.partNumberFriendlyName, this.status, this.credentialType, this.cardNumber});

  static Credential? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Credential(
        id: JsonUtils.intValue(json['id']),
        partNumber: JsonUtils.stringValue(json['partNumber']),
        partNumberFriendlyName: JsonUtils.stringValue(json['partnumberFriendlyName']),
        status: JsonUtils.stringValue(json['status']),
        credentialType: JsonUtils.stringValue(json['credentialType']),
        cardNumber: JsonUtils.stringValue(json['cardNumber']));
  }
}

class UserInvitation {
  final int? id;
  final String? invitationCode;
  final String? status;
  final DateTime? createdDateUtc;
  final DateTime? expirationDateUtc;
  final UserInvitationMeta? meta;

  UserInvitation({this.id, this.invitationCode, this.status, this.createdDateUtc, this.expirationDateUtc, this.meta});

  static UserInvitation? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return UserInvitation(
        id: JsonUtils.intValue(json['id']),
        invitationCode: JsonUtils.stringValue(json['invitationCode']),
        status: JsonUtils.stringValue(json['status']),
        createdDateUtc:
            DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['createdDate']), format: _serverDateTimeFormat, isUtc: true),
        expirationDateUtc:
            DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['expirationDate']), format: _serverDateTimeFormat, isUtc: true),
        meta: UserInvitationMeta.fromJson(JsonUtils.mapValue(json['meta'])));
  }
}

class UserInvitationMeta {
  final String? resourceType;
  final DateTime? lastModifiedDateUtc;
  final String? location;

  UserInvitationMeta({this.resourceType, this.lastModifiedDateUtc, this.location});

  static UserInvitationMeta? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return UserInvitationMeta(
        resourceType: JsonUtils.stringValue(json['resourceType']),
        lastModifiedDateUtc:
            DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['lastModified']), format: _serverDateTimeFormat, isUtc: true),
        location: JsonUtils.stringValue(json['location']));
  }
}

final String _serverDateTimeFormat = 'yyyy-MM-ddTHH:mm:sssZ';
