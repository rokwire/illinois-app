
import 'package:illinois/model/courses/Module.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class Course{
  final String? id;
  final String? name;
  final String? key;
  late final List<Module>? modules;

  Course({this.id, this.name, this.key, this.modules});

  static Course? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Course(
        id: JsonUtils.stringValue(json['id']),
        name: JsonUtils.stringValue(json['name']),
        key: JsonUtils.stringValue(json['key']),
        modules: Module.listFromJson(JsonUtils.listValue(json['modules'])),
    );

  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'id': id,
      'title': name,
      'key': key,
      'modules': Module.listToJson(modules)
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }
}