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
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/MapWidget.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';

class LaundryDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final LaundryRoom room;

  LaundryDetailPanel({required this.room});

  @override
  _LaundryDetailPanelState createState() => _LaundryDetailPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes {
    return room.analyticsAttributes;
  }
}

class _LaundryDetailPanelState extends State<LaundryDetailPanel> implements NotificationsListener {
  LaundryRoomAvailability? _laundryRoomAvailability;
  List<LaundryRoomAppliance>? _laundryRoomAppliances;
  bool _availabilityLoaded = false;
  bool _appliancesLoaded = false;

  //Maps
  late MapController _nativeMapController;
  bool _detailVisible = true;
  bool _mapAllowed = false;

  bool get _isLoading => (_availabilityLoaded != true) ||  (_appliancesLoaded != true);

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, Auth2UserPrefs.notifyFavoritesChanged);
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
    return Stack(children: <Widget>[
      _mapAllowed ? MapWidget(onMapCreated: _onNativeMapCreated,) : Container(),
      Visibility(visible: _detailVisible, child:
        Column(children: <Widget>[
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
        ],),
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
    ExploreLocation? laundryLocationDetails = widget.room.location;
    if (laundryLocationDetails == null) {
      return Container();
    }
    String? locationText = laundryLocationDetails.getDisplayAddress();
    String? semanticText =sprintf(Localization().getStringEx('panel.laundry_detail.location_coordinates.format', '"Location: %s "'), [locationText]);
    if (StringUtils.isEmpty(locationText)) {
      double? latitude = laundryLocationDetails.latitude?.toDouble();
      double? longitude = laundryLocationDetails.longitude?.toDouble();
      locationText = '$latitude, $longitude';

      semanticText = sprintf(Localization().getStringEx('panel.laundry_detail.location_coordinates.format', '"Location coordinates, Latitude:%s , Longitude:%s "'), [latitude,longitude]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Visibility(visible: StringUtils.isNotEmpty(locationText), child:
        Semantics(label:semanticText, excludeSemantics: true, child:
          Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
            Image.asset('images/icon-location.png', excludeFromSemantics: true),
            Padding(padding: EdgeInsets.only(right: 5),),
            Flexible(child:
              Text(locationText, overflow: TextOverflow.ellipsis, maxLines: 2, style: TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: 16, color: Styles().colors?.textBackground)),
            )
          ],),
        )
      ),
      GestureDetector(onTap: _onTapViewMap, child:
        Semantics(label: Localization().getStringEx('panel.laundry_detail.button.view_on_map.title', 'View on map'), hint: Localization().getStringEx('panel.laundry_detail.button.view_on_map.hint', ''), excludeSemantics: true, button:true, child:
          Padding(padding: EdgeInsets.symmetric(vertical: 5, horizontal: 24), child:
            Text(Localization().getStringEx('panel.laundry_detail.button.view_on_map.title', 'View on map'), style: TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: 16, color: Styles().colors?.fillColorPrimary, decoration: TextDecoration.underline, decorationThickness: 1.17, decorationColor: Styles().colors?.fillColorSecondary),),
          ),
        ),
      ),
    ],);
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

    String favoriteIcon = isFavorite? 'images/icon-star-selected.png' : 'images/icon-star.png';
    return Container(color: Colors.white, child:
      Padding(padding: EdgeInsets.only(left: 24, right: 24, top: 11, bottom: 24), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
            Text(Localization().getStringEx('panel.laundry_detail.heading.laundry', 'Laundry'), style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 14, color: Styles().colors?.fillColorPrimary,),),
            Visibility(visible: Auth2().canFavorite, child:
              GestureDetector(onTap: _onTapFavorite, child:
                Semantics(label: favoriteLabel, hint: favoriteHint, button: true, excludeSemantics: true, child:
                  Padding(padding: EdgeInsets.all(10), child:
                    Image.asset(favoriteIcon, excludeFromSemantics: true)
                  ),
                ),
              ),
            ),
          ],),
          Padding(padding:EdgeInsets.only(top: 2, bottom: 14), child:
            Text(widget.room.title ?? '', style: TextStyle( fontFamily: Styles().fontFamilies?.extraBold, fontSize: 24, color: Styles().colors?.fillColorPrimary,),),
          ),
          _buildLocationWidget()
        ],),
      ),
    );
  }

  Widget _buildLaundryRoomAvailabilitySection() {
    String? availableWashers = StringUtils.isNotEmpty(_laundryRoomAvailability?.availableWashers) ?
      sprintf(Localization().getStringEx('panel.laundry_detail.available.format', '"%s available"'), [_laundryRoomAvailability?.availableWashers]) : Localization().getStringEx("panel.laundry_detail.available.undefined", "unknown");
    
    String? availableDryers = StringUtils.isNotEmpty(_laundryRoomAvailability?.availableDryers) ?
      sprintf(Localization().getStringEx('panel.laundry_detail.available.format', '"%s available"'), [_laundryRoomAvailability?.availableDryers]) : Localization().getStringEx("panel.laundry_detail.available.undefined", "unknown");

    return Padding(padding: EdgeInsets.all(24), child:
      SingleChildScrollView(scrollDirection: Axis.horizontal, child:
        Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
            Image.asset('images/icon-washer-big.png', semanticLabel: Localization().getStringEx('panel.laundry_detail.label.washer', 'WASHER'),),
            Padding(padding: EdgeInsets.only(right: 12),),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(Localization().getStringEx('panel.laundry_detail.label.washers', 'WASHERS'), style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 14, letterSpacing: 1, color: Styles().colors?.fillColorPrimary,),),
              Text(availableWashers, style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground, ),),
            ],)
          ],),
          Padding(padding: EdgeInsets.only(right: 16)),
          Row(children: <Widget>[
            Image.asset('images/icon-dryer-big.png', semanticLabel: Localization().getStringEx('panel.laundry_detail.label.dryer', 'DRYER')),
            Padding(padding: EdgeInsets.only(right: 12),),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(Localization().getStringEx('panel.laundry_detail.label.dryers', 'DRYERS'), style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 14, letterSpacing: 1, color: Styles().colors?.fillColorPrimary,),),
              Text( availableDryers, style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground,),),
            ],),
          ],)
        ],),
      ),
    );

  }

  Widget _buildLaundryRoomAppliancesListSection() {
    int appliancesCount = _laundryRoomAppliances?.length ?? 0;
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
    LaundryRoomAppliance? appliance = (_laundryRoomAppliances != null) ? _laundryRoomAppliances![index] : null;
    return (appliance != null) ? _LaundryRoomApplianceItem(appliance) : Container();
  }

  Widget _buildApplianceSeparator(BuildContext context, int index) {
    return Container(height: 1, color: Styles().colors?.background,);
  }

  void _load() {
    Laundries().loadRoomAvailability(widget.room.id).then((roomAvailability) => _onAvailabilityLoaded(roomAvailability));
    Laundries().loadRoomAppliances(widget.room.id).then((roomAppliances) => _onAppliancesLoaded(roomAppliances));
  }

  void _onAvailabilityLoaded(LaundryRoomAvailability? availability) {
    if (mounted) {
      setState(() {
        _laundryRoomAvailability = availability;
        _availabilityLoaded = true;
      });
    }
  }

  void _onAppliancesLoaded(List<LaundryRoomAppliance>? appliances) {
    if (mounted) {
      setState(() {
        _laundryRoomAppliances = appliances;
        _appliancesLoaded = true;
      });
    }
  }

  void _onTapViewMap() {
    Analytics().logSelect(target: "View Map");
    if (_detailVisible) {
      setState(() {
        _detailVisible = false;
        _mapAllowed = true;
      });
    }
  }

  void _onTapFavorite() {
    Analytics().logSelect(target: "Favorite: ${widget.room.title}");
    Auth2().prefs?.toggleFavorite(widget.room);
  }

  void _onNativeMapCreated(mapController) {
    this._nativeMapController = mapController;
    _nativeMapController.placePOIs([widget.room]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (mounted) {
        setState(() {});
      }
    }
  }
}

