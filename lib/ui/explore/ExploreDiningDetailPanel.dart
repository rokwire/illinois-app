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
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart' as Core;
import 'package:illinois/ext/Dining.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/ui/dining/HorizontalDiningSpecials.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/location_services.dart';
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
import 'package:url_launcher/url_launcher.dart';

class ExploreDiningDetailPanel extends StatefulWidget with AnalyticsInfo {
  final Dining dining;
  final Core.Position? initialLocationData;
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  ExploreDiningDetailPanel(this.dining, { this.initialLocationData, this.analyticsFeature});

  @override
  _DiningDetailPanelState createState() => _DiningDetailPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes => dining.analyticsAttributes;
}

class _DiningDetailPanelState extends State<ExploreDiningDetailPanel> with NotificationsListener {

  late Dining _dining;
  bool _isDiningLoading = false;

  DiningFeedback? _diningFeedback;
  bool _isDiningFeedbackLoading = false;

  //Maps
  Core.Position? _locationData;

  // Dining Worktime
  bool _diningWorktimeExpanded = false;

  // Dining Worktime
  bool _diningAdditionalInfoExpanded = false;

  // Dining Payment Types
  bool _diningPaymentTypesExpanded = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFoodChanged,
      LocationServices.notifyStatusChanged,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged
    ]);
    
    _dining = widget.dining;

    _reloadDiningIfNeed();
    _loadDiningFeedback();

    _addRecentItem();
    _locationData = widget.initialLocationData;
    _loadCurrentLocation().then((_) {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFoodChanged) {
      setStateIfMounted();
    }
    else if (name == LocationServices.notifyStatusChanged) {
      _updateCurrentLocation();
    }
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      setStateIfMounted();
      _updateCurrentLocation();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted();
    }
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted();
      _updateCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
      body: Column(children: <Widget>[
        Expanded(child:
          CustomScrollView(scrollDirection: Axis.vertical, slivers: <Widget>[
            SliverToutHeaderBar(
              flexImageUrl: _dining.exploreImageUrl,
              flexRightToLeftTriangleColor: Styles().colors.white,
            ),
            SliverList(delegate: SliverChildListDelegate([
              Container(color: Colors.white, child:
                Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Padding(padding: EdgeInsets.only(right: 20, left: 20), child:
                    Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      _exploreTitle(),
                      _exploreDetails(),
                    ])
                  ),
                ],),
              ),
              Padding(padding: EdgeInsets.only(right: 20, left: 20, top: 16), child:
                Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  _exploreOrderOnline() ?? Container(),
                  _buildDiningFeedback(),
              ])),
              _buildDiningDetail(),
            ], addSemanticIndexes:false),),
          ],),
        ),
      ],),
    );
  }

  Widget _exploreTitle() {
    bool starVisible = Auth2().canFavorite;
    bool isFavorite = Auth2().isFavorite(_dining);
    return Padding(padding: EdgeInsets.only(top: 8), child:
      Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        Expanded(child:
          Text(_dining.exploreTitle ?? '', style: Styles().textStyles.getTextStyle("common.panel.title")),
        ),
        Visibility(visible: starVisible, child:
          GestureDetector(behavior: HitTestBehavior.opaque, onTap: _onFavorite, child:
            Semantics(button: true,
              label: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
              hint: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx('widget.card.button.favorite.on.hint', ''), child:
                Padding(padding: EdgeInsets.only(left: 20, top: 10, bottom: 10), child:
                  Styles().images.getImage(isFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true)
                )
            )
          ),
        ),
      ],)
    );
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

    Widget? additionalInfo =_exploreAdditionalLocationDetail();
    if(additionalInfo != null){
      details.add(additionalInfo);
    }

    return (0 < details.length) ? Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
      Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: details)) : Container();
  }

  Widget? _explorePaymentTypes() {
    List<Widget>? details;
    List<PaymentType>? paymentTypes = _dining.paymentTypes;
    if ((paymentTypes != null) && (0 < paymentTypes.length)) {
      details = [];
      for (PaymentType paymentType in paymentTypes) {
        Widget? image = paymentType.iconWidget;
        if (image != null) {
          details.add(Padding(padding: EdgeInsets.only(right: 6), child:
            Row(children: <Widget>[
              image,
              _diningPaymentTypesExpanded ? Container(width: 5,) : Container(),
              _diningPaymentTypesExpanded ? Text(paymentType.displayTitle) : Container()
            ],)
          ));
        }
      }
    }
    return ((details != null) && (0 < details.length)) ?
        Semantics(excludeSemantics: true, label: Localization().getStringEx("panel.explore_detail.label.accepted_payments", "Accepted payments: ") + paymentsToString(paymentTypes), child:
          Padding(padding: EdgeInsets.only(bottom: 8), child:
          Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            // _divider(),
            Row(children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 6), child:
                Styles().images.getImage('cost', excludeFromSemantics: true, size: 17)
              ),
              // Expanded(child:
              //   Text(Localization().getStringEx("panel.explore_detail.label.accepted_payment", "Accepted Payment"), style: Styles().textStyles.getTextStyle("widget.item.small.thin")),
              // ),
              Expanded(
                child: FilterSelector(
                  title: Localization().getStringEx("panel.explore_detail.label.accepted_payment", "Accepted payment details"), //Localize
                  padding: EdgeInsets.zero,
                  titleTextStyle: Styles().textStyles.getTextStyle("widget.item.regular"),
                  active: _diningPaymentTypesExpanded,
                  onTap: _onDiningPaymentTypeTapped,
                )
              )
            ],),
            _diningPaymentTypesExpanded ? GridView.count(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              childAspectRatio: 6,
              crossAxisCount: 2,
              children: details
            ) : Container(),
            // : Padding(padding: EdgeInsets.symmetric(vertical: 10,), child:
            //   Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: details)
            // )
            Container(height: 8),
            _divider(),
          ]))
        ) : Container();
  }

  Widget? _exploreOrderOnline() {
    Map<String, dynamic>? onlineOrder = _dining.onlineOrder;
    Map<String, dynamic>? platformDetails = (onlineOrder != null) ? (JsonUtils.mapValue(onlineOrder[Platform.operatingSystem]) ?? onlineOrder) : null;
    String? deepLinkUrl = (platformDetails != null) ? JsonUtils.stringValue(platformDetails['deep_link']) : null;
    String? storeUrl = (platformDetails != null) ? JsonUtils.stringValue(platformDetails['store_url']) : null;

    return ((deepLinkUrl != null) && deepLinkUrl.isNotEmpty) ? Align(alignment: Alignment.center, child:
      SmallRoundedButton(
        label: Localization().getStringEx('panel.explore_detail.button.order_online', 'Order Online'),
        textStyle: Styles().textStyles.getTextStyle("widget.button.title.regular"),
        backgroundColor: Styles().colors.white,
        borderColor: Styles().colors.fillColorSecondary,
        rightIcon: Container(),
        rightIconPadding: EdgeInsets.only(right: 12),
        leftIconPadding: EdgeInsets.only(left: 12),
        onTap: () => _onTapOrderOnline(deepLinkUrl, storeUrl: storeUrl),
      ),
    ) : null;
  }

  String paymentsToString(List<PaymentType>? payments) {
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

  Widget _divider() {
    return Padding(padding: EdgeInsets.symmetric(vertical: 0), child:
      Container(height: 1, color: Styles().colors.fillColorPrimaryTransparent015,),
    );
  }

  Widget? _exploreLocationDetail() {
    String? locationText = _dining.getLongDisplayLocation(_locationData);
    String? locationHint = Localization().getStringEx('panel.explore_detail.button.directions.hint', '');
    if ((locationText != null) && locationText.isNotEmpty) {
      return GestureDetector(onTap: _onLoacationDetailTapped, child:
        Semantics(label: locationText, hint: locationHint, button: true, excludeSemantics: true, child:
          Padding(padding: EdgeInsets.only(bottom: 12), child:
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 4), child:
                Styles().images.getImage('location', excludeFromSemantics: true),
              ),
              Expanded(child:
                Text(locationText, style: Styles().textStyles.getTextStyle("widget.item.regular_underline"))
              ),],
            ),
          )
        ),
      );
    } else {
      return null;
    }
  }

  Widget? _exploreWorktimeDetail() {
    bool hasAdditionalInformation = _dining.diningSchedules != null && (_dining.diningSchedules?.isNotEmpty ?? false) && (_dining.firstOpeningDateSchedules.isNotEmpty);
    String? displayTime = _dining.displayWorkTime;
    String displayHint = hasAdditionalInformation ? Localization().getStringEx("panel.explore_detail.button.wirking_detail.hint","activate to show more details") : "";
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Padding(padding: EdgeInsets.only(bottom: 8), child:
        Semantics(container: true, child:
          Column(children: <Widget>[
            Semantics(excludeSemantics: true, label: displayTime, hint: displayHint, button: hasAdditionalInformation? true : null, child:
              Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                Padding(padding: EdgeInsets.only(right: 6), child:
                  Styles().images.getImage('time', excludeFromSemantics: true, size: 17)
                ),
                Expanded(child:
                  FilterSelector(
                    title: displayTime,
                    titleTextStyle: Styles().textStyles.getTextStyle("widget.item.regular"),
                    padding: EdgeInsets.zero,
                    expanded: true,
                    active: _diningWorktimeExpanded,
                    onTap: _onDiningWorktimeTapped,
                  )
                )
              ],)
            ),
            Semantics(explicitChildNodes: true, child:
              _exploreWorktimeFullDetail(),
            ),
            Container(height: 8,),
            _divider(),
          ],)
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _exploreWorktimeFullDetail() {
    if (_dining.diningSchedules != null && _dining.diningSchedules!.isNotEmpty && _diningWorktimeExpanded) {

      List<Widget> widgets = [];
      List<DiningSchedule> schedules = _dining.firstOpeningDateSchedules;
      if (schedules.isNotEmpty) {

        for (DiningSchedule schedule in schedules) {
          String? meal = schedule.meal;
          String mealDisplayTime = schedule.displayWorkTime;
          String timeHint = "From: "+schedule.getDisplayTime(", to: ");
          if (schedule.isOpen || schedule.isFuture) {
            widgets.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child:
              Semantics(container:true, child:
                Row(children: <Widget>[
                  Expanded(child:
                    Text(meal!, textAlign: TextAlign.start, style: Styles().textStyles.getTextStyle("widget.item.regular.thin")),
                  ),
                  Expanded(child:
                    Semantics(excludeSemantics: true, label: timeHint, child:
                      Text(mealDisplayTime, textAlign: TextAlign.end, style: Styles().textStyles.getTextStyle("widget.item.regular.thin")),
                    )
                  )
                ],)
              )
            ));
          }
        }
      }

      return Padding(padding: const EdgeInsets.only(left: 30), child:
        Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          widgets.isNotEmpty ? Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: widgets) : Container(),
        ],),
      );
    }
    return Container();
  }

  Widget? _exploreAdditionalLocationDetail() {
    bool hasAdditionalInformation = _dining.diningSchedules != null && (_dining.diningSchedules?.isNotEmpty ?? false) && (_dining.firstOpeningDateSchedules.isNotEmpty);
    String? title = "More about this location";
    String displayHint = hasAdditionalInformation ? Localization().getStringEx("panel.explore_detail.button.wirking_detail.hint","activate to show more details") : "";
    if (StringUtils.isNotEmpty(_dining.description)) {
      return Padding(padding: EdgeInsets.only(bottom: 0), child:
      Semantics(container: true, child:
      Column(children: <Widget>[
        Semantics(excludeSemantics: true, label: title, hint: displayHint, button: hasAdditionalInformation? true : null, child:
          Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Padding(padding: EdgeInsets.only(right: 6), child:
              Styles().images.getImage('info', excludeFromSemantics: true, size: 17)
            ),
            Expanded(child:
              FilterSelector(
                title: title,
                titleTextStyle: Styles().textStyles.getTextStyle("widget.item.regular"),
                padding: EdgeInsets.zero,
                expanded: true,
                active: _diningAdditionalInfoExpanded,
                onTap: _onDiningAdditionalInfoTapped,
              )
            )
          ],)
        ),
        Semantics(explicitChildNodes: true, child:
          _exploreAdditionalInfoFullDetail(),
        ),
        Container(height: 8,),
        // _divider(),
      ],)
      ),
      );
    } else {
      return Container();
    }
  }

  Widget _exploreAdditionalInfoFullDetail(){
    if(_diningAdditionalInfoExpanded == true) {
      return Container(child: _exploreDescription());
    }

    return Container();
  }

  Widget _exploreDescription() {
    String? description = _dining.description;
    bool showDescription = StringUtils.isNotEmpty(description);
    return showDescription ? Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
      HtmlWidget(
        StringUtils.ensureNotEmpty(description),
        onTapUrl : (url) {_launchUrl(url, 'Description'); return true;},
        textStyle:  Styles().textStyles.getTextStyle("widget.item.regular.thin"),
      )
    ) : Container();
  }

  Widget _buildDiningDetail() {
    return _isDiningLoading ? Row(children: <Widget>[
      Expanded(child:
        Center(child:
          Padding(padding: const EdgeInsets.all(16.0), child:
            CircularProgressIndicator(),
          )
        )
      )
    ],) : _DiningDetail(_dining);
  }

  Widget _buildDiningFeedback() {
    if (_diningFeedback?.isNotEmpty ?? false) {
      return Padding(padding: EdgeInsets.only(top: 10, bottom: 20), child:
        Column(children: [
          Text(Localization().getStringEx('panel.explore_detail.label.text_and_tell', 'Text and tell us about your dining experience!'), textAlign: TextAlign.center, style:
              Styles().textStyles.getTextStyle("widget.message.regular.fat")),
          Container(height: 10,),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              StringUtils.isNotEmpty(_diningFeedback?.feedbackUrl) ? SmallRoundedButton(
                label: Localization().getStringEx('panel.explore_detail.button.text_feedback', 'Text Feedback'),
                backgroundColor: Styles().colors.white,
                borderColor: Styles().colors.fillColorSecondary,
                textStyle: Styles().textStyles.getTextStyle("widget.title.regular.fat"),
                rightIcon: Container(),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                onTap: () => _onTapTextFeedback(),
              ) : Container(),
            Container(width: 10,),
              StringUtils.isNotEmpty(_diningFeedback?.dieticianUrl) ? SmallRoundedButton(
                label: Localization().getStringEx('panel.explore_detail.button.ask_dietician', 'Ask a Dietitian'),
                backgroundColor: Styles().colors.white,
                borderColor: Styles().colors.fillColorSecondary,
                textStyle: Styles().textStyles.getTextStyle("widget.title.regular.fat"),
                rightIcon: Container(),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                onTap: () => _onTapAskDietician(),
              ) : Container()
          ],)
        ],)
      );
    }
    else if (_isDiningFeedbackLoading) {
      return Row(children: <Widget>[
        Expanded(child:
          Center(child:
            Padding(padding: const EdgeInsets.symmetric(vertical: 24.0), child:
              CircularProgressIndicator(),
            )
          )
        )
      ],);
    }
    else {
      return Container();
    }
  }

  Future<void> _reloadDiningIfNeed() async {
    if ((_dining.hasDiningSchedules != true) && mounted) {
      setState(() {
        _isDiningLoading = true;
      });

      List<Dining>? dinings = await Dinings().loadFilteredDinings(location: _locationData);
      if (mounted) {
        setState(() {
          Dining? foundDining = DiningUtils.entryInList(dinings, id: _dining.id);
          if (foundDining != null) {
            _dining = foundDining;
          }
          _isDiningLoading = false;
        });
      }
    }
  }

  void _loadDiningFeedback() {
    if (_dining.id != null) {
      _isDiningFeedbackLoading = true;
      Dinings().loadDiningFeedback(diningId: widget.dining.id).then((DiningFeedback? diningFeedback) {
        if (mounted) {
          setState(() {
            _diningFeedback = diningFeedback;
            _isDiningFeedbackLoading = false;
          });
        }
      });
    }
  }


  Future<void> _loadCurrentLocation() async {
    _locationData = FlexUI().isLocationServicesAvailable ? await LocationServices().location : null;
  }

  void _updateCurrentLocation() {
    _loadCurrentLocation().then((_) {
      setStateIfMounted();
    });
  }

  void _addRecentItem() {
    RecentItems().addRecentItem(RecentItem.fromSource(_dining));
  }

  void _onFavorite() {
    Analytics().logSelect(target: "Favorite: ${_dining.title}");
    Auth2().prefs?.toggleFavorite(_dining);
  }

  void _onDiningWorktimeTapped() {
    Analytics().logSelect(target: "Dining Work Time");
    setState(() {
      _diningWorktimeExpanded = !_diningWorktimeExpanded;
    });
  }

  void _onDiningAdditionalInfoTapped() {
    Analytics().logSelect(target: "Dining Additional Info");
    setState(() {
      _diningAdditionalInfoExpanded = !_diningAdditionalInfoExpanded;
    });
  }

  void _onDiningPaymentTypeTapped() {
    Analytics().logSelect(target: "Dining Payment Type");
    setState(() {
      _diningPaymentTypesExpanded = !_diningPaymentTypesExpanded;
    });
  }

  void _onLoacationDetailTapped() {
    Analytics().logSelect(target: "Location Directions");
    _dining.launchDirections();
  }

  void _onTapOrderOnline(String deepLinkUrl, { String? storeUrl }) async {
    Analytics().logSelect(target: "Order Online");
    bool? appLaunched = await RokwirePlugin.launchApp({"deep_link": deepLinkUrl});
    if ((appLaunched != true) && (storeUrl != null) && storeUrl.isNotEmpty) {
      Uri? storeUri = Uri.tryParse(storeUrl);
      if (storeUri != null) {
        launchUrl(storeUri, mode: LaunchMode.externalApplication).
          catchError((e) { debugPrint(e.toString()); return false; });
      }
    }
  }

  void _onTapTextFeedback() {
    Analytics().logSelect(target: 'Text Feedback');
    String? url = _diningFeedback?.feedbackUrl;
    if (url != null) {
      showDialog<String?>(context: context, builder: (BuildContext context) {
        return _FeedbackBodyWidget(
          analyticsTitle: 'Text Feedback',
          title: Localization().getStringEx('panel.explore_detail.label.text_feedback', 'Text Feedback'),
          message: Localization().getStringEx('panel.explore_detail.label.text_feedback_descr', 'Share your thoughts about your dining experience:'),
        );
      }).then((String? body) {
        if (body != null) {
          _sendFeedback(url, body);
        }
      });
    }
  }

  void _onTapAskDietician() {
    Analytics().logSelect(target: 'Ask a Dietitian');
    String? url = _diningFeedback?.dieticianUrl;
    if (url != null) {
      showDialog<String?>(context: context, builder: (BuildContext context) {
        return _FeedbackBodyWidget(
          analyticsTitle: 'Ask a Dietitian',
          title: Localization().getStringEx('panel.explore_detail.label.ask_dietician', 'Ask a Dietitian'),
          message: Localization().getStringEx('panel.explore_detail.label.ask_dietician_descr', 'Type your question to our Dietitian:'),
        );
      }).then((String? body) {
        if (body != null) {
          _sendFeedback(url, body);
        }
      });
    }
  }

  void _sendFeedback(String url, String body) {
    url = url.replaceAll('{{body}}', Uri.encodeComponent(body));
    Uri? uri = Uri.tryParse(url);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication).catchError((e) { debugPrint(e.toString()); return false; });
    }
  }

  void _launchUrl(String? url, String analyticsName) {
    if (StringUtils.isNotEmpty(url)) {
      AppLaunchUrl.launch(context: context, url: url, analyticsName: analyticsName, analyticsSource: widget.dining.analyticsAttributes);
    }
  }
}

