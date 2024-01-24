
import 'package:illinois/service/AppDateTime.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class Course{
  final String? id;
  final String? name;
  final String? key;
  final List<Module>? modules;

  Course({this.id, this.name, this.key, this.modules});

  static Course? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Course(
        id: JsonUtils.stringValue(json['id']),
        name: JsonUtils.stringValue(json['name']),
        key: JsonUtils.stringValue(json['key']),
        modules: Module.listFromJson(JsonUtils.listValue(json['modules'])),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'key': key,
      'modules': Module.listToJson(modules)
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static List<Course> listFromJson(List<dynamic> json) {
    List<Course> courses = [];
    for (dynamic courseJson in json) {
      if (courseJson is Map<String, dynamic>) {
        Course? course = fromJson(courseJson);
        if (course != null) {
          courses.add(course);
        }
      }
    }
    return courses;
  }
}

class UserCourse {
  final String? id;
  final String? timezoneName;
  final int? timezoneOffset;
  final int? streak;
  final List<DateTime>? streakResets;
  final int? pauses;
  final List<DateTime>? pauseUses;

  final Course? course;
  final DateTime? dateDropped;

  UserCourse({this.id, this.timezoneName, this.timezoneOffset, this.streak, this.streakResets, this.pauses, this.pauseUses, this.course, this.dateDropped});

  static UserCourse? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    List<DateTime>? streakResets;
    for (dynamic reset in JsonUtils.listValue(json['streak_resets']) ?? []) {
      if (reset is String) {
        streakResets ??= [];
        DateTime? resetTime = AppDateTime().getDeviceTimeFromUtcTime(DateTimeUtils.dateTimeFromString(reset));
        if (resetTime != null) {
          streakResets.add(resetTime);
        }
      }
    }
    List<DateTime>? pauseUses;
    for (dynamic use in JsonUtils.listValue(json['pause_uses']) ?? []) {
      if (use is String) {
        pauseUses ??= [];
        DateTime? useTime = AppDateTime().getDeviceTimeFromUtcTime(DateTimeUtils.dateTimeFromString(use));
        if (useTime != null) {
          pauseUses.add(useTime);
        }
      }
    }

    return UserCourse(
      id: JsonUtils.stringValue(json['id']),
      timezoneName: JsonUtils.stringValue(json['timezone_name']),
      timezoneOffset: JsonUtils.intValue(json['timezone_offset']),
      streak: JsonUtils.intValue(json['streak']),
      streakResets: streakResets,
      pauses: JsonUtils.intValue(json['pauses']),
      pauseUses: pauseUses,
      course: Course.fromJson(json['course']),
      dateDropped: AppDateTime().dateTimeLocalFromJson(json['date_dropped']),
    );
  }

  Map<String, dynamic> toJson() {
    List<String>? streakResetsJson;
    for (DateTime reset in streakResets ?? []) {
      streakResetsJson ??= [];
      String? resetJson = AppDateTime().dateTimeLocalToJson(reset);
      if (resetJson != null) {
        streakResetsJson.add(resetJson);
      }
    }
    List<String>? pauseUsesJson;
    for (DateTime use in pauseUses ?? []) {
      pauseUsesJson ??= [];
      String? useJson = AppDateTime().dateTimeLocalToJson(use);
      if (useJson != null) {
        pauseUsesJson.add(useJson);
      }
    }

    Map<String, dynamic> json = {
      'timezone_name': timezoneName,
      'timezone_offset': timezoneOffset,
      'streak': streak,
      'streak_resets': streakResetsJson,
      'pauses': pauses,
      'pause_uses': pauseUsesJson,
      'course': course?.toJson(),
      'date_dropped': AppDateTime().dateTimeLocalToJson(dateDropped),
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }
}

class Module{
  final String? id;
  final String? name;
  final String? key;
  final List<Unit>? units;

  Module({this.id, this.name, this.key, this.units});


