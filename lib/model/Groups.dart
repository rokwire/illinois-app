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

import 'package:illinois/model/Event.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/utils/Utils.dart';

//////////////////////////////
// Group

class Group {
	String              id;
	String              category;
	String              type;
	String              title;
	bool                certified;

  GroupPrivacy         privacy;
  String               description;
  String               imageURL;
  String               webURL;
  int                  membersCount;
  List<Member>         members;
  List<String>         tags;
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

  void _initFromJson(Map<String, dynamic> json) {
    try { id              = json['id'];         } catch(e) { print(e.toString()); }
    try { category        = json['category'];   } catch(e) { print(e.toString()); }
    try { type            = json['type'];       } catch(e) { print(e.toString()); }
    try { title           = json['title'];      } catch(e) { print(e.toString()); }
    try { certified       = json['certified']; } catch(e) { print(e.toString()); }
    try { privacy         = groupPrivacyFromString(json['privacy']); } catch(e) { print(e.toString()); }
    try { description     = json['description'];  } catch(e) { print(e.toString()); }
    try { imageURL        = json['image_url'];     } catch(e) { print(e.toString()); }
    try { webURL          = json['web_url'];       } catch(e) { print(e.toString()); }
    try { tags            = (json['tags'] as List)?.cast<String>(); } catch(e) { print(e.toString()); }
    try { membershipQuest = GroupMembershipQuest.fromJson(json['membershipQuest']); } catch(e) { print(e.toString()); }
    try { membersCount    = json['members_count']; } catch(e) { print(e.toString()); }
    try {
      List<dynamic> _members    = json['members'];
      if(AppCollection.isCollectionNotEmpty(_members)){
        members = _members.map((memberJson) => Member.fromJson(memberJson)).toList();
      }
    } catch(e) { print(e.toString()); }
    try {
      List<dynamic> _questions    = json['membership_questions'];
      if(AppCollection.isCollectionNotEmpty(_questions)){
        questions =  _questions.map((e) => GroupMembershipQuestion.fromString(e.toString())).toList();
      }
    } catch(e) { print(e.toString()); }
  }

  void _initFromOther(Group other) {
    id              = other?.id;
    category        = other?.category;
    type            = other?.type;
    title           = other?.title;
    certified       = other?.certified;
    privacy         = other?.privacy;
    description     = other?.description;
    imageURL        = other?.imageURL;
    webURL          = other?.webURL;
    membersCount    = other?.membersCount;
    members         = other?.members;
    tags            = (other?.tags != null) ? List.from(other?.tags) : null;
    questions       = (other?.questions != null) ? other.questions.map((e) => GroupMembershipQuestion.fromString(e.question)).toList()  : null;
    membershipQuest = GroupMembershipQuest.fromOther(other?.membershipQuest);
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Group(json: json) : null;
  }

  factory Group.fromOther(Group other) {
    return (other != null) ? Group(other: other) : null;
  }

  Map<String, dynamic> toJson({bool withId = true}) {
    Map<String, dynamic> json = {};
    if(withId){
      json['id'] = id;
    }
    json['category']          = category;
    json['type']              = type;
    json['title']             = title;
    json['certified']         = certified;
    json['privacy']           = groupPrivacyToString(privacy);
    json['description']       = description;
    json['image_url']         = imageURL;
    json['web_url']           = webURL;
    json['tags']              = tags;
    json['members_count']     = membersCount;
    json['members']           = members;
    json['membership_questions']= AppCollection.isCollectionNotEmpty(questions) ? questions.map((e) => e?.question ?? "").toList() : null;
    json['membershipQuest']   = membershipQuest?.toJson();

    return json;
  }

