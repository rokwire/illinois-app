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

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:illinois/ext/Dining.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:rokwire_plugin/ext/network.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:intl/intl.dart';

import 'package:geolocator/geolocator.dart';


class Dinings with Service, NotificationsListener implements ContentItemCategoryClient {

  static const String notifyLaunchDetail  = "edu.illinois.rokwire.dining2.launch.detail";
  static const String notifyLaunchQuery  = "edu.illinois.rokwire.dining2.launch.query";

  static const String _diningContentCategory = "dining";

  static final Dinings _instance = Dinings._internal();

  factory Dinings() => _instance;
  
  Dinings._internal();

  // Service
  @override
  void createService() {
    NotificationService().subscribe(this,[
      DeepLink.notifyUiUri,
    ]);
    super.createService();
  }

  @override
  Future<void> initService() async {
    await super.initService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { DeepLink() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUiUri) {
      _onDeepLinkUri(JsonUtils.cast(param));
    }
  }

  // ContentItemCategoryClient

  @override
  List<String> get contentItemCategory => <String>[_diningContentCategory];

  // Implementation

  bool get _enabled => StringUtils.isNotEmpty(Config().illiniCashUrl);

  Future<List<Dining>?> loadDinings() async {
    String? diningsUrl = _enabled ? "${Config().illiniCashUrl}/LocationSchedules" : null;
    Response? response = (diningsUrl != null) ? await Network().get(diningsUrl, auth: Auth2Csrf()) : null;
    Map<String, dynamic>? responseJson = (response?.succeeded == true) ? JsonUtils.decodeMap(response?.body) : null;
    List<dynamic>? diningOptionsJsonList = (responseJson != null) ? JsonUtils.listValue(responseJson['DiningOptions']) : null;
    return Dining.listFromJson(diningOptionsJsonList);
  }

  Future<List<Dining>?> loadFilteredDinings({bool? onlyOpened, PaymentType? paymentType, Position? location}) async {
    List<Dining>? dinings = _enabled ? await loadDinings() : null;
    if (dinings != null) {

      if (paymentType != null) {
        dinings = List.from(dinings.where((Dining? dining) => (dining?.paymentTypes?.contains(paymentType) == true)));
      }

      if (onlyOpened == true) {
        dinings = List.from(dinings.where((Dining? dining) => (dining?.isOpen == true)));
      }

      // 1.3 Sort
      if (location != null) {
        _sortExploresByLocation(dinings, location);
      }
      else {
        _sortExploresByName(dinings);
      }

      return dinings;
    }
    else {
      return null;
    }
  }

  Future<Dining?> loadDining(String diningOptionId) async {
    List<Dining>? dinings = await loadDinings();
    return dinings?.firstWhereOrNull((Dining dining) => (dining.id == diningOptionId));
  }

  Future<List<DiningProductItem>?> loadMenuItemsForDate({required String diningId, required DateTime date}) async {
    String? url = _enabled ? "${Config().illiniCashUrl}/Menu/$diningId/${DateFormat('M-d-yyyy').format(date)}" : null;
    Response? response = (url != null) ? await Network().get(url, auth: Auth2Csrf()) : null;
    return (response?.succeeded == true) ? DiningProductItem.listFromJson(JsonUtils.decodeList(response?.body)) : null;
  }


  Future<DiningNutritionItem?> loadNutritionItemWithId(String? itemId) async {
    String? url = _enabled ? "${Config().illiniCashUrl}/Nutrition/$itemId" : null;
    Response? response = (url != null) ? await Network().get(url, auth: Auth2Csrf()) : null;
    return (response?.succeeded == true) ? DiningNutritionItem.fromJson(JsonUtils.decodeMap(response?.body)) : null;
  }

  Future<List<DiningSpecial>?> loadDiningSpecials() async {
    String? url = _enabled ? "${Config().illiniCashUrl}/Offers" : null;
    Response? response = (url != null) ? await Network().get(url, auth: Auth2Csrf()) : null;
    return (response?.succeeded == true) ? DiningSpecial.listFromJson(JsonUtils.decodeList(response?.body)) : null;
  }

  Map<String, dynamic>? get _diningContentData =>
    Content().contentItem(_diningContentCategory);

  List<String>? get foodTypes =>
    _enabled ? JsonUtils.listStringsValue(MapUtils.get(_diningContentData, 'food_types')) : null;

  List<String>? get foodIngredients =>
    _enabled ? JsonUtils.listStringsValue(MapUtils.get(_diningContentData, 'food_ingredients')) : null;

  String? getLocalizedString(String? text) =>
    _enabled ? Localization().getStringFromMapping(text,  JsonUtils.mapValue(MapUtils.get(_diningContentData, 'strings'))) : null;

  Future<DiningFeedback?> loadDiningFeedback({String? diningId}) async {
    //return (_feedbacks ??= DiningFeedback.mapFromJson(JsonUtils.decodeMap(await AppBundle.loadString('assets/dining.feedbacks.json'))) ?? <String, DiningFeedback>{})[diningId];
    const String diningFeedbackCategory = 'dining_feedbacks';
    Map<String, DiningFeedback>? feedbacksMap = DiningFeedback.mapFromJson(JsonUtils.mapValue(await Content().loadContentItem(diningFeedbackCategory)));
    return (feedbacksMap != null) ? feedbacksMap[diningId] : null;
  }

  // Deep Links

  static String get diningDetailRawUrl => '${DeepLink().appUrl}/dining2_detail'; //TBD: => dining_detail
  static String eventDetailUrl(String diningId) => UrlUtils.buildWithQueryParameters(diningDetailRawUrl, <String, String>{
    'dining_id' : diningId
  });

  static String get diningQueryRawUrl => '${DeepLink().appUrl}/dining2_query'; //TBD: => dining_query
  static String diningQueryUrl(Map<String, String> params) => UrlUtils.buildWithQueryParameters(diningQueryRawUrl,
    params
  );

  void _onDeepLinkUri(Uri? uri) {
    if (uri != null) {
      if (uri.matchDeepLinkUri(Uri.tryParse(diningDetailRawUrl))) {
        try { NotificationService().notify(notifyLaunchDetail, uri.queryParameters.cast<String, dynamic>()); }
        catch (e) { print(e.toString()); }
      }
      else if (uri.matchDeepLinkUri(Uri.tryParse(diningQueryRawUrl))) {
        try { NotificationService().notify(notifyLaunchQuery, uri.queryParameters.cast<String, dynamic>()); }
        catch (e) { print(e.toString()); }
      }
    }
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

}

