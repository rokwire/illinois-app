
import 'dart:convert';
import 'dart:typed_data';

import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension Auth2UserProfileVCard on Auth2UserProfile {
  String toVCard({Uint8List? photoImageData,}) {
    // https://en.wikipedia.org/wiki/VCard
    String vcfContent = "";
    vcfContent += _fieldValue('BEGIN', 'VCARD');
    vcfContent += _fieldValue('VERSION', '2.1');
    vcfContent += _fieldValue('FN', vcardFullName);
    vcfContent += _fieldValue('N', _vcardName);
    vcfContent += _fieldValue('TITLE', title);
    vcfContent += _fieldValue('ORG', _vcardOrg);
    vcfContent += _fieldValue('EMAIL;TYPE=primary', email);
    vcfContent += _fieldValue('EMAIL;TYPE=secondary', email2);
    vcfContent += _fieldValue('TEL', phone);
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
  String get _vcardOrg => "$_vcardUniversityName;$_vcardCollegeAndDepartment";
  String get _vcardCollegeAndDepartment => (college?.isNotEmpty == true) ? ((department?.isNotEmpty == true) ? "$college / $department" : (college ?? '')) : (department ?? '');
  String get _vcardUniversityName => Localization().getStringEx('app.univerity_long_name', 'University of Illinois Urbana-Champaign', language: 'en');
}