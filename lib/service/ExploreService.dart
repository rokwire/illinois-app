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
import 'package:http/http.dart' as http;
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Config.dart';
import 'package:location/location.dart' as Core;

import 'package:illinois/service/User.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/UserData.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Log.dart';


/// ExploreService does rely on Service initialization API so it does not override service interfaces and is not registered in Services.
class ExploreService /* with Service */ {
  static final ExploreService _instance = ExploreService._internal();

  factory ExploreService() {
    return _instance;
  }

  ExploreService._internal();

  Future<List<Explore>> loadEvents({String searchText, Core.LocationData locationData, Set<String> categories, DateTime startDate, DateTime startDateLimit,
    DateTime endDate, Set<String> tags, bool excludeRecurring = true, int recurrenceId, int limit = 0}) async {
    if(_enabled) {
      if (startDate == null) {
        startDate = DateTime.now();
      }
      http.Response response;
      DateTime startDateInGmt = AppDateTime().getUtcTimeFromDeviceTime(startDate);
      DateTime startDateLimitInGmt = AppDateTime().getUtcTimeFromDeviceTime(startDateLimit);
      DateTime endDateInGmt = AppDateTime().getUtcTimeFromDeviceTime(endDate);
      String queryParameters = _buildEventsQueryParameters(
          searchText,
          locationData,
          startDateInGmt,
          startDateLimitInGmt,
          endDateInGmt,
          categories,
          tags,
          recurrenceId,
          limit);
      try {
        response = (Config().eventsOrConvergeUrl != null) ? await Network().get('${Config().eventsOrConvergeUrl}$queryParameters', auth: NetworkAuth.App, headers: _stdEventsHeaders) : null;
      } catch (e) {
        Log.e('Failed to load events');
        Log.e(e.toString());
        return null;
      }
      String responseBody = response?.body;
      if ((response != null) && (response.statusCode == 200)) {
        //Directory appDocDir = await getApplicationDocumentsDirectory();
        //String cacheFilePath = join(appDocDir.path, 'events.json');
        //File cacheFile = File(cacheFilePath);
        //cacheFile.writeAsString(responseBody, flush: true);
        List<dynamic> jsonList = AppJson.decode(responseBody);
        List<Event> events = await _buildEvents(eventsJsonList: jsonList, excludeRecurringEvents: excludeRecurring, nowUtc: startDateInGmt);
        return events;
      } else {
        Log.e('Failed to load events');
        Log.e(responseBody);
      }
    }
    return null;
  }

  Future<List<Event>> loadSuperEventSubEvents(String superEventId) async {
    if(_enabled) {
      if (AppString.isStringEmpty(superEventId)) {
        return null;
      }
      DateTime nowUtc = DateTime.now().toUtc();
      String dateTimeFormatted = AppDateTime().formatDateTime(nowUtc, ignoreTimeZone: true);
      http.Response response;
      try {
        response = (Config().eventsOrConvergeUrl != null) ? await Network().get(
            '${Config().eventsOrConvergeUrl}?superEventId=$superEventId&startDate=$dateTimeFormatted', auth: NetworkAuth.App) : null;
      } catch (e) {
        Log.e('Failed to retrieve super event with id: $superEventId');
        Log.e(e.toString());
        return null;
      }
      int responseCode = response?.statusCode ?? -1;
      String responseBody = response?.body;
      if ((response != null) && (responseCode >= 200 && responseCode <= 300)) {
        List<dynamic> jsonList = AppJson.decode(responseBody);
        List<Event> subEvents = await _buildEvents(eventsJsonList: jsonList);
        return subEvents;
      } else {
        Log.e('Failed to retrieve sub events for super event with id: $superEventId');
        Log.e(responseBody);
      }
    }
    return null;
  }

