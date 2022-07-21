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

import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as Core;
import 'package:illinois/ext/Dining.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/ui/dining/HorizontalDiningSpecials.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/ui/dining/FoodDetailPanel.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_tab.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:url_launcher/url_launcher.dart';

class ExploreDiningDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Dining? dining;
  final Core.Position? initialLocationData;

  ExploreDiningDetailPanel({this.dining, this.initialLocationData});

  @override
  _DiningDetailPanelState createState() => _DiningDetailPanelState(dining);

  @override
  Map<String, dynamic>? get analyticsPageAttributes => dining?.analyticsAttributes;
}

class _DiningDetailPanelState extends State<ExploreDiningDetailPanel> implements NotificationsListener {

  Dining? dining;

  _DiningDetailPanelState(this.dining);

  bool _isDiningLoading = false;

  //Maps
  Core.Position? _locationData;

  // Dining Worktime
  bool _diningWorktimeExpanded = false;

  // Dining Payment Types
  bool _diningPaymentTypesExpanded = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      LocationServices.notifyStatusChanged,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);

    _reloadDiningIfNeed();

    _addRecentItem();
    _locationData = widget.initialLocationData;
    _loadCurrentLocation().then((_){
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  void _reloadDiningIfNeed(){
    if(!dining!.hasDiningSchedules){
      _isDiningLoading = true;

      Dinings().loadBackendDinings(false, null, _locationData).then((List<Dining>? dinings){
        if(dinings != null){
          Dining? foundDining = Dining.entryInList(dinings, id: dining!.id);
          if(foundDining != null){
            dining = foundDining;
            _isDiningLoading = false;
            setState(() {});
          }
        }
      });
    }

  }

  Future<void> _loadCurrentLocation() async {
    _locationData = Auth2().privacyMatch(2) ? await LocationServices().location : null;
  }

  void _updateCurrentLocation() {
    _loadCurrentLocation().then((_){
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                child: CustomScrollView(
                  scrollDirection: Axis.vertical,
                  slivers: <Widget>[
                    
                    SliverToutHeaderBar(
                      flexImageUrl: dining?.exploreImageUrl,
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate(
                          [
                        Stack(
                          children: <Widget>[
                            Container(
                                color: Colors.white,
                                child: Column(
                                  children: <Widget>[
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Column(
                                          children: <Widget>[
                                            Padding(
                                                padding:
                                                EdgeInsets.only(right: 20, left: 20),
                                                child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: <Widget>[
                                                      _exploreTitle(),
                                                      _exploreDetails(),
                                                      _exploreSubTitle(),
                                                      _exploreDescription(),
                                                    ]
                                                )),
                                            _buildDiningDetail(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                            )
                          ],
                        )
                      ],addSemanticIndexes:false),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar(),
      );
  }

  Widget _exploreTitle() {
    bool starVisible = Auth2().canFavorite;
    bool isFavorite = Auth2().isFavorite(dining);
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                dining!.exploreTitle!,
                style: TextStyle(
                    fontSize: 24,
                    color: Styles().colors!.fillColorPrimary,
                    letterSpacing: 1),
              ),
            ),
            Visibility(visible: starVisible,child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: (){
                  Analytics().logSelect(target: "Favorite: ${dining?.title}");
                  Auth2().prefs?.toggleFavorite(dining);},
                child: Container( child: Semantics(
                    label: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                    hint: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                    button: true,
                    child:Padding(padding: EdgeInsets.only(left: 20, top: 10, bottom: 10), child: Image.asset(isFavorite?'images/icon-star-blue.png':'images/icon-star-gray-frame-thin.png', excludeFromSemantics: true))))
            ),),
          ],
        ));
  }

  Widget _exploreDetails() {
    List<Widget> details = [];

    Widget? location = _exploreLocationDetail();
    if (location != null) {
      details.add(location);
    }

    Widget? workTime = _exploreWorktimeDetail();
    if (workTime != null) {
      details.add(workTime);
    }

    Widget? paymentTypes = _explorePaymentTypes();
    if (paymentTypes != null) {
      details.add(paymentTypes);
    }

    Widget? orderOnline = _exploreOrderOnline();
    if (orderOnline != null) {
      details.add(orderOnline);
    }

    return (0 < details.length)
        ? Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details))
        : Container();
  }

  Widget? _explorePaymentTypes() {
    List<Widget>? details;
    List<PaymentType>? paymentTypes = dining?.paymentTypes;
    if ((paymentTypes != null) && (0 < paymentTypes.length)) {
      details = [];
      for (PaymentType? paymentType in paymentTypes) {
        Image? image = PaymentTypeHelper.paymentTypeIcon(paymentType);
        if (image != null) {
          details.add(Padding(padding: EdgeInsets.only(right: 6) ,child:
            Row(
              children: <Widget>[
                image,
                _diningPaymentTypesExpanded ? Container(width: 5,) : Container(),
                _diningPaymentTypesExpanded ? Text(PaymentTypeHelper.paymentTypeToDisplayString(paymentType)!) : Container()
              ],
            )
          ) );
        }
      }
    }
    return ((details != null) && (0 < details.length)) ?
        Semantics(
          excludeSemantics: true,
            label: Localization().getStringEx("panel.explore_detail.label.accepted_payments", "Accepted payments: ") + paymentsToString(paymentTypes),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _divider(),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(Localization().getStringEx("panel.explore_detail.label.accepted_payment", "Accepted Payment"),
                        style: TextStyle(
                          color: Styles().colors!.textBackground
                        ),
                      ),
                    ),
                    FilterSelector(
                      title: Localization().getStringEx("panel.explore_detail.label.accepted_payment_details","Details"),
                      padding: EdgeInsets.symmetric(vertical: 5),
                      active: _diningPaymentTypesExpanded,
                      onTap: _onDiningPaymentTypeTapped,
                    )
                  ],
                ),
                _diningPaymentTypesExpanded
                    ? GridView.count(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        childAspectRatio: 6,
                        crossAxisCount: 2,
                        children: details
                      )
                    : Padding(
                      padding: EdgeInsets.symmetric(vertical: 10,),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: details)
                )

              ]))

        : Container();
  }

  Widget? _exploreOrderOnline() {
    Map<String, dynamic>? onlineOrder = dining?.onlineOrder;
    if (onlineOrder == null) {
      return null;
    }
    Map<String, dynamic>? onlineOrderPlatformDetails;
    if (Platform.isAndroid) {
      onlineOrderPlatformDetails = onlineOrder['android'];
    } else if (Platform.isIOS) {
      onlineOrderPlatformDetails = onlineOrder['ios'];
    }
    if (onlineOrderPlatformDetails == null) {
      return null;
    }
    if (StringUtils.isEmpty(onlineOrderPlatformDetails['deep_link'])) {
      return null;
    }
    return Align(
      alignment: Alignment.centerRight,
      child: RoundedButton(
        label: Localization().getStringEx('panel.explore_detail.button.order_online', 'Order Online'),
        backgroundColor: Styles().colors!.white,
        borderColor: Styles().colors!.fillColorSecondary,
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _onTapOrderOnline(onlineOrderPlatformDetails),
      ),
    );
  }

  String paymentsToString(List<PaymentType>? payments){
    String result = "";
    final String paymentTypePrefix = "PaymentType.";
    if(CollectionUtils.isNotEmpty(payments)) {
      payments!.forEach((payment) {
        String paymentType = payment.toString();
        if (paymentType.startsWith(paymentTypePrefix) && (paymentTypePrefix.length < paymentType.length)) {
          result += paymentType.substring(paymentTypePrefix.length, paymentType.length) + "\n";
        }
      });
    }

    //print("Semantics: paymentsToString= $result");
    return result;
  }

  Widget _divider(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0),
      child: Container(
        height: 1,
        color: Styles().colors!.fillColorPrimaryTransparent015,
      ),
    );
  }

  Widget? _exploreLocationDetail() {
    String? locationText = dining?.getLongDisplayLocation(_locationData);
    if ((locationText != null) && locationText.isNotEmpty) {
      return GestureDetector(
        onTap: _onLoacationDetailTapped,
        child: Semantics(
          label: locationText,
          hint: Localization().getStringEx('panel.explore_detail.button.directions.hint', ''),
          button: true,
          excludeSemantics: true,
          child:Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 10),
                  child:Image.asset('images/icon-location.png', excludeFromSemantics: true),
                ),
                Expanded(child: Text(locationText,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies!.medium,
                        fontSize: 16,
                        color: Styles().colors!.textBackground))),
              ],
            ),
          )
        ),
      );
    } else {
      return null;
    }
  }

  Widget? _exploreWorktimeDetail() {
    bool hasAdditionalInformation = dining?.diningSchedules != null && (dining?.diningSchedules?.isNotEmpty ?? false) && (dining?.firstOpeningDateSchedules.isNotEmpty?? false);
    String? displayTime = dining?.displayWorkTime;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Padding(
          padding: EdgeInsets.only(bottom: 11),
          child:Semantics(
            container: true,
          child:Column(
                children: <Widget>[
              Semantics(
              excludeSemantics: true,
              label: displayTime,
              button: hasAdditionalInformation? true : null,
              hint: hasAdditionalInformation?Localization().getStringEx("panel.explore_detail.button.wirking_detail.hint","activate to show more details") : "",
              child:
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 10),
                        child:Image.asset('images/icon-time.png', excludeFromSemantics: true),),
                      Expanded(child:
                        FilterSelector(
                          title: displayTime,
                          padding: EdgeInsets.symmetric(vertical: 5),
                          expanded: true,
                          active: _diningWorktimeExpanded,
                          onTap: _onDiningWorktimeTapped,
                        )
                      )
                    ],
                  )),
                  Semantics(
                    explicitChildNodes: true,
                      child: _exploreWorktimeFullDetail(),
                  )
                ],
          )),
      );
    } else {
      return Container();
    }
  }

  Widget _exploreWorktimeFullDetail() {
    if(dining?.diningSchedules != null && dining!.diningSchedules!.isNotEmpty && _diningWorktimeExpanded){

      List<Widget> widgets = [];
      List<DiningSchedule> schedules = dining!.firstOpeningDateSchedules;
      if(schedules.isNotEmpty){

        for(DiningSchedule schedule in schedules){
          String? meal = schedule.meal;
          String mealDisplayTime = schedule.displayWorkTime;
          String timeHint = "From: "+schedule.getDisplayTime(", to: ");
          if(schedule.isOpen || schedule.isFuture) {
            widgets.add(Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child:
                Semantics(container:true, child:
                  Row(
                    children: <Widget>[
                      Expanded(child:
                      Text(meal!,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies!.regular,
                            fontSize: 15,
                            color: Styles().colors!.textBackground
                        ),
                      ),),
                      Expanded(
                        child: Semantics( excludeSemantics: true, label: timeHint,
                          child: Text(mealDisplayTime,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontFamily: Styles().fontFamilies!.regular,
                              fontSize: 15,
                              color: Styles().colors!.textBackground
                          ),
                        ),
                      ))
                    ],
                  ))
            ));
          }
        }
      }

      return Padding(
        padding: const EdgeInsets.only(left: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            widgets.isNotEmpty ? Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgets
            ) : Container(),
          ],
        ),
      );
    }
    return Container();
  }

  Widget _exploreSubTitle() {
    String? subTitle = dining!.exploreSubTitle;
    if (StringUtils.isEmpty(subTitle)) {
      return Container();
    }
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          subTitle!,
          style: TextStyle(
              fontSize: 20,
              color: Styles().colors!.textBackground),
        ));
  }

  Widget _exploreDescription() {
    String? longDescription = dining!.exploreLongDescription;
    bool showDescription = StringUtils.isNotEmpty(longDescription);
    if (!showDescription) {
      return Container();
    }
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Html(
          data: dining!.exploreLongDescription,
          onLinkTap: (url, renderContext, attributes, element) => _launchUrl(url, context: context),
          style: { "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(16), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
        ));
  }

  Widget _buildDiningDetail(){
    return _isDiningLoading ? Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            ],
          ) : _DiningDetail(dining: dining,);
  }

  void _addRecentItem(){
    RecentItems().addRecentItem(RecentItem.fromSource(dining));
  }

  void _onDiningWorktimeTapped(){
    Analytics().logSelect(target: "Dining Work Time");
    _diningWorktimeExpanded = !_diningWorktimeExpanded;
    setState(() {});
  }

  void _onDiningPaymentTypeTapped(){
    Analytics().logSelect(target: "Dining Payment Type");
    _diningPaymentTypesExpanded = !_diningPaymentTypesExpanded;
    setState(() {});
  }

  void _onLoacationDetailTapped(){
    Analytics().logSelect(target: "Location Detail");
    NativeCommunicator().launchExploreMapDirections(target: dining);
  }

  void _onTapOrderOnline(Map<String, dynamic>? orderOnlineDetails) async {
    String? deepLink = (orderOnlineDetails != null) ? orderOnlineDetails['deep_link'] : null;
    if (StringUtils.isEmpty(deepLink)) {
      return;
    }
    bool? appLaunched = await RokwirePlugin.launchApp({"deep_link": deepLink});
    if (appLaunched != true) {
      String storeUrl = orderOnlineDetails!['store_url'];
      url_launcher.launch(storeUrl);
    }
  }

  void _launchUrl(String? url, {BuildContext? context}) {
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context!, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url!);
      }
    }
  }

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == LocationServices.notifyStatusChanged) {
      _updateCurrentLocation();
    }
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      _updateCurrentLocation();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setState(() {});
    }
  }
}

