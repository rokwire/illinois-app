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

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/geo_fence.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';
import 'package:rokwire_plugin/service/firebase_core.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/debug/DebugCreateInboxMessagePanel.dart';
import 'package:illinois/ui/debug/DebugInboxUserInfoPanel.dart';
import 'package:illinois/ui/debug/DebugGuidePanel.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/debug/DebugStylesPanel.dart';
import 'package:illinois/ui/debug/DebugHttpProxyPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';

import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/config.dart' as rokwire;

class DebugHomePanel extends StatefulWidget {
  @override
  _DebugHomePanelState createState() => _DebugHomePanelState();
}

class _DebugHomePanelState extends State<DebugHomePanel> implements NotificationsListener {

  DateTime? _offsetDate;
  rokwire.ConfigEnvironment? _selectedEnv;
  Set<String> _rangingRegionIds = Set();

  final TextEditingController _mapThresholdDistanceController = TextEditingController();
  final TextEditingController _geoFenceRegionRadiusController = TextEditingController();

  @override
  void initState() {
    
    NotificationService().subscribe(this, [
      Config.notifyEnvironmentChanged,
      Styles.notifyChanged,
      GeoFence.notifyCurrentRegionsUpdated,
      GeoFence.notifyCurrentBeaconsUpdated,
    ]);

    _offsetDate = Storage().offsetDate;
    
    int? geoFenceRegionRadius = Storage().debugGeoFenceRegionRadius;

    _mapThresholdDistanceController.text = '${Storage().debugMapThresholdDistance}';
    _geoFenceRegionRadiusController.text = (geoFenceRegionRadius != null) ? '$geoFenceRegionRadius' : '';

    _selectedEnv = Config().configEnvironment;

    _updateRangingRegions();
    super.initState();
  }

  @override
  void dispose() {
    
    NotificationService().unsubscribe(this);

    _stopRangingRegions();

    // Map Threshold Distance
    int? mapThresholdDistance = int.tryParse(_mapThresholdDistanceController.text);
    if (mapThresholdDistance != null) {
      Storage().debugMapThresholdDistance = mapThresholdDistance;
    }
    _mapThresholdDistanceController.dispose();

    // Geo Fence
    int? storageGeoFenceRegionRadius = Storage().debugGeoFenceRegionRadius;
    int? geoFenceRegionRadius = int.tryParse(_geoFenceRegionRadiusController.text);
    if (((storageGeoFenceRegionRadius == null) && (geoFenceRegionRadius != null)) ||
        ((storageGeoFenceRegionRadius != null) && (geoFenceRegionRadius == null)) ||
        ((storageGeoFenceRegionRadius != null) && (geoFenceRegionRadius != null) && (storageGeoFenceRegionRadius != geoFenceRegionRadius)))
    {
      Storage().debugGeoFenceRegionRadius = geoFenceRegionRadius;
    }
    _geoFenceRegionRadiusController.dispose();

    super.dispose();
  }

  String? get _userDebugData{
    String? userData = JsonUtils.encode(Auth2().account?.toJson(), prettify: true);
    return userData;
  }

