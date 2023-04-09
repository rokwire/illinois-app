import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Skill {
  String? id;
  String? name;
  String? description;
  double? matchPercentage;
  int? importance;
  int? level;
  int? jobZone;

  Skill({
    this.id,
    this.name,
    this.description,
    this.matchPercentage,
    this.importance,
    this.level,
    this.jobZone,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: JsonUtils.stringValue(json["id"]) ?? "",
      name: JsonUtils.stringValue(json["name"]) ?? "",
      description: JsonUtils.stringValue(json["description"]) ?? "",
      matchPercentage: 50.0,
    );
  }

  static List<Skill>? listFromJson(List<dynamic>? jsonList) {
    List<Skill>? result;
    if (jsonList != null) {
      result = <Skill>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? mapVal = JsonUtils.mapValue(jsonEntry);
        if (mapVal != null) {
          try {
            ListUtils.add(result, Skill.fromJson(mapVal));
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      }
    }
    return result;
  }
}
