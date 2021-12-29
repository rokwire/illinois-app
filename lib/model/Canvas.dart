import 'package:collection/collection.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/utils/Utils.dart';

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

  CanvasCourse({
    this.id, this.accountId, this.rootAccountId, this.enrollmentTermId, this.gradingStandardId, this.sisImportId, this.integrationId, this.sisCourseId,
    this.uuid, this.name, this.friendlyName, this.courseCode, this.courseColor, this.timezone,
    this.createdAt, this.startAt, this.endAt,
    this.isPublic, this.isPublicToAuthUsers, this.publicSyllabus, this.publicSyllabusToAuth, this.homeroomCourse, this.applyAssignmentGroupWeights, this.hideFinalGrades, this.restrictEnrollmentsToCourseDates, this.blueprint, this.template,
    this.gradePassbackSetting, this.workflowState, this.defaultView, this.license,
    this.storageQuotaMb, this.calendar, this.enrollments
  });

  static CanvasCourse? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? CanvasCourse(
      id: AppJson.intValue(json['id']),
      accountId: AppJson.intValue(json['account_id']),
      rootAccountId: AppJson.intValue(json['root_account_id']),
      enrollmentTermId: AppJson.intValue(json['enrollment_term_id']),
      gradingStandardId: AppJson.intValue(json['grading_standard_id']),
      sisImportId: AppJson.intValue(json['sis_import_id']),
      integrationId: AppJson.intValue(json['integration_id']),
      sisCourseId: AppJson.stringValue(json['sis_course_id']),
      
      uuid: AppJson.stringValue(json['uuid']),
      name: AppJson.stringValue(json['name']),
      friendlyName: AppJson.stringValue(json['friendly_name']),
      courseCode: AppJson.stringValue(json['course_code']),
      courseColor: AppJson.stringValue(json['course_color']),
      timezone: AppJson.stringValue(json['time_zone']),
      
      createdAt: AppDateTime.parseDateTime(AppJson.stringValue(json['created_at'])),
      startAt: AppDateTime.parseDateTime(AppJson.stringValue(json['start_at'])),
      endAt: AppDateTime.parseDateTime(AppJson.stringValue(json['end_at'])),

      isPublic: AppJson.boolValue(json['is_public']),
      isPublicToAuthUsers: AppJson.boolValue(json['is_public_to_auth_users']),
      publicSyllabus: AppJson.boolValue(json['public_syllabus']),
      publicSyllabusToAuth: AppJson.boolValue(json['public_syllabus_to_auth']),
      homeroomCourse: AppJson.boolValue(json['homeroom_course']),
      applyAssignmentGroupWeights: AppJson.boolValue(json['apply_assignment_group_weights']),
      hideFinalGrades: AppJson.boolValue(json['hide_final_grades']),
      restrictEnrollmentsToCourseDates: AppJson.boolValue(json['restrict_enrollments_to_course_dates']),
      blueprint: AppJson.boolValue(json['blueprint']),
      template: AppJson.boolValue(json['template']),
      
      gradePassbackSetting: AppJson.stringValue(json['grade_passback_setting']),
      workflowState: AppJson.stringValue(json['workflow_state']),
      defaultView: AppJson.stringValue(json['default_view']),
      license: AppJson.stringValue(json['license']),

      storageQuotaMb: AppJson.intValue(json['storage_quota_mb']),
      calendar: CanvasCalendar.fromJson(AppJson.mapValue(json['calendar'])),
      enrollments: CanvasEnrollment.listFromJson(AppJson.listValue(json['enrollments'])),
    ) : null;
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
      
      'created_at': AppDateTime.utcDateTimeToString(createdAt, format: _canvasDateFormat),
      'start_at': AppDateTime.utcDateTimeToString(startAt, format: _canvasDateFormat),
      'end_at': AppDateTime.utcDateTimeToString(endAt, format: _canvasDateFormat),

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
      DeepCollectionEquality().equals(o.enrollments, enrollments);

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
    DeepCollectionEquality().hash(enrollments);
}

////////////////////////////////
// CanvasCalendar

class CanvasCalendar {
  final String? ics;

  CanvasCalendar({this.ics});

  static CanvasCalendar? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? CanvasCalendar(
      ics: AppJson.stringValue(json['ics']),
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
      id: AppJson.intValue(json['is']),
      userId: AppJson.intValue(json['user_id']),
      type: AppJson.stringValue(json['type']),
      role: AppJson.stringValue(json['role']),
      enrollmentState: AppJson.stringValue(json['enrollment_state']),
      limitPrivilegesToCourseSection: AppJson.boolValue(json['limit_privileges_to_course_section']),
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
        AppList.add(result, CanvasEnrollment.fromJson(AppJson.mapValue(jsonEntry)));
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