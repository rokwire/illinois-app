
import 'package:rokwire_plugin/service/content.dart';

extension FileContentItemReferenceUtils on FileContentItemReference {

  static Map<String, FileContentItemReference> mapList(List<FileContentItemReference> list, { String? Function(FileContentItemReference ref) keyAccess = accessRefKey }) {
    Map<String, FileContentItemReference> map = <String, FileContentItemReference>{};
    for (FileContentItemReference entry in list) {
      String? entryKey = keyAccess(entry);
      if (entryKey != null) {
        map[entryKey] = entry;
      }
    }
    return map;
  }

  static String? accessRefKey(FileContentItemReference ref) => ref.key;
  static String? accessRefName(FileContentItemReference ref) => ref.name;

}