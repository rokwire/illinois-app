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
import 'dart:core';

import 'package:http/http.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
//import 'package:flutter/services.dart' show rootBundle;
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/utils/Utils.dart';

class Groups with Service implements NotificationsListener {

  static const String GROUP_URI = 'edu.illinois.rokwire://rokwire.illinois.edu/group_detail';

  static const String notifyUserMembershipUpdated   = "edu.illinois.rokwire.groups.membership.updated";
  static const String notifyGroupEventsUpdated      = "edu.illinois.rokwire.groups.events.updated";
  static const String notifyGroupCreated            = "edu.illinois.rokwire.group.created";
  static const String notifyGroupUpdated            = "edu.illinois.rokwire.group.updated";
  static const String notifyGroupDeleted            = "edu.illinois.rokwire.group.deleted";
  static const String notifyGroupPostsUpdated       = "edu.illinois.rokwire.group.posts.updated";
  static const String notifyGroupDetail             = "edu.illinois.rokwire.group.detail";

  Map<String, Member> _userMembership;
  List<Map<String, dynamic>> _groupDetailsCache;

  final List<Completer<void>> _loginCompleters = [];
  bool _loggedIn = false;

  // Singletone instance

  static final Groups _service = Groups._internal();
  Groups._internal();

  factory Groups() {
    return _service;
  }

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this,[
      DeepLink.notifyUri,
      Auth2.notifyLoginSucceeded,
      Auth2.notifyLogout,
    ]);
    _groupDetailsCache = [];
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async{
    await super.initService();

    _waitForLogin();
  }

  @override
  void initServiceUI() {
    _processCachedGroupDetails();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([DeepLink()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(param);
    } if(name == Auth2.notifyLoginSucceeded){
      _waitForLogin();
    } if(name == Auth2.notifyLogout){
      _loggedIn = false;
    }
  }

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

  Future<void> _waitForLogin() async{
    if(!_loggedIn) {
      if (_loginCompleters.isEmpty) {
        return _login().whenComplete((){
          _loggedIn = true;
          _loginCompleters.forEach((completer) {
            completer.complete();
          });
          _loginCompleters.clear();
        });
      } else {
        Completer<void> completer = Completer<void>();
        _loginCompleters.add(completer);
        return completer.future;
      }
    }
  }

  Future<void> _login() async{
      try {
        if ((Config().groupsUrl != null) && Auth2().isLoggedIn) {
          try {
            String url = '${Config().groupsUrl}/user/login';
            await Network().get(url, auth: NetworkAuth.Auth2,);

            // we need just to be sure the request is made no matter for the result at this point
          } catch (e) {
            print(e);
          }
        }
      } catch (err) {
        print(err);
      }
  }

  Future<List<Group>> loadGroups({bool myGroups = false}) async {
    await _waitForLogin();
    if ((Config().groupsUrl != null) && ((myGroups != true) || Auth2().isLoggedIn)) {
      try {
        String url = myGroups ? '${Config().groupsUrl}/user/groups' : '${Config().groupsUrl}/groups';
        Response response = await Network().get(url, auth: NetworkAuth.Auth2,);
        int responseCode = response?.statusCode ?? -1;
        String responseBody = response?.body;
        List<dynamic> groupsJson = ((responseBody != null) && (responseCode == 200)) ? AppJson.decodeList(responseBody) : null;
        return (groupsJson != null) ? Group.listFromJson(groupsJson) : null;
      } catch (e) {
        print(e);
      }
    }
    
    return null;
  }

  Future<List<Group>> searchGroups(String searchText) async {
    await _waitForLogin();
    if (AppString.isStringEmpty(searchText)) {
      return null;
    }
    String encodedTExt = Uri.encodeComponent(searchText);
    String url = '${Config().groupsUrl}/groups?title=$encodedTExt';
    Response response = await Network().get(url, auth: NetworkAuth.Auth2);
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
    await _waitForLogin();
    if(AppString.isStringNotEmpty(groupId)) {
      String url = '${Config().groupsUrl}/groups/$groupId';
      try {
        Response response = await Network().get(url, auth: NetworkAuth.Auth2,);
        int responseCode = response?.statusCode ?? -1;
        String responseBody = response?.body;
        Map<String, dynamic> groupsJson = ((responseBody != null) && (responseCode == 200)) ? AppJson.decodeMap(responseBody) : null;
        return groupsJson != null ? Group.fromJson(groupsJson) : null;
      } catch (e) {
        print(e);
      }
    }
    return null;
  }

  Future<GroupError> createGroup(Group group) async {
    await _waitForLogin();
    if(group != null) {
      String url = '${Config().groupsUrl}/groups';
      try {
        Map<String, dynamic> json = group.toJson(withId: false);
        json["creator_email"] = Auth2().account?.profile?.email ?? "";
        json["creator_name"] = Auth2().account?.profile?.fullName ?? "";
        json["creator_photo_url"] = "";
        String body = AppJson.encode(json);
        Response response = await Network().post(url, auth: NetworkAuth.Auth2, body: body);
        int responseCode = response?.statusCode ?? -1;
        Map<String, dynamic> jsonData = AppJson.decodeMap(response?.body);
        if (responseCode == 200) {
          String groupId = (jsonData != null) ? AppJson.stringValue(jsonData['inserted_id']) : null;
          if (AppString.isStringNotEmpty(groupId)) {
            NotificationService().notify(notifyGroupCreated, group.id);
            return null; // succeeded
          }
        }
        else {
          Map<String, dynamic> jsonError = (jsonData != null) ? AppJson.mapValue(jsonData['error']) : null;
          if (jsonError != null) {
            return GroupError.fromJson(jsonError); // error description
          }
        }
      } catch (e) {
        print(e);
      }
    }
    return GroupError(); // generic error
  }

  Future<GroupError> updateGroup(Group group) async {

    await _waitForLogin();

    if(group != null) {
      String url = '${Config().groupsUrl}/groups/${group.id}';
      try {
        Map<String, dynamic> json = group.toJson();
        String body = AppJson.encode(json);
        Response response = await Network().put(url, auth: NetworkAuth.Auth2, body: body);
        int responseCode = response?.statusCode ?? -1;
        if(responseCode == 200){
          NotificationService().notify(notifyGroupUpdated, group.id);
          return null;
        }
        else {
          Map<String, dynamic> jsonData = AppJson.decodeMap(response?.body);
          Map<String, dynamic> jsonError = (jsonData != null) ? AppJson.mapValue(jsonData['error']) : null;
          if (jsonError != null) {
            return GroupError.fromJson(jsonError); // error description
          }
        }
      } catch (e) {
        print(e);
      }
    }
    return GroupError(); // generic error
  }

  Future<bool> deleteGroup(String groupId) async {
    await _waitForLogin();
    if (AppString.isStringEmpty(groupId)) {
      return false;
    }
    String url = '${Config().groupsUrl}/group/$groupId';
    Response response = await Network().delete(url, auth: NetworkAuth.Auth2);
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
    await _waitForLogin();
    if(group != null) {
      String url = '${Config().groupsUrl}/group/${group.id}/pending-members';
      try {
        Map<String, dynamic> json = {};
        json["email"] = Auth2().account?.profile?.email ?? "";
        json["name"] = Auth2().account?.profile?.fullName ?? "";
        json["creator_photo_url"] = "";
        json["member_answers"] = AppCollection.isCollectionNotEmpty(answers) ? answers.map((e) => e.toJson()).toList() : [];

        String body = AppJson.encode(json);
        Response response = await Network().post(url, auth: NetworkAuth.Auth2, body: body);
        if((response?.statusCode ?? -1) == 200){
          Analytics().logGroup(action: Analytics.LogGroupMembershipRequested, attributes: group.analyticsAttributes);
          NotificationService().notify(notifyGroupUpdated, group.id);
          return true;
        }
      } catch (e) {
        print(e);
      }
    }
    return false; // fail
  }

  Future<bool> cancelRequestMembership(Group group) async{
    await _waitForLogin();
    if(group?.id != null) {
      String url = '${Config().groupsUrl}/group/${group.id}/pending-members';
      try {
        Response response = await Network().delete(url, auth: NetworkAuth.Auth2,);
        if((response?.statusCode ?? -1) == 200){
          Analytics().logGroup(action: Analytics.LogGroupMembershipRequestCanceled, attributes: group.analyticsAttributes);
          NotificationService().notify(notifyGroupUpdated, group.id);
          return true;
        }
      } catch (e) {
        print(e);
      }
    }
    return false; // fail
  }

  Future<bool> leaveGroup(Group group) async {
    await _waitForLogin();
    if (AppString.isStringEmpty(group?.id)) {
      return false;
    }
    String url = '${Config().groupsUrl}/group/${group.id}/members';
    Response response = await Network().delete(url, auth: NetworkAuth.Auth2);
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      Analytics().logGroup(action: Analytics.LogGroupMembershipQuit, attributes: group.analyticsAttributes);
      NotificationService().notify(notifyGroupUpdated, group.id);
      return true;
    } else {
      String responseString = response?.body;
      print(responseString);
      return false;
    }
  }

  Future<bool> acceptMembership(Group group, Member member, bool decision, String reason) async{
    await _waitForLogin();
    if(AppString.isStringNotEmpty(group?.id) && AppString.isStringNotEmpty(member?.id) && decision != null) {
      Map<String, dynamic> bodyMap = {"approve": decision, "reject_reason": reason};
      String body = AppJson.encode(bodyMap);
      String url = '${Config().groupsUrl}/memberships/${member.id}/approval';
      try {
        Response response = await Network().put(url, auth: NetworkAuth.Auth2, body: body);
        if((response?.statusCode ?? -1) == 200){
          Analytics().logGroup(action: decision ? Analytics.LogGroupMembershipApproved : Analytics.LogGroupMembershipRejected, attributes: group.analyticsAttributes);    
          NotificationService().notify(notifyGroupUpdated, group.id);
          return true;
        }
      } catch (e) {
        print(e);
      }
    }
    return false; // fail
  }

  Future<bool> updateMembership(Group group, Member member, GroupMemberStatus status) async{
    await _waitForLogin();
    if(AppString.isStringNotEmpty(group?.id) && AppString.isStringNotEmpty(member?.id)) {
      Map<String, dynamic> bodyMap = {"status":groupMemberStatusToString(status)};
      String body = AppJson.encode(bodyMap);
      String url = '${Config().groupsUrl}/memberships/${member.id}';
      try {
        Response response = await Network().put(url, auth: NetworkAuth.Auth2, body: body);
        if((response?.statusCode ?? -1) == 200){
          if (status == GroupMemberStatus.admin) {
            Analytics().logGroup(action: Analytics.LogGroupMembershipSwitchToAdmin, attributes: group.analyticsAttributes);    
          }
          else if (status == GroupMemberStatus.member) {
            Analytics().logGroup(action: Analytics.LogGroupMembershipSwitchToMember, attributes: group.analyticsAttributes);    
          }
          NotificationService().notify(notifyGroupUpdated, group.id);
          return true;
        }
      } catch (e) {
        print(e);
      }
    }
    return false; // fail
  }

  Future<bool> deleteMembership(Group group, Member member) async{
    await _waitForLogin();
    if(AppString.isStringNotEmpty(group?.id) && AppString.isStringNotEmpty(member?.id)) {
      String url = '${Config().groupsUrl}/memberships/${member.id}';
      try {
        Response response = await Network().delete(url, auth: NetworkAuth.Auth2,);
        if((response?.statusCode ?? -1) == 200){
          Analytics().logGroup(action: Analytics.LogGroupMembershipRemoved, attributes: group.analyticsAttributes);    
          NotificationService().notify(notifyGroupUpdated, group.id);
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
    await _waitForLogin();
    if(AppString.isStringNotEmpty(groupId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events';
      try {
        Response response = await Network().get(url, auth: NetworkAuth.Auth2);
        if((response?.statusCode ?? -1) == 200){
          //Successfully loaded ids
          int responseCode = response?.statusCode ?? -1;
          String responseBody = response?.body;
          List<dynamic> eventIdsJson = ((responseBody != null) && (responseCode == 200)) ? AppJson.decodeList(responseBody) : null;
          return eventIdsJson;
        }
      } catch (e) {
        print(e);
      }
    }
    return null; // fail
  }

  /// 
  /// Loads group events based on the current user membership
  /// 
  /// Returns Map with single element:
  ///
  /// key - all events count ignoring the limit,
  /// 
  /// value - events (limited or not)
  ///
  Future<Map<int, List<GroupEvent>>> loadEvents(Group group, {int limit = -1}) async {
    await _waitForLogin();
    if (group != null) {
      List<dynamic> eventIds = await loadEventIds(group.id);
      List<Event> allEvents = AppCollection.isCollectionNotEmpty(eventIds) ? await ExploreService().loadEventsByIds(Set<String>.from(eventIds)) : null;
      if (AppCollection.isCollectionNotEmpty(allEvents)) {
        List<Event> currentUserEvents = [];
        bool isCurrentUserMemberOrAdmin = group.currentUserIsMemberOrAdmin;
        for (Event event in allEvents) {
          bool isPrivate = event.isGroupPrivate;
          if (!isPrivate || isCurrentUserMemberOrAdmin) {
            currentUserEvents.add(event);
          }
        }
        int eventsCount = currentUserEvents.length;
        ExploreService().sortEvents(currentUserEvents);
        //limit the result count // limit available events
        List<Event> visibleEvents = ((limit > 0) && (eventsCount > limit)) ? currentUserEvents.sublist(0, limit) : currentUserEvents;
        List<GroupEvent> groupEvents = visibleEvents?.map((Event event) => GroupEvent.fromJson(event?.toJson()))?.toList();
        return {eventsCount: groupEvents};
      }
    }
    return null;
  }

  Future<bool> linkEventToGroup({String groupId, String eventId}) async {
    await _waitForLogin();
    if(AppString.isStringNotEmpty(groupId) && AppString.isStringNotEmpty(eventId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events';
      try {
        Map<String, dynamic> bodyMap = {"event_id":eventId};
        String body = AppJson.encode(bodyMap);
        Response response = await Network().post(url, auth: NetworkAuth.Auth2,body: body);
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
    await _waitForLogin();
    if(AppString.isStringNotEmpty(groupId) && AppString.isStringNotEmpty(eventId)) {
      String url = '${Config().groupsUrl}/group/$groupId/event/$eventId';
      try {
        Response response = await Network().delete(url, auth: NetworkAuth.Auth2);
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
    await _waitForLogin();
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

  // Event Comments

  Future<bool> postEventComment(String groupId, String eventId, GroupEventComment comment) {
    return Future<bool>.delayed(Duration(seconds: 1), (){ return true; });
  }

  // Group Posts and Replies

  Future<bool> createPost(String groupId, GroupPost post) async {
    await _waitForLogin();
    if (AppString.isStringEmpty(groupId) || (post == null)) {
      return false;
    }
    String requestBody = AppJson.encode(post.toJson(create: true));
    String requestUrl = '${Config().groupsUrl}/group/$groupId/posts';
    Response response = await Network().post(requestUrl, auth: NetworkAuth.Auth2, body: requestBody);
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupPostsUpdated, (post.parentId == null) ? 1 : null);
      return true;
    } else {
      Log.e('Failed to create group post. Response: ${response?.body}');
      return false;
    }
  }

  Future<bool> updatePost(String groupId, GroupPost post) async {
    await _waitForLogin();
    if (AppString.isStringEmpty(groupId) || AppString.isStringEmpty(post?.id)) {
      return false;
    }
    String requestBody = AppJson.encode(post.toJson(update: true));
    String requestUrl = '${Config().groupsUrl}/group/$groupId/posts/${post.id}';
    Response response = await Network().put(requestUrl, auth: NetworkAuth.Auth2, body: requestBody);
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupPostsUpdated);
      return true;
    } else {
      Log.e('Failed to update group post. Response: ${response?.body}');
      return false;
    }
  }

  Future<bool> deletePost(String groupId, GroupPost post) async {
    await _waitForLogin();
    if (AppString.isStringEmpty(groupId) || AppString.isStringEmpty(post?.id)) {
      return false;
    }
    String requestUrl = '${Config().groupsUrl}/group/$groupId/posts/${post.id}';
    Response response = await Network().delete(requestUrl, auth: NetworkAuth.Auth2);
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupPostsUpdated, (post.parentId == null) ? -1 : null);
      return true;
    } else {
      Log.e('Failed to delete group post. Response: ${response?.body}');
      return false;
    }
  }

  Future<List<GroupPost>> loadGroupPosts(String groupId, {int offset, int limit, GroupSortOrder order}) async {
    await _waitForLogin();
    if (AppString.isStringEmpty(groupId)) {
      return null;
    }
    
    String urlParams = "";
    if (offset != null) {
      urlParams = urlParams.isEmpty ? "?" : "$urlParams&";
      urlParams += "offset=$offset";
    }
    if (limit != null) {
      urlParams = urlParams.isEmpty ? "?" : "$urlParams&";
      urlParams += "limit=$limit";
    }
    if (order != null) {
      urlParams = urlParams.isEmpty ? "?" : "$urlParams&";
      urlParams += "order=${groupSortOrderToString(order)}";
    }
    
    String requestUrl = '${Config().groupsUrl}/group/$groupId/posts$urlParams';
    Response response = await Network().get(requestUrl, auth: NetworkAuth.Auth2);
    int responseCode = response?.statusCode ?? -1;
    String responseString = response?.body;
    if (responseCode == 200) {
      List<GroupPost> posts = GroupPost.fromJsonList(AppJson.decodeList(responseString));
      return posts;
    } else {
      Log.e('Failed to retrieve group posts. Response: ${response?.body}');
      return null;
    }
  }

  //Delete User
  void deleteUserData() async{
    try {
      Response response = (Auth2().isLoggedIn && Config().notificationsUrl != null) ? await Network().delete("${Config().groupsUrl}/user", auth: NetworkAuth.Auth2) : null;
      if(response?.statusCode == 200) {
        Log.d('Successfully deleted groups user data');
      }
    } catch (e) {
      Log.e('Failed to load inbox user info');
      Log.e(e.toString());
    }
  }

  /////////////////////////
  // DeepLinks

  void _onDeepLinkUri(Uri uri) {
    if (uri != null) {
      Uri eventUri = Uri.tryParse(GROUP_URI);
      if ((eventUri != null) &&
          (eventUri.scheme == uri.scheme) &&
          (eventUri.authority == uri.authority) &&
          (eventUri.path == uri.path))
      {
        try { _handleGroupDetail(uri.queryParameters?.cast<String, dynamic>()); }
        catch (e) { print(e?.toString()); }
      }
    }
  }

  void _handleGroupDetail(Map<String, dynamic> params) {
    if ((params != null) && params.isNotEmpty) {
      if (_groupDetailsCache != null) {
        _cacheGroupDetail(params);
      }
      else {
        _processGroupDetail(params);
      }
    }
  }

  void _processGroupDetail(Map<String, dynamic> params) {
    NotificationService().notify(notifyGroupDetail, params);
  }

  void _cacheGroupDetail(Map<String, dynamic> params) {
    _groupDetailsCache?.add(params);
  }

  void _processCachedGroupDetails() {
    if (_groupDetailsCache != null) {
      List<Map<String, dynamic>> groupDetailsCache = _groupDetailsCache;
      _groupDetailsCache = null;

      for (Map<String, dynamic> groupDetail in groupDetailsCache) {
        _processGroupDetail(groupDetail);
      }
    }
  }
}

enum GroupSortOrder { asc, desc }

GroupSortOrder groupSortOrderFromString(String value) {
  if (value == 'asc') {
    return GroupSortOrder.asc;
  }
  else if (value == 'desc') {
    return GroupSortOrder.desc;
  }
  else {
    return null;
  }
}

String groupSortOrderToString(GroupSortOrder value) {
  switch(value) {
    case GroupSortOrder.asc:  return 'asc';
    case GroupSortOrder.desc: return 'desc';
  }
  return null;
}