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

import 'package:illinois/model/Event.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Localization.dart';

//////////////////////////////
// Group

class Group {
	String       id;
	String       category;
	String       type;
	String       title;
	bool         certified;

  Group({Map<String, dynamic> json, Group other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { id         = json['id'];         } catch(e) { print(e.toString()); }
    try { category   = json['category'];   } catch(e) { print(e.toString()); }
    try { type       = json['type'];       } catch(e) { print(e.toString()); }
    try { title      = json['title'];      } catch(e) { print(e.toString()); }
    try { certified  = json['certified']; } catch(e) { print(e.toString()); }
  }

  void _initFromOther(Group other) {
    id         = other?.id;
    category   = other?.category;
    type       = other?.type;
    title      = other?.title;
    certified  = other?.certified;
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Group(json: json) : null;
  }

  factory Group.fromOther(Group other) {
    return (other != null) ? Group(other: other) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id']                = id;
    json['category']          = category;
    json['type']              = type;
    json['title']             = title;
    json['certified']         = certified;
    return json;
  }
}

//////////////////////////////
// GroupDetail

class GroupDetail extends Group {
	GroupPrivacy         privacy;
	String               description;
	String               imageURL;
	String               webURL;
  int                  membersCount;
	List<String>         tags;
	GroupMembershipQuest membershipQuest;

  GroupDetail({Map<String, dynamic> json, GroupDetail other}) : super() {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  @override
  void _initFromJson(Map<String, dynamic> json) {
    super._initFromJson(json);
    try { privacy         = groupPrivacyFromString(json['privacy']); } catch(e) { print(e.toString()); }
    try { description     = json['description'];  } catch(e) { print(e.toString()); }
    try { imageURL        = json['imageURL'];     } catch(e) { print(e.toString()); }
    try { webURL          = json['webURL'];       } catch(e) { print(e.toString()); }
    try { membersCount    = json['membersCount']; } catch(e) { print(e.toString()); }
    try { tags            = (json['tags'] as List)?.cast<String>(); } catch(e) { print(e.toString()); }
    try { membershipQuest = GroupMembershipQuest.fromJson(json['membershipQuest']); } catch(e) { print(e.toString()); }
  }

  @override
  void _initFromOther(Group other) {
    super._initFromOther(other);
    GroupDetail groupDetail = (other is GroupDetail) ? other : null;
    privacy         = groupDetail?.privacy;
    description     = groupDetail?.description;
    imageURL        = groupDetail?.imageURL;
    webURL          = groupDetail?.webURL;
    membersCount    = groupDetail?.membersCount;
    tags            = (groupDetail?.tags != null) ? List.from(groupDetail?.tags) : null;
    membershipQuest = GroupMembershipQuest.fromOther(groupDetail?.membershipQuest);
  }

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    return (json != null) ? GroupDetail(json: json) : null;
  }

