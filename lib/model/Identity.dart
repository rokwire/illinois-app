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

import 'package:collection/collection.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class MobileCredential {
  final List<String>? schemas;
  final List<UserInvitation>? invitations;
  final List<Credential>? credentials;

  MobileCredential({this.schemas, this.invitations, this.credentials});

  static MobileCredential? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    List<String>? schemas = JsonUtils.stringListValue(json['schemas']);
    List<UserInvitation>? invitations;
    List<Credential>? credentials;
    if (CollectionUtils.isNotEmpty(schemas)) {
      for (String schema in schemas!) {
        List<dynamic>? jsonList = JsonUtils.listValue(json[schema]);
        if (schema.endsWith('UserInvitation')) {
          invitations = UserInvitation.fromJsonList(jsonList);
        } else if (schema.endsWith('Credential')) {
          credentials = Credential.fromJsonList(jsonList);
        }
      }
    }

    // Sort by expiration date
    invitations?.sort((a, b) {
      DateTime? expirationDateA = a.expirationDateUtc;
      DateTime? expirationDateB = b.expirationDateUtc;
      if ((expirationDateA == null) && (expirationDateB == null)) {
        return 0;
      } else if ((expirationDateA == null) && (expirationDateB != null)) {
        return 1;
      } else if ((expirationDateA != null) && (expirationDateB == null)) {
        return -1;
      } else {
        return expirationDateB!.compareTo(expirationDateA!);
      }
    });

    return MobileCredential(schemas: schemas, invitations: invitations, credentials: credentials);
  }

  UserInvitation? get lastPendingInvitation {
    if (CollectionUtils.isNotEmpty(invitations)) {
      for (UserInvitation invitation in invitations!) {
        if (invitation.status == InvitationCodeStatus.pending) {
          return invitation;
        }
      }
    }
    return null;
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

  static List<Credential>? fromJsonList(List<dynamic>? jsonList) {
    List<Credential>? items;
    if (jsonList != null) {
      items = <Credential>[];
      for (dynamic json in jsonList) {
        ListUtils.add(items, Credential.fromJson(json));
      }
    }
    return items;
  }
}