class _DiningDetail extends StatefulWidget {

  final Dining dining;

  _DiningDetail(this.dining);

  _DiningDetailState createState() => _DiningDetailState();
}

class _DiningDetailState extends State<_DiningDetail> with NotificationsListener {

  late List<DateTime> _filterDates;
  late Map<String, List<DiningSchedule>> _displayDateScheduleMapping;

  late List<DiningSchedule> _schedules;
  int _selectedScheduleIndex = -1;

  late List<String> _displayDates;
  int _selectedDateFilterIndex = 0;

  List<DiningProductItem>? _productItems;
  List<DiningSpecial>? _specials;

  bool _isLoading = false;

  @override
  void initState() {
    NotificationService().subscribe(this, Auth2UserPrefs.notifyFoodChanged);

    _displayDates = widget.dining.displayScheduleDates;
    _filterDates = widget.dining.filterScheduleDates;
    _displayDateScheduleMapping = widget.dining.displayDateScheduleMapping;

    _selectedDateFilterIndex = _getTodayFilterIndex();
    _schedules = _buildCurrentSchedule();
    _selectedScheduleIndex = _getCurrentScheduleIndex();

    _loadProductItems();
    _loadOffers();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    bool hasFoodFilterApplied = Auth2().prefs?.hasFoodFilters ?? false;

    String filtersLabel = hasFoodFilterApplied
      ? Localization().getStringEx("widget.food_detail.button.filters_applied.title", "Food Filters Applied")
      : Localization().getStringEx("widget.food_detail.button.filters_empty.title", "Add Food Filters");

    String filtersHint = hasFoodFilterApplied
      ? Localization().getStringEx("widget.food_detail.button.filters_applied.hint", "")
      : Localization().getStringEx("widget.food_detail.button.filters_empty.hint", "");

    return hasMenuData ? Container(color: Styles().colors.background, child:
      Column(children: <Widget>[
        Container(color: Styles().colors.background, height: 1,),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
          HorizontalDiningSpecials(locationId: widget.dining.id, specials: _specials,),
        ),
        // Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), child:
          // Row(children: <Widget>[
          //   Expanded(flex: 2, child:
          //     Text(Localization().getStringEx("widget.food_detail.label.menu.title", "Menu"), style:
          //         Styles().textStyles.getTextStyle("widget.title.regular.fat"),
          //     ),
          //   ),
          //   Expanded(flex: 5, child:
          //     Semantics(button: false, label: filtersLabel, hint: filtersHint, child:
          //       GestureDetector(onTap: _onFoodFilersTapped, child:
          //         Row(children: <Widget>[
          //           Expanded(child:
          //             Text(filtersLabel, textAlign: TextAlign.right, style:
          //                 Styles().textStyles.getTextStyle("widget.title.regular"),
          //             )
          //           ),
          //           Padding(padding: EdgeInsets.only(left: 4), child:
          //             Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true),
          //           )
          //         ],),
          //       ),
          //     )
          //   )
          // ],),
        // ),
        Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), child:
          Row(children: <Widget>[
            Semantics(
              label: Localization().getStringEx("widget.food_detail.button.prev_menu.title", "Previous dining date"),
              hint: Localization().getStringEx("widget.food_detail.button.prev_menu.hint", ""),
              excludeSemantics: true,
              child: _CircularButton(
                image: Styles().images.getImage('chevron-left-bold', excludeFromSemantics: true),
                onTap: decrementDateFilter,
              ),
            ),
            Container(width: 8,),
            Expanded(child:
                Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Text(ListUtils.entry(_displayDates, _selectedDateFilterIndex) ?? '', style: Styles().textStyles.getTextStyle("widget.title.medium.fat"),),
                  Semantics(button: false, label: filtersLabel, hint: filtersHint, child:
                        GestureDetector(onTap: _onFoodFilersTapped, child:
                          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Padding(padding: EdgeInsets.only(right: 4), child:
                                Styles().images.getImage('filters', excludeFromSemantics: true),
                              ),
                              Text(filtersLabel, style:
                                  Styles().textStyles.getTextStyle("widget.title.regular.underline"),
                              ),
                          ],),
                        ),
                      )
                ],)
            ),
            Container(width: 8,),
            Semantics(
              label: Localization().getStringEx("widget.food_detail.button.next_menu.title", "Next dining date"),
              hint: Localization().getStringEx("widget.food_detail.button.next_menu.hint", ""),
              excludeSemantics: true,
              child: _CircularButton(
                image: Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true),
                onTap: incrementDateFilter,
              ),
            ),
          ],),
        ),
        Padding(padding: EdgeInsets.all(16), child:
          SingleChildScrollView(scrollDirection: Axis.horizontal, child:
            Row(children: _buildScheduleTabs(),),
          ),
        ),
        _buildScheduleWorkTime(),
        _isLoading ? Semantics(
          label: Localization().getStringEx("widget.food_detail.label.loading.title", "Loading menu data"),
          hint: Localization().getStringEx("widget.food_detail.label.loading.hint", ""),
          button: false,
          child: Column(children: <Widget>[
            CircularProgressIndicator(),
            Padding(padding: EdgeInsets.symmetric(vertical: 20), child:
              Text(Localization().getStringEx("widget.food_detail.label.loading.title", "Loading menu data")),
            )
          ],),
        ) : Column(children: <Widget>[
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child:
            ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child:
              Column(children:
                _buildStations(),
              ),
            ),
          ),
          Container(height: 20),
        ],),
      ],)
    ) : Container(
      child: Text('No menu data'),
    );
  }


  List<Widget> _buildScheduleTabs() {
    List<Widget> tabs = [];
    for (int i = 0; i < _schedules.length; i++) {
      DiningSchedule schedule = _schedules[i];
      tabs.add(Padding(padding: EdgeInsets.only(right: 8), child: RoundedTab(title: schedule.meal, tabIndex: i, onTap: _onTapTab, selected: (i == _selectedScheduleIndex))));
    }

    return tabs;
  }

  List<Widget> _buildStations() {
    List<Widget> list = [];
    if(_productItems != null && _productItems!.isNotEmpty && _selectedScheduleIndex > -1) {
      List<DiningProductItem> mealProducts = DiningProductItemUtils.filter(
          _productItems,
          ListUtils.entry(_schedules, _selectedScheduleIndex)?.scheduleId,
          Auth2().prefs?.includedFoodTypes,
          Auth2().prefs?.excludedFoodIngredients
      );
      Map<String, List<DiningProductItem>> productStationMapping = DiningProductItemUtils.productsByCategory(mealProducts);

      if (_productItems != null && _productItems!.isNotEmpty) {
        List<String> stations = productStationMapping.keys.toList();

        for(String? stationName in stations) {
          List<DiningProductItem> products = productStationMapping[stationName]!;

          if (products.isNotEmpty) {

            if (list.isNotEmpty) {
              list.add(Container(height: 1, color: Styles().colors.white,));
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

    if (list.isEmpty) {
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

  Widget _buildScheduleWorkTime() {
    DiningSchedule? selectedSchedule = ListUtils.entry(_schedules, _selectedScheduleIndex);
    String workTimeDisplayText = selectedSchedule?.displayWorkTime ?? '';
    return workTimeDisplayText.isNotEmpty ? Column(children: <Widget>[
      Center(child:
        Text(workTimeDisplayText, style: Styles().textStyles.getTextStyle("widget.title.small")),
      ),
      Container(height: 10,),
    ],) : Container();
  }

  int _getTodayFilterIndex() {
    DateTime nowUtc = DateTime.now().toUtc();
    for (String dateString in _displayDates) {
      List<DiningSchedule> schedules = _displayDateScheduleMapping[dateString]!;
      for (DiningSchedule schedule in schedules) {
        if (nowUtc.isBefore(schedule.endTimeUtc!)) {
          return _displayDates.indexOf(dateString);
        }
      }
    }
    return 0;
  }

  int _getCurrentScheduleIndex() {
    if(_schedules.isNotEmpty) {
      var nowUtc = DateTime.now().toUtc();
      for (int i = 0; i < _schedules.length; i++) {
        DiningSchedule schedule = _schedules[i];
        if(nowUtc.isBefore(schedule.startTimeUtc!) || nowUtc.isBefore(schedule.endTimeUtc!)) {
          return i;
        }
      }
      return 0;
    }
    else{
      return -1;
    }
  }

  List<DiningSchedule> _buildCurrentSchedule() {
    String? displayDate = ListUtils.entry(_displayDates, _selectedDateFilterIndex);
    List<DiningSchedule>? schedules = _displayDateScheduleMapping[displayDate];
    return (schedules != null) ? ListUtils.sort(schedules, _compareSchedules) : <DiningSchedule>[];
  }

  static int _compareSchedules(DiningSchedule ds1, DiningSchedule ds2) {
    int order = SortUtils.compare(ds1.startTimeUtc, ds2.startTimeUtc);
    if (order != 0) {
      order = SortUtils.compare(ds1.endTimeUtc, ds2.endTimeUtc);
    }
    if (order == 0) {
      order = SortUtils.compare(ds1.meal, ds2.meal);
    }
    return order;
  }

  bool get hasMenuData{
    return _filterDates.isNotEmpty && _schedules.isNotEmpty;
  }

  Future<void> _loadOffers() async {
    List<DiningSpecial>? offers = await Dinings().loadDiningSpecials();
    if (mounted && offers != null && offers.isNotEmpty) {
      setState(() {
        _specials = offers.where((entry)=>entry.locationIds!.contains(widget.dining.id)).toList();
      });
    }
  }

  Future<void> _loadProductItems() async {
    if (hasMenuData && mounted) {
      setState(() {
        _isLoading = true;
      });
      String? diningId = widget.dining.id;
      DateTime? filterDate = ListUtils.entry(_filterDates, _selectedDateFilterIndex);
      List<DiningProductItem>? items = ((diningId != null) && (filterDate != null)) ? await Dinings().loadMenuItemsForDate(diningId: diningId, date: filterDate) : null;
      setStateIfMounted(() {
        _isLoading = false;
        _productItems = items;
      });
    }
  }

  void _onTapTab(RoundedTab tab) {
    Analytics().logSelect(target: "Tab: ${tab.title}");
    if (mounted) {
      setState(() {
        _selectedScheduleIndex = tab.tabIndex;
      });
    }
  }

  void _onFoodFilersTapped() {
    Analytics().logSelect(target: "Food filters");
    //#5206: SettingsHomePanel.present(context, content: SettingsContentType.food_filters);
    //#5490: SettingsFoodFiltersBottomSheet.present(context).then((_) {
    //  setStateIfMounted();
    //});
    SettingsHomePanel.present(context, content: SettingsContentType.food_filters).then((_){
      setStateIfMounted();
    });
  }

  void incrementDateFilter() {
    Analytics().logSelect(target: "Increment Date filter");
    if (_selectedDateFilterIndex < _filterDates.length - 1) {
      setState(() {
        _selectedDateFilterIndex++;
        _schedules = _buildCurrentSchedule();
        _selectedScheduleIndex = _getCurrentScheduleIndex();
      });

      _loadProductItems();
    }
  }

  void decrementDateFilter() {
    Analytics().logSelect(target: "Decrement Date filter");
    if (_selectedDateFilterIndex > 0) {
      setState(() {
        _selectedDateFilterIndex--;
        _schedules = _buildCurrentSchedule();
        _selectedScheduleIndex = _getCurrentScheduleIndex();
      });

      _loadProductItems();
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

  bool expanded;

  _StationItemState({this.expanded = false});

  void onTap() {
    Analytics().logSelect(target: "Station Item: ${widget.title}");
    if(mounted) {
      setState(() {
        expanded = !expanded;
      });
    }
  }

  void _onProductItemTapped(DiningProductItem productItem) {
    Analytics().logSelect(target: "Product Item: "+productItem.name!);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => FoodDetailPanel(productItem: productItem,)
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Semantics(
        label: widget.title,
        hint: expanded
            ? Localization().getStringEx("model.accessability.expandable.expanded.hint", "Double tap to collaps")
            : Localization().getStringEx("model.accessability.expandable.collapsed.hint", "Double tap to expand"),
        value: expanded
            ? Localization().getStringEx("model.accessability.expandable.expanded.value", "Expanded")
            : Localization().getStringEx("model.accessability.expandable.collapsed.value", "Collapsed"),
        button: true,
        excludeSemantics: true,
        child: GestureDetector(onTap: onTap, child:
          Container(color: Styles().colors.fillColorPrimary, child:
            Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), child:
              Row(children: <Widget>[
                Expanded(child:
                  Text(widget.title!, style: Styles().textStyles.getTextStyle("widget.colourful_button.title.accent")),
                ),
                Styles().images.getImage(expanded ? 'chevron-down-white' : 'chevron-up-white', excludeFromSemantics: true) ?? Container(),
              ],),
            ),
          ),
        ),
      ),
      _buildExpandedWidget(),
    ],);
  }

  Widget _buildExpandedWidget() {
    return (widget.productItems.isNotEmpty && expanded) ?  Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Styles().colors.surfaceAccent),
            right: BorderSide(color: Styles().colors.surfaceAccent)
          )
        ),
        child: Column(
          children: _createExpandedItems(),
        )
    ) : Container();
  }

  List<Widget> _createExpandedItems() {
    List<Widget> list = [];
    list.add(Container(height: 1, color: Styles().colors.surfaceAccent,));
    for(DiningProductItem productItem in widget.productItems) {
      list.add(_ProductItem(productItem: productItem, onTap: () => _onProductItemTapped(productItem),));
      list.add(Container(height: 1, color: Styles().colors.surfaceAccent,));
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
    return Semantics(label: productItem!.name, button: true, excludeSemantics: true, child:
      GestureDetector(onTap: onTap, child:
        Container(color: Colors.white, child:
          Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), child:
            Row(children: <Widget>[
              Expanded(child:
                Text(productItem!.name!, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat")),
              ),
              Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true) ?? Container(),
            ],),
          ),
        ),
      ),
    );
  }
}