  Future<Explore> getEventById(String eventId) async {
    if(_enabled) {
      if (AppString.isStringEmpty(eventId)) {
        return null;
      }
      http.Response response;
      try {
        response = (Config().eventsOrConvergeUrl != null) ? await Network().get('${Config().eventsOrConvergeUrl}/$eventId', auth: NetworkAuth.App, headers: _stdEventsHeaders) : null;
      } catch (e) {
        Log.e('Failed to retrieve event with id: $eventId');
        Log.e(e.toString());
        return null;
      }
      int responseCode = response?.statusCode ?? -1;
      String responseBody = response?.body;
      if ((response != null) && (responseCode >= 200 && responseCode <= 300)) {
        Map<String, dynamic> jsonData = AppJson.decode(responseBody);
        Event event = Event.fromJson(jsonData);
        return event;
      } else {
        Log.e('Failed to retrieve event with id: $eventId');
        Log.e(responseBody);
      }
    }
    return null;
  }

  Future<bool> postNewEvent(Explore explore) async{
    if(_enabled) {
      Event event = explore is Event ? explore : null;
      http.Response response;
      try {
        response = (Config().eventsOrConvergeUrl != null) ? await Network().post(Config().eventsOrConvergeUrl, body: json.encode(event.toJson()),
            headers: _applyStdEventsHeaders({"Accept": "application/json", "content-type": "application/json"}),
            auth: NetworkAuth.User) : null;
        return ((response != null) && (response.statusCode == 200 || response.statusCode == 201));
      } catch (e) {
        Log.e('Failed to load events');
        Log.e(e.toString());
      }
    }
    return false;
  }

  Future<List<Event>> loadEventsByIds(Set<String> eventIds) async {
    if(_enabled) {
      if (AppCollection.isCollectionEmpty(eventIds)) {
        Log.i('Missing event ids param');
        return null;
      }
      StringBuffer idsBuffer = StringBuffer();
      eventIds.forEach((eventId) {
        idsBuffer.write('id=$eventId&');
      });
      String idsQueryParam = idsBuffer.toString().substring(0, (idsBuffer.length - 1)); //Remove & at last position
      DateTime startDateInGmt = AppDateTime().getUtcTimeFromDeviceTime(DateTime.now());
      String dateFormatted = AppDateTime().formatDateTime(startDateInGmt, ignoreTimeZone: true);
      String dateTimeQueryParam = '&startDate=$dateFormatted';
      http.Response response;
      String queryParameters = '?$idsQueryParam$dateTimeQueryParam';
      try {
        response = (Config().eventsOrConvergeUrl != null) ? await Network().get(
            '${Config().eventsOrConvergeUrl}$queryParameters', auth: NetworkAuth.App, headers: _stdEventsHeaders) : null;
      } catch (e) {
        Log.e('Failed to load events by ids.');
        Log.e(e?.toString());
        return null;
      }
      String responseBody = response?.body;
      if ((response != null) && (response.statusCode == 200)) {
        List<dynamic> jsonList = AppJson.decode(responseBody);
        List<Event> events = await _buildEvents(eventsJsonList: jsonList, excludeRecurringEvents: false, nowUtc: startDateInGmt);
        return events;
      } else {
        Log.e('Failed to load events by ids');
        Log.e(responseBody);
      }
    }
    return null;
  }

  Future<List<ExploreCategory>> loadEventCategoriesEx() async {
    http.Response response;
    if(_enabled) {
      try {
        response = (Config().eventsUrl != null) ? await Network().get('${Config().eventsUrl}/categories', auth: NetworkAuth.App, headers: _stdEventsHeaders) : null;
      } catch (e) {
        Log.e('Failed to load event categories');
        Log.e(e.toString());
        return null;
      }
      String responseBody = response?.body;
      if ((response != null) && (response.statusCode >= 200) && (response.statusCode <= 301)) {
        List<dynamic> categoriesJson = AppJson.decode(responseBody);
        List<ExploreCategory> categories = AppCollection.isCollectionNotEmpty(categoriesJson) ? categoriesJson.map((entry) => ExploreCategory.fromJson(entry)).toList() : null;
        return categories;
      } else {
        Log.e('Failed to load event categories');
        Log.e(responseBody);
        return null;
      }
    }
    return null;
  }


