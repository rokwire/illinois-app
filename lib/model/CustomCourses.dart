
import 'package:flutter/cupertino.dart';
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

  dynamic searchByKey({String? moduleKey, String? unitKey, String? contentKey}) {
    if (moduleKey != null) {
      try {
        return modules?.firstWhere((module) => module.key == moduleKey);
      } catch (e) {
        if (e is! StateError) {
          debugPrint(e.toString());
        }
      }
    } else if (unitKey != null || contentKey != null) {
      for (Module module in modules ?? []) {
        dynamic item = module.searchByKey(unitKey: unitKey, contentKey: contentKey);
        if (item != null) {
          return item;
        }
      }
    }
    return null;
  }
}

class UserCourse {
  final String? id;
  final String? timezoneName;
  final int? timezoneOffset;
  final int? streak;
  List<DateTime>? streakResets;
  List<DateTime>? streakRestarts;
  final int? pauses;
  List<DateTime>? pauseUses;

  final Course? course;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;
  final DateTime? dateDropped;

  UserCourse({this.id, this.timezoneName, this.timezoneOffset, this.streak, this.streakResets, this.streakRestarts, this.pauses, this.pauseUses, this.course, this.dateCreated, this.dateUpdated, this.dateDropped});

  static UserCourse? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return UserCourse(
      id: JsonUtils.stringValue(json['id']),
      timezoneName: JsonUtils.stringValue(json['timezone_name']),
      timezoneOffset: JsonUtils.intValue(json['timezone_offset']),
      streak: JsonUtils.intValue(json['streak']),
      streakResets: deviceTimeListFromJson(json['streak_resets']),
      streakRestarts: deviceTimeListFromJson(json['streak_restarts']),
      pauses: JsonUtils.intValue(json['pauses']),
      pauseUses: deviceTimeListFromJson(json['pause_uses']),
      course: Course.fromJson(json['course']),
      dateCreated: AppDateTime().dateTimeLocalFromJson(json['date_created']),
      dateUpdated: AppDateTime().dateTimeLocalFromJson(json['date_updated']),
      dateDropped: AppDateTime().dateTimeLocalFromJson(json['date_dropped']),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'timezone_name': timezoneName,
      'timezone_offset': timezoneOffset,
      'streak': streak,
      'streak_resets': deviceTimeListToJson(streakResets),
      'streak_restarts': deviceTimeListToJson(streakRestarts),
      'pauses': pauses,
      'pause_uses': deviceTimeListToJson(pauseUses),
      'course': course?.toJson(),
      'date_created': AppDateTime().dateTimeLocalToJson(dateCreated),
      'date_updated': AppDateTime().dateTimeLocalToJson(dateUpdated),
      'date_dropped': AppDateTime().dateTimeLocalToJson(dateDropped),
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static List<UserCourse> listFromJson(List<dynamic> json) {
    List<UserCourse> userCourses = [];
    for (dynamic userCourseJson in json) {
      if (userCourseJson is Map<String, dynamic>) {
        UserCourse? userCourse = fromJson(userCourseJson);
        if (userCourse != null) {
          userCourses.add(userCourse);
        }
      }
    }
    return userCourses;
  }

  static List<DateTime>? deviceTimeListFromJson(dynamic value) {
    if (value != null) {
      List<DateTime> times = [];
      for (dynamic timeJson in JsonUtils.listValue(value) ?? []) {
        if (timeJson is String) {
          DateTime? time = AppDateTime().getDeviceTimeFromUtcTime(DateTimeUtils.dateTimeFromString(timeJson));
          if (time != null) {
            times.add(time);
          }
        }
      }
      return times;
    }
    return null;
  }

  List<String>? deviceTimeListToJson(List<DateTime>? times) {
    if (times != null) {
      List<String> timesJson = [];
      for (DateTime time in times) {
        String? timeJson = AppDateTime().dateTimeLocalToJson(time);
        if (timeJson != null) {
          timesJson.add(timeJson);
        }
      }
      return timesJson;
    }
    return null;
  }

  bool isDateStreak(DateTime date, DateTime? firstScheduleItemCompleted, Duration startOfDay, {bool includeToday = false}) {
    if (firstScheduleItemCompleted != null) {
      DateTime normalizedFirstCompleted = firstScheduleItemCompleted.subtract(startOfDay);
      DateTime normalizedNow = DateTime.now().subtract(startOfDay);
      if (!includeToday) {
        normalizedNow = normalizedNow.subtract(const Duration(days: 1));
      }
      if ((_isSameDay(date, normalizedFirstCompleted) || date.isAfter(normalizedFirstCompleted)) && (_isSameDay(date, normalizedNow) || date.isBefore(normalizedNow))) {
        for (DateTime restart in normalizeDateTimes(streakRestarts ?? [], startOfDay)) {
          if (_isSameDay(restart, date)) {
            return true;  // part of a streak if a streak was restarted on this day
          }
        }
        for (DateTime reset in normalizeDateTimes(streakResets ?? [], startOfDay)) {
          if (_isSameDay(reset, date)) {
            return false; // not part of streak if a streak was reset on this day
          }
        }
        for (DateTime use in normalizeDateTimes(pauseUses ?? [], startOfDay)) {
          if (_isSameDay(use, date)) {
            return false; // not part of streak if a pause was used on this day
          }
        }

        return true;  // part of a streak if not in any of the above lists
      }
    }

    return false; // not part of a streak if missing firstScheduleItemCompleted or not between firstScheduleItemCompleted and now
  }

  bool isDatePauseUse(DateTime date, Duration startOfDay, {bool includeToday = false}) {
    DateTime normalizedNow = DateTime.now().subtract(startOfDay);
    if (!includeToday && _isSameDay(date, normalizedNow)) {
      return false;
    }

    for (DateTime use in normalizeDateTimes(pauseUses ?? [], startOfDay)) {
      if (_isSameDay(use, date)) {
        return true;
      }
    }

    return false;
  }

  bool _isSameDay(DateTime date, DateTime other) {
    return date.year == other.year && date.month == other.month && date.day == other.day;
  }

  static List<DateTime> normalizeDateTimes(List<DateTime> dateTimes, Duration startOfDay) {
    return List.generate(dateTimes.length, (index) => dateTimes[index].subtract(startOfDay));
  }
}

class Module{
  final String? id;
  final String? name;
  final String? key;
  final List<Unit>? units;

