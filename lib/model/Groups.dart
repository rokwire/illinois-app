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

import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

//////////////////////////////
// Group

class Group {
	String              id;
	String              category;
	String              type;
	String              title;
  String              description;
  GroupPrivacy        privacy;
	bool                certified;
  DateTime            dateCreatedUtc;
  DateTime            dateUpdatedUtc;

  String              imageURL;
  String              webURL;
  List<Member>        members;
  List<String>        tags;
  List<GroupMembershipQuestion>  questions;
  GroupMembershipQuest membershipQuest; // MD: Looks as deprecated. Consider and remove if need!

  Group({Map<String, dynamic> json, Group other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Group(json: json) : null;
  }

  factory Group.fromOther(Group other) {
    return (other != null) ? Group(other: other) : null;
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { id              = json['id'];         } catch(e) { print(e.toString()); }
    try { category        = json['category'];   } catch(e) { print(e.toString()); }
    try { type            = json['type'];       } catch(e) { print(e.toString()); }
    try { title           = json['title'];      } catch(e) { print(e.toString()); }
    try { description     = json['description'];  } catch(e) { print(e.toString()); }
    try { privacy         = groupPrivacyFromString(json['privacy']); } catch(e) { print(e.toString()); }
    try { certified       = json['certified']; } catch(e) { print(e.toString()); }
    try { dateCreatedUtc  = groupUtcDateTimeFromString(json['date_created']); } catch(e) { print(e.toString()); }
    try { dateUpdatedUtc  = groupUtcDateTimeFromString(json['date_updated']); } catch(e) { print(e.toString()); }
    try { imageURL        = json['image_url'];     } catch(e) { print(e.toString()); }
    try { webURL          = json['web_url'];       } catch(e) { print(e.toString()); }
    try { tags            = (json['tags'] as List)?.cast<String>(); } catch(e) { print(e.toString()); }
    try { membershipQuest = GroupMembershipQuest.fromJson(json['membershipQuest']); } catch(e) { print(e.toString()); }
    try { members         = Member.listFromJson(json['members']); } catch(e) { print(e.toString()); }
    try { questions       = GroupMembershipQuestion.listFromStringList((json['membership_questions'] as List)?.cast<String>()); } catch(e) { print(e.toString()); }
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
    json['date_created']         = groupUtcDateTimeToString(dateCreatedUtc);
    json['date_updated']         = groupUtcDateTimeToString(dateUpdatedUtc);
    json['image_url']            = imageURL;
    json['web_url']              = webURL;
    json['tags']                 = tags;
    json['members']              = Member.listToJson(members);
    json['membership_questions'] = GroupMembershipQuestion.listToStringList(questions);

    return json;
  }

  void _initFromOther(Group other) {
    id              = other?.id;
    category        = other?.category;
    type            = other?.type;
    title           = other?.title;
    description     = other?.description;
    privacy         = other?.privacy;
    certified       = other?.certified;
    dateCreatedUtc  = other?.dateCreatedUtc;
    dateUpdatedUtc  = other?.dateUpdatedUtc;
    imageURL        = other?.imageURL;
    webURL          = other?.webURL;
    members         = other?.members;
    tags            = (other?.tags != null) ? List.from(other?.tags) : null;
    questions       = (other?.questions != null) ? other.questions.map((e) => GroupMembershipQuestion.fromString(e.question)).toList()  : null;
    membershipQuest = GroupMembershipQuest.fromOther(other?.membershipQuest);
  }

  List<Member> getMembersByStatus(GroupMemberStatus status){
    if(AppCollection.isCollectionNotEmpty(members) && status != null){
      return members.where((member) => member.status == status).toList();
    }
    return [];
  }

  Member getMembersById(String id){
    if(AppCollection.isCollectionNotEmpty(members) && AppString.isStringNotEmpty(id)){
      for(Member member in members){
        if(member.id == id){
          return member;
        }
      }
    }
    return null;
  }

  Member get currentUserAsMember{
    if(Auth().isShibbolethLoggedIn && AppCollection.isCollectionNotEmpty(members)) {
      for (Member member in members) {
        if (member.email == Auth()?.authInfo?.email) {
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

  bool get currentUserIsMemberOrAdmin{
    Member currentUser = currentUserAsMember;
    return (currentUser?.isMember ?? false) || (currentUser?.isAdmin ?? false);
  }

  bool get currentUserCanJoin{
    return currentUserAsMember == null;
  }

  bool get currentUserIsUserMember{
    if(Auth().isShibbolethLoggedIn && AppCollection.isCollectionNotEmpty(members)){
      for(Member member in members){
        if(member.email == Auth()?.authInfo?.email && member.status != GroupMemberStatus.pending){
          return true;
        }
      }
    }
    return false;
  }

  Color get currentUserStatusColor{
    Member member = currentUserAsMember;
    if(member?.status != null){
      return groupMemberStatusToColor(member.status);
    }
    return Styles().colors.white;
  }

  String get currentUserStatusText{
    Member member = currentUserAsMember;
    if(member?.status != null){
      return groupMemberStatusToDisplayString(member.status);
    }
    return "";
  }

  int get adminsCount{
    int adminsCount = 0;
    if(AppCollection.isCollectionNotEmpty(members)){
      for(Member member in members){
        if(member.isAdmin){
          adminsCount++;
        }
      }
    }
    return adminsCount;
  }

  int get membersCount{
    int membersCount = 0;
    if(AppCollection.isCollectionNotEmpty(members)){
      for(Member member in members){
        if(member.isAdmin || member.isMember){
          membersCount++;
        }
      }
    }
    return membersCount;
  }

  int get pendingCount{
    int membersCount = 0;
    if(AppCollection.isCollectionNotEmpty(members)){
      for(Member member in members){
        if(member.isPendingMember){
          membersCount++;
        }
      }
    }
    return membersCount;
  }

  String get displayUpdateTime {
    DateTime deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateUpdatedUtc);
    //return AppDateTime().formatDateTime(deviceDateTime, format: AppDateTime.groupPostDateTimeFormat);
    if (deviceDateTime != null) {
      DateTime now = DateTime.now();
      if (deviceDateTime.compareTo(now) < 0) {
        Duration difference = DateTime.now().difference(deviceDateTime);
        if (difference.inSeconds < 60) {
          return Localization().getStringEx('model.group.updated.now', 'Updated now');
        }
        else if (difference.inMinutes < 60) {
          return sprintf((difference.inMinutes != 1) ?
            Localization().getStringEx('model.group.updated.minutes', 'Updated about %s minutes ago') :
            Localization().getStringEx('model.group.updated.minute', 'Updated about a minute ago'),
            [difference.inMinutes]);
        }
        else if (difference.inHours < 24) {
          return sprintf((difference.inHours != 1) ?
            Localization().getStringEx('model.group.updated.hours', 'Updated about %s hours ago') :
            Localization().getStringEx('model.group.updated.hour', 'Updated about an hour ago'),
            [difference.inHours]);
        }
        else if (difference.inDays < 30) {
          return sprintf((difference.inDays != 1) ?
            Localization().getStringEx('model.group.updated.days', 'Updated about %s days ago') :
            Localization().getStringEx('model.group.updated.day', 'Updated about a day ago'),
            [difference.inDays]);
        }
        else {
          int differenceInMonths = difference.inDays ~/ 30;
          if (differenceInMonths < 12) {
            return sprintf((differenceInMonths != 1) ?
              Localization().getStringEx('model.group.updated.months', 'Updated about %s months ago') :
              Localization().getStringEx('model.group.updated.month', 'Updated about a month ago'),
              [differenceInMonths]);
          }
        }
      }
      String value = DateFormat("MMM dd, yyyy").format(deviceDateTime);
      return sprintf(
        Localization().getStringEx('model.group.updated.date', 'Updated on %s'),
        [value]);
    }
    return null;
  }

  static List<Group> listFromJson(List<dynamic> json) {
    List<Group> values;
    if (json != null) {
      values = <Group>[];
      for (dynamic entry in json) {
          try { values.add(Group.fromJson((entry as Map)?.cast<String, dynamic>())); }
          catch(e) { print(e?.toString()); }
      }
    }
    return values;
  }

  static List<dynamic> listToJson(List<Group> values) {
    List<dynamic> json;
    if (values != null) {
      json = <dynamic>[];
      for (Group value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }
}

//////////////////////////////
// GroupPrivacy

enum GroupPrivacy { private, public }

GroupPrivacy groupPrivacyFromString(String value) {
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

String groupPrivacyToString(GroupPrivacy value) {
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
	String            id;
	String            name;
	String            email;
	String            photoURL;
  GroupMemberStatus status;
  String            officerTitle;
  
  DateTime          dateCreatedUtc;
  DateTime          dateUpdatedUtc;

  List<GroupMembershipAnswer> answers;

  Member({Map<String, dynamic> json, Member other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    List<dynamic> _answers = json['member_answers'];
    try { id          = json['id'];      } catch(e) { print(e.toString()); }
    try { name        = json['name'];     } catch(e) { print(e.toString()); }
    try { email       = json['email'];    } catch(e) { print(e.toString()); }
    try { photoURL    = json['photo_url']; } catch(e) { print(e.toString()); }
    try { status       = groupMemberStatusFromString(json['status']); } catch(e) { print(e.toString()); }
    try { officerTitle = json['officerTitle']; } catch(e) { print(e.toString()); }
    try {
      answers = AppCollection.isCollectionNotEmpty(_answers) ? _answers.map((answerJson) => GroupMembershipAnswer.fromJson(answerJson)).toList() : null;
    } catch (e) {
      print(e.toString());
    }

    try { dateCreatedUtc    = groupUtcDateTimeFromString(json['date_created']); } catch(e) { print(e.toString()); }
    try { dateUpdatedUtc    = groupUtcDateTimeFromString(json['date_updated']); } catch(e) { print(e.toString()); }
  }

  void _initFromOther(Member other) {
    id             = other?.id;
    name           = other?.name;
    email          = other?.email;
    photoURL       = other?.photoURL;
    status         = other?.status;
    officerTitle   = other?.officerTitle;
    answers        = other?.answers;
    dateCreatedUtc = other?.dateCreatedUtc;
    dateUpdatedUtc = other?.dateUpdatedUtc;
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Member(json: json) : null;
  }

  factory Member.fromOther(Member other) {
    return (other != null) ? Member(other: other) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id']                  = id;
    json['name']                = name;
    json['email']               = email;
    json['photo_url']           = photoURL;
    json['status']              = groupMemberStatusToString(status);
    json['officerTitle']        = officerTitle;
    json['answers']             = AppCollection.isCollectionNotEmpty(answers) ? answers.map((answer) => answer.toJson()).toList() : null;
    json['date_created']        = groupUtcDateTimeToString(dateCreatedUtc);
    json['date_updated']        = groupUtcDateTimeToString(dateUpdatedUtc);

    return json;
  }

  bool operator == (dynamic o) {
    return (o is Member) &&
           (o.id == id) &&
           (o.name == name) &&
           (o.email == email) &&
           (o.photoURL == photoURL) &&
           (o.status == status) &&
           (o.officerTitle == officerTitle) &&
           (o.dateCreatedUtc == dateCreatedUtc) &&
           (o.dateUpdatedUtc == dateUpdatedUtc) &&
            DeepCollectionEquality().equals(o.answers, answers);
  }

  int get hashCode {
    return (id?.hashCode ?? 0) ^
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

  static List<Member> listFromJson(List<dynamic> json) {
    List<Member> values;
    if (json != null) {
      values = <Member>[];
      for (dynamic entry in json) {
          try { values.add(Member.fromJson((entry as Map)?.cast<String, dynamic>())); }
          catch(e) { print(e?.toString()); }
      }
    }
    return values;
  }

  static List<dynamic> listToJson(List<Member> values) {
    List<dynamic> json;
    if (values != null) {
      json = <dynamic>[];
      for (Member value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }
}

//////////////////////////////
// GroupMemberStatus

enum GroupMemberStatus { pending, member, admin, rejected }

GroupMemberStatus groupMemberStatusFromString(String value) {
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

String groupMemberStatusToString(GroupMemberStatus value) {
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

String groupMemberStatusToDisplayString(GroupMemberStatus value) {
  if (value != null) {
    if (value == GroupMemberStatus.pending) {
      return Localization().getStringEx('model.groups.member.status.pending', 'Pending');
    } else if (value == GroupMemberStatus.member) {
      return Localization().getStringEx('model.groups.member.status.member', 'Member');
    } else if (value == GroupMemberStatus.admin) {
      return Localization().getStringEx('model.groups.member.status.admin', 'Admin');
    } else if (value == GroupMemberStatus.rejected) {
      return Localization().getStringEx('model.groups.member.status.rejected', 'Denied');
    }
  }
  return null;
}

Color groupMemberStatusToColor(GroupMemberStatus value) {
  if (value != null) {
    switch(value){
      case GroupMemberStatus.admin    :  return Styles().colors.fillColorSecondary;
      case GroupMemberStatus.member   :  return Styles().colors.fillColorPrimary;
      case GroupMemberStatus.pending  :  return Styles().colors.mediumGray1;
      case GroupMemberStatus.rejected :  return Styles().colors.mediumGray1;
    }
  }
  return null;
}

//////////////////////////////
// GroupMembershipQuest

class GroupMembershipQuest {
  List<GroupMembershipStep> steps;

  GroupMembershipQuest({Map<String, dynamic> json, GroupMembershipQuest other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { steps     = GroupMembershipStep.listFromJson(json['steps']); } catch(e) { print(e.toString()); }
  }

  void _initFromOther(GroupMembershipQuest other) {
    steps = GroupMembershipStep.listFromOthers(other?.steps);
  }

  factory GroupMembershipQuest.fromJson(Map<String, dynamic> json) {
    return (json != null) ? GroupMembershipQuest(json: json) : null;
  }

  factory GroupMembershipQuest.fromOther(GroupMembershipQuest other) {
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
	String       description;
  List<String> eventIds;

  GroupMembershipStep({Map<String, dynamic> json, GroupMembershipStep other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { description = json['description'];   } catch(e) { print(e.toString()); }
    try { eventIds    = (json['eventIds'] as List)?.cast<String>(); } catch(e) { print(e.toString()); }
  }

  void _initFromOther(GroupMembershipStep other) {
	  description = other?.description;
    eventIds    = (other?.eventIds != null) ? List.from(other?.eventIds) : null;
  }

  factory GroupMembershipStep.fromJson(Map<String, dynamic> json) {
    return (json != null) ? GroupMembershipStep(json: json) : null;
  }

  factory GroupMembershipStep.fromOther(GroupMembershipStep other) {
    return (other != null) ? GroupMembershipStep(other: other) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['description'] = description;
    json['eventIds']    = eventIds;
    return json;
  }

  static List<GroupMembershipStep> listFromJson(List<dynamic> json) {
    List<GroupMembershipStep> values;
    if (json != null) {
      values = [];
      for (dynamic entry in json) {
          GroupMembershipStep value;
          try { value = GroupMembershipStep.fromJson((entry as Map)?.cast<String, dynamic>()); }
          catch(e) { print(e.toString()); }
          values.add(value);
      }
    }
    return values;
  }

  static List<dynamic> listToJson(List<GroupMembershipStep> values) {
    List<dynamic> json;
    if (values != null) {
      json = [];
      for (GroupMembershipStep value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }

  static List<GroupMembershipStep> listFromOthers(List<GroupMembershipStep> others) {
    List<GroupMembershipStep> values;
    if (others != null) {
      values = [];
      for (GroupMembershipStep other in others) {
          values.add(GroupMembershipStep.fromOther(other));
      }
    }
    return values;
  }
}

//////////////////////////////
// GroupMembershipQuestion

class GroupMembershipQuestion {
	String       question;

  GroupMembershipQuestion({this.question});

  factory GroupMembershipQuestion.fromString(String question) {
    return (question != null) ? GroupMembershipQuestion(question: question) : null;
  }

  String toStirng() {
    return question;
  }

  static List<GroupMembershipQuestion> listFromOthers(List<GroupMembershipQuestion> others) {
    List<GroupMembershipQuestion> values;
    if (others != null) {
      values = [];
      for (GroupMembershipQuestion other in others) {
        values.add(GroupMembershipQuestion.fromString(other.question));
      }
    }
    return values;
  }

  static List<GroupMembershipQuestion> listFromStringList(List<String> strings) {
    List<GroupMembershipQuestion> values;
    if (strings != null) {
      values = <GroupMembershipQuestion>[];
      for (String string in strings) {
        values.add(GroupMembershipQuestion.fromString(string));
      }
    }
    return values;
  }

  static List<String> listToStringList(List<GroupMembershipQuestion> values) {
    List<String> strings;
    if (values != null) {
      strings = <String>[];
      for (GroupMembershipQuestion value in values) {
        strings.add(value.toString());
      }
    }
    return strings;
  }
}

//////////////////////////////
// GroupMembershipQuestionAnswer

class GroupMembershipAnswer {
  String       question;
  String       answer;

  GroupMembershipAnswer({this.question, this.answer});

  factory GroupMembershipAnswer.fromJson(Map<String, dynamic> json){
    return json != null ? GroupMembershipAnswer(question: json["question"], answer: json["answer"]) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "question": question,
      "answer": answer,
    };
  }


  static List<GroupMembershipAnswer> listFromJson(List<dynamic> json) {
    List<GroupMembershipAnswer> values;
    if (json != null) {
      values = [];
      for (dynamic entry in json) {
          GroupMembershipAnswer value;
          try { value = GroupMembershipAnswer.fromJson((entry as Map)?.cast<String, dynamic>()); }
          catch(e) { print(e.toString()); }
          values.add(value);
      }
    }
    return values;
  }

  static List<dynamic> listToJson(List<GroupMembershipAnswer> values) {
    List<dynamic> json;
    if (values != null) {
      json = [];
      for (GroupMembershipAnswer value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }
}

//////////////////////////////
// GroupEvent

class GroupEvent extends Event {
  List<GroupEventComment> comments;
  
  GroupEvent({Map<String, dynamic> json}) : super(json: json) {
    if (json != null) {
      _initFromJson(json);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { comments = GroupEventComment.listFromJson(json['comments']); } catch(e) { print(e.toString()); }
  }

  factory GroupEvent.fromJson(Map<String, dynamic> json) {
    return (json != null) ? GroupEvent(json: json) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson() ?? {};
    json['comments']  = GroupEventComment.listToJson(comments);
    return json;
  }
}

//////////////////////////////
// GroupEventComment

class GroupEventComment {
  Member       member;
  DateTime     dateCreated;
	String       text;

  GroupEventComment({Map<String, dynamic> json}) {
    if (json != null) {
      _initFromJson(json);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { member      = Member.fromJson(json['member']); } catch(e) { print(e.toString()); }
    try { dateCreated = AppDateTime().dateTimeFromString(json['dateCreated'], format: AppDateTime.iso8601DateTimeFormat); } catch(e) { print(e.toString()); }
    try { text         = json['text']; } catch(e) { print(e.toString()); }
  }

  factory GroupEventComment.fromJson(Map<String, dynamic> json) {
    return (json != null) ? GroupEventComment(json: json) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['member'] = member?.toJson();
    json['dateCreated'] = AppDateTime().formatDateTime(dateCreated, format: AppDateTime.iso8601DateTimeFormat);
    json['text'] = text;
    return json;
  }

  static List<GroupEventComment> listFromJson(List<dynamic> json) {
    List<GroupEventComment> values;
    if (json != null) {
      values = [];
      for (dynamic entry in json) {
          GroupEventComment value;
          try { value = GroupEventComment.fromJson((entry as Map)?.cast<String, dynamic>()); }
          catch(e) { print(e.toString()); }
          values.add(value);
      }
    }
    return values;
  }

  static List<dynamic> listToJson(List<GroupEventComment> values) {
    List<dynamic> json;
    if (values != null) {
      json = [];
      for (GroupEventComment value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }
}

//////////////////////////////
// GroupPost

class GroupPost {
  final String id;
  final String parentId;
  final Member member;
  final String subject;
  final String body;
  final DateTime dateCreatedUtc;
  final DateTime dateUpdatedUtc;
  final bool private;
  final List<GroupPost> replies;

  GroupPost({this.id, this.parentId, this.member, this.subject, this.body, this.dateCreatedUtc, this.dateUpdatedUtc, this.private, this.replies});

  factory GroupPost.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return null;
    }
    return GroupPost(
        id: json['id'],
        parentId: json['parent_id'],
        member: Member.fromJson(json['member']),
        subject: json['subject'],
        body: json['body'],
        dateCreatedUtc: groupUtcDateTimeFromString(json['date_created']),
        dateUpdatedUtc: groupUtcDateTimeFromString(json['date_updated']),
        private: json['private'],
        replies: GroupPost.fromJsonList(json['replies']));
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
    return json;
  }

  String get displayDateTime {
    DateTime deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateCreatedUtc);
    //return AppDateTime().formatDateTime(deviceDateTime, format: AppDateTime.groupPostDateTimeFormat);
    if (deviceDateTime != null) {
      DateTime now = DateTime.now();
      if (deviceDateTime.compareTo(now) < 0) {
        Duration difference = DateTime.now().difference(deviceDateTime);
        if (difference.inSeconds < 60) {
          return "now";
        }
        else if (difference.inMinutes < 60) {
          return "${difference.inMinutes}min";
        }
        else if (difference.inHours < 24) {
          return "${difference.inHours}h";
        }
        else if (difference.inDays < 30) {
          return "${difference.inDays}d";
        }
        else {
          int differenceInMonths = difference.inDays ~/ 30;
          if (differenceInMonths < 12) {
            return "${differenceInMonths}m";
          }
        }
      }
      return DateFormat("MMM dd, yyyy").format(deviceDateTime);
    }
    return null;
  }

  bool get isUpdated {
    return (dateUpdatedUtc != null) && (dateCreatedUtc != dateUpdatedUtc);
  }

  static List<GroupPost> fromJsonList(List<dynamic> jsonList) {
    List<GroupPost> posts;
    if (jsonList != null) {
      posts = [];
      for (dynamic jsonEntry in jsonList) {
        posts.add(GroupPost.fromJson(jsonEntry));
      }
    }
    return posts;
  }
}

//////////////////////////////
// GroupError

class GroupError {
  int       code;
  String    text;

  GroupError({this.code, this.text});

  factory GroupError.fromJson(Map<String, dynamic> json){
    return json != null ? GroupError(
      code: AppJson.intValue(json['code']),
      text: AppJson.stringValue(json['text'])
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "code": code,
      "text": text,
    };
  }
}

DateTime groupUtcDateTimeFromString(String dateTimeString) {
  return AppDateTime().dateTimeFromString(dateTimeString, format: "yyyy-MM-ddTHH:mm:ssZ", isUtc: true);
}

String groupUtcDateTimeToString(DateTime dateTime) {
  if (dateTime != null) {
    try { return DateFormat("yyyy-MM-ddTHH:mm:ss").format(dateTime) + 'Z'; }
    catch (e) { print(e?.toString()); }
  }
  return null;
}

