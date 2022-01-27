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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as Http;
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/GeoFence.dart';
import 'package:illinois/model/Poll.dart';
import 'package:rokwire_plugin/service/app_navigation.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/config.dart' as rokwire;
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/GeoFence.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:package_info/package_info.dart';
import 'package:device_info/device_info.dart';
import 'package:uuid/uuid.dart';
import 'package:notification_permissions/notification_permissions.dart' as Notifications;

import 'package:illinois/main.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:illinois/ui/RootPanel.dart';


class Analytics with Service implements NotificationsListener {

  // Database Data

  static const String   _databaseName         = "analytics.db";
  static const int      _databaseVersion      = 1;
  static const String   _databaseTable        = "events";
  static const String   _databaseColumn       = "packet";
  static const String   _databaseRowID        = "rowid";
  static const int      _databaseMaxPackCount = 64;
  static const Duration _timerTick            = const Duration(milliseconds: 100);
  
  // Log Data

  // Standard (shared) Attributes
  static const String   LogStdTimestampName                = "timestamp";
  static const String   LogStdAppIdName                    = "app_id";
  static const String   LogStdAppVersionName               = "app_version";
  static const String   LogStdOSName                       = "os_name";
  static const String   LogStdOSVersionName                = "os_version";
  static const String   LogStdLocaleName                   = "locale";
  static const String   LogStdDeviceModelName              = "device_model";
  static const String   LogStdConnectionName               = "connection";
  static const String   LogStdLocationSvcName              = "location_services";
  static const String   LogStdNotifySvcName                = "notification_services";
  static const String   LogStdLocationName                 = "location";
  static const String   LogStdSessionUuidName              = "session_uuid";
  static const String   LogStdUserUuidName                 = "user_uuid";
  static const String   LogStdUserPrivacyLevelName         = "user_privacy_level";
  static const String   LogStdUserRolesName                = "user_roles";
  static const String   LogStdAccessibilityName            = "accessibility";
  static const String   LogStdAuthCardRoleName             = "icard_role";
  static const String   LogStdAuthCardStudentLevel         = "icard_student_level";
  
  static const String   LogEvent                           = "event";
  static const String   LogEventName                       = "name";
  static const String   LogEventPageName                   = "page";

  static const List<String> DefaultAttributes = [
    LogStdTimestampName,
    LogStdAppIdName,
    LogStdAppVersionName,
    LogStdOSName,
    LogStdOSVersionName,
    LogStdLocaleName,
    LogStdDeviceModelName,
    LogStdConnectionName,
    LogStdLocationSvcName,
    LogStdNotifySvcName,
    LogStdLocationName,
    LogStdSessionUuidName,
    LogStdUserUuidName,
    LogStdUserPrivacyLevelName,
    LogStdUserRolesName,
    LogStdAccessibilityName,
    LogStdAuthCardRoleName,
    LogStdAuthCardStudentLevel,
  ];

  // Livecycle Event
  // { "event" : { "name":"livecycle", "livecycle_event":"..." } }
  static const String   LogLivecycleEventName              = "livecycle";
  static const String   LogLivecycleName                   = "livecycle_event";
  static const String   LogLivecycleEventCreate            = "create";
  static const String   LogLivecycleEventDestroy           = "destroy";
  static const String   LogLivecycleEventBackground        = "background";
  static const String   LogLivecycleEventForeground        = "foreground";

  // Page Event
  // { "event" : { "name":"page", "page":"...", "page_name":"...", "previous_page_name":"" } }
  static const String   LogPageEventName                   = "page";
  static const String   LogPageName                        = "page_name";
  static const String   LogPagePreviousName                = "previous_page_name";

  // Select Event
  // "event" : { "name":"select", "page":"...", "target":"..." } }
  static const String   LogSelectEventName                 = "select";
  static const String   LogSelectTargetName                = "target";

  // Alert Event
  // {  "event" : { "name":"alert", "page":"...", "text":"...", "selection":"..." }}
  static const String   LogAlertEventName                  = "alert";
  static const String   LogAlertTextName                   = "text";
  static const String   LogAlertSelectionName              = "selection";

