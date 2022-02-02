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

import 'package:rokwire_plugin/model/explore.dart';

import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/utils/utils.dart';

//////////////////////////////
/// Event

class Event with Explore implements Favorite {
  String? id;
  String? title;
  String? subTitle;
  String? shortDescription;
  String? longDescription;
  String? imageURL;
  String? placeID;

  ExploreLocation? location;
  
  int? convergeScore;
  String? convergeUrl;

  String? sourceEventId;
  String? startDateString;
  String? endDateString;
  DateTime? startDateGmt;
  DateTime? endDateGmt;
  String? category;
  String? subCategory;
  String? sponsor;
  String? titleUrl;
  List<String>? targetAudience;
  String? icalUrl;
  String? outlookUrl;
  String? speaker;
  String? registrationLabel;
  String? registrationUrl;
  String? cost;
  List<Contact>? contacts;
  List<String>? tags;
  DateTime? modifiedDate;
  String? submissionResult;
  String? eventId;
  bool? allDay;
  bool? recurringFlag;
  int? recurrenceId;
  List<Event>? recurringEvents;

  bool? isSuperEvent;
  bool? displayOnlyWithSuperEvent;
  bool? isVirtual;
  List<Map<String, dynamic>>? subEventsMap;
  String? track;
  List<Event>? _subEvents;
  List<Event>? _featuredEvents;

  String? randomImageURL;

  String? createdByGroupId;
  bool? isGroupPrivate;

  bool? isEventFree;

  static const String dateTimeFormat = 'E, dd MMM yyyy HH:mm:ss v';
  static const String serverRequestDateTimeFormat =  'yyyy/MM/ddTHH:mm:ss';


  Event({Map<String, dynamic>? json, Event? other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    dynamic targetAudienceJson = json['targetAudience'];
    List<String>? targetAudience = targetAudienceJson != null ? List.from(targetAudienceJson) : null;
    
    dynamic tagsJson = json['tags'];
    List<String>? tags = tagsJson != null ? List.from(tagsJson) : null;
    
    List<Contact>? contacts = Contact.listFromJson(json['contacts']);
    
    List<Event>? recurringEvents = Event.listFromJson(json['recurringEvents']);

    List<dynamic>? subEventsJson = json['subEvents'];
    List<Map<String, dynamic>>? subEventsMap = _constructSubEventsMap(subEventsJson);

    id = json["id"];
    title = json['title'];
    subTitle = json['subTitle'];
    shortDescription = json['shortDescription'];
    longDescription = json.containsKey("description") ? json["description"] : json['longDescription']; /*Back compatibility keep until we use longDescription */
    imageURL = json['imageURL'];
    placeID = json['placeID'];
    location = ExploreLocation.fromJSON(json['location']);
    eventId = json['eventId'];
    startDateString = json['startDate'];
    endDateString = json['endDate'];
    startDateGmt = DateTimeUtils.dateTimeFromString(json['startDate'], format: dateTimeFormat, isUtc: true);
    endDateGmt = DateTimeUtils.dateTimeFromString(json['endDate'], format: dateTimeFormat, isUtc: true);
    category = json['category'];
    subCategory = json['subCategory'];
    sponsor = json['sponsor'];
    titleUrl = json['titleURL'];
    this.targetAudience = targetAudience;
    icalUrl = json['icalUrl'];
    outlookUrl = json['outlookUrl'];
    speaker = json['speaker'];
    registrationLabel = json['registrationLabel'];
    if (StringUtils.isNotEmpty(json['registrationUrl'])) {
      registrationUrl = json['registrationUrl'];
    }
    else if (StringUtils.isNotEmpty(json['registrationURL'])) {
      registrationUrl = json['registrationURL'];
    }
    cost = json['cost'];
    this.contacts = contacts;
    this.tags = tags;
    modifiedDate = DateTimeUtils.dateTimeFromString(json['modifiedDate']);
    submissionResult = json['submissionResult'];
    allDay = json['allDay'] ?? false;
    recurringFlag = json['recurringFlag'] ?? false;
    recurrenceId = json['recurrenceId'];
    this.recurringEvents = recurringEvents;
    convergeScore = json['converge_score'];
    convergeUrl = json['converge_url'];
    isSuperEvent = json['isSuperEvent'] ?? false;
    displayOnlyWithSuperEvent = json['displayOnlyWithSuperEvent'] ?? false;
    this.subEventsMap = subEventsMap;
    track = json['track'];
    isVirtual = json['isVirtual'] ?? false;
    createdByGroupId = json["createdByGroupId"];
    isGroupPrivate = json["isGroupPrivate"] ?? false;
    isEventFree = json["isEventFree"] ?? false;
  }

  void _initFromOther(Event? other) {
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
    displayOnlyWithSuperEvent = other?.displayOnlyWithSuperEvent;
    subEventsMap = other?.subEventsMap;
    track = other?.track;
    isVirtual = other?.isVirtual;
    createdByGroupId = other?.createdByGroupId;
    isGroupPrivate = other?.isGroupPrivate;
    isEventFree = other?.isEventFree;
  }

  static Event? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Event(json: json) : null;
  }

