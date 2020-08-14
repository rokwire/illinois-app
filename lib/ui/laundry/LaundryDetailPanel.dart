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
import 'package:illinois/service/LaundryService.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/model/Location.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/MapWidget.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:sprintf/sprintf.dart';

class LaundryDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final LaundryRoom room;

  LaundryDetailPanel({@required this.room});

  @override
  _LaundryDetailPanelState createState() => _LaundryDetailPanelState();

  @override
  Map<String, dynamic> get analyticsPageAttributes {
    return room?.analyticsAttributes;
  }
}

class _LaundryDetailPanelState extends State<LaundryDetailPanel> implements NotificationsListener {
  LaundryRoomAvailability _laundryRoomAvailability;
  List<LaundryRoomAppliance> _laundryRoomAppliances;
  bool _availabilityLoaded = false;
  bool _appliancesLoaded = false;

  //Maps
  MapController _nativeMapController;
  bool _detailVisible = true;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, User.notifyFavoritesUpdated);
    _load();
    Analytics().logMapShow();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    Analytics().logMapHide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!(_availabilityLoaded && _appliancesLoaded)) {
      return Scaffold(
        appBar: _buildHeaderBar(),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    String washersAvailable = (_laundryRoomAvailability?.availableWashers is String)  ? _laundryRoomAvailability?.availableWashers : '0';
    String dryersAvailable = (_laundryRoomAvailability?.availableDryers is String) ? _laundryRoomAvailability?.availableDryers : '0';
    bool isFavorite = User().isFavorite(widget.room);

    return Scaffold(
      appBar: _buildHeaderBar(),
      body: Stack(
        children: <Widget>[
          MapWidget(
            onMapCreated: _onNativeMapCreated,
          ),
          Visibility(
              visible: _detailVisible,
              child: Column(
                children: <Widget>[
                  Expanded(
                      child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Container(
                      color: Styles().colors.background,
                      child: Column(
                        children: <Widget>[
                          Container(
                            color: Styles().colors.accentColor2,
                            height: 4,
                          ),
                          Container(
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: 24, right: 24, top: 11, bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        Localization().getStringEx(
                                            'panel.laundry_detail.heading.laundry',
                                            'Laundry'),
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Styles().colors.fillColorPrimary,
                                            fontFamily: Styles().fontFamilies.bold),
                                      ),
                                      Visibility(visible: User().favoritesStarVisible,
                                          child: GestureDetector(
                                            onTap: () {
                                              Analytics.instance.logSelect(target: "Favorite");
                                              User()
                                                  .switchFavorite(widget.room);
                                            },
                                            child: Semantics(
                                                label: isFavorite
                                                    ? Localization().getStringEx(
                                                    'widget.card.button.favorite.off.title',
                                                    'Remove From Favorites')
                                                    : Localization().getStringEx(
                                                    'widget.card.button.favorite.on.title',
                                                    'Add To Favorites'),
                                                hint: isFavorite
                                                    ? Localization().getStringEx(
                                                    'widget.card.button.favorite.off.hint',
                                                    '')
                                                    : Localization().getStringEx(
                                                    'widget.card.button.favorite.on.hint',
                                                    ''),
                                                button: true,
                                                excludeSemantics: true,
                                                child: Padding(
                                                    padding: EdgeInsets.all(10),
                                                    child: Image.asset(
                                                        isFavorite
                                                            ? 'images/icon-star-selected.png'
                                                            : 'images/icon-star.png'))),
                                          ))
                                    ],
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(top: 2, bottom: 14),
                                    child: Text(
                                      widget.room?.title,
                                      style: TextStyle(
                                          color: Styles().colors.fillColorPrimary,
                                          fontSize: 24,
                                          fontFamily: Styles().fontFamilies.extraBold),
                                    ),
                                  ),
                                  _buildLocationWidget()
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Image.asset('images/icon-washer-big.png', semanticLabel: Localization().getStringEx('panel.laundry_detail.label.washer', 'WASHER'),),
                                    Padding(
                                      padding: EdgeInsets.only(right: 12),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          Localization().getStringEx('panel.laundry_detail.label.washers', 'WASHERS'),
                                          style: TextStyle(
                                              color: Styles().colors.fillColorPrimary,
                                              fontSize: 14,
                                              fontFamily: Styles().fontFamilies.bold,
                                              letterSpacing: 1),
                                        ),
                                        Text(
                                          sprintf(Localization().getStringEx('panel.laundry_detail.available.format', '"%s available"'), [washersAvailable]),
                                          style: TextStyle(
                                              color: Styles().colors.textBackground,
                                              fontSize: 16,
                                              fontFamily: Styles().fontFamilies.regular),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                                Padding(padding: EdgeInsets.only(right: 16)),
                                Row(
                                  children: <Widget>[
                                    Image.asset('images/icon-dryer-big.png', semanticLabel: Localization().getStringEx('panel.laundry_detail.label.dryer', 'DRYER')),
                                    Padding(
                                      padding: EdgeInsets.only(right: 12),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          Localization().getStringEx('panel.laundry_detail.label.dryers', 'DRYERS'),
                                          style: TextStyle(
                                              color: Styles().colors.fillColorPrimary,
                                              fontSize: 14,
                                              fontFamily: Styles().fontFamilies.bold,
                                              letterSpacing: 1),
                                        ),
                                        Text(
                                          sprintf(Localization().getStringEx('panel.laundry_detail.available.format', '"%s available"'), [dryersAvailable]),
                                          style: TextStyle(
                                              color: Styles().colors.textBackground,
                                              fontSize: 16,
                                              fontFamily: Styles().fontFamilies.regular),
                                        )
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                          _buildLaundryRoomAppliancesListWidget()
                        ],
                      ),
                    ),
                  )),
                ],
              ))
        ],
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildHeaderBar() {
    return SimpleHeaderBarWithBack(
      context: context,
      titleWidget: Text(Localization().getStringEx("panel.laundry_detail.header.title", "Laundry"),
        style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildLocationWidget() {
    Location laundryLocationDetails = widget.room?.location;
    if (laundryLocationDetails == null) {
      return Container();
    }
    String locationText = laundryLocationDetails.getDisplayAddress();
    String semanticText =sprintf(Localization().getStringEx('panel.laundry_detail.location_coordinates.format', '"Location: %s "'), [locationText]);
    if (AppString.isStringEmpty(locationText)) {
      double latitude = laundryLocationDetails.latitude;
      double longitude = laundryLocationDetails.longitude;
      locationText = '$latitude, $longitude';

      semanticText = sprintf(Localization().getStringEx('panel.laundry_detail.location_coordinates.format', '"Location coordinates, Latitude:%s , Longitude:%s "'), [latitude,longitude]);
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Visibility(
          visible: AppString.isStringNotEmpty(locationText),
          child:Semantics(label:semanticText, excludeSemantics: true,child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Image.asset('images/icon-location.png'),
                Padding(
                  padding: EdgeInsets.only(right: 5),
                ),
                Flexible(
                  child: Text(locationText,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies.medium,
                          fontSize: 16,
                          color: Styles().colors.textBackground)),
                )
              ],
            ),
          )
        ),
        GestureDetector(
          onTap: _onTapViewMap,
          child: Semantics(
            label: Localization().getStringEx('panel.laundry_detail.button.view_on_map.title', 'View on map'),
            hint: Localization().getStringEx('panel.laundry_detail.button.view_on_map.hint', ''),
            excludeSemantics: true,
            button:true,
            child:Padding(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 24),
            child: Text(
              Localization().getStringEx('panel.laundry_detail.button.view_on_map.title', 'View on map'),
              style: TextStyle(
                  color: Styles().colors.fillColorPrimary,
                  fontSize: 16,
                  fontFamily: Styles().fontFamilies.medium,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.17,
                  decorationColor: Styles().colors.fillColorSecondary),
            ),
          )),
        )
      ],
    );
  }

  Widget _buildLaundryRoomAppliancesListWidget() {
    int appliancesCount = _laundryRoomAppliances?.length ?? 0;
    if (appliancesCount == 0) {
      return Container();
    }
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 48),
      child: ListView.separated(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            LaundryRoomAppliance appliance = _laundryRoomAppliances[index];
            return _LaundryRoomApplianceItem(appliance);
          },
          separatorBuilder: (context, index) => Container(
                height: 1,
                color: Styles().colors.background,
              ),
          itemCount: appliancesCount),
    );
  }

  void _load() {
    LaundryService().getNumAvailable(widget.room?.id).then((roomAvailability) => _onAvailabilityLoaded(roomAvailability));
    LaundryService().getAppliances(widget.room?.id).then((roomAppliances) => _onAppliancesLoaded(roomAppliances));
  }

  void _onAvailabilityLoaded(LaundryRoomAvailability availability) {
    _laundryRoomAvailability = availability;
    _availabilityLoaded = true;
    setState(() {});
  }

  void _onAppliancesLoaded(List<LaundryRoomAppliance> appliances) {
    _laundryRoomAppliances = appliances;
    _appliancesLoaded = true;
    setState(() {});
  }

  void _onTapViewMap() {
    Analytics.instance.logSelect(target: "View Map");
    if (_detailVisible) {
      setState(() {
        _detailVisible = false;
      });
    }
  }

  void _onNativeMapCreated(mapController) {
    this._nativeMapController = mapController;
    _nativeMapController.placePOIs([widget.room]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == User.notifyFavoritesUpdated) {
      setState(() {});
    }
  }
}