  // Http Response Event
  // "event" : { "name":"http_response", "http_request_url":"...", "http_request_method":"...", "http_response_code":... }
  static const String   LogHttpResponseEventName           = "http_response";
  static const String   LogHttpRequestUrlName              = "http_request_url";
  static const String   LogHttpRequestMethodName           = "http_request_method";
  static const String   LogHttpResponseCodeName            = "http_response_code";

  // Favorite Event
  // {  "event" : { "name":"favorite", "action":"on/off", "type":"...", "id":"...", "title":"..." }}
  static const String   LogFavoriteEventName                = "favorite";
  static const String   LogFavoriteActionName               = "action";
  static const String   LogFavoriteTypeName                 = "type";
  static const String   LogFavoriteIdName                   = "id";
  static const String   LogFavoriteTitleName                = "title";

  static const String   LogFavoriteOnActionName             = "on";
  static const String   LogFavoriteOffActionName            = "off";

  // Poll Event
  // {  "event" : { "name":"favorite", "action":"on/off", "type":"...", "id":"...", "title":"..." }}
  static const String   LogPollEventName                    = "poll";
  static const String   LogPollActionName                   = "action";
  static const String   LogPollIdName                       = "id";
  static const String   LogPollTitleName                    = "title";

  static const String   LogPollCreateActionName             = "create";
  static const String   LogPollOpenActionName               = "open";
  static const String   LogPollCloseActionName              = "close";
  static const String   LogPollVoteActionName               = "vote";

  // Map Route
  static const String   LogMapRouteEventName               = "map_route";
  static const String   LogMapRouteAction                  = "action";
  static const String   LogMapRouteStartActionName         = "start";
  static const String   LogMapRouteFinishActionName        = "finish";
  static const String   LogMapRouteOrigin                  = "origin";
  static const String   LogMapRouteDestination             = "destination";
  static const String   LogMapRouteLocation                = "location";

  // Map Display
  static const String   LogMapDisplayEventName             = "map_dispaly";
  static const String   LogMapDisplayAction                = "action";
  static const String   LogMapDisplayShowActionName        = "show";
  static const String   LogMapDisplayHideActionName        = "hide";

  // GeoFence Regions
  static const String   LogGeoFenceRegionEventName         = "geofence_region";
  static const String   LogGeoFenceRegionAction            = "action";
  static const String   LogGeoFenceRegionEnterActionName   = "enter";
  static const String   LogGeoFenceRegionExitActionName    = "exit";
  static const String   LogGeoFenceRegionRegion            = "region";
  static const String   LogGeoFenceRegionRegionId          = "id";
  static const String   LogGeoFenceRegionRegionName        = "name";
  
  // Illini Cash
  static const String   LogIllniCashEventName              = "illini_cash";
  static const String   LogIllniCashAction                 = "action";
  static const String   LogIllniCashPurchaseActionName     = "purchase";
  static const String   LogIllniCashPurchaseAmount         = "amount";

  // Auth
  static const String   LogAuthEventName                   = "auth";
  static const String   LogAuthAction                      = "action";
  static const String   LogAuthLoginNetIdActionName        = "login_netid";
  static const String   LogAuthLoginPhoneActionName        = "login_phone";
  static const String   LogAuthLoginEmailActionName        = "login_email";
  static const String   LogAuthLogoutActionName            = "logout";
  static const String   LogAuthResult                      = "result";

  // Group
  static const String   LogGroupEventName                  = "group";
  static const String   LogGroupAction                     = "action";
  static const String   LogGroupMembershipRequested        = "membership_requested";
  static const String   LogGroupMembershipRequestCanceled  = "membership_request_canceled";
  static const String   LogGroupMembershipQuit             = "membership_quit";
  static const String   LogGroupMembershipApproved         = "membership_approved";
  static const String   LogGroupMembershipRejected         = "membership_rejected";
  static const String   LogGroupMembershipSwitchToAdmin    = "membership_switch_admin";
  static const String   LogGroupMembershipSwitchToMember   = "membership_switch_member";
  static const String   LogGroupMembershipRemoved          = "membership_removed";