  factory GroupDetail.fromOther(GroupDetail other) {
    return (other != null) ? GroupDetail(other: other) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson() ?? {};
    json['privacy']           = groupPrivacyToString(privacy);
    json['description']       = description;
    json['imageURL']          = imageURL;
    json['webURL']            = webURL;
    json['membersCount']      = membersCount;
    json['tags']              = tags;
    json['membershipQuest']   = membershipQuest?.toJson();
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
	String       uin;
	String       name;
	String       email;
	String       photoURL;

  Member({Map<String, dynamic> json, Member other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { uin         = json['uin'];      } catch(e) { print(e.toString()); }
    try { name        = json['name'];     } catch(e) { print(e.toString()); }
    try { email       = json['email'];    } catch(e) { print(e.toString()); }
    try { photoURL    = json['photoURL']; } catch(e) { print(e.toString()); }
  }

  void _initFromOther(Member other) {
    uin         = other?.uin;
    name        = other?.name;
    email       = other?.email;
    photoURL    = other?.photoURL;
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Member(json: json) : null;
  }

  factory Member.fromOther(Member other) {
    return (other != null) ? Member(other: other) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uin']                = uin;
    json['name']               = name;
    json['email']              = email;
    json['photoURL']           = photoURL;
    return json;
  }

  bool operator == (dynamic o) {
    return (o is Member) &&
           (o.uin == uin) &&
           (o.name == name) &&
           (o.email == email) &&
           (o.photoURL == photoURL);
  }

  int get hashCode {
    return (uin?.hashCode ?? 0) ^
           (name?.hashCode ?? 0) ^
           (email?.hashCode ?? 0) ^
           (photoURL?.hashCode ?? 0);
  }
}

//////////////////////////////
// GroupMember

class GroupMember extends Member {
	GroupMemberStatus status;
  bool              admin;
  String            officerTitle;
  DateTime          dateAdded;

  GroupMember({Map<String, dynamic> json, GroupMember other}) : super() {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  @override
  void _initFromJson(Map<String, dynamic> json) {
    super._initFromJson(json);
    try { status       = groupMemberStatusFromString(json['status']); } catch(e) { print(e.toString()); }
    try { admin        = json['admin'];        } catch(e) { print(e.toString()); }
    try { officerTitle = json['officerTitle']; } catch(e) { print(e.toString()); }
    try { dateAdded    = AppDateTime().dateTimeFromString(json['dateAdded'], format: AppDateTime.iso8601DateTimeFormat); } catch(e) { print(e.toString()); }
  }

  @override
  void _initFromOther(Member other) {
    super._initFromOther(other);
    GroupMember groupMember = (other is GroupMember) ? other : null;
    status         = groupMember?.status;
    admin          = groupMember?.admin;
    officerTitle   = groupMember?.officerTitle;
    dateAdded      = groupMember?.dateAdded;
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return (json != null) ? GroupMember(json: json) : null;
  }

  factory GroupMember.fromOther(GroupMember other) {
    return (other != null) ? GroupMember(other: other) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['status']             = groupMemberStatusToString(status);
    json['admin']              = admin;
    json['officerTitle']       = officerTitle;
    json['dateAdded']          = AppDateTime().formatDateTime(dateAdded, format: AppDateTime.iso8601DateTimeFormat);
    return json;
  }

  bool operator == (dynamic o) {
    return (o is GroupMember) &&
           (super == o) &&
           (o.status == status) &&
           (o.admin == admin) &&
           (o.officerTitle == officerTitle) &&
           (o.dateAdded == dateAdded);
  }

  int get hashCode {
    return (super.hashCode) ^
           (status?.hashCode ?? 0) ^
           (admin?.hashCode ?? 0) ^
           (officerTitle?.hashCode ?? 0) ^
           (dateAdded?.hashCode ?? 0);
  }
}

//////////////////////////////
// GroupPendingMember

class GroupPendingMember extends Member {
	GroupMembershipRequest membershipRequest;

  GroupPendingMember({Map<String, dynamic> json}) : super(json: json) {
    try { membershipRequest = GroupMembershipRequest.fromJson(json['membershipRequest']); } catch(e) { print(e.toString()); }
  }

  factory GroupPendingMember.fromJson(Map<String, dynamic> json) {
    return (json != null) ? GroupPendingMember(json: json) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['membershipRequest']  = membershipRequest?.toJson();
    return json;
  }
}

//////////////////////////////
// GroupMemberStatus

enum GroupMemberStatus { current, inactive, officer }

GroupMemberStatus groupMemberStatusFromString(String value) {
  if (value != null) {
    if (value == 'current') {
      return GroupMemberStatus.current;
    }
    else if (value == 'inactive') {
      return GroupMemberStatus.inactive;
    }
    else if (value == 'officer') {
      return GroupMemberStatus.officer;
    }
  }
  return null;
}

String groupMemberStatusToString(GroupMemberStatus value) {
  if (value != null) {
    if (value == GroupMemberStatus.current) {
      return 'current';
    }
    else if (value == GroupMemberStatus.inactive) {
      return 'inactive';
    }
    else if (value == GroupMemberStatus.officer) {
      return 'officer';
    }
  }
  return null;
}

String groupMemberStatusToDisplayString(GroupMemberStatus value) {
  if (value != null) {
    if (value == GroupMemberStatus.current) {
      return Localization().getStringEx('model.groups.member.status.current', 'Current');
    }
    else if (value == GroupMemberStatus.inactive) {
      return Localization().getStringEx('model.groups.member.status.inactive', 'Inactive');
    }
    else if (value == GroupMemberStatus.officer) {
      return Localization().getStringEx('model.groups.member.status.officer', 'Officer');
    }
  }
  return null;
}


//////////////////////////////
// GroupMembershipQuest

class GroupMembershipQuest {
  List<GroupMembershipStep> steps;
  List<GroupMembershipQuestion> questions;

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
    try { questions = GroupMembershipQuestion.listFromJson(json['questions']); } catch(e) { print(e.toString()); }
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
    json['questions'] = GroupMembershipQuestion.listToJson(questions);
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

  GroupMembershipQuestion({Map<String, dynamic> json, GroupMembershipQuestion other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { question = json['question'];   } catch(e) { print(e.toString()); }
  }

  void _initFromOther(GroupMembershipQuestion other) {
	  question = other?.question;
  }

  factory GroupMembershipQuestion.fromJson(Map<String, dynamic> json) {
    return (json != null) ? GroupMembershipQuestion(json: json) : null;
  }

  factory GroupMembershipQuestion.fromOther(GroupMembershipQuestion other) {
    return (other != null) ? GroupMembershipQuestion(other: other) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['question'] = question;
    return json;
  }

  static List<GroupMembershipQuestion> listFromJson(List<dynamic> json) {
    List<GroupMembershipQuestion> values;
    if (json != null) {
      values = [];
      for (dynamic entry in json) {
          GroupMembershipQuestion value;
          try { value = GroupMembershipQuestion.fromJson((entry as Map)?.cast<String, dynamic>()); }
          catch(e) { print(e.toString()); }
          values.add(value);
      }
    }
    return values;
  }

  static List<dynamic> listToJson(List<GroupMembershipQuestion> values) {
    List<dynamic> json;
    if (values != null) {
      json = [];
      for (GroupMembershipQuestion value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }

  static List<GroupMembershipQuestion> listFromOthers(List<GroupMembershipQuestion> others) {
    List<GroupMembershipQuestion> values;
    if (others != null) {
      values = [];
      for (GroupMembershipQuestion other in others) {
          values.add(GroupMembershipQuestion.fromOther(other));
      }
    }
    return values;
  }
}

//////////////////////////////
// GroupMembershipRequest

class GroupMembershipRequest {
  DateTime dateCreated;
  List<GroupMembershipAnswer> answers;

  GroupMembershipRequest({Map<String, dynamic> json, this.answers, this.dateCreated}) {
    if (json != null) {
      _initFromJson(json);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { dateCreated = AppDateTime().dateTimeFromString(json['dateCreated'], format: AppDateTime.iso8601DateTimeFormat); } catch(e) { print(e.toString()); }
    try { answers     = GroupMembershipAnswer.listFromJson(json['answers']); } catch(e) { print(e.toString()); }
  }

  factory GroupMembershipRequest.fromJson(Map<String, dynamic> json) {
    return (json != null) ? GroupMembershipRequest(json: json) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['dateCreated'] = AppDateTime().formatDateTime(dateCreated, format: AppDateTime.iso8601DateTimeFormat);
    json['answers']    = GroupMembershipAnswer.listToJson(answers);
    return json;
  }
}

//////////////////////////////
// GroupMembershipAnswer

class GroupMembershipAnswer {
	String       answer;

  GroupMembershipAnswer({Map<String, dynamic> json, this.answer}) {
    if (json != null) {
      _initFromJson(json);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { answer = json['answer'];   } catch(e) { print(e.toString()); }
  }

  factory GroupMembershipAnswer.fromJson(Map<String, dynamic> json) {
    return (json != null) ? GroupMembershipAnswer(json: json) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['answer'] = answer;
    return json;
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
  GroupMember  member;
  DateTime     dateCreated;
	String       text;

  GroupEventComment({Map<String, dynamic> json}) {
    if (json != null) {
      _initFromJson(json);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    try { member      = GroupMember.fromJson(json['member']); } catch(e) { print(e.toString()); }
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