class _LaundryRoomApplianceItem extends StatelessWidget {
  final LaundryRoomAppliance appliance;

  _LaundryRoomApplianceItem(this.appliance);

  @override
  Widget build(BuildContext context) {
    String imageAssetPath = _getImageAssetPath(appliance?.applianceType);
    String deviceName = _getDeviceName(appliance?.applianceType);
    return Container(
      height: 46,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Image.asset(imageAssetPath, semanticLabel: deviceName,),
            Padding(
              padding: EdgeInsets.only(left: 12, right: 10),
              child: Text(
                appliance?.label,
                style: TextStyle(
                    color: Styles().colors.textBackground,
                    fontSize: 16,
                    fontFamily: Styles().fontFamilies.regular),
              ),
            ),
            Text(
              appliance?.status,
              style: TextStyle(
                  color: Styles().colors.textBackground,
                  fontSize: 16,
                  fontFamily: Styles().fontFamilies.regular),
            )
          ],
        ),
      ),
    );
  }

  String _getImageAssetPath(String applianceType) {
    String defaultAssetPath = 'images/icon-washer-small.png';
    if (AppString.isStringEmpty(applianceType)) {
      return defaultAssetPath;
    }
    switch (applianceType) {
      case 'WASHER':
        return 'images/icon-washer-small.png';
      case 'DRYER':
        return 'images/icon-dryer-small.png';
      default:
        return defaultAssetPath;
    }
  }

  String _getDeviceName(String applianceType) {
    if (AppString.isStringEmpty(applianceType)) {
      return Localization().getStringEx('panel.laundry_detail.label.washer', 'WASHER');
    }
    switch (applianceType) {
      case 'WASHER':
        return Localization().getStringEx('panel.laundry_detail.label.washer', 'WASHER');
      case 'DRYER':
        return Localization().getStringEx('panel.laundry_detail.label.dryer', 'DRYER');
      default:
        return Localization().getStringEx('panel.laundry_detail.label.washer', 'WASHER');
    }
  }
}