  static Module? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Module(
        id: JsonUtils.stringValue(json['id']),
        name: JsonUtils.stringValue(json['name']),
        key: JsonUtils.stringValue(json['key']),
        units: Unit.listFromJson(JsonUtils.listValue(json['units'])),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'key': key,
      'units': Unit.listToJson(units)
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static List<Module>? listFromJson(List<dynamic>? jsonList) {
    List<Module>? result;
    if (jsonList != null) {
      result = <Module>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Module.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Module>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

class Unit{
  final String? id;
  final String? name;
  final String? key;
  final List<ScheduleItem>? scheduleItems;
  final List<Content>? contentItems;

  Unit({this.id, this.name, this.key, this.scheduleItems, this.contentItems});

  static Unit? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Unit(
      id: JsonUtils.stringValue(json['id']),
      name: JsonUtils.stringValue(json['name']),
      key: JsonUtils.stringValue(json['key']),
      scheduleItems: ScheduleItem.listFromJson(JsonUtils.listValue(json['schedule'])),
      contentItems: Content.listFromJson(JsonUtils.listValue(json['content'])),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'key': key,
      'schedule': ScheduleItem.listToJson(scheduleItems),
      'content': Content.listToJson(contentItems),
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static List<Unit>? listFromJson(List<dynamic>? jsonList) {
    List<Unit>? result;
    if (jsonList != null) {
      result = <Unit>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Unit.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Unit>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

class UserUnit {
  final String? id;
  final String? courseKey;
  final int? completed;
  final bool? current;

  final Unit? unit;

  final DateTime? lastCompleted;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;

  UserUnit({this.id, this.courseKey, this.completed, this.current, this.unit, this.lastCompleted, this.dateCreated, this.dateUpdated});

  static UserUnit? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return UserUnit(
      id: JsonUtils.stringValue(json['id']),
      courseKey: JsonUtils.stringValue(json['course_key']),
      completed: JsonUtils.intValue(json['completed']),
      current: JsonUtils.boolValue(json['current']),
      unit: Unit.fromJson(json['unit']),
      lastCompleted: AppDateTime().dateTimeLocalFromJson(json['last_completed']),
      dateCreated: AppDateTime().dateTimeLocalFromJson(json['date_created']),
      dateUpdated: AppDateTime().dateTimeLocalFromJson(json['date_updated']),
    );

  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'course_key': courseKey,
      'completed': completed,
      'current': current,
      'unit': unit?.toJson(),
      'last_completed': AppDateTime().dateTimeLocalToJson(lastCompleted),
      'date_created': AppDateTime().dateTimeLocalToJson(dateCreated),
      'date_updated': AppDateTime().dateTimeLocalToJson(dateUpdated),
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }
}

class ScheduleItem{
  final String? name;
  final int? duration;
  final List<UserReference>? userReferences;
  
  final DateTime? dateStarted;
  final DateTime? dateCompleted;

  ScheduleItem({this.name, this.duration, this.userReferences, this.dateStarted, this.dateCompleted});

  static ScheduleItem? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ScheduleItem(
      name: JsonUtils.stringValue(json['name']),
      duration: JsonUtils.intValue(json['duration']),
      userReferences: UserReference.listFromJson(JsonUtils.listValue(json['user_content'])),
      dateStarted: AppDateTime().dateTimeLocalFromJson(json['date_started']),
      dateCompleted: AppDateTime().dateTimeLocalFromJson(json['date_completed']),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'duration': duration,
      'user_content': UserReference.listToJson(userReferences),
      'date_started': AppDateTime().dateTimeLocalToJson(dateStarted),
      'date_completed': AppDateTime().dateTimeLocalToJson(dateCompleted),
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static List<ScheduleItem>? listFromJson(List<dynamic>? jsonList) {
    List<ScheduleItem>? result;
    if (jsonList != null) {
      result = <ScheduleItem>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, ScheduleItem.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<ScheduleItem>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

class UserReference{
  final Reference? reference;
  final Map<String,dynamic>? userData;

  UserReference({this.reference, this.userData,});

  static UserReference? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return UserReference(
      reference: Reference.fromJson(JsonUtils.mapValue('reference')),
      userData: json['user_data'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'reference': reference?.toJson(),
      'user_data': userData,
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static List<UserReference>? listFromJson(List<dynamic>? jsonList) {
    List<UserReference>? result;
    if (jsonList != null) {
      result = <UserReference>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, UserReference.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<UserReference>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

class Reference{
  final String? name;
  final String? type;
  final String? referenceKey;

  Reference({this.name, this.type, this.referenceKey});

  static Reference? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Reference(
      name: JsonUtils.stringValue(json['name']),
      type: JsonUtils.stringValue(json['type']),
      referenceKey: JsonUtils.stringValue(json['reference_key']),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'type': type,
      'reference_key': referenceKey
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }
}

class Content{
  final String? id;
  final String? name;
  final String? key;
  final String? type;
  final String? details;
  final Reference? reference;
  final List<String>? linkedContent;
  bool isComplete;


  Content({this.id, this.name, this.key, this.type, this.details, this.reference, this.linkedContent, this.isComplete = false});

  static Content? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Content(
      id: JsonUtils.stringValue(json['id']),
      name: JsonUtils.stringValue(json['name']),
      key: JsonUtils.stringValue(json['key']),
      type: JsonUtils.stringValue(json['type']),
      details: JsonUtils.stringValue(json['details']),
      reference: Reference.fromJson(JsonUtils.mapValue('reference')),
      linkedContent: JsonUtils.stringListValue(json['linked_content']),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'key': key,
      'type': type,
      'details': details,
      'reference': reference?.toJson(),
      'linked_content': linkedContent,
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static List<Content>? listFromJson(List<dynamic>? jsonList) {
    List<Content>? result;
    if (jsonList != null) {
      result = <Content>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Content.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Content>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}