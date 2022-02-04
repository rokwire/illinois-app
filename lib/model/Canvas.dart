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

import 'package:collection/collection.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:rokwire_plugin/utils/utils.dart';

final String _canvasServerDateFormat = "yyyy-MM-ddTHH:mm:ssZ";
final String _canvasDisplayDateTimeFormat = 'MM-dd-yyyy h:mm a';

////////////////////////////////
// CanvasCourse

class CanvasCourse {
  final int? id;
  final int? accountId;
  final int? rootAccountId;
  final int? enrollmentTermId;
  final int? gradingStandardId;
  final int? sisImportId;
  final int? integrationId;
  final String? sisCourseId;

  final String? uuid;
  final String? name;
  final String? friendlyName;
  final String? courseCode;
  final String? courseColor;
  final String? timezone;
  
  final DateTime? createdAt;
  final DateTime? startAt;
  final DateTime? endAt;
  
  final bool? isPublic;
  final bool? isPublicToAuthUsers;
  final bool? publicSyllabus;
  final bool? publicSyllabusToAuth;
  final bool? homeroomCourse;
  final bool? applyAssignmentGroupWeights;
  final bool? hideFinalGrades;
  final bool? restrictEnrollmentsToCourseDates;
  final bool? blueprint;
  final bool? template;
  
  final String? gradePassbackSetting;
  final String? workflowState;
  final String? defaultView;
  final String? license;

  final int? storageQuotaMb;
  final CanvasCalendar? calendar;
  final List<CanvasEnrollment>? enrollments;

  final String? syllabusBody;

  CanvasCourse({
    this.id, this.accountId, this.rootAccountId, this.enrollmentTermId, this.gradingStandardId, this.sisImportId, this.integrationId, this.sisCourseId,
    this.uuid, this.name, this.friendlyName, this.courseCode, this.courseColor, this.timezone,
    this.createdAt, this.startAt, this.endAt,
    this.isPublic, this.isPublicToAuthUsers, this.publicSyllabus, this.publicSyllabusToAuth, this.homeroomCourse, this.applyAssignmentGroupWeights, this.hideFinalGrades, this.restrictEnrollmentsToCourseDates, this.blueprint, this.template,
    this.gradePassbackSetting, this.workflowState, this.defaultView, this.license,
    this.storageQuotaMb, this.calendar, this.enrollments,
    this.syllabusBody
  });

