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

import 'package:flutter/material.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Location.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/DiningService.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/Styles.dart';



//////////////////////////////
/// Dining

class Dining with Explore implements Favorite {
  String id;
  String title;
  String subTitle;
  String diningType;
  String shortDescription;
  String longDescription;
  String imageURL;
  Map<String, dynamic> onlineOrder;
  String placeID;

  Location location;
  List<PaymentType> paymentTypes;
  List<DiningSchedule> diningSchedules;

  Dining(
      {this.id,
      this.title,
      this.subTitle,
      this.diningType,
      this.shortDescription,
      this.longDescription,
      this.imageURL,
      this.onlineOrder,
      this.placeID,
      this.location,
      this.paymentTypes,
      this.diningSchedules});

  factory Dining.fromJson(Map<String, dynamic> json) {
    String id = json['DiningOptionID'].toString();
    String addressInfo = json["Address"];
    List<DiningSchedule> diningSchedules = [];

    if(json['DiningSchedules'] != null) {
      List<dynamic> menuSchedules = json['DiningSchedules'];
      for (Map<String, dynamic> menuScheduleData in menuSchedules) {
        DiningSchedule schedule = DiningSchedule.fromJson(menuScheduleData);

        diningSchedules.add(schedule);
      }

      diningSchedules.sort((schedule1, schedule2){
        return schedule1.startTimeUtc.compareTo(schedule2.startTimeUtc);
      });
    }

    return Dining(
        id: id,
        title: json['DiningOptionName'],
        diningType: json['Type'],
        shortDescription: json['MoreInfo'],
        longDescription: json['MoreInfo'],
        imageURL: json['ImageUrl'],
        onlineOrder: json['OnLineOrder'],
        location: Location(
          description: addressInfo,
          latitude: json["Lat"],
          longitude: json["Long"],
        ),
        paymentTypes: PaymentTypeHelper.paymentTypesFromList(json['PaymentTypes']),
        diningSchedules: diningSchedules,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      // Explore
      'id': id,
      'title': title,
      'shortDescription': shortDescription,
      'longDescription': longDescription,
      'imageURL': imageURL,
      'placeID': placeID,
      'location': location?.toJson(),

      // Dining Location
      'DiningOptionID': id,
      'DiningOptionName': title,
      'subTitle': subTitle,
      'Type': diningType,
      'MoreInfo': shortDescription,
      'ImageUrl': imageURL,
      'OnLineOrder': onlineOrder,
      'Address': location.description,
      'Lat': location.latitude,
      'Long': location.longitude,
      'PaymentTypes': PaymentTypeHelper.paymentTypesToList(paymentTypes),
    };
  }

  static bool canJson(Map<String, dynamic> json) {
    return (json != null) && (json['DiningOptionID'] != null);
  }

  // Explore
  @override String   get exploreId               { return id; }
  @override String   get exploreTitle            { return title; }
  @override String   get exploreSubTitle         { return subTitle; }
  @override String   get exploreShortDescription { return shortDescription; }
  @override String   get exploreLongDescription  { return longDescription; }
  @override DateTime get exploreStartDateUtc     { return null; }
  @override String   get exploreImageURL         { return imageURL; }
  @override String   get explorePlaceId          { return null; }
  @override Location get exploreLocation         { return location; }
  @override Color    get uiColor                 { return Styles().colors.diningColor; }

  @override
  Map<String, dynamic> get analyticsAttributes {
    Map<String, dynamic> attributes = {
      Analytics.LogAttributeDiningId:   exploreId,
      Analytics.LogAttributeDiningName: exploreTitle,
    };
    attributes.addAll(analyticsSharedExploreAttributes ?? {});
    return attributes;
  }


  static String favoriteKeyName = "diningPlaceIds";
  @override String get favoriteId => exploreId;
  @override String get favoriteTitle => title;
  @override String get favoriteKey => favoriteKeyName;

