import 'package:collection/collection.dart';
import 'package:rokwire_plugin/utils/utils.dart';

final _canvasDateFormat = "yyyy-MM-ddTHH:mm:ssZ";

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
      
      'created_at': DateTimeUtils.utcDateTimeToString(createdAt, format: _canvasDateFormat),
      'start_at': DateTimeUtils.utcDateTimeToString(startAt, format: _canvasDateFormat),
      'end_at': DateTimeUtils.utcDateTimeToString(endAt, format: _canvasDateFormat),

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

class CanvasFile {
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
}

////////////////////////////////
// CanvasFolder

class CanvasFolder {
  final int? id;
  final int? parentFolderId;

  final String? name;
  final String? fullName;
  
  final int? contextId;
  final String? contextType;

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
    this.contextId, this.contextType,
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
}