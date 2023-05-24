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
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

final String _canvasDisplayDateTimeFormat = 'MM-dd-yyyy h:mm a';

////////////////////////////////
// CanvasCourse

class CanvasCourse {
  final int? id;
  final String? name;
  final bool? accessRestrictedByDate;
  final int? accountId;

  final String? syllabusBody;

  CanvasCourse({this.id, this.name, this.accessRestrictedByDate, this.syllabusBody, this.accountId});

  static CanvasCourse? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasCourse(
            id: JsonUtils.intValue(json['id']),
            name: JsonUtils.stringValue(json['name']),
            accessRestrictedByDate: JsonUtils.boolValue(json['access_restricted_by_date']),
            syllabusBody: JsonUtils.stringValue(json['syllabus_body']),
            accountId: JsonUtils.intValue(json['account_id'])
          )
        : null;
  }

  @override
  bool operator ==(other) =>
      (other is CanvasCourse) &&
      (other.id == id) &&
      (other.name == name) &&
      (other.accessRestrictedByDate == accessRestrictedByDate) &&
      (other.syllabusBody == syllabusBody) &&
      (other.accountId == accountId);

  @override
  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (name?.hashCode ?? 0) ^
      (accessRestrictedByDate?.hashCode ?? 0) ^
      (syllabusBody?.hashCode ?? 0) ^
      (accountId?.hashCode ?? 0);
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
  final CanvasSubmission? submission;

  CanvasAssignment({this.id, this.name, this.dueAt, this.courseId, this.htmlUrl, this.position, this.submission});

  static CanvasAssignment? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasAssignment(
            id: JsonUtils.intValue(json['id']),
            name: JsonUtils.stringValue(json['name']),
            dueAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['due_at']), isUtc: true),
            courseId: JsonUtils.intValue(json['course_id']),
            htmlUrl: JsonUtils.stringValue(json['html_url']),
            position: JsonUtils.intValue(json['position']),
            submission: CanvasSubmission.fromJson(JsonUtils.mapValue(json['submission'])))
        : null;
  }

  DateTime? get dueAtLocal {
    return AppDateTime().getDeviceTimeFromUtcTime(dueAt);
  }

  String? get dueDisplayDateTime {
    if (dueAtLocal == null) {
      return null;
    }
    int nowYear = DateTime.now().year;
    int dueYear = dueAtLocal!.year;
    String dateTimeFormat = (nowYear != dueYear) ? 'yyyy-MM-dd' : 'MMM d, h:mma';
    String? dueDisplayDate = AppDateTime().formatDateTime(dueAtLocal, format: dateTimeFormat);
    return dueDisplayDate;
  }

  String? get submittedDisplayDateTime {
    return submission?.submittedDisplayDateTime;
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
// CanvasSubmission

class CanvasSubmission {
  final int? id;
  final DateTime? submittedAt;

  CanvasSubmission({this.id, this.submittedAt});

  DateTime? get submittedAtLocal {
    return AppDateTime().getDeviceTimeFromUtcTime(submittedAt);
  }

  String? get submittedDisplayDateTime {
    if (submittedAtLocal == null) {
      return null;
    }
    int nowYear = DateTime.now().year;
    int dueYear = submittedAtLocal!.year;
    String dateTimeFormat = (nowYear != dueYear) ? 'yyyy-MM-dd' : 'MMM d, h:mma';
    String? dueDisplayDate = AppDateTime().formatDateTime(submittedAtLocal, format: dateTimeFormat);
    return dueDisplayDate;
  }

  static CanvasSubmission? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasSubmission(id: JsonUtils.intValue(json['id']), submittedAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['submitted_at']), isUtc: true))
        : null;
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

////////////////////////////////
// CanvasCollaboration

class CanvasCollaboration {
  final int? id;
  final DateTime? createdAt;
  final String? title;
  final String? userName;

  CanvasCollaboration({this.id, this.createdAt, this.title, this.userName});