  String get displayWorkTime {
    if(diningSchedules != null && diningSchedules.isNotEmpty) {
      bool useDeviceLocalTime = Storage().useDeviceLocalTimeZone;
      for(DiningSchedule schedule in diningSchedules){
        if((schedule.isOpen) && schedule.isToday){
          DateTime endDateTime = useDeviceLocalTime ? AppDateTime()
              .getDeviceTimeFromUtcTime(schedule.endTimeUtc) : schedule
              .endTimeUtc;
          String timeFormat = "h:mma";
          String formattedEndTime = AppDateTime().formatDateTime(
              endDateTime, format: timeFormat,
              ignoreTimeZone: useDeviceLocalTime,
              showTzSuffix: !useDeviceLocalTime);

          return Localization().getStringEx("model.dining.schedule.label.serving","Serving ")
              + schedule.meal.toLowerCase()
              + Localization().getStringEx("model.dining.schedule.label.until", " until ")
              + formattedEndTime;
        }
        else if(schedule.isFuture && schedule.isToday){
          DateTime startDateTime = useDeviceLocalTime ? AppDateTime()
              .getDeviceTimeFromUtcTime(schedule.startTimeUtc) : schedule
              .startTimeUtc;
          String timeFormat = "h:mma";
          String formattedStartTime = AppDateTime().formatDateTime(
              startDateTime, format: timeFormat,
              ignoreTimeZone: useDeviceLocalTime,
              showTzSuffix: !useDeviceLocalTime);

          return Localization().getStringEx("model.dining.schedule.label.serving","Serving ")
              + schedule.meal.toLowerCase()
              + Localization().getStringEx("model.dining.schedule.label.from", " from ")
              + formattedStartTime;
        }
        else if(schedule.isFuture && schedule.isNextTwoWeeks){
          DateTime startDateTime = useDeviceLocalTime ? AppDateTime()
              .getDeviceTimeFromUtcTime(schedule.startTimeUtc) : schedule
              .startTimeUtc;
          String timeFormat = 'MMM d h:mm a';
          String formattedStartTime = AppDateTime().formatDateTime(
              startDateTime, format: timeFormat,
              ignoreTimeZone: useDeviceLocalTime,
              showTzSuffix: !useDeviceLocalTime);

          return Localization().getStringEx("model.dining.schedule.label.open_on", "Opening on ")
              + formattedStartTime;
        }
      }
      return Localization().getStringEx("model.dining.schedule.label.closed_today","Closed today");
    }
    return Localization().getStringEx("model.dining.schedule.label.closed_for_two_weeks", "Closed for next 2 weeks");
  }

  bool get isWorkingToday {
    if(diningSchedules != null && diningSchedules.isNotEmpty){
      for(DiningSchedule schedule in diningSchedules){
        if((schedule.isOpen || schedule.isFuture) && schedule.isToday){
          return true;
        }
      }
    }
    return false;
  }

  bool  get isOpen {
    if(diningSchedules != null && diningSchedules.isNotEmpty){
      for(DiningSchedule schedule in diningSchedules){
        if(schedule.isOpen){
          return true;
        }
      }
    }
    return false;
  }

  bool get hasDiningSchedules {
    return (diningSchedules != null);
  }

  // Dinings support

  void mergeFromBackendJson(Map<String, dynamic> json){
    title = json["DiningOptionName"];

    if(json['DiningSchedules'] != null) {

      diningSchedules = [];

      List<dynamic> menuSchedules = json['DiningSchedules'];
      for (Map<String, dynamic> menuScheduleData in menuSchedules) {
        DiningSchedule schedule = DiningSchedule.fromJson(
            menuScheduleData);

        diningSchedules.add(schedule);
      }

      diningSchedules.sort((schedule1, schedule2){
        return schedule1.startTimeUtc.compareTo(schedule2.startTimeUtc);
      });
    }
  }

  List<String> get displayScheduleDates{
    Set<String> displayScheduleDates = Set<String>();
    if (diningSchedules != null) {
    for(DiningSchedule schedule in diningSchedules){
      displayScheduleDates.add(_dateToLongDisplayDate(schedule.eventDateUtc));
    }
    }
    return displayScheduleDates.toList();
  }

  List<DateTime> get filterScheduleDates{
    Set<DateTime> filterScheduleDates = Set<DateTime>();
    if (diningSchedules != null) {
    for(DiningSchedule schedule in diningSchedules){
      filterScheduleDates.add(schedule.eventDateUtc);
    }
    }

    return filterScheduleDates.toList();
  }

