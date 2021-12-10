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
import 'package:illinois/service/Assets.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:intl/intl.dart';

import 'package:location/location.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';


class DiningService  with Service {

  static final String _olddiningsFileName = 'dinings_schedules.json';

  String? _diningLocationsResponse;
  DateTime? _lastDiningLocationsRequestTime;

  String? _diningSpecialsResponse;
  DateTime? _lastDiningSpecialsRequestTime;

  static final DiningService _logic = DiningService._internal();

  factory DiningService() {
    return _logic;
  }

  void createService() {
    super.createService();
    _cleanDinigsCacheFile();
  }

  DiningService._internal();

  Future<List<Dining>?> loadBackendDinings(bool onlyOpened, PaymentType? paymentType, LocationData? locationData) async {
    if(_enabled) {
      List<Dining> dinings = [];

      // 1.2 Load Dining locations only if need
      if (!_useCachedDiningLoacations) {
        // 1.3 Load dining locations from server
        _diningLocationsResponse = await _loadDiningsFromServer();
        _lastDiningLocationsRequestTime = DateTime.now();
      }

      Map<String, dynamic>? jsonData = AppJson.decode(_diningLocationsResponse);
      if (jsonData != null) {
        // 1.2.2 Load Menu Schedules
        List<dynamic>? diningLocations = jsonData["DiningOptions"];
        if (diningLocations != null && diningLocations.isNotEmpty) {
          for (Map<String, dynamic> diningLocation in diningLocations as Iterable<Map<String, dynamic>>) {
            AppList.add(dinings, Dining.fromJson(diningLocation));
          }
        }
      }

      // 1.3 Sort
      if (locationData != null) {
        _sortExploresByLocation(dinings, locationData);
      }
      else {
        _sortExploresByName(dinings);
      }

      // Filter by payment type
      List<Dining>? diningsLimited = paymentType != null ? dinings.where((Dining? dining){
        return (dining?.paymentTypes?.contains(paymentType) ?? false);
      }).toList() : dinings;

      //Filter only opened
      return onlyOpened ? diningsLimited.where((Dining? dining) => dining!.isOpen).toList() : diningsLimited;
    }
    return null;
  }