  static CanvasCollaboration? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasCollaboration(
            id: JsonUtils.intValue(json['id']),
            createdAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['created_at']), isUtc: true),
            title: JsonUtils.stringValue(json['title']),
            userName: JsonUtils.stringValue(json['user_name']),
          )
        : null;
  }

  DateTime? get createdAtLocal {
    return AppDateTime().getDeviceTimeFromUtcTime(createdAt);
  }

  String? get createdAtDisplayDate {
    return AppDateTime().formatDateTime(createdAtLocal, format: _canvasDisplayDateTimeFormat);
  }

  static List<CanvasCollaboration>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasCollaboration>? result;
    if (jsonList != null) {
      result = <CanvasCollaboration>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasCollaboration.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

////////////////////////////////
// CanvasCalendarEvent

class CanvasCalendarEvent implements Favorite {
  final int? id;
  final String? title;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? description;
  final String? contextName;
  final bool? hidden;
  final String? url;
  final String? htmlUrl;
  final CanvasCalendarEventType? type;
  final CanvasAssignment? assignment;

  CanvasCalendarEvent(
      {this.id,
      this.title,
      this.startAt,
      this.endAt,
      this.description,
      this.contextName,
      this.hidden,
      this.url,
      this.htmlUrl,
      this.type,
      this.assignment});

  static CanvasCalendarEvent? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasCalendarEvent(
            id: JsonUtils.intValue(json['id']),
            title: JsonUtils.stringValue(json['title']),
            startAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['start_at']), isUtc: true),
            endAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['end_at']), isUtc: true),
            description: JsonUtils.stringValue(json['description']),
            contextName: JsonUtils.stringValue(json['context_name']),
            hidden: JsonUtils.boolValue(json['hidden']),
            url: JsonUtils.stringValue(json['url']),
            htmlUrl: JsonUtils.stringValue(json['html_url']),
            type: CanvasCalendarEvent.typeFromString(json['type']),
            assignment: CanvasAssignment.fromJson(json['assignment']))
        : null;
  }

  DateTime? get startAtLocal {
    return AppDateTime().getDeviceTimeFromUtcTime(startAt);
  }

  DateTime? get endAtLocal {
    return AppDateTime().getDeviceTimeFromUtcTime(endAt);
  }

  String? get startAtDisplayDate {
    return AppDateTime().formatDateTime(startAtLocal, format: _canvasDisplayDateTimeFormat);
  }

  String? get endAtDisplayDate {
    return AppDateTime().formatDateTime(endAtLocal, format: _canvasDisplayDateTimeFormat);
  }

  String? get displayDateTime {
    const String emptyTime = 'N/A';
    const dayFormat = 'MMM d';
    const timeFormat = 'h:mma';
    String? startTime = AppDateTime().formatDateTime(startAtLocal, format: '$dayFormat $timeFormat');
    String endTimeFormat = timeFormat;
    if (startAtLocal?.day != endAtLocal?.day) {
      endTimeFormat = '$dayFormat ' + endTimeFormat;
    }
    String? endTime = AppDateTime().formatDateTime(endAtLocal, format: endTimeFormat);
    return StringUtils.ensureNotEmpty(startTime, defaultValue: emptyTime) +
        ' - ' +
        StringUtils.ensureNotEmpty(endTime, defaultValue: emptyTime);
  }

  static List<CanvasCalendarEvent>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasCalendarEvent>? result;
    if (jsonList != null) {
      result = <CanvasCalendarEvent>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasCalendarEvent.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static CanvasCalendarEventType? typeFromString(String? value) {
    switch (value) {
      case 'event':
        return CanvasCalendarEventType.event;
      case 'assignment':
        return CanvasCalendarEventType.assignment;
      default:
        return null;
    }
  }

  static String? typeToKeyString(CanvasCalendarEventType? type) {
    switch (type) {
      case CanvasCalendarEventType.event:
        return 'event';
      case CanvasCalendarEventType.assignment:
        return 'assignment';
      default:
        return null;
    }
  }

  static String? typeToDisplayString(CanvasCalendarEventType? type) {
    switch (type) {
      case CanvasCalendarEventType.event:
        return Localization().getStringEx('model.canvas.calendar.event.type.event.label', 'Event');
      case CanvasCalendarEventType.assignment:
        return Localization().getStringEx('model.canvas.calendar.event.type.assignment.label', 'Assignment');
      default:
        return null;
    }
  }

  ////////////////////////////
  // Favorite implementation

  static String _favoriteKeyName = "canvasCalendarEventIds";
  @override
  String get favoriteKey => _favoriteKeyName;
  @override
  String? get favoriteId => id?.toString();
}

////////////////////////////////
// CanvasCalendarEventType

enum CanvasCalendarEventType { event, assignment }

////////////////////////////////
// CanvasAccountNotification