  Map<String,List<DiningSchedule>> get displayDateScheduleMapping{
    Map<String,List<DiningSchedule>> displayDateScheduleMapping = Map<String,List<DiningSchedule>>();

    if (diningSchedules != null) {
      for(DiningSchedule schedule in diningSchedules){
        String displayDate = _dateToLongDisplayDate(schedule.eventDateUtc);
        if(!displayDateScheduleMapping.containsKey(displayDate)){
          displayDateScheduleMapping[displayDate] = [];
        }

        displayDateScheduleMapping[displayDate].add(schedule);
      }
    }

    return displayDateScheduleMapping;
  }

  List<DiningSchedule> get firstOpeningDateSchedules{
    List<DiningSchedule> firstOpeningDateSchedules = [];
    List<String> displayDates = displayScheduleDates;

    if(displayDates != null && displayDates.isNotEmpty){
      for(String displayDate in displayDates){

        if(firstOpeningDateSchedules.isNotEmpty){
          break;
        }

        List<DiningSchedule> schedules = displayDateScheduleMapping[displayDate];
        if(schedules != null && schedules.isNotEmpty){
          for(DiningSchedule schedule in schedules){
            if(schedule.isOpen || (schedule.isFuture && schedule.isNextTwoWeeks)) {
              firstOpeningDateSchedules.add(schedule);
            }
          }
        }
      }
    }

    return firstOpeningDateSchedules;
  }

  String _dateToLongDisplayDate(DateTime dateUtc) {
    return AppDateTime().formatDateTime(dateUtc, format: 'EEEE, MMM d');
  }
}

//////////////////////////////
/// PaymentType

enum PaymentType { ClassicMeal, DiningDollars, IlliniCash, CreditCard, Cash, GooglePay, ApplePay  }

class PaymentTypeHelper {
  static String paymentTypeToString(PaymentType paymentType) {
    switch(paymentType) {
      case PaymentType.ClassicMeal: return 'ClassicMeal';
      case PaymentType.DiningDollars: return 'Dining Dollars';
      case PaymentType.IlliniCash:  return 'IlliniCash';
      case PaymentType.CreditCard:  return 'CreditCard';
      case PaymentType.Cash:        return 'Cash';
      case PaymentType.GooglePay:   return 'GooglePay';
      case PaymentType.ApplePay:    return 'ApplePay';
      default:                      return null;
    }
  }

  static PaymentType paymentTypeFromString(String paymentTypeString) {
    if (paymentTypeString != null) {
      if (paymentTypeString == 'ClassicMeal') {
        return PaymentType.ClassicMeal;
      }
      else if (paymentTypeString == 'Dining Dollars') {
        return PaymentType.DiningDollars;
      }
      else if (paymentTypeString == 'IlliniCash') {
        return PaymentType.IlliniCash;
      }
      else if (paymentTypeString == 'CreditCard') {
        return PaymentType.CreditCard;
      }
      else if (paymentTypeString == 'Cash') {
        return PaymentType.Cash;
      }
      else if (paymentTypeString == 'GooglePay') {
        return PaymentType.GooglePay;
      }
      else if (paymentTypeString == 'ApplePay') {
        return PaymentType.ApplePay;
      }
    }
    return null;
  }
  

  static String paymentTypeToDisplayString(PaymentType paymentType) {
    if (paymentType != null) {
      switch (paymentType) {
        case PaymentType.ClassicMeal:
          return Localization().getStringEx('payment_type.text.classic_meal', 'Classic Meal');
        case PaymentType.DiningDollars:
          return Localization().getStringEx('payment_type.text.dining_dollars', 'Dining Dollars');
       case PaymentType.IlliniCash:
          return Localization().getStringEx('payment_type.text.illini_cash', 'Illini Cash');
        case PaymentType.CreditCard:
          return Localization().getStringEx('payment_type.text.credit_card', 'Credit Card');
       case PaymentType.Cash:
          return Localization().getStringEx('payment_type.text.cash', 'Cash');
        case PaymentType.GooglePay:
          return Localization().getStringEx('payment_type.text.google_pay', 'Google Pay');
        case PaymentType.ApplePay:
          return Localization().getStringEx('payment_type.text.apple_pay', 'Apple Pay');
      }
    }
    return '';
  }

