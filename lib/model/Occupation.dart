import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Occupation {
  String? code;
  String? name;
  String? description;
  String? onetLink;
  List<WorkStyle>? workStyles;
  List<TechnologySkill>? technologySkills;

  Occupation({
    this.code,
    this.name,
    this.description,
    this.onetLink,
    this.workStyles,
    this.technologySkills,
  });

  factory Occupation.fromJson(Map<String, dynamic> json) {
    return Occupation(
      code: JsonUtils.stringValue(json["code"]) ?? "",
      name: JsonUtils.stringValue(json["name"]) ?? "",
      description: JsonUtils.stringValue(json["description"]) ?? "",
      onetLink: JsonUtils.stringValue(json["onetLink"]) ?? "",
      workStyles: WorkStyle.listFromJson(json["work_styles"]) ?? [],
      technologySkills: TechnologySkill.listFromJson(json["technology_skills"]) ?? [],
    );
  }

  static List<Occupation>? listFromJson(List<dynamic>? jsonList) {
    List<Occupation>? result;
    if (jsonList != null) {
      result = <Occupation>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? mapVal = JsonUtils.mapValue(jsonEntry);
        if (mapVal != null) {
          try {
            ListUtils.add(result, Occupation.fromJson(mapVal));
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      }
    }
    return result;
  }

  @override
  String toString() {
    return 'Occupation(code: $code, name: $name, description: $description, onetLink: $onetLink, workStyles: $workStyles, technologySkills: $technologySkills)';
  }
}

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

class OccupationMatch {
  double? matchPercent;
  Occupation? occupation;

  OccupationMatch({
    this.matchPercent,
    this.occupation,
  });

  factory OccupationMatch.fromJson(Map<String, dynamic> json) {
    return OccupationMatch(
      occupation: Occupation.fromJson(json["occupation"]),
      matchPercent: JsonUtils.doubleValue(json["match_percent"]) ?? 0.0,
    );
  }

  static List<OccupationMatch>? listFromJson(List<dynamic>? jsonList) {
    List<OccupationMatch>? result;
    if (jsonList != null) {
      result = <OccupationMatch>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? mapVal = JsonUtils.mapValue(jsonEntry);
        if (mapVal != null) {
          try {
            ListUtils.add(result, OccupationMatch.fromJson(mapVal));
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      }
    }
    return result;
  }

  @override
  String toString() {
    return 'OccupationMatch(occupation: $occupation, matchPercent: $matchPercent';
  }
}
