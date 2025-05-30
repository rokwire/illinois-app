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

import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/groups/GroupDetailPanel.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

extension GroupExt on Group {
  Map<String, dynamic> get analyticsAttributes {
    return {
      Analytics.LogAttributeGroupId : id,
      Analytics.LogAttributeGroupName : title,
      Analytics.LogAttributeGroupHiddenForSearch: hiddenForSearch,
      Analytics.LogAttributeGroupStats: Groups().cachedGroupStats(id)?.toJson(),
    };
  }

  Color? get currentUserStatusColor {
    Member? member = currentMember;
    if(member?.status != null){
      return groupMemberStatusToColor(member!.status);
    }
    return Styles().colors.white;
  }

  String? get displayUpdateTime {
    DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateUpdatedUtc);
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

  String? get displayManagedMembershipUpdateTime {
    DateTime? deviceManagedDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateManagedMembershipUpdatedUtc);
    if (deviceManagedDateTime != null) {
      String formattedManagedDateTime = DateFormat('yyyy/MM/dd h:mma').format(deviceManagedDateTime);
      return formattedManagedDateTime;
    }
    return null;
  }

  String? get displayMembershipUpdateTime {
    DateTime? deviceMembershipDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateMembershipUpdatedUtc);
    if (deviceMembershipDateTime != null) {
      String formattedMembershipDateTime = DateFormat('yyyy/MM/dd h:mma').format(deviceMembershipDateTime);
      return formattedMembershipDateTime;
    }
    return null;
  }

  bool get canMemberCreatePoll {
    return !(onlyAdminsCanCreatePolls ?? true);
  }

  bool get isResearchProject {
    return researchProject == true;
  }

  String? get currentUserStatusText {
    Member? member = currentMember;
    if(member?.status != null){
      return isResearchProject ? researchParticipantStatusToDisplayString(member!.status) : groupMemberStatusToDisplayString(member!.status);
    }
    return "";
  }

  //Settings Preferences rules
  //Post
  bool get isMemberAllowedToPost => /*true ||*//*TMP TODO*//* */(settings?.memberPostPreferences?.allowSendPost == true) && //If all 5 sub checks for posts are set to false by an admin, this is the same as the admin unchecking/false the main section category, in this case "Member Posts"
      ((settings?.memberPostPreferences?.sendPostToSpecificMembers == true) ||
          (settings?.memberPostPreferences?.sendPostToAdmins == true) ||
          (settings?.memberPostPreferences?.sendPostToAll == true) ||
          (settings?.memberPostPreferences?.sendPostReplies == true) ||
          (settings?.memberPostPreferences?.sendPostReactions == true)
      );

  bool get isMemberAllowedToCreatePost => (settings?.memberPostPreferences?.allowSendPost == true) && //If all the above 3 are set to false then a member will not see a + (create) option for posts as they cannot make a post.
      ((settings?.memberPostPreferences?.sendPostToSpecificMembers == true) ||
          (settings?.memberPostPreferences?.sendPostToAdmins == true) ||
          (settings?.memberPostPreferences?.sendPostToAll == true)
      );

  bool get isMemberAllowedToPostToSpecificMembers =>
      (settings?.memberPostPreferences?.allowSendPost == true) &&
      (settings?.memberPostPreferences?.sendPostToSpecificMembers == true) &&
      (isMemberAllowedToViewMembersInfo); // Additional dependency to Member Info

  bool get isMemberAllowedToReplyToPost =>
      (settings?.memberPostPreferences?.allowSendPost == true) &&
          (settings?.memberPostPreferences?.sendPostReplies == true);

  bool get isMemberAllowedToSendReactionsToPost =>
      (settings?.memberPostPreferences?.allowSendPost == true) &&
          (settings?.memberPostPreferences?.sendPostReactions == true);

  //Member Info
  bool get isMemberAllowedToViewMembersInfo => (settings?.memberInfoPreferences?.allowMemberInfo == true) && //If all 5 sub checks for posts are set to false by an admin, this is the same as the admin unchecking/false the main section category, in this case allowMemberInfo/"View Other Members"
      ((settings?.memberInfoPreferences?.viewMemberNetId == true) ||
          (settings?.memberInfoPreferences?.viewMemberName == true) ||
          (settings?.memberInfoPreferences?.viewMemberEmail == true) ||
          (settings?.memberInfoPreferences?.viewMemberPhone == true)
      );

  //Settings user permission depending on settings and role
  bool get currentUserHasPermissionToSendReactions{
    return (currentUserIsAdmin == true) ||
        (currentUserIsMember == true &&
          isMemberAllowedToSendReactionsToPost == true);
  }

  bool get currentUserHasPermissionToSendReply{
    return ((currentUserIsAdmin == true) ||
        (currentUserIsMember == true &&
            isMemberAllowedToReplyToPost == true));
  }

  // Returns PollsChunk? or PollsException?
  Future<dynamic>? loadPolls({PollsCursor? cursor}) async {
    try {
      return (id != null) ? Polls().getGroupPolls(
        groupIds: {id!},
        pollStatuses: currentUserIsAdmin ? null /* no status filter */ : { PollStatus.opened }
      ) : null;
    }
    catch (e) {
      return e;
    }
  }
}