  final CourseDisplay? display;

  Module({this.id, this.name, this.key, this.units, this.display});


  static Module? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Module(
        id: JsonUtils.stringValue(json['id']),
        name: JsonUtils.stringValue(json['name']),
        key: JsonUtils.stringValue(json['key']),
        units: Unit.listFromJson(JsonUtils.listValue(json['units'])),
        display: CourseDisplay.fromJson(JsonUtils.mapValue(json['display'])),
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

  dynamic searchByKey({String? unitKey, String? contentKey}) {
    if (unitKey != null) {
      try {
        return units?.firstWhere((unit) => unit.key == unitKey);
      } catch (e) {
        if (e is! StateError) {
          debugPrint(e.toString());
        }
      }
    } else if (contentKey != null) {
      for (Unit unit in units ?? []) {
        Content? content = unit.searchByKey(contentKey: contentKey);
        if (content != null) {
          return content;
        }
      }
    }
    return null;
  }
}

class Unit{
  final String? id;
  final String? name;
  final String? key;
  final int? scheduleStart;
  final List<ScheduleItem>? scheduleItems;
  final List<Content>? contentItems;

  Unit({this.id, this.name, this.key, this.scheduleStart, this.scheduleItems, this.contentItems});

  static Unit? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Unit(
      id: JsonUtils.stringValue(json['id']),
      name: JsonUtils.stringValue(json['name']),
      key: JsonUtils.stringValue(json['key']),
      scheduleStart: JsonUtils.intValue(json['schedule_start']),
      scheduleItems: ScheduleItem.listFromJson(JsonUtils.listValue(json['schedule'])),
      contentItems: Content.listFromJson(JsonUtils.listValue(json['content'])),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'key': key,
      'schedule_start': scheduleStart,
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

  dynamic searchByKey({String? contentKey}) {
    if (contentKey != null) {
      try {
        return contentItems?.firstWhere((content) => content.key == contentKey);
      } catch (e) {
        if (e is! StateError) {
          debugPrint(e.toString());
        }
      }
    }
    return null;
  }

  List<Content>? get resourceContent => contentItems?.where((item) => item.type == 'resource').toList();
}

class UserUnit {
  final String? id;
  final String? courseKey;
  final String? moduleKey;
  final int completed;
  final bool current;

  final Unit? unit;

  final DateTime? lastCompleted;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;

  UserUnit({this.id, this.courseKey, this.moduleKey, this.completed = 0, this.current = false, this.unit, this.lastCompleted, this.dateCreated, this.dateUpdated});

  factory UserUnit.emptyFromUnit(Unit unit, String courseKey, {bool current = false}) {
    return UserUnit(courseKey: courseKey, completed: unit.scheduleStart ?? 0, unit: unit, current: current);
  }