  static CanvasCourse? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? CanvasCourse(
      id: JsonUtils.intValue(json['id']),
      accountId: JsonUtils.intValue(json['account_id']),
      rootAccountId: JsonUtils.intValue(json['root_account_id']),
      enrollmentTermId: JsonUtils.intValue(json['enrollment_term_id']),
      gradingStandardId: JsonUtils.intValue(json['grading_standard_id']),
      sisImportId: JsonUtils.intValue(json['sis_import_id']),
      integrationId: JsonUtils.intValue(json['integration_id']),
      sisCourseId: JsonUtils.stringValue(json['sis_course_id']),
      
      uuid: JsonUtils.stringValue(json['uuid']),
      name: JsonUtils.stringValue(json['name']),
      friendlyName: JsonUtils.stringValue(json['friendly_name']),
      courseCode: JsonUtils.stringValue(json['course_code']),
      courseColor: JsonUtils.stringValue(json['course_color']),
      timezone: JsonUtils.stringValue(json['time_zone']),
      
      createdAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['created_at']), isUtc: true),
      startAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['start_at']), isUtc: true),
      endAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['end_at']), isUtc: true),

      isPublic: JsonUtils.boolValue(json['is_public']),
      isPublicToAuthUsers: JsonUtils.boolValue(json['is_public_to_auth_users']),
      publicSyllabus: JsonUtils.boolValue(json['public_syllabus']),
      publicSyllabusToAuth: JsonUtils.boolValue(json['public_syllabus_to_auth']),
      homeroomCourse: JsonUtils.boolValue(json['homeroom_course']),
      applyAssignmentGroupWeights: JsonUtils.boolValue(json['apply_assignment_group_weights']),
      hideFinalGrades: JsonUtils.boolValue(json['hide_final_grades']),
      restrictEnrollmentsToCourseDates: JsonUtils.boolValue(json['restrict_enrollments_to_course_dates']),
      blueprint: JsonUtils.boolValue(json['blueprint']),
      template: JsonUtils.boolValue(json['template']),
      
      gradePassbackSetting: JsonUtils.stringValue(json['grade_passback_setting']),
      workflowState: JsonUtils.stringValue(json['workflow_state']),
      defaultView: JsonUtils.stringValue(json['default_view']),
      license: JsonUtils.stringValue(json['license']),

      storageQuotaMb: JsonUtils.intValue(json['storage_quota_mb']),
      calendar: CanvasCalendar.fromJson(JsonUtils.mapValue(json['calendar'])),
      enrollments: CanvasEnrollment.listFromJson(JsonUtils.listValue(json['enrollments'])),

      syllabusBody: JsonUtils.stringValue(json['syllabus_body']),
    ) : null;
  }

  static List<CanvasCourse>? listFromJson(List<dynamic>? jsonList) {
    if (CollectionUtils.isEmpty(jsonList)) {
      return null;
    }
    List<CanvasCourse>? courses;
    if (jsonList != null) {
      courses = [];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(courses, CanvasCourse.fromJson(jsonEntry));
      }
    }
    return courses;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'account_id': accountId,
      'root_account_id': rootAccountId,
      'enrollment_term_id': enrollmentTermId,
      'grading_standard_id': gradingStandardId,
      'sis_import_id': sisImportId,
      'integration_id': integrationId,
      'sis_course_id': sisCourseId,

      'uuid': uuid,
      'name': name,
      'friendly_name': friendlyName,
      'course_code': courseCode,
      'course_color': courseColor,
      'time_zone': timezone,
      
      'created_at': DateTimeUtils.utcDateTimeToString(createdAt, format: _canvasServerDateFormat),
      'start_at': DateTimeUtils.utcDateTimeToString(startAt, format: _canvasServerDateFormat),
      'end_at': DateTimeUtils.utcDateTimeToString(endAt, format: _canvasServerDateFormat),

      'is_public': isPublic,
      'is_public_to_auth_users': isPublicToAuthUsers,
      'public_syllabus': publicSyllabus,
      'public_syllabus_to_auth': publicSyllabusToAuth,
      'homeroom_course': homeroomCourse,
      'apply_assignment_group_weights': applyAssignmentGroupWeights,
      'hide_final_grades': hideFinalGrades,
      'restrict_enrollments_to_course_dates': restrictEnrollmentsToCourseDates,
      'blueprint': blueprint,
      'template': template,
      
      'grade_passback_setting': gradePassbackSetting,
      'workflow_state': workflowState,
      'default_view': defaultView,
      'license': license,

      'storage_quota_mb': storageQuotaMb,
      'calendar': calendar?.toJson(),
      'enrollments': CanvasEnrollment.listToJson(enrollments),

      'syllabus_body': syllabusBody,
    };
  }

  bool operator ==(o) =>
    (o is CanvasCourse) &&
      (o.id == id) &&
      (o.accountId == accountId) &&
      (o.rootAccountId == rootAccountId) &&
      (o.enrollmentTermId == enrollmentTermId) &&
      (o.gradingStandardId == gradingStandardId) &&
      (o.sisImportId == sisImportId) &&
      (o.integrationId == integrationId) &&
      (o.sisCourseId == sisCourseId) &&
      
      (o.uuid == uuid) &&
      (o.name == name) &&
      (o.friendlyName == friendlyName) &&
      (o.courseCode == courseCode) &&
      (o.courseColor == courseColor) &&
      (o.timezone == timezone) &&
      
      (o.createdAt == createdAt) &&
      (o.startAt == startAt) &&
      (o.endAt == endAt) &&

      (o.isPublic == isPublic) &&
      (o.isPublicToAuthUsers == isPublicToAuthUsers) &&
      (o.publicSyllabus == publicSyllabus) &&
      (o.publicSyllabusToAuth == publicSyllabusToAuth) &&
      (o.homeroomCourse == homeroomCourse) &&
      (o.applyAssignmentGroupWeights == applyAssignmentGroupWeights) &&
      (o.hideFinalGrades == hideFinalGrades) &&
      (o.restrictEnrollmentsToCourseDates == restrictEnrollmentsToCourseDates) &&
      (o.blueprint == blueprint) &&
      (o.template == template) &&

      (o.gradePassbackSetting == gradePassbackSetting) &&
      (o.workflowState == workflowState) &&
      (o.defaultView == defaultView) &&
      (o.license == license) &&

      (o.storageQuotaMb == storageQuotaMb) &&
      (o.calendar == calendar) &&
      DeepCollectionEquality().equals(o.enrollments, enrollments) &&

      (o.syllabusBody == syllabusBody);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (accountId?.hashCode ?? 0) ^
    (rootAccountId?.hashCode ?? 0) ^
    (enrollmentTermId?.hashCode ?? 0) ^
    (gradingStandardId?.hashCode ?? 0) ^
    (sisImportId?.hashCode ?? 0) ^
    (integrationId?.hashCode ?? 0) ^
    (sisCourseId?.hashCode ?? 0) ^
    
    (uuid?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (friendlyName?.hashCode ?? 0) ^
    (courseCode?.hashCode ?? 0) ^
    (courseColor?.hashCode ?? 0) ^
    (timezone?.hashCode ?? 0) ^

    (createdAt?.hashCode ?? 0) ^
    (startAt?.hashCode ?? 0) ^
    (endAt?.hashCode ?? 0) ^
    
    (isPublic?.hashCode ?? 0) ^
    (isPublicToAuthUsers?.hashCode ?? 0) ^
    (publicSyllabus?.hashCode ?? 0) ^
    (publicSyllabusToAuth?.hashCode ?? 0) ^
    (homeroomCourse?.hashCode ?? 0) ^
    (applyAssignmentGroupWeights?.hashCode ?? 0) ^
    (hideFinalGrades?.hashCode ?? 0) ^
    (restrictEnrollmentsToCourseDates?.hashCode ?? 0) ^
    (blueprint?.hashCode ?? 0) ^
    (template?.hashCode ?? 0) ^
    
    (gradePassbackSetting?.hashCode ?? 0) ^
    (workflowState?.hashCode ?? 0) ^
    (defaultView?.hashCode ?? 0) ^
    (license?.hashCode ?? 0) ^

    (storageQuotaMb?.hashCode ?? 0) ^
    (calendar?.hashCode ?? 0) ^
    DeepCollectionEquality().hash(enrollments) ^

    (syllabusBody?.hashCode ?? 0);
}

////////////////////////////////
// CanvasCalendar

class CanvasCalendar {
  final String? ics;

  CanvasCalendar({this.ics});

  static CanvasCalendar? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? CanvasCalendar(
      ics: JsonUtils.stringValue(json['ics']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'ics': ics,
    };
  }

  bool operator ==(o) =>
    (o is CanvasCalendar) &&
      (o.ics == ics);

  int get hashCode =>
    (ics?.hashCode ?? 0);
}

////////////////////////////////
// CanvasEnrollment

class CanvasEnrollment {
  final int? id;
  final int? userId;
  final String? type;
  final String? role;
  final String? enrollmentState;
  final bool? limitPrivilegesToCourseSection;

  CanvasEnrollment({this.id, this.userId, this.type, this.role, this.enrollmentState, this.limitPrivilegesToCourseSection});

  static CanvasEnrollment? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? CanvasEnrollment(
      id: JsonUtils.intValue(json['is']),
      userId: JsonUtils.intValue(json['user_id']),
      type: JsonUtils.stringValue(json['type']),
      role: JsonUtils.stringValue(json['role']),
      enrollmentState: JsonUtils.stringValue(json['enrollment_state']),
      limitPrivilegesToCourseSection: JsonUtils.boolValue(json['limit_privileges_to_course_section']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'role': role,
      'enrollment_state': enrollmentState,
      'limit_privileges_to_course_section': limitPrivilegesToCourseSection,
    };
  }

