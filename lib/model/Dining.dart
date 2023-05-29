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

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';



//////////////////////////////
/// Dining

class Dining with Explore implements Favorite {
  String? id;
  String? title;
  String? diningType;
  String? description;
  String? imageURL;
  Map<String, dynamic>? onlineOrder;

  ExploreLocation? location;
  List<PaymentType>? paymentTypes;
  List<DiningSchedule>? diningSchedules;

  Dining(
      {this.id,
      this.title,
      this.diningType,
      this.description,
      this.imageURL,
      this.onlineOrder,
      this.location,
      this.paymentTypes,
      this.diningSchedules});

  static Dining? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    String id = json['DiningOptionID'].toString();
    String? addressInfo = json["Address"];
    List<DiningSchedule> diningSchedules = <DiningSchedule>[];

    if(json['DiningSchedules'] != null) {
      List<dynamic> menuSchedules = json['DiningSchedules'];
      for (Map<String, dynamic> menuScheduleData in menuSchedules) {
        DiningSchedule? schedule = DiningSchedule.fromJson(menuScheduleData);
        if (schedule != null) {
          diningSchedules.add(schedule);
        }
      }

      diningSchedules.sort((schedule1, schedule2){
        return schedule1.startTimeUtc!.compareTo(schedule2.startTimeUtc!);
      });
    }