  static String paymentTypeToImageAsset(PaymentType paymentType) {
    if (paymentType == null) {
      return null;
    }
    switch (paymentType) {
      case PaymentType.ClassicMeal:
        return 'images/icon-payment-type-classic-meal.png';
      case PaymentType.DiningDollars:
        return 'images/icon-payment-type-dining-dollars.png';
      case PaymentType.IlliniCash:
        return 'images/icon-payment-type-ilini-cash.png';
      case PaymentType.CreditCard:
        return 'images/icon-payment-type-credit-card.png';
      case PaymentType.Cash:
        return 'images/icon-payment-type-cache.png';
      case PaymentType.GooglePay:
        return 'images/icon-payment-type-google-pay.png';
      case PaymentType.ApplePay:
        return 'images/icon-payment-type-apple-pay.png';
      default:
        return null;
    }
  }

  static Image paymentTypeIcon(PaymentType paymentType) {
    return (paymentType != null) ? Image.asset(paymentTypeToImageAsset(paymentType), semanticLabel: paymentTypeToDisplayString(paymentType)) : null;
  }

  static List<PaymentType> paymentTypesFromList(List<dynamic> paymentTypesList) {
    if (paymentTypesList == null) {
      return null;
    }
    else {
      List<PaymentType> paymentTypes = [];
      for (String paymentType in paymentTypesList) {
        paymentTypes.add(PaymentTypeHelper.paymentTypeFromString(paymentType));
      }
      return paymentTypes;
    }
  }

  static List<dynamic> paymentTypesToList(List<PaymentType> paymentTypes) {
    if (paymentTypes == null) {
      return null;
    }
    else {
      List<String> paymentTypesList = [];
      for (PaymentType paymentType in paymentTypes) {
        paymentTypesList.add(PaymentTypeHelper.paymentTypeToString(paymentType));
      }
      return paymentTypesList;
    }
  }
}

//////////////////////////////
/// DiningNutritionItem

class DiningNutritionItem {
  String itemID;
  String name;
  String serving;
  List<NutritionNameValuePair> nutritionList;


  DiningNutritionItem({this.itemID, this.name, this.serving, this.nutritionList});

  factory DiningNutritionItem.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return null;
    }
    List<NutritionNameValuePair> nutritionsList = [];
    if(json.containsKey("NutritionList")) {
      for (Map<String, dynamic> nutritionEntry in json["NutritionList"]) {
        nutritionsList.add(NutritionNameValuePair.fromJson(nutritionEntry));
      }
    }

    return DiningNutritionItem(
      itemID: json['ItemID'].toString(),
      name: json['FormalName'],
      serving: json['Serving'],
      nutritionList: nutritionsList,
    );
  }
}

//////////////////////////////
/// NutritionNameValuePair

class NutritionNameValuePair{
  String name;
  String value;

  NutritionNameValuePair({this.name, this.value});

  factory NutritionNameValuePair.fromJson(Map<String,dynamic>json){
    String name = json["Name"];
    String value = json["Value"];

    name = Localization().getStringEx("com.illinois.nutrition_type.entry.$name", name);

    return NutritionNameValuePair(
      name: name,
      value: value,
    );
  }
}

//////////////////////////////
/// DiningProductItem

class DiningProductItem {
  String itemID;
  String scheduleId;
  String name;
  String servingUnit;
  String course;
  String traits;
  String category;
  int courseSort;
  String meal;

  List<String> get traitList{
    List<String> traitList = [];
    for (String entry in (traits ?? "").split(',')) {
      entry = entry.trim();
      if(entry != null && entry.isNotEmpty) {
        traitList.add(entry);
      }
    }
    return traitList;
  }

  List<String> get ingredients{
    List<String> foodTypes = DiningService().foodTypes;
    return traitList.where((entry)=>!foodTypes.contains(entry)).toList();
  }

  List<String> get dietaryPreferences{
    List<String> foodTypes = DiningService().foodTypes;
    return traitList.where((entry)=>foodTypes.contains(entry)).toList();
  }


  DiningProductItem({this.itemID, this.name, this.scheduleId, this.servingUnit, this.course, this.traits, this.category, this.courseSort, this.meal});

  bool containsFoodType(List<String> foodTypePrefs){
    if ((foodTypePrefs == null) || foodTypePrefs.isEmpty) {
      return false;
    }
    else if ((traits != null) && traits.isNotEmpty){

      // Reversed logic. Use case:
      // Selected Halal & Kosher -> Show only if the product is marked both as Kosher & Halal -> (not either!)
      String lowerCaseTraits = traits.toLowerCase();
      for (String foodTypePref in foodTypePrefs){
        if (!lowerCaseTraits.contains(foodTypePref.toLowerCase())) {
          return false;
        }
      }
      return true;
    }

    return false;
  }