class CanvasAccountNotification {
  final int? id;
  final String? subject;
  final String? message;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? icon;
  final List<String>? roles;
  final List<int>? roleIds;

  CanvasAccountNotification({this.id, this.subject, this.message, this.startAt, this.endAt, this.icon, this.roles, this.roleIds});

  static CanvasAccountNotification? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasAccountNotification(
            id: JsonUtils.intValue(json['id']),
            subject: JsonUtils.stringValue(json['subject']),
            message: JsonUtils.stringValue(json['message']),
            startAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['start_at']), isUtc: true),
            endAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['end_at']), isUtc: true),
            icon: JsonUtils.stringValue(json['icon']),
            roles: JsonUtils.listValue(json['roles'])?.cast<String>(),
            roleIds: JsonUtils.listValue(json['role_ids'])?.cast<int>())
        : null;
  }

  DateTime? get startAtLocal {
    return AppDateTime().getDeviceTimeFromUtcTime(startAt);
  }

  DateTime? get endAtLocal {
    return AppDateTime().getDeviceTimeFromUtcTime(endAt);
  }

  String? get startAtDisplayDate {
    return AppDateTime().formatDateTime(startAtLocal, format: _canvasDisplayDateTimeFormat);
  }

  static List<CanvasAccountNotification>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasAccountNotification>? result;
    if (jsonList != null) {
      result = <CanvasAccountNotification>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasAccountNotification.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

////////////////////////////////
// CanvasModule

class CanvasModule {
  final int? id;
  final int? position;
  final String? name;

  CanvasModule({this.id, this.position, this.name});

  static CanvasModule? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasModule(
            id: JsonUtils.intValue(json['id']), position: JsonUtils.intValue(json['position']), name: JsonUtils.stringValue(json['name']))
        : null;
  }

  static List<CanvasModule>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasModule>? result;
    if (jsonList != null) {
      result = <CanvasModule>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasModule.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

////////////////////////////////
// CanvasModuleItem

class CanvasModuleItem {
  final int? id;
  final int? moduleId;
  final int? position;
  final String? title;
  final int? indent;
  final CanvasModuleItemType? type;
  final String? htmlUrl;
  final String? url;

  CanvasModuleItem({this.id, this.moduleId, this.position, this.title, this.indent, this.type, this.htmlUrl, this.url});

  static CanvasModuleItem? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasModuleItem(
            id: JsonUtils.intValue(json['id']),
            moduleId: JsonUtils.intValue(json['module_id']),
            position: JsonUtils.intValue(json['position']),
            title: JsonUtils.stringValue(json['title']),
            indent: JsonUtils.intValue(json['indent']),
            type: itemTypeFromString(JsonUtils.stringValue(json['type'])),
            htmlUrl: JsonUtils.stringValue(json['html_url']),
            url: JsonUtils.stringValue(json['url']))
        : null;
  }

  static List<CanvasModuleItem>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasModuleItem>? result;
    if (jsonList != null) {
      result = <CanvasModuleItem>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasModuleItem.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static CanvasModuleItemType? itemTypeFromString(String? value) {
    switch (value) {
      case 'SubHeader':
        return CanvasModuleItemType.sub_header;
      case 'Page':
        return CanvasModuleItemType.page;
      case 'Quiz':
        return CanvasModuleItemType.quiz;
      case 'ExternalUrl':
        return CanvasModuleItemType.external_url;
      case 'Assignment':
        return CanvasModuleItemType.assignment;
      default:
        return null;
    }
  }
}

enum CanvasModuleItemType { sub_header, page, quiz, external_url, assignment }

////////////////////////////////
// CanvasErrorReport

class CanvasErrorReport {
  final String? subject;
  final String? url;
  String? email;
  String? comments;

  CanvasErrorReport({this.subject, this.url, this.email, this.comments});

  static CanvasErrorReport? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasErrorReport(
            subject: JsonUtils.stringValue(json['subject']),
            url: JsonUtils.stringValue(json['url']),
            email: JsonUtils.stringValue(json['email']),
            comments: JsonUtils.stringValue(json['comments']))
        : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {'subject': subject};
    if (StringUtils.isNotEmpty(comments)) {
      json['comments'] = comments;
    }
    if (StringUtils.isNotEmpty(email)) {
      json['email'] = email;
    }
    if (StringUtils.isNotEmpty(url)) {
      json['url'] = url;
    }
    return json;
  }
}
