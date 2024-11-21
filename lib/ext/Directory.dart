
import 'package:illinois/model/Directory.dart';

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
}