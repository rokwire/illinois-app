
import 'package:illinois/model/courses/UserReference.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ScheduleItem{
  final String? name;
  final int? duration;
  final List<UserReference>? userReferences;

  ScheduleItem({this.name, this.duration, this.userReferences});

  static ScheduleItem? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ScheduleItem(
      name: JsonUtils.stringValue(json['name']),
      duration: JsonUtils.intValue(json['duration']),
      userReferences: UserReference.listFromJson(JsonUtils.listValue(json['contents'])),

    );

  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'duration': duration,
      'contents': UserReference.listToJson(userReferences)
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static List<ScheduleItem>? listFromJson(List<dynamic>? jsonList) {
    List<ScheduleItem>? result;
    if (jsonList != null) {
      result = <ScheduleItem>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, ScheduleItem.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<ScheduleItem>? contentList) {
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