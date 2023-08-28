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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/ui/laundry/LaundryRequestIssuePanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';

class LaundryRoomDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final LaundryRoom room;

  LaundryRoomDetailPanel({required this.room});

  @override
  _LaundryRoomDetailPanelState createState() => _LaundryRoomDetailPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes {
    return room.analyticsAttributes;
  }
}

class _LaundryRoomDetailPanelState extends State<LaundryRoomDetailPanel> implements NotificationsListener {
  LaundryRoomDetails? _laundryRoomDetails;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
    ]);
    RecentItems().addRecentItem(RecentItem.fromSource(widget.room));
    Analytics().logMapShow();
    _load();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    Analytics().logMapHide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHeaderBar(),
      body: _isLoading ? _buildLoadingWidget() : _buildRoomContentWidget(),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: !_isLoading ? uiuc.TabBar() : null,
    );
  }

  Widget _buildRoomContentWidget() {
    return Column(children: <Widget>[
      Expanded(child:
        SingleChildScrollView(scrollDirection: Axis.vertical, child:
          Container(color: Styles().colors?.background, child:
            Column(children: <Widget>[
              _buildLaundryRoomCaptionSection(),
              _buildLaundryRoomInfoSection(),
              _buildLaundryRoomAvailabilitySection(),
              _buildLaundryRoomAppliancesListSection()
            ],),
          ),
        ),
      ),
    ],);
  }

  Widget _buildLoadingWidget() {
    return Center(child:
      CircularProgressIndicator(),
    );
  }

  PreferredSizeWidget _buildHeaderBar() {
    return HeaderBar(title: Localization().getStringEx("panel.laundry_detail.header.title", "Laundry"),);
  }

  Widget _buildLocationWidget() {
    return _isLocationWidgetEnabled &&  (widget.room.location?.isLocationCoordinateValid == true) ? Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
      Styles().images?.getImage('location', excludeFromSemantics: true) ?? Container(),
      Expanded(
          child: GestureDetector(
              onTap: _onTapViewMap,
              child: Semantics(
                  label: Localization().getStringEx('panel.laundry_detail.button.view_on_map.title', 'View on map'),
                  hint: Localization().getStringEx('panel.laundry_detail.button.view_on_map.hint', ''),
                  excludeSemantics: true,
                  button: true,
                  child: Padding(
                      padding: EdgeInsets.only(left: 10, right: 24),
                      child: Text(Localization().getStringEx('panel.laundry_detail.button.view_on_map.title', 'View on map'),
                          style: Styles().textStyles?.getTextStyle("panel.laundry_room_detail.map_button.title.regular.underline"))))))
    ]) : Container();
  }

  Widget _buildReportIssueWidget() {
    return Padding(padding: EdgeInsets.only(top: 10), child: Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
      Styles().images?.getImage('issue', excludeFromSemantics: true) ?? Container(),
      Expanded(
          child: GestureDetector(
              onTap: _onTapReportIssue,
              child: Semantics(
                  label: Localization().getStringEx('panel.laundry_detail.button.report_issue.title', 'Report an Issue'),
                  hint: Localization().getStringEx('panel.laundry_detail.button.report_issue.hint', ''),
                  excludeSemantics: true,
                  button: true,
                  child: Padding(
                      padding: EdgeInsets.only(left: 10, right: 24),
                      child: Text(Localization().getStringEx('panel.laundry_detail.button.report_issue.title', 'Report an Issue'),
                          style: Styles().textStyles?.getTextStyle("panel.laundry_room_detail.map_button.title.regular.underline"))))))
    ]));
  }

  Widget _buildLaundryRoomCaptionSection() {
    return Container(color: Styles().colors?.accentColor2, height: 4,);
  }

  Widget _buildLaundryRoomInfoSection() {
    bool isFavorite = Auth2().isFavorite(widget.room);
    
    String favoriteLabel = isFavorite ?
      Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') :
      Localization().getStringEx('widget.card.button.favorite.on.title','Add To Favorites');

    String favoriteHint = isFavorite ?
      Localization().getStringEx('widget.card.button.favorite.off.hint', '') :
      Localization().getStringEx('widget.card.button.favorite.on.hint', '');

    String favoriteIconKey = isFavorite? 'star-filled' : 'star-outline-gray';
    
    return Container(color: Colors.white, child:
      Padding(padding: EdgeInsets.only(left: 24), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
            Expanded(child:
              Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
                Text(widget.room.name ?? '', style: Styles().textStyles?.getTextStyle("widget.title.medium_large.extra_fat"),),
              ),
            ),
            Visibility(visible: Auth2().canFavorite, child:
              GestureDetector(onTap: _onTapFavorite, child:
                Semantics(label: favoriteLabel, hint: favoriteHint, button: true, excludeSemantics: true, child:
                  Padding(padding: EdgeInsets.only(left: 12, right: 16, top: 24, bottom: 25), child:
                    Styles().images?.getImage(favoriteIconKey, excludeFromSemantics: true)
                  ),
                ),
              ),
            ),
          ],),
          Padding(padding: EdgeInsets.only(right: 24, bottom: 24), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              _buildLocationWidget(),
              _buildReportIssueWidget()
            ],)
          ),
        ],),
      ),
    );
  }

  Widget _buildLaundryRoomAvailabilitySection() {
    int? availableWashersCount = _laundryRoomDetails?.availableWashersCount;
    String? availableWashersLabel = (availableWashersCount != null) ?
      sprintf(Localization().getStringEx('panel.laundry_detail.available.format', '"%s available"'), [availableWashersCount]) : Localization().getStringEx("panel.laundry_detail.available.undefined", "unknown");
    
    int? availableDryersCount = _laundryRoomDetails?.availableDryersCount;
    String? availableDryersLabel = (availableDryersCount != null) ?
      sprintf(Localization().getStringEx('panel.laundry_detail.available.format', '"%s available"'), [availableDryersCount]) : Localization().getStringEx("panel.laundry_detail.available.undefined", "unknown");

    return Padding(padding: EdgeInsets.all(24), child:
      SingleChildScrollView(scrollDirection: Axis.horizontal, child:
        Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
            Styles().images?.getImage('washer-large', semanticLabel: Localization().getStringEx('panel.laundry_detail.label.washer', 'WASHER')) ?? Container(),
            Padding(padding: EdgeInsets.only(right: 12),),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(Localization().getStringEx('panel.laundry_detail.label.washers', 'WASHERS'), style: Styles().textStyles?.getTextStyle("widget.title.small.fat.spaced")),
              Text(availableWashersLabel, style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")),
            ],)
          ],),
          Padding(padding: EdgeInsets.only(right: 16)),
          Row(children: <Widget>[
            Styles().images?.getImage('dryer-large', semanticLabel: Localization().getStringEx('panel.laundry_detail.label.dryer', 'DRYER')) ?? Container(),
            Padding(padding: EdgeInsets.only(right: 12),),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(Localization().getStringEx('panel.laundry_detail.label.dryers', 'DRYERS'), style: Styles().textStyles?.getTextStyle("widget.title.small.fat.spaced"),),
              Text( availableDryersLabel, style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),),
            ],),
          ],)
        ],),
      ),
    );

  }

  Widget _buildLaundryRoomAppliancesListSection() {
    int appliancesCount = _laundryRoomDetails?.appliances?.length ?? 0;
    if (appliancesCount == 0) {
      return Container();
    }
    return Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 48), child:
      ListView.separated(physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: _buildApplianceItem,
          separatorBuilder: _buildApplianceSeparator,
          itemCount: appliancesCount),
    );
  }

  Widget _buildApplianceItem(BuildContext context, int index) {
    LaundryRoomAppliance? appliance = (_laundryRoomDetails?.appliances != null) ? _laundryRoomDetails?.appliances![index] : null;
    return (appliance != null) ? _LaundryRoomApplianceItem(appliance) : Container();
  }

  Widget _buildApplianceSeparator(BuildContext context, int index) {
    return Container(height: 1, color: Styles().colors?.background,);
  }

  void _load() {
    _setLoading(true);
    Laundries().loadRoomDetails(widget.room.id).then((roomDetails) {
      _laundryRoomDetails = roomDetails;
      _setLoading(false);
    });
  }

  void _onTapViewMap() {
    Analytics().logSelect(target: "View Map");
    //TBD Map2: Map Panel
  }

  void _onTapReportIssue() {
    Analytics().logSelect(target: "Laundry: Report an Issue");
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => LaundryRequestIssuePanel(), settings: RouteSettings(name: LaundryRequestIssuePanel.routeSettingsName)));
  }

  void _onTapFavorite() {
    Analytics().logSelect(target: "Favorite: ${widget.room.name}");
    Auth2().prefs?.toggleFavorite(widget.room);
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      if (mounted) {
        setState(() {});
      }
    }
  }

  bool get _isLocationWidgetEnabled => false; //[FEATURE] Remove "View on Map" from the laundry detail page #1674: "Laundry rooms do not need navigation"

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (mounted) {
        setStateIfMounted(() {});
      }
    }
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
    }
  }
}