class _DiningDetail extends StatefulWidget {

  final Dining? dining;

  _DiningDetail({required this.dining});

  _DiningDetailState createState() => _DiningDetailState();
}

class _DiningDetailState extends State<_DiningDetail> implements NotificationsListener {

  List<DiningSpecial>? _specials;

  List<DiningSchedule>? __schedules;
  int _selectedScheduleIndex = -1;

  List<String>? _displayDates;
  List<DateTime>? _filterDates;
  int _selectedDateFilterIndex = 0;

  List<DiningProductItem>? _productItems;
  late Map<String,DiningProductItem> _productItemsMapping;

  bool _isLoading = false;

  @override
  void initState() {
    NotificationService().subscribe(this, Auth2UserPrefs.notifyFoodChanged);

    _displayDates = widget.dining?.displayScheduleDates;
    _filterDates = widget.dining?.filterScheduleDates;

    _findTodayFilter();

    bool hasDisplayDates = (_displayDates != null && _displayDates!.isNotEmpty);
    String? currentDate = hasDisplayDates ? _displayDates![_selectedDateFilterIndex] : null;
    _schedules = (hasDisplayDates && (currentDate != null)) ? widget.dining!.displayDateScheduleMapping[currentDate] : [];

    _loadProductItems();
    _loadOffers();
    super.initState();
  }

