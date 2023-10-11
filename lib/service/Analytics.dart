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
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/mainImpl.dart';
import 'package:illinois/model/wellness/ToDo.dart' as wellness;
import 'package:illinois/model/wellness/WellnessRing.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/geo_fence.dart';
import 'package:rokwire_plugin/service/app_navigation.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/analytics.dart' as rokwire;

import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/ext/Favorite.dart';
import 'package:illinois/service/Auth2.dart';

import 'package:illinois/ui/RootPanel.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'package:uuid/uuid.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as firebase;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';

class Analytics extends rokwire.Analytics implements NotificationsListener {

  static const String notifyEvent = "edu.illinois.rokwire.analytics.event";

  // Log Data

  // Standard (shared) Attributes
  static const String   LogStdTimestampName                = "timestamp";
  static const String   LogStdAppIdName                    = "app_id";
  static const String   LogStdAppVersionName               = "app_version";
  static const String   LogStdOSName                       = "os_name";
  static const String   LogStdOSVersionName                = "os_version";
  static const String   LogStdLocaleName                   = "locale";
  static const String   LogStdSystemLocaleName             = "system_locale";
  static const String   LogStdSelectedLocaleName           = "selected_locale";
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
  static const String   LogStdStudentTermCode              = "student_term_code";
  static const String   LogStdStudentType                  = "student_type";
  static const String   LogStdStudentTypeCode              = "student_type_code";
  static const String   LogStdStudentAdmittedTerm          = "student_admitted_term";
  static const String   LogStdStudentCollegeName           = "student_college_name";
  static const String   LogStdStudentDepartmentName        = "student_department_name";
  static const String   LogStdStudentLevelCode             = "student_level_code";
  static const String   LogStdStudentLevelDescription      = "student_level_description";
  static const String   LogStdStudentClassification        = "student_classification";
  static const String   LogStdStudentFirstYear             = "student_first_year";
  
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
    LogStdSystemLocaleName,
    LogStdSelectedLocaleName,
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
    LogStdStudentTermCode,
    LogStdStudentType,
    LogStdStudentTypeCode,
    LogStdStudentAdmittedTerm,
    LogStdStudentCollegeName,
    LogStdStudentDepartmentName,
    LogStdStudentLevelCode,
    LogStdStudentLevelDescription,
    LogStdStudentClassification,
    LogStdStudentFirstYear,
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
  static const String   LogSelectSourceName                = "source";

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
  static const String   LogFavoriteTargetName               = "target";
  static const String   LogFavoriteTypeName                 = "type";
  static const String   LogFavoriteIdName                   = "id";
  static const String   LogFavoriteTitleName                = "title";
  static const String   LogFavoriteUsedName                 = "used";
  static const String   LogFavoriteUnusedName               = "unused";

  static const String   LogFavoriteOnActionName             = "on";
  static const String   LogFavoriteOffActionName            = "off";
  static const String   LogFavoriteReorderActionName        = "reorder";

  // Widget Favorite Event
  // {  "event" : { "name":"favorite", "action":"on/off", "type":"...", "id":"...", "title":"..." }}
  static const String   LogWidgetFavoriteEventName          = "widget_favorite";

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

  static const String   LogMapSelectEventName             = "map_select";
  static const String   LogMapSelectTarget                = "target";

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
  static const String   LogAuthLoginUsernameActionName     = "username";
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

  // Wellness
  static const String   LogWellnessEventName               = "wellness";
  static const String   LogWellnessCategoryName            = "category";
  static const String   LogWellnessCategoryToDo            = "todo";
  static const String   LogWellnessCategoryRings           = "rings";
  static const String   LogWellnessActionName              = "action";
  static const String   LogWellnessActionComplete          = "complete";
  static const String   LogWellnessActionUncomplete        = "uncomplete";
  static const String   LogWellnessActionCreate            = "create";
  static const String   LogWellnessActionUpdate            = "update";
  static const String   LogWellnessActionClear             = "clear";
  static const String   LogWellnessTargetName              = "target";
  static const String   LogWellnessSourceName              = "source";
  static const String   LogWellnessRingGoalName            = "goal";
  static const String   LogWellnessRingUnitName            = "unit";
  static const String   LogWellnessToDoCategoryName        = "target_category";
  static const String   LogWellnessToDoDueDateTime         = "date";
  static const String   LogWellnessToDoReminderType        = "reminder";
  static const String   LogWellnessToDoWorkdays            = "workdays";

