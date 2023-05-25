import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WorkStyle {
  String? id;
  String? name;
  String? description;
  String? scale;
  double? value;

  static const Map<String, String> workstyleToBessi = {
    "Stress Tolerance": "stress_regulation",
    "Adaptability/Flexibility": "adaptability",
    "Concern for Others": "capacity_social_warmth",
    "Analytical Thinking": "abstract_thinking",
    "Cooperation": "teamwork",
    "Dependability": "responsibility_management",
    "Attention to Detail": "detail_management",
    "Initiative": "initiative",
    "Self-Control": "anger_management",
    "Persistence": "capacity_consistency",
    "Independence": "capacity_independence",
    "Social Orientation": "perspective_taking",
    "Achievement/Effort": "goal_regulation",
    "Innovation": "creativity",
    "Integrity": "ethical_competence",
    "Leadership": "leadership",
  };

  WorkStyle({
    this.id,
    this.name,
    this.description,
    this.scale,
    this.value
  });

  factory WorkStyle.fromJson(Map<String, dynamic> json) {
    return WorkStyle(
      id: JsonUtils.stringValue(json["id"]),
      name: JsonUtils.stringValue(json["name"]),
      description: JsonUtils.stringValue(json["description"]),
      scale: JsonUtils.stringValue(json["scale"]),
      value: JsonUtils.doubleValue(json["value"]),
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

  String? get bessiSection => name != null ? workstyleToBessi[name] : null;
}
