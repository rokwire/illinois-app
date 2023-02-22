import 'dart:convert';

class Skill {
  String? name;
  String? description;
  double? matchPercentage;
  int? importance;
  int? level;
  int? jobZone;

  Skill({
    this.name,
    this.description,
    this.matchPercentage,
    this.importance,
    this.level,
    this.jobZone,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'matchPercentage': matchPercentage,
      'importance': importance,
      'level': level,
      'jobZone': jobZone,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      name: map['name'] != null ? map['name'] as String : null,
      description: map['description'] != null ? map['description'] as String : null,
      matchPercentage: map['matchPercentage'] != null ? map['matchPercentage'] as double : null,
      importance: map['importance'] != null ? map['importance'] as int : null,
      level: map['level'] != null ? map['level'] as int : null,
      jobZone: map['jobZone'] != null ? map['jobZone'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Skill.fromJson(String source) => Skill.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant Skill other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.description == description &&
        other.matchPercentage == matchPercentage &&
        other.importance == importance &&
        other.level == level &&
        other.jobZone == jobZone;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        description.hashCode ^
        matchPercentage.hashCode ^
        importance.hashCode ^
        level.hashCode ^
        jobZone.hashCode;
  }

  Skill copyWith({
    String? name,
    String? description,
    double? matchPercentage,
    int? importance,
    int? level,
    int? jobZone,
  }) {
    return Skill(
      name: name ?? this.name,
      description: description ?? this.description,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      importance: importance ?? this.importance,
      level: level ?? this.level,
      jobZone: jobZone ?? this.jobZone,
    );
  }

  @override
  String toString() {
    return 'Skill(name: $name, description: $description, matchPercentage: $matchPercentage, importance: $importance, level: $level, jobZone: $jobZone)';
  }
}
