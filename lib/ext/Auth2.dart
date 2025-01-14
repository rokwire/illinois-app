
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension Auth2UserProfileExt on Auth2UserProfile {
  String toVCF() {
    String vcfContent = "";
    vcfContent += _fieldValue('BEGIN', 'VCARD');
    vcfContent += _fieldValue('VERSION', '4.0');
    vcfContent += _fieldValue('FN', vcfFullName);
    vcfContent += _fieldValue('N', _vcfName);
    vcfContent += _fieldValue('TITLE', title);
    vcfContent += _fieldValue('ORG', _vcfOrg);
    //TODO: get email and phone from identifiers
    // vcfContent += _fieldValue('EMAIL', email);
    // vcfContent += _fieldValue('TEL', phone);
    vcfContent += _fieldValue('URL', website);
    //LOGO;TYPE=PNG;ENCODING=BASE64:[base64-data]
    //PHOTO;TYPE=PNG;ENCODING=BASE64:[base64-data]
    //SOUND:data:audio/ogg;base64:[base64-data]
    vcfContent += _fieldValue('END', 'VCARD');
    return vcfContent;
  }

  String _fieldValue(String key, String? value) =>
    (value?.isNotEmpty == true) ? '$key:$value\n' : '';

  String? get vcfFullName => StringUtils.fullName([title, firstName, lastName]);
  String get _vcfName => "${lastName ?? ''};${firstName ?? ''};${middleName ?? ''};${title ?? ''};";
  String get _vcfOrg => "$_vcfUniversityName;${college ?? ''};${department ?? ''}";
  String get _vcfUniversityName => Localization().getStringEx('app.univerity_long_name', 'University of Illinois Urbana-Champaign', language: 'en');
}