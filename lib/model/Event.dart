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

import 'package:illinois/service/Assets.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Location.dart';
import 'package:illinois/model/UserData.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

//////////////////////////////
/// Event

class Event with Explore implements Favorite {
  String id;
  String title;
  String subTitle;
  String shortDescription;
  String longDescription;
  String imageURL;
  String placeID;

  Location location;
  
  int convergeScore;
  String convergeUrl;

  String sourceEventId;
  String startDateString;
  String endDateString;
  DateTime startDateGmt;
  DateTime endDateGmt;
  String category;
  String subCategory;
  String sponsor;
  String titleUrl;
  List<String> targetAudience;
  String icalUrl;
  String outlookUrl;
  String speaker;
  String registrationLabel;
  String registrationUrl;
  String cost;
  List<Contact> contacts;
  List<String> tags;
  DateTime modifiedDate;
  String submissionResult;
  String eventId;
  bool allDay;
  bool recurringFlag;
  int recurrenceId;
  List<Event> recurringEvents;

  bool isSuperEvent;
  bool isVirtual;
  List<Map<String, dynamic>> subEventsMap;
  String track;
  List<Event> _subEvents;
  List<Event> _featuredEvents;

  String randomImageURL;

  Event({Map<String, dynamic> json, Event other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    dynamic targetAudienceJson = json['targetAudience'];
    List<String> targetAudience = targetAudienceJson != null ? List.from(targetAudienceJson) : null;
    
    dynamic tagsJson = json['tags'];
    List<String> tags = tagsJson != null ? List.from(tagsJson) : null;
    
    List<dynamic> contactsJson = json['contacts'];
    List<Contact> contacts = (contactsJson != null) ? contactsJson.map((value) => Contact.fromJson(value)).toList() : null;
    
    List<dynamic> recurringEventsJson = json['recurringEvents'];
    List<Event> recurringEvents = (recurringEventsJson != null) ? recurringEventsJson.map((value) => Event.fromJson(value)).toList() : null;

    List<dynamic> subEventsJson = json['subEvents'];
    List<Map<String, dynamic>> subEventsMap = _constructSubEventsMap(subEventsJson);

    id = json["id"];
    title = json['title'];
    subTitle = json['subTitle'];
    shortDescription = json['shortDescription'];
    longDescription = json.containsKey("description") ? json["description"] : json['longDescription']; /*Back compatibility keep until we use longDescription */
    imageURL = json['imageURL'];
    placeID = json['placeID'];
    location = Location.fromJSON(json['location']);
    eventId = json['eventId'];
    startDateString = json['startDate'];
    endDateString = json['endDate'];
    startDateGmt = AppDateTime().dateTimeFromString(json['startDate'], format: AppDateTime.serverResponseDateTimeFormat, isUtc: true);
    endDateGmt = AppDateTime().dateTimeFromString(json['endDate'], format: AppDateTime.serverResponseDateTimeFormat, isUtc: true);
    category = json['category'];
    subCategory = json['subCategory'];
    sponsor = json['sponsor'];
    titleUrl = json['titleURL'];
    this.targetAudience = targetAudience;
    icalUrl = json['icalUrl'];
    outlookUrl = json['outlookUrl'];
    speaker = json['speaker'];
    registrationLabel = json['registrationLabel'];
    registrationUrl = json['registrationUrl'];
    cost = json['cost'];
    this.contacts = contacts;
    this.tags = tags;
    modifiedDate = AppDateTime().dateTimeFromString(json['modifiedDate']);
    submissionResult = json['submissionResult'];
    allDay = json['allDay'] ?? false;
    recurringFlag = json['recurringFlag'] ?? false;
    recurrenceId = json['recurrenceId'];
    this.recurringEvents = recurringEvents;
    convergeScore = json['converge_score'];
    convergeUrl = json['converge_url'];
    isSuperEvent = json['isSuperEvent'] ?? false;
    this.subEventsMap = subEventsMap;
    track = json['track'];
    isVirtual = json['isVirtual'];
  }

  void _initFromOther(Event other) {
    id = other?.id;
    title = other?.title;
    subTitle = other?.subTitle;
    shortDescription = other?.shortDescription;
    longDescription = other?.longDescription;
    imageURL = other?.imageURL;
    placeID = other?.placeID;
    location = other?.location;
    eventId = other?.eventId;
    startDateString = other?.startDateString;
    endDateString = other?.endDateString;
    startDateGmt = other?.startDateGmt;
    endDateGmt = other?.endDateGmt;
    category = other?.category;
    subCategory = other?.subCategory;
    sponsor = other?.sponsor;
    titleUrl = other?.titleUrl;
    targetAudience = other?.targetAudience;
    icalUrl = other?.icalUrl;
    outlookUrl = other?.outlookUrl;
    speaker = other?.speaker;
    registrationLabel = other?.registrationLabel;
    registrationUrl = other?.registrationUrl;
    cost = other?.cost;
    contacts = other?.contacts;
    tags = other?.tags;
    modifiedDate = other?.modifiedDate;
    submissionResult = other?.submissionResult;
    allDay = other?.allDay;
    recurringFlag = other?.recurringFlag;
    recurrenceId = other?.recurrenceId;
    recurringEvents = other?.recurringEvents;
    convergeScore = other?.convergeScore;
    convergeUrl = other?.convergeUrl;
    isSuperEvent = other?.isSuperEvent;
    subEventsMap = other?.subEventsMap;
    track = other?.track;
    isVirtual = other?.isVirtual;
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Event(json: json) : null;
  }

  factory Event.fromOther(Event other) {
    return (other != null) ? Event(other: other) : null;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "subTitle": subTitle,
      "shortDescription": shortDescription,
      "longDescription": longDescription,
      "imageURL": imageURL,
      "placeID": placeID,
      "location": location?.toJson(),

      "eventId" : eventId,
      "startDate": startDateString,
      "startDateLocal": AppDateTime().formatDateTime(
          startDateLocal, format: AppDateTime.iso8601DateTimeFormat,
          ignoreTimeZone: true),
      "endDate": endDateString,
      "endDateLocal": AppDateTime().formatDateTime(
          endDateLocal, format: AppDateTime.iso8601DateTimeFormat,
          ignoreTimeZone: true),
      "category": category,
      "subCategory": subCategory,
      "sponsor": sponsor??"", // Required for CreateEvent
      "titleURL": titleUrl,
      "targetAudience": targetAudience,
      "icalUrl": icalUrl,
      "outlookUrl": outlookUrl,
      "speaker": speaker,
      "registrationLabel": registrationLabel,
      "registrationUrl": registrationUrl,
      "cost": cost,
      "contacts": _encodeContacts(),
      "tags": tags,
      "modifiedDate": AppDateTime().formatDateTime(modifiedDate, ignoreTimeZone: true),
      "submissionResult": submissionResult,
      "allDay": allDay,
      "recurringFlag": recurringFlag,
      "recurrenceId": recurrenceId,
      "recurringEvents": _encodeRecurringEvents(),
      "converge_score": convergeScore,
      "converge_url": convergeUrl,
      "isSuperEvent": isSuperEvent,
      "subEvents": subEventsMap,
      "track": track,
      'isVirtual': isVirtual,
    };
  }