  @override
  Widget build(BuildContext context) {
    String? userUuid = Auth2().accountId;
    String? pid = Auth2().profile?.id;
    String? firebaseProjectId = FirebaseCore().app?.options.projectId;
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
          Localization().getStringEx("panel.debug.header.title", "Debug")!,
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                color: Styles().colors!.background,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: Text(StringUtils.isNotEmpty(userUuid) ? 'Uuid: $userUuid' : "unknown uuid"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: Text(StringUtils.isNotEmpty(pid) ? 'PID: $pid' : "unknown pid"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: Text('Firebase: $firebaseProjectId'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: Text('GeoFence: $_geoFenceStatus'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: Text('Beacon: $_beaconsStatus'),
                    ),
                    
                    Container(height: 1, color: Styles().colors!.surfaceAccent),
                    ToggleRibbonButton(label: 'Disable live game check', toggled: Storage().debugDisableLiveGameCheck, onTap: _onDisableLiveGameCheckToggled),
                    ToggleRibbonButton(label: 'Display all times in Central Time', toggled: !Storage().useDeviceLocalTimeZone!, onTap: _onUseDeviceLocalTimeZoneToggled),
                    ToggleRibbonButton(label: 'Show map location source', toggled: Storage().debugMapLocationProvider, onTap: _onMapLocationProvider),
                    ToggleRibbonButton(label: 'Show map levels', toggled: !Storage().debugMapHideLevels!, onTap: _onMapShowLevels),
                    Container(height: 1, color: Styles().colors!.surfaceAccent),
                    Container(color: Colors.white, child: Padding(padding: EdgeInsets.only(top: 5), child: Container(height: 1, color: Styles().colors!.surfaceAccent))),
                    Container(
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: TextFormField(
                              controller: _mapThresholdDistanceController,
                              keyboardType: TextInputType.number,
                              validator: _validateThresoldDistance,
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(), hintText: "Enter map threshold distance in meters", labelText: 'Threshold Distance (meters)')),
                        )),
                    Container(color: Colors.white,child: Padding(padding: EdgeInsets.symmetric(vertical: 5), child: Container(height: 1, color: Styles().colors!.surfaceAccent))),
                    Container(
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: TextFormField(
                              controller: _geoFenceRegionRadiusController,
                              keyboardType: TextInputType.number,
                              validator: _validateGeoFenceRegionRadius,
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(), hintText: "Enter geo fence region radius in meters", labelText: 'Geo Fence Region Radius (meters)')),
                        )),
                    Container(color: Colors.white, child: Padding(padding: EdgeInsets.only(top: 5), child: Container(height: 1, color: Styles().colors!.surfaceAccent))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Padding(
                      padding: EdgeInsets.only(left: 16), child: Text('Config Environment: '),), ListView.separated(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      separatorBuilder: (context, index) => Divider(color: Colors.transparent),
                      itemCount: rokwire.ConfigEnvironment.values.length,
                      itemBuilder: (context, index) {
                        rokwire.ConfigEnvironment environment = rokwire.ConfigEnvironment.values[index];
                        RadioListTile widget = RadioListTile(
                            title: Text(rokwire.configEnvToString(environment)!), value: environment, groupValue: _selectedEnv, onChanged: _onConfigChanged);
                        return widget;
                      },
                    )
                    ],),),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            child: RoundedButton(
                              label: "Clear Offset",
                              backgroundColor: Styles().colors!.background,
                              fontSize: 16.0,
                              textColor: Styles().colors!.fillColorPrimary,
                              borderColor: Styles().colors!.fillColorPrimary,
                              contentWeight: 0.0,
                              onTap: () {
                                _clearDateOffset();
                              },
                            )),
                        Expanded(
                            child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: Text(_offsetDate != null ? AppDateTime().formatDateTime(_offsetDate, format: 'MM/dd/yyyy HH:mm:ss a')! : "None",
                              textAlign: TextAlign.end),
                        ))
                      ],
                    ),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: RoundedButton(
                          label: "Sports Offset",
                          backgroundColor: Styles().colors!.background,
                          fontSize: 16.0,
                          textColor: Styles().colors!.fillColorPrimary,
                          borderColor: Styles().colors!.fillColorPrimary,
                          onTap: () {
                            _changeDate();
                          },
                        )),
                    Visibility(
                      visible: true,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "Create Event",
                              backgroundColor: Styles().colors!.background,
                              fontSize: 16.0,
                              textColor: Styles().colors!.fillColorPrimary,
                              borderColor: Styles().colors!.fillColorPrimary,
                              onTap: _onCreateEventClicked),),
                    ),
                    Visibility(
                      visible: true,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: RoundedButton(
                            label: "Inbox User Info",
                            backgroundColor: Styles().colors!.background,
                            fontSize: 16.0,
                            textColor: Styles().colors!.fillColorPrimary,
                            borderColor: Styles().colors!.fillColorPrimary,
                            onTap: _onInboxUserInfoClicked),),
                    ),
                    Visibility(
                      visible: true,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "Create Message",
                              backgroundColor: Styles().colors!.background,
                              fontSize: 16.0,
                              textColor: Styles().colors!.fillColorPrimary,
                              borderColor: Styles().colors!.fillColorPrimary,
                              onTap: _onCreateInboxMessageClicked),),
                    ),
                    Visibility(
                      visible: true,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "User Profile Info",
                              backgroundColor: Styles().colors!.background,
                              fontSize: 16.0,
                              textColor: Styles().colors!.fillColorPrimary,
                              borderColor: Styles().colors!.fillColorPrimary,
                              onTap: _onUserProfileInfoClicked
                              )),
                    ),
                    Visibility(
                      visible: true,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "User Card Info",
                              backgroundColor: Styles().colors!.background,
                              fontSize: 16.0,
                              textColor: Styles().colors!.fillColorPrimary,
                              borderColor: Styles().colors!.fillColorPrimary,
                              onTap: () { _onUserCardInfoClicked(); }
                              )),
                    ),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: RoundedButton(
                            label: "Clear voting",
                            backgroundColor: Styles().colors!.background,
                            fontSize: 16.0,
                            textColor: Styles().colors!.fillColorPrimary,
                            borderColor: Styles().colors!.fillColorPrimary,
                            onTap: _onTapClearVoting)),
                    Visibility(
                      visible: Config().configEnvironment == rokwire.ConfigEnvironment.dev,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "Campus Guide",
                              backgroundColor: Styles().colors!.background,
                              fontSize: 16.0,
                              textColor: Styles().colors!.fillColorPrimary,
                              borderColor: Styles().colors!.fillColorPrimary,
                              onTap: _onTapGuide))
                    ),
                    Visibility(
                      visible: Config().configEnvironment == rokwire.ConfigEnvironment.dev,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "Styles",
                              backgroundColor: Styles().colors!.background,
                              fontSize: 16.0,
                              textColor: Styles().colors!.fillColorPrimary,
                              borderColor: Styles().colors!.fillColorPrimary,
                              onTap: _onTapStyles)),
                    ),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: RoundedButton(
                            label: _refreshTokenTitle,
                            backgroundColor: Styles().colors!.background,
                            fontSize: 16.0,
                            textColor: Styles().colors!.fillColorPrimary,
                            borderColor: Styles().colors!.fillColorPrimary,
                            onTap: _onTapRefreshToken)),
                    Visibility(
                      visible: Config().configEnvironment == rokwire.ConfigEnvironment.dev,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "Http Proxy",
                              backgroundColor: Styles().colors!.background,
                              fontSize: 16.0,
                              textColor: Styles().colors!.fillColorPrimary,
                              borderColor: Styles().colors!.fillColorPrimary,
                              onTap: _onTapHttpProxy)),
                    ),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: RoundedButton(
                            label: "Test Crash",
                            backgroundColor: Styles().colors!.background,
                            fontSize: 16.0,
                            textColor: Styles().colors!.fillColorPrimary,
                            borderColor: Styles().colors!.fillColorPrimary,
                            onTap: _onTapCrash)),
                    Padding(padding: EdgeInsets.only(top: 5), child: Container()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == GeoFence.notifyCurrentRegionsUpdated) {
      _updateRangingRegions();
      setState(() {});
    }
    else if (name == GeoFence.notifyCurrentBeaconsUpdated) {
      setState(() {});
    }
    else if(name == Config.notifyEnvironmentChanged){
      setState(() {});
    }
    else if(name == Styles.notifyChanged){
      setState(() {});
    }
  }

  // Helpers

  String? _validateThresoldDistance(String? value) {
    return (int.tryParse(value!) == null) ? 'Please enter a number.' : null;
  }

  String? _validateGeoFenceRegionRadius(String? value) {
    return (int.tryParse(value!) == null) ? 'Please enter a number.' : null;
  }
  
  _clearDateOffset() {
    setState(() {
      Storage().offsetDate = _offsetDate = null;
    });
  }

  _changeDate() async {
    DateTime offset = _offsetDate ?? DateTime.now();

    DateTime firstDate = DateTime.fromMillisecondsSinceEpoch(offset.millisecondsSinceEpoch).add(Duration(days: -365));
    DateTime lastDate = DateTime.fromMillisecondsSinceEpoch(offset.millisecondsSinceEpoch).add(Duration(days: 365));

    DateTime? date = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: offset,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light(),
          child: child!,
        );
      },
    );

    if (date == null) return;

    TimeOfDay? time = await showTimePicker(context: context, initialTime: new TimeOfDay(hour: date.hour, minute: date.minute));
    if (time == null) return;

    int endHour = time.hour;
    int endMinute = time.minute;
    offset = new DateTime(date.year, date.month, date.day, endHour, endMinute);

    setState(() {
      Storage().offsetDate = _offsetDate = offset;
    });
  }

  String get _geoFenceStatus {

    String inside = '';
    for (String regionId in GeoFence().currentRegionIds) {
        if (inside.isNotEmpty) {
          inside += ', ';
        }
        inside += regionId;
    }
    int regionsCount = GeoFence().regionsList(enabled: true).length;
    return '[$inside] / [#$regionsCount] ...';
  }

  String get _beaconsStatus {
    GeoFenceBeacon? beacon = _currentBeacon;
    return (beacon != null) ? '{${beacon.uuid!.toLowerCase()} ${beacon.major}:${beacon.minor}}' : '...';
  }

  GeoFenceBeacon? get _currentBeacon {
    // Just return the first beacon that we have for now.
    for (String regionId in _rangingRegionIds) {
      List<GeoFenceBeacon>? regionBacons = GeoFence().currentBeaconsInRegion(regionId);
      if ((regionBacons != null) && regionBacons.isNotEmpty) {
        return regionBacons.first;
      }
    }
    return null;
  }

  void _updateRangingRegions() {
    Set<String> currentRegionIds = GeoFence().currentRegionIds;
    
    // 1. Remove all ranging regions that are not current (inside)
    Set<String>? removeRegionIds;
    for (String regionId in _rangingRegionIds) {
      if (!currentRegionIds.contains(regionId)) {
        GeoFence().stopRangingBeaconsInRegion(regionId);
        if (removeRegionIds == null) {
          removeRegionIds = Set();
        }
        removeRegionIds.add(regionId);
      }
    }
    if (removeRegionIds != null) {
      _rangingRegionIds.removeAll(removeRegionIds);
    }

    // 2. Start ranging for all current (inside) regions that are not already raning.
    for (String regionId in currentRegionIds) {
      GeoFenceRegion region = GeoFence().regions![regionId]!;
      if ((region.regionType == GeoFenceRegionType.beacon) && !_rangingRegionIds.contains(regionId)) {
        GeoFence().startRangingBeaconsInRegion(regionId).then((_) {
          _rangingRegionIds.add(regionId);
        });
      }
    }
  }

  void _stopRangingRegions() {
    for (String regionId in _rangingRegionIds) {
      GeoFence().stopRangingBeaconsInRegion(regionId);
    }
    _rangingRegionIds.clear();
  }

  void _onDisableLiveGameCheckToggled() {
    setState(() {
      Storage().debugDisableLiveGameCheck = (Storage().debugDisableLiveGameCheck != true);
    });
  }

  void _onMapLocationProvider() {
    setState(() {
      Storage().debugMapLocationProvider = !Storage().debugMapLocationProvider!;
    });
  }

  void _onMapShowLevels() {
    setState(() {
      Storage().debugMapHideLevels = !Storage().debugMapHideLevels!;
    });
  }

  void _onUseDeviceLocalTimeZoneToggled() {
    setState(() {
      Storage().useDeviceLocalTimeZone = !Storage().useDeviceLocalTimeZone!;
    });
  }

  void _onCreateEventClicked() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CreateEventPanel()));
  }

  void _onInboxUserInfoClicked(){
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugInboxUserInfoPanel()));
  }

  void _onCreateInboxMessageClicked() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugCreateInboxMessagePanel()));
  }
  
  
  void _onUserProfileInfoClicked() {
    showDialog(context: context, builder: (_) => _buildTextContentInfoDialog(_userDebugData) );
  }

  void _onUserCardInfoClicked() {
    String? cardInfo = JsonUtils.encode(Auth2().authCard?.toShortJson(), prettify: true);
    if (StringUtils.isNotEmpty(cardInfo)) {
      showDialog(context: context, builder: (_) => _buildTextContentInfoDialog(cardInfo) );
    }
    else {
      AppAlert.showDialogResult(context, 'No card available.');
    }
  }
  //

  Widget _buildTextContentInfoDialog(String? textContent) {
    return Material(type: MaterialType.transparency, borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)), child:
      Dialog(backgroundColor: Styles().colors!.background, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(color: Styles().colors!.fillColorPrimary, child:
            Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
              Container(width: 20,),
              Expanded(child:
                RoundedButton(
                  label: "Copy to clipboard",
                  textColor: Styles().colors!.white,
                  borderColor: Styles().colors!.fillColorSecondary,
                  backgroundColor: Styles().colors!.fillColorPrimary,
                  onTap: (){ _copyToClipboard(textContent); },
                ),
              ),
              Container(width: 20,),
              GestureDetector( onTap:  () => Navigator.of(context).pop(), child:
                Padding(padding: EdgeInsets.only(right: 10, top: 10), child:
                  Text('\u00D7', style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies!.medium, fontSize: 50 ),),
                ),
              ),
            ],),
          ),
          Expanded(child:
            SingleChildScrollView(child:
              Padding(padding: EdgeInsets.all(8), child: Text(StringUtils.ensureNotEmpty(textContent), style: TextStyle(color: Colors.black, fontFamily: Styles().fontFamilies!.bold, fontSize: 14)))
            )
          ),
        ])
      )
    );
  }

  void _copyToClipboard(String? textContent){
    Clipboard.setData(ClipboardData(text: textContent)).then((_){
      AppToast.show("Text data has been copied to the clipboard!");
    });
  }

  void _onTapClearVoting() {
    Storage().voterHiddenForPeriod = false;
    Auth2().prefs?.voter?.clear();
    AppAlert.showDialogResult(context, 'Successfully cleared user voting.');
  }

  void _onTapGuide() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugGuidePanel()));
  }

  void _onConfigChanged(dynamic env) {
    if (env is rokwire.ConfigEnvironment) {
      setState(() {
        Config().configEnvironment = env;
        _selectedEnv = Config().configEnvironment;
      });
    }
  }

  void _onTapHttpProxy() {
    if(Config().configEnvironment == rokwire.ConfigEnvironment.dev) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHttpProxyPanel()));
    }
  }

  void _onTapStyles() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugStylesPanel()));
  }

  void _onTapCrash(){
    FirebaseCrashlytics.instance.crash();
  }

  String get _refreshTokenTitle {
    Auth2Token? token = Auth2().token;
    if (token == Auth2().userToken) {
      return "Refresh User Token";
    }
    else if (token == Auth2().anonymousToken) {
      return "Refresh Anonymous Token";
    }
    else {
      return (token != null) ? "Refresh Token" : "Refresh Token NA";
    }
  }

  void _onTapRefreshToken() {
    Auth2Token? token = Auth2().token;
    if (token != null) {
      Auth2().refreshToken(token).then((token) {
        AppAlert.showDialogResult(context, (token != null) ? "Token refreshed successfully" : "Failed to refresh token");
      });
    }
    else {
      AppAlert.showDialogResult(context, "No token to refresh");
    }
  }

  // SettingsListenerMixin

  void onDateOffsetChanged() {
    setState(() {
      _offsetDate = Storage().offsetDate;
    });
  }
}
