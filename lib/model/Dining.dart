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
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/utils/utils.dart';

//////////////////////////////
/// DiningOption

class Dining with Explore implements Favorite {
  final String? id;
  final String? title;
  final String? diningType;
  final String? diningLocationName;
  final String? description;
  final String? imageUrl;

  final String? address;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic>? onlineOrder;
  List<PaymentType>? paymentTypes;
  List<DiningSchedule>? diningSchedules;

  Dining({ this.id, this.title, this.diningType, this.diningLocationName, this.description, this.imageUrl,
    this.address, this.latitude, this.longitude,
    this.onlineOrder,
      this.paymentTypes,
      this.diningSchedules
  });

  // JSON Serialization
  
  static Dining? fromJson(Map<String, dynamic>? json) => (json != null) ? Dining(
    id: JsonUtils.stringValue(json['DiningOptionID']),
    title: JsonUtils.stringValue(json['DiningOptionName']),
    diningType: JsonUtils.stringValue(json['Type']),
    diningLocationName: JsonUtils.stringValue(json['DiningLocation']),
    description: JsonUtils.stringValue(json['MoreInfo']),
    imageUrl: JsonUtils.stringValue(json['ImageUrl']),
    address: JsonUtils.stringValue(json['Address']),
    onlineOrder: JsonUtils.mapValue(json['OnLineOrder']),
    paymentTypes: PaymentTypeImpl.listFromJson(JsonUtils.listValue(json['PaymentTypes'])),
    diningSchedules: DiningSchedule.listFromJson(JsonUtils.listValue(json['DiningSchedules'])),
  ) : null;

  toJson() => {
      'DiningOptionID': id,
      'DiningOptionName': title,
      'Type': diningType,
      'DiningLocation': diningLocationName,
      'MoreInfo': description,
      'ImageUrl': imageUrl,
      'Address': address,
      'Lat': latitude,
      'Long': longitude,
      'OnLineOrder': onlineOrder,
      'PaymentTypes': PaymentTypeImpl.listToJson(paymentTypes),
      'DiningSchedules': DiningSchedule.listToJson(diningSchedules),
    };

  // JSON List Serialization