  static bool canJson(Map<String, dynamic> json) {
    return (json != null) && (json['eventId'] != null);
  }

  List<dynamic> _encodeContacts(){
    List<dynamic> result = new List();
    if(contacts!=null && contacts.isNotEmpty) {
      contacts.forEach((Contact contact) {
        result.add(contact.toJson());
      });
    }

    return result;
  }

  List<dynamic> _encodeRecurringEvents() {
    if (!isRecurring) {
      return null;
    }
    List<dynamic> eventsList = List();
    recurringEvents.forEach((Event event) {
      eventsList.add(event.toJson());
    });
    return eventsList;
  }

  String toString() {
    return toJson()?.toString();
  }

  bool get isGameEvent {
    bool isAthletics = (category == "Athletics" || category == "Recreation");
    bool hasGameId = AppString.isStringNotEmpty(speaker);
    bool hasRegistrationFlag = AppString.isStringNotEmpty(registrationLabel);
    return isAthletics && hasGameId && hasRegistrationFlag;
  }

  bool get isRecurring {
    return recurringFlag && (recurringEvents?.isNotEmpty ?? false);
  }

  void addRecurrentEvent(Event event) {
    if (recurringEvents == null) {
      recurringEvents = List();
    }
    recurringEvents.add(event);
  }

