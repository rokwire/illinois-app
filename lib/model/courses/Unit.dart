
import 'package:rokwire_plugin/utils/utils.dart';

import 'Content.dart';
import 'ScheduleItem.dart';

class Unit{
  final String? id;
  final String? name;
  final String? key;
  final String? courseKey;
  final String? moduleKey;
  final List<ScheduleItem>? scheduleItems;
  final List<Content>? contentItems;

  Unit({this.id, this.name, this.key, this.courseKey, this.moduleKey, this.scheduleItems, this.contentItems});

  static Unit? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Unit(
      id: JsonUtils.stringValue(json['id']),
      name: JsonUtils.stringValue(json['name']),
      key: JsonUtils.stringValue(json['key']),
      courseKey: JsonUtils.stringValue(json['course_key']),
      moduleKey: JsonUtils.stringValue(json['module_key']),
      scheduleItems: ScheduleItem.listFromJson(JsonUtils.listValue(json['schedule_items'])),
      contentItems: Content.listFromJson(JsonUtils.listValue(json['content_items'])),
    );

  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'id': id,
      'name': name,
      'key': key,
      'course_key': courseKey,
      'module_key': moduleKey,
      'schedule_items': ScheduleItem.listToJson(scheduleItems),
      'content_items': Content.listToJson(contentItems),
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static List<Unit>? listFromJson(List<dynamic>? jsonList) {
    List<Unit>? result;
    if (jsonList != null) {
      result = <Unit>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Unit.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Unit>? contentList) {
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