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

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/event.dart';

import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Groups with Service implements NotificationsListener {

  static const String notifyUserMembershipUpdated   = "edu.illinois.rokwire.groups.membership.updated";
  static const String notifyGroupEventsUpdated      = "edu.illinois.rokwire.groups.events.updated";
  static const String notifyGroupCreated            = "edu.illinois.rokwire.group.created";
  static const String notifyGroupUpdated            = "edu.illinois.rokwire.group.updated";
  static const String notifyGroupDeleted            = "edu.illinois.rokwire.group.deleted";
  static const String notifyGroupPostsUpdated       = "edu.illinois.rokwire.group.posts.updated";
  static const String notifyGroupDetail             = "edu.illinois.rokwire.group.detail";

  static const String notifyGroupMembershipRequested      = "edu.illinois.rokwire.group.membership.requested";
  static const String notifyGroupMembershipCanceled       = "edu.illinois.rokwire.group.membership.canceled";
  static const String notifyGroupMembershipQuit           = "edu.illinois.rokwire.group.membership.quit";
  static const String notifyGroupMembershipApproved       = "edu.illinois.rokwire.group.membership.approved";
  static const String notifyGroupMembershipRejected       = "edu.illinois.rokwire.group.membership.rejected";
  static const String notifyGroupMembershipRemoved        = "edu.illinois.rokwire.group.membership.removed";
  static const String notifyGroupMembershipSwitchToAdmin  = "edu.illinois.rokwire.group.membership.switch_to_admin";
  static const String notifyGroupMembershipSwitchToMember = "edu.illinois.rokwire.group.membership.switch_to_member";
  
  List<Map<String, dynamic>>? _groupDetailsCache;
  List<Map<String, dynamic>>? get groupDetailsCache => _groupDetailsCache;

  final List<Completer<void>> _loginCompleters = [];
  List<Completer<void>> get loginCompleters => _loginCompleters;

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  // Singletone Factory

  static Groups? _instance;

  static Groups? get instance => _instance;
  
  @protected
  static set instance(Groups? value) => _instance = value;

  factory Groups() => _instance ?? (_instance = Groups.internal());

  @protected
  Groups.internal();

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

    waitForLogin();
  }

  @override
  void initServiceUI() {
    processCachedGroupDetails();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { DeepLink(), Config(), Auth2() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      onDeepLinkUri(param);
    } if(name == Auth2.notifyLoginSucceeded){
      waitForLogin();
    } if(name == Auth2.notifyLogout){
      _loggedIn = false;
    }
  }

  // Current User Membership

  Future<bool> isAdminForGroup(String groupId) async{
    Group? group = await loadGroup(groupId);
    return group?.currentUserIsAdmin ?? false;
  }

  // Categories APIs

  Future<List<String>?> loadCategories() async {
    List<dynamic>? categoriesJsonArray = await Events().loadEventCategories();
    if (CollectionUtils.isNotEmpty(categoriesJsonArray)) {
      List<String> categoriesList = categoriesJsonArray!.map((e) => e['category'].toString()).toList();
      return categoriesList;
    } else {
      return null;
    }
  }

  // Tags APIs

  Future<List<String>?> loadTags() async {
    return Events().loadEventTags();
  }

  // Groups APIs

  @protected
  Future<void> waitForLogin() async{
    if(!_loggedIn && Auth2().isLoggedIn) {
      try {
        if (_loginCompleters.isEmpty) {
          Completer<void> completer = Completer<void>();
          _loginCompleters.add(completer);
          _login().whenComplete(() {
            _loggedIn = true;
            for (var completer in _loginCompleters) {
              completer.complete();
            }
            _loginCompleters.clear();
          });
          return completer.future;
        } else {
          Completer<void> completer = Completer<void>();
          _loginCompleters.add(completer);
          return completer.future;
        }
      } catch(err){
        Log.e("Failed to invoke groups login API");
        debugPrint(err.toString());
      }
    }
  }

  Future<void> _login() async{
      try {
        if ((Config().groupsUrl != null) && Auth2().isLoggedIn) {
          try {
            String url = '${Config().groupsUrl}/user/login';
            await Network().get(url, auth: Auth2(),);

            // we need just to be sure the request is made no matter for the result at this point
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      } catch (err) {
        debugPrint(err.toString());
      }
  }

  Future<List<Group>?> loadGroups({bool myGroups = false}) async {
    await waitForLogin();
    if ((Config().groupsUrl != null) && ((myGroups != true) || Auth2().isLoggedIn)) {
      try {
        String url = myGroups ? '${Config().groupsUrl}/user/groups' : '${Config().groupsUrl}/groups';
        Response? response = await Network().get(url, auth: Auth2(),);
        int responseCode = response?.statusCode ?? -1;
        String? responseBody = response?.body;
        List<dynamic>? groupsJson = ((responseBody != null) && (responseCode == 200)) ? JsonUtils.decodeList(responseBody) : null;
        return (groupsJson != null) ? Group.listFromJson(groupsJson) : null;
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    
    return null;
  }

  Future<List<Group>?> searchGroups(String searchText) async {
    await waitForLogin();
    if (StringUtils.isEmpty(searchText)) {
      return null;
    }
    String encodedTExt = Uri.encodeComponent(searchText);
    String url = '${Config().groupsUrl}/groups?title=$encodedTExt';
    Response? response = await Network().get(url, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      return Group.listFromJson(JsonUtils.decodeList(responseBody));
    } else {
      debugPrint('Failed to search for groups. Reason: ');
      debugPrint(responseBody);
      return null;
    }
  }

  Future<Group?> loadGroup(String? groupId) async {
    await waitForLogin();
    if(StringUtils.isNotEmpty(groupId)) {
      String url = '${Config().groupsUrl}/groups/$groupId';
      try {
        Response? response = await Network().get(url, auth: Auth2(),);
        int responseCode = response?.statusCode ?? -1;
        String? responseBody = response?.body;
        Map<String, dynamic>? groupsJson = ((responseBody != null) && (responseCode == 200)) ? JsonUtils.decodeMap(responseBody) : null;
        return groupsJson != null ? Group.fromJson(groupsJson) : null;
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  //TBD sync with backend team, update group model and UI
  Future<Group?> loadGroupByCanvasCourseId(int? courseId) async {
    await waitForLogin();
    if (courseId != null) {
      String url = '${Config().groupsUrl}/groups/canvas_course/$courseId';
      try {
        Response? response = await Network().get(url, auth: Auth2());
        int responseCode = response?.statusCode ?? -1;
        String? responseBody = response?.body;
        if (responseCode == 200) {
          Map<String, dynamic>? groupJson = JsonUtils.decodeMap(responseBody);
          return Group.fromJson(groupJson);
        } else {
          Log.d('Failed to load group by canvas course id. Reason: \n$responseCode: $responseBody');
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  Future<GroupError?> createGroup(Group? group) async {
    await waitForLogin();
    if(group != null) {
      String url = '${Config().groupsUrl}/groups';
      try {
        Map<String, dynamic> json = group.toJson(withId: false);
        json["creator_email"] = Auth2().account?.profile?.email ?? "";
        json["creator_name"] = Auth2().account?.profile?.fullName ?? "";
        json["creator_photo_url"] = "";
        String? body = JsonUtils.encode(json);
        Response? response = await Network().post(url, auth: Auth2(), body: body);
        int responseCode = response?.statusCode ?? -1;
        Map<String, dynamic>? jsonData = JsonUtils.decodeMap(response?.body);
        if (responseCode == 200) {
          String? groupId = (jsonData != null) ? JsonUtils.stringValue(jsonData['inserted_id']) : null;
          if (StringUtils.isNotEmpty(groupId)) {
            NotificationService().notify(notifyGroupCreated, group.id);
            return null; // succeeded
          }
        }
        else {
          Map<String, dynamic>? jsonError = (jsonData != null) ? JsonUtils.mapValue(jsonData['error']) : null;
          if (jsonError != null) {
            return GroupError.fromJson(jsonError); // error description
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return GroupError(); // generic error
  }

  Future<GroupError?> updateGroup(Group? group) async {

    await waitForLogin();

    if(group != null) {
      String url = '${Config().groupsUrl}/groups/${group.id}';
      try {
        Map<String, dynamic> json = group.toJson();
        String? body = JsonUtils.encode(json);
        Response? response = await Network().put(url, auth: Auth2(), body: body);
        int responseCode = response?.statusCode ?? -1;
        if(responseCode == 200){
          NotificationService().notify(notifyGroupUpdated, group.id);
          return null;
        }
        else {
          Map<String, dynamic>? jsonData = JsonUtils.decodeMap(response?.body);
          Map<String, dynamic>? jsonError = (jsonData != null) ? JsonUtils.mapValue(jsonData['error']) : null;
          if (jsonError != null) {
            return GroupError.fromJson(jsonError); // error description
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return GroupError(); // generic error
  }

  Future<bool> deleteGroup(String? groupId) async {
    await waitForLogin();
    if (StringUtils.isEmpty(groupId)) {
      return false;
    }
    String url = '${Config().groupsUrl}/group/$groupId';
    Response? response = await Network().delete(url, auth: Auth2());
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

  Future<bool> requestMembership(Group? group, List<GroupMembershipAnswer>? answers) async{
    await waitForLogin();
    if(group != null) {
      String url = '${Config().groupsUrl}/group/${group.id}/pending-members';
      try {
        Map<String, dynamic> json = {};
        json["email"] = Auth2().account?.profile?.email ?? "";
        json["name"] = Auth2().account?.profile?.fullName ?? "";
        json["creator_photo_url"] = "";
        json["member_answers"] = CollectionUtils.isNotEmpty(answers) ? answers!.map((e) => e.toJson()).toList() : [];

        String? body = JsonUtils.encode(json);
        Response? response = await Network().post(url, auth: Auth2(), body: body);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupMembershipRequested, group);
          NotificationService().notify(notifyGroupUpdated, group.id);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> cancelRequestMembership(Group? group) async{
    await waitForLogin();
    if(group?.id != null) {
      String url = '${Config().groupsUrl}/group/${group!.id}/pending-members';
      try {
        Response? response = await Network().delete(url, auth: Auth2(),);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupMembershipCanceled, group);
          NotificationService().notify(notifyGroupUpdated, group.id);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> leaveGroup(Group? group) async {
    await waitForLogin();
    if (StringUtils.isEmpty(group?.id)) {
      return false;
    }
    String url = '${Config().groupsUrl}/group/${group!.id}/members';
    Response? response = await Network().delete(url, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupMembershipQuit, group);
      NotificationService().notify(notifyGroupUpdated, group.id);
      return true;
    } else {
      String? responseString = response?.body;
      debugPrint(responseString);
      return false;
    }
  }

  Future<bool> acceptMembership(Group? group, Member? member, bool? decision, String? reason) async{
    await waitForLogin();
    if(StringUtils.isNotEmpty(group?.id) && StringUtils.isNotEmpty(member?.id) && decision != null) {
      Map<String, dynamic> bodyMap = {"approve": decision, "reject_reason": reason};
      String? body = JsonUtils.encode(bodyMap);
      String url = '${Config().groupsUrl}/memberships/${member!.id}/approval';
      try {
        Response? response = await Network().put(url, auth: Auth2(), body: body);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(decision ? notifyGroupMembershipApproved : notifyGroupMembershipRejected, group);
          NotificationService().notify(notifyGroupUpdated, group?.id);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> updateMembership(Group? group, Member? member, GroupMemberStatus status) async{
    await waitForLogin();
    if(StringUtils.isNotEmpty(group?.id) && StringUtils.isNotEmpty(member?.id)) {
      Map<String, dynamic> bodyMap = {"status":groupMemberStatusToString(status)};
      String? body = JsonUtils.encode(bodyMap);
      String url = '${Config().groupsUrl}/memberships/${member!.id}';
      try {
        Response? response = await Network().put(url, auth: Auth2(), body: body);
        if((response?.statusCode ?? -1) == 200){
          if (status == GroupMemberStatus.admin) {
            NotificationService().notify(notifyGroupMembershipSwitchToAdmin, group);
          }
          else if (status == GroupMemberStatus.member) {
            NotificationService().notify(notifyGroupMembershipSwitchToMember, group);
          }
          NotificationService().notify(notifyGroupUpdated, group!.id);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> deleteMembership(Group? group, Member? member) async{
    await waitForLogin();
    if(StringUtils.isNotEmpty(group?.id) && StringUtils.isNotEmpty(member?.id)) {
      String url = '${Config().groupsUrl}/memberships/${member!.id}';
      try {
        Response? response = await Network().delete(url, auth: Auth2(),);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupMembershipRemoved, group);
          NotificationService().notify(notifyGroupUpdated, group?.id);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }


// Events
  Future<List<dynamic>?> loadEventIds(String? groupId) async{
    await waitForLogin();
    if(StringUtils.isNotEmpty(groupId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events';
      try {
        Response? response = await Network().get(url, auth: Auth2());
        if((response?.statusCode ?? -1) == 200){
          //Successfully loaded ids
          int responseCode = response?.statusCode ?? -1;
          String? responseBody = response?.body;
          List<dynamic>? eventIdsJson = ((responseBody != null) && (responseCode == 200)) ? JsonUtils.decodeList(responseBody) : null;
          return eventIdsJson;
        }
      } catch (e) {
        debugPrint(e.toString());
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
  Future<Map<int, List<GroupEvent>>?> loadEvents (Group? group, {int limit = -1}) async {
    await waitForLogin();
    if (group != null) {
      List<dynamic>? eventIds = await loadEventIds(group.id);
      List<Event>? allEvents = CollectionUtils.isNotEmpty(eventIds) ? await Events().loadEventsByIds(Set<String>.from(eventIds!)) : null;
      if (CollectionUtils.isNotEmpty(allEvents)) {
        List<Event> currentUserEvents = [];
        bool isCurrentUserMemberOrAdmin = group.currentUserIsMemberOrAdmin;
        for (Event event in allEvents!) {
          bool isPrivate = event.isGroupPrivate!;
          if (!isPrivate || isCurrentUserMemberOrAdmin) {
            currentUserEvents.add(event);
          }
        }
        int eventsCount = currentUserEvents.length;
        SortUtils.sort(currentUserEvents);
        //limit the result count // limit available events
        List<Event> visibleEvents = ((limit > 0) && (eventsCount > limit)) ? currentUserEvents.sublist(0, limit) : currentUserEvents;
        List<GroupEvent> groupEvents = <GroupEvent>[];
        for (Event event in visibleEvents) {
          ListUtils.add(groupEvents, GroupEvent.fromJson(event.toJson()));
        }
        return {eventsCount: groupEvents};
      }
    }
    return null;
  }

  Future<bool> linkEventToGroup({String? groupId, String? eventId}) async {
    await waitForLogin();
    if(StringUtils.isNotEmpty(groupId) && StringUtils.isNotEmpty(eventId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events';
      try {
        Map<String, dynamic> bodyMap = {"event_id":eventId};
        String? body = JsonUtils.encode(bodyMap);
        Response? response = await Network().post(url, auth: Auth2(),body: body);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupUpdated, groupId);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> removeEventFromGroup({String? groupId, String? eventId}) async {
    await waitForLogin();
    if(StringUtils.isNotEmpty(groupId) && StringUtils.isNotEmpty(eventId)) {
      String url = '${Config().groupsUrl}/group/$groupId/event/$eventId';
      try {
        Response? response = await Network().delete(url, auth: Auth2());
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupUpdated, groupId);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false;
  }

  Future<String?> updateGroupEvents(Event event) async {
    await waitForLogin();
    String? id = await Events().updateEvent(event);
    if (StringUtils.isNotEmpty(id)) {
      NotificationService().notify(Groups.notifyGroupEventsUpdated);
    }
    return id;
  }

  Future<bool?> deleteEventFromGroup({String? groupId, required Event event}) async {
    bool? deleteResult = false;
    await removeEventFromGroup(groupId: groupId, eventId: event.id);
    String? creatorGroupId = event.createdByGroupId;
    if(creatorGroupId!=null){
      Group? creatorGroup = await loadGroup(creatorGroupId);
      if(creatorGroup!=null && creatorGroup.currentUserIsAdmin){
        deleteResult = await Events().deleteEvent(event.id);
      }
    }
    NotificationService().notify(Groups.notifyGroupEventsUpdated);
    return deleteResult;
  }

  // Event Comments

  Future<bool> postEventComment(String groupId, String eventId, GroupEventComment comment) {
    return Future<bool>.delayed(const Duration(seconds: 1), (){ return true; });
  }

  // Group Posts and Replies

  Future<bool> createPost(String? groupId, GroupPost? post) async {
    await waitForLogin();
    if (StringUtils.isEmpty(groupId) || (post == null)) {
      return false;
    }
    String? requestBody = JsonUtils.encode(post.toJson(create: true));
    String requestUrl = '${Config().groupsUrl}/group/$groupId/posts';
    Response? response = await Network().post(requestUrl, auth: Auth2(), body: requestBody);
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupPostsUpdated, (post.parentId == null) ? 1 : null);
      return true;
    } else {
      Log.e('Failed to create group post. Response: ${response?.body}');
      return false;
    }
  }

  Future<bool> updatePost(String? groupId, GroupPost? post) async {
    await waitForLogin();
    if (StringUtils.isEmpty(groupId) || StringUtils.isEmpty(post?.id)) {
      return false;
    }
    String? requestBody = JsonUtils.encode(post!.toJson(update: true));
    String requestUrl = '${Config().groupsUrl}/group/$groupId/posts/${post.id}';
    Response? response = await Network().put(requestUrl, auth: Auth2(), body: requestBody);
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupPostsUpdated);
      return true;
    } else {
      Log.e('Failed to update group post. Response: ${response?.body}');
      return false;
    }
  }

  Future<bool> deletePost(String? groupId, GroupPost? post) async {
    await waitForLogin();
    if (StringUtils.isEmpty(groupId) || StringUtils.isEmpty(post?.id)) {
      return false;
    }
    String requestUrl = '${Config().groupsUrl}/group/$groupId/posts/${post!.id}';
    Response? response = await Network().delete(requestUrl, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupPostsUpdated, (post.parentId == null) ? -1 : null);
      return true;
    } else {
      Log.e('Failed to delete group post. Response: ${response?.body}');
      return false;
    }
  }

  Future<List<GroupPost>?> loadGroupPosts(String? groupId, {int? offset, int? limit, GroupSortOrder? order}) async {
    await waitForLogin();
    if (StringUtils.isEmpty(groupId)) {
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
    Response? response = await Network().get(requestUrl, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<GroupPost>? posts = GroupPost.fromJsonList(JsonUtils.decodeList(responseString));
      return posts;
    } else {
      Log.e('Failed to retrieve group posts. Response: ${response?.body}');
      return null;
    }
  }

  //Delete User
  void deleteUserData() async{
    try {
      Response? response = (Auth2().isLoggedIn && Config().notificationsUrl != null) ? await Network().delete("${Config().groupsUrl}/user", auth: Auth2()) : null;
      if(response?.statusCode == 200) {
        Log.d('Successfully deleted groups user data');
      }
    } catch (e) {
      Log.e('Failed to load inbox user info');
      Log.e(e.toString());
    }
  }

  Future<Map<String, dynamic>?> loadUserStats() async {
    try {
      Response? response = (Auth2().isLoggedIn && Config().notificationsUrl != null) ? await Network().get("${Config().groupsUrl}/user/stats", auth: Auth2()) : null;
      if(response?.statusCode == 200) {
        return  JsonUtils.decodeMap(response?.body);
      }
    } catch (e) {
      Log.e('Failed to load user stats');
      Log.e(e.toString());
    }

    return null;
  }

  Future<int> getUserPostCount() async{
    Map<String, dynamic>? stats = await loadUserStats();
    return stats != null ? (JsonUtils.intValue(stats["posts_count"]) ?? -1) : -1;
  }

  /////////////////////////
  // DeepLinks

  String get groupDetailUrl => '${DeepLink().appUrl}/group_detail';

  @protected
  void onDeepLinkUri(Uri? uri) {
    if (uri != null) {
      Uri? eventUri = Uri.tryParse(groupDetailUrl);
      if ((eventUri != null) &&
          (eventUri.scheme == uri.scheme) &&
          (eventUri.authority == uri.authority) &&
          (eventUri.path == uri.path))
      {
        try { handleGroupDetail(uri.queryParameters.cast<String, dynamic>()); }
        catch (e) { debugPrint(e.toString()); }
      }
    }
  }

  @protected
  void handleGroupDetail(Map<String, dynamic>? params) {
    if ((params != null) && params.isNotEmpty) {
      if (_groupDetailsCache != null) {
        cacheGroupDetail(params);
      }
      else {
        processGroupDetail(params);
      }
    }
  }

  @protected
  void processGroupDetail(Map<String, dynamic> params) {
    NotificationService().notify(notifyGroupDetail, params);
  }

  @protected
  void cacheGroupDetail(Map<String, dynamic> params) {
    _groupDetailsCache?.add(params);
  }

  @protected
  void processCachedGroupDetails() {
    if (_groupDetailsCache != null) {
      List<Map<String, dynamic>> groupDetailsCache = _groupDetailsCache!;
      _groupDetailsCache = null;

      for (Map<String, dynamic> groupDetail in groupDetailsCache) {
        processGroupDetail(groupDetail);
      }
    }
  }
}

enum GroupSortOrder { asc, desc }

GroupSortOrder? groupSortOrderFromString(String? value) {
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

String? groupSortOrderToString(GroupSortOrder? value) {
  switch(value) {
    case GroupSortOrder.asc:  return 'asc';
    case GroupSortOrder.desc: return 'desc';
    default: return null;
  }
  
}