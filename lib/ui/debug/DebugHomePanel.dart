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
import 'package:illinois/service/AppReview.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/debug/mobile_access/DebugMobileAccessHomePanel.dart';
import 'package:illinois/ui/debug/DebugRewardsPanel.dart';
import 'package:illinois/ui/debug/DebugStudentCoursesPanel.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/geo_fence.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';
import 'package:rokwire_plugin/service/firebase_core.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/surveys.dart';
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
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/panels/survey_creation_panel.dart';
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
  bool _preparingRatingApp = false;

  List<Survey>? _userSurveys;

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
    
    int? mapThresholdDistance = Storage().debugMapThresholdDistance;
    int? geoFenceRegionRadius = Storage().debugGeoFenceRegionRadius;

    _mapThresholdDistanceController.text = (mapThresholdDistance != null) ? '$mapThresholdDistance' : '';
    _geoFenceRegionRadiusController.text = (geoFenceRegionRadius != null) ? '$geoFenceRegionRadius' : '';

    _selectedEnv = Config().configEnvironment;

    _updateRangingRegions();
    _loadUserSurveys();
    super.initState();
  }

  @override
  void dispose() {
    
    NotificationService().unsubscribe(this);

    _stopRangingRegions();

    // Map Threshold Distance
    int? storageMapThresholdDistance = Storage().debugMapThresholdDistance;
    int? mapThresholdDistance = int.tryParse(_mapThresholdDistanceController.text);
    if (((storageMapThresholdDistance == null) && (mapThresholdDistance != null)) ||
        ((storageMapThresholdDistance != null) && (mapThresholdDistance == null)) ||
        ((storageMapThresholdDistance != null) && (mapThresholdDistance != null) && (storageMapThresholdDistance != mapThresholdDistance)))
    {
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
    String sportOffset = (_offsetDate != null) ? AppDateTime().formatDateTime(_offsetDate, format: 'MM/dd/yyyy HH:mm a')! : "None";
    String lastAppReviewTime = (AppReview().appReviewRequestTime != null) ? DateFormat('MM/dd/yyyy').format(DateTime.fromMillisecondsSinceEpoch(AppReview().appReviewRequestTime!)) : 'NA';

    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx("panel.debug.header.title", "Debug"),),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
      body: Column(children: <Widget>[
        Expanded(child:
          SingleChildScrollView(child:
            Container(color: Styles().colors!.background, child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Container(height: 16,),
                Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), child:
                  Text(StringUtils.isNotEmpty(userUuid) ? 'Uuid: $userUuid' : "unknown uuid"),
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), child:
                  Text(StringUtils.isNotEmpty(pid) ? 'PID: $pid' : "unknown pid"),
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), child:
                  Text('Firebase: $firebaseProjectId'),
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), child:
                  Text('GeoFence: $_geoFenceStatus'),
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), child:
                  Text('Beacon: $_beaconsStatus'),
                ),
                
                Padding(padding: EdgeInsets.only(top: 16), child: Container(height: 1, color: Styles().colors!.surfaceAccent),),

                ToggleRibbonButton(label: 'Disable live game check', toggled: Storage().debugDisableLiveGameCheck ?? false, onTap: _onDisableLiveGameCheckToggled),
                ToggleRibbonButton(label: 'Display all times in Central Time', toggled: !Storage().useDeviceLocalTimeZone!, onTap: _onUseDeviceLocalTimeZoneToggled),
                ToggleRibbonButton(label: 'Show map location source', toggled: Storage().debugMapLocationProvider ?? false, onTap: _onMapLocationProvider),
                ToggleRibbonButton(label: 'Show map levels', toggled: Storage().debugMapShowLevels!, onTap: _onMapShowLevels),
                ToggleRibbonButton(label: 'Canvas LMS', toggled: (Storage().debugUseCanvasLms == true), onTap: _onUseCanvasLms),
                ToggleRibbonButton(label: 'Sample Appointments', toggled: (Storage().debugUseSampleAppointments == true), onTap: _onUseSampleAppointments),
                ToggleRibbonButton(label: 'Mobile icard - Use Identity BB', toggled: (Storage().debugUseIdentityBb == true), onTap: _onUseIdentityBb),
                ToggleRibbonButton(label: 'Mobile icard - Automatic Credentials', toggled: (Storage().debugAutomaticCredentials == true), onTap: _onAutomaticCredentials),

                Container(color: Colors.white, child: Padding(padding: EdgeInsets.only(top: 16), child: Container(height: 1, color: Styles().colors!.surfaceAccent))),
                Container(color: Colors.white, child:
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16), child:
                    TextFormField(
                      controller: _mapThresholdDistanceController,
                      keyboardType: TextInputType.number,
                      validator: _validateThresoldDistance,
                      decoration: InputDecoration(
                      border: OutlineInputBorder(), hintText: "Enter map threshold distance in meters", labelText: 'Threshold Distance (meters)')
                    ),
                  )
                ),
                    
                Container(color: Colors.white,child: Padding(padding: EdgeInsets.only(bottom: 16), child: Container(height: 1, color: Styles().colors!.surfaceAccent))),
                Container(color: Colors.white, child:
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), child:
                    TextFormField(
                      controller: _geoFenceRegionRadiusController,
                      keyboardType: TextInputType.number,
                      validator: _validateGeoFenceRegionRadius,
                      decoration: InputDecoration(
                      border: OutlineInputBorder(), hintText: "Enter geo fence region radius in meters", labelText: 'Geo Fence Region Radius (meters)')
                    ),
                  )
                ),
                Container(color: Colors.white, child: Padding(padding: EdgeInsets.only(top: 16), child: Container(height: 1, color: Styles().colors!.surfaceAccent))),
                
                Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Padding(padding: EdgeInsets.only(left: 16, bottom: 16), child:
                      Text('Config Environment: ', style: TextStyle(color: Styles().colors?.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20 )),
                    ),
                    ListView.separated(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      separatorBuilder: (context, index) => Divider(color: Colors.transparent),
                      itemCount: rokwire.ConfigEnvironment.values.length,
                      itemBuilder: (context, index) {
                        rokwire.ConfigEnvironment environment = rokwire.ConfigEnvironment.values[index];
                        RadioListTile widget = RadioListTile(
                          title: Text(rokwire.configEnvToString(environment) ?? '',
                          style: TextStyle(color: Styles().colors?.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 16 )),
                          value: environment,
                          groupValue: _selectedEnv,
                          onChanged: _onConfigChanged
                        );
                        return widget;
                      },
                    )
                  ],),
                ),

                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Container(height: 1, color: Styles().colors?.surfaceAccent ,),),

                Visibility(
                  visible: Config().configEnvironment == rokwire.ConfigEnvironment.dev,
                  child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child: _buildSurveyCreation()),
                ),
                
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Container(height: 1, color: Styles().colors?.surfaceAccent ,),),
                
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                  Row(children: <Widget>[
                    Expanded(child:
                      Text('Sport Offset: $sportOffset'),
                    ),
                    RoundedButton(
                      label: "Edit",
                      backgroundColor: Styles().colors!.background,
                      fontSize: 16.0,
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorPrimary,
                      contentWeight: 0.0,
                      onTap: _changeDate,
                    ),
                    Container(width: 5,),
                    RoundedButton(
                      label: "Clear",
                      backgroundColor: Styles().colors!.background,
                      fontSize: 16.0,
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorPrimary,
                      contentWeight: 0.0,
                      onTap: _clearDateOffset,
                    ),
                  ],),
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                  Row(children: [
                    Expanded(child:
                      Text("Last App Review: $lastAppReviewTime"),
                    ),
                    RoundedButton(
                      label: "Clear",
                      backgroundColor: Styles().colors!.background,
                      fontSize: 16.0,
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorPrimary,
                      contentWeight: 0.0,
                      onTap: _clearLastAppReview,
                    ),
                  ],)
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                  RoundedButton(
                    label: "Clear Account Prefs",
                    backgroundColor: Styles().colors!.background,
                    fontSize: 16.0,
                    textColor: Styles().colors!.fillColorPrimary,
                    borderColor: Styles().colors!.fillColorPrimary,
                    onTap: _onTapClearAccountPrefs
                  )
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                  RoundedButton(
                    label: "Clear Voting",
                    backgroundColor: Styles().colors!.background,
                    fontSize: 16.0,
                    textColor: Styles().colors!.fillColorPrimary,
                    borderColor: Styles().colors!.fillColorPrimary,
                    onTap: _onTapClearVoting
                  )
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                  RoundedButton(
                    label: _refreshTokenTitle,
                    backgroundColor: Styles().colors!.background,
                    fontSize: 16.0,
                    textColor: Styles().colors!.fillColorPrimary,
                    borderColor: Styles().colors!.fillColorPrimary,
                    onTap: _onTapRefreshToken
                  )
                ),

                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Container(height: 1, color: Styles().colors?.surfaceAccent ,),),

                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                  RoundedButton(
                    label: "Create Event",
                    backgroundColor: Styles().colors!.background,
                    fontSize: 16.0,
                    textColor: Styles().colors!.fillColorPrimary,
                    borderColor: Styles().colors!.fillColorPrimary,
                    onTap: _onCreateEventClicked
                  ),
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                  RoundedButton(
                    label: "Create Message",
                    backgroundColor: Styles().colors!.background,
                    fontSize: 16.0,
                    textColor: Styles().colors!.fillColorPrimary,
                    borderColor: Styles().colors!.fillColorPrimary,
                    onTap: _onCreateInboxMessageClicked
                  ),
                ),

                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Container(height: 1, color: Styles().colors?.surfaceAccent ,),),

                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                  RoundedButton(
                    label: "Inbox User Info",
                    backgroundColor: Styles().colors!.background,
                    fontSize: 16.0,
                    textColor: Styles().colors!.fillColorPrimary,
                    borderColor: Styles().colors!.fillColorPrimary,
                    onTap: _onInboxUserInfoClicked
                  ),
                ),
                Padding( padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                  RoundedButton(
                    label: "User Profile Info",
                    backgroundColor: Styles().colors!.background,
                    fontSize: 16.0,
                    textColor: Styles().colors!.fillColorPrimary,
                    borderColor: Styles().colors!.fillColorPrimary,
                    onTap: _onUserProfileInfoClicked
                  )
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                  RoundedButton(
                    label: "User Card Info",
                    backgroundColor: Styles().colors!.background,
                    fontSize: 16.0,
                    textColor: Styles().colors!.fillColorPrimary,
                    borderColor: Styles().colors!.fillColorPrimary,
                    onTap: _onUserCardInfoClicked
                  )
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                  RoundedButton(
                    label: 'Canvas User Info',
                    backgroundColor: Styles().colors!.background,
                    fontSize: 16.0,
                    textColor: Styles().colors!.fillColorPrimary,
                    borderColor: Styles().colors!.fillColorPrimary,
                    onTap: _onTapCanvasUser
                  )
                ),

                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Container(height: 1, color: Styles().colors?.surfaceAccent ,),),

                Visibility(visible: Config().configEnvironment == rokwire.ConfigEnvironment.dev, child:
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                    RoundedButton(
                      label: "Campus Guide",
                      backgroundColor: Styles().colors!.background,
                      fontSize: 16.0,
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorPrimary,
                      onTap: _onTapGuide
                    )
                  )
                ),
                Visibility(visible: Config().configEnvironment == rokwire.ConfigEnvironment.dev, child:
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                    RoundedButton(
                      label: "Student Courses",
                      backgroundColor: Styles().colors!.background,
                      fontSize: 16.0,
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorPrimary,
                      onTap: _onTapStudentCourses
                    )
                  ),
                ),
                Visibility(visible: Config().configEnvironment == rokwire.ConfigEnvironment.dev, child:
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                    RoundedButton(
                      label: "Styles",
                      backgroundColor: Styles().colors!.background,
                      fontSize: 16.0,
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorPrimary,
                      onTap: _onTapStyles
                    )
                  ),
                ),
                Visibility(visible: Config().configEnvironment == rokwire.ConfigEnvironment.dev, child:
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                    RoundedButton(
                      label: 'Rewards',
                      backgroundColor: Styles().colors!.background,
                      fontSize: 16.0,
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorPrimary,
                      onTap: _onTapRewards
                    )
                  )
                ),

                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Container(height: 1, color: Styles().colors?.surfaceAccent ,),),

                Visibility(visible: Config().configEnvironment == rokwire.ConfigEnvironment.dev, child:
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                    RoundedButton(
                      label: 'Rate App',
                      backgroundColor: Styles().colors!.background,
                      fontSize: 16.0,
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorPrimary,
                      progress: _preparingRatingApp,
                      onTap: _onTapRateApp
                    )
                  )
                ),

                Visibility(visible: Config().configEnvironment == rokwire.ConfigEnvironment.dev, child:
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                    RoundedButton(
                      label: 'Review App',
                      backgroundColor: Styles().colors!.background,
                      fontSize: 16.0,
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorPrimary,
                      onTap: _onTapReviewApp
                    )
                  )
                ),

                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Container(height: 1, color: Styles().colors?.surfaceAccent ,),),

                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                    RoundedButton(
                      label: 'Mobile Access Keys',
                      backgroundColor: Styles().colors!.background,
                      fontSize: 16.0,
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorPrimary,
                      onTap: _onTapMobileAccessKeys
                    )
                  ),

                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Container(height: 1, color: Styles().colors?.surfaceAccent ,),),

                Visibility(visible: Config().configEnvironment == rokwire.ConfigEnvironment.dev, child:
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                    RoundedButton(
                      label: "Http Proxy",
                      backgroundColor: Styles().colors!.background,
                      fontSize: 16.0,
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorPrimary,
                      onTap: _onTapHttpProxy
                    )
                  ),
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child:
                  RoundedButton(
                    label: "Test Crash",
                    backgroundColor: Styles().colors!.background,
                    fontSize: 16.0,
                    textColor: Styles().colors!.fillColorPrimary,
                    borderColor: Styles().colors!.fillColorPrimary,
                    onTap: _onTapCrash
                  )
                ),
                
                Container(height: 16),
              ],),
            ),
          ),
        ),
      ],),
    );
  }

  Widget _buildSurveyCreation() {
    List<Widget> userSurveyEntries = [];
    for (Survey survey in _userSurveys ?? []) {
      userSurveyEntries.add(Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(children: [
          Expanded(flex: 2, child: Text(survey.title)),
          Expanded(child: RoundedButton(
            label: 'Edit',
            backgroundColor: Styles().colors!.background,
            textColor: Styles().colors!.fillColorPrimary,
            fontFamily: Styles().fontFamilies!.bold,
            fontSize: 16,
            padding: EdgeInsets.all(8),
            borderColor: Styles().colors!.fillColorPrimary,
            borderWidth: 2,
            onTap: () => _onTapCreateSurvey(survey: survey),
          )),
        ],),
      ));
    }
    return Column(children: [
      ...userSurveyEntries,
      Padding(padding: const EdgeInsets.only(top: 16), child: RoundedButton(
        label: 'Create New Survey',
        backgroundColor: Styles().colors!.background,
        textColor: Styles().colors!.fillColorPrimary,
        fontFamily: Styles().fontFamilies!.bold,
        fontSize: 16,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        borderColor: Styles().colors!.fillColorPrimary,
        borderWidth: 2,
        onTap: _onTapCreateSurvey,
      )),
    ]);
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

  void _loadUserSurveys() async {
    if (Auth2().isLoggedIn) {
      Surveys().loadCreatorSurveys().then((surveyList) {
        if (mounted) {
          setState(() {
            _userSurveys = surveyList;
          });
        }
      });
    }
  }

  String? _validateThresoldDistance(String? value) {
    return (int.tryParse(value!) == null) ? 'Please enter a number.' : null;
  }

  String? _validateGeoFenceRegionRadius(String? value) {
    return (int.tryParse(value!) == null) ? 'Please enter a number.' : null;
  }
  
  void _clearDateOffset() {
    setState(() {
      Storage().offsetDate = _offsetDate = null;
    });
  }

  void _clearLastAppReview() {
    setState(() {
      AppReview().appReviewRequestTime = null;
    });
  }

  void _changeDate() async {
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
      Set<GeoFenceBeacon>? regionBacons = GeoFence().currentBeaconsInRegion(regionId);
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
      Storage().debugMapShowLevels = (Storage().debugMapShowLevels != true);
    });
  }

  void _onUseCanvasLms() {
    setState(() {
      Storage().debugUseCanvasLms = (Storage().debugUseCanvasLms != true);
    });
  }

  void _onUseSampleAppointments() {
    setState(() {
      Storage().debugUseSampleAppointments = (Storage().debugUseSampleAppointments != true);
    });
  }

  void _onUseIdentityBb() {
    setState(() {
      Storage().debugUseIdentityBb = (Storage().debugUseIdentityBb != true);
    });
  }

  void _onAutomaticCredentials() {
    setState(() {
      Storage().debugAutomaticCredentials = (Storage().debugAutomaticCredentials != true);
    });
  }

  void _onUseDeviceLocalTimeZoneToggled() {
    setState(() {
      Storage().useDeviceLocalTimeZone = !Storage().useDeviceLocalTimeZone!;
    });
  }

  void _onTapClearAccountPrefs() {
    Auth2().prefs?.clear(notify: true);
    AppAlert.showDialogResult(context, 'Successfully cleared user account prefs.');
  }

  void _onTapClearVoting() {
    Storage().voterHiddenForPeriod = false;
    Auth2().prefs?.voter?.clear();
    AppAlert.showDialogResult(context, 'Successfully cleared user voting.');
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

  void _onCreateEventClicked() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CreateEventPanel()));
  }

  void _onTapCreateSurvey({Survey? survey}) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyCreationPanel(survey: survey, tabBar: uiuc.TabBar())));
  }

  void _onCreateInboxMessageClicked() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugCreateInboxMessagePanel()));
  }

  void _onInboxUserInfoClicked(){
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugInboxUserInfoPanel()));
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
  
  void _onTapCanvasUser() {
    Canvas().loadSelfUser().then((userJson) {
      if (userJson != null) {
        showDialog(context: context, builder: (_) => _buildTextContentInfoDialog(JsonUtils.encode(userJson, prettify: true)));
      } else {
        AppAlert.showDialogResult(context, 'Failed to retrieve canvas user.');
      }
    });
  }

  
  void _onTapGuide() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugGuidePanel()));
  }

  void _onTapStudentCourses() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugStudentCoursesPanel()));
  }

  void _onTapStyles() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugStylesPanel()));
  }

  void _onTapRewards() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugRewardsPanel()));
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
    Clipboard.setData(ClipboardData(text: textContent ?? '')).then((_){
      AppToast.show("Text data has been copied to the clipboard!");
    });
  }

  void _onConfigChanged(dynamic env) {
    if (env is rokwire.ConfigEnvironment) {
      _confirmConfigChange(env);
    }
  }

  void _confirmConfigChange(rokwire.ConfigEnvironment env) {
      AppAlert.showCustomDialog(context: context,
        contentWidget: Text('Switch to ${rokwire.configEnvToString(env)}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _changeConfig(env);
            },
            child: Text(Localization().getStringEx('dialog.ok.title', 'OK'))),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(Localization().getStringEx('dialog.cancel.title', 'Cancel')))
        ]);
  }

  void _changeConfig(rokwire.ConfigEnvironment env) {
    if (mounted) {
        setState(() {
          _selectedEnv = Config().configEnvironment = env;
        });
    }
  }

  void _onTapRateApp() async {
    if (!_preparingRatingApp) {
      setState(() {
        _preparingRatingApp = true;
      });
      Future.delayed(Duration(milliseconds: 500)).then((_) {
        final InAppReview inAppReview = InAppReview.instance;
        inAppReview.isAvailable().then((bool result) {
          if (mounted) {
            setState(() {
              _preparingRatingApp = false;
            });
            if (result) {
              inAppReview.requestReview();
            }
          }
        });
      });
    }
  }

  void _onTapReviewApp() {
    InAppReview.instance.openStoreListing(appStoreId: Config().appStoreId);
  }

  void _onTapMobileAccessKeys() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugMobileAccessHomePanel()));
  }

  void _onTapHttpProxy() {
    if(Config().configEnvironment == rokwire.ConfigEnvironment.dev) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHttpProxyPanel()));
    }
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

  // SettingsListenerMixin

  void onDateOffsetChanged() {
    setState(() {
      _offsetDate = Storage().offsetDate;
    });
  }
}
