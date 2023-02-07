// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

enum JobCategory {
  core,
  supplemental,
  notAvailable,
}

class Task {
  String? name;
  int? importance;
  JobCategory? category;
  Task({
    this.name,
    this.importance,
    this.category,
  });

  Task copyWith({
    String? name,
    int? importance,
    JobCategory? category,
  }) {
    return Task(
      name: name ?? this.name,
      importance: importance ?? this.importance,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'importance': importance,
      'category': category?.toMap(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      name: map['name'] != null ? map['name'] as String : null,
      importance: map['importance'] != null ? map['importance'] as int : null,
      category: map['category'] != null ? JobCategory.fromMap(map['category'] as Map<String, dynamic>) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Task(name: $name, importance: $importance, category: $category)';

  @override
  bool operator ==(covariant Task other) {
    if (identical(this, other)) return true;

    return other.name == name && other.importance == importance && other.category == category;
  }

  @override
  int get hashCode => name.hashCode ^ importance.hashCode ^ category.hashCode;
}
