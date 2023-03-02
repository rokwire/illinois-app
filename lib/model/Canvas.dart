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

final String _canvasDisplayDateTimeFormat = 'MM-dd-yyyy h:mm a';

////////////////////////////////
// CanvasCourse

class CanvasCourse {
  final int? id;
  final String? name;
  final bool? accessRestrictedByDate;

  final String? syllabusBody;

  CanvasCourse({this.id, this.name, this.accessRestrictedByDate, this.syllabusBody});

  static CanvasCourse? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasCourse(
            id: JsonUtils.intValue(json['id']),
            name: JsonUtils.stringValue(json['name']),
            accessRestrictedByDate: JsonUtils.boolValue(json['access_restricted_by_date']),
            syllabusBody: JsonUtils.stringValue(json['syllabus_body']),
          )
        : null;
  }

  @override
  bool operator ==(other) =>
      (other is CanvasCourse) &&
      (other.id == id) &&
      (other.name == name) &&
      (other.accessRestrictedByDate == accessRestrictedByDate) &&
      (other.syllabusBody == syllabusBody);

  @override
  int get hashCode => (id?.hashCode ?? 0) ^ (name?.hashCode ?? 0) ^ (accessRestrictedByDate?.hashCode ?? 0) ^ (syllabusBody?.hashCode ?? 0);
}

////////////////////////////////
// CanvasEnrollment

class CanvasEnrollment {
  final int? id;
  final CanvasEnrollmentType? type;
  final CanvasGrade? grade;

  CanvasEnrollment({this.id, this.type, this.grade});

  static CanvasEnrollment? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasEnrollment(
            id: JsonUtils.intValue(json['id']),
            type: CanvasEnrollment.typeFromString(JsonUtils.stringValue(json['type'])),
            grade: CanvasGrade.fromJson(JsonUtils.mapValue(json['grades'])),
          )
        : null;
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
    return (json != null)
        ? CanvasGrade(
            currentScore: JsonUtils.doubleValue(json['current_score']),
          )
        : null;
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

  CanvasUser(
      {this.id, this.name, this.sortableName, this.lastName, this.firstName, this.shortName, this.sisUserId, this.enrollments, this.email});

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
        ? CanvasAssignmentGroup(id: JsonUtils.intValue(json['id']), assignments: CanvasAssignment.listFromJson(json['assignments']))
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

////////////////////////////////
// CanvasDiscussionTopic

class CanvasDiscussionTopic {
  final int? id;
  final int? assignmentId;
  final String? title;
  final DateTime? postedAt;
  final int? position;
  final List<CanvasFile>? attachments;
  final CanvasTopicAuthor? author;
  final String? message;

  CanvasDiscussionTopic(
      {this.id, this.assignmentId, this.title, this.postedAt, this.position, this.attachments, this.author, this.message});

  static CanvasDiscussionTopic? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasDiscussionTopic(
            id: JsonUtils.intValue(json['id']),
            assignmentId: JsonUtils.intValue(json['assignment_id']),
            title: JsonUtils.stringValue(json['title']),
            postedAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['posted_at']), isUtc: true),
            position: JsonUtils.intValue(json['position']),
            attachments: CanvasFile.listFromJson(json['attachments']),
            author: CanvasTopicAuthor.fromJson(json['author']),
            message: JsonUtils.stringValue(json['message']),
          )
        : null;
  }

  DateTime? get postedAtLocal {
    return AppDateTime().getDeviceTimeFromUtcTime(postedAt);
  }

  String? get postedAtDisplayDate {
    return AppDateTime().formatDateTime(postedAtLocal, format: _canvasDisplayDateTimeFormat);
  }

  static List<CanvasDiscussionTopic>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasDiscussionTopic>? result;
    if (jsonList != null) {
      result = <CanvasDiscussionTopic>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasDiscussionTopic.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

////////////////////////////////
// CanvasTopicAuthor

class CanvasTopicAuthor {
  final int? id;
  final String? anonymousId;
  final String? displayName;
  final String? avatarImageUrl;

  CanvasTopicAuthor({this.id, this.anonymousId, this.displayName, this.avatarImageUrl});

  static CanvasTopicAuthor? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasTopicAuthor(
            id: JsonUtils.intValue(json['id']),
            anonymousId: JsonUtils.stringValue(json['anonymous_id']),
            displayName: JsonUtils.stringValue(json['display_name']),
            avatarImageUrl: JsonUtils.stringValue(json['avatar_image_url']),
          )
        : null;
  }
}

////////////////////////////////
// CanvasFile

class CanvasFile implements CanvasFileSystemEntity {
  final int? id;
  final String? uuid;
  final int? folderId;
  final String? displayName;
  final String? fileName;
  final DateTime? createdAt;
  final String? url;

  CanvasFile({this.id, this.uuid, this.folderId, this.displayName, this.fileName, this.createdAt, this.url});

  static CanvasFile? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasFile(
            id: JsonUtils.intValue(json['id']),
            uuid: JsonUtils.stringValue(json['uuid']),
            folderId: JsonUtils.intValue(json['folder_id']),
            displayName: JsonUtils.stringValue(json['display_name']),
            fileName: JsonUtils.stringValue(json['filename']),
            createdAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['created_at']), isUtc: true),
            url: JsonUtils.stringValue(json['url']),
          )
        : null;
  }

  static List<CanvasFile>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasFile>? result;
    if (jsonList != null) {
      result = <CanvasFile>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasFile.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  // CanvasFileSystemEntity

  @override
  int? get entityId => id;

  @override
  int? get parentEntityId => folderId;

  @override
  String? get entityName => displayName;

  @override
  DateTime? get createdDateTime => createdAt;

  @override
  bool get isFile => true;
}

////////////////////////////////
// CanvasFolder

class CanvasFolder implements CanvasFileSystemEntity {
  final int? id;
  final int? parentFolderId;
  final String? name;
  final String? fullName;
  final DateTime? createdAt;

  CanvasFolder({this.id, this.parentFolderId, this.name, this.fullName, this.createdAt});

  static CanvasFolder? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasFolder(
            id: JsonUtils.intValue(json['id']),
            parentFolderId: JsonUtils.intValue(json['parent_folder_id']),
            name: JsonUtils.stringValue(json['name']),
            fullName: JsonUtils.stringValue(json['full_name']),
            createdAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['created_at']), isUtc: true),
          )
        : null;
  }

  static List<CanvasFolder>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasFolder>? result;
    if (jsonList != null) {
      result = <CanvasFolder>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasFolder.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  // CanvasFileSystemEntity

  @override
  int? get entityId => id;

  @override
  int? get parentEntityId => parentFolderId;

  @override
  String? get entityName => name;

  @override
  DateTime? get createdDateTime => createdAt;

  @override
  bool get isFile => false;
}

abstract class CanvasFileSystemEntity {
  int? get entityId;
  int? get parentEntityId;
  String? get entityName;
  DateTime? get createdDateTime;
  bool get isFile;
}