  bool containsFoodIngredient(List<String> foodIngredientPrefs){
    if ((foodIngredientPrefs == null) || foodIngredientPrefs.isEmpty) {
      return false;
    }
    else if ((traits != null) && traits.isNotEmpty) {
      String smallTraits = traits.toLowerCase();
      for (String foodIngredientPref in foodIngredientPrefs) {
        if (smallTraits.contains(foodIngredientPref.toLowerCase())){
          return true;
        }
      }
    }

    return false;
  }

  factory DiningProductItem.fromJson(Map<String, dynamic> json) {
    return DiningProductItem(
      itemID: json['ItemID'].toString(),
      scheduleId: json['ScheduleID'].toString(),
      name: json['FormalName'],
      servingUnit: json['ServingUnit'],
      traits: json['Traits'],
      category: json['Category'],
      course: json['Course'],
      courseSort: json['CourseSort'],
      meal: json['Meal'],
    );
  }
}

//////////////////////////////
/// DiningSchedule

class DiningSchedule {
  String scheduleId;
  String diningLocationId;
  DateTime eventDateUtc;
  DateTime startTimeUtc;
  DateTime endTimeUtc;
  String meal;

  DiningSchedule({this.scheduleId, this.diningLocationId, this.eventDateUtc, this.startTimeUtc, this.endTimeUtc, this.meal,});