  void sortRecurringEvents() {
    if (isRecurring) {
      recurringEvents.sort((Event first, Event second) {
        DateTime firstStartDate = first?.startDateGmt;
        DateTime secondStartDate = second?.startDateGmt;
        if (firstStartDate != null && secondStartDate != null) {
          return firstStartDate.compareTo(secondStartDate);
        } else if (firstStartDate != null) {
          return -1;
        } else if (secondStartDate != null) {
          return 1;
        } else {
          return 0;
        }
      });
    }
  }

  List<Event> get subEvents {
    return _subEvents;
  }

  void addSubEvent(Event event) {
    if (!isSuperEvent || (event == null)) {
      return;
    }
    if (_subEvents == null) {
      _subEvents = List();
    }
    _subEvents.add(event);
  }

  List<Event> get featuredEvents {
    return _featuredEvents;
  }

  void addFeaturedEvent(Event event) {
    if (!isSuperEvent || (event == null)) {
      return;
    }
    if (_featuredEvents == null) {
      _featuredEvents = List();
    }
    _featuredEvents.add(event);
  }

  static List<Map<String, dynamic>> _constructSubEventsMap(List<dynamic> subEventsJson) {
    if (subEventsJson == null || subEventsJson.isEmpty) {
      return null;
    }
    List<Map<String, dynamic>> subEvents = List();
    for (dynamic eventDynamic in subEventsJson) {
      if (eventDynamic is Map<String, dynamic>) {
        subEvents.add(eventDynamic);
      }
    }
    return subEvents;
  }

  // Explore
  
  @override String   get exploreId               { return id ?? eventId; }
  @override String   get exploreTitle            { return title; }
  @override String   get exploreSubTitle         { return subTitle; }
  @override String   get exploreShortDescription { return shortDescription; }
  @override String   get exploreLongDescription  { return longDescription; }
  @override String   get explorePlaceId          { return placeID; }
  @override Location get exploreLocation         { return location; }
  @override Color    get uiColor                 { return Styles().colors.eventColor; }

  @override String   get exploreImageURL         {
    if ((imageURL != null) && imageURL.isNotEmpty)
      return imageURL;

    if (randomImageURL == null)
      randomImageURL = _createRandomImageUrl();

    return randomImageURL.isNotEmpty ? randomImageURL : null;
  }

  @override
  Map<String, dynamic> get analyticsAttributes {
    Map<String, dynamic> attributes = {
      Analytics.LogAttributeEventId:   exploreId,
      Analytics.LogAttributeEventName: exploreTitle,
      Analytics.LogAttributeEventCategory: category,
      Analytics.LogAttributeRecurrenceId: recurrenceId,
    };
    attributes.addAll(analyticsSharedExploreAttributes ?? {});
    return attributes;
  }

  DateTime get startDateLocal     { return AppDateTime().getUniLocalTimeFromUtcTime(startDateGmt); }
  DateTime get endDateLocal       { return AppDateTime().getUniLocalTimeFromUtcTime(endDateGmt); }


  static String favoriteKeyName = "eventIds";
  @override String get favoriteId => exploreId;
  @override String get favoriteKey => favoriteKeyName;

  ///
  /// Specific for Events with 'Athletics' category
  ///
  /// Requirement 1:
  /// 'When in explore/events and the category is athletics, do not show the time anymore, just the date. Also do not process it for timezone (now we go to athletics detail panel we will rely on how detail already deals with any issues)'
  ///
  /// Requirement 2: 'If an event is longer than 1 day, then please show the Date as (for example) Sep 26 - Sep 29.'
  String get displayDateTime {
    final String dateFormat = 'MMM dd';
    final bool isAthleticsCategory = (category == 'Athletics');
    int eventDays = (endDateGmt?.difference(startDateGmt)?.inDays ?? 0).abs();
    bool eventIsMoreThanOneDay = (eventDays >= 1);
    if (eventIsMoreThanOneDay) {
      String startDateFormatted = AppDateTime().formatDateTime(startDateGmt, format: dateFormat, ignoreTimeZone: isAthleticsCategory);
      String endDateFormatted = AppDateTime().formatDateTime(endDateGmt, format: dateFormat, ignoreTimeZone: isAthleticsCategory);
      return '$startDateFormatted - $endDateFormatted';
    } else {
      if (isAthleticsCategory) {
        return AppDateTime().formatDateTime(startDateGmt, format: dateFormat, ignoreTimeZone: true);
      }
      return AppDateTime().getDisplayDateTime(startDateGmt, allDay: allDay);
    }
  }

