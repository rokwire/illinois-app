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
import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:intl/intl.dart';

//////////////////////////////
// Group

class Group {
	String?             id;
	String?             category;
	String?             type;
	String?             title;
  String?             description;
  GroupPrivacy?       privacy;
  bool?               certified;
  DateTime?           dateCreatedUtc;
  DateTime?           dateUpdatedUtc;

  bool?               authManEnabled;
  String?             authManGroupName;

  String?             imageURL;
  String?             webURL;
  List<Member>?       members;
  List<String>?       tags;
  List<GroupMembershipQuestion>? questions;
  GroupMembershipQuest? membershipQuest; // MD: Looks as deprecated. Consider and remove if need!

  Group({Map<String, dynamic>? json, Group? other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  static Group? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Group(json: json) : null;
  }

  static Group? fromOther(Group? other) {
    return (other != null) ? Group(other: other) : null;
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { id                = json['id'];         } catch(e) { debugPrint(e.toString()); }
    try { category          = json['category'];   } catch(e) { debugPrint(e.toString()); }
    try { type              = json['type'];       } catch(e) { debugPrint(e.toString()); }
    try { title             = json['title'];      } catch(e) { debugPrint(e.toString()); }
    try { description       = json['description'];  } catch(e) { debugPrint(e.toString()); }
    try { privacy           = groupPrivacyFromString(json['privacy']); } catch(e) { debugPrint(e.toString()); }
    try { certified         = json['certified']; } catch(e) { debugPrint(e.toString()); }
    try { authManEnabled    = json['authman_enabled']; } catch(e) { debugPrint(e.toString()); }
    try { authManGroupName  = json['authman_group']; } catch(e) { debugPrint(e.toString()); }
    try { dateCreatedUtc    = groupUtcDateTimeFromString(json['date_created']); } catch(e) { debugPrint(e.toString()); }
    try { dateUpdatedUtc    = groupUtcDateTimeFromString(json['date_updated']); } catch(e) { debugPrint(e.toString()); }
    try { imageURL          = json['image_url'];     } catch(e) { debugPrint(e.toString()); }
    try { webURL            = json['web_url'];       } catch(e) { debugPrint(e.toString()); }
    try { tags              = JsonUtils.listStringsValue(json['tags']); } catch(e) { debugPrint(e.toString()); }
    try { membershipQuest   = GroupMembershipQuest.fromJson(json['membershipQuest']); } catch(e) { debugPrint(e.toString()); }
    try { members           = Member.listFromJson(json['members']); } catch(e) { debugPrint(e.toString()); }
    try { questions         = GroupMembershipQuestion.listFromStringList(JsonUtils.stringListValue(json['membership_questions'])); } catch(e) { debugPrint(e.toString()); }
  }

  Map<String, dynamic> toJson({bool withId = true}) {
    Map<String, dynamic> json = {};
    if(withId){
      json['id']                 = id;
    }
    json['category']             = category;
    json['type']                 = type;
    json['title']                = title;
    json['description']          = description;
    json['privacy']              = groupPrivacyToString(privacy);
    json['certified']            = certified;
    json['authman_enabled']      = authManEnabled;
    json['authman_group']        = authManGroupName;
    json['date_created']         = groupUtcDateTimeToString(dateCreatedUtc);
    json['date_updated']         = groupUtcDateTimeToString(dateUpdatedUtc);
    json['image_url']            = imageURL;
    json['web_url']              = webURL;
    json['tags']                 = tags;
    json['members']              = Member.listToJson(members);
    json['membership_questions'] = GroupMembershipQuestion.listToStringList(questions);

    return json;
  }

  void _initFromOther(Group? other) {
    id                = other?.id;
    category          = other?.category;
    type              = other?.type;
    title             = other?.title;
    description       = other?.description;
    privacy           = other?.privacy;
    certified         = other?.certified;
    authManEnabled    = other?.authManEnabled;
    authManGroupName  = other?.authManGroupName;
    dateCreatedUtc    = other?.dateCreatedUtc;
    dateUpdatedUtc    = other?.dateUpdatedUtc;
    imageURL          = other?.imageURL;
    webURL            = other?.webURL;
    members           = other?.members;
    tags              = (other?.tags != null) ? List.from(other!.tags!) : null;
    questions         = GroupMembershipQuestion.listFromOthers(other?.questions);
    membershipQuest   = GroupMembershipQuest.fromOther(other?.membershipQuest);
  }

  List<Member> getMembersByStatus(GroupMemberStatus? status){
    if(CollectionUtils.isNotEmpty(members) && status != null){
      return members!.where((member) => member.status == status).toList();
    }
    return [];
  }

  Member? getMembersById(String? id){
    if(CollectionUtils.isNotEmpty(members) && StringUtils.isNotEmpty(id)){
      for(Member? member in members!){
        if(member!.id == id){
          return member;
        }
      }
    }
    return null;
  }

  Member? get currentUserAsMember{
    if(Auth2().isOidcLoggedIn && CollectionUtils.isNotEmpty(members)) {
      for (Member? member in members!) {
        if (member!.userId == Auth2().accountId) {
          return member;
        }
      }
    }
    return null;
  }

  bool get currentUserIsAdmin{
    return (currentUserAsMember?.isAdmin ?? false);
  }

  bool get currentUserIsPendingMember{
    return (currentUserAsMember?.isPendingMember ?? false);
  }

  bool get currentUserIsMember{
    Member? currentUser = currentUserAsMember;
    return (currentUser?.isMember ?? false);
  }

  bool get currentUserIsMemberOrAdmin{
    Member? currentUser = currentUserAsMember;
    return (currentUser?.isMember ?? false) || (currentUser?.isAdmin ?? false);
  }

  bool get currentUserCanJoin {
    return (currentUserAsMember == null) && (authManEnabled != true);
  }

  int get adminsCount{
    int adminsCount = 0;
    if(CollectionUtils.isNotEmpty(members)){
      for(Member? member in members!){
        if(member!.isAdmin){
          adminsCount++;
        }
      }
    }
    return adminsCount;
  }

  int get membersCount{
    int membersCount = 0;
    if(CollectionUtils.isNotEmpty(members)){
      for(Member? member in members!){
        if(member!.isAdmin || member.isMember){
          membersCount++;
        }
      }
    }
    return membersCount;
  }

  int get pendingCount{
    int membersCount = 0;
    if(CollectionUtils.isNotEmpty(members)){
      for(Member? member in members!){
        if(member!.isPendingMember){
          membersCount++;
        }
      }
    }
    return membersCount;
  }

  static List<Group>? listFromJson(List<dynamic>? json) {
    List<Group>? values;
    if (json != null) {
      values = <Group>[];
      for (dynamic entry in json) {
        ListUtils.add(values, Group.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<Group>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (Group value in values) {
        json.add(value.toJson());
      }
    }
    return json;
  }
}

//////////////////////////////
// GroupPrivacy

enum GroupPrivacy { private, public }

GroupPrivacy? groupPrivacyFromString(String? value) {
  if (value != null) {
    if (value == 'private') {
      return GroupPrivacy.private;
    }
    else if (value == 'public') {
      return GroupPrivacy.public;
    }
  }
  return null;
}

String? groupPrivacyToString(GroupPrivacy? value) {
  if (value != null) {
    if (value == GroupPrivacy.private) {
      return 'private';
    }
    else if (value == GroupPrivacy.public) {
      return 'public';
    }
  }
  return null;
}

//////////////////////////////
// Member

class Member {
	String?            id;
  String?            userId;
  String?            externalId;
	String?            name;
	String?            email;
	String?            photoURL;
  GroupMemberStatus? status;
  String?            officerTitle;
  
  DateTime?          dateCreatedUtc;
  DateTime?          dateUpdatedUtc;

  List<GroupMembershipAnswer>? answers;

  Member({Map<String, dynamic>? json, Member? other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    List<dynamic>? _answers = json['member_answers'];
    try { id          = json['id'];      } catch(e) { debugPrint(e.toString()); }
    try { userId      = json['user_id'];      } catch(e) { debugPrint(e.toString()); }
    try { externalId  = json['external_id'];      } catch(e) { debugPrint(e.toString()); }
    try { name        = json['name'];     } catch(e) { debugPrint(e.toString()); }
    try { email       = json['email'];     } catch(e) { debugPrint(e.toString()); }
    try { photoURL    = json['photo_url']; } catch(e) { debugPrint(e.toString()); }
    try { status       = groupMemberStatusFromString(json['status']); } catch(e) { debugPrint(e.toString()); }
    try { officerTitle = json['officerTitle']; } catch(e) { debugPrint(e.toString()); }
    try {
      answers = GroupMembershipAnswer.listFromJson(_answers);
    } catch (e) {
      debugPrint(e.toString());
    }

    try { dateCreatedUtc    = groupUtcDateTimeFromString(json['date_created']); } catch(e) { debugPrint(e.toString()); }
    try { dateUpdatedUtc    = groupUtcDateTimeFromString(json['date_updated']); } catch(e) { debugPrint(e.toString()); }
  }

  void _initFromOther(Member? other) {
    id             = other?.id;
    userId         = other?.userId;
    externalId     = other?.externalId;
    name           = other?.name;
    photoURL       = other?.photoURL;
    status         = other?.status;
    officerTitle   = other?.officerTitle;
    answers        = other?.answers;
    dateCreatedUtc = other?.dateCreatedUtc;
    dateUpdatedUtc = other?.dateUpdatedUtc;
  }

  static Member? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Member(json: json) : null;
  }

  static Member? fromOther(Member? other) {
    return (other != null) ? Member(other: other) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id']                  = id;
    json['user_id']             = userId;
    json['external_id']         = externalId;
    json['name']                = name;
    json['email']               = email;
    json['photo_url']           = photoURL;
    json['status']              = groupMemberStatusToString(status);
    json['officerTitle']        = officerTitle;
    json['answers']             = CollectionUtils.isNotEmpty(answers) ? answers!.map((answer) => answer.toJson()).toList() : null;
    json['date_created']        = groupUtcDateTimeToString(dateCreatedUtc);
    json['date_updated']        = groupUtcDateTimeToString(dateUpdatedUtc);

    return json;
  }

  String get displayName {
    String displayName = '';
    if (StringUtils.isNotEmpty(name)) {
      displayName += name!;
    }
    if (StringUtils.isNotEmpty(email)) {
      if (StringUtils.isNotEmpty(displayName)) {
        displayName += ' ';
      }
      displayName += email!;
    }
    if (StringUtils.isNotEmpty(externalId)) {
      if (StringUtils.isNotEmpty(displayName)) {
        displayName += ' ';
      }
      displayName += externalId!;
    }
    return displayName;
  }

  String get displayShortName {
    if (StringUtils.isNotEmpty(name)) {
      return name!;
    }
    if (StringUtils.isNotEmpty(email)) {
      return email!;
    }
    if (StringUtils.isNotEmpty(externalId)) {
      return externalId!;
    }
    return "";
  }


  @override
  bool operator == (dynamic other) {
    return (other is Member) &&
           (other.id == id) &&
           (other.userId == userId) &&
           (other.externalId == externalId) &&
           (other.name == name) &&
           (other.email == email) &&
           (other.photoURL == photoURL) &&
           (other.status == status) &&
           (other.officerTitle == officerTitle) &&
           (other.dateCreatedUtc == dateCreatedUtc) &&
           (other.dateUpdatedUtc == dateUpdatedUtc) &&
            const DeepCollectionEquality().equals(other.answers, answers);
  }

  @override
  int get hashCode {
    return (id?.hashCode ?? 0) ^
           (userId?.hashCode ?? 0) ^
           (externalId?.hashCode ?? 0) ^
           (name?.hashCode ?? 0) ^
           (email?.hashCode ?? 0) ^
           (photoURL?.hashCode ?? 0) ^
           (status?.hashCode ?? 0) ^
           (officerTitle?.hashCode ?? 0) ^
           (dateCreatedUtc?.hashCode ?? 0) ^
           (dateUpdatedUtc?.hashCode ?? 0) ^
           (answers?.hashCode ?? 0);
  }

  bool get isAdmin           => status == GroupMemberStatus.admin;
  bool get isMember          => status == GroupMemberStatus.member;
  bool get isPendingMember   => status == GroupMemberStatus.pending;
  bool get isRejected        => status == GroupMemberStatus.rejected;

  static List<Member>? listFromJson(List<dynamic>? json) {
    List<Member>? values;
    if (json != null) {
      values = <Member>[];
      for (dynamic entry in json) {
        ListUtils.add(values, Member.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<Member>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (Member? value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }
}

//////////////////////////////
// GroupMemberStatus

enum GroupMemberStatus { pending, member, admin, rejected }

GroupMemberStatus? groupMemberStatusFromString(String? value) {
  if (value != null) {
    if (value == 'pending') {
      return GroupMemberStatus.pending;
    } else if (value == 'member') {
      return GroupMemberStatus.member;
    } else if (value == 'admin') {
      return GroupMemberStatus.admin;
    } else if (value == 'rejected') {
      return GroupMemberStatus.rejected;
    }
  }
  return null;
}

String? groupMemberStatusToString(GroupMemberStatus? value) {
  if (value != null) {
    if (value == GroupMemberStatus.pending) {
      return 'pending';
    } else if (value == GroupMemberStatus.member) {
      return 'member';
    } else if (value == GroupMemberStatus.admin) {
      return 'admin';
    } else if (value == GroupMemberStatus.rejected) {
      return 'rejected';
    }
  }
  return null;
}

//////////////////////////////
// GroupMembershipQuest

class GroupMembershipQuest {
  List<GroupMembershipStep>? steps;

  GroupMembershipQuest({Map<String, dynamic>? json, GroupMembershipQuest? other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { steps     = GroupMembershipStep.listFromJson(json['steps']); } catch(e) { debugPrint(e.toString()); }
  }

  void _initFromOther(GroupMembershipQuest other) {
    steps = GroupMembershipStep.listFromOthers(other.steps);
  }

  static GroupMembershipQuest? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GroupMembershipQuest(json: json) : null;
  }

  static GroupMembershipQuest? fromOther(GroupMembershipQuest? other) {
    return (other != null) ? GroupMembershipQuest(other: other) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['steps']     = GroupMembershipStep.listToJson(steps);
    return json;
  }
}

//////////////////////////////
// GroupMembershipStep

class GroupMembershipStep {
	String?       description;
  List<String>? eventIds;

  GroupMembershipStep({Map<String, dynamic>? json, GroupMembershipStep? other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { description = json['description'];   } catch(e) { debugPrint(e.toString()); }
    try { eventIds    = JsonUtils.stringListValue(json['eventIds']); } catch(e) { debugPrint(e.toString()); }
  }

  void _initFromOther(GroupMembershipStep? other) {
    
	  description = (other != null) ? other.description : null;
    eventIds    = (other?.eventIds != null) ? List.from(other!.eventIds!) : null;
  }

  static GroupMembershipStep? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GroupMembershipStep(json: json) : null;
  }

  static GroupMembershipStep? fromOther(GroupMembershipStep? other) {
    return (other != null) ? GroupMembershipStep(other: other) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['description'] = description;
    json['eventIds']    = eventIds;
    return json;
  }

  static List<GroupMembershipStep>? listFromJson(List<dynamic>? json) {
    List<GroupMembershipStep>? values;
    if (json != null) {
      values = [];
      for (dynamic entry in json) {
        ListUtils.add(values, GroupMembershipStep.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<GroupMembershipStep>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = [];
      for (GroupMembershipStep? value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }

  static List<GroupMembershipStep>? listFromOthers(List<GroupMembershipStep>? others) {
    List<GroupMembershipStep>? values;
    if (others != null) {
      values = [];
      for (GroupMembershipStep? other in others) {
          ListUtils.add(values, GroupMembershipStep.fromOther(other));
      }
    }
    return values;
  }
}

//////////////////////////////
// GroupMembershipQuestion

class GroupMembershipQuestion {
	String?       question;

  GroupMembershipQuestion({this.question});

  static GroupMembershipQuestion? fromString(String? question) {
    return (question != null) ? GroupMembershipQuestion(question: question) : null;
  }

  String? toStirng() {
    return question;
  }

  static List<GroupMembershipQuestion>? listFromOthers(List<GroupMembershipQuestion>? others) {
    List<GroupMembershipQuestion>? values;
    if (others != null) {
      values = [];
      for (GroupMembershipQuestion? other in others) {
        ListUtils.add(values, GroupMembershipQuestion.fromString(other!.question));
      }
    }
    return values;
  }

  static List<GroupMembershipQuestion>? listFromStringList(List<String>? strings) {
    List<GroupMembershipQuestion>? values;
    if (strings != null) {
      values = <GroupMembershipQuestion>[];
      for (String string in strings) {
        ListUtils.add(values, GroupMembershipQuestion.fromString(string));
      }
    }
    return values;
  }

  static List<String>? listToStringList(List<GroupMembershipQuestion>? values) {
    List<String>? strings;
    if (values != null) {
      strings = <String>[];
      for (GroupMembershipQuestion value in values) {
        ListUtils.add(strings, value.question);
      }
    }
    return strings;
  }
}

//////////////////////////////
// GroupMembershipQuestionAnswer

class GroupMembershipAnswer {
  String?       question;
  String?       answer;

  GroupMembershipAnswer({this.question, this.answer});

  static GroupMembershipAnswer? fromJson(Map<String, dynamic>? json){
    return json != null ? GroupMembershipAnswer(question: json["question"], answer: json["answer"]) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "question": question,
      "answer": answer,
    };
  }


  static List<GroupMembershipAnswer>? listFromJson(List<dynamic>? json) {
    List<GroupMembershipAnswer>? values;
    if (json != null) {
      values = [];
      for (dynamic entry in json) {
        ListUtils.add(values, GroupMembershipAnswer.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<GroupMembershipAnswer>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = [];
      for (GroupMembershipAnswer value in values) {
        json.add(value.toJson());
      }
    }
    return json;
  }
}

//////////////////////////////
// GroupEvent

class GroupEvent extends Event {
  List<GroupEventComment>? comments;
  
  GroupEvent({Map<String, dynamic>? json}) : super(json: json) {
    if (json != null) {
      _initFromJson(json);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { comments = GroupEventComment.listFromJson(json['comments']); } catch(e) { debugPrint(e.toString()); }
  }

  static GroupEvent? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GroupEvent(json: json) : null;
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['comments']  = GroupEventComment.listToJson(comments);
    return json;
  }
}

//////////////////////////////
// GroupEventComment

class GroupEventComment {
  Member?       member;
  DateTime?     dateCreated;
	String?       text;

  GroupEventComment({Map<String, dynamic>? json}) {
    if (json != null) {
      _initFromJson(json);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { member      = Member.fromJson(json['member']); } catch(e) { debugPrint(e.toString()); }
    try { dateCreated = DateTimeUtils.dateTimeFromString(json['dateCreated'], format: AppDateTime.iso8601DateTimeFormat); } catch(e) { debugPrint(e.toString()); }
    try { text         = json['text']; } catch(e) { debugPrint(e.toString()); }
  }

  static GroupEventComment? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GroupEventComment(json: json) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['member'] = member?.toJson();
    json['dateCreated'] = AppDateTime().formatDateTime(dateCreated, format: AppDateTime.iso8601DateTimeFormat);
    json['text'] = text;
    return json;
  }

  static List<GroupEventComment>? listFromJson(List<dynamic>? json) {
    List<GroupEventComment>? values;
    if (json != null) {
      values = [];
      for (dynamic entry in json) {
        ListUtils.add(values, GroupEventComment.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<GroupEventComment>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = [];
      for (GroupEventComment? value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }
}

//////////////////////////////
// GroupPost

class GroupPost {
  final String? id;
  final String? parentId;
  final Member? member;
  final String? subject;
  final String? body;
  final DateTime? dateCreatedUtc;
  final DateTime? dateUpdatedUtc;
  final bool? private;
  final List<GroupPost>? replies;
  final String? imageUrl;

  GroupPost({this.id, this.parentId, this.member, this.subject, this.body, this.dateCreatedUtc, this.dateUpdatedUtc, this.private, this.imageUrl, this.replies});

  static GroupPost? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GroupPost(
        id: json['id'],
        parentId: json['parent_id'],
        member: Member.fromJson(json['member']),
        subject: json['subject'],
        body: json['body'],
        dateCreatedUtc: groupUtcDateTimeFromString(json['date_created']),
        dateUpdatedUtc: groupUtcDateTimeFromString(json['date_updated']),
        private: json['private'],
        imageUrl: JsonUtils.stringValue(json["image_url"]),
        replies: GroupPost.fromJsonList(json['replies'])) : null;
  }

  Map<String, dynamic> toJson({bool create = false, bool update = false}) {
    // MV: This does not look well at all!
    Map<String, dynamic> json = {'body': body, 'private': private};
    if ((parentId != null) && create) {
      json['parent_id'] = parentId;
    }
    if ((id != null) && update) {
      json['id'] = id;
    }
    if (subject != null) {
      json['subject'] = subject;
    }
    if(imageUrl!=null){
      json['image_url'] = imageUrl;
    }
    return json;
  }

  bool get isUpdated {
    return (dateUpdatedUtc != null) && (dateCreatedUtc != dateUpdatedUtc);
  }

  static List<GroupPost>? fromJsonList(List<dynamic>? jsonList) {
    List<GroupPost>? posts;
    if (jsonList != null) {
      posts = [];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(posts, GroupPost.fromJson(jsonEntry));
      }
    }
    return posts;
  }
}

//Model for editable post data. Helping to keep GroupPost immutable. Internal use
class PostDataModel {
  String? body;
  String? subject;
  String? imageUrl;

  PostDataModel({this.body, this.subject, this.imageUrl});
}

//////////////////////////////
// GroupError

class GroupError {
  int?       code;
  String?    text;

  GroupError({this.code, this.text});

  static GroupError? fromJson(Map<String, dynamic>? json){
    return json != null ? GroupError(
      code: JsonUtils.intValue(json['code']),
      text: JsonUtils.stringValue(json['text'])
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "code": code,
      "text": text,
    };
  }
}

DateTime? groupUtcDateTimeFromString(String? dateTimeString) {
  return DateTimeUtils.dateTimeFromString(dateTimeString, format: "yyyy-MM-ddTHH:mm:ssZ", isUtc: true);
}

String? groupUtcDateTimeToString(DateTime? dateTime) {
  if (dateTime != null) {
    try { return DateFormat("yyyy-MM-ddTHH:mm:ss").format(dateTime) + 'Z'; }
    catch (e) { debugPrint(e.toString()); }
  }
  return null;
}

