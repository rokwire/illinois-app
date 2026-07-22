
import 'package:rokwire_plugin/service/content.dart';

extension FileContentItemReferenceUtils on FileContentItemReference {

  static Map<String, FileContentItemReference> mapList(List<FileContentItemReference> list) {
    Map<String, FileContentItemReference> map = <String, FileContentItemReference>{};
    for (FileContentItemReference entry in list) {
      if (entry.key != null) {
        map[entry.key ?? ''] = entry;
      }
    }
    return map;
  }

}