  static UserUnit? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return UserUnit(
      id: JsonUtils.stringValue(json['id']),
      courseKey: JsonUtils.stringValue(json['course_key']),
      moduleKey: JsonUtils.stringValue(json['module_key']),
      completed: JsonUtils.intValue(json['completed']) ?? 0,
      current: JsonUtils.boolValue(json['current']) ?? false,
      unit: Unit.fromJson(json['unit']),
      lastCompleted: AppDateTime().dateTimeLocalFromJson(json['last_completed']),
      dateCreated: AppDateTime().dateTimeLocalFromJson(json['date_created']),
      dateUpdated: AppDateTime().dateTimeLocalFromJson(json['date_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'course_key': courseKey,
      'module_key': moduleKey,
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

  static List<UserUnit> listFromJson(List<dynamic> json) {
    List<UserUnit> userUnits = [];
    for (dynamic userUnitJson in json) {
      if (userUnitJson is Map<String, dynamic>) {
        UserUnit? userUnit = fromJson(userUnitJson);
        if (userUnit != null) {
          userUnits.add(userUnit);
        }
      }
    }
    return userUnits;
  }

  static DateTime? firstScheduleItemCompletionFromList(List<UserUnit> userUnits) {
    DateTime? firstCompleted;
    for (UserUnit userUnit in userUnits) {
      for (ScheduleItem item in userUnit.unit?.scheduleItems ?? []) {
        if (item.dateCompleted != null) {
          firstCompleted ??= item.dateCompleted;
          if (item.dateCompleted!.isBefore(firstCompleted!)) {
            firstCompleted = item.dateCompleted;
          }
        }
      }
    }
    return firstCompleted;
  }
}

class ScheduleItem{
  final String? name;
  final int? duration;
  final List<UserContent>? userContent;
  
  final DateTime? dateStarted;
  final DateTime? dateCompleted;

  ScheduleItem({this.name, this.duration, this.userContent, this.dateStarted, this.dateCompleted});

  static ScheduleItem? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ScheduleItem(
      name: JsonUtils.stringValue(json['name']),
      duration: JsonUtils.intValue(json['duration']),
      userContent: UserContent.listFromJson(JsonUtils.listValue(json['user_content'])),
      dateStarted: AppDateTime().dateTimeLocalFromJson(json['date_started']),
      dateCompleted: AppDateTime().dateTimeLocalFromJson(json['date_completed']),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'duration': duration,
      'user_content': UserContent.listToJson(userContent),
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

  bool get isComplete => dateCompleted != null;
}

class UserContent{
  final String? contentKey;
  final Map<String,dynamic>? userData;

  UserContent({this.contentKey, this.userData,});

  static UserContent? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return UserContent(
      contentKey: JsonUtils.stringValue(json['content_key']),
      userData: json['user_data'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'content_key': contentKey,
      'user_data': userData,
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static List<UserContent>? listFromJson(List<dynamic>? jsonList) {
    List<UserContent>? result;
    if (jsonList != null) {
      result = <UserContent>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, UserContent.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<UserContent>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  bool get hasData => userData?.isNotEmpty ?? false;
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

  final CourseDisplay? display;

  Content({this.id, this.name, this.key, this.type, this.details, this.reference, this.linkedContent, this.display});

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
      display: CourseDisplay.fromJson(JsonUtils.mapValue(json['display'])),
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

// CourseConfig

class CourseConfig {
  final String? id;
  final String? courseKey;
  final int? initialPauses;
  final int? maxPauses;
  final int? pauseRewardStreak;
  final int? streaksProcessTime;

  CourseConfig({this.id, this.courseKey, this.initialPauses, this.maxPauses, this.pauseRewardStreak, this.streaksProcessTime});

  static CourseConfig? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return CourseConfig(
      id: JsonUtils.stringValue(json['id']),
      courseKey: JsonUtils.stringValue(json['course_key']),
      initialPauses: JsonUtils.intValue(json['initial_pauses']),
      maxPauses: JsonUtils.intValue(json['max_pauses']),
      pauseRewardStreak: JsonUtils.intValue(json['pause_reward_streak']),
      streaksProcessTime: JsonUtils.intValue(json['streaks_notifications_config']?['streaks_process_time']),
    );
  }
}

// CourseDisplay

class CourseDisplay {
  final String? primaryColor;
  final String? accentColor;
  final String? completeColor;
  final String? incompleteColor;
  final String? icon;

  CourseDisplay({this.primaryColor, this.accentColor, this.completeColor, this.incompleteColor, this.icon});

  static CourseDisplay? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return CourseDisplay(
      primaryColor: JsonUtils.stringValue(json['primary_color']),
      accentColor: JsonUtils.stringValue(json['accent_color']),
      completeColor: JsonUtils.stringValue(json['complete_color']),
      incompleteColor: JsonUtils.stringValue(json['incomplete_color']),
      icon: JsonUtils.stringValue(json['icon']),
    );
  }
}
