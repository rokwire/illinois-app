import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'WorkStyles.dart';
import 'TechnologySkill.dart';

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