  // Video Attributes
  static const String   LogVideoEventName                  = "video";
  static const String   LogAttributeVideoId                = "video_id";
  static const String   LogAttributeVideoTitle             = "video_title";
  static const String   LogAttributeVideoDuration          = "video_duration";
  static const String   LogAttributeVideoPosition          = "video_position";
  static const String   LogAttributeVideoEvent             = "video_event";
  static const String   LogAttributeVideoEventStarted      = "started";
  static const String   LogAttributeVideoEventPaused       = "paused";
  static const String   LogAttributeVideoEventStopped      = "stopped";

  // Research Questionnaire Event
  // "event" : { "name":"research_questionnaire", "page":"...", "answers":["question": yes/no, ] } }
  static const String   LogResearchQuestionnaireEventName  = "research_questionnaire";
  static const String   LogResearchQuestionnaireAnswersName= "answers";

  // Event Attributes
  static const String   LogAttributeUrl                    = "url";
  static const String   LogAttributeSource                 = "source";
  static const String   LogAttributeEventId                = "event_id";
  static const String   LogAttributeEventName              = "event_name";
  static const String   LogAttributeEventCategory          = "event_category";
  static const String   LogAttributeEventAttributes        = "event_attributes";
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

  static const String   LogAnonymousUin                    = 'UINxxxxxx';
  static const String   LogAnonymousFirstName              = 'FirstNameXXXXXX';
  static const String   LogAnonymousLastName               = 'LastNameXXXXXX';

  // Data

  String?               _currentPageName;
  Map<String, dynamic>? _currentPageAttributes;
  String?               _connectionName;
  String?               _locationServices;
  String?               _notificationServices;
  String?               _sessionUuid;
  List<dynamic>?        _userRoles;
  

  // Singletone Factory

  @protected
  Analytics.internal() : super.internal();

  factory Analytics() => ((rokwire.Analytics.instance is Analytics) ? (rokwire.Analytics.instance as Analytics) : (rokwire.Analytics.instance = Analytics.internal()));

  // Service

  @override
  void createService() {
    super.createService();
    NotificationService().subscribe(this, [
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
      
      GeoFence.notifyRegionEnter,
      GeoFence.notifyRegionExit,
      
      Polls.notifyLifecycleCreate,
      Polls.notifyLifecycleOpen,
      Polls.notifyLifecycleClose,
      Polls.notifyLifecycleVote,

      Groups.notifyGroupMembershipRequested,
      Groups.notifyGroupMembershipCanceled,
      Groups.notifyGroupMembershipQuit,
      Groups.notifyGroupMembershipApproved,
      Groups.notifyGroupMembershipRejected,
      Groups.notifyGroupMembershipRemoved,
      Groups.notifyGroupMembershipSwitchToAdmin,
      Groups.notifyGroupMembershipSwitchToMember,
    ]);

  }