  Future<List<dynamic>> loadEventCategories() async {
    if(_enabled) {
      http.Response response;
      try {
        response = (Config().eventsUrl != null) ? await Network().get('${Config().eventsUrl}/categories', auth: NetworkAuth.App, headers: _stdEventsHeaders) : null;
      } catch (e) {
        Log.e('Failed to load event categories');
        Log.e(e.toString());
        return null;
      }
      String responseBody = response?.body;
      if ((response != null) && (response.statusCode >= 200) && (response.statusCode <= 301)) {
        List<dynamic> categories = AppJson.decode(responseBody);
        return categories;
      } else {
        Log.e('Failed to load event categories');
        Log.e(responseBody);
        return null;
      }
    }
    return null;
  }

  Future<List<String>> loadEventTags() async {
    if(_enabled) {
      http.Response response;
      try {
        response = (Config().eventsUrl != null) ? await Network().get('${Config().eventsUrl}/tags', auth: NetworkAuth.App, headers: _stdEventsHeaders) : null;
      } catch (e) {
        Log.e(e.toString());
        return null;
      }
      int responseCode = response?.statusCode ?? -1;
      String responseBody = response?.body;
      if ((response != null) && (responseCode >= 200) && (responseCode <= 301)) {
        List<dynamic> tagsList = AppJson.decode(responseBody);
        return (tagsList != null) ? List.from(tagsList) : null;
      } else {
        Log.e(responseBody);
        return null;
      }
    }
    return null;
  }

  String _buildEventsQueryParameters(String searchText, Core.LocationData locationData,
      DateTime startDate, DateTime startDateLimit, DateTime endDate, Set<String> categories, Set<String> tags,
      int recurrenceId, int limit) {

    String queryParameters = "";

    /// Search text
    if(AppString.isStringNotEmpty(searchText)){
      queryParameters += _constructSearchParams(searchText);
    }

    ///Location
    if (locationData != null) {
      double lat = locationData.latitude;
      double lng =locationData.longitude;
      int radius = AppLocation.defaultLocationRadiusInMeters;
      queryParameters += 'latitude=$lat&longitude=$lng&radius=$radius&';
    }

    ///StartDate
    if (startDate != null) {
      String startDateFormatted = AppDateTime().formatDateTime(
          startDate, ignoreTimeZone: true);
      queryParameters += 'startDate=$startDateFormatted&';
    }

    ///StartDateLimit
    if (startDateLimit != null) {
      String startDateLimitFormatted = AppDateTime().formatDateTime(
          startDateLimit, ignoreTimeZone: true);
      queryParameters += 'startDateLimit=$startDateLimitFormatted&';
    }

    ///End Date
    if (endDate != null) {
      String endDateFormatted = AppDateTime().formatDateTime(
          endDate, ignoreTimeZone: true);
      queryParameters += 'endDate=$endDateFormatted&';
    }

    ///User Roles
    String rolesParameters = '';
    Set<String> targetAudiences = UserRole.targetAudienceFromUserRoles(User().roles);
    if (targetAudiences != null) {
      for (String targetAudience in targetAudiences) {
        rolesParameters += 'targetAudience=$targetAudience&';
      }
    }
    if (AppString.isStringNotEmpty(rolesParameters)) {
      queryParameters += rolesParameters;
    }

    ///Limit results
    if (limit > 0) {
      queryParameters += 'limit=$limit&';
    }

    ///Categories
    if (categories != null && categories.length > 0) {
      for (String category in categories) {
        if (AppString.isStringNotEmpty(category)) {
          queryParameters += 'category=$category&';
        }
      }
    }

    ///Recurrence Id
    if (recurrenceId != null) {
      queryParameters += 'recurrenceId=$recurrenceId&';
    }

    ///Tags
    if (tags != null && tags.length > 0) {
      for (String tag in tags) {
        if (AppString.isStringNotEmpty(tag)) {
          queryParameters += 'tags=$tag&';
        }
      }
    }

    queryParameters = "?" + queryParameters;
    queryParameters = queryParameters.substring(0, queryParameters.length - 1); //remove the last "&"
    return queryParameters;
  }

  String _constructSearchParams(String searchInput) {
    String param = "";
    RegExp regExp = new RegExp("\\s+");
    List<String> words = searchInput.split(regExp);
    for (String word in words) {
      param += "title=" + word + "&";
    }
    return param;
  }

