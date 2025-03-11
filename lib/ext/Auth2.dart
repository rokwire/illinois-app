
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

  bool get isNotEmpty =>
    (photoUrl?.isNotEmpty == true) ||
    (firstName?.isNotEmpty == true) ||
    (middleName?.isNotEmpty == true) ||
    (lastName?.isNotEmpty == true) ||
    (title?.isNotEmpty == true) ||
    (college?.isNotEmpty == true) ||
    (department?.isNotEmpty == true) ||
    (major?.isNotEmpty == true) ||
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
  String get _vcardOrg => "$_textUniversityName;$_vcardCollegeAndDepartment";
  String get _vcardCollegeAndDepartment => (college?.isNotEmpty == true) ? ((department?.isNotEmpty == true) ? "$college / $department" : (college ?? '')) : (department ?? '');
}

extension Auth2UserProfileDisplayText on Auth2UserProfile {
  String toDisplayText() {
    String displayText = "";
    displayText += _fieldValue(_textFullName, delimiter: '\n\n');
    displayText += _fieldValue(_textOrgColDept, delimiter: '\n\n');
    // displayText += _fieldValue(phone, label: Localization().getStringEx('generic.app.field.phone', 'Phone'));
    // displayText += _fieldValue(email, label: Localization().getStringEx('generic.app.field.email', 'Email'));
    displayText += _fieldValue(email2, label: Localization().getStringEx('generic.app.field.email2', 'Email2'));
    displayText += _fieldValue(website, label: Localization().getStringEx('generic.app.field.website', 'Website'));

    return displayText;
  }

  String? get _textFullName => StringUtils.fullName([firstName, middleName, lastName]);

  String? get _textOrgColDept => StringUtils.fullName([
    title,
    StringUtils.fullName([
      college,department, _textUniversityName
    ], delimiter: ' • '),
  ], delimiter: ' - ');

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

  String get _textUniversityName => Localization().getStringEx('app.university_long_name', 'University of Illinois Urbana-Champaign', language: 'en');
}

extension Auth2AccountEx on Auth2Account {

  Auth2UserProfile? previewProfile({Set<Auth2FieldVisibility> permitted = const <Auth2FieldVisibility>{Auth2FieldVisibility.public}}) {
    Auth2UserProfileFieldsVisibility profileVisibility = Auth2UserProfileFieldsVisibility.fromOther(privacy?.fieldsVisibility?.profile,
      firstName: Auth2FieldVisibility.public,
      middleName: Auth2FieldVisibility.public,
      lastName: Auth2FieldVisibility.public,
      // email: Auth2FieldVisibility.public,
    );

    return Auth2UserProfile.fromFieldsVisibility(profile, profileVisibility, permitted: permitted);
  }
}