  bool operator ==(o) =>
    (o is CanvasEnrollment) &&
      (o.id == id) &&
      (o.userId == userId) &&
      (o.type == type) &&
      (o.role == role) &&
      (o.enrollmentState == enrollmentState) &&
      (o.limitPrivilegesToCourseSection == limitPrivilegesToCourseSection);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (userId?.hashCode ?? 0) ^
    (type?.hashCode ?? 0) ^
    (role?.hashCode ?? 0) ^
    (enrollmentState?.hashCode ?? 0) ^
    (limitPrivilegesToCourseSection?.hashCode ?? 0);

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
}

////////////////////////////////
// CanvasFile

class CanvasFile implements CanvasFileSystemEntity {
  final int? id;
  final String? uuid;
  final int? folderId;
  
  final String? displayName;
  final String? fileName;
  final String? contentType;
  final int? size;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? modifiedAt;
  final DateTime? lockAt;
  final DateTime? unlockAt;

  final bool? locked;
  final bool? lockedForUser;
  final bool? hidden;
  final bool? hiddenForUser;

  final String? url;
  final String? thumbnailUrl;
  final String? previewUrl;
  
  final String? mimeClass;
  final String? mediaEntryId;
  
  final String? lockInfo;
  final String? lockExplanation;

  CanvasFile({this.id, this.uuid, this.folderId, 
    this.displayName, this.fileName, this.contentType, this.size, 
    this.createdAt, this.updatedAt, this.modifiedAt, this.lockAt, this.unlockAt, 
    this.locked, this.lockedForUser, this.hidden, this.hiddenForUser,
    this.url, this.thumbnailUrl, this.previewUrl,
    this.mimeClass, this.mediaEntryId,
    this.lockInfo, this.lockExplanation});

  static CanvasFile? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasFile(
            id: JsonUtils.intValue(json['id']),
            uuid: JsonUtils.stringValue(json['uuid']),
            folderId: JsonUtils.intValue(json['folder_id']),

            displayName: JsonUtils.stringValue(json['display_name']),
            fileName: JsonUtils.stringValue(json['filename']),
            contentType: JsonUtils.stringValue(json['content-type']),
            size: JsonUtils.intValue(json['size']),

            createdAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['created_at']), isUtc: true),
            updatedAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['updated_at']), isUtc: true),
            modifiedAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['modified_at']), isUtc: true),
            lockAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['lock_at']), isUtc: true),
            unlockAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['unlock_at']), isUtc: true),

            locked: JsonUtils.boolValue(json['locked']),
            lockedForUser: JsonUtils.boolValue(json['locked_for_user']),
            hidden: JsonUtils.boolValue(json['hidden']),
            hiddenForUser: JsonUtils.boolValue(json['hidden_for_user']),

            url: JsonUtils.stringValue(json['url']),
            thumbnailUrl: JsonUtils.stringValue(json['thumbnail_url']),
            previewUrl: JsonUtils.stringValue(json['preview_url']),

            mimeClass: JsonUtils.stringValue(json['mime_class']),
            mediaEntryId: JsonUtils.stringValue(json['media_entry_id']),

            lockInfo: JsonUtils.stringValue(json['lock_info']),
            lockExplanation: JsonUtils.stringValue(json['lock_explanation']),
          )
        : null;
  }

  bool operator ==(o) =>
    (o is CanvasFile) &&
      (o.id == id) &&
      (o.uuid == uuid) &&
      (o.folderId == folderId) &&

      (o.displayName == displayName) &&
      (o.fileName == fileName) &&
      (o.contentType == contentType) &&
      (o.size == size) &&

      (o.createdAt == createdAt) &&
      (o.updatedAt == updatedAt) &&
      (o.modifiedAt == modifiedAt) &&
      (o.lockAt == lockAt) &&
      (o.unlockAt == unlockAt) &&

      (o.locked == locked) &&
      (o.lockedForUser == lockedForUser) &&
      (o.hidden == hidden) &&
      (o.hiddenForUser == hiddenForUser) &&
      
      (o.url == url) &&
      (o.thumbnailUrl == thumbnailUrl) &&
      (o.previewUrl == previewUrl) &&
      
      (o.mimeClass == mimeClass) &&
      (o.mediaEntryId == mediaEntryId) &&
      
      (o.lockInfo == lockInfo) &&
      (o.lockExplanation == lockExplanation);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (uuid?.hashCode ?? 0) ^
    (folderId?.hashCode ?? 0) ^

    (displayName?.hashCode ?? 0) ^
    (fileName?.hashCode ?? 0) ^
    (contentType?.hashCode ?? 0) ^
    (size?.hashCode ?? 0) ^

    (createdAt?.hashCode ?? 0) ^
    (updatedAt?.hashCode ?? 0) ^
    (modifiedAt?.hashCode ?? 0) ^
    (lockAt?.hashCode ?? 0) ^
    (unlockAt?.hashCode ?? 0) ^

    (locked?.hashCode ?? 0) ^
    (lockedForUser?.hashCode ?? 0) ^
    (hidden?.hashCode ?? 0) ^
    (hiddenForUser?.hashCode ?? 0) ^

    (url?.hashCode ?? 0) ^
    (thumbnailUrl?.hashCode ?? 0) ^
    (previewUrl?.hashCode ?? 0) ^
    
    (mimeClass?.hashCode ?? 0) ^
    (mediaEntryId?.hashCode ?? 0) ^
    
    (lockInfo?.hashCode ?? 0) ^
    (lockExplanation?.hashCode ?? 0);

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
  
  final int? contextId;
  final String? contextType;
  final String? uploadStatus;

  final int? position;
  final String? filesUrl;
  final int? filesCount;
  final String? foldersUrl;
  final int? foldersCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lockAt;
  final DateTime? unlockAt;

  final bool? locked;
  final bool? lockedForUser;
  final bool? hidden;
  final bool? hiddenForUser;

  final bool? forSubmissions;

  CanvasFolder({this.id, this.parentFolderId,
    this.name, this.fullName,
    this.contextId, this.contextType, this.uploadStatus,
    this.position, this.filesUrl, this.filesCount, this.foldersUrl, this.foldersCount,
    this.createdAt, this.updatedAt, this.lockAt, this.unlockAt,
    this.locked, this.lockedForUser, this.hidden, this.hiddenForUser,
    this.forSubmissions});

  static CanvasFolder? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasFolder(
            id: JsonUtils.intValue(json['id']),
            parentFolderId: JsonUtils.intValue(json['parent_folder_id']),

            name: JsonUtils.stringValue(json['name']),
            fullName: JsonUtils.stringValue(json['full_name']),

            contextId: JsonUtils.intValue(json['context_id']),
            contextType: JsonUtils.stringValue(json['context_type']),
            uploadStatus: JsonUtils.stringValue(json['upload_status']),
            
            position: JsonUtils.intValue(json['position']),
            filesUrl: JsonUtils.stringValue(json['files_url']),
            filesCount: JsonUtils.intValue(json['files_count']),
            foldersUrl: JsonUtils.stringValue(json['folders_url']),
            foldersCount: JsonUtils.intValue(json['folders_count']),

            createdAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['created_at']), isUtc: true),
            updatedAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['updated_at']), isUtc: true),
            lockAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['lock_at']), isUtc: true),
            unlockAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['unlock_at']), isUtc: true),

            locked: JsonUtils.boolValue(json['locked']),
            lockedForUser: JsonUtils.boolValue(json['locked_for_user']),
            hidden: JsonUtils.boolValue(json['hidden']),
            hiddenForUser: JsonUtils.boolValue(json['hidden_for_user']),
            
            forSubmissions: JsonUtils.boolValue(json['for_submissions']),
          )
        : null;
  }

  bool operator ==(o) =>
    (o is CanvasFolder) &&
      (o.id == id) &&
      (o.parentFolderId == parentFolderId) &&

      (o.name == name) &&
      (o.fullName == fullName) &&

      (o.contextId == contextId) &&
      (o.contextType == contextType) &&
      (o.uploadStatus == uploadStatus) &&
      
      (o.position == position) &&
      (o.filesUrl == filesUrl) &&
      (o.filesCount == filesCount) &&
      (o.foldersUrl == foldersUrl) &&
      (o.foldersCount == foldersCount) &&

      (o.createdAt == createdAt) &&
      (o.updatedAt == updatedAt) &&
      (o.lockAt == lockAt) &&
      (o.unlockAt == unlockAt) &&

      (o.locked == locked) &&
      (o.lockedForUser == lockedForUser) &&
      (o.hidden == hidden) &&
      (o.hiddenForUser == hiddenForUser) &&

      (o.forSubmissions == forSubmissions);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (parentFolderId?.hashCode ?? 0) ^

    (name?.hashCode ?? 0) ^
    (fullName?.hashCode ?? 0) ^

    (contextId?.hashCode ?? 0) ^
    (contextType?.hashCode ?? 0) ^
    (uploadStatus?.hashCode ?? 0) ^
    
    (position?.hashCode ?? 0) ^
    (filesUrl?.hashCode ?? 0) ^
    (filesCount?.hashCode ?? 0) ^
    (foldersUrl?.hashCode ?? 0) ^
    (foldersCount?.hashCode ?? 0) ^

    (createdAt?.hashCode ?? 0) ^
    (updatedAt?.hashCode ?? 0) ^
    (lockAt?.hashCode ?? 0) ^
    (unlockAt?.hashCode ?? 0) ^

    (locked?.hashCode ?? 0) ^
    (lockedForUser?.hashCode ?? 0) ^
    (hidden?.hashCode ?? 0) ^
    (hiddenForUser?.hashCode ?? 0) ^

    (forSubmissions?.hashCode ?? 0);

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
  int?      get entityId;
  int?      get parentEntityId;
  String?   get entityName;
  DateTime? get createdDateTime;
  bool      get isFile;
}