  // Event Attributes
  static const String   LogAttributeUrl                    = "url";
  static const String   LogAttributeEventId                = "event_id";
  static const String   LogAttributeEventName              = "event_name";
  static const String   LogAttributeEventCategory          = "event_category";
  static const String   LogAttributeRecurrenceId           = "recurrence_id";
  static const String   LogAttributeDiningId               = "dining_id";
  static const String   LogAttributeDiningName             = "dining_name";
  static const String   LogAttributePlaceId                = "place_id";
  static const String   LogAttributePlaceName              = "place_name";
  static const String   LogAttributeGameId                 = "game_id";
  static const String   LogAttributeGameName               = "game_name";
  static const String   LogAttributeLaundryId              = "laundry_id";
  static const String   LogAttributeLaundryName            = "laundry_name";
  static const String   LogAttributeGroupId                = "group_id";
  static const String   LogAttributeGroupName              = "group_name";
  static const String   LogAttributeGuide                  = "guide";
  static const String   LogAttributeGuideId                = "guide_id";
  static const String   LogAttributeGuideTitle             = "guide_title";
  static const String   LogAttributeGuideCategory          = "guide_category";
  static const String   LogAttributeGuideSection           = "guide_section";
  static const String   LogAttributeLocation               = "location";


  // Data

  Database?             _database;
  Timer?                _timer;
  bool                 _inTimer = false;
  
  String?               _currentPageName;
  Map<String, dynamic>? _currentPageAttributes;
  PackageInfo?          _packageInfo;
  AndroidDeviceInfo?    _androidDeviceInfo;
  IosDeviceInfo?        _iosDeviceInfo;
  String?               _appId;
  String?               _appVersion;
  String?               _osVersion;
  String?               _deviceModel;
  ConnectivityStatus?   _connectionStatus;
  String?               _connectionName;
  String?               _locationServices;
  String?               _notificationServices;
  String?               _sessionUuid;
  String?               _accessibilityState;
  List<dynamic>?        _userRoles;
  

  // Singletone Instance

  Analytics._internal();
  static final Analytics _instance = Analytics._internal();

  factory Analytics() {
    return _instance;
  }
  
  static Analytics get instance {
    return _instance;
  }