class _LaundryRoomApplianceItem extends StatelessWidget {
  final LaundryRoomAppliance appliance;

  _LaundryRoomApplianceItem(this.appliance);

  @override
  Widget build(BuildContext context) {
    String imageKey = _getImageAssetPath(appliance.type);
    String? deviceName = _getDeviceName(appliance.type);
    return Container(color: Colors.white, child:
      Padding(padding: EdgeInsets.all(12), child:
        Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Styles().images?.getImage(imageKey, semanticLabel: deviceName, excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.only(left: 12, right: 10), child:
            Text(appliance.label ?? '', style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),),
          ),
          Expanded(child:
            Text(StringUtils.ensureNotEmpty(_applianceStatusLabel), style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")),
          )
        ],),
      ),
    );
  }

  String _getImageAssetPath(LaundryApplianceType? applianceType) {
    switch (applianceType) {
      case LaundryApplianceType.washer: return 'washer';
      case LaundryApplianceType.dryer: return 'dryer';
      default: return 'washer';
    }
  }

  String? _getDeviceName(LaundryApplianceType? applianceType) {
    switch (applianceType) {
      case LaundryApplianceType.washer: return Localization().getStringEx('panel.laundry_detail.label.washer', 'WASHER');
      case LaundryApplianceType.dryer: return Localization().getStringEx('panel.laundry_detail.label.dryer', 'DRYER');
      default: return Localization().getStringEx('panel.laundry_detail.label.washer', 'WASHER');
    }
  }

  String? get _applianceStatusLabel {
    switch (appliance.status) {
      case LaundryApplianceStatus.available:
        return Localization().getStringEx('panel.laundry_detail.available.label', 'Available');
      case LaundryApplianceStatus.out_of_service:
        return Localization().getStringEx('panel.laundry_detail.out_of_service.label', 'OUT OF SERVICE');
      case LaundryApplianceStatus.in_use:
        int? timeRemaining = appliance.timeRemainingInMins;
        return (timeRemaining != null)
            ? sprintf(Localization().getStringEx('panel.laundry_detail.in_use.with_minutes.label', 'In Use with %d minutes remaining'),
                [timeRemaining])
            : Localization().getStringEx('panel.laundry_detail.in_use.label', 'In Use');
      default:
        return null;
    }
  }
}
