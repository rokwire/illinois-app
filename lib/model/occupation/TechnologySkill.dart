import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class TechnologySkill {
  int? id;
  String? name;
  List<String?>? examples;

  TechnologySkill({
    this.id,
    this.name,
    this.examples,
  });

  factory TechnologySkill.fromJson(Map<String, dynamic> json) {
    return TechnologySkill(
      id: JsonUtils.intValue(json["id"]),
      name: JsonUtils.stringValue(json["name"]) ?? "",
      examples: JsonUtils.listStringsValue(json["examples"]) ?? [],
    );
  }

  static List<TechnologySkill>? listFromJson(List<dynamic>? jsonList) {
    List<TechnologySkill>? result;
    if (jsonList != null) {
      result = <TechnologySkill>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? mapVal = JsonUtils.mapValue(jsonEntry);
        if (mapVal != null) {
          try {
            ListUtils.add(result, TechnologySkill.fromJson(mapVal));
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      }
    }
    return result;
  }
}
