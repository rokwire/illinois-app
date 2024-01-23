
import 'package:rokwire_plugin/utils/utils.dart';

import 'Reference.dart';

class Content{
  final String? id;
  final String? name;
  final String? key;
  final String? courseKey;
  final String? moduleKey;
  final String? unitKey;
  final String? type;
  final String? details;
  final Reference? reference;
  final List<Content>? linkedContent;
  bool isComplete;


  Content({this.id, this.name, this.key, this.courseKey, this.moduleKey, this.unitKey, this.type, this.details, this.reference, this.linkedContent, this.isComplete = false});

  static Content? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Content(
      id: JsonUtils.stringValue(json['id']),
      name: JsonUtils.stringValue(json['name']),
      key: JsonUtils.stringValue(json['key']),
      courseKey: JsonUtils.stringValue(json['course_key']),
      moduleKey: JsonUtils.stringValue(json['module_key']),
      unitKey: JsonUtils.stringValue(json['unit_key']),
      type: JsonUtils.stringValue(json['type']),
      details: JsonUtils.stringValue(json['details']),
      reference: Reference.fromJson(JsonUtils.mapValue('reference')),
      linkedContent: Content.listFromJson(JsonUtils.listValue(json['linked_content'])),

    );

  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'id': id,
      'name': name,
      'key': key,
      'course_key': courseKey,
      'module_key': moduleKey,
      'unit_key': unitKey,
      'type': type,
      'details': details,
      'reference': reference?.toJson(),
      'linked_content': Content.listToJson(linkedContent)
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static List<Content>? listFromJson(List<dynamic>? jsonList) {
    List<Content>? result;
    if (jsonList != null) {
      result = <Content>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Content.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Content>? contentList) {
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