  Future<void> _cleanDinigsCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String configFilePath = join(appDocDir.path, _olddiningsFileName);
    File diningsCacheFile = File(configFilePath);
    bool exist = await diningsCacheFile.exists();
    if(exist){
      await diningsCacheFile.delete();
    }
  }

  bool get _useCachedDiningLoacations{
    return (_diningLocationsResponse != null && _lastDiningLocationsRequestTime != null
        && DateTime.now().difference(_lastDiningLocationsRequestTime!).inHours.abs() < 24);
  }

  Future<String?> _loadDiningsFromServer() async {
    final url = (Config().illiniCashBaseUrl != null) ? "${Config().illiniCashBaseUrl}/LocationSchedules" : null;
    final response = await Network().get(url);
    String? responseBody;
    if ((response != null) && (response.statusCode == 200)) {
      responseBody = response.body;
    } else {
      Log.e('Failed to load dinings schedule table');
    }
    return responseBody;
  }

  Future<List<DiningProductItem>?> loadMenuItemsForDate(String? diningId, DateTime? diningDate) async{
    if(_enabled) {
      if (diningId != null && diningDate != null) {
        String? filterDateString = DiningUtils.dateToRequestString(diningDate);

        final url = (Config().illiniCashBaseUrl != null) ? "${Config().illiniCashBaseUrl}/Menu/$diningId/$filterDateString" : null;
        final response = await Network().get(url);
        if ((response != null) && (response.statusCode == 200)) {
          List<dynamic>? jsonList = AppJson.decode(response.body);
          List<DiningProductItem> productList = [];
          if (AppCollection.isCollectionNotEmpty(jsonList)) {
            for (Map<String, dynamic> jsonEntry in jsonList as Iterable<Map<String, dynamic>>) {
              DiningProductItem? item = DiningProductItem.fromJson(jsonEntry);
              if (item != null) {
                productList.add(item);
              }
            }
          }
          return productList;
        } else {
          throw Exception('Failed to load products for the desired date and location');
        }
      }
      throw Exception('Failed to load products for the desired date and location');
    }
    return null;
  }


  Future<DiningNutritionItem?> loadNutritionItemWithId(String? itemId) async {
    if(_enabled) {
      // TMP: "https://shibtest.housing.illinois.edu/MobileAppWS/api/Nutrition/44";
      final url = (Config().illiniCashBaseUrl != null) ? "${Config().illiniCashBaseUrl}/Nutrition/$itemId" : null;
      final response = await Network().get(url);
      String? responseBody;
      if ((response != null) && (response.statusCode == 200)) {
        responseBody = response.body;

        if (AppString.isStringNotEmpty(responseBody)) {
          Map<String, dynamic>? jsonData = AppJson.decode(responseBody);
          return DiningNutritionItem.fromJson(jsonData);
        }
      } else {
        Log.e('Failed to load nutrition item with id: $itemId ');
        Log.e(responseBody);
      }
    }

    return null;
  }

  Future<String?> _loadDiningSpecialsFromServer() async {
    _diningSpecialsResponse = null;
    // TMP: "https://shibtest.housing.illinois.edu/MobileAppWS/api/Offers";
    final url = (Config().illiniCashBaseUrl != null) ? "${Config().illiniCashBaseUrl}/Offers" : null;
    final response = await Network().get(url);
    if ((response != null) && (response.statusCode == 200)) {
      _diningSpecialsResponse = response.body;
      _lastDiningSpecialsRequestTime = DateTime.now();
      return _diningSpecialsResponse;
    }
    return null;
  }

  bool get _useCachedDiningSpecials{
    return (_diningSpecialsResponse != null && _lastDiningSpecialsRequestTime != null
        && DateTime.now().difference(_lastDiningSpecialsRequestTime!).inHours.abs() < 24);
  }

  Future<List<DiningSpecial>?> loadDiningSpecials() async {
    if(_enabled) {
      String? responseBody = _diningSpecialsResponse;
      if (!_useCachedDiningSpecials) {
        responseBody = await _loadDiningSpecialsFromServer();
      }

      if (responseBody != null) {
        List<dynamic>? jsonList = AppJson.decode(responseBody);
        if (AppCollection.isCollectionNotEmpty(jsonList)) {
          List<DiningSpecial> list = [];

          for (Map<String, dynamic> jsonEntry in jsonList as Iterable<Map<String, dynamic>>) {
            AppList.add(list, DiningSpecial.fromJson(jsonEntry));
          }

          return list;
        }
      } else {
        Log.e('Failed to load special offers');
        Log.e(responseBody);
      }
    }
    return null;
  }

  List<String>? get foodTypes {
    return _enabled ? Assets()['dining.food_types'].cast<String>() : null;
  }

  List<String>? get foodIngredients {
    return _enabled ? Assets()['dining.food_ingredients'].cast<String>() : null;
  }

  String? getLocalizedString(String? text) {
    return _enabled ? Localization().getStringFromMapping(text, Assets()['dining.strings']) : null;
  }

  /*
  Set<String> getIncludedFoodTypesPrefs() {
    return _enabled ? Auth2().prefs?.includedFoodTypes : null;
  }

  void setIncludedFoodTypesPrefs(Set<String> value) {
    if(_enabled) {
      Auth2().prefs?.includedFoodTypes = value;
      _notifyFoodPrefsChanged();
    }
  }

  Set<String> getExcludedFoodIngredientsPrefs() {
    return _enabled ? Auth2().prefs?.excludedFoodIngredients : null;
  }

  void setExcludedFoodIngredientsPrefs(Set<String> value) {
    if(_enabled) {
      Auth2().prefs?.excludedFoodIngredients = value;
      _notifyFoodPrefsChanged();
    }
  }
  */

  // Helpers
  void _sortExploresByLocation(List<Explore?> explores, LocationData locationData) {
    explores.sort((Explore? explore1, Explore? explore2) {
      double distance1 = AppLocation.distance(explore1!.exploreLocation!.latitude as double, explore1.exploreLocation!.longitude as double, locationData.latitude!, locationData.longitude!);
      double distance2 = AppLocation.distance(explore2!.exploreLocation!.latitude as double, explore2.exploreLocation!.longitude as double, locationData.latitude!, locationData.longitude!);
      if (distance1 < distance2) {
        return -1;
      }
      else if (distance1 > distance2) {
        return 1;
      }
      else {
        return 0;
      }
    });
  }

  void _sortExploresByName(List<Explore?> explores) {
    explores.sort((Explore? explore1, Explore? explore2) {
      return (explore1?.exploreTitle ?? "").compareTo(explore2?.exploreTitle ?? "");
    });
  }

  /////////////////////////
  // Enabled

  bool get _enabled => AppString.isStringNotEmpty(Config().illiniCashBaseUrl);
}

