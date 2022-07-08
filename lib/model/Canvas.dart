/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:illinois/service/AppDateTime.dart';
import 'package:rokwire_plugin/utils/utils.dart';

////////////////////////////////
// CanvasCourse

class CanvasCourse {
  final int? id;
  final String? name;
  final bool? accessRestrictedByDate;

  CanvasCourse({this.id, this.name, this.accessRestrictedByDate});

  static CanvasCourse? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? CanvasCourse(
      id: JsonUtils.intValue(json['id']),
      name: JsonUtils.stringValue(json['name']),
      accessRestrictedByDate: JsonUtils.boolValue(json['access_restricted_by_date']),
    ) : null;
  }

  static List<CanvasCourse>? listFromJson(List<dynamic>? jsonList) {
    if (CollectionUtils.isEmpty(jsonList)) {
      return null;
    }
    List<CanvasCourse>? courses;
    if (jsonList != null) {
      courses = <CanvasCourse>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(courses, CanvasCourse.fromJson(jsonEntry));
      }
    }
    return courses;
  }
}

////////////////////////////////
// CanvasEnrollment

class CanvasEnrollment {
  final int? id;
  final CanvasEnrollmentType? type;
  final CanvasGrade? grade;

  CanvasEnrollment({this.id, this.type, this.grade});

  static CanvasEnrollment? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? CanvasEnrollment(
      id: JsonUtils.intValue(json['id']),
      type: CanvasEnrollment.typeFromString(JsonUtils.stringValue(json['type'])),
      grade: CanvasGrade.fromJson(JsonUtils.mapValue(json['grades'])),
    ) : null;
  }

  static List<CanvasEnrollment>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasEnrollment>? result;
    if (jsonList != null) {
      result = <CanvasEnrollment>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasEnrollment.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<CanvasEnrollment>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  static CanvasEnrollmentType? typeFromString(String? value) {
    switch (value) {
      case 'StudentEnrollment':
        return CanvasEnrollmentType.student;
      case 'TeacherEnrollment':
        return CanvasEnrollmentType.teacher;
      case 'TaEnrollment':
        return CanvasEnrollmentType.ta;
      case 'DesignerEnrollment':
        return CanvasEnrollmentType.designer;
      case 'ObserverEnrollment':
        return CanvasEnrollmentType.observer;
      default:
        return null;
    }
  }
}

////////////////////////////////
// CanvasEnrollmentType

enum CanvasEnrollmentType { student, teacher, ta, designer, observer }

////////////////////////////////
// CanvasGrade

class CanvasGrade {
  final double? currentScore;

  CanvasGrade({this.currentScore});

  static CanvasGrade? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? CanvasGrade(
      currentScore: JsonUtils.doubleValue(json['current_score']),
    ) : null;
  }
}

////////////////////////////////
// CanvasUser

class CanvasUser {
  final int? id;
  final String? name;
  final String? sortableName;
  final String? lastName;
  final String? firstName;
  final String? shortName;
  final String? sisUserId;
  final List<CanvasEnrollment>? enrollments;
  final String? email;

  CanvasUser({this.id, this.name, this.sortableName, this.lastName, this.firstName, this.shortName,
    this.sisUserId, this.enrollments, this.email});

  static CanvasUser? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasUser(
            id: JsonUtils.intValue(json['id']),
            name: JsonUtils.stringValue(json['name']),
            sortableName: JsonUtils.stringValue(json['sortable_name']),
            lastName: JsonUtils.stringValue(json['last_name']),
            firstName: JsonUtils.stringValue(json['first_name']),
            shortName: JsonUtils.stringValue(json['short_name']),
            sisUserId: JsonUtils.stringValue(json['sis_user_id']),
            enrollments: CanvasEnrollment.listFromJson(JsonUtils.listValue(json['enrollments'])),
            email: JsonUtils.stringValue(json['email']),
          )
        : null;
  }

  static List<CanvasUser>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasUser>? result;
    if (jsonList != null) {
      result = <CanvasUser>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasUser.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

////////////////////////////////
// CanvasAssignmentDate

class CanvasAssignmentDate {
  final int? id;
  final bool? base;
  final String? title;
  final DateTime? dueAt;
  final DateTime? lockAt;
  final DateTime? unlockAt;

  CanvasAssignmentDate({this.id, this.base, this.title, this.dueAt, this.lockAt, this.unlockAt});

  static CanvasAssignmentDate? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasAssignmentDate(
            id: JsonUtils.intValue(json['id']),
            base: JsonUtils.boolValue(json['base']),
            title: JsonUtils.stringValue(json['title']),
            dueAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['due_at']), isUtc: true),
            lockAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['lock_at']), isUtc: true),
            unlockAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['unlock_at']), isUtc: true))
        : null;
  }

  bool operator ==(o) =>
      (o is CanvasAssignmentDate) &&
      (o.id == id) &&
      (o.base == base) &&
      (o.title == title) &&
      (o.dueAt == dueAt) &&
      (o.lockAt == lockAt) &&
      (o.unlockAt == unlockAt);

  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (base?.hashCode ?? 0) ^
      (title?.hashCode ?? 0) ^
      (dueAt?.hashCode ?? 0) ^
      (lockAt?.hashCode ?? 0) ^
      (unlockAt?.hashCode ?? 0);

  static List<CanvasAssignmentDate>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasAssignmentDate>? result;
    if (jsonList != null) {
      result = <CanvasAssignmentDate>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasAssignmentDate.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

////////////////////////////////
// CanvasTurnitinSettings

class CanvasTurnitinSettings {
  final String? originalityReportVisibility;
  final bool? sPaperCheck;
  final bool? internetCheck;
  final bool? journalCheck;
  final bool? excludeBiblio;
  final bool? excludeQuoted;
  final String? excludeSmallMatchesType;
  final int? excludeSmallMatchesValue;

  CanvasTurnitinSettings({this.originalityReportVisibility, this.sPaperCheck, this.internetCheck, this.journalCheck, this.excludeBiblio, 
    this.excludeQuoted, this.excludeSmallMatchesType, this.excludeSmallMatchesValue});

  static CanvasTurnitinSettings? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasTurnitinSettings(
            originalityReportVisibility: JsonUtils.stringValue(json['originality_report_visibility']),
            sPaperCheck: JsonUtils.boolValue(json['s_paper_check']),
            internetCheck: JsonUtils.boolValue(json['internet_check']),
            journalCheck: JsonUtils.boolValue(json['journal_check']),
            excludeBiblio: JsonUtils.boolValue(json['exclude_biblio']),
            excludeQuoted: JsonUtils.boolValue(json['exclude_quoted']),
            excludeSmallMatchesType: JsonUtils.stringValue(json['exclude_small_matches_type']),
            excludeSmallMatchesValue: JsonUtils.intValue(json['exclude_small_matches_value']))
        : null;
  }

  bool operator ==(o) =>
      (o is CanvasTurnitinSettings) &&
      (o.originalityReportVisibility == originalityReportVisibility) &&
      (o.sPaperCheck == sPaperCheck) &&
      (o.internetCheck == internetCheck) &&
      (o.journalCheck == journalCheck) &&
      (o.excludeBiblio == excludeBiblio) &&
      (o.excludeQuoted == excludeQuoted) &&
      (o.excludeSmallMatchesType == excludeSmallMatchesType) &&
      (o.excludeSmallMatchesValue == excludeSmallMatchesValue);

  int get hashCode =>
      (originalityReportVisibility?.hashCode ?? 0) ^
      (sPaperCheck?.hashCode ?? 0) ^
      (internetCheck?.hashCode ?? 0) ^
      (journalCheck?.hashCode ?? 0) ^
      (excludeBiblio?.hashCode ?? 0) ^
      (excludeQuoted?.hashCode ?? 0) ^
      (excludeSmallMatchesType?.hashCode ?? 0) ^
      (excludeSmallMatchesValue?.hashCode ?? 0);
}