  List<Member> getMembersByStatus(GroupMemberStatus status){
    if(AppCollection.isCollectionNotEmpty(members) && status != null){
      return members.where((member) => member.status == status).toList();
    }
    return [];
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

  bool get currentUserIsUserAdmin{
    if(Auth().isShibbolethLoggedIn && AppCollection.isCollectionNotEmpty(members)){
      for(Member member in members){
        if(member.email == Auth()?.authInfo?.email && member.status == GroupMemberStatus.admin){
          return true;
        }
      }
    }
    return false;
  }

  bool get currentUserIsPendingMember{
    if(Auth().isShibbolethLoggedIn && AppCollection.isCollectionNotEmpty(members)){
      for(Member member in members){
        if(member.email == Auth()?.authInfo?.email && member.status == GroupMemberStatus.pending){
          return true;
        }
      }
    }
    return false;
  }

  bool get currentUserIsGenericMember{
    if(Auth().isShibbolethLoggedIn && AppCollection.isCollectionNotEmpty(members)){
      for(Member member in members){
        if(member.email == Auth()?.authInfo?.email){
          return true;
        }
      }
    }
    return false;
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
    if(member != null){
      switch(member.status){
        case GroupMemberStatus.admin    :  return Styles().colors.fillColorSecondary;
        case GroupMemberStatus.member   :  return Styles().colors.fillColorPrimary;
        case GroupMemberStatus.pending  :  return Styles().colors.mediumGray1;
      }
    }
    return Styles().colors.white;
  }

  String get currentUserStatusText{
    Member member = currentUserAsMember;
    if(member != null){
      switch(member.status){
        case GroupMemberStatus.admin    :  return "ADMIN";
        case GroupMemberStatus.member   :  return "MEMBER";
        case GroupMemberStatus.pending  :  return "PENDING MEMBERSHIP";
      }
    }
    return "";
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
  DateTime          dateAdded;

  Member({Map<String, dynamic> json, Member other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { id          = json['id'];      } catch(e) { print(e.toString()); }
    try { name        = json['name'];     } catch(e) { print(e.toString()); }
    try { email       = json['email'];    } catch(e) { print(e.toString()); }
    try { photoURL    = json['photo_url']; } catch(e) { print(e.toString()); }
    try { status       = groupMemberStatusFromString(json['status']); } catch(e) { print(e.toString()); }
    try { officerTitle = json['officerTitle']; } catch(e) { print(e.toString()); }

  }

  void _initFromOther(Member other) {
    id          = other?.id;
    name        = other?.name;
    email       = other?.email;
    photoURL    = other?.photoURL;
    status      = other?.status;
    officerTitle= other?.officerTitle;
    dateAdded   = other?.dateAdded;
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
    json['dateAdded']           = AppDateTime().formatDateTime(dateAdded, format: AppDateTime.iso8601DateTimeFormat);
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
           (o.dateAdded == dateAdded);
  }

  int get hashCode {
    return (id?.hashCode ?? 0) ^
           (name?.hashCode ?? 0) ^
           (email?.hashCode ?? 0) ^
           (photoURL?.hashCode ?? 0) ^
           (status?.hashCode ?? 0) ^
           (officerTitle?.hashCode ?? 0) ^
           (dateAdded?.hashCode ?? 0);
  }

  bool get isAdmin           => status == GroupMemberStatus.admin;
  bool get isMember          => status == GroupMemberStatus.member;
  bool get isPendingMember   => status == GroupMemberStatus.pending;
}

//////////////////////////////
// GroupMemberStatus

enum GroupMemberStatus { pending, member, admin }

GroupMemberStatus groupMemberStatusFromString(String value) {
  if (value != null) {
    if (value == 'pending') {
      return GroupMemberStatus.pending;
    }
    else if (value == 'member') {
      return GroupMemberStatus.member;
    }
    else if (value == 'admin') {
      return GroupMemberStatus.admin;
    }
  }
  return null;
}

String groupMemberStatusToString(GroupMemberStatus value) {
  if (value != null) {
    if (value == GroupMemberStatus.pending) {
      return 'pending';
    }
    else if (value == GroupMemberStatus.member) {
      return 'member';
    }
    else if (value == GroupMemberStatus.admin) {
      return 'admin';
    }
  }
  return null;
}

String groupMemberStatusToDisplayString(GroupMemberStatus value) {
  if (value != null) {
    if (value == GroupMemberStatus.pending) {
      return Localization().getStringEx('model.groups.member.status.pending', 'Pending');
    }
    else if (value == GroupMemberStatus.member) {
      return Localization().getStringEx('model.groups.member.status.member', 'Member');
    }
    else if (value == GroupMemberStatus.admin) {
      return Localization().getStringEx('model.groups.member.status.admin', 'Admin');
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
}

//////////////////////////////
// GroupMembershipAnswer

class GroupMembershipQuestionAnswer {
  String       question;
  String       answer;

  GroupMembershipQuestionAnswer({this.question, this.answer});

  factory GroupMembershipQuestionAnswer.fromJson(Map<String, dynamic> json){
    return json != null ? GroupMembershipQuestionAnswer(question: json["question"], answer: json["answer"]) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "question": question,
      "answer": answer,
    };
  }


  static List<GroupMembershipQuestionAnswer> listFromJson(List<dynamic> json) {
    List<GroupMembershipQuestionAnswer> values;
    if (json != null) {
      values = [];
      for (dynamic entry in json) {
          GroupMembershipQuestionAnswer value;
          try { value = GroupMembershipQuestionAnswer.fromJson((entry as Map)?.cast<String, dynamic>()); }
          catch(e) { print(e.toString()); }
          values.add(value);
      }
    }
    return values;
  }

  static List<dynamic> listToJson(List<GroupMembershipQuestionAnswer> values) {
    List<dynamic> json;
    if (values != null) {
      json = [];
      for (GroupMembershipQuestionAnswer value in values) {
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