  Future<List<Event>> _buildEvents({List<dynamic> eventsJsonList, bool excludeRecurringEvents = true, DateTime nowUtc}) async {
    if (AppCollection.isCollectionEmpty(eventsJsonList)) {
      return null;
    }
    List<Event> events = List<Event>();
    Map<int, int> recurringIdToIndexMap = HashMap();
    for (dynamic jsonEntry in eventsJsonList) {
      Event event = Event.fromJson(jsonEntry);
      if (event != null) {
        bool addEventToList = true;
        int recurrenceId = event.recurrenceId;
        int eventIndex = events.length;
        if (excludeRecurringEvents && event.recurringFlag && (recurrenceId != null)) {
          if (!recurringIdToIndexMap.containsKey(recurrenceId)) {
            recurringIdToIndexMap[recurrenceId] = eventIndex;
          } else {
            int eventIndex = recurringIdToIndexMap[recurrenceId];
            Event existingEvent = events[eventIndex];
            if (existingEvent?.isRecurring ?? false) {
              existingEvent.addRecurrentEvent(event);
            } else {
              Event containerEvent = Event.fromOther(existingEvent);
              containerEvent.recurringFlag = true;
              containerEvent.addRecurrentEvent(existingEvent);
              containerEvent.addRecurrentEvent(event);
              events[eventIndex] = containerEvent;
            }
            addEventToList = false;
          }
        } else if(event.isSuperEvent) {
          await _buildEventsForSuperEvent(event, nowUtc);
        }
        if (addEventToList) {
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

  Future<void> _buildEventsForSuperEvent(Event superEvent, DateTime nowUtc) async {
    List<Map<String, dynamic>> subEventsMap = superEvent.subEventsMap;
    if (AppCollection.isCollectionEmpty(subEventsMap)) {
      Log.e('Super event does not contain sub events!');
      return;
    }
    String superEventId = superEvent?.id;
    if (AppString.isStringEmpty(superEventId)) {
      Log.e('Super event has no id!');
      return;
    }
    String dateTimeQueryParam = '';
    if (nowUtc == null) {
      nowUtc = DateTime.now().toUtc();
    }
    String dateFormatted = AppDateTime().formatDateTime(nowUtc, ignoreTimeZone: true);
    dateTimeQueryParam = '&startDate=$dateFormatted';
    http.Response response;
    String queryParameters = '?superEventId=$superEventId$dateTimeQueryParam';
    try {
      response = (Config().eventsOrConvergeUrl != null) ? await Network().get(
          '${Config().eventsOrConvergeUrl}$queryParameters', auth: NetworkAuth.App, headers: _stdEventsHeaders) : null;
    } catch (e) {
      Log.e('Failed to load super event sub events');
      Log.e(e.toString());
      return;
    }
    if ((response == null) || response.statusCode != 200) {
      return;
    }
    String responseBody = response.body;
    List<dynamic> subEventsJsonList = AppJson.decodeList(responseBody);
    if (AppCollection.isCollectionNotEmpty(subEventsJsonList)) {
      for (dynamic eventJson in subEventsJsonList) {
        String id = eventJson['id'];
        Map<String, dynamic> subEventJson = subEventsMap.firstWhere((jsonEntry) => (id == jsonEntry['id']), orElse: () {
          print('No matching sub event');
          return null;
        });
        if (subEventJson != null) {
          Event event = Event.fromJson(eventJson);
          event.track = subEventJson['track'];
          if (true == subEventJson['isFeatured']) {
            superEvent.addFeaturedEvent(event);
          }
          superEvent.addSubEvent(event);
        }
      }
    }
  }

  Map<String, String> get _stdEventsHeaders {
    return _applyStdEventsHeaders(null);
  }

  Map<String, String> _applyStdEventsHeaders(Map<String, String> headers) {
    if (headers == null) {
      headers = Map<String, String>();
    }
    headers[Network.RokwireUserUuid] = User().uuid ?? "null";
    headers[Network.RokwireUserPrivacyLevel] = User().privacyLevel?.toString() ?? "null";
    return headers;
  }

  /////////////////////////
  // Enabled

  bool get _enabled => AppString.isStringNotEmpty(Config().eventsOrConvergeUrl)
      && AppString.isStringNotEmpty(Config().eventsUrl);
}