  factory DiningSchedule.fromJson(Map<String, dynamic> json) {
    int timestampInSeconds = json['EventDateUTC'];
    int startTimeStampInSeconds = json['StartTimeUTC'];
    int endTimeStampInSeconds = json['EndTimeUTC'];

    return DiningSchedule(
      scheduleId:       json['ScheduleID']?.toString(),
      diningLocationId: json['DiningOptionID']?.toString(),
      eventDateUtc:     (timestampInSeconds != null)      ? DateTime.fromMillisecondsSinceEpoch(timestampInSeconds * 1000, isUtc: true) : null,
      startTimeUtc:     (startTimeStampInSeconds != null) ? DateTime.fromMillisecondsSinceEpoch(startTimeStampInSeconds * 1000, isUtc: true) : null,
      endTimeUtc:       (endTimeStampInSeconds != null)   ? DateTime.fromMillisecondsSinceEpoch(endTimeStampInSeconds * 1000, isUtc: true) : null,
      meal:             json['TimePeriod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ScheduleID':     (scheduleId != null) ? int.tryParse(scheduleId) : null,
      'DiningOptionID': (diningLocationId != null) ? int.tryParse(diningLocationId) : null,
      'EventDateUTC':   (eventDateUtc != null) ? eventDateUtc.millisecondsSinceEpoch : null,
      'StartTimeUTC':   (startTimeUtc != null) ? startTimeUtc.millisecondsSinceEpoch : null,
      'EndTimeUTC':     (endTimeUtc != null)   ? endTimeUtc.millisecondsSinceEpoch   : null,
      'TimePeriod':     meal,
    };
  }

  bool get isOpen {
    if (startTimeUtc != null && endTimeUtc != null) {
      DateTime nowUtc = DateTime.now().toUtc();
      return nowUtc.isAfter(startTimeUtc) && nowUtc.isBefore(endTimeUtc);
    }
    return false;
  }

  bool get isFuture {
    if (startTimeUtc != null && endTimeUtc != null) {
      DateTime nowUtc = DateTime.now().toUtc();
      return nowUtc.isBefore(startTimeUtc) && nowUtc.isBefore(endTimeUtc);
    }
    return false;
  }

  bool get isPast {
    if (startTimeUtc != null && endTimeUtc != null) {
      DateTime nowUtc = DateTime.now().toUtc();
      return nowUtc.isAfter(startTimeUtc) && nowUtc.isAfter(endTimeUtc);
    }
    return false;
  }

  bool get isToday {
    if (eventDateUtc != null && eventDateUtc != null) {
      DateTime nowUniTime = AppDateTime().getUniLocalTimeFromUtcTime(DateTime.now().toUtc());
      DateTime scheduleUniTime = AppDateTime().getUniLocalTimeFromUtcTime(eventDateUtc.toUtc());
      return nowUniTime.year == scheduleUniTime.year &&
          nowUniTime.month == scheduleUniTime.month && nowUniTime.day == scheduleUniTime.day;
    }
    return false;
  }

  bool get isNextTwoWeeks{
    // two weeks + 1 day in order to ensure and cover the whole 14th day roughly
    int twoWeeksDeltaInSeconds = 15 * 24 * 60 * 60;
    DateTime utcNow = DateTime.now().toUtc();
    int secondsStartDelta = startTimeUtc.difference(utcNow).inSeconds;
    int secondsEndDelta = endTimeUtc.difference(utcNow).inSeconds;
    return (secondsStartDelta >= 0 && secondsStartDelta < twoWeeksDeltaInSeconds)
        || (secondsEndDelta >= 0 && secondsEndDelta < twoWeeksDeltaInSeconds);
  }

  String get displayWorkTime {
      return getDisplayTime(' - ');
  }

  String getDisplayTime(String separator){
    if(startTimeUtc != null && endTimeUtc != null) {
      String timeFormat = 'h:mm a';
      bool useDeviceLocalTime = Storage().useDeviceLocalTimeZone;
      DateTime startDateTime;
      DateTime endDateTime;
      if(useDeviceLocalTime) {
        startDateTime = AppDateTime().getDeviceTimeFromUtcTime(startTimeUtc);
        endDateTime = AppDateTime().getDeviceTimeFromUtcTime(endTimeUtc);
      } else {
        startDateTime = startTimeUtc;
        endDateTime = endTimeUtc;
      }
      return AppDateTime().formatDateTime(startDateTime, format: timeFormat, ignoreTimeZone: useDeviceLocalTime, showTzSuffix: !useDeviceLocalTime) +
          separator +
          AppDateTime().formatDateTime(endDateTime, format: timeFormat, ignoreTimeZone: useDeviceLocalTime, showTzSuffix: !useDeviceLocalTime);
    }
    return "";
  }

  static List<DiningSchedule> listFromJson(dynamic json) {
    List<DiningSchedule> diningSchedules;
    if (json is List) {
      diningSchedules = [];
      for (dynamic jsonEntry in json) {
        if (jsonEntry is Map) {
          DiningSchedule diningSchedule = DiningSchedule.fromJson(jsonEntry);
          if (diningSchedule != null) {
            diningSchedules.add(diningSchedule);
          }
        }
      }
    }
    return diningSchedules;
  }

  static List<dynamic> listToJson(List<DiningSchedule> diningSchedules) {
    List<dynamic> jsonList;
    if (diningSchedules != null) {
      jsonList = [];
      for (DiningSchedule diningSchedule in diningSchedules) {
        Map<String, dynamic> jsonEntry = diningSchedule.toJson();
        if (jsonEntry != null) {
          jsonList.add(jsonEntry);
        }
      }
    }
    return jsonList;
  }
}

//////////////////////////////
/// DiningSpecial

class DiningSpecial {
  String id;
  String title;
  String text;
  String startDateString;
  String endDateString;
  String imageUrl;
  Set<int> locationIds;

  bool get hasLocationIds{
    return locationIds != null && locationIds.isNotEmpty;
  }

  DiningSpecial({this.id, this.title, this.text, this.startDateString, this.endDateString, this.imageUrl, this.locationIds});

  factory DiningSpecial.fromJson(Map<String, dynamic>json){
    List<dynamic> _locationIds = json['DiningOptionIDs'];
    List<String> _castedIds = _locationIds != null ? _locationIds.map((entry)=>entry.toString()).toList() : null;
    return DiningSpecial(
      id: (json['OfferID'] ?? "").toString(),
      title: json['Title'],
      text: json['OfferText'],
      startDateString: json['StartDate'],
      endDateString: json['EndDate'],
      imageUrl: json['ImageUrl'],
      locationIds: _castedIds != null ? _castedIds.toSet().cast() : null
    );
  }

  toJson(){
    return {
      "OfferID": id,
      "Title": title,
      "OfferText": text,
      "StartDate": startDateString,
      "EndDate": endDateString,
      "ImageUrl": imageUrl,
      "DiningOptionIDs": locationIds != null ? locationIds.toList() : [],
    };
  }
}