////////////////////////////////
// CanvasDiscussionTopic

class CanvasDiscussionTopic {
  final int? id;
  final int? assignmentId;
  final int? rootTopicId;
  final bool? isSectionSpecific;
  final String? title;
  final DateTime? lastReplyAt;
  final DateTime? createdAt;
  final DateTime? delayedPostAt;
  final DateTime? postedAt;
  final int? position;
  final bool? podcastHasStudentPosts;
  final String? discussionType;
  final DateTime? lockAt;
  final bool? allowRating;
  final bool? onlyGradersCanRate;
  final bool? sortByRating;
  final String? anonymousState;
  final String? userName;
  final int? discussionSubEntryCount;
  final CanvasTopicPermissions? permissions;
  final bool? requireInitialPost;
  final bool? userCanSeePosts;
  final String? podcastUrl;
  final String? readState;
  final int? unreadCount;
  final bool? subscribed;
  final List<CanvasFile>? attachments;
  final bool? published;
  final bool? canUnpublish;
  final bool? locked;
  final bool? canLock;
  final bool? commentsDisabled;
  final CanvasTopicAuthor? author;
  final String? htmlUrl;
  final String? url;
  final bool? pinned;
  final int? groupCategoryId;
  final bool? canGroup;
  final List<CanvasGroupTopic>? groupTopicChildren;
  final bool? lockedForUser;
  final String? message;
  final String? subscriptionHold;
  final DateTime? todoDate;

  CanvasDiscussionTopic({this.id, this.assignmentId, this.rootTopicId, this.isSectionSpecific, this.title, this.lastReplyAt,
    this.createdAt, this.delayedPostAt, this.postedAt, this.position, this.podcastHasStudentPosts, this.discussionType, this.lockAt,
    this.allowRating, this.onlyGradersCanRate, this.sortByRating, this.anonymousState, this.userName, this.discussionSubEntryCount,
    this.permissions, this.requireInitialPost, this.userCanSeePosts, this.podcastUrl, this.readState, this.unreadCount, this.subscribed,
    this.attachments, this.published, this.canUnpublish, this.locked, this.canLock, this.commentsDisabled, this.author, this.htmlUrl,
    this.url, this.pinned, this.groupCategoryId, this.canGroup, this.groupTopicChildren, this.lockedForUser, this.message, 
    this.subscriptionHold, this.todoDate});

