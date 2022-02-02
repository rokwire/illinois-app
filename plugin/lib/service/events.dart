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
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'package:geolocator/geolocator.dart' as core;
import 'package:http/http.dart' as http;

class Events with Service implements NotificationsListener, ExploreJsonHandler {

  static const String notifyEventDetail  = "edu.illinois.rokwire.explore.event.detail";
  static const String notifyEventCreated = "edu.illinois.rokwire.explore.event.created";
  static const String notifyEventUpdated = "edu.illinois.rokwire.explore.event.updated";

  static const String _rokwireUserUuid = 'ROKWIRE-USER-UUID';
  static const String _rokwireUserPrivacyLevel = 'ROKWIRE-USER-PRIVACY-LEVEL';

  static const int _defaultLocationRadiusInMeters = 1000;

  List<Map<String, dynamic>>? _eventDetailsCache;
  
  // Singletone Factory

  static Events? _instance;

  static Events? get instance => _instance;
  
  @protected
  static set instance(Events? value) => _instance = value;

  factory Events() => _instance ?? (_instance = Events.internal());

  @protected
  Events.internal();

  // Service

  @override
  void createService() {
    Explore.addJsonHandler(this);
    NotificationService().subscribe(this,[
      DeepLink.notifyUri,
    ]);
    _eventDetailsCache = [];
  }