String? groupMemberStatusToDisplayString(GroupMemberStatus? value) {
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

String? researchParticipantStatusToDisplayString(GroupMemberStatus? value) {
  if (value != null) {
    if (value == GroupMemberStatus.pending) {
      return Localization().getStringEx('model.research_project.member.status.pending', 'Pending');
    } else if (value == GroupMemberStatus.member) {
      return Localization().getStringEx('model.research_project.member.status.member', 'Participant');
    } else if (value == GroupMemberStatus.admin) {
      return Localization().getStringEx('model.research_project.member.status.admin', 'Admin');
    } else if (value == GroupMemberStatus.rejected) {
      return Localization().getStringEx('model.research_project.member.status.rejected', 'Denied');
    }
  }
  return null;
}

Color? groupMemberStatusToColor(GroupMemberStatus? value) {
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

extension GroupSettingsExt on GroupSettings{
  static List<DetailTab?> getDefaultDetailTabs() => GroupContentItemExt.defaultContentCodes.map(
          (code) => GroupContentItemExt.getDetailTabByCode(code)).toList();
  
  static GroupSettings initialDefaultSettings({Group? group}){
      //Set Default values to true
    return (group?.researchProject != true) ?
      GroupSettings(
        memberInfoPreferences: MemberInfoPreferences(allowMemberInfo: true, viewMemberNetId: false, viewMemberName: true, viewMemberEmail: false),
        memberPostPreferences: MemberPostPreferences(allowSendPost: true, sendPostToSpecificMembers: false, sendPostToAll: true, sendPostToAdmins: true, sendPostReplies: true, sendPostReactions: true)
      ) :
      GroupSettings(
        memberInfoPreferences: MemberInfoPreferences(allowMemberInfo: false, viewMemberNetId: false, viewMemberName: false, viewMemberEmail: false),
        memberPostPreferences: MemberPostPreferences(allowSendPost: false, sendPostToSpecificMembers: false, sendPostToAll: false, sendPostToAdmins: false, sendPostReplies: false, sendPostReactions: false)
      );
  }

  List<String>? get contentCodes => contentItems?.map<String>(
          (GroupContentItem item) => item.code ?? 'unknown'
  ).toList();

  set contentCodes(List<String>? codes) =>
      contentItems = codes != null ?
        codes.map((String code) => GroupContentItem(code: code)).toList() :
        contentItems;

  List<DetailTab?>? get contentDetailTabs =>
      contentItems?.map((item) => item.detailTab).toList();
}

extension GroupContentItemExt on GroupContentItem{
  static final List<String> availableContentCodes =   ["posts", "events", "messages", "polls"];
  static final List<String> defaultContentCodes =  ["posts", "events", "messages", "polls"];

  static String getTitleByCode(String code) {
    switch(code){
      case 'events' : return 'Events';
      case 'past_events' : return 'Past Events';
      case 'posts' : return 'Posts';
      case 'scheduled' : return 'Scheduled';
      case 'messages' : return 'Messages';
      case 'polls' : return 'Polls';
      default : return "unknown";
    }
  }
  
  static DetailTab? getDetailTabByCode(String? code){
    switch(code){
      case 'events' : return DetailTab.Events;
      case 'past_events' : return DetailTab.PastEvents;
      case 'posts' : return DetailTab.Posts;
      case 'scheduled' : return DetailTab.ScheduledPosts;
      case 'messages' : return DetailTab.Messages;
      case 'polls' : return DetailTab.Polls;
    }
    return null;
  }

  DetailTab? get detailTab => getDetailTabByCode(code);
}

extension MemberExt on Member {
  static List<String>? extractUserIds(List<Member>? members) {
    List<String>? userIds;
    if (members != null) {
      userIds = <String>[];
      for (Member member in members) {
        if (member.userId != null) {
          userIds.add(member.userId!);
        }
      }
    }
    return userIds;
  }
}

extension GroupsExt on Groups {
  Future<GroupResult> syncAuthmanGroupsExt() async {
    return syncAuthmanGroups(params: {
      'group_auto_create_stem_names': [
        'urb:org:bus:Rokwire_AdHoc',
        'urb:app:rokwire:service:groups-rosters:gies-rosters'
      ]
    });
  }
}
