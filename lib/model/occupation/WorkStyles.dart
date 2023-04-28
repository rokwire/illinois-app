import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WorkStyle {
  String? id;
  String? name;
  String? description;

  WorkStyle({
    this.id,
    this.name,
    this.description,
  });

  factory WorkStyle.fromJson(Map<String, dynamic> json) {
    return WorkStyle(
      id: JsonUtils.stringValue(json["id"]) ?? "",
      name: JsonUtils.stringValue(json["name"]) ?? "",
      description: JsonUtils.stringValue(json["description"]) ?? "",
    );
  }

  static List<WorkStyle>? listFromJson(List<dynamic>? jsonList) {
    List<WorkStyle>? result;
    if (jsonList != null) {
      result = <WorkStyle>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? mapVal = JsonUtils.mapValue(jsonEntry);
        if (mapVal != null) {
          try {
            ListUtils.add(result, WorkStyle.fromJson(mapVal));
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      }
    }
    return result;
  }
}