  static CanvasDiscussionTopic? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasDiscussionTopic(
            id: JsonUtils.intValue(json['id']),
            assignmentId: JsonUtils.intValue(json['assignment_id']),
            rootTopicId: JsonUtils.intValue(json['root_topic_id']),
            isSectionSpecific: JsonUtils.boolValue(json['is_section_specific']),
            title: JsonUtils.stringValue(json['title']),
            lastReplyAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['last_reply_at']), isUtc: true),
            createdAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['created_at']), isUtc: true),
            delayedPostAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['delayed_post_at']), isUtc: true),
            postedAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['posted_at']), isUtc: true),
            position: JsonUtils.intValue(json['position']),
            podcastHasStudentPosts: JsonUtils.boolValue(json['podcast_has_student_posts']),
            discussionType: JsonUtils.stringValue(json['discussion_type']),
            lockAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['lock_at']), isUtc: true),
            allowRating: JsonUtils.boolValue(json['allow_rating']),
            onlyGradersCanRate: JsonUtils.boolValue(json['only_graders_can_rate']),
            sortByRating: JsonUtils.boolValue(json['sort_by_rating']),
            anonymousState: JsonUtils.stringValue(json['anonymous_state']),
            userName: JsonUtils.stringValue(json['user_name']),
            discussionSubEntryCount: JsonUtils.intValue(json['discussion_subentry_count']),
            permissions: CanvasTopicPermissions.fromJson(json['permissions']),
            requireInitialPost: JsonUtils.boolValue(json['require_initial_post']),
            userCanSeePosts: JsonUtils.boolValue(json['user_can_see_posts']),
            podcastUrl: JsonUtils.stringValue(json['podcast_url']),
            readState: JsonUtils.stringValue(json['read_state']),
            unreadCount: JsonUtils.intValue(json['unread_count']),
            subscribed: JsonUtils.boolValue(json['subscribed']),
            attachments: CanvasFile.listFromJson(json['attachments']),
            published: JsonUtils.boolValue(json['published']),
            canUnpublish: JsonUtils.boolValue(json['can_unpublish']),
            locked: JsonUtils.boolValue(json['locked']),
            canLock: JsonUtils.boolValue(json['can_lock']),
            commentsDisabled: JsonUtils.boolValue(json['comments_disabled']),
            author: CanvasTopicAuthor.fromJson(json['author']),
            htmlUrl: JsonUtils.stringValue(json['html_url']),
            url: JsonUtils.stringValue(json['url']),
            pinned: JsonUtils.boolValue(json['pinned']),
            groupCategoryId: JsonUtils.intValue(json['group_category_id']),
            canGroup: JsonUtils.boolValue(json['can_group']),
            groupTopicChildren: CanvasGroupTopic.listFromJson(json['group_topic_children']),
            lockedForUser: JsonUtils.boolValue(json['locked_for_user']),
            message: JsonUtils.stringValue(json['message']),
            subscriptionHold: JsonUtils.stringValue(json['subscription_hold']),
            todoDate: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['todo_date']), isUtc: true),
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
// CanvasTopicPermissions

class CanvasTopicPermissions {
  final bool? attach;
  final bool? update;
  final bool? reply;
  final bool? delete;

  CanvasTopicPermissions({this.attach, this.update, this.reply, this.delete});

  static CanvasTopicPermissions? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasTopicPermissions(
            attach: JsonUtils.boolValue(json['attach']),
            update: JsonUtils.boolValue(json['update']),
            reply: JsonUtils.boolValue(json['reply']),
            delete: JsonUtils.boolValue(json['delete']),
          )
        : null;
  }
}

////////////////////////////////
// CanvasTopicAuthor

class CanvasTopicAuthor {
  final int? id;
  final String? anonymousId;
  final String? displayName;
  final String? avatarImageUrl;
  final String? htmlUrl;
  final String? pronouns;

  CanvasTopicAuthor(
      {this.id, this.anonymousId, this.displayName, this.avatarImageUrl, this.htmlUrl, this.pronouns});

  static CanvasTopicAuthor? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasTopicAuthor(
            id: JsonUtils.intValue(json['id']),
            anonymousId: JsonUtils.stringValue(json['anonymous_id']),
            displayName: JsonUtils.stringValue(json['display_name']),
            avatarImageUrl: JsonUtils.stringValue(json['avatar_image_url']),
            htmlUrl: JsonUtils.stringValue(json['html_url']),
            pronouns: JsonUtils.stringValue(json['pronouns']),
          )
        : null;
  }

  bool operator ==(o) =>
      (o is CanvasTopicAuthor) &&
      (o.id == id) &&
      (o.anonymousId == anonymousId) &&
      (o.displayName == displayName) &&
      (o.avatarImageUrl == avatarImageUrl) &&
      (o.htmlUrl == htmlUrl) &&
      (o.pronouns == pronouns);

  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (anonymousId?.hashCode ?? 0) ^
      (displayName?.hashCode ?? 0) ^
      (avatarImageUrl?.hashCode ?? 0) ^
      (htmlUrl?.hashCode ?? 0) ^
      (pronouns?.hashCode ?? 0);
}

////////////////////////////////
// CanvasGroupTopic

class CanvasGroupTopic {
  final int? id;
  final int? groupId;

  CanvasGroupTopic({this.id, this.groupId});