  // Initialization

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      AppLivecycle.notifyStateChanged,
      AppNavigation.notifyEvent,
      LocationServices.notifyStatusChanged,
      Auth2UserPrefs.notifyRolesChanged,
      Auth2UserPrefs.notifyFavoriteChanged,
      Auth2.notifyLoginSucceeded,
      Auth2.notifyLoginFailed,
      Auth2.notifyLogout,
      Auth2.notifyPrefsChanged,
      Auth2.notifyUserDeleted,
      Network.notifyHttpResponse,
      NativeCommunicator.notifyMapRouteStart,
      NativeCommunicator.notifyMapRouteFinish,
      NativeCommunicator.notifyGeoFenceRegionsEnter,
      NativeCommunicator.notifyGeoFenceRegionsExit,
    ]);

  }

  @override
  Future<void> initService() async {

    await _initDatabase();
    _initTimer();
    
    _updateConnectivity();
    _updateLocationServices();
    _updateNotificationServices();
    _updateUserRoles();
    _updateSessionUuid();

    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      _packageInfo = packageInfo;
      _appId = _packageInfo?.packageName;
      _appVersion = "${_packageInfo?.version}+${_packageInfo?.buildNumber}";
    });

    if (defaultTargetPlatform == TargetPlatform.android) {
      DeviceInfoPlugin().androidInfo.then((AndroidDeviceInfo androidDeviceInfo) {
        _androidDeviceInfo = androidDeviceInfo;
        _deviceModel = _androidDeviceInfo?.model;
        _osVersion = _androidDeviceInfo?.version.release;
      });
    }
    else if (defaultTargetPlatform == TargetPlatform.iOS) {
      DeviceInfoPlugin().iosInfo.then((IosDeviceInfo iosDeviceInfo) {
        _iosDeviceInfo = iosDeviceInfo;
        _deviceModel = _iosDeviceInfo?.model;
        _osVersion = _iosDeviceInfo?.systemVersion;
      });
    }
  
    if (_database != null) {
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'Analytics Initialization Failed',
        description: 'Failed to create analytics database.',
      );
    }
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);

    _closeDatabase();
    _closeTimer();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config(), Auth2(), LocationServices(), Connectivity() ]);
  }

  // Database

  Future<void> _initDatabase() async {
    if (_database == null) {
      String databasePath = await getDatabasesPath();
      String databaseFile = join(databasePath, _databaseName);
      _database = await openDatabase(databaseFile, version: _databaseVersion, onCreate: (db, version) {
        return db.execute("CREATE TABLE IF NOT EXISTS $_databaseTable($_databaseColumn TEXT NOT NULL)",);
      });
    }
  }

  void _closeDatabase() {
    if (_database != null) {
      _database!.close();
      _database = null;
    }
  }

  // Timer

  void _initTimer() {
      if (_timer == null) {
        //Log.d("Analytics: awake");
        _timer = Timer.periodic(_timerTick, _onTimer);
        _inTimer = false;
      }
  }

  void _closeTimer() {
    if (_timer != null) {
      //Log.d("Analytics: asleep");
      _timer!.cancel();
      _timer = null;
    }
    _inTimer = false;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Connectivity.notifyStatusChanged) {
      _applyConnectivityStatus(param);
    }
    else if (name == LocationServices.notifyStatusChanged) {
      _applyLocationServicesStatus(param);
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == AppNavigation.notifyEvent) {
      _onAppNavigationEvent(param);
    }
    else if (name == Auth2UserPrefs.notifyRolesChanged) {
      _updateUserRoles();
    }
    else if (name == Auth2UserPrefs.notifyFavoriteChanged) {
      logFavorite(param);
    }
    else if (name == Auth2.notifyLoginSucceeded) {
      logAuth(loginType: param, result: true);
    }
    else if (name == Auth2.notifyLoginFailed) {
      logAuth(loginType: param, result: false);
    }
    else if (name == Auth2.notifyLogout) {
      logAuth(action: Analytics.LogAuthLogoutActionName);
    }
    else if (name == Auth2.notifyPrefsChanged) {
      _updateUserRoles();
    }
    else if (name == Auth2.notifyUserDeleted) {
      _updateSessionUuid();
      _updateUserRoles();
    }
    else if (name == Network.notifyHttpResponse) {
      logHttpResponse(param);
    }
    else if (name == NativeCommunicator.notifyMapRouteStart) {
      logMapRoute(action: LogMapRouteStartActionName, params: param);
    }
    else if (name == NativeCommunicator.notifyMapRouteFinish) {
      logMapRoute(action: LogMapRouteFinishActionName, params: param);
    }
    else if (name == NativeCommunicator.notifyGeoFenceRegionsEnter) {
      logGeoFenceRegion(action: LogGeoFenceRegionEnterActionName, regionId: param);
    }
    else if (name == NativeCommunicator.notifyGeoFenceRegionsExit) {
      logGeoFenceRegion(action: LogGeoFenceRegionExitActionName, regionId: param);
    }
}

  // Connectivity

  void _updateConnectivity() {
    _applyConnectivityStatus(Connectivity().status);
}

  void _applyConnectivityStatus(ConnectivityStatus? status) {
    _connectionName = _connectivityStatusToString(_connectionStatus = status);
  }

  static String? _connectivityStatusToString(ConnectivityStatus? result) {
    return result?.toString().substring("ConnectivityStatus.".length);
  }
  
  // App Livecycle Service
  
  void _onAppLivecycleStateChanged(AppLifecycleState? state) {

    if (state == AppLifecycleState.paused) {
      logLivecycle(name: LogLivecycleEventBackground);
    }
    else if (state == AppLifecycleState.resumed) {
      _updateSessionUuid();
      _updateNotificationServices();
      logLivecycle(name: LogLivecycleEventForeground);
    }
    else if (state == AppLifecycleState.detached) {
      logLivecycle(name: Analytics.LogLivecycleEventDestroy);
    }

  }

  // App Naviagtion Service

  void _onAppNavigationEvent(Map<String, dynamic> param) {
    AppNavigationEvent? event = param[AppNavigation.notifyParamEvent];
    if (event == AppNavigationEvent.push) {
      _logRoute(param[AppNavigation.notifyParamRoute]);
    }
    else if (event == AppNavigationEvent.pop) {
      _logRoute(param[AppNavigation.notifyParamPreviousRoute]);
    }
    else if (event == AppNavigationEvent.remove) {
      _logRoute(param[AppNavigation.notifyParamPreviousRoute]);
    }
    else if (event == AppNavigationEvent.replace) {
      _logRoute(param[AppNavigation.notifyParamRoute]);
    }
  }

  void _logRoute(Route? route) {

    WidgetBuilder? builder;
    if (route is CupertinoPageRoute) {
      builder = route.builder;
    }
    else if (route is MaterialPageRoute) {
      builder = route.builder;
    }
    else {
      // _ModalBottomSheetRoute presented by showModalBottomSheet
      try { builder = (route as dynamic).builder; }
      catch(e) { print(e.toString()); }
    }

    if (builder != null) {
      Widget? panel = (App.instance?.homeContext != null) ? builder(App.instance?.homeContext) : null;
      if (panel != null) {
        
        if (panel is RootPanel) {
          Widget? tabPanel = App.instance?.panelState?.rootPanel?.panelState?.currentTabPanel;
          if (tabPanel != null) {
            panel = tabPanel;
          }
        }
        
        String? panelName;
        if (panel is AnalyticsPageName) {
          panelName = (panel as AnalyticsPageName).analyticsPageName;
        }
        if (panelName == null) {
          panelName = panel.runtimeType.toString();
        }

        Map<String, dynamic>? panelAttributes;
        if (panel is AnalyticsPageAttributes) {
          panelAttributes = (panel as AnalyticsPageAttributes).analyticsPageAttributes;
        }

        logPage(name: panelName, attributes: panelAttributes);
      }
    }
  }

  // Location Services

  void _updateLocationServices() {
    LocationServices().status.then((LocationServicesStatus? locationServicesStatus) {
      _applyLocationServicesStatus(locationServicesStatus);
    });
  }

  void _applyLocationServicesStatus(LocationServicesStatus? locationServicesStatus) {
    switch (locationServicesStatus) {
      case LocationServicesStatus.serviceDisabled:          _locationServices = "disabled"; break;
      case LocationServicesStatus.permissionNotDetermined:  _locationServices = "not_determined"; break;
      case LocationServicesStatus.permissionDenied:         _locationServices = "denied"; break;
      case LocationServicesStatus.permissionAllowed:        _locationServices = "allowed"; break;
      default: break;
    }
  }

  Map<String, dynamic>? get _location {
    Position? location = Auth2().privacyMatch(3) ? LocationServices().lastLocation : null;
    return (location != null) ? {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timestamp': location.timestamp?.millisecondsSinceEpoch,
    } : null;
  }
  

  // Notification Services

  void updateNotificationServices() {
    _updateNotificationServices();
  }

  void _updateNotificationServices() {
    Notifications.NotificationPermissions.getNotificationPermissionStatus().then((Notifications.PermissionStatus status) {
      _notificationServices = (status == Notifications.PermissionStatus.granted) ? 'enabled' : "not_enabled";
    });
  }

  // Sesssion Uuid

  void _updateSessionUuid() {
    _sessionUuid = Uuid().v1();
  }

  // Accessibility

  bool? get accessibilityState {
    return (_accessibilityState != null) ? (true.toString() == _accessibilityState) : null;
  }

  set accessibilityState(bool? value) {
    _accessibilityState = (value != null) ? value.toString() : null;
  }

  // User Roles Service

  void _updateUserRoles() {
    _userRoles = UserRole.setToJson(Auth2().prefs?.roles);
  }

  // Packets Processing
  
  Future<int> _savePacket(String? packet) async {
    if ((packet != null) && (_database != null)) {
      int result = await _database!.insert(_databaseTable, { _databaseColumn : packet });
      //Log.d("Analytics: scheduled packet #$result $packet");
      _initTimer();
      return result;
    }
    return -1;
  }

  void _onTimer(_) {
    
    if ((_database != null) && !_inTimer && (_connectionStatus != ConnectivityStatus.none)) {
      _inTimer = true;
      
      _database!.rawQuery("SELECT $_databaseRowID, $_databaseColumn FROM $_databaseTable ORDER BY $_databaseRowID LIMIT $_databaseMaxPackCount").then((List<Map<String, dynamic>> records) {
        if ((0 < records.length)) {

          String packets = '', rowIDs = '';
          for (Map<String, dynamic> record in records) {

            if (0 < packets.length)
              packets += ',';
            packets += '${record[_databaseColumn]}';

            if (0 < rowIDs.length)
              rowIDs += ',';
            rowIDs += '${record[_databaseRowID]}';
          }
          packets = '[' + packets + ']';
          rowIDs = '(' + rowIDs + ')';

          _sendPacket(packets).then((bool success) {
            if (success) {
              _database!.execute("DELETE FROM $_databaseTable WHERE $_databaseRowID in $rowIDs").then((_){
                //Log.d("Analytics: sent packets $rowIDs");
                _inTimer = false;
              });
            }
            else {
              //Log.d("Analytics: failed to send packets $rowIDs");
              _inTimer = false;
            }
          });
        }
        else {
          _closeTimer();
        }
      });
    }
  }

  Future<bool>_sendPacket(String? packet) async {
    if (packet != null) {
      try {
        //TMP: Temporarly use ApiKeyNetworkAuth auth until logging service gets updated to acknowledge the new Core BB token.
        //TBD: Remove this when logging service gets updated.
        final response = await Network().post(Config().loggingUrl, body: packet, headers: { "Accept": "application/json", "Content-type":"application/json" }, auth: rokwire.ApiKeyNetworkAuth() /* Auth2NetworkAuth() */, sendAnalytics: false);
        return (response != null) && ((response.statusCode == 200) || (response.statusCode == 201));
      }
      catch (e) {
        print(e.toString());
        return false;
      }
    }
    return false;
  }

  // Public Accessories

  void logEvent(Map<String, dynamic>? event, { List<String> defaultAttributes = DefaultAttributes}) {
    if ((event != null) && Auth2().privacyMatch(2)) {
      
      event[LogEventPageName] = _currentPageName;

      Map<String, dynamic> analyticsEvent = {
        LogEvent:            event,
      };

      for (String attributeName in defaultAttributes) {
        if (attributeName == LogStdTimestampName) {
          analyticsEvent[LogStdTimestampName] = DateTime.now().toUtc().toIso8601String();
        }
        else if (attributeName == LogStdAppIdName) {
          analyticsEvent[LogStdAppIdName] = _appId;
        }
        else if (attributeName == LogStdAppVersionName) {
          analyticsEvent[LogStdAppVersionName] = _appVersion;
        }
        else if (attributeName == LogStdOSName) {
          analyticsEvent[LogStdOSName] = Platform.operatingSystem;
        }
        else if (attributeName == LogStdOSVersionName) {
          analyticsEvent[LogStdOSVersionName] = _osVersion; // Platform.operatingSystemVersion;
        }
        else if (attributeName == LogStdLocaleName) {
          analyticsEvent[LogStdLocaleName] = Platform.localeName;
        }
        else if (attributeName == LogStdDeviceModelName) {
          analyticsEvent[LogStdDeviceModelName] = _deviceModel;
        }
        else if (attributeName == LogStdConnectionName) {
          analyticsEvent[LogStdConnectionName] = _connectionName;
        }
        else if (attributeName == LogStdLocationSvcName) {
          analyticsEvent[LogStdLocationSvcName] = _locationServices;
        }
        else if (attributeName == LogStdNotifySvcName) {
          analyticsEvent[LogStdNotifySvcName] = _notificationServices;
        }
        else if (attributeName == LogStdLocationName) {
          analyticsEvent[LogStdLocationName] = _location;
        }
        else if (attributeName == LogStdSessionUuidName) {
          analyticsEvent[LogStdSessionUuidName] = _sessionUuid;
        }
        else if (attributeName == LogStdUserUuidName) {
          analyticsEvent[LogStdUserUuidName] = Auth2().accountId;
        }
        else if (attributeName == LogStdUserPrivacyLevelName) {
          analyticsEvent[LogStdUserPrivacyLevelName] = Auth2().prefs?.privacyLevel;
        }
        else if (attributeName == LogStdUserRolesName) {
          analyticsEvent[LogStdUserRolesName] = _userRoles;
        }
        else if (attributeName == LogStdAccessibilityName) {
          analyticsEvent[LogStdAccessibilityName] = _accessibilityState;
        }
        else if(attributeName == LogStdAuthCardRoleName){
          analyticsEvent[LogStdAuthCardRoleName] = Auth2().authCard?.role;
        }
        else if(attributeName == LogStdAuthCardStudentLevel){
          analyticsEvent[LogStdAuthCardStudentLevel] = Auth2().authCard?.studentLevel;
        }
      }

      String packet = json.encode(analyticsEvent);
      print('Analytics: $packet');
      _savePacket(packet);
    }
  }

  void logLivecycle({String? name}) {
    logEvent({
      LogEventName          : LogLivecycleEventName,
      LogLivecycleName      : name,
    });
  }

  String? get currentPageName {
    return _currentPageName;
  }

  Map<String, dynamic>? get currentPageAttributes {
    return _currentPageAttributes;
  }

  void logPage({String? name,  Map<String, dynamic>? attributes}) {

    // Update Current page name
    String? previousPageName = _currentPageName;
    _currentPageName        = name;
    _currentPageAttributes  = attributes;

    // Build event data
    Map<String, dynamic> event = {
      LogEventName          : LogPageEventName,
      LogPageName           : name,
      LogPagePreviousName   : previousPageName
    };

    // Add optional attribute, if applied
    if (attributes != null) {
      event.addAll(attributes);
    }

    // Log the event
    logEvent(event);
  }

  void logSelect({String? target,  Map<String, dynamic>? attributes}) {

    // Build event data
    Map<String, dynamic> event = {
      LogEventName          : LogSelectEventName,
      LogSelectTargetName   : target,
    };

    // Add optional attribute, if applied
    if (attributes != null) {
      event.addAll(attributes);
    }

    // Log the event
    logEvent(event);
  }

  void logAlert({String? text, String? selection, Map<String, dynamic>? attributes}) {
    // Build event data
    Map<String, dynamic> event = {
      LogEventName          : LogAlertEventName,
      LogAlertTextName      : text,
      LogAlertSelectionName : selection,
    };

    // Add optional attribute, if applied
    if (attributes != null) {
      event.addAll(attributes);
    }

    // Log the event
    logEvent(event);
  }

  void logHttpResponse(dynamic param) {

    Map<String, dynamic>? httpResponseEvent;
    if (param is Http.BaseResponse) {
      httpResponseEvent = {
        LogEventName                    : LogHttpResponseEventName,
        LogHttpRequestUrlName           : param.request?.url.toString(),
        LogHttpRequestMethodName        : param.request?.method,
        LogHttpResponseCodeName         : param.statusCode,
      };
    }
    else if (param is Map) {
      httpResponseEvent = {
        LogEventName                    : LogHttpResponseEventName,
        LogHttpRequestUrlName           : param[Network.notifyHttpRequestUrl],
        LogHttpRequestMethodName        : param[Network.notifyHttpRequestMethod],
        LogHttpResponseCodeName         : param[Network.notifyHttpResponseCode],
      };
    }

    logEvent(httpResponseEvent);
  }

  void logFavorite(Favorite? favorite, [bool? on]) {
    if (on == null) {
      on = Auth2().isFavorite(favorite);
    }
    logEvent({
      LogEventName          : LogFavoriteEventName,
      LogFavoriteActionName : on ? LogFavoriteOnActionName : LogFavoriteOffActionName,
      LogFavoriteTypeName   : favorite?.favoriteKey,
      LogFavoriteIdName     : favorite?.favoriteId,
      LogFavoriteTitleName  : favorite?.favoriteTitle,
    });
  }

  void logPoll(Poll? poll, String action) {
    logEvent({
      LogEventName          : LogPollEventName,
      LogPollActionName     : action,
      LogPollIdName         : poll?.pollId,
      LogPollTitleName      : poll?.title,
    });
  }

  void logMapRoute({String? action, required Map<String, dynamic> params}) {
    
    logEvent({
      LogEventName             : LogMapRouteEventName,
      LogMapRouteAction        : action,
      LogMapRouteOrigin        : params['origin'],
      LogMapRouteDestination   : params['destination'],
      LogMapRouteLocation      : params['location'],
    });
  }

  void logMapShow() {
    logMapDisplay(action: LogMapDisplayShowActionName);
  }

  void logMapHide() {
    logMapDisplay(action: LogMapDisplayHideActionName);
  }

  void logMapDisplay({String? action}) {
    
    logEvent({
      LogEventName             : LogMapDisplayEventName,
      LogMapDisplayAction      : action
    });
  }

  void logGeoFenceRegion({String? action, String? regionId}) {

    Map<String, GeoFenceRegion?>? regions = GeoFence().regions;
    GeoFenceRegion? region = (regions != null) ? regions[regionId] : null;
    
    logEvent({
      LogEventName             : LogGeoFenceRegionEventName,
      LogMapRouteAction        : action,
      LogGeoFenceRegionRegion  : {
        LogGeoFenceRegionRegionId : regionId,
        LogGeoFenceRegionRegionName: region?.name,
      }
    });
  }

  void logIlliniCash({String? action, Map<String, dynamic>? attributes}) {
    Map<String, dynamic> event = {
      LogEventName           : LogIllniCashEventName,
      LogIllniCashAction     : action,
    };
    if (attributes != null) {
      event.addAll(attributes);
    }
    logEvent(event);
  }

  void logAuth({String? action, Auth2LoginType? loginType, bool? result, Map<String, dynamic>? attributes}) {
    
    if ((action == null) && (loginType != null)) {
      switch(loginType) {
        case Auth2LoginType.oidc:
        case Auth2LoginType.oidcIllinois: action = LogAuthLoginNetIdActionName; break;
        case Auth2LoginType.phone:
        case Auth2LoginType.phoneTwilio:  action = LogAuthLoginPhoneActionName; break;
        case Auth2LoginType.email:        action = LogAuthLoginEmailActionName; break;
        case Auth2LoginType.anonymous:    break;
      }
    }

    if (action != null) {
      Map<String, dynamic> event = {
        LogEventName           : LogAuthEventName,
        LogAuthAction          : action,
      };
      if (result != null) {
        event[LogAuthResult] = result;
      }
      if (attributes != null) {
        event.addAll(attributes);
      }
      logEvent(event);
    }
  }

  void logGroup({String? action, Map<String, dynamic>? attributes}) {
    Map<String, dynamic> event = {
      LogEventName           : LogGroupEventName,
      LogGroupAction         : action,
    };
    if (attributes != null) {
      event.addAll(attributes);
    }
    logEvent(event);
  }
}


abstract class AnalyticsPageName {
  String? get analyticsPageName;
}

abstract class AnalyticsPageAttributes {
  Map<String, dynamic>? get analyticsPageAttributes;
}
