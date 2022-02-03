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
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/explore/ExploreViewTypeTab.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/laundry/LaundryDetailPanel.dart';
import 'package:illinois/ui/laundry/LaundryListPanel.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/MapWidget.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';


enum _DisplayType { List, Map }

class LaundryHomePanel extends StatefulWidget {
  @override
  _LaundryHomePanelState createState() => _LaundryHomePanelState();
}

class _LaundryHomePanelState extends State<LaundryHomePanel> with SingleTickerProviderStateMixin implements NotificationsListener {
  static const double _MapBarHeight = 114;

  List<LaundryRoom>? _rooms;
  bool _loading = false;
  _DisplayType _displayType = _DisplayType.List;
  bool? _mapAllowed;
  MapController? _nativeMapController;
  LocationServicesStatus? _locationServicesStatus;
  dynamic _selectedMapLaundry;
  late AnimationController _mapLaundryBarAnimationController;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      LocationServices.notifyStatusChanged,
      NativeCommunicator.notifyMapSelectExplore,
      NativeCommunicator.notifyMapClearExplore,
      Assets.notifyChanged,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
    ]);

    LocationServices().status.then((LocationServicesStatus? locationServicesStatus) {
      _locationServicesStatus = locationServicesStatus;

      if (_locationServicesStatus == LocationServicesStatus.permissionNotDetermined) {
        LocationServices().requestPermission().then((LocationServicesStatus? locationServicesStatus) {
          _locationServicesStatus = locationServicesStatus;
        });
      }
      else {}
    });

    _mapLaundryBarAnimationController = AnimationController(duration: Duration(milliseconds: 200), lowerBound: -_MapBarHeight, upperBound: 0, vsync: this)
      ..addListener(() {
        this.setState(() {});
      });

    _loadRooms();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    if (_displayType == _DisplayType.Map) {
      Analytics().logMapHide();
    }
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == LocationServices.notifyStatusChanged) {
      _onLocationServicesStatusChanged(param);
    }
    else if (name == NativeCommunicator.notifyMapSelectExplore) {
      _onNativeMapSelectExplore(param['mapId'], param['exploreJson']);
    }
    else if (name == NativeCommunicator.notifyMapClearExplore) {
      _onNativeMapClearExplore(param['mapId']);
    }
    else if (name == Assets.notifyChanged) {
      _refreshRooms();
    }
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      _updateOnPrivacyLevelChanged();
    }
  }

  void _updateOnPrivacyLevelChanged() {
    if (Auth2().privacyMatch(2)) {
      LocationServices().status.then((LocationServicesStatus? locationServicesStatus) {
        _locationServicesStatus = locationServicesStatus;
        _enableMyLocationOnMap();
      });
    }
    else {
      _enableMyLocationOnMap();
    }
  }

  void _onLocationServicesStatusChanged(LocationServicesStatus? status) {
    if (Auth2().privacyMatch(2)) {
      _locationServicesStatus = status;
      _enableMyLocationOnMap();
    }
  }

  void _onNativeMapSelectExplore(int? mapID, dynamic laundryJson) {
    if (_nativeMapController!.mapId == mapID) {
      dynamic laundry;
      if (laundryJson is Map) {
        laundry = LaundryRoom.fromJson(JsonUtils.mapValue(laundryJson));
      }
      else if (laundryJson is List) {
        laundry = [];
        for (dynamic jsonEntry in laundryJson) {
          LaundryRoom? laundryEntry = LaundryRoom.fromJson(jsonEntry);
          if (laundryEntry != null) {
            laundry.add(laundryEntry);
          }
        }
      }

      if (laundry != null) {
        _selectMapLaundry(laundry);
      }
    }
  }

  void _onNativeMapClearExplore(int? mapID) {
    if (_nativeMapController!.mapId == mapID) {
      _selectMapLaundry(null);
    }
  }

  void _refreshRooms() {
    Laundries().getRoomData().then((List<LaundryRoom>? laundryRooms) {
      setState(() {
        _rooms = laundryRooms;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHeaderBar(),
      body: _loading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : _buildContentWidget(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  AppBar _buildHeaderBar() {
    return AppBar(
      leading: Semantics(
          label: Localization().getStringEx('headerbar.back.title', 'Back'),
          hint: Localization().getStringEx('headerbar.back.hint', ''),
          button: true,
          child: IconButton(
              icon: Image.asset('images/chevron-left-white.png', excludeFromSemantics: true),
              onPressed: () {
                Navigator.pop(context);
              })),
      actions: <Widget>[
        Column(
            children: <Widget>[
              Expanded(child: Row(children: <Widget>[
                ExploreViewTypeTab(label: Localization().getStringEx('panel.laundry_home.button.list.title', 'List'),
                  hint: Localization().getStringEx('panel.laundry_home.button.list.hint', ''),
                  iconResource: 'images/icon-list-view.png',
                  selected: (_displayType == _DisplayType.List),
                  onTap: () {
                    _selectDisplayType(_DisplayType.List);
                  },),
                Container(width: 10,),
                ExploreViewTypeTab(label: Localization().getStringEx('panel.laundry_home.button.map.title', 'Map'),
                  hint: Localization().getStringEx('panel.laundry_home.button.map.hint', ''),
                  iconResource: 'images/icon-map-view.png',
                  selected: (_displayType == _DisplayType.Map),
                  onTap: () {
                    _selectDisplayType(_DisplayType.Map);
                  },),
              ],)),
            ]),
      ],
      title: Text(
        Localization()
            .getStringEx('panel.laundry_home.heading.laundry', 'Laundry')!,
        style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontFamily: Styles().fontFamilies!.extraBold,
            letterSpacing: 1),
      ),
      centerTitle: false,
    );
  }

  Widget _buildContentWidget() {
    int roomsCount = _rooms?.length ?? 0;
    if (roomsCount == 0) {
      return Center(
        child: Text(
          Localization().getStringEx(
              'panel.laundry_home.content.empty', 'No rooms available')!,
          style: TextStyle(
              fontSize: 16,
              color: Styles().colors!.fillColorPrimary,
              fontFamily: Styles().fontFamilies!.bold),
        ),
      );
    }
    return Column(
      children: <Widget>[
        Expanded(
            child: Stack(
              children: <Widget>[
                _buildMapView(context),
                Visibility(
                    visible: (_displayType == _DisplayType.List),
                    child: Container(
                      color: Styles().colors!.background,
                      child: Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Container(
                              color: Styles().colors!.background,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 16, right: 16, bottom: 80),
                                    child: ListView.separated(
                                        physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          LaundryRoom laundryRoom = _rooms![index];
                                          return LaundryRoomRibbonButton(
                                            label: laundryRoom.title,
                                            onTap: () => _onRoomTap(laundryRoom),
                                          );
                                        },
                                        separatorBuilder: (context, index) =>
                                            Container(),
                                        itemCount: roomsCount),
                                  )
                                ],
                              )),
                        ),
                      ),
                    )),
              ],
            )),
      ],
    );
  }

  Widget _buildMapView(BuildContext context) {
    String? title, description;
    if (_selectedMapLaundry is LaundryRoom) {
      title = _selectedMapLaundry.title ?? '';
      description = _selectedMapLaundry.campusName ?? '';
    }
    else if (_selectedMapLaundry is List<LaundryRoom>) {
      title = sprintf(Localization().getStringEx('panel.laundry_home.map.popup.title.format', '%d Laundries')!, [_selectedMapLaundry.length]);
      description = _selectedMapLaundry.first?.campusName ?? '';
    }

    return Stack(clipBehavior: Clip.hardEdge, children: <Widget>[
      (_mapAllowed == true) ? MapWidget(
        onMapCreated: _onNativeMapCreated,
        creationParams: { "myLocationEnabled": _userLocationEnabled()},
      ) : Container(),
      Positioned(
          bottom: _mapLaundryBarAnimationController.value,
          left: 0,
          right: 0,
          child: Container(
            height: _MapBarHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26, width: 1.0),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4)),
            ),
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text((title != null) ? title : "",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Styles().colors!.fillColorPrimary,
                              fontFamily: Styles().fontFamilies!.bold,
                              fontSize: 16)),
                      Text((description != null) ? description : "",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.black38,
                              fontFamily: Styles().fontFamilies!.medium,
                              fontSize: 14)),
                      Container(
                        height: 8,
                      ),
                      Row(
                        children: <Widget>[
                          _userLocationEnabled() ?
                          Row(
                              children: <Widget>[
                                RoundedButton(
                                    label: Localization().getStringEx('panel.laundry_home.button.directions.title', 'Directions'),
                                    hint: Localization().getStringEx('panel.laundry_home.button.directions.hint', ''),
                                    backgroundColor: Colors.white,
                                    fontSize: 16.0,
                                    textColor: Styles().colors!.fillColorPrimary,
                                    borderColor: Styles().colors!.fillColorSecondary,
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                    onTap: () {
                                      Analytics().logSelect(target: 'Directions');
                                      _presentMapLaundryDirections(context);
                                    }),
                                Container(
                                  width: 12,
                                ),
                              ]) :
                          Container(),
                          RoundedButton(
                              label: Localization().getStringEx('panel.laundry_home.button.details.title', 'Details'),
                              hint: Localization().getStringEx('panel.laundry_home.button.details.hint', ''),
                              backgroundColor: Colors.white,
                              fontSize: 16.0,
                              textColor: Styles().colors!.fillColorPrimary,
                              borderColor: Styles().colors!.fillColorSecondary,
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              onTap: () {
                                Analytics().logSelect(target: 'Details');
                                _presentMapLaundryDetail(context);
                              }),


                        ],
                      )
                    ])),
          ))
    ]);
  }

  void _loadRooms() {
    _setLoading(true);
    Laundries()
        .getRoomData()
        .then((laundryRooms) => _onRoomsLoaded(laundryRooms));
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _loading = loading;
      });
    }
  }

  void _selectDisplayType(_DisplayType displayType) {
    Analytics().logSelect(target: displayType.toString());
    if (_displayType != displayType) {
      setState(() {
        _displayType = displayType;
        _mapAllowed = (_displayType == _DisplayType.Map) || (_mapAllowed == true);
        _enableMap(_displayType == _DisplayType.Map);
      });
    }
  }

  void _onRoomsLoaded(List<LaundryRoom>? laundryRooms) {
    _rooms = laundryRooms;
    _setLoading(false);
  }

  void _onRoomTap(LaundryRoom room) {
    Analytics().logSelect(target: "Room Tap: " + room.id!);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryDetailPanel(room: room,)));
  }

  void _selectMapLaundry(dynamic laundry) {
    if (laundry != null) {
      setState(() {
        _selectedMapLaundry = laundry;
      });
      _mapLaundryBarAnimationController.forward();
    }
    else if (_selectedMapLaundry != null) {
      _mapLaundryBarAnimationController.reverse().then((_) {
        setState(() {
          _selectedMapLaundry = null;
        });
      });
    }
  }

  void _presentMapLaundryDirections(BuildContext context) async {
    dynamic laundry = _selectedMapLaundry;
    _mapLaundryBarAnimationController.reverse().then((_) {
      setState(() {
        _selectedMapLaundry = null;
      });
    });
    if (laundry != null) {
      NativeCommunicator().launchExploreMapDirections(target: laundry);
    }
  }

  void _presentMapLaundryDetail(BuildContext context) {
    dynamic laundry = _selectedMapLaundry;
    _mapLaundryBarAnimationController.reverse().then((_) {
      setState(() {
        _selectedMapLaundry = null;
      });
    });

    if (laundry is LaundryRoom) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryDetailPanel(room: laundry,)));
    }
    else if (laundry is List) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryListPanel(rooms: laundry as List<LaundryRoom>?,)));
    }
  }

  void _onNativeMapCreated(mapController) {
    this._nativeMapController = mapController;
    _placeLaundryRoomsOnMap(_rooms);
    _enableMap(_displayType == _DisplayType.Map);
    _enableMyLocationOnMap();
  }

  void _enableMap(bool enable) {
    if (_nativeMapController != null) {
      _nativeMapController!.enable(enable);
      Analytics().logMapDisplay(action: enable ? Analytics.LogMapDisplayShowActionName : Analytics.LogMapDisplayHideActionName);
    }
  }

  void _enableMyLocationOnMap() {
    if (_nativeMapController != null) {
      _nativeMapController!.enableMyLocation(_userLocationEnabled());
    }
  }

  bool _userLocationEnabled() {
    return Auth2().privacyMatch(2) && (_locationServicesStatus == LocationServicesStatus.permissionAllowed);
  }

  void _placeLaundryRoomsOnMap(List<LaundryRoom>? rooms) {
    if (_nativeMapController != null) {
      _nativeMapController!.placePOIs(rooms);
    }
  }
}