  static CanvasGroupTopic? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasGroupTopic(
            id: JsonUtils.intValue(json['id']),
            groupId: JsonUtils.intValue(json['group_id']),
          )
        : null;
  }

  bool operator ==(o) =>
      (o is CanvasGroupTopic) && (o.id == id) && (o.groupId == groupId);

  int get hashCode => (id?.hashCode ?? 0) ^ (groupId?.hashCode ?? 0);

  static List<CanvasGroupTopic>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasGroupTopic>? result;
    if (jsonList != null) {
      result = <CanvasGroupTopic>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasGroupTopic.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

////////////////////////////////
// CanvasCollaboration

class CanvasCollaboration {
  final int? id;
  final String? collaborationType;
  final String? documentId;
  final int? userId;
  final int? contextId;
  final String? contextType;
  final String? url;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? description;
  final String? title;
  final String? type;
  final String? updateUrl;
  final String? userName;

  CanvasCollaboration({this.id, this.collaborationType, this.documentId, this.userId,
    this.contextId, this.contextType, this.url, this.createdAt, this.updatedAt, this.description,
    this.title, this.type, this.updateUrl, this.userName});

  static CanvasCollaboration? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasCollaboration(
            id: JsonUtils.intValue(json['id']),
            collaborationType: JsonUtils.stringValue(json['collaboration_type']),
            documentId: JsonUtils.stringValue(json['document_id']),
            userId: JsonUtils.intValue(json['user_id']),
            contextId: JsonUtils.intValue(json['context_id']),
            contextType: JsonUtils.stringValue(json['context_type']),
            url: JsonUtils.stringValue(json['url']),
            createdAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['created_at']), isUtc: true),
            updatedAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['updated_at']), isUtc: true),
            description: JsonUtils.stringValue(json['description']),
            title: JsonUtils.stringValue(json['title']),
            type: JsonUtils.stringValue(json['type']),
            updateUrl: JsonUtils.stringValue(json['update_url']),
            userName: JsonUtils.stringValue(json['user_name']),
          )
        : null;
  }

  bool operator ==(o) =>
      (o is CanvasCollaboration) &&
      (o.id == id) &&
      (o.collaborationType == collaborationType) &&
      (o.documentId == documentId) &&
      (o.userId == userId) &&
      (o.contextId == contextId) &&
      (o.contextType == contextType) &&
      (o.url == url) &&
      (o.createdAt == createdAt) &&
      (o.updatedAt == updatedAt) &&
      (o.description == description) &&
      (o.title == title) &&
      (o.type == type) &&
      (o.updateUrl == updateUrl) &&
      (o.userName == userName);

  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (collaborationType?.hashCode ?? 0) ^
      (documentId?.hashCode ?? 0) ^
      (userId?.hashCode ?? 0) ^
      (contextId?.hashCode ?? 0) ^
      (contextType?.hashCode ?? 0) ^
      (url?.hashCode ?? 0) ^
      (createdAt?.hashCode ?? 0) ^
      (updatedAt?.hashCode ?? 0) ^
      (description?.hashCode ?? 0) ^
      (title?.hashCode ?? 0) ^
      (type?.hashCode ?? 0) ^
      (updateUrl?.hashCode ?? 0) ^
      (userName?.hashCode ?? 0);

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

class CanvasCalendarEvent {
  final int? id;
  final String? title;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? description;
  final String? locationName;
  final String? locationAddress;
  final String? contextCode;
  final String? effectiveContextCode;
  final String? contextName;
  final String? allContextCodes;
  final String? workflowState;
  final bool? hidden;
  final int? parentEventId;
  final int? childEventsCount;
  final List<int>? childEvents;
  final String? url;
  final String? htmlUrl;
  final String? allDayDate;
  final bool? allDay;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? appointmentGroupId;
  final String? appointmentGroupUrl;
  final bool? ownReservation;
  final String? reserveUrl;
  final bool? reserved;
  final String? participantType;
  final int? participantsPerAppointment;
  final int? availableSlots;
  final CanvasUser? user;
  final CanvasGroup? group;
  final bool? importantDates;

  CanvasCalendarEvent({this.id, this.title, this.startAt, this.endAt, this.description, this.locationName,
    this.locationAddress, this.contextCode, this.effectiveContextCode, this.contextName, this.allContextCodes, this.workflowState,
    this.hidden, this.parentEventId, this.childEventsCount, this.childEvents, this.url, this.htmlUrl,
    this.allDayDate, this.allDay, this.createdAt, this.updatedAt, this.appointmentGroupId, this.appointmentGroupUrl,
    this.ownReservation, this.reserveUrl, this.reserved, this.participantType, this.participantsPerAppointment, 
    this.availableSlots, this.user, this.group, this.importantDates});

