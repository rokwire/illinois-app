
import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:timezone/timezone.dart' as timezone;
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

  bool isDateStreak(DateTime date, DateTime? firstScheduleItemCompleted, Duration startOfDayOffset, {bool includeToday = false}) {
    if (firstScheduleItemCompleted != null) {
      DateTime normalizedFirstCompleted = firstScheduleItemCompleted.subtract(startOfDayOffset);
      DateTime normalizedNow = DateTime.now().subtract(startOfDayOffset);
      if (!includeToday) {
        normalizedNow = normalizedNow.subtract(const Duration(days: 1));
      }
      if ((_isSameDay(date, normalizedFirstCompleted) || date.isAfter(normalizedFirstCompleted)) && (_isSameDay(date, normalizedNow) || date.isBefore(normalizedNow))) {
        for (DateTime restart in normalizeDateTimes(streakRestarts ?? [], startOfDayOffset + Duration(minutes: 5))) {
          if (_isSameDay(restart, date)) {
            return true;  // part of a streak if a streak was restarted on this day
          }
        }
        for (DateTime reset in normalizeDateTimes(streakResets ?? [], startOfDayOffset + Duration(minutes: 5))) {
          if (_isSameDay(reset, date)) {
            return false; // not part of streak if a streak was reset on this day
          }
        }
        for (DateTime use in normalizeDateTimes(pauseUses ?? [], startOfDayOffset + Duration(minutes: 5))) {
          if (_isSameDay(use, date)) {
            return false; // not part of streak if a pause was used on this day
          }
        }

        return true;  // part of a streak if not in any of the above lists
      }
    }

    return false; // not part of a streak if missing firstScheduleItemCompleted or not between firstScheduleItemCompleted and now
  }

  bool isDatePauseUse(DateTime date, Duration startOfDayOffset, {bool includeToday = false}) {
    DateTime normalizedNow = DateTime.now().subtract(startOfDayOffset);
    if (!includeToday && _isSameDay(date, normalizedNow)) {
      return false;
    }

    for (DateTime use in normalizeDateTimes(pauseUses ?? [], startOfDayOffset + Duration(minutes: 5))) {
      if (_isSameDay(use, date)) {
        return true;
      }
    }

    return false;
  }

  bool _isSameDay(DateTime date, DateTime other) {
    return date.year == other.year && date.month == other.month && date.day == other.day;
  }

  static List<DateTime> normalizeDateTimes(List<DateTime> dateTimes, Duration startOfDayOffset) {
    return List.generate(dateTimes.length, (index) {
      return dateTimes[index].subtract(startOfDayOffset);
    });
  }
}

class Module{
  final String? id;
  final String? name;
  final String? key;
  final List<Unit>? units;

  final CourseStyles? styles;

  Module({this.id, this.name, this.key, this.units, this.styles});


