
import 'package:illinois/model/Directory.dart';
import 'package:illinois/model/IlliniCash.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';

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

  static DirectoryMember fromExternalData({Auth2Account? auth2Account, IlliniStudentClassification? studentClassification} ) =>
    DirectoryMember(
      netId: auth2Account?.authType?.uiucUser?.netId,
      firstName: (auth2Account?.profile?.firstName?.isNotEmpty == true) ? auth2Account?.profile?.firstName : auth2Account?.authType?.uiucUser?.firstName,
      middleName: (auth2Account?.profile?.middleName?.isNotEmpty == true) ? auth2Account?.profile?.middleName : auth2Account?.authType?.uiucUser?.middleName,
      lastName: (auth2Account?.profile?.lastName?.isNotEmpty == true) ? auth2Account?.profile?.lastName : auth2Account?.authType?.uiucUser?.lastName,
      photoUrl: (auth2Account?.profile?.photoUrl?.isNotEmpty == true) ? auth2Account?.profile?.photoUrl : Content().getUserProfileImage(accountId: auth2Account?.id, type: UserProfileImageType.medium),
      email: (auth2Account?.profile?.email?.isNotEmpty == true) ? auth2Account?.profile?.email : auth2Account?.authType?.uiucUser?.email,
      phone: auth2Account?.profile?.phone,
      college: studentClassification?.collegeName,
      department: studentClassification?.departmentName,
  );

}