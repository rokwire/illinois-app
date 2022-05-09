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
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

extension GroupExt on Group {
  Map<String, dynamic> get analyticsAttributes {
    return {
      Analytics.LogAttributeGroupId : id,
      Analytics.LogAttributeGroupName : title
    };
  }

  Color? get currentUserStatusColor {
    Member? member = currentUserAsMember;
    if(member?.status != null){
      return groupMemberStatusToColor(member!.status);
    }
    return Styles().colors!.white;
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

  String get displayTags {
    String tagsString = "";
    if (tags != null) {
      for (String tag in tags!) {
        if (0 < tag.length) {
          if (tagsString.isNotEmpty) {
            tagsString += ", ";
          }
          tagsString += tag;
        }
      }
    }
    return tagsString;
  }

  bool get canMemberCreatePoll {
    return !(onlyAdminsCanCreatePolls ?? true);
  }

  String? get currentUserStatusText {
    Member? member = currentUserAsMember;
    if(member?.status != null){
      return groupMemberStatusToDisplayString(member!.status);
    }
    return "";
  }
}

Color? groupMemberStatusToColor(GroupMemberStatus? value) {
  if (value != null) {
    switch(value){
      case GroupMemberStatus.admin    :  return Styles().colors!.fillColorSecondary;
      case GroupMemberStatus.member   :  return Styles().colors!.fillColorPrimary;
      case GroupMemberStatus.pending  :  return Styles().colors!.mediumGray1;
      case GroupMemberStatus.rejected :  return Styles().colors!.mediumGray1;
    }
  }
  return null;
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

extension GroupPostExt on GroupPost {
  String? get displayDateTime {
    DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateCreatedUtc);
    if (deviceDateTime != null) {
      DateTime now = DateTime.now();
      if (deviceDateTime.compareTo(now) < 0) {
        Duration difference = DateTime.now().difference(deviceDateTime);
        if (difference.inSeconds < 60) {
          return "now";
        }
        else if (difference.inMinutes < 60) {
          return "${difference.inMinutes} ${Localization().getStringEx("generic.minutes", "minutes")}";
        }
        else if (difference.inHours < 24) {
          return "${difference.inHours} ${Localization().getStringEx("generic.hours", "hours")}";
        }
        else if (difference.inDays < 30) {
          return "${difference.inDays} ${Localization().getStringEx("generic.days", "days")}";
        }
        else {
          int differenceInMonths = difference.inDays ~/ 30;
          if (differenceInMonths < 12) {
            return "$differenceInMonths ${Localization().getStringEx("generic.months", "months")}";
          }
        }
      }
      return DateFormat("MMM dd, yyyy").format(deviceDateTime);
    }
    return null;
  }
}

