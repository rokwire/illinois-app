
import 'package:illinois/model/courses/Unit.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Module{
  final String? id;
  final String? name;
  final String? key;
  final String? courseKey;
  final List<Unit>? units;

  Module({this.id, this.name, this.key, this.courseKey, this.units});


  static Module? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Module(
        id: JsonUtils.stringValue(json['id']),
        name: JsonUtils.stringValue(json['name']),
        key: JsonUtils.stringValue(json['key']),
        courseKey: JsonUtils.stringValue(json['course_key']),
        units: Unit.listFromJson(JsonUtils.listValue(json['units'])),

    );

  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'id': id,
      'name': name,
      'key': key,
      'course_key': courseKey,
      'units': Unit.listToJson(units)
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static List<Module>? listFromJson(List<dynamic>? jsonList) {
    List<Module>? result;
    if (jsonList != null) {
      result = <Module>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Module.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Module>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}