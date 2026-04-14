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
import 'package:illinois/model/Assistant.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/service/AppReview.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/CustomCourses.dart';
import 'package:illinois/ui/debug/DebugGuideBrowsePanel.dart';
import 'package:illinois/ui/debug/DebugRewardsPanel.dart';
import 'package:illinois/ui/debug/DebugStudentCoursesPanel.dart';
import 'package:illinois/ui/debug/DebugWordlePanel.dart';
import 'package:illinois/ui/map2/Map2LocationPanel.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
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
import 'package:illinois/ui/debug/DebugGuideEditPanel.dart';
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

class _DebugHomePanelState extends State<DebugHomePanel> with NotificationsListener {

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
  Widget build(BuildContext context) => Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx("panel.debug.header.title", "Debug"),),
    backgroundColor: Styles().colors.surface,
    bottomNavigationBar: uiuc.TabBar(),
    body: SingleChildScrollView(child: _scaffoldContent),
  );

  Widget get _scaffoldContent =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _buildStaticInfo(),

      Container(height: 1, color: Styles().colors.surfaceAccent),

      ToggleRibbonButton(title: 'Disable live game check', toggled: Storage().debugDisableLiveGameCheck ?? false, onTap: _onDisableLiveGameCheckToggled),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      ToggleRibbonButton(title: 'Display all times in Central Time', toggled: !Storage().useDeviceLocalTimeZone!, onTap: _onUseDeviceLocalTimeZoneToggled),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      ToggleRibbonButton(title: 'Show map location source', toggled: Storage().debugMapLocationProvider ?? false, onTap: _onMapLocationProvider),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      ToggleRibbonButton(title: 'Show map levels', toggled: Storage().debugMapShowLevels!, onTap: _onMapShowLevels),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      ToggleRibbonButton(title: 'Canvas LMS', toggled: (Storage().debugUseCanvasLms == true), onTap: _onUseCanvasLms),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      ToggleRibbonButton(title: 'Sample Appointments', toggled: (Storage().debugUseSampleAppointments == true), onTap: _onUseSampleAppointments),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      ToggleRibbonButton(title: 'Mobile icard - Use Identity BB', toggled: (Storage().debugUseIdentityBb == true), onTap: _onUseIdentityBb),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      ToggleRibbonButton(title: 'Mobile icard - Automatic Credentials', toggled: (Storage().debugAutomaticCredentials == true), onTap: _onAutomaticCredentials),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      ToggleRibbonButton(title: 'Messages/Conversations Enabled', toggled: (Storage().debugMessagesDisabled == false), onTap: _onMessagesEnabled),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      ToggleRibbonButton(title: 'Use Test Wallet Service', toggled: (Storage().debugUseIlliniCashTestUrl == true), enabled: _canUseTestWalletService, onTap: _canUseTestWalletService ? _onUseTestWalletService : null,
        textStyle: Styles().textStyles.getTextStyle(_canUseTestWalletService ? 'widget.button.title.medium.fat' : 'widget.button.title.medium.fat.variant3'),
      ),

      Container(height: 1, color: Styles().colors.surfaceAccent),

      Container(padding: EdgeInsets.symmetric(horizontal: 15, vertical: 16), child:
        TextFormField(
          controller: _mapThresholdDistanceController,
          keyboardType: TextInputType.number,
          validator: _validateThresoldDistance,
          decoration: InputDecoration(
          border: OutlineInputBorder(), hintText: "Enter map threshold distance in meters", labelText: 'Threshold Distance (meters)')
        ),
      ),

      Container(height: 1, color: Styles().colors.surfaceAccent),

      Container(padding: EdgeInsets.symmetric(horizontal: 15, vertical: 16), child:
        TextFormField(
          controller: _geoFenceRegionRadiusController,
          keyboardType: TextInputType.number,
          validator: _validateGeoFenceRegionRadius,
          decoration: InputDecoration(
          border: OutlineInputBorder(), hintText: "Enter geo fence region radius in meters", labelText: 'Geo Fence Region Radius (meters)')
        ),
      ),

      Container(height: 1, color: Styles().colors.surfaceAccent),
      _buildEnvironmentUi(),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),

      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
        _buildSurveyCreation()
      ),

      Container(height: 1, color: Styles().colors.surfaceAccent ,),

      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
        _buildSportOffset()
      ),

      Container(height: 1, color: Styles().colors.surfaceAccent ,),

      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
        _buildAppReview()
      ),

      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: "Clear Account Prefs", onTap: _onTapClearAccountPrefs),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: "Clear Voting", onTap: _onTapClearVoting),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: _refreshTokenTitle, onTap: _onTapRefreshToken),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: "Create Message", onTap: _onCreateInboxMessageClicked),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: "Inbox User Info", onTap: _onInboxUserInfoClicked),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: "User Profile Info", onTap: _onUserProfileInfoClicked),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: "User Card Info", onTap: _onUserCardInfoClicked),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: 'Canvas User Info', onTap: _onTapCanvasUser),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: "Edit Guide", onTap: _onTapGuideEdit),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: "Browse Guide", onTap: _onTapGuideBrowse),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: "Student Courses", onTap: _onTapStudentCourses),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: "Styles", onTap: _onTapStyles),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: 'Rewards', onTap: _onTapRewards),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: 'Rate App', onTap: _onTapRateApp),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: 'Review App', onTap: _onTapReviewApp),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: "Http Proxy", onTap: _onTapHttpProxy),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: "Test Crash", onTap: _onTapCrash),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: "Clear Essential Skills Coach Data", onTap: _onTapClearEssentialSkillsCoachData),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: 'Set Assistant Location', onTap: _onTapSetAssistantLocation),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),
      RibbonButton(title: 'ILLordle', onTap: _onTapWordle),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),

      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
        _buildFontAwesomeInfo(),
      ),
      Container(height: 1, color: Styles().colors.surfaceAccent ,),

      Container(height: 32),
    ],);

  Widget _buildStaticInfo() =>
    Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), constraints: BoxConstraints(minWidth: double.infinity), color: Styles().colors.background, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.zero, child:
          Text('Uuid: ${Auth2().accountId}'),
        ),
        Padding(padding: EdgeInsets.only(top: 8), child:
          Text('PID: ${Auth2().profile?.id}'),
        ),
        Padding(padding: EdgeInsets.only(top: 8), child:
          Text('Firebase: ${FirebaseCore().app?.options.projectId}'),
        ),
        Padding(padding: EdgeInsets.only(top: 8), child:
          Text('GeoFence: $_geoFenceStatus'),
        ),
        Padding(padding: EdgeInsets.only(top: 8), child:
          Text('Beacon: $_beaconsStatus'),
        ),
      ])
    );

  Widget _buildEnvironmentUi() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
          Text('Config Environment: ', style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold, fontSize: 20 )),
        ),
        Container(height: 1, color: Styles().colors.surfaceAccent ,),
        RadioGroup<rokwire.ConfigEnvironment>(
          groupValue: _selectedEnv,
          onChanged: _onConfigChanged,
          child: ListView.separated(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            separatorBuilder: (context, index) => Divider(color: Styles().colors.surfaceAccent),
            itemCount: rokwire.ConfigEnvironment.values.length,
            itemBuilder: (context, index) {
              rokwire.ConfigEnvironment environment = rokwire.ConfigEnvironment.values[index];
              RadioListTile widget = RadioListTile<rokwire.ConfigEnvironment>(
                title: Text(rokwire.configEnvToString(environment) ?? '',
                style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold, fontSize: 16 )),
                value: environment,
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              );
              return widget;
            },
          ),
        ),
        Container(height: 1, color: Styles().colors.surfaceAccent ,),
      ],);

  Widget _buildSurveyCreation() {
    List<Widget> userSurveyEntries = [];
    for (Survey survey in _userSurveys ?? []) {
      userSurveyEntries.add(Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(children: [
          Expanded(flex: 2, child: Text(survey.title, style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold, fontSize: 16 ),)),
          Expanded(child: RoundedButton(label: 'Edit', fontSize: 16, padding: _smallButtonPadding, onTap: () => _onTapCreateSurvey(survey: survey),)),
        ],),
      ));
    }
    return Column(children: [
      ...userSurveyEntries,
      Padding(padding: const EdgeInsets.only(top: 16), child:
        RoundedButton(label: 'Create New Survey', fontSize: 16, padding: _compactButtonPadding, onTap: _onTapCreateSurvey,)
      ),
    ]);
  }

  EdgeInsetsGeometry get _smallButtonPadding => EdgeInsets.symmetric(horizontal: 16, vertical: 4);
  EdgeInsetsGeometry get _compactButtonPadding => EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  Widget _buildSportOffset() =>
    Row(children: <Widget>[
      Expanded(child:
        Text('Sport Offset: $_sportOffsetText', style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold, fontSize: 16 )),
      ),
      RoundedButton(label: "Edit", fontSize: 16, padding: _smallButtonPadding, contentWeight: 0.0, onTap: _changeDate,),
      Container(width: 5,),
      RoundedButton(label: "Clear", fontSize: 16, padding: _smallButtonPadding, contentWeight: 0.0, onTap: _clearDateOffset,),
    ],);

  String get _sportOffsetText => (_offsetDate != null) ? AppDateTime().formatDateTime(_offsetDate, format: 'MM/dd/yyyy HH:mm a')! : "None";

  Widget _buildAppReview() =>
      Row(children: [
        Expanded(child:
          Text("Last App Review: $_lastAppReviewTimeText", style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold, fontSize: 16 )),
        ),
        RoundedButton(label: "Clear", fontSize: 16, padding: _smallButtonPadding, contentWeight: 0.0, onTap: _clearLastAppReview,),
      ],);

  String get _lastAppReviewTimeText => (AppReview().appReviewRequestTime != null) ? DateFormat('MM/dd/yyyy').format(DateTime.fromMillisecondsSinceEpoch(AppReview().appReviewRequestTime!)) : 'NA';

  Widget _buildFontAwesomeInfo() =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(bottom: 8), child:
        Text('Font Awesome Pro Icons', style: Styles().textStyles.getTextStyle('widget.message.medium'))
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
        Center(child: Styles().images.getImage('thinVacuum')),
        Center(child: Styles().images.getImage('lightVacuum')),
        Center(child: Styles().images.getImage('solidVacuum'))
      ]),
    ]);

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

  void _onMessagesEnabled() {
    setState(() {
      Storage().debugMessagesDisabled = (Storage().debugMessagesDisabled != true);
    });
  }

  bool get _canUseTestWalletService => StringUtils.isNotEmpty(Config().illiniCashTestUrl);

  void _onUseTestWalletService() {
    setState(() {
      Storage().debugUseIlliniCashTestUrl = (Storage().debugUseIlliniCashTestUrl != true);
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
    String? cardInfo = JsonUtils.encode(Auth2().iCard?.toShortJson(), prettify: true);
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

  
  void _onTapGuideEdit() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugGuideEditPanel()));
  }

  void _onTapGuideBrowse() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugGuideBrowsePanel()));
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
      Dialog(backgroundColor: Styles().colors.background, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(color: Styles().colors.fillColorPrimary, child:
            Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
              Container(width: 20,),
              Expanded(child:
                RoundedButton(
                  label: "Copy to clipboard",
                  textColor: Styles().colors.white,
                  borderColor: Styles().colors.fillColorSecondary,
                  backgroundColor: Styles().colors.fillColorPrimary,
                  onTap: (){ _copyToClipboard(textContent); },
                ),
              ),
              Container(width: 20,),
              GestureDetector( onTap:  () => Navigator.of(context).pop(), child:
                Padding(padding: EdgeInsets.only(right: 10, top: 10), child:
                  Text('\u00D7', style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies.medium, fontSize: 50 ),),
                ),
              ),
            ],),
          ),
          Expanded(child:
            SingleChildScrollView(child:
              Padding(padding: EdgeInsets.all(8), child: Text(StringUtils.ensureNotEmpty(textContent), style: TextStyle(color: Colors.black, fontFamily: Styles().fontFamilies.bold, fontSize: 14)))
            )
          ),
        ])
      )
    );
  }

  void _copyToClipboard(String? textContent){
    Clipboard.setData(ClipboardData(text: textContent ?? '')).then((_){
      AppToast.showMessage("Text data has been copied to the clipboard!");
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

  void _onTapHttpProxy() {
    if(Config().configEnvironment == rokwire.ConfigEnvironment.dev) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHttpProxyPanel()));
    }
  }

  void _onTapCrash(){
    FirebaseCrashlytics.instance.crash();
  }

  void _onTapClearEssentialSkillsCoachData() {
    if (StringUtils.isNotEmpty(Config().essentialSkillsCoachKey)) {
      CustomCourses().deleteUserCourse(Config().essentialSkillsCoachKey!);
    }
  }

  void _onTapSetAssistantLocation() {
    ExploreLocation? location = Storage().debugAssistantLocation?.toExploreLocation();
    Map2LocationPanel.push(context,
      selectedLocation: (location != null) ? ExplorePOI(location: location) : null,
    ).then((Explore? explore) {
      ExploreLocation? newLocation = explore?.exploreLocation;
      Storage().debugAssistantLocation = AssistantLocation.fromExploreLocation(newLocation);
    });
  }

  void _onTapWordle() =>
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugWordlePanel()));

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