class UserInvitation {
  final int? id;
  final String? invitationCode;
  final InvitationCodeStatus? status;
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
        status: statusFromString(JsonUtils.stringValue(json['status'])),
        createdDateUtc:
            DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['createdDate']), format: _serverDateTimeFormat, isUtc: true),
        expirationDateUtc:
            DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['expirationDate']), format: _serverDateTimeFormat, isUtc: true),
        meta: UserInvitationMeta.fromJson(JsonUtils.mapValue(json['meta'])));
  }

  static List<UserInvitation>? fromJsonList(List<dynamic>? jsonList) {
    List<UserInvitation>? items;
    if (jsonList != null) {
      items = <UserInvitation>[];
      for (dynamic json in jsonList) {
        ListUtils.add(items, UserInvitation.fromJson(json));
      }
    }
    return items;
  }

  static InvitationCodeStatus? statusFromString(String? value) {
    switch (value) {
      case 'PENDING':
        return InvitationCodeStatus.pending;
      case 'ACKNOWLEDGED':
        return InvitationCodeStatus.acknowledged;
      case 'NOT_SUPPORTED':
        return InvitationCodeStatus.not_supported;
      case 'FAILED':
        return InvitationCodeStatus.failed;
      default:
        return null;
    }
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

enum InvitationCodeStatus { pending, acknowledged, not_supported, failed }

class StudentId {
  final String? fullName;
  final String? uin;
  final String? role;
  final String? studentLevel;
  final String? cardNumber;
  final DateTime? expirationDate;
  final String? libraryNumber;
  final String? magTrack2;
  final String? photoBase64;
  final int? resultCode;
  final String? resultDescription;
  final bool? isActiveCard;
  final int? birthYear;
  final MobileIdStatus? mobileIdStatus;
  final List<MobileIdCredential>? mobileCredentials;
  final bool? canRenewMobileId;

  StudentId(
      {this.fullName,
      this.uin,
      this.role,
      this.studentLevel,
      this.cardNumber,
      this.expirationDate,
      this.libraryNumber,
      this.magTrack2,
      this.photoBase64,
      this.resultCode,
      this.resultDescription,
      this.isActiveCard,
      this.birthYear,
      this.mobileIdStatus,
      this.mobileCredentials,
      this.canRenewMobileId});

  static StudentId? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    bool isActiveCard = ('Y' == JsonUtils.stringValue(json['is_active_card']));
    bool canRenewMobileId = ('yes' == JsonUtils.stringValue(json['can_renew_mobileid'])?.toLowerCase());
    return StudentId(
        fullName: JsonUtils.stringValue(json['full_name']),
        uin: JsonUtils.stringValue(json['UIN']),
        role: JsonUtils.stringValue(json['role']),
        studentLevel: JsonUtils.stringValue(json['student_level']),
        cardNumber: JsonUtils.stringValue(json['card_number']),
        expirationDate:
            DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['expiration_date']), format: _expirationDateFormat, isUtc: false),
        libraryNumber: JsonUtils.stringValue(json['library_number']),
        magTrack2: JsonUtils.stringValue(json['mag_track2']),
        photoBase64: JsonUtils.stringValue(json['photo_base64']),
        resultCode: JsonUtils.intValue(int.tryParse(json['result_code'])),
        resultDescription: JsonUtils.stringValue(json['result_description']),
        isActiveCard: isActiveCard,
        birthYear: JsonUtils.intValue(int.tryParse(json['birth_year'])),
        mobileIdStatus: mobileIdStatusFromString(JsonUtils.stringValue(json['mobileid_status'])),
        mobileCredentials: MobileIdCredential.fromJsonList(JsonUtils.listValue(json['mobile_credentials'])),
        canRenewMobileId: canRenewMobileId);
  }

  @override
  bool operator ==(dynamic other) =>
      (other is StudentId) &&
      (fullName == other.fullName) &&
      (uin == other.uin) &&
      (role == other.role) &&
      (studentLevel == other.studentLevel) &&
      (cardNumber == other.cardNumber) &&
      (expirationDate == other.expirationDate) &&
      (libraryNumber == other.libraryNumber) &&
      (magTrack2 == other.magTrack2) &&
      (photoBase64 == other.photoBase64) &&
      (resultCode == other.resultCode) &&
      (resultDescription == other.resultDescription) &&
      (isActiveCard == other.isActiveCard) &&
      (birthYear == other.birthYear) &&
      (mobileIdStatus == other.mobileIdStatus) &&
      (DeepCollectionEquality().equals(mobileCredentials, other.mobileCredentials)) &&
      (canRenewMobileId == other.canRenewMobileId);

  @override
  int get hashCode =>
      (fullName?.hashCode ?? 0) ^
      (uin?.hashCode ?? 0) ^
      (role?.hashCode ?? 0) ^
      (studentLevel?.hashCode ?? 0) ^
      (cardNumber?.hashCode ?? 0) ^
      (expirationDate?.hashCode ?? 0) ^
      (libraryNumber?.hashCode ?? 0) ^
      (magTrack2?.hashCode ?? 0) ^
      (photoBase64?.hashCode ?? 0) ^
      (resultCode?.hashCode ?? 0) ^
      (resultDescription?.hashCode ?? 0) ^
      (isActiveCard?.hashCode ?? 0) ^
      (birthYear?.hashCode ?? 0) ^
      (mobileIdStatus?.hashCode ?? 0) ^
      (DeepCollectionEquality().hash(mobileCredentials)) ^
      (canRenewMobileId?.hashCode ?? 0);

  static MobileIdStatus? mobileIdStatusFromString(String? value) {
    switch (value) {
      case 'ELIGIBLE':
        return MobileIdStatus.eligible;
      case 'ACTIVE':
        return MobileIdStatus.active;
      case 'PENDING':
        return MobileIdStatus.pending;
      case 'ISSUING':
        return MobileIdStatus.issuing;
      case 'INELIGIBLE':
        return MobileIdStatus.ineligible;
      default:
        return null;
    }
  }
}

class MobileIdCredential {
  final String? id;
  final DateTime? expirationDate;

  MobileIdCredential({this.id, this.expirationDate});

  String? get displayExpirationDate {
    return AppDateTime().formatDateTime(expirationDate, format: _expirationDateFormat);
  }

  @override
  bool operator ==(dynamic other) => (other is MobileIdCredential) && (id == other.id) && (expirationDate == other.expirationDate);

  @override
  int get hashCode => (id?.hashCode ?? 0) ^ (expirationDate?.hashCode ?? 0);

  static MobileIdCredential? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return MobileIdCredential(
        id: JsonUtils.stringValue(json['id']),
        expirationDate: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['expiration_date']), format: 'yyyy-MM-dd', isUtc: false));
  }

  static List<MobileIdCredential>? fromJsonList(List<dynamic>? jsonList) {
    List<MobileIdCredential>? items;
    if (jsonList != null) {
      items = <MobileIdCredential>[];
      for (dynamic json in jsonList) {
        ListUtils.add(items, MobileIdCredential.fromJson(json));
      }
    }
    return items;
  }
}

enum MobileIdStatus { eligible, active, pending, issuing, ineligible }

final String _serverDateTimeFormat = 'yyyy-MM-ddTHH:mm:sssZ';
final String _expirationDateFormat = 'yyyy-MM-dd';
