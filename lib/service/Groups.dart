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

import 'package:http/http.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Groups.dart';
//import 'package:flutter/services.dart' show rootBundle;
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/utils/Utils.dart';

class Groups /* with Service */ {

  static const String notifyUserMembershipUpdated   = "edu.illinois.rokwire.groups.membership.updated";
  static const String notifyGroupEventsUpdated   = "edu.illinois.rokwire.groups.events.updated";
  static const String notifyGroupCreated            = "edu.illinois.rokwire.group.created";
  static const String notifyGroupUpdated            = "edu.illinois.rokwire.group.updated";
  static const String notifyGroupDeleted            = "edu.illinois.rokwire.group.deleted";

  Map<String, Member> _userMembership;

  // Singletone instance

  static final Groups _service = Groups._internal();
  Groups._internal();

  factory Groups() {
    return _service;
  }

  // Emulation

  /*Future<Map<String, dynamic>> get _sampleJson async {
      Map<String, dynamic> result;
      try {
        String sampleSource = await rootBundle.loadString('assets/sample.groups.json');
        result = (sampleSource != null) ? json.decode(sampleSource) : null;
      }
      catch(e) {
        print(e.toString());
      }
      return result ?? {};
  }*/

  // Current User Membership

  Member getUserMembership(String groupId) {
    return (_userMembership != null) ? _userMembership[groupId] : null;
  }

  Future<bool> isAdminForGroup(String groupId) async{
    Group group = await loadGroup(groupId);
    return group?.currentUserIsAdmin ?? false;
  }

  // Categories APIs

  Future<List<String>> loadCategories() async {
    List<dynamic> categoriesJsonArray = await ExploreService().loadEventCategories();
    if (AppCollection.isCollectionNotEmpty(categoriesJsonArray)) {
      List<String> categoriesList = categoriesJsonArray.map((e) => e['category']?.toString()).toList();
      return categoriesList;
    } else {
      return null;
    }
  }

  // Tags APIs

  Future<List<String>> loadTags() async {
    return ExploreService().loadEventTags();
  }

  // Groups APIs