  String get displayDate {
    return AppDateTime().getDisplayDay(dateTimeUtc: startDateGmt, allDay: allDay);
  }

  String get displayStartEndTime {
    if (allDay) {
      return Localization().getStringEx('model.explore.time.all_day', 'All Day');
    }
    String startTime = AppDateTime().getDisplayTime(dateTimeUtc: startDateGmt, allDay: allDay);
    String endTime = AppDateTime().getDisplayTime(dateTimeUtc: endDateGmt, allDay: allDay);
    String displayTime = '$startTime';
    if (AppString.isStringNotEmpty(endTime)) {
      displayTime += '-$endTime';
    }
    return displayTime;
  }

  String get displayRecurringDates {
    if (!isRecurring) {
      return '';
    }
    Event first = recurringEvents.first;
    Event last = recurringEvents.last;
    return _buildDisplayDates(first, last);
  }

  String get displaySuperTime {
    String date = AppDateTime().getDisplayDay(dateTimeUtc: startDateGmt, allDay: allDay);
    String time = displayStartEndTime;
    return '$date, $time';
  }

  String get displaySuperDates {
    if (!isSuperEvent) {
      return '';
    }
    if (subEvents == null || subEvents.isEmpty) {
      return displayDateTime;
    }
    Event first = subEvents.first;
    Event last = subEvents.last;
    return _buildDisplayDates(first, last);
  }

  String get timeDisplayString {
    if (isRecurring) {
      return displayRecurringDates;
    } else if (isSuperEvent) {
      return displaySuperDates;
    }
    return displayDateTime;
  }

  String _buildDisplayDates(Event firstEvent, Event lastEvent) {
    bool useDeviceLocalTime = Storage().useDeviceLocalTimeZone;
    DateTime startDateTime;
    DateTime endDateTime;
    if (useDeviceLocalTime) {
      startDateTime = AppDateTime().getDeviceTimeFromUtcTime(firstEvent.startDateGmt);
      endDateTime = AppDateTime().getDeviceTimeFromUtcTime(lastEvent.startDateGmt);
    } else {
      startDateTime = AppDateTime().getUniLocalTimeFromUtcTime(firstEvent.startDateGmt);
      endDateTime = AppDateTime().getUniLocalTimeFromUtcTime(lastEvent.startDateGmt);
    }
    bool sameDay = ((startDateTime != null) && (endDateTime != null) && (startDateTime.year == endDateTime.year) &&
        (startDateTime.month == endDateTime.month) && (startDateTime.day == endDateTime.day));
    String startDateString = AppDateTime().getDisplayDay(dateTimeUtc: firstEvent.startDateGmt, allDay: firstEvent.allDay);
    if (sameDay) {
      return startDateString;
    }
    String endDateString = AppDateTime().getDisplayDay(dateTimeUtc: lastEvent.startDateGmt, allDay: lastEvent.allDay);
    return '$startDateString - $endDateString';
  }

  String get displayInterests {
    String interests = "";
    if(AppCollection.isCollectionNotEmpty(tags)) {
      tags.forEach((String tag){
          if(User().isTagged(tag, true)) {
            if (interests.isNotEmpty) {
              interests += ", ";
            }
            interests += tag;
          }
      });
    }
    return interests;
  }

  bool get isComposite {
    return isRecurring || isSuperEvent;
  }

  String _createRandomImageUrl() {
    //create sports random image when athletics
    if ((category == "Athletics" || category == "Recreation") &&
        (registrationLabel != null && registrationLabel.isNotEmpty))
      return Assets().randomStringFromListWithKey('images.random.sports.$registrationLabel') ?? '';

    return Assets().randomStringFromListWithKey('images.random.events.$category') ?? '';
  }
}

class Contact {
  String firstName;
  String lastName;
  String email;
  String phone;
  String organization;

  Contact({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.organization});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        phone: json['phone'],
        organization: json['organization']);
  }

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "phone": phone,
      "organization": organization
    };
  }
}


