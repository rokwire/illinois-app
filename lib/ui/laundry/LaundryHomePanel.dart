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
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/laundry/LaundryRoomDetailPanel.dart';
import 'package:illinois/ui/laundry/LaundryListPanel.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/MapWidget.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';


enum _DisplayType { List, Map }

class LaundryHomePanel extends StatefulWidget {
  final LaundrySchool? laundrySchool;

  LaundryHomePanel({Key? key, this.laundrySchool}) : super(key: key);

  @override
  _LaundryHomePanelState createState() => _LaundryHomePanelState();
}

class _LaundryHomePanelState extends State<LaundryHomePanel> with SingleTickerProviderStateMixin implements NotificationsListener {
  static const double _MapBarHeight = 114;

  LaundrySchool? _laundrySchool;
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
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      FlexUI.notifyChanged,
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

    _laundrySchool = widget.laundrySchool;
    if (_laundrySchool == null) {
      _loadSchool();
    }
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
      _onNativeMapSelectExplore(param);
    }
    else if (name == NativeCommunicator.notifyMapClearExplore) {
      _onNativeMapClearExplore(param);
    }
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      _updateLocationServicesStatus();
    }
    else if (name == FlexUI.notifyChanged) {
      _updateLocationServicesStatus();
    }
  }

  void _updateLocationServicesStatus() {
    if (FlexUI().isLocationServicesAvailable) {
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
    if (FlexUI().isLocationServicesAvailable) {
      _locationServicesStatus = status;
      _enableMyLocationOnMap();
    }
  }

  void _onNativeMapSelectExplore(Map<String, dynamic>? params) {
    int? mapId = (params != null) ? JsonUtils.intValue(params['mapId']) : null;
    if (_nativeMapController!.mapId == mapId) {
      dynamic laundry;
      dynamic laundryJson = (params != null) ? params['explore'] : null;
      if (laundryJson is Map) {
        laundry = LaundryRoom.fromNativeMapJson(JsonUtils.mapValue(laundryJson));
      }
      else if (laundryJson is List) {
        laundry = <LaundryRoom>[];
        for (dynamic jsonEntry in laundryJson) {
          LaundryRoom? laundryEntry = LaundryRoom.fromNativeMapJson(jsonEntry);
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

  void _onNativeMapClearExplore(Map<String, dynamic>? params) {
    int? mapId = (params != null) ? JsonUtils.intValue(params['mapId']) : null;
    if (_nativeMapController!.mapId == mapId) {
      _selectMapLaundry(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.laundry_home.heading.laundry', 'Laundry'),),
      body: _loading ? Center(child: CircularProgressIndicator(),) : _buildContentWidget(),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  /*PreferredSizeWidget _buildHeaderBar() {
    return AppBar(
      leading: Semantics(
        label: Localization().getStringEx('headerbar.back.title', 'Back'),
        hint: Localization().getStringEx('headerbar.back.hint', ''),
        button: true,
        child: IconButton(
          icon: Image.asset('images/chevron-left-white.png', excludeFromSemantics: true),
          onPressed: _onTapBack)
        ),
      actions: <Widget>[
        Column(children: <Widget>[
          Expanded(child:
            Row(children: <Widget>[
              ExploreViewTypeTab(
                label: Localization().getStringEx('panel.laundry_home.button.list.title', 'List'),
                hint: Localization().getStringEx('panel.laundry_home.button.list.hint', ''),
                iconResource: 'images/icon-list-view.png',
                selected: (_displayType == _DisplayType.List),
                onTap: _onTapList,
              ),
              
              Container(width: 10,),
              
              ExploreViewTypeTab(
                label: Localization().getStringEx('panel.laundry_home.button.map.title', 'Map'),
                hint: Localization().getStringEx('panel.laundry_home.button.map.hint', ''),
                iconResource: 'images/icon-map-view.png',
                selected: (_displayType == _DisplayType.Map),
                onTap: _onTapMap,
              ),
            ],),
          ),
        ]),
      ],
      title: Text(Localization().getStringEx('panel.laundry_home.heading.laundry', 'Laundry'),
        style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 16, color: Colors.white, letterSpacing: 1),
      ),
      centerTitle: false,
    );
  }

  void _onTapMap() {
    Analytics().logSelect(target: 'Map');
    _selectDisplayType(_DisplayType.Map);
  }

  void _onTapList() {
    Analytics().logSelect(target: 'List');
    _selectDisplayType(_DisplayType.List);
  }

  void _onTapBack() {
    Analytics().logSelect(target: 'Back');
    Navigator.pop(context);
  }*/

  Widget _buildContentWidget() {
    if (_loading == true) {
      return _buildProgressContentWidget();
    }
    else if (CollectionUtils.isEmpty(_laundrySchool?.rooms)) {
      return _buildEmptyContentWidget();
    }
    else {
      return _buildRoomsContentWidget();
    }
  }

  Widget _buildRoomsContentWidget() {
    return Column(children: <Widget>[
      Expanded(child:
        Stack(children: <Widget>[
          _buildMapView(context),
          Visibility(visible: (_displayType == _DisplayType.List), child:
            Container(color: Styles().colors?.background, child:
              Padding(padding: EdgeInsets.only(top: 16), child:
                SingleChildScrollView(scrollDirection: Axis.vertical, child:
                  Container(color: Styles().colors?.background, child:
                    Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                      Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 80), child:
                        ListView.separated(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemBuilder: _buildListItem,
                          separatorBuilder: _buildListSeparator,
                          itemCount: _laundrySchool?.rooms?.length ?? 0
                        ),
                      ),
                    ],),
                  ),
                ),
              ),
            ),
          ),
        ],),
      ),
    ],);
  }

  Widget _buildEmptyContentWidget() {
    return Center(child:
      Padding(padding: EdgeInsets.all(32), child:
        Text(Localization().getStringEx('panel.laundry_home.content.empty', 'No rooms available'), style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 16, color: Styles().colors?.fillColorPrimary,),),
      )
    );
  }

  Widget _buildProgressContentWidget() {
    return Center(child:
      CircularProgressIndicator(),
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    LaundryRoom? laundryRoom = (_laundrySchool?.rooms != null) ? _laundrySchool?.rooms![index] : null;
    return (laundryRoom != null) ? LaundryRoomRibbonButton(
      label: laundryRoom.name,
      onTap: () => _onRoomTap(laundryRoom),
    ) : Container();
  }

  Widget _buildListSeparator(BuildContext context, int index) {
    return Container();
  }

  Widget _buildMapView(BuildContext context) {
    String? title;
    if (_selectedMapLaundry is LaundryRoom) {
      title = _selectedMapLaundry.name ?? '';
    }
    else if (_selectedMapLaundry is List<LaundryRoom>) {
      title = sprintf(Localization().getStringEx('panel.laundry_home.map.popup.title.format', '%d Laundries'), [_selectedMapLaundry.length]);
    }
    
    String description = StringUtils.ensureNotEmpty(_laundrySchool?.schoolName);
    double buttonWidth = (MediaQuery.of(context).size.width - (40 + 12 + 2)) / 2;

    return Stack(clipBehavior: Clip.hardEdge, children: <Widget>[
      (_mapAllowed == true) ? MapWidget(
        onMapCreated: _onNativeMapCreated,
        creationParams: { "myLocationEnabled": _userLocationEnabled(), "levelsEnabled": Storage().debugMapShowLevels},
      ) : Container(),
      
      Positioned(bottom: _mapLaundryBarAnimationController.value, left: 0, right: 0, child:
        Container(height: _MapBarHeight, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black26, width: 1.0), borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),), child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(title ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors?.fillColorPrimary,),),
              Text(description, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 14, color: Colors.black38,),),
              Container(height: 8,),
              Row(children: <Widget>[
                _userLocationEnabled() ? Row(children: <Widget>[
                  SizedBox(width: buttonWidth, child:
                    RoundedButton(
                      label: Localization().getStringEx('panel.laundry_home.button.directions.title', 'Directions'),
                      hint: Localization().getStringEx('panel.laundry_home.button.directions.hint', ''),
                      backgroundColor: Colors.white,
                      fontSize: 16.0,
                      textColor: Styles().colors?.fillColorPrimary,
                      borderColor: Styles().colors?.fillColorSecondary,
                      contentWeight: 0.0,
                      onTap: _onTapDirections
                    ),
                  ),
                  Container(width: 12,),
                ]) : Container(),
                SizedBox(width: buttonWidth, child:
                  RoundedButton(
                    label: Localization().getStringEx('panel.laundry_home.button.details.title', 'Details'),
                    hint: Localization().getStringEx('panel.laundry_home.button.details.hint', ''),
                    backgroundColor: Colors.white,
                    fontSize: 16.0,
                    textColor: Styles().colors?.fillColorPrimary,
                    borderColor: Styles().colors?.fillColorSecondary,
                    onTap: _onTapDetails
                  ),
                ),
              ],)
            ]),
          ),
        ),
      ),
    ]);
  }

  void _loadSchool() {
    setState(() { _loading = true; });
    Laundries().loadSchoolRooms().then((laundrySchool) => _onSchoolLoaded(laundrySchool));
  }

  /*void _selectDisplayType(_DisplayType displayType) {
    Analytics().logSelect(target: displayType.toString());
    if (_displayType != displayType) {
      setState(() {
        _displayType = displayType;
        _mapAllowed = (_displayType == _DisplayType.Map) || (_mapAllowed == true);
        _enableMap(_displayType == _DisplayType.Map);
      });
    }
  }*/

  void _onSchoolLoaded(LaundrySchool? laundrySchool) {
    if (mounted) {
      setState(() {
        _laundrySchool = laundrySchool;
        _loading = false;
      });
    }
  }

  void _onRoomTap(LaundryRoom room) {
    Analytics().logSelect(target: "Room Tap: " + room.id!);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryRoomDetailPanel(room: room,)));
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

  void _onTapDirections() {
    Analytics().logSelect(target: 'Directions');
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

  void _onTapDetails() {
    Analytics().logSelect(target: 'Details');
    dynamic laundry = _selectedMapLaundry;
    _mapLaundryBarAnimationController.reverse().then((_) {
      setState(() {
        _selectedMapLaundry = null;
      });
    });

    if (laundry is LaundryRoom) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryRoomDetailPanel(room: laundry,)));
    }
    else if (laundry is List) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryListPanel(rooms: laundry as List<LaundryRoom>?,)));
    }
  }

  void _onNativeMapCreated(mapController) {
    this._nativeMapController = mapController;
    _placeLaundryRoomsOnMap(_laundrySchool?.rooms);
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
    return FlexUI().isLocationServicesAvailable && (_locationServicesStatus == LocationServicesStatus.permissionAllowed);
  }

  void _placeLaundryRoomsOnMap(List<LaundryRoom>? rooms) {
    if (_nativeMapController != null) {
      _nativeMapController!.placePOIs(rooms);
    }
  }
}