class _LaundryRoomApplianceItem extends StatelessWidget {
  final LaundryRoomAppliance appliance;

  _LaundryRoomApplianceItem(this.appliance);

  @override
  Widget build(BuildContext context) {
    String imageAssetPath = _getImageAssetPath(appliance.applianceType);
    String? deviceName = _getDeviceName(appliance.applianceType);
    return Container(color: Colors.white, child:
      Padding(padding: EdgeInsets.all(12), child:
        Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Image.asset(imageAssetPath, semanticLabel: deviceName, excludeFromSemantics: true),
          Padding(padding: EdgeInsets.only(left: 12, right: 10), child:
            Text(appliance.label ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground,),),
          ),
          Expanded(child:
            Text(appliance.status ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground,),),
          )
        ],),
      ),
    );
  }

  String _getImageAssetPath(String? applianceType) {
    switch (applianceType) {
      case 'WASHER': return 'images/icon-washer-small.png';
      case 'DRYER': return 'images/icon-dryer-small.png';
      default: return 'images/icon-washer-small.png';
    }
  }

  String? _getDeviceName(String? applianceType) {
    switch (applianceType) {
      case 'WASHER': return Localization().getStringEx('panel.laundry_detail.label.washer', 'WASHER');
      case 'DRYER': return Localization().getStringEx('panel.laundry_detail.label.dryer', 'DRYER');
      default: return Localization().getStringEx('panel.laundry_detail.label.washer', 'WASHER');
    }
  }
}
