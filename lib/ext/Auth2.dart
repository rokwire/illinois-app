
import 'dart:convert';
import 'dart:typed_data';

import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension Auth2UserProfileExt on Auth2UserProfile {
  bool get isNameNotEmpty =>
    StringUtils.isNotEmpty(firstName) ||
    StringUtils.isNotEmpty(middleName) ||
    StringUtils.isNotEmpty(lastName);

  bool get isCityStateZipCountryNotEmpty =>
    StringUtils.isNotEmpty(city) ||
    StringUtils.isNotEmpty(state) ||
    StringUtils.isNotEmpty(zip) ||
    StringUtils.isNotEmpty(country);

  bool get isNotEmpty =>
    (photoUrl?.isNotEmpty == true) ||
    (firstName?.isNotEmpty == true) ||
    (middleName?.isNotEmpty == true) ||
    (lastName?.isNotEmpty == true) ||
    (title?.isNotEmpty == true) ||
    (universityRole?.isNotEmpty == true) ||
    (college?.isNotEmpty == true) ||
    (department?.isNotEmpty == true) ||
    (major?.isNotEmpty == true) ||
    (department2?.isNotEmpty == true) ||
    (major2?.isNotEmpty == true) ||
    // (email?.isNotEmpty == true) ||
    (email2?.isNotEmpty == true) ||
    // (phone?.isNotEmpty == true) ||
    (website?.isNotEmpty == true);
}

extension Auth2UserProfileVCard on Auth2UserProfile {
  String toDigitalCard({Uint8List? photoImageData,}) {
    // https://en.wikipedia.org/wiki/VCard
    String vcfContent = "";
    vcfContent += _fieldValue('BEGIN', 'VCARD');
    vcfContent += _fieldValue('VERSION', '2.1');
    vcfContent += _fieldValue('FN', vcardFullName);
    vcfContent += _fieldValue('N', _vcardName);
    vcfContent += _fieldValue('TITLE', title);
    vcfContent += _fieldValue('ORG', _vcardOrg);
    vcfContent += _fieldValue('ADR', _vcardAddr);
    // vcfContent += _fieldValue('EMAIL;TYPE=primary', email);
    // vcfContent += _fieldValue('EMAIL;TYPE=secondary', email2);
    // vcfContent += _fieldValue('TEL', phone);
    vcfContent += _fieldValue('URL', website);
    if ((photoImageData != null) && photoImageData.isNotEmpty) {
      vcfContent += _fieldValue('PHOTO;JPG;ENCODING=BASE64', base64Encode(photoImageData));
    }
    //LOGO;TYPE=PNG;ENCODING=BASE64:[base64-data]
    //PHOTO;TYPE=PNG;ENCODING=BASE64:[base64-data]
    //SOUND:data:audio/ogg;base64:[base64-data]
    vcfContent += _fieldValue('END', 'VCARD');
    return vcfContent;
  }

  String _fieldValue(String key, String? value) =>
    (value?.isNotEmpty == true) ? '$key:$value\n' : '';

  String? get vcardFullName => StringUtils.fullName([firstName, lastName]);
  String get _vcardName => "${lastName ?? ''};${firstName ?? ''};${middleName ?? ''};;";
  String get _vcardOrg => "$displayUniversityName;$_vcardCollegeAndDepartment";
  String get _vcardCollegeAndDepartment {
    if (college?.isNotEmpty == true) {
      if (department?.isNotEmpty == true) {
        if (department2?.isNotEmpty == true) {
          return "$college / $department, $department2";
        }
        else {
          return "$college / $department";
        }
      }
      else if (department2?.isNotEmpty == true) {
        return "$college / $department2";
      }
      else {
        return college ?? '';
      }
    }
    else if (department?.isNotEmpty == true) {
      return (department2?.isNotEmpty == true) ? "$department, $department2" : (department ?? '');
    }
    else if (department2?.isNotEmpty == true) {
      return (department2 ?? '');
    }
    else {
      return '';
    }
  }

  String get _vcardAddr => "$poBox;$address2;$address;$city;$state;$zip;$country";

}

extension Auth2UserProfileDisplayText on Auth2UserProfile {
  String toDisplayText() {
    String displayText = "";
    displayText += _fieldValue(displayFullName, delimiter: '\n\n');

    displayText += _fieldValue(displayUniverirySection, delimiter: '\n\n');

    displayText += _fieldValue(displayAddressSection, delimiter: '\n\n');

    // displayText += _fieldValue(phone, label: Localization().getStringEx('generic.app.field.phone', 'Phone'));
    // displayText += _fieldValue(email, label: Localization().getStringEx('generic.app.field.email', 'Email'));
    displayText += _fieldValue(email2, label: Localization().getStringEx('generic.app.field.email2', 'Email2'));
    displayText += _fieldValue(website, label: Localization().getStringEx('generic.app.field.website', 'Website'));

    return displayText;
  }

  String? get displayFullName => StringUtils.fullName([firstName, middleName, lastName]);

  String? get displayUniverirySection => StringUtils.fullName([
    displayUniversityName,
    StringUtils.fullName([
      title,
      StringUtils.fullName([
        college, department, major,
      ], delimiter: ' • '),
      StringUtils.fullName([
        department2, major2,
      ], delimiter: ' • '),
    ], delimiter: ' - '),
  ], delimiter: '\n');

  String? get displayAddressSection => StringUtils.fullName([
    address,
    address2,
    displayPOBox,
    displayCityStateZipCountry,
  ], delimiter: '\n');

  static const String _poBoxMacro = '{{po_box}}';
  String? get displayPOBox => (poBox?.isNotEmpty == true) ?
    Localization().getStringEx('generic.app.field.po_box.format', 'PO Box $_poBoxMacro').
      replaceAll(_poBoxMacro, poBox ?? '') : null;

  String? get displayCityStateZipCountry => StringUtils.fullName([
    city,
    StringUtils.fullName([
      state, zip
    ], delimiter: ' '),
    country,
  ], delimiter: ', ');

  String _fieldValue(String? value, { String? label = null, String delimiter = '\n' }) {
    if ((value != null) && value.isNotEmpty) {
      if ((label != null) && label.isNotEmpty) {
        return '$label: $value$delimiter';
      }
      else {
        return '$value$delimiter';
      }
    }
    else {
      return '';
    }
  }

  String get displayUniversityName => Localization().getStringEx('app.university_long_name', 'NEOM U', language: 'en');
}

extension Auth2AccountEx on Auth2Account {

  Auth2UserProfile? previewProfile({Set<Auth2FieldVisibility> permitted = const <Auth2FieldVisibility>{Auth2FieldVisibility.public}}) =>
    profile?.buildPublic(privacy, permitted: permitted);
}

extension Auth2PublicUserProfile on Auth2UserProfile {

  Auth2UserProfile buildPublic(Auth2UserPrivacy? privacy, {Set<Auth2FieldVisibility> permitted = const <Auth2FieldVisibility>{Auth2FieldVisibility.public}}) {
    Auth2UserProfileFieldsVisibility profileVisibility = Auth2UserProfileFieldsVisibility.fromOther(privacy?.fieldsVisibility?.profile,
      firstName: Auth2FieldVisibility.public,
      middleName: Auth2FieldVisibility.public,
      lastName: Auth2FieldVisibility.public,
      // email: Auth2FieldVisibility.public,
    );

    return Auth2UserProfile.fromFieldsVisibility(this, profileVisibility, permitted: permitted);
  }
}