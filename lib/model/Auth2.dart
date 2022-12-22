
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';


////////////////////////////////
// AuthCard

class AuthCard {

  final String? uin;
  final String? fullName;
  final String? role;
  final String? studentLevel;
  final String? cardNumber;
  final String? expirationDate;
  final String? libraryNumber;
  final String? magTrack2;
  final String? photoBase64;

  AuthCard({this.uin, this.cardNumber, this.libraryNumber, this.expirationDate, this.fullName, this.role, this.studentLevel, this.magTrack2, this.photoBase64});

  static AuthCard? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AuthCard(
      uin: json['UIN'],
      fullName: json['full_name'],
      role: json['role'],
      studentLevel: json['student_level'],
      cardNumber: json['card_number'],
      expirationDate: json['expiration_date'],
      libraryNumber: json['library_number'],
      magTrack2: json['mag_track2'],
      photoBase64: json['photo_base64'],
    ) : null;
  }

  toJson() {
    return {
      'UIN': uin,
      'full_name': fullName,
      'role': role,
      'student_level': studentLevel,
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
      'student_level': studentLevel,
      'card_number': cardNumber,
      'expiration_date': expirationDate,
      'library_number': libraryNumber,
      'mag_track2': magTrack2,
      'photo_base64_len': photoBase64?.length,
    };
  }

  @override
  bool operator ==(other) =>
      other is AuthCard &&
          other.uin == uin &&
          other.fullName == fullName &&
          other.role == role &&
          other.studentLevel == studentLevel &&
          other.cardNumber == cardNumber &&
          other.expirationDate == expirationDate &&
          other.libraryNumber == libraryNumber &&
          other.magTrack2 == magTrack2 &&
          other.photoBase64 == photoBase64;

  @override
  int get hashCode =>
      uin.hashCode ^
      fullName.hashCode ^
      role.hashCode ^
      studentLevel.hashCode ^
      cardNumber.hashCode ^
      expirationDate.hashCode ^
      libraryNumber.hashCode ^
      magTrack2.hashCode ^
      photoBase64.hashCode;

  Future<Uint8List?>? get photoBytes async {
    return (photoBase64 != null) ? await compute(base64Decode, photoBase64!) : null;
  }

  bool get needsUpdate {
    return (role == "Undergraduate") && (studentLevel != "1U");
  }

  DateTime? get expirationDateTimeUtc {
    Location? universityLocation = AppDateTime().universityLocation;
    DateTime? expirationDateTimeUtc = (expirationDate != null) ? DateTimeUtils.parseDateTime(expirationDate!, format: "yyyy-MM-dd", isUtc: true) : null;
    return  ((expirationDateTimeUtc != null) && (universityLocation != null)) ? TZDateTime(universityLocation, expirationDateTimeUtc.year, expirationDateTimeUtc.month, expirationDateTimeUtc.day).toUtc() : null;
  }
}