  @override
  void dispose(){
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  void _findTodayFilter(){
    DateTime nowUtc = DateTime.now().toUtc();
    if(_displayDates != null) {
      for(String dateString in _displayDates!){
        List<DiningSchedule> schedules = widget.dining!.displayDateScheduleMapping[dateString]!;
        for(DiningSchedule schedule in schedules){
          if(nowUtc.isBefore(schedule.endTimeUtc!)){
            _selectedDateFilterIndex = _displayDates!.indexOf(dateString);
            return;
          }
        }
      }
    }
    _selectedDateFilterIndex = 0;
  }

  void _findCurrentSchedule(){
    if(__schedules != null && __schedules!.isNotEmpty){
      var nowUtc = DateTime.now().toUtc();
      bool found = false;
      for(int i = 0; i < __schedules!.length; i++){
        DiningSchedule schedule = __schedules![i];
        if(nowUtc.isBefore(schedule.startTimeUtc!) || nowUtc.isBefore(schedule.endTimeUtc!)){
          _selectedScheduleIndex = i;
          found = true;
          break;
        }
      }

      if(!found){
        _selectedScheduleIndex = 0;
      }
    }
    else{
      _selectedScheduleIndex = -1;
    }
  }

  bool get hasMenuData{
    return _filterDates != null && _filterDates!.isNotEmpty && _schedules != null && _schedules!.isNotEmpty;
  }

  void _loadOffers(){
    Dinings().loadDiningSpecials().then((List<DiningSpecial>? offers){
      if(offers != null && offers.isNotEmpty){
        _specials = offers.where((entry)=>entry.locationIds!.contains(widget.dining!.id)).toList();
        setState((){});
      }
    });
  }

  void _loadProductItems(){
    if(hasMenuData) {
      _isLoading = true;
      DateTime? filterDate = _filterDates![_selectedDateFilterIndex];
      Dinings().loadMenuItemsForDate(widget.dining!.id, filterDate).then((
          List<DiningProductItem>? items) {
        _productItems = items;
        _productItemsMapping = Map<String, DiningProductItem>();
        _productItems!.forEach((DiningProductItem item) {
          if (item.itemID != null) {
            _productItemsMapping[item.itemID!] = item;
          }
        });

        _isLoading = false;
        if(mounted) {
          setState(() {});
        }
      });
    }
  }

  void _onTapTab(RoundedTab tab){
    Analytics().logSelect(target: "Tab: ${tab.title}");
    _selectedScheduleIndex = tab.tabIndex;
    if(mounted) {
      setState(() {});
    }
  }

  void _onFoodFilersTapped(){
    Analytics().logSelect(target: "Food filters");
    SettingsHomeContentPanel.present(context, content: SettingsContent.food_filters);
  }


  List<DiningSchedule>? get _schedules{
    return __schedules;
  }

  set _schedules(List<DiningSchedule>? schedules){
    __schedules = schedules;
    _findCurrentSchedule();
  }

  void incrementDateFilter(){
    Analytics().logSelect(target: "Increment Date filter");
    if(_selectedDateFilterIndex < _filterDates!.length - 1) {
      _selectedDateFilterIndex++;

      String? displayDate = (_displayDates != null) ? _displayDates![_selectedDateFilterIndex] : null;
      _schedules = widget.dining!.displayDateScheduleMapping[displayDate];

      _loadProductItems();

      if(mounted) {
        setState(() {});
      }
    }
  }

  void decrementDateFilter(){
    Analytics().logSelect(target: "Decrement Date filter");
    if(_selectedDateFilterIndex > 0) {
      _selectedDateFilterIndex--;

      String? displayDate = (_displayDates != null) ? _displayDates![_selectedDateFilterIndex] : null;
      _schedules = widget.dining!.displayDateScheduleMapping[displayDate];

      _loadProductItems();
      if(mounted) {
        setState(() {});
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    bool hasFoodFilterApplied = Auth2().prefs?.hasFoodFilters ?? false;
    return hasMenuData ?
    Container(
        color: Styles().colors!.background,
        child: Column(
          children: <Widget>[
            Container(
              color: Styles().colors!.background,
              height: 1,
            ),
            HorizontalDiningSpecials(locationId: widget.dining!.id, specials: _specials,),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Text(Localization().getStringEx("widget.food_detail.label.menu.title", "Menu"),
                      style: TextStyle(
                        fontFamily: Styles().fontFamilies!.bold,
                        fontSize: 16,
                        color: Styles().colors!.fillColorPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child:
                    Semantics(
                      label: hasFoodFilterApplied
                          ? Localization().getStringEx("widget.food_detail.button.filters_applied.title", "Food Filters Applied")
                          : Localization().getStringEx("widget.food_detail.button.filters_empty.title", "Add Food Filters"),
                      hint: hasFoodFilterApplied
                          ? Localization().getStringEx("widget.food_detail.button.filters_applied.hint", "")
                          : Localization().getStringEx("widget.food_detail.button.filters_empty.hint", ""),
                      button: false,
                      child: GestureDetector(
                        onTap: _onFoodFilersTapped,
                        child: Container(
                          child: Row(
                            children: <Widget>[
                              Expanded(child:
                              Text(hasFoodFilterApplied
                                  ? Localization().getStringEx("widget.food_detail.button.filters_applied.title", "Food Filters Applied")
                                  : Localization().getStringEx("widget.food_detail.button.filters_empty.title", "Add Food Filters"),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: Styles().colors!.fillColorPrimary,
                                    fontFamily: Styles().fontFamilies!.regular,
                                    fontSize: 16
                                ),
                              )),
                              Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Image.asset('images/chevron-right.png', excludeFromSemantics: true),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      (_displayDates != null) ? _displayDates![_selectedDateFilterIndex] : '',
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies!.extraBold,
                          fontSize: 20,
                          color: Styles().colors!.fillColorPrimary
                      ),
                    ),
                  ),
                  Semantics(
                    label: Localization().getStringEx("widget.food_detail.button.prev_menu.title", "Previous dining date"),
                    hint: Localization().getStringEx("widget.food_detail.button.prev_menu.hint", ""),
                    excludeSemantics: true,
                    child: _CircularButton(
                      image: Image.asset('images/chevron-left.png', excludeFromSemantics: true),
                      onTap: decrementDateFilter,
                    ),
                  ),
                  Container(width: 15,),
                  Semantics(
                    label: Localization().getStringEx("widget.food_detail.button.next_menu.title", "Next dining date"),
                    hint: Localization().getStringEx("widget.food_detail.button.next_menu.hint", ""),
                    excludeSemantics: true,
                    child: _CircularButton(
                      image: Image.asset('images/chevron-right.png', excludeFromSemantics: true),
                      onTap: incrementDateFilter,
                    ),
                  ),
                ],
              ),
            ),
            Padding(padding: EdgeInsets.all(16), child: 
              SingleChildScrollView(scrollDirection: Axis.horizontal, child:
                Row(children: _buildScheduleTabs(),),
              ),
            ),
            _buildScheduleWorkTime(),
            _isLoading
                ? Semantics(
              label: Localization().getStringEx("widget.food_detail.label.loading.title", "Loading menu data"),
              hint: Localization().getStringEx("widget.food_detail.label.loading.hint", ""),
              button: false,
              child: Column(
                children: <Widget>[
                  CircularProgressIndicator(),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(Localization().getStringEx("widget.food_detail.label.loading.title", "Loading menu data")),
                  )
                ],
              ),
            )
                : Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(
                            Radius.circular(8)),
                        child: Column(
                          children: _buildStations(),
                        ),
                      ),
                    ),
                    Container(height: 20),
                  ],
                ),
              ],
            ),
          ],
        )) : Container(
      child: Text('No menu data'),
    );
  }


  List<Widget> _buildScheduleTabs() {
    List<Widget> tabs = [];
    for (int i = 0; i < _schedules!.length; i++) {
      DiningSchedule schedule = _schedules![i];
      tabs.add(Padding(padding: EdgeInsets.only(right: 8), child: RoundedTab(title: schedule.meal, tabIndex: i, onTap: _onTapTab, selected: (i == _selectedScheduleIndex))));
    }

    return tabs;
  }

  List<Widget> _buildStations(){
    List<Widget> list = [];
    if(_productItems != null && _productItems!.isNotEmpty && _selectedScheduleIndex > -1) {
      List<DiningProductItem> mealProducts = DiningUtils.getProductsForScheduleId(
          _productItems,
          _schedules![_selectedScheduleIndex].scheduleId,
          Auth2().prefs?.includedFoodTypes,
          Auth2().prefs?.excludedFoodIngredients
      );
      Map<String, List<DiningProductItem>> productStationMapping = DiningUtils
          .getCategoryGroupedProducts(mealProducts);

      if (_productItems != null && _productItems!.isNotEmpty) {
        List<String> stations = productStationMapping.keys.toList();

        for(String? stationName in stations){
          List<DiningProductItem> products = productStationMapping[stationName]!;

          if (products.isNotEmpty) {

            if (list.isNotEmpty) {
              list.add(Container(height: 1, color: Styles().colors!.white,));
            }

            list.add(
              _StationItem(
                title: stationName,
                productItems: products,
                defaultExpanded: (list.length < 1),
              ),
            );
          }
        }
      }
    }

    if(list.isEmpty){
      list.add(Semantics(
        label: Localization().getStringEx("widget.food_detail.label.no_entries_for_desired_filter.title", "There are no entries according to the current filter"),
        hint: Localization().getStringEx("widget.food_detail.label.no_entries_for_desired_filter.hint", ""),
        button: false,
        child: Padding(padding: EdgeInsets.symmetric(vertical: 20,),
          child: Text(Localization().getStringEx("widget.food_detail.button.no_entries_for_desired_filter.title", "There are no entries according to the current filter"),),
        ),
      ));
    }
    return list;
  }

  Widget _buildScheduleWorkTime(){
    String workTimeDisplayText = (_selectedScheduleIndex > -1 && __schedules != null && __schedules!.length >= _selectedScheduleIndex)
        ? (__schedules![_selectedScheduleIndex].displayWorkTime)
        : "";
    return workTimeDisplayText.isNotEmpty ? Column(
      children: <Widget>[
        Center(
          child: Text(workTimeDisplayText,
            style: TextStyle(
                fontFamily: Styles().fontFamilies!.regular,
                color: Styles().colors!.fillColorPrimary,
                fontSize: 14
            ),
          ),
        ),
        Container(height: 10,),
      ],
    ) : Container();
  }

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFoodChanged) {
      if (mounted) {
        setState(() {});
      }
    }
  }
}

