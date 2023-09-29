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
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/firebase_messaging.dart' as rokwire;

import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class FirebaseMessaging extends rokwire.FirebaseMessaging implements NotificationsListener {

  static String get notifyToken                  => rokwire.FirebaseMessaging.notifyToken;
  static String get notifyForegroundMessage      => rokwire.FirebaseMessaging.notifyForegroundMessage;
  static String get notifyGroupsNotification     => rokwire.FirebaseMessaging.notifyGroupsNotification;

  static const String notifyBase                                       = 'edu.illinois.rokwire.firebase.messaging';
  static const String notifyPopupMessage                               = "$notifyBase.message.popup";
  static const String notifyScoreMessage                               = "$notifyBase.message.score";
  static const String notifyConfigUpdate                               = "$notifyBase.config.update";
  static const String notifyPollNotification                           = "$notifyBase.poll";
  static const String notifyPollOpen                                   = "$notifyBase.poll.create";
  static const String notifyEventsNotification                         = "$notifyBase.events";
  static const String notifyEventDetail                                = "$notifyBase.event.detail";
  static const String notifyEventAttendeeSurveyInvitation              = "$notifyBase.event.attendee.survey.invitation";
  static const String notifyGameDetail                                 = "$notifyBase.game.detail";
  static const String notifyAthleticsGameStarted                       = "$notifyBase.athletics_game.started";
  static const String notifyAthleticsNewsUpdated                       = "$notifyBase.athletics.news.updated";
  static const String notifyAthleticsTeam                              = "$notifyBase.athletics.team";
  static const String notifyAthleticsTeamRoster                        = "$notifyBase.athletics.team.roster";
  static const String notifySettingUpdated                             = "$notifyBase.setting.updated";
  static const String notifyGroupPostNotification                      = "$notifyBase.group.posts.updated";
  static const String notifyHomeNotification                           = "$notifyBase.home";
  static const String notifyBrowseNotification                         = "$notifyBase.browse";
  static const String notifyMapNotification                            = "$notifyBase.map";
  static const String notifyMapEventsNotification                      = '$notifyBase.map.events';
  static const String notifyMapDiningNotification                      = '$notifyBase.map.dining';
  static const String notifyMapBuildingsNotification                   = '$notifyBase.map.buildings';
  static const String notifyMapStudentCoursesNotification              = '$notifyBase.map.student_courses';
  static const String notifyMapAppointmentsNotification                = '$notifyBase.map.appointments';
  static const String notifyMapMtdStopsNotification                    = '$notifyBase.map.mtd_stops';
  static const String notifyMapMtdDestinationsNotification             = '$notifyBase.map.mtd_destinations';
  static const String notifyMapMentalHealthNotification                = '$notifyBase.map.mental_health';
  static const String notifyMapStateFarmWayfindingNotification         = '$notifyBase.map.state_farm_wayfinding';
  static const String notifyAcademicsNotification                      = "$notifyBase.academics";
  static const String notifyAcademicsAppointmentsNotification          = "$notifyBase.academics.appointments";
  static const String notifyAcademicsCanvasCoursesNotification         = "$notifyBase.academics.canvas_courses";
  static const String notifyAcademicsDueDateCatalogNotification        = "$notifyBase.academics.due_date_catalog";
  static const String notifyAcademicsEventsNotification                = "$notifyBase.academics.events";
  static const String notifyAcademicsGiesChecklistNotification         = "$notifyBase.academics.gies_checklist";
  static const String notifyAcademicsMedicineCoursesNotification       = "$notifyBase.academics.medicine_courses";
  static const String notifyAcademicsMyIlliniNotification              = "$notifyBase.academics.my_illini";
  static const String notifyAcademicsSkillsSelfEvaluationNotification  = "$notifyBase.academics.skills_self_evaluation";
  static const String notifyAcademicsStudentCoursesNotification        = "$notifyBase.academics.student_courses";
  static const String notifyAcademicsToDoListNotification              = "$notifyBase.academics.todo_list";
  static const String notifyAcademicsUiucChecklistNotification         = "$notifyBase.academics.uiuc_checklist";
  static const String notifyWellnessNotification                       = "$notifyBase.wellness";
  static const String notifyWellnessDailyTipsNotification              = "$notifyBase.wellness.daily_tips";
  static const String notifyWellnessRingsNotification                  = "$notifyBase.wellness.rings";
  static const String notifyWellnessTodoListNotification               = "$notifyBase.wellness.todo_list";
  static const String notifyWellnessAppointmentsNotification           = "$notifyBase.wellness.appointments";
  static const String notifyWellnessHealthScreenerNotification         = "$notifyBase.wellness.health_screener";
  static const String notifyWellnessPodcastNotification                = "$notifyBase.wellness.podcast";
  static const String notifyWellnessResourcesNotification              = "$notifyBase.wellness.resources";
  static const String notifyWellnessStrugglingNotification             = "$notifyBase.wellness.struggling";
  static const String notifyWellnessMentalHealthNotification           = "$notifyBase.wellness.mental_health";
  static const String notifyInboxNotification                          = "$notifyBase.inbox";
  static const String notifyCanvasAppDeepLinkNotification              = "$notifyBase.app.canvas.deeplink";
  static const String notifyAppointmentNotification                    = "$notifyBase.appointment";
  static const String notifyWellnessToDoItemNotification               = "$notifyBase.wellness.to_do";
  static const String notifyProfileMyNotification                      = "$notifyBase.profile.my";
  static const String notifyProfileWhoAreYouNotification               = "$notifyBase.profile.who_are_you";
  static const String notifyProfilePrivacyNotification                 = "$notifyBase.profile.privacy";
  static const String notifySettingsSectionsNotification               = "$notifyBase.settings.sections";
  static const String notifySettingsInterestsNotification              = "$notifyBase.settings.interests";
  static const String notifySettingsFoodFiltersNotification            = "$notifyBase.settings.food_filters";
  static const String notifySettingsSportsNotification                 = "$notifyBase.settings.sports";
  static const String notifySettingsFavoritesNotification              = "$notifyBase.settings.favorites";
  static const String notifySettingsAssessmentsNotification            = "$notifyBase.settings.assessments";
  static const String notifySettingsCalendarNotification               = "$notifyBase.settings.calendar";
  static const String notifySettingsAppointmentsNotification           = "$notifyBase.settings.appointments";
  static const String notifyGuideArticleDetailNotification             = "$notifyBase.guide.article.detail";

  // Topic names
  static const List<String> _permanentTopics = [
    "config_update",
    "popup_message",
    "polls",
  ];

  // Settings entry : topic name
  static const Map<String, String> _notifySettingTopics = {
    'event_reminders'  : 'event_reminders',
    'dining_specials'  : 'dinning_specials',
    _groupUpdatesPostsNotificationSetting : _groupUpdatesPostsNotificationSetting,
    _groupUpdatesInvitationsNotificationSetting : _groupUpdatesInvitationsNotificationSetting,
    _groupUpdatesEventsNotificationSetting : _groupUpdatesEventsNotificationSetting,
    _groupUpdatesPollsNotificationSetting : _groupUpdatesPollsNotificationSetting,
  };

  // Settings entry : setting name (User.prefs.setting name)
  static const Map<String, String> _notifySettingNames = {
    _eventRemindersUpdatesNotificationSetting   : 'edu.illinois.rokwire.settings.inbox.notification.event_reminders.enabled',
    _diningSpecialsUpdatesNotificationSetting   : 'edu.illinois.rokwire.settings.inbox.notification.dining_specials.enabled',
    _groupUpdatesPostsNotificationSetting       : 'edu.illinois.rokwire.settings.inbox.notification.group.posts.enabled',
    _groupUpdatesPollsNotificationSetting       : 'edu.illinois.rokwire.settings.inbox.notification.group.polls.enabled',
    _groupUpdatesInvitationsNotificationSetting : 'edu.illinois.rokwire.settings.inbox.notification.group.invitations.enabled',
    _groupUpdatesEventsNotificationSetting      : 'edu.illinois.rokwire.settings.inbox.notification.group.events.enabled',
    _athleticsUpdatesStartNotificationSetting   : 'edu.illinois.rokwire.settings.inbox.notification.athletic_updates.start.enabled',
    _athleticsUpdatesEndNotificationSetting     : 'edu.illinois.rokwire.settings.inbox.notification.athletic_updates.end.enabled',
    _athleticsUpdatesNewsNotificationSetting    : 'edu.illinois.rokwire.settings.inbox.notification.athletic_updates.news.enabled',
    _athleticsUpdatesNotificationKey            : 'edu.illinois.rokwire.settings.inbox.notification.athletic_updates.main.notifications.enabled',
    _groupUpdatesNotificationKey                : 'edu.illinois.rokwire.settings.inbox.notification.group.main.notifications.enabled',
    _pauseNotificationKey                       : 'edu.illinois.rokwire.settings.inbox.notification.event_reminders.enabled',
  };

  static const Map<String, bool> _defaultNotificationSettings = {
    _pauseNotificationKey : false
  };

  //settingKeys
  static const String _eventRemindersUpdatesNotificationSetting = 'event_reminders';
  static const String _diningSpecialsUpdatesNotificationSetting = 'dining_specials';
  static const String _pauseNotificationKey = 'pause_notifications';

  static const String _athleticsUpdatesNotificationKey = 'athletic_updates';
  static const String _groupUpdatesNotificationKey = 'group';

  // Athletics Notification updates
  static const String _athleticsStartNotificationKey = 'start';
  static const String _athleticsEndNotificationKey = 'end';
  static const String _athleticsNewsNotificationKey = 'news';

  static const List<String> _athleticsNotificationsKeyList = [_athleticsStartNotificationKey, _athleticsEndNotificationKey, _athleticsNewsNotificationKey];

  static const String _athleticsUpdatesStartNotificationSetting = '$_athleticsUpdatesNotificationKey.$_athleticsStartNotificationKey';
  static const String _athleticsUpdatesEndNotificationSetting = '$_athleticsUpdatesNotificationKey.$_athleticsEndNotificationKey';
  static const String _athleticsUpdatesNewsNotificationSetting = '$_athleticsUpdatesNotificationKey.$_athleticsNewsNotificationKey';

  // Group Notification updates
  static const String _groupPostsNotificationKey = 'posts';
  static const String _groupInvitationsNotificationKey = 'invitations';
  static const String _groupEventsNotificationKey = 'events';
  static const String _groupPollsNotificationKey = 'polls';

  static const List<String> _groupNotificationsKeyList = [_groupPostsNotificationKey, _groupInvitationsNotificationKey, _groupEventsNotificationKey, _groupPollsNotificationKey];

  static const String _groupUpdatesPostsNotificationSetting = '$_groupUpdatesNotificationKey.$_groupPostsNotificationKey';
  static const String _groupUpdatesInvitationsNotificationSetting = '$_groupUpdatesNotificationKey.$_groupInvitationsNotificationKey';
  static const String _groupUpdatesEventsNotificationSetting = '$_groupUpdatesNotificationKey.$_groupEventsNotificationKey';
  static const String _groupUpdatesPollsNotificationSetting = '$_groupUpdatesNotificationKey.$_groupPollsNotificationKey';

  // Payload types
  static const String payloadTypeConfigUpdate = 'config_update';
  static const String payloadTypePopupMessage = 'popup_message';
  static const String payloadTypeOpenPoll = 'poll_open';
  static const String payloadTypeEvents = 'events';
  static const String payloadTypeEventDetail = 'event_detail';
  static const String payloadTypeEvent = 'event';
  static const String payloadTypeGameDetail = 'game_detail';
  static const String payloadTypeAthleticsGameStarted = 'athletics_game_started';
  static const String payloadTypeAthleticsNewDetail = 'athletics_news_detail';
  static const String payloadTypeAthleticsTeam = 'athletics.team';
  static const String payloadTypeAthleticsTeamRoster = 'athletics.team.roster';
  static const String payloadTypeGroup = 'group';
  static const String payloadTypeHome = 'home';
  static const String payloadTypeBrowse = 'browse';
  static const String payloadTypeMap = 'map';
  static const String payloadTypeMapEvents = 'map.events';
  static const String payloadTypeMapDining = 'map.dining';
  static const String payloadTypeMapBuildings = 'map.buildings';
  static const String payloadTypeMapStudentCourses = 'map.student_courses';
  static const String payloadTypeMapAppointments = 'map.appointments';
  static const String payloadTypeMapMtdStops = 'map.mtd_stops';
  static const String payloadTypeMapMtdDestinations = 'map.mtd_destinations';
  static const String payloadTypeMapMentalHealth = 'map.mental_health';
  static const String payloadTypeMapStateFarmWayfinding = 'map.state_farm_wayfinding';
  static const String payloadTypeAcademics = 'academics';
  static const String payloadTypeAcademicsGiesCheckilst = 'academics.gies_checklist';
  static const String payloadTypeAcademicsUiucCheckilst = 'academics.uiuc_checklist';
  static const String payloadTypeAcademicsEvents = 'academics.events';
  static const String payloadTypeAcademicsCanvasCourses = 'academics.canvas_courses';
  static const String payloadTypeAcademicsMedicineCourses = 'academics.medicine_courses';
  static const String payloadTypeAcademicsStudentCourses = 'academics.student_courses';
  static const String payloadTypeAcademicsSkillsSelfEvaluation = 'academics.skills_self_evaluation';
  static const String payloadTypeAcademicsToDoList = 'academics.todo_list';
  static const String payloadTypeAcademicsDueDateCatalog = 'academics.due_date_catalog';
  static const String payloadTypeAcademicsMyIllini = 'academics.my_illini';
  static const String payloadTypeAcademicsAppointments = 'academics.appointments';
  static const String payloadTypeWellness = 'wellness';
  static const String payloadTypeWellnessDailyTips = 'wellness.daily_tips';
  static const String payloadTypeWellnessRings = 'wellness.rings';
  static const String payloadTypeWellnessTodoList = 'wellness.todo';
  static const String payloadTypeWellnessAppointments = 'wellness.appointments';
  static const String payloadTypeWellnessHealthScreener = 'wellness.health_screener';
  static const String payloadTypeWellnessPodcast = 'wellness.podcast';
  static const String payloadTypeWellnessResources = 'wellness.resources';
  static const String payloadTypeWellnessStruggling = 'wellness.struggling';
  static const String payloadTypeWellnessMentalHealth = 'wellness.mental_health';
  static const String payloadTypeInbox = 'inbox';
  static const String payloadTypeCanvasAppDeepLink = 'canvas_app_deeplink';
  static const String payloadTypeAppointment = 'appointment';
  static const String payloadTypeWellnessToDoItem = 'wellness_todo_entry';
  static const String payloadTypePoll = 'poll';
  static const String payloadTypeProfileMy = 'profile.my';
  static const String payloadTypeProfileWhoAreYou = 'profile.who_are_you';
  static const String payloadTypeProfilePrivacy = 'profile.privacy';
  static const String payloadTypeSettingsSections = 'settings.sections';
  static const String payloadTypeSettingsInterests = 'settings.interests';
  static const String payloadTypeSettingsFoodFilters = 'settings.food_filters';
  static const String payloadTypeSettingsSports = 'settings.sports';
  static const String payloadTypeSettingsFavorites = 'settings.favorites';
  static const String payloadTypeSettingsAssessments = 'settings.assessments';
  static const String payloadTypeSettingsCalendar = 'settings.calendar';
  static const String payloadTypeSettingsAppointments = 'settings.appointments';
  static const String payloadTypeGuideArticleDetail= 'guide.article.detail';

  DateTime? _pausedDateTime;
  
  // Singletone Factory

  @protected
  FirebaseMessaging.internal() : super.internal();

  factory FirebaseMessaging() => ((rokwire.FirebaseMessaging.instance is FirebaseMessaging) ? (rokwire.FirebaseMessaging.instance as FirebaseMessaging) : (rokwire.FirebaseMessaging.instance = FirebaseMessaging.internal()));

  // Service

  @override
  void createService() {
    super.createService();
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyRolesChanged,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2UserPrefs.notifyInterestsChanged,
      Auth2.notifyProfileChanged,
      Auth2.notifyUserDeleted,
      FlexUI.notifyChanged,
      AppLivecycle.notifyStateChanged,
      Inbox.notifyInboxUserInfoChanged
    ]);
  }

  @override
  void destroyService() {
    super.destroyService();
    NotificationService().unsubscribe(this);
  }

  @override
  Set<Service> get serviceDependsOn {
    Set<Service> services = super.serviceDependsOn;
    services.add(Auth2());
    return services;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyRolesChanged) {
      _updateRolesSubscriptions();
    }
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      _updateNotifySettingsSubscriptions();
    }
    else if (name == Auth2UserPrefs.notifyInterestsChanged) {
      _updateAthleticsSubscriptions();
    }
    else if (name == Auth2.notifyProfileChanged) {
      _updateSubscriptions();
    }
    else if (name == Auth2.notifyUserDeleted) {
      _updateSubscriptions();
    }
    else if (name == FlexUI.notifyChanged) {
      _updateNotifySettingsSubscriptions();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param); 
    }
    else if (name == Inbox.notifyInboxUserInfoChanged) {
      _updateSubscriptions();
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateSubscriptions();
        }
      }
    }
  }

  // Token

  @override
  void applyToken(String? token) {
    super.applyToken(token);
    _updateSubscriptions();
  }

  // Message Processing

  @override
  void processDataMessage(Map<String, dynamic>? data) {
    String? messageId = JsonUtils.stringValue(data?['message_id']);
    if (messageId != null) {
      Inbox().readMessage(messageId);
    }
    _processDataMessage(data);
  }

  void _processDataMessage(Map<String, dynamic>? data, {String? type} ) {
    
    if (type == null) {
      type = _getMessageType(data);
    }
    
    if (type == payloadTypeConfigUpdate) {
      _onConfigUpdate(data);
    }
    else if (type == payloadTypePopupMessage) {
      NotificationService().notify(notifyPopupMessage, data);
    }
    else if (type == payloadTypeOpenPoll) {
      NotificationService().notify(notifyPollOpen, data);
    }
    else if (type == payloadTypePoll) {
      NotificationService().notify(notifyPollNotification, data);
    }
    else if (type == payloadTypeEvents) {
      NotificationService().notify(notifyEventsNotification, data);
    }
    else if (type == payloadTypeEventDetail) {
      NotificationService().notify(notifyEventDetail, data);
    }
    else if (type == payloadTypeEvent) {
      String? entityType = JsonUtils.stringValue(data?['entity_type']);
      String? operation = JsonUtils.stringValue(data?['operation']);
      if ((entityType == 'event_attendance') && (operation == 'survey_invite')) {
        NotificationService().notify(notifyEventAttendeeSurveyInvitation, data);
      }
    }
    else if (type == payloadTypeGameDetail) {
      NotificationService().notify(notifyGameDetail, data);
    }
    else if (type == payloadTypeAthleticsGameStarted) {
      NotificationService().notify(notifyAthleticsGameStarted, data);
    }
    else if (type == payloadTypeAthleticsNewDetail) {
      NotificationService().notify(notifyAthleticsNewsUpdated, data);
    }
    else if (type == payloadTypeAthleticsTeam) {
      NotificationService().notify(notifyAthleticsTeam, data);
    }
    else if (type == payloadTypeAthleticsTeamRoster) {
      NotificationService().notify(notifyAthleticsTeamRoster, data);
    }
    else if (type == payloadTypeGroup) {
      String? groupPostId = JsonUtils.stringValue(data?['post_id']);
      if (groupPostId != null) {
        NotificationService().notify(notifyGroupPostNotification, data);
      } else {
        NotificationService().notify(notifyGroupsNotification, data);
      }
    }
    else if (type == payloadTypeHome) {
      NotificationService().notify(notifyHomeNotification, data);
    }
    else if (type == payloadTypeBrowse) {
      NotificationService().notify(notifyBrowseNotification, data);
    }
    else if (type == payloadTypeMap) {
      NotificationService().notify(notifyMapNotification, data);
    }
    else if (type == payloadTypeMapEvents) {
      NotificationService().notify(notifyMapEventsNotification, data);
    }
    else if (type == payloadTypeMapDining) {
      NotificationService().notify(notifyMapDiningNotification, data);
    }
    else if (type == payloadTypeMapBuildings) {
      NotificationService().notify(notifyMapBuildingsNotification, data);
    }
    else if (type == payloadTypeMapStudentCourses) {
      NotificationService().notify(notifyMapStudentCoursesNotification, data);
    }
    else if (type == payloadTypeMapAppointments) {
      NotificationService().notify(notifyMapAppointmentsNotification, data);
    }
    else if (type == payloadTypeMapMtdStops) {
      NotificationService().notify(notifyMapMtdStopsNotification, data);
    }
    else if (type == payloadTypeMapMtdDestinations) {
      NotificationService().notify(notifyMapMtdDestinationsNotification, data);
    }
    else if (type == payloadTypeMapMentalHealth) {
      NotificationService().notify(notifyMapMentalHealthNotification, data);
    }
    else if (type == payloadTypeMapStateFarmWayfinding) {
      NotificationService().notify(notifyMapStateFarmWayfindingNotification, data);
    }
    else if (type == payloadTypeAcademics) {
      NotificationService().notify(notifyAcademicsNotification, data);
    }
    else if (type == payloadTypeAcademicsAppointments) {
      NotificationService().notify(notifyAcademicsAppointmentsNotification, data);
    }
    else if (type == payloadTypeAcademicsCanvasCourses) {
      NotificationService().notify(notifyAcademicsCanvasCoursesNotification, data);
    }
    else if (type == payloadTypeAcademicsDueDateCatalog) {
      NotificationService().notify(notifyAcademicsDueDateCatalogNotification, data);
    }
    else if (type == payloadTypeAcademicsEvents) {
      NotificationService().notify(notifyAcademicsEventsNotification, data);
    }
    else if (type == payloadTypeAcademicsGiesCheckilst) {
      NotificationService().notify(notifyAcademicsGiesChecklistNotification, data);
    }
    else if (type == payloadTypeAcademicsMedicineCourses) {
      NotificationService().notify(notifyAcademicsMedicineCoursesNotification, data);
    }
    else if (type == payloadTypeAcademicsMyIllini) {
      NotificationService().notify(notifyAcademicsMyIlliniNotification, data);
    }
    else if (type == payloadTypeAcademicsSkillsSelfEvaluation) {
      NotificationService().notify(notifyAcademicsSkillsSelfEvaluationNotification, data);
    }
    else if (type == payloadTypeAcademicsStudentCourses) {
      NotificationService().notify(notifyAcademicsStudentCoursesNotification, data);
    }
    else if (type == payloadTypeAcademicsToDoList) {
      NotificationService().notify(notifyAcademicsToDoListNotification, data);
    }
    else if (type == payloadTypeAcademicsUiucCheckilst) {
      NotificationService().notify(notifyAcademicsUiucChecklistNotification, data);
    }
    else if (type == payloadTypeWellness) {
      NotificationService().notify(notifyWellnessNotification, data);
    }
    else if (type == payloadTypeWellnessAppointments) {
      NotificationService().notify(notifyWellnessAppointmentsNotification, data);
    }
    else if (type == payloadTypeWellnessDailyTips) {
      NotificationService().notify(notifyWellnessDailyTipsNotification, data);
    }
    else if (type == payloadTypeWellnessHealthScreener) {
      NotificationService().notify(notifyWellnessHealthScreenerNotification, data);
    }
    else if (type == payloadTypeWellnessMentalHealth) {
      NotificationService().notify(notifyWellnessMentalHealthNotification, data);
    }
    else if (type == payloadTypeWellnessPodcast) {
      NotificationService().notify(notifyWellnessPodcastNotification, data);
    }
    else if (type == payloadTypeWellnessResources) {
      NotificationService().notify(notifyWellnessResourcesNotification, data);
    }
    else if (type == payloadTypeWellnessRings) {
      NotificationService().notify(notifyWellnessRingsNotification, data);
    }
    else if (type == payloadTypeWellnessStruggling) {
      NotificationService().notify(notifyWellnessStrugglingNotification, data);
    }
    else if (type == payloadTypeWellnessTodoList) {
      NotificationService().notify(notifyWellnessTodoListNotification, data);
    }
    else if (type == payloadTypeInbox) {
      NotificationService().notify(notifyInboxNotification, data);
    }
    else if (type == payloadTypeCanvasAppDeepLink) {
      NotificationService().notify(notifyCanvasAppDeepLinkNotification, data);
    }
    else if (type == payloadTypeAppointment) {
      NotificationService().notify(notifyAppointmentNotification, data);
    }
    else if (type == payloadTypeWellnessToDoItem) {
      NotificationService().notify(notifyWellnessToDoItemNotification, data);
    }
    else if (type == payloadTypeProfileMy) {
      NotificationService().notify(notifyProfileMyNotification, data);
    }
    else if (type == payloadTypeProfileWhoAreYou) {
      NotificationService().notify(notifyProfileWhoAreYouNotification, data);
    }
    else if (type == payloadTypeProfilePrivacy) {
      NotificationService().notify(notifyProfilePrivacyNotification, data);
    }
    else if (type == payloadTypeSettingsSections) {
      NotificationService().notify(notifySettingsSectionsNotification, data);
    }
    else if (type == payloadTypeSettingsInterests) {
      NotificationService().notify(notifySettingsInterestsNotification, data);
    }
    else if (type == payloadTypeSettingsInterests) {
      NotificationService().notify(notifySettingsInterestsNotification, data);
    }
    else if (type == payloadTypeSettingsFoodFilters) {
      NotificationService().notify(notifySettingsFoodFiltersNotification, data);
    }
    else if (type == payloadTypeSettingsSports) {
      NotificationService().notify(notifySettingsSportsNotification, data);
    }
    else if (type == payloadTypeSettingsFavorites) {
      NotificationService().notify(notifySettingsFavoritesNotification, data);
    }
    else if (type == payloadTypeSettingsAssessments) {
      NotificationService().notify(notifySettingsAssessmentsNotification, data);
    }
    else if (type == payloadTypeSettingsCalendar) {
      NotificationService().notify(notifySettingsCalendarNotification, data);
    }
    else if (type == payloadTypeSettingsAppointments) {
      NotificationService().notify(notifySettingsAppointmentsNotification, data);
    }
    else if (type == payloadTypeGuideArticleDetail) {
      NotificationService().notify(notifyGuideArticleDetailNotification, data);
    }
    else if (_isScoreTypeMessage(type)) {
      NotificationService().notify(notifyScoreMessage, data);
    }
    else {
      Log.d("FCM: unknown message type: ${JsonUtils.encode(data)}");
    }
  }

  static String? _getMessageType(Map<String, dynamic>? data) {
    if (data == null)
      return null;

    //1. check type
    String? type = data["type"];
    if (type != null)
      return type;

    //2. check Type - deprecated!
    String? type2 = data["Type"];
    if (type2 != null)
      return type2;

    //3. check Path - deprecated!
    String? path = data["Path"];
    if (path != null) {
      String? gameId = data['GameId'];
      dynamic hasStarted = data['HasStarted'];
      // Handle 'Game Started / Ended' notification which does not contain key 'HasStarted'
      if (StringUtils.isNotEmpty(gameId) && (hasStarted == null)) {
        return 'athletics_game_started';
      } else {
        return path;
      }
    }

    //treat everything else as config update - the backend gives it without "type"!
    return "config_update";
  }

  bool _isScoreTypeMessage(String? type) {
    return type == "football" ||
        type == "mbball" ||
        type == "wbball" ||
        type == "mvball" ||
        type == "wvball" ||
        type == "mtennis" ||
        type == "wtennis" ||
        type == "baseball" ||
        type == "softball" ||
        type == "wsoc";
  }

  void _onConfigUpdate(Map<String, dynamic>? data) {
    int interval = 5 * 60; // 5 minutes
    var rng = new Random();
    int delay = rng.nextInt(interval);
    Log.d("FCM: Scheduled config update after ${delay.toString()} seconds");
    Timer(Duration(seconds: delay), () {
      Log.d("FCM: Perform config update");
      NotificationService().notify(notifyConfigUpdate, data);
    });
  }

  void processDataMessageEx(Map<String, dynamic>? data, { Set<String>? allowedPayloadTypes }) {
    String? messageType;
    if ((allowedPayloadTypes == null) || (allowedPayloadTypes.contains(messageType = _getMessageType(data)))) {
      _processDataMessage(data, type: messageType);
    }
  }

  // Settings topics

  bool? get notifyEventReminders               { return _getNotifySetting('event_reminders'); } 
       set notifyEventReminders(bool? value)   { _setNotifySetting('event_reminders', value); }

  bool? get notifyAthleticsUpdates             { return _getNotifySetting(_athleticsUpdatesNotificationKey); }
       set notifyAthleticsUpdates(bool? value) { _setNotifySetting(_athleticsUpdatesNotificationKey, value); }

  bool? get notifyStartAthleticsUpdates              { return _getNotifySetting(_athleticsUpdatesStartNotificationSetting); }
       set notifyStartAthleticsUpdates(bool? value)  { _setNotifySetting(_athleticsUpdatesStartNotificationSetting, value); }

  bool? get notifyEndAthleticsUpdates                { return _getNotifySetting(_athleticsUpdatesEndNotificationSetting); }
       set notifyEndAthleticsUpdates(bool? value)    { _setNotifySetting(_athleticsUpdatesEndNotificationSetting, value); }

  bool? get notifyNewsAthleticsUpdates               { return _getNotifySetting(_athleticsUpdatesNewsNotificationSetting); }
       set notifyNewsAthleticsUpdates(bool? value)   { _setNotifySetting(_athleticsUpdatesNewsNotificationSetting, value); }

  bool? get notifyGroupUpdates             { return _getNotifySetting(_groupUpdatesNotificationKey); }
  set notifyGroupUpdates(bool? value) { _setNotifySetting(_groupUpdatesNotificationKey, value); }

  bool? get notifyGroupPostUpdates              { return _getNotifySetting(_groupUpdatesPostsNotificationSetting); }
  set notifyGroupPostUpdates(bool? value)  { _setNotifySetting(_groupUpdatesPostsNotificationSetting, value); }

  bool? get notifyGroupInvitationsUpdates                { return _getNotifySetting(_groupUpdatesInvitationsNotificationSetting); }
  set notifyGroupInvitationsUpdates(bool? value)    { _setNotifySetting(_groupUpdatesInvitationsNotificationSetting, value); }

  bool? get notifyGroupPollsUpdates                { return _getNotifySetting(_groupUpdatesPollsNotificationSetting); }
  set notifyGroupPollsUpdates(bool? value)    { _setNotifySetting(_groupUpdatesPollsNotificationSetting, value); }

  bool? get notifyGroupEventsUpdates               { return _getNotifySetting(_groupUpdatesEventsNotificationSetting); }
  set notifyGroupEventsUpdates(bool? value)   { _setNotifySetting(_groupUpdatesEventsNotificationSetting, value); }

  bool? get notifyDiningSpecials               { return _getNotifySetting('dining_specials'); } 
       set notifyDiningSpecials(bool? value)   { _setNotifySetting('dining_specials', value); }

  set notificationsPaused(bool? value)   {_setNotifySetting(_pauseNotificationKey, value);}

  bool? get notificationsPaused {return _getStoredSetting(_pauseNotificationKey,);}

  bool get _notifySettingsAvailable  {
    return FlexUI().isNotificationsAvailable;
  }

  bool? _getNotifySetting(String name) {
    if (_notifySettingsAvailable) {
      return _getStoredSetting(name);
    }
    else {
      return false;
    }
  }

  void _setNotifySetting(String name, bool? value) {
    if (_notifySettingsAvailable && (_getNotifySetting(name) != value)) {
      _storeSetting(name, value);
      NotificationService().notify(notifySettingUpdated, name);

      if (name == _athleticsUpdatesNotificationKey) {
        _processAthleticsSubscriptions(subscribedTopics: currentTopics);
      } else if (name == _athleticsUpdatesStartNotificationSetting) {
        _processAthleticsSingleSubscription(_athleticsStartNotificationKey);
      } else if (name == _athleticsUpdatesEndNotificationSetting) {
        _processAthleticsSingleSubscription(_athleticsEndNotificationKey);
      } else if (name == _athleticsUpdatesNewsNotificationSetting) {
        _processAthleticsSingleSubscription(_athleticsNewsNotificationKey);
      } else if (name == _groupUpdatesNotificationKey) {
        _processGroupsSubscriptions(subscribedTopics: currentTopics);
      } else if (name == _pauseNotificationKey) {
        Inbox().applySettingNotificationsEnabled(value);
      } else {
        _processNotifySettingSubscription(topic: _notifySettingTopics[name], value: value, subscribedTopics: currentTopics);
      }

    }
  }

  // Subscription Management

  void _updateSubscriptions(){
    if (hasToken) {
      Set<String?>? subscribedTopics = currentTopics;
      _processPermanentSubscriptions(subscribedTopics: subscribedTopics);
      _processRolesSubscriptions(subscribedTopics: subscribedTopics);
      _processNotifySettingsSubscriptions(subscribedTopics: subscribedTopics);
      _processAthleticsSubscriptions(subscribedTopics: subscribedTopics);
      _processGroupsSubscriptions(subscribedTopics: subscribedTopics);
    }
  }

  void _updateRolesSubscriptions(){
    if (hasToken) {
      _processRolesSubscriptions(subscribedTopics: currentTopics);
    }
  }

  void _updateNotifySettingsSubscriptions(){
    if (hasToken) {
      _processNotifySettingsSubscriptions(subscribedTopics: currentTopics);
    }
  }

  void _updateAthleticsSubscriptions(){
    if (hasToken) {
      _processAthleticsSubscriptions(subscribedTopics: currentTopics);
    }
  }

  void _processPermanentSubscriptions({Set<String?>? subscribedTopics}) {
    for (String permanentTopic in _permanentTopics) {
      if ((subscribedTopics == null) || !subscribedTopics.contains(permanentTopic)) {
        subscribeToTopic(permanentTopic);
      }
    }
  }

  void _processRolesSubscriptions({Set<String?>? subscribedTopics}) {
    Set<UserRole>? roles = Auth2().prefs?.roles;
    for (UserRole role in UserRole.values) {
      String roleTopic = role.toString();
      bool roleSubscribed = (subscribedTopics != null) && subscribedTopics.contains(roleTopic);
      bool roleSelected = (roles != null) && roles.contains(role);
      if (roleSelected && !roleSubscribed) {
        subscribeToTopic(roleTopic);
      }
      else if (!roleSelected && roleSubscribed) {
        unsubscribeFromTopic(roleTopic);
      }
    }
  }
  
  void _processNotifySettingsSubscriptions({Set<String?>? subscribedTopics}) {
    _notifySettingTopics.forEach((String setting, String topic) {
      bool? value = _getNotifySetting(setting);
      _processNotifySettingSubscription(topic: topic, value: value, subscribedTopics: subscribedTopics);
    });
  }

  void _processNotifySettingSubscription({String? topic, bool? value, Set<String?>? subscribedTopics}) {
    if (topic != null) {
      bool itemSubscribed = (subscribedTopics != null) && subscribedTopics.contains(topic);
      if (value! && !itemSubscribed) {
        subscribeToTopic(topic);
      }
      else if (!value && itemSubscribed) {
        unsubscribeFromTopic(topic);
      }
    }
  }

  void _processAthleticsSubscriptions({Set<String?>? subscribedTopics}) {
    bool? notifyAthletics = notifyAthleticsUpdates;
    List<SportDefinition>? sportDefs = Sports().sports;
    if (sportDefs != null) {
      for (SportDefinition sportDef in sportDefs) {
        String? sport = sportDef.shortName;
        for (String key in _athleticsNotificationsKeyList) {
          _processAthleticsSubscriptionForSport(notifyAllowed: notifyAthletics, athleticsKey: key, sport: sport, subscribedTopics: subscribedTopics);
        }
      }
    }
  }

  void _processAthleticsSingleSubscription(String athleticsKey) {
    List<SportDefinition>? sports = Sports().sports;
    if (CollectionUtils.isNotEmpty(sports)) {
      Set<String?>? subscribedTopics = currentTopics;
      for (SportDefinition sport in sports!) {
        _processAthleticsSubscriptionForSport(notifyAllowed: true, athleticsKey: athleticsKey, sport: sport.shortName, subscribedTopics: subscribedTopics);
      }
    }
  }

  void _processAthleticsSubscriptionForSport({bool? notifyAllowed, String? athleticsKey, String? sport, Set<String?>? subscribedTopics}) {
    if (StringUtils.isNotEmpty(sport)) {
      bool notify = notifyAllowed! && _getNotifySetting('$_athleticsUpdatesNotificationKey.$athleticsKey')!;
      bool sportSelected = Auth2().prefs?.sportsInterests?.contains(sport) ?? false;
      bool subscriptionValue = notify && sportSelected;
      String topic = 'athletics.$sport.notification.$athleticsKey';
      bool subscribed = subscribedTopics?.contains(topic) ?? false;
      if (subscriptionValue && !subscribed) {
        FirebaseMessaging().subscribeToTopic(topic);
      } else if (!subscriptionValue && subscribed) {
        FirebaseMessaging().unsubscribeFromTopic(topic);
      }
    }
  }

  void _processGroupsSubscriptions({Set<String?>? subscribedTopics}) {
    bool? groupSettingsAvailable  = notifyGroupUpdates;
    if (groupSettingsAvailable  != null) {
      for (String key in _groupNotificationsKeyList) {
        String topic = "$_groupUpdatesNotificationKey.$key";
        bool subscribed = subscribedTopics?.contains(topic) ?? false;
        bool value = true;
        try{value = _getNotifySetting(topic) ?? false;} catch (e){print(e);}
        if ((!groupSettingsAvailable || !value) && subscribed){
          FirebaseMessaging().unsubscribeFromTopic(topic);
        }
        if(groupSettingsAvailable && value  && !subscribed){
          FirebaseMessaging().subscribeToTopic(topic);
        }
      }
    }
  }

  bool? _getStoredSetting(String name){
    bool defaultValue = _defaultNotificationSettings[name] ?? true; //true by default
    if(name == _pauseNotificationKey){ // settings depending on userInfo
      if(Auth2().isLoggedIn && Inbox().userInfo != null){
        return Inbox().userInfo?.notificationsDisabled ?? false; //This is the only setting stored in the userInfo
      }
    }
    if(Auth2().isLoggedIn){ // Logged user choice stored in the UserPrefs
      return  Auth2().prefs?.getBoolSetting(_notifySettingNames[name] ?? name, defaultValue: defaultValue);
    }
    return Storage().getNotifySetting(_notifySettingNames[name] ?? name) ?? defaultValue;
  }

  void _storeSetting(String name, bool? value) {
    //// Logged user choice stored in the UserPrefs
    if (Auth2().isLoggedIn) {
      Auth2().prefs?.applySetting(_notifySettingNames[name] ?? name, value);
    } else {
      Storage().setNotifySetting(_notifySettingNames[name] ?? name, value);
    }
  }

  static Map<String, dynamic>? get storedSettings {
    Map<String, dynamic>? result;
    _notifySettingNames.forEach((String storageKey, String profileKey) {
      bool? value = Storage().getNotifySetting(storageKey) ?? Storage().getNotifySetting(profileKey);
      if (value != null) {
        if (result != null) {
          result![profileKey] = value;
        }
        else {
          result = { profileKey : value };
        }
      }
    });
    return result;
  }

  Set<String?>? get currentTopics{
    Set<String?>? subscribedTopics = Storage().inboxFirebaseMessagingSubscriptionTopics;
    if(Auth2().isLoggedIn){
      subscribedTopics = (Inbox().userInfo)?.topics;
    }

    return subscribedTopics;
  }
}
