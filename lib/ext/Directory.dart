
import 'package:illinois/model/Directory.dart';
import 'package:illinois/model/IlliniCash.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension DirectoryMemberExt on DirectoryMember {

  String get fullName {
    String string = '';
    string = _addNameString(string, firstName);
    string = _addNameString(string, middleName);
    string = _addNameString(string, lastName);
    return string;
  }

  String _addNameString(String string, String? name) {
    if (name?.isNotEmpty == true) {
      if (string.isNotEmpty) {
        string += ' ';
      }
      string += name ?? '';
    }
    return string;
  }

  static DirectoryMember fromExternalData({
    Auth2Account? auth2Account,
    IlliniStudentClassification? studentClassification,

    String? id,
    String? netId,

    String? firstName,
    String? middleName,
    String? lastName,
    String? pronoun,
    String? title,

    String? photoUrl,
    String? pronunciationUrl,

    String? college,
    String? department,
    String? major,

    String? email,
    String? email2,
    String? phone,
    String? website,
  } ) =>
    DirectoryMember(
      id: id,
      netId: StringUtils.firstNotEmpty(netId, auth2Account?.authType?.uiucUser?.netId),

      firstName: StringUtils.firstNotEmpty(firstName, auth2Account?.profile?.firstName, auth2Account?.authType?.uiucUser?.firstName),
      middleName: StringUtils.firstNotEmpty(middleName, auth2Account?.profile?.middleName, auth2Account?.authType?.uiucUser?.middleName),
      lastName: StringUtils.firstNotEmpty(lastName, auth2Account?.profile?.lastName, auth2Account?.authType?.uiucUser?.lastName),
      pronoun: pronoun,
      title: title,

      photoUrl: StringUtils.firstNotEmpty(photoUrl, auth2Account?.profile?.photoUrl, Content().getUserProfileImage(accountId: auth2Account?.id, type: UserProfileImageType.medium)),
      pronunciationUrl: pronunciationUrl,

      college: StringUtils.firstNotEmpty(college, studentClassification?.collegeName),
      department: StringUtils.firstNotEmpty(department, studentClassification?.departmentName),
      major: major,

      email: StringUtils.firstNotEmpty(email, auth2Account?.profile?.email, auth2Account?.authType?.uiucUser?.email),
      email2: email2,
      phone: StringUtils.firstNotEmpty(phone, auth2Account?.profile?.phone),
      website: website,
  );

}