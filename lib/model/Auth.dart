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

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:illinois/utils/Utils.dart';

abstract class AuthToken {
  String get idToken => null;
  String get accessToken => null;
  String get refreshToken => null;
  String get tokenType => null;
  int get expiresIn => null;

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    if(json != null){
      if(json.containsKey("phone")){
        return PhoneToken.fromJson(json);
      }
      else{
        return ShibbolethToken.fromJson(json);
      }
    }
    return null;
  }

  toJson() => {};
}

class ShibbolethToken with AuthToken {

  final String idToken;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  ShibbolethToken({this.idToken, this.accessToken, this.refreshToken, this.tokenType, this.expiresIn});

  factory ShibbolethToken.fromJson(Map<String, dynamic> json) {
    return ShibbolethToken(
      idToken: json['id_token'],
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
    );
  }

  toJson() {
    return {
      'id_token': idToken,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn
    };
  }

  bool operator ==(o) =>
      o is ShibbolethToken &&
          o.idToken == idToken &&
          o.accessToken == accessToken &&
          o.refreshToken == refreshToken &&
          o.tokenType == tokenType &&
          o.expiresIn == expiresIn;

  int get hashCode =>
      idToken.hashCode ^
      accessToken.hashCode ^
      refreshToken.hashCode ^
      tokenType.hashCode ^
      expiresIn.hashCode;
}

class PhoneToken with AuthToken{
  final String phone;
  final String idToken;
  final String tokenType = "Bearer"; // missing data from the phone validation

  PhoneToken({this.phone, this.idToken});

  factory PhoneToken.fromJson(Map<String, dynamic> json) {
    return PhoneToken(
      phone: json['phone'],
      idToken: json['id_token'],
    );
  }

  toJson() {
    return {
      'phone': phone,
      'id_token': idToken,
    };
  }

  bool operator ==(o) =>
      o is PhoneToken &&
          o.phone == phone &&
          o.accessToken == accessToken;

  int get hashCode =>
      phone.hashCode ^
      accessToken.hashCode;
}

class AuthInfo {

  String fullName;
  String firstName;
  String middleName;
  String lastName;
  String username;
  String uin;
  String sub;
  String email;
  Set<String> userGroupMembership;

  static const analyticsUin = 'UINxxxxxx';
  static const analyticsFirstName = 'FirstNameXXXXXX';
  static const analyticsLastName = 'LastNameXXXXXX';

  AuthInfo({this.fullName, this.firstName, this.middleName, this.lastName,
    this.username, this.uin, this.sub, this.email, this.userGroupMembership});

  factory AuthInfo.fromJson(Map<String, dynamic> json) {
    dynamic groupMembershipJson = json != null
        ? json['uiucedu_is_member_of']
        : null;
    Set<String> userGroupMembership = groupMembershipJson != null ? Set.from(
        groupMembershipJson) : null;

    return (json != null) ? AuthInfo(
        fullName: AppString.isStringNotEmpty(json["name"]) ? json["name"] : "",
        firstName: AppString.isStringNotEmpty(json["given_name"]) ? json["given_name"] : "",
        middleName: AppString.isStringNotEmpty(json["middle_name"]) ? json["middle_name"] : "",
        lastName: AppString.isStringNotEmpty(json["family_name"]) ? json["family_name"] : "",
        username: AppString.isStringNotEmpty(json["preferred_username"]) ? json["preferred_username"] : "",
        uin: AppString.isStringNotEmpty(json["uiucedu_uin"]) ? json["uiucedu_uin"] : "",
        sub: AppString.isStringNotEmpty(json["sub"]) ? json["sub"] : "",
        email: AppString.isStringNotEmpty(json["email"]) ? json["email"] : "",
        userGroupMembership: userGroupMembership
    ) : null;
  }

  toJson() {
    List<dynamic> userGroupsToJson = (userGroupMembership != null) ?
    userGroupMembership.toList() : null;

    return {
      "name": fullName,
      "given_name": firstName,
      "middle_name": middleName,
      "family_name": lastName,
      "preferred_username": username,
      "uiucedu_uin": uin,
      "sub": sub,
      "email": email,
      "uiucedu_is_member_of": userGroupsToJson
    };
  }
}

class AuthCard {

  final String uin;
  final String fullName;
  final String role;
  final String cardNumber;
  final String expirationDate;
  final String libraryNumber;
  final String magTrack2;
  final String photoBase64;

  Future<Uint8List> get photoBytes async{
    return (photoBase64 != null) ? await compute(AppBytes.decodeBase64Bytes, photoBase64) : null;
  }

  AuthCard({this.uin, this.cardNumber, this.libraryNumber, this.expirationDate, this.fullName, this.role, this.magTrack2, this.photoBase64});

  factory AuthCard.fromJson(Map<String, dynamic> json) {
    return AuthCard(
      uin: json['UIN'],
      fullName: json['full_name'],
      role: json['role'],
      cardNumber: json['card_number'],
      expirationDate: json['expiration_date'],
      libraryNumber: json['library_number'],
      magTrack2: json['mag_track2'],
      photoBase64: json['photo_base64'],
    );
  }

  toJson() {
    return {
      'UIN': uin,
      'full_name': fullName,
      'role': role,
      'card_number': cardNumber,
      'expiration_date': expirationDate,
      'library_number': libraryNumber,
      'mag_track2': magTrack2,
      'photo_base64': photoBase64,
    };
  }

  toShortJson() {
    return {
      'UIN': uin,
      'full_name': fullName,
      'role': role,
      'card_number': cardNumber,
      'expiration_date': expirationDate,
      'library_number': libraryNumber,
      'mag_track2': magTrack2,
      'photo_base64_len': photoBase64?.length,
    };
  }

  bool operator ==(o) =>
      o is AuthCard &&
          o.uin == uin &&
          o.fullName == fullName &&
          o.role == role &&
          o.cardNumber == cardNumber &&
          o.expirationDate == expirationDate &&
          o.libraryNumber == libraryNumber &&
          o.magTrack2 == magTrack2 &&
          o.photoBase64 == photoBase64;

  int get hashCode =>
      uin.hashCode ^
      fullName.hashCode ^
      role.hashCode ^
      cardNumber.hashCode ^
      expirationDate.hashCode ^
      libraryNumber.hashCode ^
      magTrack2.hashCode ^
      photoBase64.hashCode;
}