  Future<List<Group>> loadGroups({bool myGroups = false}) async {
    String url = myGroups ? '${Config().groupsUrl}/user/groups' : '${Config().groupsUrl}/groups';
    try {
      Response response = await Network().get(url, auth: myGroups ? NetworkAuth.User : (Auth().isShibbolethLoggedIn) ? NetworkAuth.User : NetworkAuth.App,);
      int responseCode = response?.statusCode ?? -1;
      String responseBody = response?.body;
      List<dynamic> groupsJson = ((response != null) && (responseCode == 200)) ? jsonDecode(responseBody) : null;
      if(AppCollection.isCollectionNotEmpty(groupsJson)){
        return groupsJson.map((e) => Group.fromJson(e)).toList();
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<List<Group>> searchGroups(String searchText) async {
    if (AppString.isStringEmpty(searchText)) {
      return null;
    }
    String encodedTExt = Uri.encodeComponent(searchText);
    String url = '${Config().groupsUrl}/groups?title=$encodedTExt';
    Response response = await Network().get(url, auth: (Auth().isShibbolethLoggedIn) ? NetworkAuth.User : NetworkAuth.App);
    int responseCode = response?.statusCode ?? -1;
    String responseBody = response?.body;
    if (responseCode == 200) {
      List<dynamic> groupsJson = AppJson.decodeList(responseBody);
      List<Group> groups;
      if (AppCollection.isCollectionNotEmpty(groupsJson)) {
        groups = groupsJson.map((e) => Group.fromJson(e)).toList();
      }
      return groups;
    } else {
      print('Failed to search for groups. Reason: ');
      print(responseBody);
      return null;
    }
  }

  Future<Group> loadGroup(String groupId) async {
    if(AppString.isStringNotEmpty(groupId)) {
      String url = '${Config().groupsUrl}/groups/$groupId';
      try {
        Response response = await Network().get(url, auth: Auth().isShibbolethLoggedIn ? NetworkAuth.User : NetworkAuth.App,);
        int responseCode = response?.statusCode ?? -1;
        String responseBody = response?.body;
        Map<String, dynamic> groupsJson = ((response != null) && (responseCode == 200)) ? jsonDecode(responseBody) : null;
        return groupsJson != null ? Group.fromJson(groupsJson) : null;
      } catch (e) {
        print(e);
      }
    }
    return null;
  }

  Future<String> createGroup(Group group) async {
    if(group != null) {
      String url = '${Config().groupsUrl}/groups';
      try {
        Map<String, dynamic> json = group.toJson(withId: false);
        json["creator_email"] = Auth()?.authInfo?.email ?? "";
        json["creator_name"] = Auth()?.authInfo?.fullName ?? "";
        json["creator_photo_url"] = "";
        String body = jsonEncode(json);
        Response response = await Network().post(url, auth: NetworkAuth.User, body: body);
        int responseCode = response?.statusCode ?? -1;
        String responseBody = response?.body;
        Map<String, dynamic> jsonData = ((response != null) && (responseCode == 200)) ? jsonDecode(responseBody) : null;
        if(jsonData != null){
          String groupId = jsonData['inserted_id'];
          NotificationService().notify(notifyGroupCreated, group.id);
          return groupId;
        }
      } catch (e) {
        print(e);
      }
    }
    return null;
  }

  Future<bool> updateGroup(Group group) async {
    if(group != null) {
      String url = '${Config().groupsUrl}/groups/${group.id}';
      try {
        Map<String, dynamic> json = group.toJson();
        String body = jsonEncode(json);
        Response response = await Network().put(url, auth: NetworkAuth.User, body: body);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupUpdated, group.id);
          return true;
        }
      } catch (e) {
        print(e);
      }
    }
    return false;
  }

  Future<bool> deleteGroup(String groupId) async {
    if (AppString.isStringEmpty(groupId)) {
      return false;
    }
    String url = '${Config().groupsUrl}/group/$groupId';
    Response response = await Network().delete(url, auth: NetworkAuth.User);
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupDeleted, null);
      return true;
    } else {
      Log.i('Failed to delete group. Reason:\n${response?.body}');
      return false;
    }
  }

  // Members APIs

  Future<bool> requestMembership(Group group, List<GroupMembershipAnswer> answers) async{
    if(group != null) {
      String url = '${Config().groupsUrl}/group/${group.id}/pending-members';
      try {
        Map<String, dynamic> json = {};
        json["email"] = Auth()?.authInfo?.email ?? "";
        json["name"] = Auth()?.authInfo?.fullName ?? "";
        json["creator_photo_url"] = "";
        json["member_answers"] = AppCollection.isCollectionNotEmpty(answers) ? answers.map((e) => e.toJson()).toList() : [];

        String body = jsonEncode(json);
        Response response = await Network().post(url, auth: NetworkAuth.User, body: body);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupUpdated, group.id);
          return true;
        }
      } catch (e) {
        print(e);
      }
    }
    return false; // fail
  }

  Future<bool> cancelRequestMembership(String groupId) async{
    if(groupId != null) {
      String url = '${Config().groupsUrl}/group/$groupId/pending-members';
      try {
        Response response = await Network().delete(url, auth: NetworkAuth.User,);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupUpdated, groupId);
          return true;
        }
      } catch (e) {
        print(e);
      }
    }
    return false; // fail
  }

  Future<bool> leaveGroup(String groupId) async {
    if (AppString.isStringEmpty(groupId)) {
      return false;
    }
    String url = '${Config().groupsUrl}/group/$groupId/members';
    Response response = await Network().delete(url, auth: NetworkAuth.User);
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupUpdated, groupId);
      return true;
    } else {
      print('Failed to leave group with id {$groupId}. Response:');
      String responseString = response?.body;
      print(responseString);
      return false;
    }
  }

  Future<bool> acceptMembership(String groupId, String memberId, bool decision, String reason) async{
    if(AppString.isStringNotEmpty(groupId) && AppString.isStringNotEmpty(memberId) && decision != null) {
      Map<String, dynamic> bodyMap = {"approve": decision, "reject_reason": reason};
      String body = jsonEncode(bodyMap);
      String url = '${Config().groupsUrl}/memberships/$memberId/approval';
      try {
        Response response = await Network().put(url, auth: NetworkAuth.User, body: body);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupUpdated, groupId);
          return true;
        }
      } catch (e) {
        print(e);
      }
    }
    return false; // fail
  }

  Future<bool> updateMembership(String groupId, String memberId, GroupMemberStatus status) async{
    if(AppString.isStringNotEmpty(groupId) && AppString.isStringNotEmpty(memberId)) {
      Map<String, dynamic> bodyMap = {"status":groupMemberStatusToString(status)};
      String body = jsonEncode(bodyMap);
      String url = '${Config().groupsUrl}/memberships/$memberId';
      try {
        Response response = await Network().put(url, auth: NetworkAuth.User, body: body);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupUpdated, groupId);
          return true;
        }
      } catch (e) {
        print(e);
      }
    }
    return false; // fail
  }

  Future<bool> deleteMembership(String groupId, String memberId) async{
    if(AppString.isStringNotEmpty(groupId) && AppString.isStringNotEmpty(memberId)) {
      String url = '${Config().groupsUrl}/memberships/$memberId';
      try {
        Response response = await Network().delete(url, auth: NetworkAuth.User,);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupUpdated, groupId);
          return true;
        }
      } catch (e) {
        print(e);
      }
    }
    return false; // fail
  }


