// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'skill.dart';

class Occupation {
  String? name;
  String? description;
  double? matchPercentage;
  String? onetLink;
  List<Skill>? skills;
  List<Skill>? technicalSkills;

  Occupation({
    required this.name,
    required this.description,
    required this.matchPercentage,
    required this.onetLink,
    required this.skills,
    required this.technicalSkills,
  });

  Occupation copyWith({
    String? name,
    String? description,
    double? matchPercentage,
    String? onetLink,
    List<Skill>? skills,
    List<Skill>? technicalSkills,
  }) {
    return Occupation(
      name: name ?? this.name,
      description: description ?? this.description,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      onetLink: onetLink ?? this.onetLink,
      skills: skills ?? this.skills,
      technicalSkills: technicalSkills ?? this.technicalSkills,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'matchPercentage': matchPercentage,
      'onetLink': onetLink,
      'skills': skills?.map((x) => x.toJson()).toList() ?? [],
      'technicalSkills': technicalSkills?.map((x) => x.toJson()).toList() ?? [],
    };
  }

  factory Occupation.fromMap(Map<String, dynamic> map) {
    return Occupation(
      name: map['name'] != null ? map['name'] as String : null,
      description: map['description'] != null ? map['description'] as String : null,
      matchPercentage: map['matchPercentage'] != null ? map['matchPercentage'] as double : null,
      onetLink: map['onetLink'] != null ? map['onetLink'] as String : null,
      skills: map['skills'] != null ? List<Skill>.from((map['skills'] as List<int>).map<Skill?>((x) => Skill.fromMap(x as Map<String,dynamic>),),) : null,
      technicalSkills: map['technicalSkills'] != null ? List<Skill>.from((map['technicalSkills'] as List<int>).map<Skill?>((x) => Skill.fromMap(x as Map<String,dynamic>),),) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Occupation.fromJson(String source) => Occupation.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Occupation(name: $name, description: $description, matchPercentage: $matchPercentage, onetLink: $onetLink, skills: $skills, technicalSkills: $technicalSkills)';
  }

  @override
  bool operator ==(covariant Occupation other) {
    if (identical(this, other)) return true;
  
    return 
      other.name == name &&
      other.description == description &&
      other.matchPercentage == matchPercentage &&
      other.onetLink == onetLink &&
      listEquals(other.skills, skills) &&
      listEquals(other.technicalSkills, technicalSkills);
  }

  @override
  int get hashCode {
    return name.hashCode ^
      description.hashCode ^
      matchPercentage.hashCode ^
      onetLink.hashCode ^
      skills.hashCode ^
      technicalSkills.hashCode;
  }
}