  @override
  Future<void> initService() async {

    await super.initService();

    _updateLocationServices();
    _updateNotificationServices();
    _updateUserRoles();
    _updateSessionUuid();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Set<Service> get serviceDependsOn {
    Set<Service> services = super.serviceDependsOn;
    services.addAll([Auth2(), LocationServices()]);
    return services;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    super.onNotification(name, param);
    
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == AppNavigation.notifyEvent) {
      _onAppNavigationEvent(param);
    }
    else if (name == LocationServices.notifyStatusChanged) {
      _applyLocationServicesStatus(param);
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
    
    else if (name == GeoFence.notifyRegionEnter) {
      logGeoFenceRegion(action: LogGeoFenceRegionEnterActionName, regionId: param);
    }
    else if (name == GeoFence.notifyRegionExit) {
      logGeoFenceRegion(action: LogGeoFenceRegionExitActionName, regionId: param);
    }
    
    else if (name == Polls.notifyLifecycleCreate) {
      logPoll(param, LogPollCreateActionName);
    }
    else if (name == Polls.notifyLifecycleOpen) {
      logPoll(param, LogPollOpenActionName);
    }
    else if (name == Polls.notifyLifecycleClose) {
      logPoll(param, LogPollCloseActionName);
    }
    else if (name == Polls.notifyLifecycleVote) {
      logPoll(param, LogPollVoteActionName);
    }

    else if (name == Groups.notifyGroupMembershipRequested) {
      logGroup(action: LogGroupMembershipRequested, attributes: (param as Group).analyticsAttributes);
    }
    else if (name == Groups.notifyGroupMembershipCanceled) {
      logGroup(action: LogGroupMembershipRequestCanceled, attributes: (param as Group).analyticsAttributes);
    }
    else if (name == Groups.notifyGroupMembershipQuit) {
      logGroup(action: LogGroupMembershipQuit, attributes: (param as Group).analyticsAttributes);
    }
    else if (name == Groups.notifyGroupMembershipApproved) {
      logGroup(action: LogGroupMembershipApproved, attributes: (param as Group).analyticsAttributes);
    }
    else if (name == Groups.notifyGroupMembershipRejected) {
      logGroup(action: LogGroupMembershipRejected, attributes: (param as Group).analyticsAttributes);
    }
    else if (name == Groups.notifyGroupMembershipRemoved) {
      logGroup(action: LogGroupMembershipRemoved, attributes: (param as Group).analyticsAttributes);
    }
    else if (name == Groups.notifyGroupMembershipSwitchToAdmin) {
      logGroup(action: LogGroupMembershipSwitchToAdmin, attributes: (param as Group).analyticsAttributes);
    }
    else if (name == Groups.notifyGroupMembershipSwitchToMember) {
      logGroup(action: LogGroupMembershipSwitchToMember, attributes: (param as Group).analyticsAttributes);
    }
  }

  // Connectivity

  @override
  void applyConnectivityStatus(ConnectivityStatus? status) {
    super.applyConnectivityStatus(status);
    _connectionName = _connectivityStatusToString(super.connectionStatus);
  }

  static String? _connectivityStatusToString(ConnectivityStatus? result) {
    return result?.toString().substring("ConnectivityStatus.".length);
  }
  
  // App Livecycle Service
  
  void _onAppLivecycleStateChanged(AppLifecycleState? state) {

    if (super.isInitialized) {
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

    Widget? panel;
    try {
      if (route is CupertinoPageRoute) {
        panel = (App.instance?.currentContext != null) ? route.builder(App.instance!.currentContext!) : null;
      }
      else if (route is MaterialPageRoute) {
        panel = (App.instance?.currentContext != null) ? route.builder(App.instance!.currentContext!) : null;
      }
      else if (route is PageRouteBuilder) {
        AnimationController? animationController = (App.instance?.state != null) ? AnimationController(duration: const Duration(milliseconds: 500), vsync: App.instance!.state!) : null;
        Animation<double>? animation = (animationController != null) ? Tween<double>(begin: 0, end: 500).animate(animationController) : null;
        panel = ((App.instance?.currentContext != null) && (animation != null)) ? route.pageBuilder(App.instance!.currentContext!, animation, animation) : null;
      }
      else {
        // _ModalBottomSheetRoute presented by showModalBottomSheet
        WidgetBuilder? builder = (route as dynamic).builder;
        panel = ((builder != null) && (App.instance?.currentContext != null)) ? builder(App.instance!.currentContext!) : null;
      }
    }
    catch(e) { print(e.toString()); }

    if (panel != null) {
      
      if (panel is RootPanel) {
        Widget? tabPanel = RootPanel.stateKey.currentState?.currentTabPanel;
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
    Position? location = FlexUI().isLocationServicesAvailable ? LocationServices().lastLocation : null;
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
    firebase.FirebaseMessaging.instance.getNotificationSettings().then((settings) {
      firebase.AuthorizationStatus status = settings.authorizationStatus;
      _notificationServices = (status == firebase.AuthorizationStatus.authorized) ? 'enabled' : "not_enabled";
    });
  }

  // Sesssion Uuid

  void _updateSessionUuid() {
    _sessionUuid = Uuid().v1();
  }

  // Accessibility

  bool? get _accessibilityState {
    BuildContext? context = App.instance?.currentContext;
    return (context != null) ? MediaQuery.of(context).accessibleNavigation : null;
  }

  // User Roles Service

  void _updateUserRoles() {
    _userRoles = UserRole.setToJson(Auth2().prefs?.roles);
  }

  // Public Accessories

  @override
  void logEvent(Map<String, dynamic> event, { List<String> defaultAttributes = DefaultAttributes, int? timestamp }) {
    NotificationService().notify(notifyEvent, event);

    if (FlexUI().isAnalyticsAvailable) {

      event[LogEventPageName] = _currentPageName;

      Map<String, dynamic> analyticsEvent = {
        LogEvent:            event,
      };

      DateTime nowUtc = DateTime.now().toUtc();

      for (String attributeName in defaultAttributes) {
        if (attributeName == LogStdTimestampName) {
          analyticsEvent[LogStdTimestampName] = nowUtc.toIso8601String();
        }
        else if (attributeName == LogStdAppIdName) {
          analyticsEvent[LogStdAppIdName] = super.appId;
        }
        else if (attributeName == LogStdAppVersionName) {
          analyticsEvent[LogStdAppVersionName] = super.appVersion;
        }
        else if (attributeName == LogStdOSName) {
          analyticsEvent[LogStdOSName] = Platform.operatingSystem;
        }
        else if (attributeName == LogStdOSVersionName) {
          analyticsEvent[LogStdOSVersionName] = super.osVersion; // Platform.operatingSystemVersion;
        }
        else if (attributeName == LogStdLocaleName) {
          analyticsEvent[LogStdLocaleName] = Platform.localeName;
        }
        else if (attributeName == LogStdSystemLocaleName) {
          analyticsEvent[LogStdSystemLocaleName] = (Localization().selectedLocale == null);
        }
        else if (attributeName == LogStdSelectedLocaleName) {
          analyticsEvent[LogStdSelectedLocaleName] = Localization().selectedLocale?.languageCode;
        }
        else if (attributeName == LogStdDeviceModelName) {
          analyticsEvent[LogStdDeviceModelName] = super.deviceModel;
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
        else if (attributeName == LogStdAuthCardRoleName) {
          analyticsEvent[LogStdAuthCardRoleName] = Auth2().authCard?.role;
        }
        else if (attributeName == LogStdAuthCardStudentLevel) {
          analyticsEvent[LogStdAuthCardStudentLevel] = Auth2().authCard?.studentLevel;
        }
        else if (attributeName == LogStdStudentTermCode) {
          analyticsEvent[LogStdStudentTermCode] = IlliniCash().studentClassification?.termCode;
        }
        else if (attributeName == LogStdStudentType) {
          analyticsEvent[LogStdStudentType] = IlliniCash().studentClassification?.studentType;
        }
        else if (attributeName == LogStdStudentTypeCode) {
          analyticsEvent[LogStdStudentTypeCode] = IlliniCash().studentClassification?.studentTypeCode;
        }
        else if (attributeName == LogStdStudentAdmittedTerm) {
          analyticsEvent[LogStdStudentAdmittedTerm] = IlliniCash().studentClassification?.admittedTerm;
        }
        else if (attributeName == LogStdStudentCollegeName) {
          analyticsEvent[LogStdStudentCollegeName] = IlliniCash().studentClassification?.collegeName;
        }
        else if (attributeName == LogStdStudentDepartmentName) {
          analyticsEvent[LogStdStudentDepartmentName] = IlliniCash().studentClassification?.departmentName;
        }
        else if (attributeName == LogStdStudentLevelCode) {
          analyticsEvent[LogStdStudentLevelCode] = IlliniCash().studentClassification?.studentLevelCode;
        }
        else if (attributeName == LogStdStudentLevelDescription) {
          analyticsEvent[LogStdStudentLevelDescription] = IlliniCash().studentClassification?.studentLevelDescription;
        }
        else if (attributeName == LogStdStudentClassification) {
          analyticsEvent[LogStdStudentClassification] = IlliniCash().studentClassification?.classification;
        }
        else if (attributeName == LogStdStudentFirstYear) {
          analyticsEvent[LogStdStudentFirstYear] = IlliniCash().studentClassification?.firstYear;
        }
      }
      
      super.logEvent(analyticsEvent, timestamp: timestamp ?? nowUtc.millisecondsSinceEpoch);
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

  void logSelect({String? target, String? source,  Map<String, dynamic>? attributes}) {

    // Build event data
    Map<String, dynamic> event = {
      LogEventName          : LogSelectEventName,
      LogSelectTargetName   : target,
      LogSelectSourceName   : source,
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
    if (param is BaseResponse) {
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

    if (httpResponseEvent != null) {
      logEvent(httpResponseEvent);
    }
  }

  void logFavorite(Favorite? favorite, {bool? on, String? title}) {
    logEvent({
      LogEventName          : LogFavoriteEventName,
      LogFavoriteActionName : (on ?? Auth2().isFavorite(favorite)) ? LogFavoriteOnActionName : LogFavoriteOffActionName,
      LogFavoriteTypeName   : favorite?.favoriteKey,
      LogFavoriteIdName     : favorite?.favoriteId,
      LogFavoriteTitleName  : title ?? favorite?.favoriteTitle,
    });
  }

  void logWidgetFavorite(dynamic favorite, bool? selected, { List<Favorite>? used, List<Favorite>? unused }) {
    dynamic target;
    if (favorite is Favorite) {
      target = favorite.toString();
    }
    else if (favorite is List) {
      target = JsonUtils.stringListValue(favorite);
    }

    String? action;
    if (selected != null) {
      action = selected ? LogFavoriteOnActionName : LogFavoriteOffActionName;
    }
    else {
      action = LogFavoriteReorderActionName;
    }

    logEvent({
      LogEventName          : LogWidgetFavoriteEventName,
      LogFavoriteTargetName : target,
      LogFavoriteActionName : action,
      LogFavoriteUsedName   : JsonUtils.stringListValue(used),
      LogFavoriteUnusedName : JsonUtils.stringListValue(unused),
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

  void logMapSelect({String? target}) {
    
    logEvent({
      LogEventName             : LogMapSelectEventName,
      LogMapSelectTarget       : target
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
        case Auth2LoginType.username:     action = LogAuthLoginUsernameActionName; break;
        case Auth2LoginType.apiKey:
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

  void logWellness({String? category, String? action, String? target, String? source, Map<String, dynamic>? attributes}) {
    Map<String, dynamic> event = {
      LogEventName            : LogWellnessEventName,
      LogWellnessCategoryName : category,
      LogWellnessActionName   : action,
      LogWellnessTargetName   : target,
      LogWellnessSourceName   : source,
    };
    if (attributes != null) {
      event.addAll(attributes);
    }
    logEvent(event);
  }

  void logWellnessToDo({String? action, wellness.ToDoItem? item, String? source}) {
    logWellness(
      category: LogWellnessCategoryToDo,
      action: action,
      target: item?.name,
      source: source,
      attributes: {
        LogWellnessToDoCategoryName: item?.category?.name,
        LogWellnessToDoDueDateTime: DateTimeUtils.utcDateTimeToString(item?.dueDateTime),
        LogWellnessToDoReminderType: item?.reminderType.toString(),
        LogWellnessToDoWorkdays: item?.workDays?.join(','),
      }
    );
  }

  void logWellnessRing({String? action, WellnessRingDefinition? item, String? source}) {
    logWellness(
      category: Analytics.LogWellnessCategoryRings,
      action: action,
      target: item?.name,
      source: source,
      attributes: {
        Analytics.LogWellnessRingGoalName: item?.goal,
        Analytics.LogWellnessRingUnitName: item?.unit,
      }
    );
  }

  void logVideo({required String videoEvent, String? videoId, String? videoTitle, int? duration, int? position}) {
    Map<String, dynamic> event = {
      LogEventName                : LogVideoEventName,
      LogAttributeVideoId         : videoId,
      LogAttributeVideoTitle      : videoTitle,
      LogAttributeVideoEvent      : videoEvent,
      LogAttributeVideoDuration   : duration,
      LogAttributeVideoPosition   : position,
    };
    logEvent(event);
  }

  void logResearchQuestionnaiire({List<dynamic>? answers, Map<String, dynamic>? attributes}) {
    // Build event data
    Map<String, dynamic> event = {
      LogEventName                        : LogResearchQuestionnaireEventName,
      LogResearchQuestionnaireAnswersName : answers,
    };

    // Add optional attribute, if applied
    if (attributes != null) {
      event.addAll(attributes);
    }

    // Log the event
    logEvent(event);
  }
}


abstract class AnalyticsPageName {
  String? get analyticsPageName;
}

abstract class AnalyticsPageAttributes {
  Map<String, dynamic>? get analyticsPageAttributes;
}

class _TicketWidget extends StatefulWidget {
  @override
  _TicketWidgetState createState() => _TicketWidgetState();
}

class _TicketWidgetState extends State<_TicketWidget> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) => Container();
}