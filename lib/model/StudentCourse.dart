import 'package:illinois/model/Building.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/utils/utils.dart';

// StudentCourse

class StudentCourse with Explore {
  final String? title;
  final String? shortName;
  final String? number;
  final String? instructionMethod;
  final StudentCourseSection? section;

  StudentCourse({this.title, this.shortName, this.number, this.instructionMethod, this.section});

  static StudentCourse? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? StudentCourse(
      title: JsonUtils.stringValue(json['coursetitle']),
      shortName: JsonUtils.stringValue(json['courseshortname']),
      number: JsonUtils.stringValue(json['coursenumber']),
      instructionMethod: JsonUtils.stringValue(json['instructionmethod']),
      section: StudentCourseSection.fromJson(JsonUtils.mapValue(json['coursesection'])),
    ) : null;
  }

  toJson() => {
    'coursetitle': title,
    'courseshortname': shortName,
    'coursenumber': number,
    'instructionmethod': instructionMethod,
    'coursesection': section?.toJson(),
  };

  bool get hasValidLocation => section?.building?.hasValidLocation ?? false;

  String get detail => '$shortName ($number) $instructionMethod';
  
  @override
  bool operator==(Object other) =>
    (other is StudentCourse) &&
    (title == other.title) &&
    (shortName == other.shortName) &&
    (number == other.number) &&
    (instructionMethod == other.instructionMethod) &&
    (section == other.section);

  @override
  int get hashCode =>
    (title?.hashCode ?? 0) ^
    (shortName?.hashCode ?? 0) ^
    (number?.hashCode ?? 0) ^
    (instructionMethod?.hashCode ?? 0) ^
    (section?.hashCode ?? 0);

  // Explore implementation

  @override String? get exploreId => number;
  @override String? get exploreTitle => title ?? '';
  @override String? get exploreDescription => null;
  @override DateTime? get exploreDateTimeUtc => null;
  @override String? get exploreImageURL => null;
  @override ExploreLocation? get exploreLocation => section?.building?.exploreLocation;

  // List<StudentCourse>

  static List<StudentCourse>? listFromJson(List<dynamic>? jsonList) {
    List<StudentCourse>? values;
    if (jsonList != null) {
      values = <StudentCourse>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, StudentCourse.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<StudentCourse>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (StudentCourse value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

// StudentCourseSection

class StudentCourseSection {
  final String? buildingId;
  final String? buildingName;
  final String? room;

  final String? instructionType;
  final String? instructor;
  final String? sectionId;

  final String? days;
  final String? startTime;
  final String? endTime;
  final String? meetingDates;

  final Building? building;

  StudentCourseSection({
    this.buildingId, this.buildingName, this.room,
    this.instructionType, this.instructor, this.sectionId,
    this.days, this.startTime, this.endTime, this.meetingDates,
    this.building
  });

  static StudentCourseSection? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? StudentCourseSection(
      buildingId: JsonUtils.stringValue(json['buildingid']),
      buildingName: JsonUtils.stringValue(json['buildingname']),
      room: JsonUtils.stringValue(json['room']),

      instructionType: JsonUtils.stringValue(json['instructiontype']),
      instructor: JsonUtils.stringValue(json['instructor']),
      sectionId: JsonUtils.stringValue(json['course_section']),

      days: JsonUtils.stringValue(json['days']),
      startTime: JsonUtils.stringValue(MapUtils.get2(json, ['starttime', 'start_time'])),
      endTime: JsonUtils.stringValue(MapUtils.get2(json, ['endtime', 'end_time'])),
      meetingDates: JsonUtils.stringValue(json['meeting_dates_or_range']),
      
      building: Building.fromJson(JsonUtils.mapValue(json['building'])),
    ) : null;
  }

  toJson() => {
    'buildingid': buildingId,
    'buildingname': buildingName,
    'room': room,

    'instructiontype': instructionType,
    'instructor': instructor,
    'course_section': sectionId,

    'days': days,
    'starttime': startTime,
    'endtime': endTime,
    'meeting_dates_or_range': meetingDates,

    'building': building?.toJson(),
  };

  @override
  bool operator==(Object other) =>
    (other is StudentCourseSection) &&
    
    (buildingName == other.buildingName) &&
    (room == other.room) &&

    (instructionType == other.instructionType) &&
    (instructor == other.instructor) &&
    (sectionId == other.sectionId) &&

    (days == other.days) &&
    (startTime == other.startTime) &&
    (endTime == other.endTime) &&

    (building == other.building);

  @override
  int get hashCode =>
    (buildingName?.hashCode ?? 0) ^
    (room?.hashCode ?? 0) ^

    (instructionType?.hashCode ?? 0) ^
    (instructor?.hashCode ?? 0) ^
    (sectionId?.hashCode ?? 0) ^

    (days?.hashCode ?? 0) ^
    (startTime?.hashCode ?? 0) ^
    (endTime?.hashCode ?? 0) ^

    (building?.hashCode ?? 0);

  static List<StudentCourseSection>? listFromJson(List<dynamic>? jsonList) {
    List<StudentCourseSection>? values;
    if (jsonList != null) {
      values = <StudentCourseSection>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, StudentCourseSection.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<StudentCourseSection>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (StudentCourseSection value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

// StudentCourseTerm

class StudentCourseTerm {
  final String? id;
  final String? name;
  final bool? isCurrent;
  
  StudentCourseTerm({this.id, this.name, this.isCurrent});

  static StudentCourseTerm? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? StudentCourseTerm(
      id: JsonUtils.stringValue(json['termid']),
      name: JsonUtils.stringValue(json['term']),
      isCurrent: JsonUtils.boolValue(json['is_current']),
    ) : null;
  }

  toJson() => {
    'termid': id,
    'term': name,
    'is_current': isCurrent,
  };

  @override
  bool operator==(Object other) =>
    (other is StudentCourseTerm) &&
    (id == other.id) &&
    (name == other.name) &&
    (isCurrent == other.isCurrent);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (isCurrent?.hashCode ?? 0);

  static List<StudentCourseTerm>? listFromJson(List<dynamic>? jsonList) {
    List<StudentCourseTerm>? values;
    if (jsonList != null) {
      values = <StudentCourseTerm>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, StudentCourseTerm.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<StudentCourseTerm>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (StudentCourseTerm value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  static StudentCourseTerm? findInList(List<StudentCourseTerm>? values, {bool? isCurrent, String? id}) {
    if (values != null) {
      for (StudentCourseTerm value in values) {
        if ((isCurrent != null) && (value.isCurrent == isCurrent)) {
          return value;
        }
        if ((id != null) && (value.id == id)) {
          return value;
        }
      }
    }
    return null;
  }
}
