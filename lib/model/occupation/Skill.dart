// ignore_for_file: public_member_api_docs, sort_constructors_first
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

  Skill.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String;
    name = json['name'] as String;
    description = json['description'] as String;

    // TODO: Fill out the rest of the values
    matchPercentage = 50.0;
  }
}