class _CircularButton extends StatelessWidget{
  final Widget? image;
  final GestureTapCallback? onTap;

  _CircularButton({required this.image, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child:
      Container(width: 40, height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: Styles().colors.fillColorSecondary, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: image,
      ),
    );
  }
}

class _FeedbackBodyWidget extends StatefulWidget {
  final String? title;
  final String? analyticsTitle;
  final String? message;

  _FeedbackBodyWidget({Key? key, this.title, this.analyticsTitle, this.message}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FeedbackBodyWidgetState();
}

class _FeedbackBodyWidgetState extends State<_FeedbackBodyWidget> {

  FocusNode _focusNode = FocusNode();
  TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child:
      Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),), child:
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
            Expanded(child:
              Container(decoration: BoxDecoration(color: Styles().colors.fillColorPrimary, borderRadius: BorderRadius.vertical(top: Radius.circular(8)),), child:
                Row(children: [
                  Expanded(child:
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
                      Text(widget.title ?? '', style: Styles().textStyles.getTextStyle("widget.dialog.message.regular.fat")),
                    )
                  ),
                  Semantics(label: Localization().getStringEx("dialog.close.title", "Close"), button: true, child:
                    InkWell(onTap: _onClose, child:
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), child:
                        Styles().images.getImage('close-circle-white'),
                        /*Container(height: 30, width: 30, decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(15)), border: Border.all(color: Styles().colors.white, width: 2),), child:
                          Center(child:
                            Baseline(baselineType: TextBaseline.alphabetic, baseline: 16, child:
                              Text('\u00D7', style: Styles().textStyles.getTextStyle("widget.dialog.message.large.extra_fat"), semanticsLabel: "", ),
                            ),
                          ),
                        ),*/
                      )
                    )
                  ),
                ],),
              ),
            ),
          ],),
          SingleChildScrollView(child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Row(children: [
                  Expanded(child:
                    Text(widget.message ?? '', style: Styles().textStyles.getTextStyle("widget.message.regular.fat"),),
                  ),
                ]),
                Container(height: 4,),
                TextField(
                  focusNode: _focusNode,
                  controller: _textController,
                  maxLines: 8,
                  decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0)), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  style: Styles().textStyles.getTextStyle("widget.detail.regular")
                ),
                Container(height: 16,),
                Row(children: [
                  Expanded(flex: 1, child: Container()),
                  Expanded(flex: 2, child:
                    RoundedButton(
                      label: Localization().getStringEx("dialog.send.title", "Send"),
                      backgroundColor: Colors.transparent,
                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                      borderColor: Styles().colors.fillColorSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      onTap: () => _onSend(),
                    ),
                  ),
                  Expanded(flex: 1, child: Container()),
                ]),
              ],),
            ),
          ),
        ]),
      ),
    );
  }

  void _onClose() {
    Analytics().logAlert(text: widget.title, selection: "Close");
    Navigator.of(context).pop(null);
  }

  void _onSend() {
    Analytics().logAlert(text: "Text Message", selection: "Send");
    Navigator.of(context).pop(_textController.text);
  }
}