class _StationItem extends StatefulWidget {
  final String? title;
  final List<DiningProductItem> productItems;
  final bool defaultExpanded;

  const _StationItem({
    required this.title,
    required this.productItems,
    this.defaultExpanded = false,
  });

  _StationItemState createState() => _StationItemState(expanded: defaultExpanded);
}

class _StationItemState extends State<_StationItem>{

  bool? expanded;

  _StationItemState({this.expanded});

  void onTap(){
    Analytics().logSelect(target: "Station Item: ${widget.title}");
    if(mounted) {
      setState(() {
        expanded = !expanded!;
      });
    }
  }

  void _onProductItemTapped(DiningProductItem productItem){
    Analytics().logSelect(target: "Product Item: "+productItem.name!);
    Navigator.push(context, CupertinoPageRoute(
        builder: (context) => FoodDetailPanel(productItem: productItem,)
    ));
  }

  @override
  Widget build(BuildContext context){
    return Column(
      children: <Widget>[
        Semantics(
          label: widget.title,
          hint: expanded!
              ? Localization().getStringEx("widget.food_detail.button.dining_station.expanded.hint","Double tap to collaps")
              : Localization().getStringEx("widget.food_detail.button.dining_station.collapsed.hint","Double tap to expand"),
          value: expanded!
              ? Localization().getStringEx("widget.food_detail.button.dining_station.value.expanded","Expanded")
              : Localization().getStringEx("widget.food_detail.button.dining_station.value.collapsed","Collapsed"),
          button: true,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              color: Styles().colors!.fillColorPrimary,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies!.bold,
                            fontSize: 16,
                            color: Colors.white
                        ),
                      ),
                    ),
                    expanded! ? Image.asset('images/chevron-down.png', excludeFromSemantics: true) : Image.asset('images/chevron-up.png', excludeFromSemantics: true)
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildExpandedWidget(),
      ],
    );
  }

  Widget _buildExpandedWidget(){
    return (widget.productItems.isNotEmpty && expanded!) ?  Container(
        decoration: BoxDecoration(
            border: Border(
                left: BorderSide(color: Styles().colors!.surfaceAccent!),
                right: BorderSide(color: Styles().colors!.surfaceAccent!)
            )
        ),
        child: Column(
          children: _createExpandedItems(),
        )
    ) : Container();
  }

  List<Widget> _createExpandedItems(){
    List<Widget> list = [];
    list.add(Container(height: 1, color: Styles().colors!.surfaceAccent,));
    for(DiningProductItem productItem in widget.productItems){
      list.add(_ProductItem(
        productItem: productItem,
        onTap: (){_onProductItemTapped(productItem);},
      ));
      list.add(Container(height: 1, color: Styles().colors!.surfaceAccent,));
    }
    return list;
  }
}

class _ProductItem extends StatelessWidget {
  final DiningProductItem? productItem;
  final GestureTapCallback? onTap;
  _ProductItem({this.productItem, this.onTap});



  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: productItem!.name,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    productItem!.name!,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies!.bold,
                        fontSize: 16,
                        color: Styles().colors!.fillColorPrimary
                    ),
                  ),
                ),
                Image.asset('images/chevron-right.png', excludeFromSemantics: true)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularButton extends StatelessWidget{
  final Image image;
  final GestureTapCallback? onTap;

  _CircularButton({required this.image, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Styles().colors!.fillColorSecondary!, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        height: 40,
        width: 40,
        child: image,
      ),
    );
  }
}