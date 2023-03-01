// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';

import 'Skill.dart';

class Occupation {
  String? code;
  String? title;
  String? description;
  double? matchPercentage;
  String? onetLink;
  List<Skill>? skills;
  List<Skill>? technicalSkills;
  Occupation({
    this.code,
    this.title,
    this.description,
    this.matchPercentage,
    this.onetLink,
    this.skills,
    this.technicalSkills,
  });

  Occupation.fromJson(Map<String, dynamic> json) {
    code = json['code'] as String;
    title = json['occupation']['title'] as String;
    description = json['occupation']['description'] as String;
    onetLink = 'https://www.onetonline.org/link/summary/$code';

    skills = (json['skills']['element'] as List).cast<Map<String, dynamic>>().map((e) => Skill.fromJson(e)).toList();
    technicalSkills = [];

    // TODO: Change this to use the backend service
    matchPercentage = 50.0;
  }

  Occupation copyWith({
    String? code,
    String? title,
    String? description,
    double? matchPercentage,
    String? onetLink,
    List<Skill>? skills,
    List<Skill>? technicalSkills,
  }) {
    return Occupation(
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      onetLink: onetLink ?? this.onetLink,
      skills: skills ?? this.skills,
      technicalSkills: technicalSkills ?? this.technicalSkills,
    );
  }

  @override
  String toString() {
    return 'Occupation(code: $code, title: $title, description: $description, matchPercentage: $matchPercentage, onetLink: $onetLink, skills: $skills, technicalSkills: $technicalSkills)';
  }

  @override
  bool operator ==(covariant Occupation other) {
    if (identical(this, other)) return true;

    return other.code == code &&
        other.title == title &&
        other.description == description &&
        other.matchPercentage == matchPercentage &&
        other.onetLink == onetLink &&
        listEquals(other.skills, skills) &&
        listEquals(other.technicalSkills, technicalSkills);
  }

  @override
  int get hashCode {
    return code.hashCode ^
        title.hashCode ^
        description.hashCode ^
        matchPercentage.hashCode ^
        onetLink.hashCode ^
        skills.hashCode ^
        technicalSkills.hashCode;
  }
}