  static List<Dining>? listFromJson(List<dynamic>? jsonList) {
    List<Dining>? values;
    if (jsonList != null) {
      values = <Dining>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, Dining.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<Dining>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (Dining value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  // Equality

  @override
  bool operator ==(other) =>
    (other is Dining) &&
      (other.id == id) &&
      (other.title == title) &&
      (other.diningType == diningType) &&
      (other.diningLocationName == diningLocationName) &&
      (other.description == description) &&
      (other.imageUrl == imageUrl) &&

      (other.address == address) &&
      (other.latitude == latitude) &&
      (other.longitude == longitude) &&

      (DeepCollectionEquality().equals(other.onlineOrder, onlineOrder)) &&
      (DeepCollectionEquality().equals(other.paymentTypes, paymentTypes)) &&
      (DeepCollectionEquality().equals(other.diningSchedules, diningSchedules));

  @override
  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (title?.hashCode ?? 0) ^
      (diningType?.hashCode ?? 0) ^
      (diningLocationName?.hashCode ?? 0) ^
      (description?.hashCode ?? 0) ^
      (imageUrl?.hashCode ?? 0) ^

      (address?.hashCode ?? 0) ^
      (latitude?.hashCode ?? 0) ^
      (longitude?.hashCode ?? 0) ^

      (DeepCollectionEquality().hash(onlineOrder)) ^
      (DeepCollectionEquality().hash(paymentTypes)) ^
      (DeepCollectionEquality().hash(diningSchedules));

  // Explore
  @override String?   get exploreId               => id;
  @override String?   get exploreTitle            => title;
  @override String?   get exploreDescription      => description;
  @override DateTime? get exploreDateTimeUtc      => null;
  @override String?   get exploreImageURL         => imageUrl;
  @override ExploreLocation? get exploreLocation  => ExploreLocation(description: address, latitude: latitude, longitude: longitude,);

  // Favorite
  static const String favoriteKeyName = "diningPlaceIds";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => id;
}

//////////////////////////////
/// PaymentType

enum PaymentType { ClassicMeal, DiningDollars, IlliniCash, CreditCard, Cash, GooglePay, ApplePay  }

extension PaymentTypeImpl on PaymentType {

  // Json Serialization
  static PaymentType? fromJsonString(String? value) {
    switch (value) {
      case 'ClassicMeal':    return  PaymentType.ClassicMeal;
      case 'Dining Dollars': return  PaymentType.DiningDollars;
      case 'IlliniCash':     return  PaymentType.IlliniCash;
      case 'CreditCard':     return  PaymentType.CreditCard;
      case 'Cash':           return  PaymentType.Cash;
      case 'GooglePay':      return  PaymentType.GooglePay;
      case 'ApplePay':       return PaymentType.ApplePay;
      default:               return null;
    }
  }

  String toJsonString() {
    switch(this) {
      case PaymentType.ClassicMeal:   return 'ClassicMeal';
      case PaymentType.DiningDollars: return 'Dining Dollars';
      case PaymentType.IlliniCash:    return 'IlliniCash';
      case PaymentType.CreditCard:    return 'CreditCard';
      case PaymentType.Cash:          return 'Cash';
      case PaymentType.GooglePay:     return 'GooglePay';
      case PaymentType.ApplePay:      return 'ApplePay';
    }
  }

  // Json List Serialization

  static List<PaymentType>? listFromJson(List<dynamic>? jsonList) {
    List<PaymentType>? values;
    if (jsonList != null) {
      values = <PaymentType>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, fromJsonString(JsonUtils.stringValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<PaymentType>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (PaymentType value in values) {
        ListUtils.add(jsonList, value.toJsonString());
      }
    }
    return jsonList;
  }

}

//////////////////////////////
/// DiningNutritionItem

class DiningNutritionItem {
  String? itemID;
  String? name;
  String? serving;
  List<NutritionAttribute>? nutritionAttributes;


  DiningNutritionItem({this.itemID, this.name, this.serving, this.nutritionAttributes});

  static DiningNutritionItem? fromJson(Map<String, dynamic>? json) => (json != null) ? DiningNutritionItem(
    itemID: JsonUtils.intValue(json['ItemID']).toString(),
    name: JsonUtils.stringValue(json['FormalName']),
    serving: JsonUtils.stringValue(json['Serving']),
    nutritionAttributes: NutritionAttribute.listFromJson(JsonUtils.listValue(json["NutritionList"])),
  ) : null;
}

//////////////////////////////
/// NutritionAttribute

class NutritionAttribute {
  String? name;
  String? value;

  NutritionAttribute({this.name, this.value});

  static NutritionAttribute? fromJson(Map<String,dynamic>? json) => (json != null) ? NutritionAttribute(
    name: JsonUtils.stringValue(json["Name"]),
    value: JsonUtils.stringValue(json["Value"]),
  ) : null;

  static List<NutritionAttribute>? listFromJson(List<dynamic>? jsonList) {
    List<NutritionAttribute>? values;
    if (jsonList != null) {
      values = <NutritionAttribute>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, NutritionAttribute.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }
}

//////////////////////////////
/// DiningProductItem

class DiningProductItem {
  String? itemID;
  String? scheduleId;
  String? diningOptionId;
  String? diningMenuId;
  String? name;
  String? servingUnit;
  String? course;
  String? traits;
  String? category;
  int? courseSort;
  String? meal;

  DiningProductItem({this.itemID, this.scheduleId, this.diningOptionId, this.diningMenuId,
    this.name, this.servingUnit, this.course, this.traits, this.category, this.courseSort, this.meal
  });

  // JSON Serialization

  static DiningProductItem? fromJson(Map<String, dynamic>? json) => (json != null) ? DiningProductItem(
    itemID: JsonUtils.intValue(json['ItemID'])?.toString(),
    scheduleId: JsonUtils.intValue(json['ScheduleID'])?.toString(),
    diningOptionId: JsonUtils.intValue(json['DiningOptionID'])?.toString(),
    name: JsonUtils.stringValue(json['FormalName']),
    servingUnit: JsonUtils.stringValue(json['ServingUnit']),
    traits: JsonUtils.stringValue(json['Traits']),
    category: JsonUtils.stringValue(json['Category']),
    course: JsonUtils.stringValue(json['Course']),
    courseSort: JsonUtils.intValue(json['CourseSort']),
    meal: JsonUtils.stringValue(json['Meal']),
  ) : null;

  // JSON List Serialization

  static List<DiningProductItem>? listFromJson(List<dynamic>? jsonList) {
    List<DiningProductItem>? values;
    if (jsonList != null) {
      values = <DiningProductItem>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, DiningProductItem.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

}

//////////////////////////////
/// DiningSchedule

class DiningSchedule {
  final String? scheduleId;
  final String? diningLocationId;
  final String? meal;
  final DateTime? eventDateUtc;
  final DateTime? startTimeUtc;
  final DateTime? endTimeUtc;

  DiningSchedule({this.scheduleId, this.diningLocationId, this.meal,
    this.eventDateUtc, this.startTimeUtc, this.endTimeUtc,
  });

  // JSON Serialization

  static DiningSchedule? fromJson(Map<String, dynamic>? json) => (json != null) ? DiningSchedule(
    scheduleId:       JsonUtils.intValue(json['ScheduleID'])?.toString(),
    diningLocationId: JsonUtils.intValue(json['DiningOptionID'])?.toString(),
    meal:             JsonUtils.stringValue(json['TimePeriod']),
    eventDateUtc:     DateTimeUtils.dateTimeFromSecondsSinceEpoch(JsonUtils.intValue(json['EventDateUTC']), isUtc: true),
    startTimeUtc:     DateTimeUtils.dateTimeFromSecondsSinceEpoch(JsonUtils.intValue(json['StartTimeUTC']), isUtc: true),
    endTimeUtc:       DateTimeUtils.dateTimeFromSecondsSinceEpoch(JsonUtils.intValue(json['EndTimeUTC']), isUtc: true),
  ) : null;

  Map<String, dynamic> toJson() {
    return {
      'ScheduleID':     JsonUtils.intValue(scheduleId),
      'DiningOptionID': JsonUtils.intValue(diningLocationId),
      'TimePeriod':     meal,
      'EventDateUTC':   eventDateUtc?.millisecondsSinceEpoch,
      'StartTimeUTC':   startTimeUtc?.millisecondsSinceEpoch,
      'EndTimeUTC':     endTimeUtc?.millisecondsSinceEpoch,
    };
  }

  // JSON List Serialization

  static List<DiningSchedule>? listFromJson(List<dynamic>? jsonList) {
    List<DiningSchedule>? values;
    if (jsonList != null) {
      values = <DiningSchedule>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, DiningSchedule.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
      //values.sort((schedule1, schedule2) => SortUtils.compare(schedule1.startTimeUtc, schedule2.startTimeUtc));
    }
    return values;
  }

  static List<dynamic>? listToJson(List<DiningSchedule>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (DiningSchedule value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  // Equality

  @override
  bool operator ==(other) =>
    (other is DiningSchedule) &&
    (other.scheduleId == scheduleId) &&
    (other.diningLocationId == diningLocationId) &&
    (other.meal == meal) &&
    (other.eventDateUtc == eventDateUtc) &&
    (other.startTimeUtc == startTimeUtc) &&
    (other.endTimeUtc == endTimeUtc);

  @override
  int get hashCode =>
    (scheduleId?.hashCode ?? 0) ^
    (diningLocationId?.hashCode ?? 0) ^
    (meal?.hashCode ?? 0) ^
    (eventDateUtc?.hashCode ?? 0) ^
    (startTimeUtc?.hashCode ?? 0) ^
    (endTimeUtc?.hashCode ?? 0);
}

//////////////////////////////
/// DiningSpecial

class DiningSpecial {
  final String? id;
  final String? title;
  final String? text;
  final String? startDateString;
  final String? endDateString;
  final String? imageUrl;
  final Set<int>? locationIds;

  DiningSpecial({this.id, this.title, this.text, this.startDateString, this.endDateString, this.imageUrl, this.locationIds});

  // Json Serialization

  static DiningSpecial? fromJson(Map<String, dynamic>? json) => (json != null) ? DiningSpecial(
      id: JsonUtils.stringValue(json['OfferID']),
      title: JsonUtils.stringValue(json['Title']),
      text: JsonUtils.stringValue(json['OfferText']),
      startDateString: JsonUtils.stringValue(json['StartDate']),
      endDateString: JsonUtils.stringValue(json['EndDate']),
      imageUrl: JsonUtils.stringValue(json['ImageUrl']),
      locationIds: SetUtils.from(JsonUtils.listIntsValue(json['DiningOptionIDs'])),
  ) : null;


  toJson() => {
    "OfferID": id,
    "Title": title,
    "OfferText": text,
    "StartDate": startDateString,
    "EndDate": endDateString,
    "ImageUrl": imageUrl,
    "DiningOptionIDs": locationIds?.toList(),
  };

  // Json List Serialization

  static List<DiningSpecial>? listFromJson(List<dynamic>? jsonList) {
    List<DiningSpecial>? values;
    if (jsonList != null) {
      values = <DiningSpecial>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, DiningSpecial.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<DiningSpecial>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (DiningSpecial value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  // Equality

  @override
  bool operator ==(other) =>
    (other is DiningSpecial) &&
    (other.id == id) &&
    (other.title == title) &&
    (other.text == text) &&
    (other.startDateString == startDateString) &&
    (other.endDateString == endDateString) &&
    (other.imageUrl == imageUrl) &&
    (DeepCollectionEquality().equals(other.locationIds, locationIds));

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (text?.hashCode ?? 0) ^
    (startDateString?.hashCode ?? 0) ^
    (endDateString?.hashCode ?? 0) ^
    (imageUrl?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(locationIds));

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