  static CanvasCalendarEvent? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasCalendarEvent(
            id: JsonUtils.intValue(json['id']),
            title: JsonUtils.stringValue(json['title']),
            startAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['start_at']), isUtc: true),
            endAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['end_at']), isUtc: true),
            description: JsonUtils.stringValue(json['description']),
            locationName: JsonUtils.stringValue(json['location_name']),
            locationAddress: JsonUtils.stringValue(json['location_address']),
            contextCode: JsonUtils.stringValue(json['context_code']),
            effectiveContextCode: JsonUtils.stringValue(json['effective_context_code']),
            contextName: JsonUtils.stringValue(json['context_name']),
            allContextCodes: JsonUtils.stringValue(json['all_context_codes']),
            workflowState: JsonUtils.stringValue(json['workflow_state']),
            hidden: JsonUtils.boolValue(json['hidden']),
            parentEventId: JsonUtils.intValue(json['parent_event_id']),
            childEventsCount: JsonUtils.intValue(json['child_events_count']),
            childEvents: JsonUtils.listValue(json['child_events'])?.cast<int>(),
            url: JsonUtils.stringValue(json['url']),
            htmlUrl: JsonUtils.stringValue(json['html_url']),
            allDayDate: JsonUtils.stringValue(json['all_day_date']),
            allDay: JsonUtils.boolValue(json['all_day']),
            createdAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['created_at']), isUtc: true),
            updatedAt: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['updated_at']), isUtc: true),
            appointmentGroupId: JsonUtils.intValue(json['appointment_group_id']),
            appointmentGroupUrl: JsonUtils.stringValue(json['appointment_group_url']),
            ownReservation: JsonUtils.boolValue(json['own_reservation']),
            reserveUrl: JsonUtils.stringValue(json['reserve_url']),
            reserved: JsonUtils.boolValue(json['reserved']),
            participantType: JsonUtils.stringValue(json['participant_type']),
            participantsPerAppointment: JsonUtils.intValue(json['participants_per_appointment']),
            availableSlots: JsonUtils.intValue(json['available_slots']),
            user: CanvasUser.fromJson(json['user']),
            group: CanvasGroup.fromJson(json['group']),
            importantDates: JsonUtils.boolValue(json['important_dates']))
        : null;
  }

  bool operator ==(o) =>
      (o is CanvasCalendarEvent) &&
      (o.id == id) &&
      (o.title == title) &&
      (o.startAt == startAt) &&
      (o.endAt == endAt) &&
      (o.description == description) &&
      (o.locationName == locationName) &&
      (o.locationAddress == locationAddress) &&
      (o.contextCode == contextCode) &&
      (o.effectiveContextCode == effectiveContextCode) &&
      (o.contextName == contextName) &&
      (o.allContextCodes == allContextCodes) &&
      (o.workflowState == workflowState) &&
      (o.hidden == hidden) &&
      (o.parentEventId == parentEventId) &&
      (o.childEventsCount == childEventsCount) &&
      (o.childEvents == childEvents) &&
      (o.url == url) &&
      (o.htmlUrl == htmlUrl) &&
      (o.allDayDate == allDayDate) &&
      (o.allDay == allDay) &&
      (o.createdAt == createdAt) &&
      (o.updatedAt == updatedAt) &&
      (o.appointmentGroupId == appointmentGroupId) &&
      (o.appointmentGroupUrl == appointmentGroupUrl) &&
      (o.ownReservation == ownReservation) &&
      (o.reserveUrl == reserveUrl) &&
      (o.reserved == reserved) &&
      (o.participantType == participantType) &&
      (o.participantsPerAppointment == participantsPerAppointment) &&
      (o.availableSlots == availableSlots) &&
      (o.user == user) &&
      (o.group == group) &&
      (o.importantDates == importantDates);

  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (title?.hashCode ?? 0) ^
      (startAt?.hashCode ?? 0) ^
      (endAt?.hashCode ?? 0) ^
      (description?.hashCode ?? 0) ^
      (locationName?.hashCode ?? 0) ^
      (locationAddress?.hashCode ?? 0) ^
      (contextCode?.hashCode ?? 0) ^
      (effectiveContextCode?.hashCode ?? 0) ^
      (contextName?.hashCode ?? 0) ^
      (allContextCodes?.hashCode ?? 0) ^
      (workflowState?.hashCode ?? 0) ^
      (hidden?.hashCode ?? 0) ^
      (parentEventId?.hashCode ?? 0) ^
      (childEventsCount?.hashCode ?? 0) ^
      (childEvents?.hashCode ?? 0) ^
      (url?.hashCode ?? 0) ^
      (htmlUrl?.hashCode ?? 0) ^
      (allDayDate?.hashCode ?? 0) ^
      (allDay?.hashCode ?? 0) ^
      (createdAt?.hashCode ?? 0) ^
      (updatedAt?.hashCode ?? 0) ^
      (appointmentGroupId?.hashCode ?? 0) ^
      (appointmentGroupUrl?.hashCode ?? 0) ^
      (ownReservation?.hashCode ?? 0) ^
      (reserveUrl?.hashCode ?? 0) ^
      (reserved?.hashCode ?? 0) ^
      (participantType?.hashCode ?? 0) ^
      (participantsPerAppointment?.hashCode ?? 0) ^
      (availableSlots?.hashCode ?? 0) ^
      (user?.hashCode ?? 0) ^
      (group?.hashCode ?? 0) ^
      (importantDates?.hashCode ?? 0);

  DateTime? get startAtLocal {
    return AppDateTime().getDeviceTimeFromUtcTime(startAt);
  }

  DateTime? get endAtLocal {
    return AppDateTime().getDeviceTimeFromUtcTime(endAt);
  }

  String? get startAtDisplayDate {
    return AppDateTime().formatDateTime(startAtLocal, format: _canvasDisplayDateTimeFormat);
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
  final int? sisImportId;
  final String? integrationId;
  final String? loginId;
  final String? avatarUrl;
  final List<CanvasEnrollment>? enrollments;
  final String? email;
  final String? locale;
  final DateTime? lastLogin;
  final String? timeZone;
  final String? bio;

  CanvasUser({this.id, this.name, this.sortableName, this.lastName, this.firstName, this.shortName,
    this.sisUserId, this.sisImportId, this.integrationId, this.loginId, this.avatarUrl, this.enrollments,
    this.email, this.locale, this.lastLogin, this.timeZone, this.bio});

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
            sisImportId: JsonUtils.intValue(json['sis_import_id']),
            integrationId: JsonUtils.stringValue(json['integration_id']),
            loginId: JsonUtils.stringValue(json['login_id']),
            avatarUrl: JsonUtils.stringValue(json['avatar_url']),
            enrollments: CanvasEnrollment.listFromJson(JsonUtils.listValue(json['enrollments'])),
            email: JsonUtils.stringValue(json['email']),
            locale: JsonUtils.stringValue(json['locale']),
            lastLogin: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['last_login']), isUtc: true),
            timeZone: JsonUtils.stringValue(json['time_zone']),
            bio: JsonUtils.stringValue(json['bio']),
          )
        : null;
  }

  bool operator ==(o) =>
      (o is CanvasUser) &&
      (o.id == id) &&
      (o.name == name) &&
      (o.sortableName == sortableName) &&
      (o.lastName == lastName) &&
      (o.firstName == firstName) &&
      (o.shortName == shortName) &&
      (o.sisUserId == sisUserId) &&
      (o.sisImportId == sisImportId) &&
      (o.integrationId == integrationId) &&
      (o.loginId == loginId) &&
      (o.avatarUrl == avatarUrl) &&
      (o.enrollments == enrollments) &&
      (o.email == email) &&
      (o.locale == locale) &&
      (o.lastLogin == lastLogin) &&
      (o.timeZone == timeZone) &&
      (o.bio == bio);

  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (name?.hashCode ?? 0) ^
      (sortableName?.hashCode ?? 0) ^
      (lastName?.hashCode ?? 0) ^
      (firstName?.hashCode ?? 0) ^
      (shortName?.hashCode ?? 0) ^
      (sisUserId?.hashCode ?? 0) ^
      (sisImportId?.hashCode ?? 0) ^
      (integrationId?.hashCode ?? 0) ^
      (loginId?.hashCode ?? 0) ^
      (avatarUrl?.hashCode ?? 0) ^
      (enrollments?.hashCode ?? 0) ^
      (email?.hashCode ?? 0) ^
      (locale?.hashCode ?? 0) ^
      (lastLogin?.hashCode ?? 0) ^
      (timeZone?.hashCode ?? 0) ^
      (bio?.hashCode ?? 0);

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
// CanvasGroup