  static Module? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Module(
        id: JsonUtils.stringValue(json['id']),
        name: JsonUtils.stringValue(json['name']),
        key: JsonUtils.stringValue(json['key']),
        units: Unit.listFromJson(JsonUtils.listValue(json['units'])),
        styles: CourseStyles.fromJson(JsonUtils.mapValue(json['styles'] ?? json['display'])),
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

  Unit? nextUnit(UserUnit userUnit) {
    int? currentUnitIndex = units?.indexWhere((moduleUnit) => moduleUnit.key == userUnit.unit?.key);
    if (currentUnitIndex != null && currentUnitIndex >= 0 && currentUnitIndex < units!.length - 1) {
      return units![currentUnitIndex + 1];
    }
    return null;
  }

  Unit? previousUnit(UserUnit userUnit) {
    int? currentUnitIndex = units?.indexWhere((moduleUnit) => moduleUnit.key == userUnit.unit?.key);
    if (currentUnitIndex != null && currentUnitIndex >= 1 && currentUnitIndex < units!.length) {
      return units![currentUnitIndex - 1];
    }
    return null;
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

  int? getActivityNumber(int scheduleIndex) {
    if (scheduleIndex >= 0 && scheduleIndex < (scheduleItems?.length ?? 0)) {
      int activityNumber = 0;
      for (int i = 0; i <= scheduleIndex; i++) {
        ScheduleItem item = scheduleItems![i];
        if (item.isRequired) {
          activityNumber++;
        }
      }
      return activityNumber;
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
  List<UserScheduleItem>? userSchedule;

  final DateTime? dateCreated;
  final DateTime? dateUpdated;

  UserUnit({this.id, this.courseKey, this.moduleKey, this.completed = 0, this.current = false, this.unit, this.dateCreated, this.dateUpdated, this.userSchedule});

  factory UserUnit.emptyFromUnit(Unit unit, String? courseKey, String? moduleKey, {bool current = false}) {
    List<UserScheduleItem> userSchedule = [];
    for (ScheduleItem item in unit.scheduleItems ?? []) {
      List<UserContentReference> userContentReferences = [];
      for (String contentKey in item.contentKeys ?? []) {
        userContentReferences.add(UserContentReference(contentKey: contentKey, complete: false, ids: []));
      }
      userSchedule.add(UserScheduleItem(userContent: userContentReferences));
    }

    return UserUnit(courseKey: courseKey, moduleKey: moduleKey, completed: 0, unit: unit, current: current, userSchedule: userSchedule);
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
      dateCreated: AppDateTime().dateTimeLocalFromJson(json['date_created']),
      dateUpdated: AppDateTime().dateTimeLocalFromJson(json['date_updated']),
      userSchedule: UserScheduleItem.listFromJson(JsonUtils.listValue(json['user_schedule']))
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'course_key': courseKey,
      'module_key': moduleKey,
      'completed': completed,
      'current': current,
      'unit': unit?.toJson(),
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
      for (UserScheduleItem item in userUnit.userSchedule ?? []) {
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

  UserScheduleItem? get currentUserScheduleItem => completed >= 0 && completed < (userSchedule?.length ?? 0) ? (userSchedule?[completed]) : null;
  UserScheduleItem? get lastUserScheduleItem => CollectionUtils.isNotEmpty(userSchedule) ? userSchedule!.last : null;

  bool get isCompleted => completed == (userSchedule?.length ?? -1);
}

class UserScheduleItem{
  List<UserContentReference>? userContent;
  final DateTime? dateStarted;
  final DateTime? dateCompleted;

  UserScheduleItem({this.userContent, this.dateStarted, this.dateCompleted});

  static UserScheduleItem? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return UserScheduleItem(
      userContent: UserContentReference.listFromJson(JsonUtils.listValue(json['user_content'])),
      dateStarted: AppDateTime().dateTimeLocalFromJson(json['date_started']),
      dateCompleted: AppDateTime().dateTimeLocalFromJson(json['date_completed']),
    );
  }

  static List<UserScheduleItem>? listFromJson(List<dynamic>? jsonList) {
    List<UserScheduleItem>? result;
    if (jsonList != null) {
      result = <UserScheduleItem>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, UserScheduleItem.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  bool get isComplete => userContent?.every((uc) => uc.isComplete) ?? false;

  UserContentReference? get firstIncomplete {
    try {
      return userContent?.firstWhere((uc) => uc.isNotComplete);
    } catch (e) {
      if (e is! StateError) {
        debugPrint(e.toString());
      }
    }
    return null;
  }
}

class UserContentReference{
  List<String>? ids;
  String? contentKey;
  bool? complete;

  UserContentReference({this.ids, this.contentKey, this.complete});

  static UserContentReference? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return UserContentReference(
      ids: JsonUtils.listStringsValue(json['ids']),
      contentKey: JsonUtils.stringValue(json['content_key']),
      complete: JsonUtils.boolValue(json['complete']) ?? false,
    );
  }

  static List<UserContentReference>? listFromJson(List<dynamic>? jsonList) {
    List<UserContentReference>? result;
    if (jsonList != null) {
      result = <UserContentReference>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, UserContentReference.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  bool get isComplete => complete ?? false;
  bool get isNotComplete => !isComplete;
}

class ScheduleItem{
  final String? name;
  final int? duration;
  final List<String>? contentKeys;

  ScheduleItem({this.name, this.duration, this.contentKeys});

  static ScheduleItem? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ScheduleItem(
      name: JsonUtils.stringValue(json['name']),
      duration: JsonUtils.intValue(json['duration']),
      contentKeys: JsonUtils.listStringsValue(json['content_keys']),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'duration': duration,
      'content_keys': contentKeys,
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

  bool get isRequired => duration != null;
}

class UserContent{
  static const String completeKey = 'complete';
  static const String experienceKey = 'experience';
  static const String goodExperience = 'good';
  static const String badExperience = 'bad';
  static const String notesKey = 'notes';

  final String? id;
  final String? courseKey;
  final String? moduleKey;
  final String? unitKey;
  final Content? content;
  Map<String,dynamic>? response;

  final DateTime? dateCreated;
  final DateTime? dateUpdated;

  UserContent({this.id, this.courseKey, this.moduleKey, this.unitKey, this.content, this.response, this.dateCreated, this.dateUpdated});

  static UserContent? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return UserContent(
      id: JsonUtils.stringValue(json['id']),
      courseKey: JsonUtils.stringValue(json['course_key']),
      moduleKey: JsonUtils.stringValue(json['module_key']),
      unitKey: JsonUtils.stringValue(json['unit_key']),
      content: Content.fromJson(json['content']),
      response: JsonUtils.mapValue(json['response']),
      dateCreated: AppDateTime().dateTimeLocalFromJson(json['date_created']),
      dateUpdated: AppDateTime().dateTimeLocalFromJson(json['date_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'course_key': courseKey,
      'module_key': moduleKey,
      'unit_key': unitKey,
      'response': response,
      'content': content?.toJson(),
      'date_created': AppDateTime().dateTimeLocalToJson(dateCreated),
      'date_updated': AppDateTime().dateTimeLocalToJson(dateUpdated),
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

  bool get isComplete => response?[completeKey] == true;
  bool get isNotComplete => !isComplete;
}

enum ReferenceType { video, text, pdf, powerpoint, uri, survey, none }

class Reference{
  final String? name;
  final ReferenceType? type;
  final String? referenceKey;

  Reference({this.name, this.type, this.referenceKey});

  static Reference? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Reference(
      name: JsonUtils.stringValue(json['name']),
      type: typeFromString(JsonUtils.stringValue(json['type']) ?? ''),
      referenceKey: JsonUtils.stringValue(json['reference_key']),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'type': stringFromType(),
      'reference_key': referenceKey
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static ReferenceType typeFromString(String value) {
    switch (value) {
      case 'video': return ReferenceType.video;
      case 'text': return ReferenceType.text;
      case 'powerpoint': return ReferenceType.powerpoint;
      case 'pdf': return ReferenceType.pdf;
      case 'uri': return ReferenceType.uri;
      case 'survey': return ReferenceType.survey;
      default: return ReferenceType.none;
    }
  }

  String stringFromType() {
    switch (type) {
      case ReferenceType.video: return 'video';
      case ReferenceType.text: return 'text';
      case ReferenceType.powerpoint: return 'powerpoint';
      case ReferenceType.pdf: return 'pdf';
      case ReferenceType.uri: return 'uri';
      case ReferenceType.survey: return 'survey';
      default: return '';
    }
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

  final CourseStyles? styles;

  Content({this.id, this.name, this.key, this.type, this.details, this.reference, this.linkedContent, this.styles});

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
      reference: Reference.fromJson(JsonUtils.mapValue(json['reference'])),
      linkedContent: JsonUtils.stringListValue(json['linked_content']),
      styles: CourseStyles.fromJson(JsonUtils.mapValue(json['styles'] ?? json['display'])),
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

  List<Content>? getLinkedContent(Course? course) {
    if (course != null) {
      List<Content> linkedContentItems = [];
      for (String linkedContentKey in linkedContent ?? []) {
        Content? linked = course.searchByKey(contentKey: linkedContentKey);
        if (linked != null) {
          linkedContentItems.add(linked);
        }
      }
      return linkedContentItems;
    }
    return null;
  }
}

class UserResponse {
  final String unitKey;
  final String contentKey;
  Map<String, dynamic>? response;

  UserResponse({required this.unitKey, required this.contentKey, this.response});
}

// CourseConfig

class CourseConfig {
  final String? id;
  final String? courseKey;
  final int? initialPauses;
  final int? maxPauses;
  final int? pauseProgressReward;

  final int? streaksProcessTime;
  final List<CourseNotification>? notifications;
  final String? timezoneName;
  final int? timezoneOffset;

  CourseConfig({this.id, this.courseKey, this.initialPauses, this.maxPauses, this.pauseProgressReward,
    this.streaksProcessTime, this.notifications, this.timezoneName, this.timezoneOffset});

  static const String userTimezone = "user";

  static CourseConfig? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return CourseConfig(
      id: JsonUtils.stringValue(json['id']),
      courseKey: JsonUtils.stringValue(json['course_key']),
      initialPauses: JsonUtils.intValue(json['initial_pauses']),
      maxPauses: JsonUtils.intValue(json['max_pauses']),
      pauseProgressReward: JsonUtils.intValue(json['pause_progress_reward']),
      streaksProcessTime: JsonUtils.intValue(json['streaks_notifications_config']?['streaks_process_time']),
      notifications: CourseNotification.listFromJson(JsonUtils.listValue(json['streaks_notifications_config']?['notifications'])),
      timezoneName: JsonUtils.stringValue(json['streaks_notifications_config']?['timezone_name']),
      timezoneOffset: JsonUtils.intValue(json['streaks_notifications_config']?['timezone_offset']),
    );
  }

  bool get usesUserTimezone => timezoneName == userTimezone;

  int? get finalNotificationTime => CollectionUtils.isNotEmpty(notifications) ? notifications!.last.processTime : null;

  DateTime? nextScheduleItemUnlockTime({bool inUtc = false}) => streaksProcessTime != null ? _nextTime(streaksProcessTime!, inUtc: inUtc) : null;

  DateTime? nextFinalNotificationTime({bool inUtc = false}) => finalNotificationTime != null ? _nextTime(finalNotificationTime!, inUtc: inUtc) : null;

  DateTime? _nextTime(int timeInSeconds, {bool inUtc = false}) {
    timezone.Location location = DateTimeLocal.timezoneLocal;
    DateTime now = DateTime.now();
    if (!usesUserTimezone) {
      if (StringUtils.isNotEmpty(timezoneName)) {
        return null;
      }
      location = timezone.getLocation(timezoneName!);
      now = DateTimeUtils.nowTimezone(location);
    }
    int nowLocalSeconds = 3600*now.hour;

    DateTime next = timezone.TZDateTime(location, now.year, now.month, now.day, timeInSeconds ~/ 3600, 0, 0);
    if (inUtc) {
      next = next.toUtc();
    }
    if (nowLocalSeconds > timeInSeconds) {
      // go forward one day if the current moment is after the unlock time in the current day
      next = next.add(Duration(days: 1));
    }
    return next;
  }
}

class CourseNotification {
  final int? processTime;

  CourseNotification({this.processTime});

  static CourseNotification? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return CourseNotification(
      processTime: JsonUtils.intValue(json['process_time']),
    );
  }

  static List<CourseNotification>? listFromJson(List<dynamic>? jsonList) {
    List<CourseNotification>? result;
    if (jsonList != null) {
      result = <CourseNotification>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CourseNotification.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

// CourseStyles

class CourseStyles {
  final Map<String, dynamic>? colors;
  final Map<String, dynamic>? images;
  final Map<String, dynamic>? strings;

  CourseStyles({this.colors, this.images, this.strings});

  static CourseStyles? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return CourseStyles(
      colors: JsonUtils.mapValue(json['colors']),
      images: JsonUtils.mapValue(json['images']),
      strings: JsonUtils.mapValue(json['strings']),
    );
  }
}