class DiningUtils{

  static String? dateToRequestString(DateTime? date) {
    if(date != null){
      return DateFormat('M-d-yyyy').format(date);
    }
    else {
      return null;
    }
  }
   
  static List<DiningProductItem> getProductsForScheduleId(List<DiningProductItem>? allProducts, String? scheduleId, Set<String>? includedFoodTypePrefs, Set<String>? excludedFoodIngredientsPrefs) {
    if(scheduleId != null && allProducts != null){
      return allProducts.where((DiningProductItem item){
        return scheduleId == item.scheduleId &&
            ((includedFoodTypePrefs == null) || includedFoodTypePrefs.isEmpty || item.containsFoodType(includedFoodTypePrefs)) &&
            ((excludedFoodIngredientsPrefs == null) || excludedFoodIngredientsPrefs.isEmpty || !item.containsFoodIngredient(excludedFoodIngredientsPrefs));
      }).toList();
    }
    return [];
  }

  static Map<String?,List<DiningProductItem>> getStationGroupedProducts(List<DiningProductItem>? allProducts){
    Map<String?, List<DiningProductItem>> mapping = Map<String?,
        List<DiningProductItem>>();
    if(allProducts != null) {
      for(DiningProductItem item in allProducts){
        if(!mapping.containsKey(item.servingUnit)){
          mapping[item.servingUnit] = [];
        }
        mapping[item.servingUnit]!.add(item);
      }
    }
    return mapping;
  }

  static Map<String?,List<DiningProductItem>> getCourseGroupedProducts(List<DiningProductItem>? allProducts){
    Map<String?, List<DiningProductItem>> mapping = Map<String?,
        List<DiningProductItem>>();
    if(allProducts != null) {
      for(DiningProductItem item in allProducts){
        if(!mapping.containsKey(item.course)){
          mapping[item.course] = [];
        }
        mapping[item.course]!.add(item);
      }
    }
    return mapping;
  }

  static Map<String?,List<DiningProductItem>> getCategoryGroupedProducts(List<DiningProductItem>? allProducts){
    Map<String?, List<DiningProductItem>> mapping = Map<String?,
        List<DiningProductItem>>();
    if(allProducts != null) {
      for(DiningProductItem item in allProducts){
        if(!mapping.containsKey(item.category)){
          mapping[item.category] = [];
        }
        mapping[item.category]!.add(item);
      }
    }
    return mapping;
  }

  static DiningNutritionItem? getNutritionItemById(String? itemId, List<DiningNutritionItem>? allItems){
    if(itemId != null && allItems != null && allItems.isNotEmpty){
      for(DiningNutritionItem item in allItems){
        if(item.itemID == itemId)
          return item;
      }
    }
    return null;
  }
}