////////////////////////////////
// CanvasNeedsGradingCount

class CanvasNeedsGradingCount {
  final String? sectionId;
  final int? needsGradingCount;

  CanvasNeedsGradingCount({this.sectionId, this.needsGradingCount});

  static CanvasNeedsGradingCount? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasNeedsGradingCount(
            sectionId: JsonUtils.stringValue(json['section_id']), needsGradingCount: JsonUtils.intValue(json['needs_grading_count']))
        : null;
  }

  bool operator ==(o) => (o is CanvasNeedsGradingCount) && (o.sectionId == sectionId) && (o.needsGradingCount == needsGradingCount);

  int get hashCode => (sectionId?.hashCode ?? 0) ^ (needsGradingCount?.hashCode ?? 0);

  static List<CanvasNeedsGradingCount>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasNeedsGradingCount>? result;
    if (jsonList != null) {
      result = <CanvasNeedsGradingCount>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasNeedsGradingCount.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

////////////////////////////////
// CanvasScoreStatistic

class CanvasScoreStatistic {
  final int? min;
  final int? max;
  final int? mean;

  CanvasScoreStatistic({this.min, this.max, this.mean});

  static CanvasScoreStatistic? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasScoreStatistic(
            min: JsonUtils.intValue(json['min']), max: JsonUtils.intValue(json['max']), mean: JsonUtils.intValue(json['mean']))
        : null;
  }

  bool operator ==(o) => (o is CanvasScoreStatistic) && (o.min == min) && (o.max == max) && (o.mean == mean);

  int get hashCode => (min?.hashCode ?? 0) ^ (max?.hashCode ?? 0) ^ (mean?.hashCode ?? 0);
}

////////////////////////////////
// CanvasAssignment

class CanvasAssignment {
  final int? id;
  final String? name;
  final DateTime? dueAt;
  final int? courseId;
  final String? htmlUrl;
  final int? position;

  CanvasAssignment({this.id, this.name, this.dueAt, this.courseId, this.htmlUrl, this.position});

  static CanvasAssignment? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasAssignment(
            id: JsonUtils.intValue(json['id']),
            name: JsonUtils.stringValue(json['name']),
            dueAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['due_at']), isUtc: true),
            courseId: JsonUtils.intValue(json['course_id']),
            htmlUrl: JsonUtils.stringValue(json['html_url']),
            position: JsonUtils.intValue(json['position']))
        : null;
  }

  DateTime? get dueAtLocal {
    return AppDateTime().getDeviceTimeFromUtcTime(dueAt);
  }

  String? get dueDisplayDateTime {
    String? dueDisplayDate = AppDateTime().formatDateTime(dueAtLocal, format: 'MMM d, h:mma');
    return dueDisplayDate;
  }

  static List<CanvasAssignment>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasAssignment>? result;
    if (jsonList != null) {
      result = <CanvasAssignment>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasAssignment.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

////////////////////////////////
// CanvasAssignmentGroup

class CanvasAssignmentGroup {
  final int? id;
  final List<CanvasAssignment>? assignments;

  CanvasAssignmentGroup({this.id, this.assignments});

  static CanvasAssignmentGroup? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasAssignmentGroup(
            id: JsonUtils.intValue(json['id']),
            assignments: CanvasAssignment.listFromJson(json['assignments']))
        : null;
  }

  static List<CanvasAssignmentGroup>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasAssignmentGroup>? result;
    if (jsonList != null) {
      result = <CanvasAssignmentGroup>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasAssignmentGroup.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}