class CanvasGroup {
  final int? id;
  final String? name;
  final String? description;
  final bool? isPublic;
  final bool? followedByUser;
  final String? joinLevel;
  final int? membersCount;
  final String? avatarUrl;
  final String? contextType;
  final int? courseId;
  final String? role;
  final int? groupCategoryId;
  final String? sisGroupId;
  final int? sisImportId;
  final int? storageQuotaMb;
  final CanvasGroupPermissions? permissions;
  final List<CanvasUser>? users;

  CanvasGroup({this.id, this.name, this.description, this.isPublic, this.followedByUser, this.joinLevel,
    this.membersCount, this.avatarUrl, this.contextType, this.courseId, this.role, this.groupCategoryId,
    this.sisGroupId, this.sisImportId, this.storageQuotaMb, this.permissions, this.users});

  static CanvasGroup? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasGroup(
            id: JsonUtils.intValue(json['id']),
            name: JsonUtils.stringValue(json['name']),
            description: JsonUtils.stringValue(json['description']),
            isPublic: JsonUtils.boolValue(json['is_public']),
            followedByUser: JsonUtils.boolValue(json['followed_by_user']),
            joinLevel: JsonUtils.stringValue(json['join_level']),
            membersCount: JsonUtils.intValue(json['members_count']),
            avatarUrl: JsonUtils.stringValue(json['avatar_url']),
            contextType: JsonUtils.stringValue(json['context_type']),
            courseId: JsonUtils.intValue(json['course_id']),
            role: JsonUtils.stringValue(json['role']),
            groupCategoryId: JsonUtils.intValue(json['group_category_id']),
            sisGroupId: JsonUtils.stringValue(json['sis_group_id']),
            sisImportId: JsonUtils.intValue(json['sis_import_id']),
            storageQuotaMb: JsonUtils.intValue(json['storage_quota_mb']),
            permissions: CanvasGroupPermissions.fromJson(json['permissions']),
            users: CanvasUser.listFromJson(JsonUtils.listValue(json['users']))
          )
        : null;
  }

  bool operator ==(o) =>
      (o is CanvasGroup) &&
      (o.id == id) &&
      (o.name == name) &&
      (o.description == description) &&
      (o.isPublic == isPublic) &&
      (o.followedByUser == followedByUser) &&
      (o.joinLevel == joinLevel) &&
      (o.membersCount == membersCount) &&
      (o.avatarUrl == avatarUrl) &&
      (o.contextType == contextType) &&
      (o.courseId == courseId) &&
      (o.role == role) &&
      (o.groupCategoryId == groupCategoryId) &&
      (o.sisGroupId == sisGroupId) &&
      (o.sisImportId == sisImportId) &&
      (o.storageQuotaMb == storageQuotaMb) &&
      (o.permissions == permissions) &&
      (o.users == users);

  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (name?.hashCode ?? 0) ^
      (description?.hashCode ?? 0) ^
      (isPublic?.hashCode ?? 0) ^
      (followedByUser?.hashCode ?? 0) ^
      (joinLevel?.hashCode ?? 0) ^
      (membersCount?.hashCode ?? 0) ^
      (avatarUrl?.hashCode ?? 0) ^
      (contextType?.hashCode ?? 0) ^
      (courseId?.hashCode ?? 0) ^
      (role?.hashCode ?? 0) ^
      (groupCategoryId?.hashCode ?? 0) ^
      (sisGroupId?.hashCode ?? 0) ^
      (sisImportId?.hashCode ?? 0) ^
      (storageQuotaMb?.hashCode ?? 0) ^
      (permissions?.hashCode ?? 0) ^
      (users?.hashCode ?? 0);

  static List<CanvasGroup>? listFromJson(List<dynamic>? jsonList) {
    List<CanvasGroup>? result;
    if (jsonList != null) {
      result = <CanvasGroup>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CanvasGroup.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}

////////////////////////////////
// CanvasGroupPermissions

class CanvasGroupPermissions {
  final bool? createDiscussionTopic;
  final bool? createAnnouncement;

  CanvasGroupPermissions({this.createDiscussionTopic, this.createAnnouncement});

  static CanvasGroupPermissions? fromJson(Map<String, dynamic>? json) {
    return (json != null)
        ? CanvasGroupPermissions(
            createDiscussionTopic: JsonUtils.boolValue(json['create_discussion_topic']),
            createAnnouncement: JsonUtils.boolValue(json['create_announcement']),
          )
        : null;
  }
}

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

  bool operator ==(o) =>
      (o is CanvasAccountNotification) &&
      (o.id == id) &&
      (o.subject == subject) &&
      (o.message == message) &&
      (o.startAt == startAt) &&
      (o.endAt == endAt) &&
      (o.icon == icon) &&
      (o.roles == roles) &&
      (o.roleIds == roleIds);

  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (subject?.hashCode ?? 0) ^
      (message?.hashCode ?? 0) ^
      (startAt?.hashCode ?? 0) ^
      (endAt?.hashCode ?? 0) ^
      (icon?.hashCode ?? 0) ^
      (roles?.hashCode ?? 0) ^
      (roleIds?.hashCode ?? 0);

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
