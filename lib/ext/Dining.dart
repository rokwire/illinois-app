import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension DiningExt on Dining {
  
  Map<String, dynamic>? get analyticsAttributes => {
        Analytics.LogAttributeDiningId:   id,
        Analytics.LogAttributeDiningName: title,
        Analytics.LogAttributeLocation : exploreLocation?.analyticsValue,
  };

  Color? get uiColor => Styles().colors.diningColor;

}

extension DiningFilterExt on Dining {
  bool matchSearchTextLowerCase(String searchLowerCase) =>
    (searchLowerCase.isNotEmpty && (
      (title?.toLowerCase().contains(searchLowerCase) == true) ||
      (diningType?.toLowerCase().contains(searchLowerCase) == true) ||
      (diningLocationName?.toLowerCase().contains(searchLowerCase) == true) ||
      (description?.toLowerCase().contains(searchLowerCase) == true) ||
      (address?.toLowerCase().contains(searchLowerCase) == true)
    ));
}

extension DiningScheduleFilterExt on DiningSchedule {
  bool matchSearchTextLowerCase(String searchLowerCase) =>
    (searchLowerCase.isNotEmpty && (
      (meal?.toLowerCase().contains(searchLowerCase) == true)
    ));
}

extension DiningSchedulesFilterExt on Iterable<DiningSchedule> {
  bool matchSearchTextLowerCase(String searchLowerCase) =>
    firstWhereOrNull((DiningSchedule diningSchedule) => diningSchedule.matchSearchTextLowerCase(searchLowerCase)) != null;
}

extension PaymentTypeUtils on PaymentType {
  String get displayTitle {
    switch (this) {
      case PaymentType.ClassicMeal: return Localization().getStringEx('payment_type.text.classic_meal', 'Classic Meal');
      case PaymentType.DiningDollars: return Localization().getStringEx('payment_type.text.dining_dollars', 'Dining Dollars');
      case PaymentType.IlliniCash: return Localization().getStringEx('payment_type.text.illini_cash', 'Illini Cash');
      case PaymentType.CreditCard: return Localization().getStringEx('payment_type.text.credit_card', 'Credit Card');
      case PaymentType.Cash: return Localization().getStringEx('payment_type.text.cash', 'Cash');
      case PaymentType.GooglePay: return Localization().getStringEx('payment_type.text.google_pay', 'Google Pay');
      case PaymentType.ApplePay: return Localization().getStringEx('payment_type.text.apple_pay', 'Apple Pay');
    }
  }

  String get imageAsset {
    switch (this) {
      case PaymentType.ClassicMeal: return 'payment-meal';
      case PaymentType.DiningDollars: return 'payment-dining';
      case PaymentType.IlliniCash: return 'payment-student-cash';
      case PaymentType.CreditCard: return 'payment-credit-card';
      case PaymentType.Cash: return 'payment-cash';
      case PaymentType.GooglePay: return 'payment-google-pay';
      case PaymentType.ApplePay: return 'payment-apple-pay';
    }
  }

  Widget? get iconWidget => Styles().images.getImage(imageAsset, semanticLabel: displayTitle);
}

extension DiningUtils on Dining {

  String? get displayWorkTime {
    if (diningSchedules != null && diningSchedules!.isNotEmpty) {
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

  bool  get isOpen => diningSchedules?.firstWhereOrNull((schedule) => schedule.isOpen) != null;
  bool get isStarred => (Auth2().prefs?.isFavorite(this) == true);
  bool get hasDiningSchedules => CollectionUtils.isNotEmpty(diningSchedules);

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

extension DiningScheduleUtils on DiningSchedule {
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
}

extension DiningSpecialUtils on DiningSpecial {
  bool get hasLocationIds => locationIds?.isNotEmpty == true;
}

extension DiningProductItemUtils on DiningProductItem {

  List<String> get traitList {
    List<String> traitList = <String>[];
    for (String entry in (traits ?? "").split(',')) {
      entry = entry.trim();
      if (entry.isNotEmpty) {
        traitList.add(entry);
      }
    }
    return traitList;
  }

  List<String> get ingredients {
    List<String>? foodTypes = Dinings().foodTypes;
    return traitList.where((entry) => (foodTypes?.contains(entry) == false)).toList();
  }

  List<String> get dietaryPreferences{
    List<String>? foodTypes = Dinings().foodTypes;
    return traitList.where((entry) => (foodTypes?.contains(entry) == true)).toList();
  }

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

  static List<DiningProductItem> filter(List<DiningProductItem>? allProducts, String? scheduleId, Set<String>? includedFoodTypePrefs, Set<String>? excludedFoodIngredientsPrefs) {
    return  (scheduleId != null && allProducts != null) ?
      allProducts.where((DiningProductItem item) => (scheduleId == item.scheduleId) &&
        ((includedFoodTypePrefs == null) || includedFoodTypePrefs.isEmpty || item.containsFoodType(includedFoodTypePrefs)) &&
        ((excludedFoodIngredientsPrefs == null) || excludedFoodIngredientsPrefs.isEmpty || !item.containsFoodIngredient(excludedFoodIngredientsPrefs))
      ).toList() : [];
  }

  static Map<String, List<DiningProductItem>> productsByCategory(List<DiningProductItem>? allProducts){
    Map<String, List<DiningProductItem>> mapping = Map<String, List<DiningProductItem>>();
    if (allProducts != null) {
      for (DiningProductItem item in allProducts) {
        String? itemCategory = item.category;
        if (itemCategory != null) {
          (mapping[itemCategory] ??= <DiningProductItem>[]).add(item);
        }
      }
    }
    return mapping;
  }
}

extension NutritionAttributeUtils on NutritionAttribute {
  String? get displayName => (name != null) ?
    Localization().getString("com.illinois.nutrition_type.entry.$name", defaults: name) : null;
}
