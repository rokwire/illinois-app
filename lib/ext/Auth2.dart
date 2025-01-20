
import 'dart:convert';
import 'dart:typed_data';

import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension Auth2UserProfileExt on Auth2UserProfile {
  String toVCF({Uint8List? photoImageData,}) {
    // https://en.wikipedia.org/wiki/VCard
    String vcfContent = "";
    vcfContent += _fieldValue('BEGIN', 'VCARD');
    vcfContent += _fieldValue('VERSION', '2.1');
    vcfContent += _fieldValue('FN', vcfFullName);
    vcfContent += _fieldValue('N', _vcfName);
    vcfContent += _fieldValue('TITLE', title);
    vcfContent += _fieldValue('ORG', _vcfOrg);
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

  String? get vcfFullName => StringUtils.fullName([firstName, lastName]);
  String get _vcfName => "${lastName ?? ''};${firstName ?? ''};${middleName ?? ''}};;";
  String get _vcfOrg => "$_vcfUniversityName;$_vcfCollegeAndDepartment";
  String get _vcfCollegeAndDepartment => (college?.isNotEmpty == true) ? ((department?.isNotEmpty == true) ? "$college / $department" : (college ?? '')) : (department ?? '');
  String get _vcfUniversityName => Localization().getStringEx('app.univerity_long_name', 'University of Illinois Urbana-Champaign', language: 'en');
}