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
import 'package:illinois/model/Dining.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:intl/intl.dart';

import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';


class Dinings with Service implements ContentItemCategoryClient{

  static final String _olddiningsFileName = 'dinings_schedules.json';

  static const String _diningContentCategory = "dining";

  String? _diningLocationsResponse;
  DateTime? _lastDiningLocationsRequestTime;

  String? _diningSpecialsResponse;
  DateTime? _lastDiningSpecialsRequestTime;

  static final Dinings _instance = Dinings._internal();

  factory Dinings() => _instance;
  
  Dinings._internal();

  // Service
  @override
  void createService() {
    super.createService();
    _cleanDinigsCacheFile();
  }

  @override
  Future<void> initService() async {
    super.initService();
  }

  @override
  void destroyService() {
    super.destroyService();
  }

  // ContentItemCategoryClient

  @override
  List<String> get contentItemCategory => <String>[_diningContentCategory];

  // Implementation

  Future<List<Dining>?> loadBackendDinings(bool onlyOpened, PaymentType? paymentType, Position? locationData) async {
    if(_enabled) {
      List<Dining> dinings = <Dining>[];

      // 1.2 Load Dining locations only if need
      if (!_useCachedDiningLoacations) {
        // 1.3 Load dining locations from server
        _diningLocationsResponse = await _loadDiningsFromServer();
        _lastDiningLocationsRequestTime = DateTime.now();
      }

      Map<String, dynamic>? jsonData = JsonUtils.decode(_diningLocationsResponse);
      if (jsonData != null) {
        // 1.2.2 Load Menu Schedules
        List<dynamic>? diningLocations = jsonData["DiningOptions"];
        if (diningLocations != null && diningLocations.isNotEmpty) {
          for (dynamic diningLocation in diningLocations) {
            ListUtils.add(dinings, Dining.fromJson(JsonUtils.mapValue(diningLocation)));
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
          List<dynamic>? jsonList = JsonUtils.decode(response.body);
          List<DiningProductItem> productList = <DiningProductItem>[];
          if (CollectionUtils.isNotEmpty(jsonList)) {
            for (dynamic jsonEntry in jsonList!) {
              DiningProductItem? item = DiningProductItem.fromJson(JsonUtils.mapValue(jsonEntry));
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

        if (StringUtils.isNotEmpty(responseBody)) {
          Map<String, dynamic>? jsonData = JsonUtils.decode(responseBody);
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
        List<dynamic>? jsonList = JsonUtils.decode(responseBody);
        if (CollectionUtils.isNotEmpty(jsonList)) {
          List<DiningSpecial> list = <DiningSpecial>[];

          for (dynamic jsonEntry in jsonList!) {
            ListUtils.add(list, DiningSpecial.fromJson(JsonUtils.mapValue(jsonEntry) ));
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

  Map<String, dynamic>? get _diningContentData {
    return Content().contentItem(_diningContentCategory);
  }

  List<String>? get foodTypes {
    return _enabled ? JsonUtils.listStringsValue(MapUtils.get(_diningContentData, 'food_types')) : null;
  }

  List<String>? get foodIngredients {
    return _enabled ? JsonUtils.listStringsValue(MapUtils.get(_diningContentData, 'food_ingredients')) : null;
  }

  String? getLocalizedString(String? text) {
    return _enabled ? Localization().getStringFromMapping(text,  JsonUtils.mapValue(MapUtils.get(_diningContentData, 'strings'))) : null;
  }

  Future<DiningFeedback?> loadDiningFeedback({String? diningId}) async {
    //return (_feedbacks ??= DiningFeedback.mapFromJson(JsonUtils.decodeMap(await AppBundle.loadString('assets/dining.feedbacks.json'))) ?? <String, DiningFeedback>{})[diningId];
    const String diningFeedbackCategory = 'dining_feedbacks';
    Map<String, DiningFeedback>? feedbacksMap = DiningFeedback.mapFromJson(JsonUtils.mapValue(await Content().loadContentItem(diningFeedbackCategory)));
    return (feedbacksMap != null) ? feedbacksMap[diningId] : null;
  }

  // Helpers
  void _sortExploresByLocation(List<Explore> explores, Position locationData) {
    explores.sort((Explore explore1, Explore explore2) {
      double? lat1 = explore1.exploreLocation?.latitude?.toDouble();
      double? lng1 = explore1.exploreLocation?.longitude?.toDouble();
      double distance1 = ((lat1 != null) && (lng1 != null)) ? Geolocator.distanceBetween(lat1, lng1, locationData.latitude, locationData.longitude) : double.infinity;
      
      double? lat2 = explore2.exploreLocation?.latitude?.toDouble();
      double? lng2 = explore2.exploreLocation?.longitude?.toDouble();
      double distance2 = ((lat2 != null) && (lng2 != null)) ? Geolocator.distanceBetween(lat2, lng2, locationData.latitude, locationData.longitude) : double.infinity;
      
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

  void _sortExploresByName(List<Explore> explores) {
    explores.sort((Explore? explore1, Explore? explore2) {
      return (explore1?.exploreTitle ?? "").compareTo(explore2?.exploreTitle ?? "");
    });
  }

  /////////////////////////
  // Enabled

  bool get _enabled => StringUtils.isNotEmpty(Config().illiniCashBaseUrl);
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

  static Map<String,List<DiningProductItem>> getStationGroupedProducts(List<DiningProductItem>? allProducts){
    Map<String, List<DiningProductItem>> mapping = Map<String,
        List<DiningProductItem>>();
    if(allProducts != null) {
      for(DiningProductItem item in allProducts){
        if((item.servingUnit != null) && !mapping.containsKey(item.servingUnit)){
          mapping[item.servingUnit!] = <DiningProductItem>[];
        }
        mapping[item.servingUnit]!.add(item);
      }
    }
    return mapping;
  }

  static Map<String,List<DiningProductItem>> getCourseGroupedProducts(List<DiningProductItem>? allProducts){
    Map<String, List<DiningProductItem>> mapping = Map<String,
        List<DiningProductItem>>();
    if(allProducts != null) {
      for(DiningProductItem item in allProducts){
        if((item.course != null) && !mapping.containsKey(item.course)){
          mapping[item.course!] = <DiningProductItem>[];
        }
        mapping[item.course]!.add(item);
      }
    }
    return mapping;
  }

  static Map<String,List<DiningProductItem>> getCategoryGroupedProducts(List<DiningProductItem>? allProducts){
    Map<String, List<DiningProductItem>> mapping = Map<String,
        List<DiningProductItem>>();
    if(allProducts != null) {
      for(DiningProductItem item in allProducts){
        if (item.category != null) {
          if(!mapping.containsKey(item.category)){
            mapping[item.category!] = <DiningProductItem>[];
          }
          mapping[item.category!]!.add(item);
        }
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