  static Event? fromOther(Event? other) {
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
      "displayOnlyWithSuperEvent": displayOnlyWithSuperEvent,
      "subEvents": subEventsMap,
      "track": track,
      'isVirtual': isVirtual,
      'createdByGroupId': createdByGroupId,
      'isGroupPrivate': isGroupPrivate,
      'isEventFree': isEventFree,
    };
  }

  //add only not null values
  Map<String, dynamic> toNotNullJson(){
    Map<String, dynamic> result = {};
    if(id!=null) {
      result["id"]= id;
    }
    if(title!=null) {
      result["title"] = title;
    }
    if(subTitle!=null) {
      result["subTitle"] = subTitle;
    }
    if(shortDescription!=null) {
      result["shortDescription"] = shortDescription;
    }
    if(longDescription!=null) {
      result["longDescription"] = longDescription;
    }
    if(imageURL!=null) {
      result["imageURL"] = imageURL;
    }
    if(placeID!=null) {
      result["placeID"] = placeID;
    }
    if(location!=null) {
      Map<String, dynamic> locationJson = {};
      if(location!.locationId!=null) {
        locationJson["locationId"] = location!.locationId;
      }
      if(location!.name!=null) {
        locationJson["name"] = location!.name;
      }
      if(location!.building!=null) {
        locationJson["building"] = location!.building;
      }
      if(location!.address!=null) {
        locationJson["address"] = location!.address;
      }
      if(location!.city!=null) {
        locationJson[ "city"] = location!.city;
      }
      if(location!.state!=null){
      locationJson["state"]= location!.state;
      }
      if(location!.zip!=null){
      locationJson[ "zip"]= location!.zip;
      }
      if(location!.latitude!=null){
      locationJson["latitude"]= location!.latitude;
      }
      if(location!.longitude!=null){
      locationJson["longitude"]= location!.longitude;
      }
      if(location!.floor!=null){
      locationJson["floor"]= location!.floor;
      }
      if(location!.description!=null){
      locationJson["description"]= location!.description;
      }

      result["location"] = locationJson;
    }

    if(eventId!=null) {
      result["eventId"] = eventId;
    }
    if(startDateString!=null) {
      result["startDate"] = startDateString;
    }
    if(startDateLocal!=null) {
      result["startDateLocal"] = AppDateTime().formatDateTime(
          startDateLocal, format: AppDateTime.iso8601DateTimeFormat,
          ignoreTimeZone: true);
    }
    if(endDateString!=null) {
      result["endDate"] = endDateString;
    }
    if(endDateLocal!=null) {
      result["endDateLocal"] = AppDateTime().formatDateTime(
          endDateLocal, format: AppDateTime.iso8601DateTimeFormat,
          ignoreTimeZone: true);
    }
    if(category!=null) {
      result["category"] = category;
    }
    if(subCategory!=null) {
      result["subCategory"] = subCategory;
    }
    if(sponsor!=null) {
      result["sponsor"] = sponsor;
    }
    // Required for CreateEvent
    if(titleUrl!=null) {
      result["titleURL"]= titleUrl;
    }
    if(targetAudience!=null) {
      result["targetAudience"] = targetAudience;
    }
    if(icalUrl!=null) {
      result["icalUrl"] = icalUrl;
    }
    if(outlookUrl!=null) {
      result["outlookUrl"] = outlookUrl;
    }
    if(speaker!=null) {
      result["speaker"] = speaker;
    }
    if(registrationLabel!=null) {
      result["registrationLabel"] = registrationLabel;
    }
    if(registrationUrl!=null) {
      result["registrationUrl"] = registrationUrl;
    }
    if(cost!=null) {
      result["cost"] = cost;
    }
    if(contacts!=null && contacts!.isNotEmpty) {
      result["contacts"] = _encodeContacts();
    }
    if(tags!=null) {
      result["tags"] = tags;
    }
    if(modifiedDate!=null) {
      result["modifiedDate"] = AppDateTime().formatDateTime(modifiedDate, ignoreTimeZone: true);
    }
    if(submissionResult!=null) {
      result["submissionResult"] = submissionResult;
    }
    if(allDay!=null) {
      result["allDay"] = allDay;
    }
    if(recurringFlag!=null) {
      result["recurringFlag"] = recurringFlag;
    }
    if(recurrenceId!=null) {
      result["recurrenceId"] = recurrenceId;
    }
    if(isRecurring && CollectionUtils.isNotEmpty(recurringEvents)) {
      result["recurringEvents"] = _encodeRecurringEvents();
    }
    if(convergeScore!=null) {
      result["converge_score"] = convergeScore;
    }
    if(convergeUrl!=null) {
      result["converge_url"] = convergeUrl;
    }
    if(isSuperEvent!=null) {
      result["isSuperEvent"] = isSuperEvent;
    }
    if(displayOnlyWithSuperEvent!=null) {
      result["displayOnlyWithSuperEvent"] = displayOnlyWithSuperEvent;
    }
    if(subEventsMap!=null) {
      result["subEvents"] = subEventsMap;
    }
    if(track!=null) {
      result["track"] = track;
    }
    if(isVirtual!=null) {
      result['isVirtual']= isVirtual;
    }
    if(createdByGroupId!=null) {
      result['createdByGroupId']= createdByGroupId;
    }
    if(isGroupPrivate!=null) {
      result['isGroupPrivate']= isGroupPrivate;
    }
    if(isEventFree!=null) {
      result['isEventFree']= isEventFree;
    }

    return result;
  }

  static bool canJson(Map<String, dynamic>? json) {
    return (json != null) && (json['eventId'] != null);
  }

  static List<Event>? listFromJson(List<dynamic>? jsonList) {
    List<Event>? result;
    if (jsonList != null) {
      result = <Event>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Event.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Event>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  List<dynamic> _encodeContacts(){
    List<dynamic> result = [];
    if(contacts!=null && contacts!.isNotEmpty) {
      for (var contact in contacts!) {
        result.add(contact.toJson());
      }
    }

    return result;
  }

  List<dynamic>? _encodeRecurringEvents() {
    if (!isRecurring) {
      return null;
    }
    List<dynamic> eventsList = [];
    for (var event in recurringEvents!) {
      eventsList.add(event.toJson());
    }
    return eventsList;
  }

  @override
  String toString() {
    return toJson().toString();
  }

  @override
  int compareTo(Explore other) {
    int result = (other is Event) ? SortUtils.compare(convergeScore, other.convergeScore, descending: true) : 0; //Descending order by score
    return (result != 0) ? result : super.compareTo(other);
  }

  bool get isGameEvent {
    bool isAthletics = (category == "Athletics" || category == "Recreation");
    bool hasGameId = StringUtils.isNotEmpty(speaker);
    bool hasRegistrationFlag = StringUtils.isNotEmpty(registrationLabel);
    return isAthletics && hasGameId && hasRegistrationFlag;
  }

  bool get isRecurring {
    return (recurringFlag == true) && (recurringEvents?.isNotEmpty ?? false);
  }

  void addRecurrentEvent(Event event) {
    recurringEvents ??= [];
    recurringEvents!.add(event);
  }

  void sortRecurringEvents() {
    if (isRecurring) {
      recurringEvents!.sort((Event? first, Event? second) {
        DateTime? firstStartDate = first?.startDateGmt;
        DateTime? secondStartDate = second?.startDateGmt;
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

  List<Event>? get subEvents {
    return _subEvents;
  }

  void addSubEvent(Event event) {
    if (isSuperEvent != true) {
      return;
    }
    _subEvents ??= [];
    _subEvents!.add(event);
  }

  List<Event>? get featuredEvents {
    return _featuredEvents;
  }

  void addFeaturedEvent(Event event) {
    if (isSuperEvent != true) {
      return;
    }
    _featuredEvents ??= [];
    _featuredEvents!.add(event);
  }

  static List<Map<String, dynamic>>? _constructSubEventsMap(List<dynamic>? subEventsJson) {
    if (subEventsJson == null || subEventsJson.isEmpty) {
      return null;
    }
    List<Map<String, dynamic>> subEvents = [];
    for (dynamic eventDynamic in subEventsJson) {
      if (eventDynamic is Map<String, dynamic>) {
        subEvents.add(eventDynamic);
      }
    }
    return subEvents;
  }

  // Explore
  
  @override String?   get exploreId               { return id ?? eventId; }
  @override String?   get exploreTitle            { return title; }
  @override String?   get exploreSubTitle         { return subTitle; }
  @override String?   get exploreShortDescription { return shortDescription; }
  @override String?   get exploreLongDescription  { return longDescription; }
  @override DateTime? get exploreStartDateUtc     { return startDateGmt; }
  @override String?   get exploreImageURL         { return StringUtils.isNotEmpty(imageURL) ? imageURL : randomImageURL; }
  @override String?   get explorePlaceId          { return placeID; }
  @override ExploreLocation? get exploreLocation  { return location; }

  DateTime? get startDateLocal     { return AppDateTime().getUniLocalTimeFromUtcTime(startDateGmt); }
  DateTime? get endDateLocal       { return AppDateTime().getUniLocalTimeFromUtcTime(endDateGmt); }

  static String favoriteKeyName = "eventIds";
  @override String? get favoriteId => exploreId;
  @override String? get favoriteTitle => title;
  @override String get favoriteKey => favoriteKeyName;

  bool get isComposite {
    return isRecurring || (isSuperEvent == true);
  }
}

class Contact {
  String? firstName;
  String? lastName;
  String? email;
  String? phone;
  String? organization;

  Contact({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.organization});

  static Contact? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Contact(
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        phone: json['phone'],
        organization: json['organization']) : null;
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

  static List<Contact>? listFromJson(List<dynamic>? jsonList) {
    List<Contact>? result;
    if (jsonList != null) {
      result = <Contact>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Contact.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Contact>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

//////////////////////////////
/// EventCategory

class EventCategory {

  final String? name;
  final List<String>? subCategories;

  EventCategory({this.name, this.subCategories});

  static EventCategory? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? EventCategory(
      name: json['category'],
      subCategories: JsonUtils.listStringsValue(json['subcategories'])
    ) : null;
  }

  toJson(){
    return{
      'category': name,
      'subcategories': subCategories
    };
  }

  static List<EventCategory>? listFromJson(List<dynamic>? jsonList) {
    List<EventCategory>? result;
    if (jsonList is List) {
      result = <EventCategory>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, EventCategory.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

}

enum EventTimeFilter{today, thisWeekend, next7Day, next30Days, upcoming,}