// Events
  Future<List<dynamic>> loadEventIds(String groupId) async{
    if(AppString.isStringNotEmpty(groupId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events';
      try {
        Response response = await Network().get(url, auth: NetworkAuth.User);
        if((response?.statusCode ?? -1) == 200){
          //Successfully loaded ids
          String responseBody = response?.body;
          List<dynamic> eventIdsJson = (response != null) ? jsonDecode(responseBody) : null;
          return eventIdsJson;
        }
      } catch (e) {
        print(e);
      }
    }
    return null; // fail
  }

  ///
  /// Returns Map with single element:
  ///
  /// key - all events count ignoring the limit,
  /// 
  /// value - events (limited or not)
  ///
  Future<Map<int, List<GroupEvent>>> loadEvents(String groupId, {int limit = -1}) async {
    List<dynamic> eventIds = await loadEventIds(groupId);
    List<Event> events = AppCollection.isCollectionNotEmpty(eventIds) ? await ExploreService().loadEventsByIds(Set<String>.from(eventIds)) : null;
    if (AppCollection.isCollectionNotEmpty(events)) {
      int eventsCount = events.length;
      ExploreService().sortEvents(events);
      //limit the result count // limit available events
      List<Event> visibleEvents = ((limit > 0) && (eventsCount > limit)) ? events.sublist(0, limit) : events;
      List<GroupEvent> groupEvents = visibleEvents?.map((Event event) => GroupEvent.fromJson(event?.toJson()))?.toList();
      return {eventsCount: groupEvents};
    }
    return null;
  }

  Future<bool> linkEventToGroup({String groupId, String eventId}) async {
    if(AppString.isStringNotEmpty(groupId) && AppString.isStringNotEmpty(eventId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events';
      try {
        Map<String, dynamic> bodyMap = {"event_id":eventId};
        String body = jsonEncode(bodyMap);
        Response response = await Network().post(url, auth: NetworkAuth.User,body: body);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupUpdated, groupId);
          return true;
        }
      } catch (e) {
        print(e);
      }
    }
    return false; // fail
  }

  Future<bool> removeEventFromGroup({String groupId, String eventId}) async {
    if(AppString.isStringNotEmpty(groupId) && AppString.isStringNotEmpty(eventId)) {
      String url = '${Config().groupsUrl}/group/$groupId/event/$eventId';
      try {
        Response response = await Network().delete(url, auth: NetworkAuth.User);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupUpdated, groupId);
          return true;
        }
      } catch (e) {
        print(e);
      }
    }
    return false;
  }

  Future<String> updateGroupEvents(Event event) async {
    String id = await ExploreService().updateEvent(event);
    if (AppString.isStringNotEmpty(id)) {
      NotificationService().notify(Groups.notifyGroupEventsUpdated);
    }
    return id;
  }

  Future<bool> deleteEventFromGroup({String groupId, Event event}) async {
    bool deleteResult = false;
    await removeEventFromGroup(groupId: groupId, eventId: event?.id);
    String creatorGroupId = event.createdByGroupId;
    if(creatorGroupId!=null){
      Group creatorGroup = await loadGroup(creatorGroupId);
      if(creatorGroup!=null && creatorGroup.currentUserIsAdmin){
        deleteResult = await ExploreService().deleteEvent(event?.id);
      }
    }
    NotificationService().notify(Groups.notifyGroupEventsUpdated);
    return deleteResult;
  }

  Future<Event> createGroupEvent(String groupId, Event event) async {
    //TBD
    return Future<Event>.delayed(Duration(seconds: 1), (){ return event; });
  }

  // Event Comments

  Future<bool> postEventComment(String groupId, String eventId, GroupEventComment comment) {
    return Future<bool>.delayed(Duration(seconds: 1), (){ return true; });
  }
}