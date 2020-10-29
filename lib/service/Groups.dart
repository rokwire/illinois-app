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

import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Groups.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/utils/Utils.dart';

class Groups /* with Service */ {

  static const String notifyUserMembershipUpdated  = "edu.illinois.rokwire.groups.membership.updated";

  Map<String, GroupMember> _userMembership;

  // Singletone instance

  static final Groups _service = Groups._internal();
  Groups._internal();

  factory Groups() {
    return _service;
  }

  // Emulation

  Future<Map<String, dynamic>> get _sampleJson async {
      Map<String, dynamic> result;
      try {
        String sampleSource = await rootBundle.loadString('assets/sample.groups.json');
        result = (sampleSource != null) ? json.decode(sampleSource) : null;
      }
      catch(e) {
        print(e.toString());
      }
      return result ?? {};
  }

  // Current User Membership

  GroupMember getUserMembership(String groupId) {
    return (_userMembership != null) ? _userMembership[groupId] : null;
  }

  Future<void> updateUserMemberships() async {
    Map<String, GroupMember> userMembership;
    Map<String, dynamic> json = (await _sampleJson)['userMembership'];
    if (json != null) {
      userMembership = Map<String, GroupMember>();
      json.forEach((String groupId, dynamic memberJson) {
        userMembership[groupId] = GroupMember.fromJson(memberJson);
      });
    }

    if ((_userMembership == null) || !DeepCollectionEquality().equals(_userMembership, userMembership)) {
      _userMembership = userMembership;
      NotificationService().notify(notifyUserMembershipUpdated, null);
    }
  }

  // Enumeration APIs

  Future<List<String>> get categories async {
    String url = '${Config().groupsUrl}/group-categories';
    try {
      Response response = await Network().get(url, auth: NetworkAuth.App,);
      int responseCode = response?.statusCode ?? -1;
      String responseBody = response?.body;
      List<dynamic> categoriesJson = ((response != null) && (responseCode == 200)) ? jsonDecode(responseBody) : null;
      if(AppCollection.isCollectionNotEmpty(categoriesJson)){
        return categoriesJson.map((e) => e.toString()).toList();
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<List<String>> get types async {
    return ((await _sampleJson)['types'] as List)?.cast<String>();
  }

  Future<List<String>> get tags async {
    return ((await _sampleJson)['tags'] as List)?.cast<String>();
  }

  Future<List<String>> get officerTitles async {
    return ((await _sampleJson)['officerTitles'] as List)?.cast<String>();
  }

  // Groups APIs

  Future<List<Group>> loadGroups({String category, String type}) async {
    List<Group> result;
    List<dynamic> json = (await _sampleJson)['groups'];
    if (json != null) {
      result = [];
      for (dynamic jsonEntry in json) {
        Group group = Group.fromJson(jsonEntry);
        if ((group != null) &&
            ((category == null) || (category == group.category)) &&
            ((type == null) || (type == group.category)))
        {
          result.add(group);
        }
      }
    }
    return result;
  }

  Future<GroupDetail>loadGroupDetail(String groupId) async {
    List<dynamic> json = (await _sampleJson)['groups'];
    if (json != null) {
      for (dynamic jsonEntry in json) {
        GroupDetail groupDetail = GroupDetail.fromJson(jsonEntry);
        if ((groupDetail != null) && (groupDetail.id == groupId)) {
          return groupDetail;
        }
      }
    }
    return null;
  }

  Future<GroupDetail>createGroup(GroupDetail groupDetail) async {
    return Future<GroupDetail>.delayed(Duration(seconds: 1), (){ return groupDetail; });
  }

  Future<GroupDetail>updateGroup(GroupDetail groupDetail) async {
    return Future<GroupDetail>.delayed(Duration(seconds: 1), (){ return groupDetail; });
  }

  // Members APIs

  Future<List<GroupMember>> loadGroupMembers(String groupId, {GroupMemberStatus status}) async {
    List<GroupMember> result;
    List<dynamic> json = (await _sampleJson)['members'];
    if (json != null) {
      result = [];
      for (dynamic jsonEntry in json) {
        GroupMember groupMember = GroupMember.fromJson(jsonEntry);
        if ((groupMember != null) &&
            ((status == null) || (status == groupMember.status)))
        {
          result.add(groupMember);
        }
      }
    }
    return result;
  }

  Future<List<GroupPendingMember>> loadPendingMembers(String groupId) async {
    List<GroupPendingMember> result;
    List<dynamic> json = (await _sampleJson)['pending_members'];
    if (json != null) {
      result = [];
      for (dynamic jsonEntry in json) {
        GroupPendingMember pendingMember = GroupPendingMember.fromJson(jsonEntry);
        if (pendingMember != null) {
          result.add(pendingMember);
        }
      }
    }
    return result;
  }

  Future<GroupMember> updateGroupMember(String groupId, GroupMember groupMember) async {
    return Future<GroupMember>.delayed(Duration(seconds: 1), (){ return groupMember; });
  }

  Future<bool> requestMembership(String groupId, GroupMembershipRequest membershipRequest) {
    return Future<bool>.delayed(Duration(seconds: 1), (){ return true; });
  }

  Future<bool> acceptMembership(String groupId, String userUin, bool decision) {
    return Future<bool>.delayed(Duration(seconds: 1), (){ return true; });
  }

  // Events

  Future<List<GroupEvent>> loadEvents(String groupId, {int limit }) async {
    List<GroupEvent> result;
    List<dynamic> json = (await _sampleJson)['events'];
    if (json != null) {
      result = [];
      for (dynamic jsonEntry in json) {
        GroupEvent event = GroupEvent.fromJson(jsonEntry);
        if ((event != null) &&
            ((limit == null) || (result.length < limit)))
        {
          result.add(event);
        }
      }
    }
    return result;
  }

  Future<Event> createGroupEvent(String groupId, Event event) async {
    return Future<Event>.delayed(Duration(seconds: 1), (){ return event; });
  }

  Future<bool> updateGroupEvents(String groupId, List<Event> events) async {
    return Future<bool>.delayed(Duration(seconds: 1), (){ return true; });
  }

  // Event Comments

  Future<bool> postEventComment(String groupId, String eventId, GroupEventComment comment) {
    return Future<bool>.delayed(Duration(seconds: 1), (){ return true; });
  }
}