  @override
  void destroyService() {
    Explore.removeJsonHandler(this);
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  void initServiceUI() {
    processCachedEventDetails();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { DeepLink() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      onDeepLinkUri(param);
    }
  }

  // ExploreJsonHandler
  @override bool exploreCanJson(Map<String, dynamic>? json) => Event.canJson(json);
  @override Explore? exploreFromJson(Map<String, dynamic>? json) => Event.fromJson(json);

  // Implementation

  Future<List<Event>?> loadEvents({String? searchText, core.Position? locationData, Set<String?>? categories, EventTimeFilter? eventFilter = EventTimeFilter.upcoming, Set<String>? tags, bool excludeRecurring = true, int? recurrenceId, int limit = 0}) async {
    if(enabled) {
      http.Response? response;
      String queryParameters = buildEventsQueryParameters(
          searchText,
          locationData,
          eventFilter,
          categories,
          tags,
          recurrenceId,
          limit);
      try {
        response = (Config().eventsUrl != null) ? await Network().get('${Config().eventsUrl}$queryParameters', auth: Auth2(), headers: stdEventsHeaders) : null;
      } catch (e) {
        Log.e('Failed to load events');
        Log.e(e.toString());
        return null;
      }
      String? responseBody = response?.body;
      if ((response != null) && (response.statusCode == 200)) {
        //Directory appDocDir = await getApplicationDocumentsDirectory();
        //String cacheFilePath = join(appDocDir.path, 'events.json');
        //File cacheFile = File(cacheFilePath);
        //cacheFile.writeAsString(responseBody, flush: true);
        List<dynamic>? jsonList = JsonUtils.decode(responseBody);
        List<Event>? events = await buildEvents(eventsJsonList: jsonList, excludeRecurringEvents: excludeRecurring, eventFilter: eventFilter);
        return events;
      } else {
        Log.e('Failed to load events');
        Log.e(responseBody);
      }
    }
    return null;
  }

  Future<Event?> getEventById(String? eventId) async {
    if(enabled) {
      if (StringUtils.isEmpty(eventId)) {
        return null;
      }
      http.Response? response;
      try {
        response = (Config().eventsUrl != null) ? await Network().get('${Config().eventsUrl}/$eventId', auth: Auth2(), headers: stdEventsHeaders) : null;
      } catch (e) {
        Log.e('Failed to retrieve event with id: $eventId');
        Log.e(e.toString());
        return null;
      }
      int responseCode = response?.statusCode ?? -1;
      String? responseBody = response?.body;
      if ((response != null) && (responseCode >= 200 && responseCode <= 300)) {
        Map<String, dynamic>? jsonData = JsonUtils.decode(responseBody);
        Event? event = Event.fromJson(jsonData);
        return event;
      } else {
        Log.e('Failed to retrieve event with id: $eventId');
        Log.e(responseBody);
      }
    }
    return null;
  }

  Future<String?> postNewEvent(Event? event) async{
    if(enabled && (event != null)) {
      http.Response? response;
      try {
        dynamic body = json.encode(event.toNotNullJson());
        response = (Config().eventsUrl != null) ? await Network().post(Config().eventsUrl, body: body,
            headers: applyStdEventsHeaders({"Accept": "application/json", "content-type": "application/json"}),
            auth: Auth2()) : null;
        Map<String, dynamic>? jsonData = ((response?.statusCode == 200) || (response?.statusCode == 201)) ? JsonUtils.decode(response?.body) : null;
        String? eventId = (jsonData != null) ? JsonUtils.stringValue(jsonData["id"]) : null;
        if (eventId != null) {
          NotificationService().notify(notifyEventCreated, eventId);
        }
        return eventId;
      } catch (e) {
        Log.e('Failed to load events');
        Log.e(e.toString());
      }
    }
    return null;
  }

  Future<String?> updateEvent(Event? event) async{
    if(enabled && event!=null) {
      http.Response? response;
      try {
        dynamic body = json.encode(event.toNotNullJson());
        String url = Config().eventsUrl! + "/" + event.id!;
        response = (Config().eventsUrl != null) ? await Network().put(url, body: body,
            headers: applyStdEventsHeaders({"Accept": "application/json", "content-type": "application/json"}),
            auth: Auth2()) : null;
        Map<String, dynamic>? jsonData = ((response?.statusCode == 200) || (response?.statusCode == 201)) ? JsonUtils.decode(response?.body) : null;
        String? eventId = (jsonData != null) ? JsonUtils.stringValue(jsonData["id"]) : null;
        if (eventId != null) {
          NotificationService().notify(notifyEventUpdated, eventId);
        }
        return eventId;
      } catch (e) {
        Log.e('Failed to load events');
        Log.e(e.toString());
      }
    }
    return null;
  }

  Future<bool?> deleteEvent(String? eventId) async{
    if(enabled && eventId!=null) {
      http.Response? response;
      try {
        String url = Config().eventsUrl! + "/" + eventId;
        response = (Config().eventsUrl != null) ? await Network().delete(url,
            headers: applyStdEventsHeaders({"Accept": "application/json", "content-type": "application/json"}),
            auth: Auth2()) : null;
    Map<String, dynamic>? jsonData = JsonUtils.decode(response?.body);
    return ((response != null && jsonData!=null) && (response.statusCode == 200 || response.statusCode == 201|| response.statusCode == 202));
    } catch (e) {
    Log.e('Failed to delete event $eventId');
    Log.e(e.toString());
    }
  }
    return null;
  }

  Future<List<Event>?> loadEventsByIds(Set<String?>? eventIds) async {
    if(enabled) {
      if (CollectionUtils.isEmpty(eventIds)) {
        Log.i('Missing event ids param');
        return null;
      }
      StringBuffer idsBuffer = StringBuffer();
      for (String? eventId in eventIds!) {
        idsBuffer.write('id=$eventId&');
      }
      String idsQueryParam = idsBuffer.toString().substring(0, (idsBuffer.length - 1)); //Remove & at last position
      EventTimeFilter upcomingFilter = EventTimeFilter.upcoming;
      String? timeQueryParams = constructEventTimeFilterParams(upcomingFilter);
      String url = '${Config().eventsUrl}?$idsQueryParam&$timeQueryParams';
      http.Response? response;
      try {
        response = (Config().eventsUrl != null) ? await Network().get(url, auth: Auth2(), headers: stdEventsHeaders) : null;
      } catch (e) {
        Log.e('Failed to load events by ids.');
        Log.e(e.toString());
        return null;
      }
      String? responseBody = response?.body;
      if ((response != null) && (response.statusCode == 200)) {
        List<dynamic>? jsonList = JsonUtils.decode(responseBody);
        List<Event>? events = await buildEvents(eventsJsonList: jsonList, excludeRecurringEvents: false, eventFilter: upcomingFilter);
        return events;
      } else {
        Log.e('Failed to load events by ids');
        Log.e(responseBody);
      }
    }
    return null;
  }

  Future<List<EventCategory>?> loadEventCategoriesEx() async {
    http.Response? response;
    if(enabled) {
      try {
        response = (Config().eventsUrl != null) ? await Network().get('${Config().eventsUrl}/categories', auth: Auth2(), headers: stdEventsHeaders) : null;
      } catch (e) {
        Log.e('Failed to load event categories');
        Log.e(e.toString());
        return null;
      }
      String? responseBody = response?.body;
      if ((response != null) && (response.statusCode >= 200) && (response.statusCode <= 301)) {
        return EventCategory.listFromJson(JsonUtils.decodeList(responseBody));
      } else {
        Log.e('Failed to load event categories');
        Log.e(responseBody);
        return null;
      }
    }
    return null;
  }


  Future<List<dynamic>?> loadEventCategories() async {
    if(enabled) {
      http.Response? response;
      try {
        response = (Config().eventsUrl != null) ? await Network().get('${Config().eventsUrl}/categories', auth: Auth2(), headers: stdEventsHeaders) : null;
      } catch (e) {
        Log.e('Failed to load event categories');
        Log.e(e.toString());
        return null;
      }
      String? responseBody = response?.body;
      if ((response != null) && (response.statusCode >= 200) && (response.statusCode <= 301)) {
        List<dynamic>? categories = JsonUtils.decode(responseBody);
        return categories;
      } else {
        Log.e('Failed to load event categories');
        Log.e(responseBody);
        return null;
      }
    }
    return null;
  }

  Future<List<String>?> loadEventTags() async {
    if(enabled) {
      http.Response? response;
      try {
        response = (Config().eventsUrl != null) ? await Network().get('${Config().eventsUrl}/tags', auth: Auth2(), headers: stdEventsHeaders) : null;
      } catch (e) {
        Log.e(e.toString());
        return null;
      }
      int responseCode = response?.statusCode ?? -1;
      String? responseBody = response?.body;
      if ((response != null) && (responseCode >= 200) && (responseCode <= 301)) {
        List<dynamic>? tagsList = JsonUtils.decode(responseBody);
        return (tagsList != null) ? List.from(tagsList) : null;
      } else {
        Log.e(responseBody);
        return null;
      }
    }
    return null;
  }

  int get defaultLocationRadiusInMeters => _defaultLocationRadiusInMeters;

  @protected
  String buildEventsQueryParameters(String? searchText, core.Position? locationData, EventTimeFilter? eventTimeFilter, Set<String?>? categories, Set<String>? tags, int? recurrenceId, int limit) {

    String queryParameters = "";

    /// Search text
    if(StringUtils.isNotEmpty(searchText)){
      queryParameters += constructSearchParams(searchText!);
    }

    ///Location
    if (locationData != null) {
      double? lat = locationData.latitude;
      double? lng =locationData.longitude;
      int radius = defaultLocationRadiusInMeters;
      queryParameters += 'latitude=$lat&longitude=$lng&radius=$radius&';
    }

    /// Time Filter
    String? timeParams = constructEventTimeFilterParams(eventTimeFilter);
    if(timeParams != null){
      queryParameters += "$timeParams&";
    }

    ///User Roles
    String rolesParameters = '';
    Set<String>? targetAudiences = targetAudienceFromUserRoles(Auth2().prefs?.roles);
    if (targetAudiences != null) {
      for (String targetAudience in targetAudiences) {
        rolesParameters += 'targetAudience=$targetAudience&';
      }
    }
    if (StringUtils.isNotEmpty(rolesParameters)) {
      queryParameters += rolesParameters;
    }

    ///Limit results
    if (limit > 0) {
      queryParameters += 'limit=$limit&';
    }

    ///Categories
    if (categories != null && categories.isNotEmpty) {
      for (String? category in categories) {
        if (StringUtils.isNotEmpty(category)) {
          queryParameters += 'category=$category&';
        }
      }
    }

    ///Recurrence Id
    if (recurrenceId != null) {
      queryParameters += 'recurrenceId=$recurrenceId&';
    }

    ///Tags
    if (tags != null && tags.isNotEmpty) {
      for (String tag in tags) {
        if (StringUtils.isNotEmpty(tag)) {
          queryParameters += 'tags=$tag&';
        }
      }
    }

    queryParameters = "?" + queryParameters;
    queryParameters = queryParameters.substring(0, queryParameters.length - 1); //remove the last "&"
    return queryParameters;
  }

  @protected
  String? constructEventTimeFilterParams(EventTimeFilter? eventFilter){
    DateTime? nowUni = AppDateTime().getUniLocalTimeFromUtcTime(AppDateTime().now.toUtc());

    switch (eventFilter) {
      case EventTimeFilter.today:{
          DateTime endDate = DateTime(nowUni!.year, nowUni.month, nowUni.day, 23, 59, 59);
          String? formattedStartDate = AppDateTime().formatDateTime(nowUni, ignoreTimeZone: true);
          String? formattedEndDate = AppDateTime().formatDateTime(endDate, ignoreTimeZone: true);
          return "startDate.lte=$formattedEndDate&endDate.gte=$formattedStartDate";
        }
      case EventTimeFilter.thisWeekend:{
        int currentWeekDay = nowUni!.weekday;
        DateTime weekendStartDateTime = DateTime(nowUni.year, nowUni.month, nowUni.day, 0, 0, 0).add(Duration(days: (6 - currentWeekDay)));
        DateTime? startDate = nowUni.isBefore(weekendStartDateTime) ? weekendStartDateTime : nowUni;
        DateTime endDate = DateTime(nowUni.year, nowUni.month, nowUni.day, 23, 59, 59)
            .add(Duration(days: (7 - currentWeekDay)));
        String? formattedStartDate = AppDateTime().formatDateTime(startDate, ignoreTimeZone: true);
        String? formattedEndDate = AppDateTime().formatDateTime(endDate, ignoreTimeZone: true);
        return "startDate.lte=$formattedEndDate&endDate.gte=$formattedStartDate";
      }
      case EventTimeFilter.next7Day:{
        DateTime endDate = nowUni!.add(const Duration(days: 6));
        String? formattedStartDate = AppDateTime().formatDateTime(nowUni, ignoreTimeZone: true);
        String? formattedEndDate = AppDateTime().formatDateTime(endDate, ignoreTimeZone: true);
        return "startDate.lte=$formattedEndDate&endDate.gte=$formattedStartDate";
      }
      case EventTimeFilter.next30Days:{
        DateTime next = nowUni!.add(const Duration(days: 30));
        DateTime endDate = DateTime(next.year, next.month, next.day, 23, 59, 59);
        String? formattedStartDate = AppDateTime().formatDateTime(nowUni, ignoreTimeZone: true);
        String? formattedEndDate = AppDateTime().formatDateTime(endDate, ignoreTimeZone: true);
        return "startDate.lte=$formattedEndDate&endDate.gte=$formattedStartDate";
      }
      case EventTimeFilter.upcoming:{
        String? formattedStartDate = AppDateTime().formatDateTime(nowUni, ignoreTimeZone: true);
        return "endDate.gte=$formattedStartDate";
      }
      default:
        return null;

    }
  }

  @protected
  String constructSearchParams(String searchInput) {
    String param = "";
    RegExp regExp = RegExp("\\s+");
    List<String> words = searchInput.split(regExp);
    for (String word in words) {
      param += "title=" + word + "&";
    }
    return param;
  }

  @protected
  Future<List<Event>?> buildEvents({List<dynamic>? eventsJsonList, bool excludeRecurringEvents = true, EventTimeFilter? eventFilter}) async {
    if (CollectionUtils.isEmpty(eventsJsonList)) {
      return null;
    }
    List<Event> events = [];
    Map<int, int> recurringIdToIndexMap = HashMap();
    for (dynamic jsonEntry in eventsJsonList!) {
      Event? event = Event.fromJson(jsonEntry);
      if (event != null) {
        bool addEventToList = true;
        bool displayOnlyWithSuperEvent = event.displayOnlyWithSuperEvent ?? false;
        int? recurrenceId = event.recurrenceId;
        int eventIndex = events.length;
        if (excludeRecurringEvents && event.recurringFlag! && (recurrenceId != null)) {
          if (!recurringIdToIndexMap.containsKey(recurrenceId)) {
            recurringIdToIndexMap[recurrenceId] = eventIndex;
          } else {
            int eventIndex = recurringIdToIndexMap[recurrenceId]!;
            Event existingEvent = events[eventIndex];
            if (existingEvent.isRecurring) {
              existingEvent.addRecurrentEvent(event);
            } else {
              Event containerEvent = Event.fromOther(existingEvent)!;
              containerEvent.recurringFlag = true;
              containerEvent.addRecurrentEvent(existingEvent);
              containerEvent.addRecurrentEvent(event);
              events[eventIndex] = containerEvent;
            }
            addEventToList = false;
          }
        } else if(event.isSuperEvent == true) {
          await buildEventsForSuperEvent(event, eventFilter);
        }
        if (addEventToList && !displayOnlyWithSuperEvent) {
          events.add(event);
        }
      }
    }
    //Sort only recurring events
    if (recurringIdToIndexMap.isNotEmpty) {
      recurringIdToIndexMap.forEach((recurringId, index) {
        Event recurringEvent = events.elementAt(index);
        recurringEvent.sortRecurringEvents();
      });
    }
    return events;
  }

  @protected
  static Set<String>? targetAudienceFromUserRoles(Set<UserRole>? roles) {
    if (roles == null || roles.isEmpty) {
      return null;
    }
    Set<String> targetAudiences = {};
    for (UserRole? role in roles) {
      if (role == UserRole.student) {
        targetAudiences.add('students');
      } else if (role == UserRole.alumni) {
        targetAudiences.add('alumni');
      } else if (role == UserRole.employee) {
        targetAudiences.addAll(['faculty', 'staff']);
      } else if (role == UserRole.fan) {
        targetAudiences.add('public');
      } else if (role == UserRole.parent) {
        targetAudiences.add('parents');
      } else if (role == UserRole.visitor) {
        targetAudiences.add('public');
      } else if (role == UserRole.resident) {
        targetAudiences.add('public');
      } else if (role == UserRole.gies) {

      }
    }
    return targetAudiences;
  }

  @protected
  Future<void> buildEventsForSuperEvent(Event superEvent, EventTimeFilter? eventFilter) async {
    List<Map<String, dynamic>>? subEventsMap = superEvent.subEventsMap;
    if (CollectionUtils.isEmpty(subEventsMap)) {
      Log.e('Super event does not contain sub events!');
      return;
    }
    String? superEventId = superEvent.id;
    if (StringUtils.isEmpty(superEventId)) {
      Log.e('Super event has no id!');
      return;
    }
    String queryParameters = '?superEventId=$superEventId';
    String? dateTimeQueryParam = constructEventTimeFilterParams(eventFilter);
    if (StringUtils.isNotEmpty(dateTimeQueryParam)) {
      queryParameters += '&$dateTimeQueryParam';
    }
    http.Response? response;
    try {
      response = (Config().eventsUrl != null) ? await Network().get(
          '${Config().eventsUrl}$queryParameters', auth: Auth2(), headers: stdEventsHeaders) : null;
    } catch (e) {
      Log.e('Failed to load super event sub events');
      Log.e(e.toString());
      return;
    }
    if ((response == null) || response.statusCode != 200) {
      return;
    }
    String responseBody = response.body;
    List<dynamic>? subEventsJsonList = JsonUtils.decodeList(responseBody);
    if (CollectionUtils.isNotEmpty(subEventsJsonList)) {
      for (dynamic eventJson in subEventsJsonList!) {
        String? id = eventJson['id'];
        Map<String, dynamic>? subEventJson = (subEventsMap as List<Map<String, dynamic>?>).firstWhere((jsonEntry) => (id == jsonEntry!['id']), orElse: () {
          debugPrint('No matching sub event');
          return {};
        });
        if ((subEventJson != null) && subEventJson.isNotEmpty) {
          Event event = Event.fromJson(eventJson)!;
          event.track = subEventJson['track'];
          if (true == subEventJson['isFeatured']) {
            superEvent.addFeaturedEvent(event);
          }
          superEvent.addSubEvent(event);
        }
      }
    }
  }


  String get rokwireUserUuid => _rokwireUserUuid;
  String get rokwireUserPrivacyLevel => _rokwireUserPrivacyLevel;
  Map<String, String> get stdEventsHeaders => applyStdEventsHeaders(null);

  @protected
  Map<String, String> applyStdEventsHeaders(Map<String, String>? headers) {
    headers ??= {};
    headers[rokwireUserUuid] = Auth2().accountId ?? "null";
    headers[rokwireUserPrivacyLevel] = Auth2().prefs?.privacyLevel?.toString() ?? "null";
    return headers;
  }

  /////////////////////////
  // Enabled

  bool get enabled => StringUtils.isNotEmpty(Config().eventsUrl);

  /////////////////////////
  // DeepLinks

  String get eventDetailUrl => '${DeepLink().appUrl}/event_detail';

  @protected
  void onDeepLinkUri(Uri? uri) {
    if (uri != null) {
      Uri? eventUri = Uri.tryParse(eventDetailUrl);
      if ((eventUri != null) &&
          (eventUri.scheme == uri.scheme) &&
          (eventUri.authority == uri.authority) &&
          (eventUri.path == uri.path))
      {
        try { handleEventDetail(uri.queryParameters.cast<String, dynamic>()); }
        catch (e) { debugPrint(e.toString()); }
      }
    }
  }

  @protected
  void handleEventDetail(Map<String, dynamic>? params) {
    if ((params != null) && params.isNotEmpty) {
      if (_eventDetailsCache != null) {
        cacheEventDetail(params);
      }
      else {
        processEventDetail(params);
      }
    }
  }

  @protected
  void processEventDetail(Map<String, dynamic> params) {
    NotificationService().notify(notifyEventDetail, params);
  }

  @protected
  void cacheEventDetail(Map<String, dynamic> params) {
    _eventDetailsCache?.add(params);
  }

  @protected
  void processCachedEventDetails() {
    if (_eventDetailsCache != null) {
      List<Map<String, dynamic>> eventDetailsCache = _eventDetailsCache!;
      _eventDetailsCache = null;

      for (Map<String, dynamic> eventDetail in eventDetailsCache) {
        processEventDetail(eventDetail);
      }
    }
  }

}