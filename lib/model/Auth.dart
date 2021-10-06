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
      else if(json.containsKey("id_token")||json.containsKey("access_token")||json.containsKey("refresh_token")){
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
    return (json != null) ? ShibbolethToken(
      idToken: json['id_token'],
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
    ) : null;
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
    return (json != null) ? PhoneToken(
      phone: json['phone'],
      idToken: json['id_token'],
    ) : null;
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
    AuthInfo result = (json != null) ? AuthInfo(
        fullName: AppJson.stringValue(json['name']),
        firstName: AppJson.stringValue(json['given_name']),
        middleName: AppJson.stringValue(json['middle_name']),
        lastName: AppJson.stringValue(json['family_name']),
        username: AppJson.stringValue(json['preferred_username']),
        uin: AppJson.stringValue(json['uiucedu_uin']),
        sub: AppJson.stringValue(json['sub']),
        email: AppJson.stringValue(json['email']),
        userGroupMembership: AppJson.stringSetValue(json['uiucedu_is_member_of']),
    ) : null;
    return result;
  }

  toJson() {
    return {
      "name": fullName,
      "given_name": firstName,
      "middle_name": middleName,
      "family_name": lastName,
      "preferred_username": username,
      "uiucedu_uin": uin,
      "sub": sub,
      "email": email,
      "uiucedu_is_member_of": userGroupMembership?.toList()
    };
  }
}