    return Dining(
        id: id,
        title: json['DiningOptionName'],
        diningType: json['Type'],
        description: json['MoreInfo'],
        imageURL: json['ImageUrl'],
        onlineOrder: json['OnLineOrder'],
        location: ExploreLocation(
          description: addressInfo,
          latitude: json["Lat"],
          longitude: json["Long"],
        ),
        paymentTypes: PaymentTypeHelper.paymentTypesFromList(json['PaymentTypes']),
        diningSchedules: diningSchedules,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Explore
      'location': location?.toJson(),

      // Dining Location
      'DiningOptionID': id,
      'DiningOptionName': title,
      'Type': diningType,
      'MoreInfo': description,
      'ImageUrl': imageURL,
      'OnLineOrder': onlineOrder,
      'Address': location!.description,
      'Lat': location!.latitude,
      'Long': location!.longitude,
      'PaymentTypes': PaymentTypeHelper.paymentTypesToList(paymentTypes),
    };
  }

  @override
  bool operator ==(other) =>
    (other is Dining) &&
      (other.id == id) &&
      (other.title == title) &&
      (other.diningType == diningType) &&
      (other.description == description) &&
      (other.imageURL == imageURL) &&
      (DeepCollectionEquality().equals(other.onlineOrder, onlineOrder)) &&
      (other.location == location) &&
      (DeepCollectionEquality().equals(other.paymentTypes, paymentTypes)) &&
      (DeepCollectionEquality().equals(other.diningSchedules, diningSchedules));

  @override
  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (title?.hashCode ?? 0) ^
      (diningType?.hashCode ?? 0) ^
      (description?.hashCode ?? 0) ^
      (imageURL?.hashCode ?? 0) ^
      (DeepCollectionEquality().hash(onlineOrder)) ^
      (location?.hashCode ?? 0) ^
      (DeepCollectionEquality().hash(paymentTypes)) ^
      (DeepCollectionEquality().hash(diningSchedules));

  // Explore
  @override String?   get exploreId               { return id; }
  @override String?   get exploreTitle            { return title; }
  @override String?   get exploreDescription      { return description; }
  @override DateTime? get exploreDateTimeUtc      { return null; }
  @override String?   get exploreImageURL         { return imageURL; }
  @override ExploreLocation? get exploreLocation  { return location; }

  // Favorite
  static const String favoriteKeyName = "diningPlaceIds";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => id;

  String? get displayWorkTime {
    if(diningSchedules != null && diningSchedules!.isNotEmpty) {
      bool? useDeviceLocalTime = Storage().useDeviceLocalTimeZone;
      for(DiningSchedule schedule in diningSchedules!){
        if((schedule.isOpen) && schedule.isToday){
          DateTime? endDateTime = useDeviceLocalTime! ? AppDateTime()
              .getDeviceTimeFromUtcTime(schedule.endTimeUtc) : schedule
              .endTimeUtc;
          String timeFormat = "h:mma";
          String formattedEndTime = AppDateTime().formatDateTime(
              endDateTime, format: timeFormat,
              ignoreTimeZone: useDeviceLocalTime,
              showTzSuffix: !useDeviceLocalTime)!;

          return Localization().getStringEx("model.dining.schedule.label.serving","Serving ")
              + schedule.meal!.toLowerCase()
              + Localization().getStringEx("model.dining.schedule.label.until", " until ")
              + formattedEndTime;
        }
        else if(schedule.isFuture && schedule.isToday){
          DateTime? startDateTime = useDeviceLocalTime! ? AppDateTime()
              .getDeviceTimeFromUtcTime(schedule.startTimeUtc) : schedule
              .startTimeUtc;
          String timeFormat = "h:mma";
          String formattedStartTime = AppDateTime().formatDateTime(
              startDateTime, format: timeFormat,
              ignoreTimeZone: useDeviceLocalTime,
              showTzSuffix: !useDeviceLocalTime)!;

          return Localization().getStringEx("model.dining.schedule.label.serving","Serving ")
              + schedule.meal!.toLowerCase()
              + Localization().getStringEx("model.dining.schedule.label.from", " from ")
              + formattedStartTime;
        }
        else if(schedule.isFuture && schedule.isNextTwoWeeks){
          DateTime? startDateTime = useDeviceLocalTime! ? AppDateTime()
              .getDeviceTimeFromUtcTime(schedule.startTimeUtc) : schedule
              .startTimeUtc;
          String timeFormat = 'MMM d h:mm a';
          String formattedStartTime = AppDateTime().formatDateTime(
              startDateTime, format: timeFormat,
              ignoreTimeZone: useDeviceLocalTime,
              showTzSuffix: !useDeviceLocalTime)!;

          return Localization().getStringEx("model.dining.schedule.label.open_on", "Opening on ")
              + formattedStartTime;
        }
      }
      return Localization().getStringEx("model.dining.schedule.label.closed_today","Closed today");
    }
    return Localization().getStringEx("model.dining.schedule.label.closed_for_two_weeks", "Closed for next 2 weeks");
  }

  bool get isWorkingToday {
    if(diningSchedules != null && diningSchedules!.isNotEmpty){
      for(DiningSchedule schedule in diningSchedules!){
        if((schedule.isOpen || schedule.isFuture) && schedule.isToday){
          return true;
        }
      }
    }
    return false;
  }

  bool  get isOpen {
    if(diningSchedules != null && diningSchedules!.isNotEmpty){
      for(DiningSchedule schedule in diningSchedules!){
        if(schedule.isOpen){
          return true;
        }
      }
    }
    return false;
  }

  bool get hasDiningSchedules {
    return CollectionUtils.isNotEmpty(diningSchedules);
  }

  // Dinings support

  void mergeFromBackendJson(Map<String, dynamic> json){
    title = json["DiningOptionName"];

    if(json['DiningSchedules'] != null) {

      diningSchedules = <DiningSchedule>[];

      List<dynamic> menuSchedules = json['DiningSchedules'];
      for (Map<String, dynamic> menuScheduleData in menuSchedules) {
        DiningSchedule? schedule = DiningSchedule.fromJson(menuScheduleData);
        if (schedule != null) {
          diningSchedules!.add(schedule);
        }
      }

      diningSchedules!.sort((schedule1, schedule2){
        return schedule1.startTimeUtc!.compareTo(schedule2.startTimeUtc!);
      });
    }
  }

  List<String> get displayScheduleDates{
    Set<String> displayScheduleDates = Set<String>();
    if (diningSchedules != null) {
      for(DiningSchedule schedule in diningSchedules!){
        String? displayDate = _dateToLongDisplayDate(schedule.eventDateUtc);
        if (displayDate != null) {
          displayScheduleDates.add(displayDate);
        }
      }
    }
    return displayScheduleDates.toList();
  }

  List<DateTime> get filterScheduleDates{
    Set<DateTime> filterScheduleDates = Set<DateTime>();
    if (diningSchedules != null) {
      for(DiningSchedule schedule in diningSchedules!){
        if (schedule.eventDateUtc != null) {
          filterScheduleDates.add(schedule.eventDateUtc!);
        }
      }
    }

    return filterScheduleDates.toList();
  }

  Map<String,List<DiningSchedule>> get displayDateScheduleMapping{
    Map<String,List<DiningSchedule>> displayDateScheduleMapping = Map<String,List<DiningSchedule>>();

    if (diningSchedules != null) {
      for(DiningSchedule schedule in diningSchedules!){
        String? displayDate = _dateToLongDisplayDate(schedule.eventDateUtc);
        if((displayDate != null) && !displayDateScheduleMapping.containsKey(displayDate)){
          displayDateScheduleMapping[displayDate] = <DiningSchedule>[];
        }

        displayDateScheduleMapping[displayDate]!.add(schedule);
      }
    }

    return displayDateScheduleMapping;
  }

  List<DiningSchedule> get firstOpeningDateSchedules{
    List<DiningSchedule> firstOpeningDateSchedules = <DiningSchedule>[];
    List<String> displayDates = displayScheduleDates;

    if(displayDates.isNotEmpty){
      for(String? displayDate in displayDates){

        if(firstOpeningDateSchedules.isNotEmpty){
          break;
        }

        List<DiningSchedule>? schedules = displayDateScheduleMapping[displayDate];
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

  String? _dateToLongDisplayDate(DateTime? dateUtc) {
    return AppDateTime().formatDateTime(dateUtc, format: 'EEEE, MMM d');
  }

  static Dining? entryInList(List<Dining>? dinings, { String? id}) {
    if (dinings != null) {
      for (Dining dining in dinings) {
        if (dining.id == id) {
          return dining;
        }
      }
    }
    return null;
  }
}

//////////////////////////////
/// PaymentType

enum PaymentType { ClassicMeal, DiningDollars, IlliniCash, CreditCard, Cash, GooglePay, ApplePay  }

class PaymentTypeHelper {
  static String? paymentTypeToString(PaymentType? paymentType) {
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

  static PaymentType? paymentTypeFromString(String? paymentTypeString) {
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
  

  static String? paymentTypeToDisplayString(PaymentType? paymentType) {
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

  static String? paymentTypeToImageAsset(PaymentType? paymentType) {
    if (paymentType == null) {
      return null;
    }
    switch (paymentType) {
      case PaymentType.ClassicMeal:
        return 'payment-meal';
      case PaymentType.DiningDollars:
        return 'payment-dining';
      case PaymentType.IlliniCash:
        return 'payment-student-cash';
      case PaymentType.CreditCard:
        return 'payment-credit-card';
      case PaymentType.Cash:
        return 'payment-cash';
      case PaymentType.GooglePay:
        return 'payment-google-pay';
      case PaymentType.ApplePay:
        return 'payment-apple-pay';
      default:
        return null;
    }
  }

  static Widget? paymentTypeIcon(PaymentType? paymentType) {
    return (paymentType != null) ? Styles().images?.getImage(paymentTypeToImageAsset(paymentType)!, semanticLabel: paymentTypeToDisplayString(paymentType)) : null;
  }

  static List<PaymentType>? paymentTypesFromList(List<dynamic>? paymentTypesList) {
    if (paymentTypesList == null) {
      return null;
    }
    else {
      List<PaymentType> paymentTypes = <PaymentType>[];
      for (String paymentTypeString in paymentTypesList) {
        PaymentType? paymentType = PaymentTypeHelper.paymentTypeFromString(paymentTypeString);
        if (paymentType != null) {
          paymentTypes.add(paymentType);
        }
      }
      return paymentTypes;
    }
  }

  static List<dynamic>? paymentTypesToList(List<PaymentType>? paymentTypes) {
    if (paymentTypes == null) {
      return null;
    }
    else {
      List<String> paymentTypesList = <String>[];
      for (PaymentType paymentType in paymentTypes) {
        String? paymentTypeString = PaymentTypeHelper.paymentTypeToString(paymentType);
        if (paymentTypeString != null) {
          paymentTypesList.add(paymentTypeString);
        }
      }
      return paymentTypesList;
    }
  }
}

//////////////////////////////
/// DiningNutritionItem

class DiningNutritionItem {
  String? itemID;
  String? name;
  String? serving;
  List<NutritionNameValuePair>? nutritionList;


  DiningNutritionItem({this.itemID, this.name, this.serving, this.nutritionList});

  static DiningNutritionItem? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    List<NutritionNameValuePair> nutritionsList = <NutritionNameValuePair>[];
    if(json.containsKey("NutritionList")) {
      for (Map<String, dynamic> nutritionEntry in json["NutritionList"]) {
        NutritionNameValuePair? pair = NutritionNameValuePair.fromJson(nutritionEntry);
        if (pair != null) {
          nutritionsList.add(pair);
        }
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
  String? name;
  String? value;

  NutritionNameValuePair({this.name, this.value});

  static NutritionNameValuePair? fromJson(Map<String,dynamic>? json){
    if (json == null) {
      return null;
    }
    String? name = json["Name"];
    String? value = json["Value"];

    name = Localization().getString("com.illinois.nutrition_type.entry.$name", defaults: name);

    return NutritionNameValuePair(
      name: name,
      value: value,
    );
  }
}

//////////////////////////////
/// DiningProductItem

class DiningProductItem {
  String? itemID;
  String? scheduleId;
  String? name;
  String? servingUnit;
  String? course;
  String? traits;
  String? category;
  int? courseSort;
  String? meal;

  List<String> get traitList{
    List<String> traitList = <String>[];
    for (String entry in (traits ?? "").split(',')) {
      entry = entry.trim();
      if(entry.isNotEmpty) {
        traitList.add(entry);
      }
    }
    return traitList;
  }

  List<String> get ingredients{
    List<String>? foodTypes = Dinings().foodTypes;
    return traitList.where((entry)=>!foodTypes!.contains(entry)).toList();
  }

  List<String> get dietaryPreferences{
    List<String>? foodTypes = Dinings().foodTypes;
    return traitList.where((entry)=>foodTypes!.contains(entry)).toList();
  }


  DiningProductItem({this.itemID, this.name, this.scheduleId, this.servingUnit, this.course, this.traits, this.category, this.courseSort, this.meal});

  bool containsFoodType(Set<String>? foodTypePrefs){
    if ((foodTypePrefs == null) || foodTypePrefs.isEmpty) {
      return false;
    }
    else if ((traits != null) && traits!.isNotEmpty){

      // Reversed logic. Use case:
      // Selected Halal & Kosher -> Show only if the product is marked both as Kosher & Halal -> (not either!)
      String lowerCaseTraits = traits!.toLowerCase();
      for (String foodTypePref in foodTypePrefs){
        if (!lowerCaseTraits.contains(foodTypePref.toLowerCase())) {
          return false;
        }
      }
      return true;
    }

    return false;
  }

  bool containsFoodIngredient(Set<String>? foodIngredientPrefs){
    if ((foodIngredientPrefs == null) || foodIngredientPrefs.isEmpty) {
      return false;
    }
    else if ((traits != null) && traits!.isNotEmpty) {
      String smallTraits = traits!.toLowerCase();
      for (String foodIngredientPref in foodIngredientPrefs) {
        if (smallTraits.contains(foodIngredientPref.toLowerCase())){
          return true;
        }
      }
    }

    return false;
  }

  static DiningProductItem? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? DiningProductItem(
      itemID: json['ItemID'].toString(),
      scheduleId: json['ScheduleID'].toString(),
      name: json['FormalName'],
      servingUnit: json['ServingUnit'],
      traits: json['Traits'],
      category: json['Category'],
      course: json['Course'],
      courseSort: json['CourseSort'],
      meal: json['Meal'],
    ) : null;
  }
}

//////////////////////////////
/// DiningSchedule

class DiningSchedule {
  String? scheduleId;
  String? diningLocationId;
  DateTime? eventDateUtc;
  DateTime? startTimeUtc;
  DateTime? endTimeUtc;
  String? meal;

  DiningSchedule({this.scheduleId, this.diningLocationId, this.eventDateUtc, this.startTimeUtc, this.endTimeUtc, this.meal,});

  static DiningSchedule? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    int? timestampInSeconds = json['EventDateUTC'];
    int? startTimeStampInSeconds = json['StartTimeUTC'];
    int? endTimeStampInSeconds = json['EndTimeUTC'];

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
      'ScheduleID':     (scheduleId != null) ? int.tryParse(scheduleId!) : null,
      'DiningOptionID': (diningLocationId != null) ? int.tryParse(diningLocationId!) : null,
      'EventDateUTC':   (eventDateUtc != null) ? eventDateUtc!.millisecondsSinceEpoch : null,
      'StartTimeUTC':   (startTimeUtc != null) ? startTimeUtc!.millisecondsSinceEpoch : null,
      'EndTimeUTC':     (endTimeUtc != null)   ? endTimeUtc!.millisecondsSinceEpoch   : null,
      'TimePeriod':     meal,
    };
  }

  bool get isOpen {
    if (startTimeUtc != null && endTimeUtc != null) {
      DateTime nowUtc = DateTime.now().toUtc();
      return nowUtc.isAfter(startTimeUtc!) && nowUtc.isBefore(endTimeUtc!);
    }
    return false;
  }

  bool get isFuture {
    if (startTimeUtc != null && endTimeUtc != null) {
      DateTime nowUtc = DateTime.now().toUtc();
      return nowUtc.isBefore(startTimeUtc!) && nowUtc.isBefore(endTimeUtc!);
    }
    return false;
  }

  bool get isPast {
    if (startTimeUtc != null && endTimeUtc != null) {
      DateTime nowUtc = DateTime.now().toUtc();
      return nowUtc.isAfter(startTimeUtc!) && nowUtc.isAfter(endTimeUtc!);
    }
    return false;
  }

  bool get isToday {
    if (eventDateUtc != null && eventDateUtc != null) {
      DateTime nowUniTime = AppDateTime().getUniLocalTimeFromUtcTime(DateTime.now().toUtc())!;
      DateTime scheduleUniTime = AppDateTime().getUniLocalTimeFromUtcTime(eventDateUtc!.toUtc())!;
      return nowUniTime.year == scheduleUniTime.year &&
          nowUniTime.month == scheduleUniTime.month && nowUniTime.day == scheduleUniTime.day;
    }
    return false;
  }

  bool get isNextTwoWeeks{
    // two weeks + 1 day in order to ensure and cover the whole 14th day roughly
    int twoWeeksDeltaInSeconds = 15 * 24 * 60 * 60;
    DateTime utcNow = DateTime.now().toUtc();
    int secondsStartDelta = startTimeUtc!.difference(utcNow).inSeconds;
    int secondsEndDelta = endTimeUtc!.difference(utcNow).inSeconds;
    return (secondsStartDelta >= 0 && secondsStartDelta < twoWeeksDeltaInSeconds)
        || (secondsEndDelta >= 0 && secondsEndDelta < twoWeeksDeltaInSeconds);
  }

  String get displayWorkTime {
      return getDisplayTime(' - ');
  }

  String getDisplayTime(String separator){
    if(startTimeUtc != null && endTimeUtc != null) {
      String timeFormat = 'h:mm a';
      bool useDeviceLocalTime = Storage().useDeviceLocalTimeZone!;
      DateTime? startDateTime;
      DateTime? endDateTime;
      if(useDeviceLocalTime) {
        startDateTime = AppDateTime().getDeviceTimeFromUtcTime(startTimeUtc);
        endDateTime = AppDateTime().getDeviceTimeFromUtcTime(endTimeUtc);
      } else {
        startDateTime = startTimeUtc;
        endDateTime = endTimeUtc;
      }
      return AppDateTime().formatDateTime(startDateTime, format: timeFormat, ignoreTimeZone: useDeviceLocalTime, showTzSuffix: !useDeviceLocalTime)! +
          separator +
          AppDateTime().formatDateTime(endDateTime, format: timeFormat, ignoreTimeZone: useDeviceLocalTime, showTzSuffix: !useDeviceLocalTime)!;
    }
    return "";
  }

  static List<DiningSchedule>? listFromJson(dynamic json) {
    List<DiningSchedule>? diningSchedules;
    if (json is List) {
      diningSchedules = <DiningSchedule>[];
      for (dynamic jsonEntry in json) {
        if (jsonEntry is Map) {
          DiningSchedule? diningSchedule = DiningSchedule.fromJson(JsonUtils.mapValue(jsonEntry));
          if (diningSchedule != null) {
            diningSchedules.add(diningSchedule);
          }
        }
      }
    }
    return diningSchedules;
  }

  static List<dynamic>? listToJson(List<DiningSchedule>? diningSchedules) {
    List<dynamic>? jsonList;
    if (diningSchedules != null) {
      jsonList = [];
      for (DiningSchedule diningSchedule in diningSchedules) {
        jsonList.add(diningSchedule.toJson());
      }
    }
    return jsonList;
  }
}

//////////////////////////////
/// DiningSpecial

class DiningSpecial {
  String? id;
  String? title;
  String? text;
  String? startDateString;
  String? endDateString;
  String? imageUrl;
  Set<int>? locationIds;

  bool get hasLocationIds{
    return locationIds != null && locationIds!.isNotEmpty;
  }

  DiningSpecial({this.id, this.title, this.text, this.startDateString, this.endDateString, this.imageUrl, this.locationIds});

  static DiningSpecial? fromJson(Map<String, dynamic>?json){
    if (json == null) {
      return null;
    }
    List<dynamic>? _locationIds = json['DiningOptionIDs'];
    List<String>? _castedIds = _locationIds != null ? _locationIds.map((entry)=>entry.toString()).toList() : null;
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
      "DiningOptionIDs": locationIds != null ? locationIds!.toList() : [],
    };
  }
}

//////////////////////////////
/// DiningFeedback

class DiningFeedback {
  final String? feedbackUrl;
  final String? dieticianUrl;
  
  DiningFeedback({this.feedbackUrl, this.dieticianUrl});

  static DiningFeedback? fromJson(Map<String, dynamic>?json) {
    return (json != null) ? DiningFeedback(
      feedbackUrl: JsonUtils.stringValue(json['feedback_url~${Platform.operatingSystem}']) ?? JsonUtils.stringValue(json['feedback_url']),
      dieticianUrl: JsonUtils.stringValue(json['dietician_url~${Platform.operatingSystem}']) ?? JsonUtils.stringValue(json['dietician_url']),
    ) : null;
  }

  bool get isEmpty =>
    StringUtils.isEmpty(feedbackUrl) &&
    StringUtils.isEmpty(dieticianUrl);

  bool get isNotEmpty => !isEmpty;

  static Map<String, DiningFeedback>? mapFromJson(Map<String, dynamic>? jsonMap) {
    Map<String, DiningFeedback>? result;
    if (jsonMap != null) {
      result = <String, DiningFeedback>{};
      jsonMap.forEach((String key, dynamic value) {
        DiningFeedback? feedback = DiningFeedback.fromJson(JsonUtils.mapValue(value));
        if (feedback != null) {
          result![key] = feedback;
        }
      });
    }
    return result;
  }

}
