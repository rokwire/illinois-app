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
import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/service/Safety.dart';
import 'package:illinois/service/SkillsSelfEvaluation.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/academics/AcademicsHomePanel.dart';
import 'package:illinois/ui/assistant/AssistantHomePanel.dart';
import 'package:illinois/ui/athletics/AthleticsRosterListPanel.dart';
import 'package:illinois/ui/athletics/AthleticsTeamPanel.dart';
import 'package:illinois/ui/canvas/CanvasCalendarEventDetailPanel.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/explore/ExploreBuildingDetailPanel.dart';
import 'package:illinois/ui/explore/ExplorePlaceDetailPanel.dart';
import 'package:illinois/ui/guide/CampusGuidePanel.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:illinois/ui/explore/ExploreMapPanel.dart';
import 'package:illinois/ui/home/HomeCustomizeFavoritesPanel.dart';
import 'package:illinois/ui/messages/MessagesConversationPanel.dart';
import 'package:illinois/ui/polls/PollDetailPanel.dart';
import 'package:illinois/ui/safety/SafetyHomePanel.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:illinois/ui/notifications/NotificationsHomePanel.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/wallet/WalletHomePanel.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/appointments/AppointmentDetailPanel.dart';
import 'package:illinois/ui/wellness/todo/WellnessToDoItemDetailPanel.dart';
import 'package:illinois/ui/widgets/InAppNotificationToast.dart';
import 'package:illinois/ui/widgets/PopScopeFix.dart';
import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/places.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsArticlePanel.dart';
import 'package:illinois/ui/groups/GroupDetailPanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeFavoritesPanel.dart';
import 'package:illinois/ui/BrowsePanel.dart';
import 'package:illinois/ui/polls/PollBubblePromptPanel.dart';
import 'package:illinois/ui/polls/PollBubbleResultPanel.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/ui/popups/alerts.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widget_builders/actions.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/local_notifications.dart';
import 'package:rokwire_plugin/service/styles.dart';

import 'package:quick_actions/quick_actions.dart';

enum RootTab { Home, Favorites, Browse, Maps, Academics, Wellness, Wallet, Assistant }

class RootPanel extends StatefulWidget {
  static final GlobalKey<_RootPanelState> stateKey = GlobalKey<_RootPanelState>();

  static const String notifyTabChanged    = "edu.illinois.rokwire.root.tab.changed";

  RootPanel() : super(key: stateKey);

  @override
  _RootPanelState createState()  => _RootPanelState();
}

class _RootPanelState extends State<RootPanel> with NotificationsListener, TickerProviderStateMixin {

  List<RootTab>  _tabs = [];
  Map<RootTab, Widget?> _panels = {};

  TabController?  _tabBarController;
  int            _currentTabIndex = 0;

  late QuickActions _quickActions;
  late List<ShortcutItem> _quickActionItems;

  _RootPanelState();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      FirebaseMessaging.notifyForegroundMessage,
      FirebaseMessaging.notifyPopupMessage,
      FirebaseMessaging.notifyEventsNotification,
      FirebaseMessaging.notifyEventDetail,
      FirebaseMessaging.notifyEventSelfCheckIn,
      FirebaseMessaging.notifyEventAttendeeSurveyInvitation,
      FirebaseMessaging.notifyAthleticsGameStarted,
      FirebaseMessaging.notifyAthleticsNewsUpdated,
      FirebaseMessaging.notifyAthleticsTeam,
      FirebaseMessaging.notifyAthleticsTeamRoster,
      FirebaseMessaging.notifyGroupsNotification,
      FirebaseMessaging.notifySocialMessageNotification,
      FirebaseMessaging.notifyGroupPostNotification,
      FirebaseMessaging.notifyGroupPostReactionNotification,
      FirebaseMessaging.notifyHomeNotification,
      FirebaseMessaging.notifyHomeFavoritesNotification,
      FirebaseMessaging.notifyHomeBrowseNotification,
      FirebaseMessaging.notifyFavoritesNotification,
      FirebaseMessaging.notifyBrowseNotification,
      FirebaseMessaging.notifyMapNotification,
      FirebaseMessaging.notifyMapEventsNotification,
      FirebaseMessaging.notifyMapDiningNotification,
      FirebaseMessaging.notifyMapBuildingsNotification,
      FirebaseMessaging.notifyMapStudentCoursesNotification,
      FirebaseMessaging.notifyMapAppointmentsNotification,
      FirebaseMessaging.notifyMapMtdStopsNotification,
      FirebaseMessaging.notifyMapMyLocationsNotification,
      FirebaseMessaging.notifyMapMentalHealthNotification,
      FirebaseMessaging.notifyAcademicsNotification,
      FirebaseMessaging.notifyAcademicsAppointmentsNotification,
      FirebaseMessaging.notifyAcademicsCanvasCoursesNotification,
      FirebaseMessaging.notifyAcademicsGiesCanvasCoursesNotification,
      FirebaseMessaging.notifyAcademicsDueDateCatalogNotification,
      FirebaseMessaging.notifyAcademicsEventsNotification,
      FirebaseMessaging.notifyAcademicsGiesChecklistNotification,
      FirebaseMessaging.notifyAcademicsMedicineCoursesNotification,
      FirebaseMessaging.notifyAcademicsMyIlliniNotification,
      FirebaseMessaging.notifyAcademicsSkillsSelfEvaluationNotification,
      FirebaseMessaging.notifyAcademicsStudentCoursesNotification,
      FirebaseMessaging.notifyAcademicsToDoListNotification,
      FirebaseMessaging.notifyAcademicsUiucChecklistNotification,
      FirebaseMessaging.notifyWellnessNotification,
      FirebaseMessaging.notifyWellnessAppointmentsNotification,
      FirebaseMessaging.notifyWellnessDailyTipsNotification,
      FirebaseMessaging.notifyWellnessHealthScreenerNotification,
      FirebaseMessaging.notifyWellnessMentalHealthNotification,
      FirebaseMessaging.notifyWellnessResourcesNotification,
      FirebaseMessaging.notifyWellnessRingsNotification,
      FirebaseMessaging.notifyWellnessTodoListNotification,
      FirebaseMessaging.notifyWalletNotification,
      FirebaseMessaging.notifyWalletIlliniIdNotification,
      FirebaseMessaging.notifyWalletBusPassNotification,
      FirebaseMessaging.notifyWalletMealPlanNotification,
      FirebaseMessaging.notifyWalletAddIlliniCashNotification,
      FirebaseMessaging.notifyInboxNotification,
      FirebaseMessaging.notifyPollNotification,
      FirebaseMessaging.notifyCanvasAppDeepLinkNotification,
      FirebaseMessaging.notifyAppointmentNotification,
      FirebaseMessaging.notifyWellnessToDoItemNotification,
      FirebaseMessaging.notifyProfileMyNotification,
      FirebaseMessaging.notifyProfileWhoAreYouNotification,
      FirebaseMessaging.notifyProfileLoginNotification,
      FirebaseMessaging.notifySettingsSectionsNotification, //TBD deprecate. Use notifyProfileLoginNotification
      FirebaseMessaging.notifySettingsFoodFiltersNotification,
      FirebaseMessaging.notifySettingsSportsNotification,
      FirebaseMessaging.notifySettingsFavoritesNotification,
      FirebaseMessaging.notifySettingsAssessmentsNotification,
      FirebaseMessaging.notifySettingsCalendarNotification,
      FirebaseMessaging.notifySettingsAppointmentsNotification,
      FirebaseMessaging.notifySettingsMapsNotification,
      FirebaseMessaging.notifySettingsContactsNotification,
      FirebaseMessaging.notifySettingsResearchNotification,
      FirebaseMessaging.notifySettingsPrivacyNotification,
      FirebaseMessaging.notifySettingsNotificationsNotification,
      FirebaseMessaging.notifyGuideArticleDetailNotification,
      LocalNotifications.notifyLocalNotificationTapped,
      Alerts.notifyAlert,
      ActionBuilder.notifyShowPanel,
      Events.notifyEventDetail,
      Events2.notifyLaunchDetail,
      Events2.notifyLaunchQuery,
      Events2.notifySelfCheckIn,
      Sports.notifyGameDetail,
      Groups.notifyGroupDetail,
      Social.notifyMessageDetail,
      Appointments.notifyAppointmentDetail,
      Canvas.notifyCanvasEventDetail,
      SkillsSelfEvaluation.notifyLaunchSkillsSelfEvaluation,
      Gateway.notifyBuildingDetail,
      Safety.notifySafeWalkDetail,
      Places.notifyPlacesDetail,
      Guide.notifyGuide,
      Guide.notifyGuideDetail,
      Guide.notifyGuideList,
      Wellness.notifyCategorySelect,
      Localization.notifyStringsUpdated,
      Styles.notifyChanged,
      FlexUI.notifyChanged,
      Polls.notifyPresentVote,
      Polls.notifyPresentResult,
      uiuc.TabBar.notifySelectionChanged,
      HomePanel.notifySelect,
      HomeFavoritesPanel.notifySelect,
      BrowsePanel.notifySelect,
      ExploreMapPanel.notifySelect,
    ]);

    _tabs = _getTabs();
    _currentTabIndex = _defaultTabIndex ?? _getIndexByRootTab(RootTab.Home) ?? 0;
    _tabBarController = TabController(length: _tabs.length, initialIndex: _currentTabIndex, animationDuration: Duration.zero, vsync: this);
    _updateTabPanels(_tabs);

    _quickActions = const QuickActions();
    _quickActions.initialize(_onQuickAction);
    _quickActions.setShortcutItems(_quickActionItems = _buildQuickActionItems());

    Analytics().logPageWidget(_getTabPanelAtIndex(_currentTabIndex));

    Services().initUI();
    _showPresentPoll();
    _checkDidNotificationLaunch().then((action) {
      action?.call();
    });
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Alerts.notifyAlert) {
      Alerts.handleNotification(context, param);
    }
    else if (name == ActionBuilder.notifyShowPanel) {
      _showPanel(param);
    }
    else if (name == FirebaseMessaging.notifyForegroundMessage){
      _onFirebaseForegroundMessage(param);
    }
    else if (name == FirebaseMessaging.notifyPopupMessage) {
      _onFirebasePopupMessage(param);
    }
    else if (name == FirebaseMessaging.notifyEventsNotification) {
      _onFirebaseEvents(param);
    }
    else if (name == FirebaseMessaging.notifyEventDetail) {
      _onFirebaseEventDetail(param);
    }
    else if (name == FirebaseMessaging.notifyEventSelfCheckIn) {
      _onFirebaseEventSelfCheckIn(param);
    }
    else if (name == FirebaseMessaging.notifyEventAttendeeSurveyInvitation) {
      _onFirebaseEventAttendeeSurveyInvitation(param);
    }
    else if (name == FirebaseMessaging.notifyGameDetail) {
      _onFirebaseGameDetail(param);
    }
    else if(name == FirebaseMessaging.notifyAthleticsGameStarted) {
      _onAthleticsGameDetail(param);
    }
    else if (name == LocalNotifications.notifyLocalNotificationTapped) {
      _onLocalNotification(param);
    }
    else if (name == FirebaseMessaging.notifyGroupsNotification) {
      _onFirebaseGroupsNotification(param);
    }
    else if (name == FirebaseMessaging.notifySocialMessageNotification) {
      _onFirebaseSocialMessageNotification(param);
    }
    else if (name == FirebaseMessaging.notifyGroupPostNotification) {
      _onFirebaseGroupPostNotification(param);
    }
    else if (name == FirebaseMessaging.notifyGroupPostReactionNotification) {
      _onFirebaseGroupPostReactionNotification(param);
    }
    else if (name == FirebaseMessaging.notifyAthleticsNewsUpdated) {
      _onFirebaseAthleticsNewsNotification(param);
    }
    else if (name == FirebaseMessaging.notifyAthleticsTeam) {
      _onFirebaseAthleticsTeamNotification(param);
    }
    else if (name == FirebaseMessaging.notifyAthleticsTeamRoster) {
      _onFirebaseAthleticsTeamRosterNotification(param);
    }
    else if (name == FirebaseMessaging.notifyHomeNotification) {
      _onFirebaseTabNotification(RootTab.Home);
    }
    else if (name == FirebaseMessaging.notifyHomeFavoritesNotification) {
      _onFirebaseTabNotification(RootTab.Favorites);
    }
    else if (name == FirebaseMessaging.notifyHomeBrowseNotification) {
      _onFirebaseTabNotification(RootTab.Browse);
    }
    else if (name == FirebaseMessaging.notifyFavoritesNotification) {
      _onFirebaseTabNotification(RootTab.Favorites);
    }
    else if (name == FirebaseMessaging.notifyBrowseNotification) {
      _onFirebaseTabNotification(RootTab.Browse);
    }
    else if (name == FirebaseMessaging.notifyMapNotification) {
      _onFirebaseTabNotification(RootTab.Maps);
    }
    else if (name == FirebaseMessaging.notifyMapEventsNotification) {
      _onFirebaseMapNotification(ExploreMapType.Events2);
    }
    else if (name == FirebaseMessaging.notifyMapDiningNotification) {
      _onFirebaseMapNotification(ExploreMapType.Dining);
    }
    else if (name == FirebaseMessaging.notifyMapBuildingsNotification) {
      _onFirebaseMapNotification(ExploreMapType.Buildings);
    }
    else if (name == FirebaseMessaging.notifyMapStudentCoursesNotification) {
      _onFirebaseMapNotification(ExploreMapType.StudentCourse);
    }
    else if (name == FirebaseMessaging.notifyMapAppointmentsNotification) {
      _onFirebaseMapNotification(ExploreMapType.Appointments);
    }
    else if (name == FirebaseMessaging.notifyMapMtdStopsNotification) {
      _onFirebaseMapNotification(ExploreMapType.MTDStops);
    }
    else if (name == FirebaseMessaging.notifyMapMyLocationsNotification) {
      _onFirebaseMapNotification(ExploreMapType.MyLocations);
    }
    else if (name == FirebaseMessaging.notifyMapMentalHealthNotification) {
      _onFirebaseMapNotification(ExploreMapType.MentalHealth);
    }
    else if (name == FirebaseMessaging.notifyMapStoriedSitesNotification) {
      _onFirebaseMapNotification(ExploreMapType.StoriedSites);
    }
    else if (name == FirebaseMessaging.notifyAcademicsNotification) {
      _onFirebaseTabNotification(RootTab.Academics);
    }
    else if (name == FirebaseMessaging.notifyAcademicsAppointmentsNotification) {
      _onFirebaseAcademicsNotification(AcademicsContentType.appointments);
    }
    else if (name == FirebaseMessaging.notifyAcademicsCanvasCoursesNotification) {
      _onFirebaseAcademicsNotification(AcademicsContentType.canvas_courses);
    }
    else if (name == FirebaseMessaging.notifyAcademicsGiesCanvasCoursesNotification) {
      _onFirebaseAcademicsNotification(AcademicsContentType.gies_canvas_courses);
    }
    else if (name == FirebaseMessaging.notifyAcademicsDueDateCatalogNotification) {
      _onFirebaseAcademicsNotification(AcademicsContentType.due_date_catalog);
    }
    else if (name == FirebaseMessaging.notifyAcademicsEventsNotification) {
      _onFirebaseAcademicsNotification(AcademicsContentType.events);
    }
    else if (name == FirebaseMessaging.notifyAcademicsGiesChecklistNotification) {
      _onFirebaseAcademicsNotification(AcademicsContentType.gies_checklist);
    }
    else if (name == FirebaseMessaging.notifyAcademicsMedicineCoursesNotification) {
      _onFirebaseAcademicsNotification(AcademicsContentType.medicine_courses);
    }
    else if (name == FirebaseMessaging.notifyAcademicsMyIlliniNotification) {
      _onFirebaseAcademicsNotification(AcademicsContentType.my_illini);
    }
    else if (name == FirebaseMessaging.notifyAcademicsSkillsSelfEvaluationNotification) {
      _onFirebaseAcademicsNotification(AcademicsContentType.skills_self_evaluation);
    }
    else if (name == FirebaseMessaging.notifyAcademicsStudentCoursesNotification) {
      _onFirebaseAcademicsNotification(AcademicsContentType.student_courses);
    }
    else if (name == FirebaseMessaging.notifyAcademicsToDoListNotification) {
      _onFirebaseAcademicsNotification(AcademicsContentType.todo_list);
    }
    else if (name == FirebaseMessaging.notifyAcademicsUiucChecklistNotification) {
      _onFirebaseAcademicsNotification(AcademicsContentType.uiuc_checklist);
    }
    else if (name == FirebaseMessaging.notifyWellnessNotification) {
      _onFirebaseTabNotification(RootTab.Wellness);
    }
    else if (name == FirebaseMessaging.notifyWellnessAppointmentsNotification) {
      _onFirebaseWellnessNotification(WellnessContentType.appointments);
    }
    else if (name == FirebaseMessaging.notifyWellnessDailyTipsNotification) {
      _onFirebaseWellnessNotification(WellnessContentType.dailyTips);
    }
    else if (name == FirebaseMessaging.notifyWellnessHealthScreenerNotification) {
      _onFirebaseWellnessNotification(WellnessContentType.healthScreener);
    }
    else if (name == FirebaseMessaging.notifyWellnessMentalHealthNotification) {
      _onFirebaseWellnessNotification(WellnessContentType.mentalHealth);
    }
    else if (name == FirebaseMessaging.notifyWellnessResourcesNotification) {
      _onFirebaseWellnessNotification(WellnessContentType.resources);
    }
    else if (name == FirebaseMessaging.notifyWellnessRingsNotification) {
      _onFirebaseWellnessNotification(WellnessContentType.rings);
    }
    else if (name == FirebaseMessaging.notifyWellnessTodoListNotification) {
      _onFirebaseWellnessNotification(WellnessContentType.todo);
    }

    else if (name == FirebaseMessaging.notifyWalletNotification) {
      _onFirebaseTabNotification(RootTab.Wallet);
    }
    else if (name == FirebaseMessaging.notifyWalletIlliniIdNotification) {
      _onFirebaseWaletNotification(WalletContentType.illiniId);
    }
    else if (name == FirebaseMessaging.notifyWalletBusPassNotification) {
      _onFirebaseWaletNotification(WalletContentType.busPass);
    }
    else if (name == FirebaseMessaging.notifyWalletMealPlanNotification) {
      _onFirebaseWaletNotification(WalletContentType.mealPlan);
    }
    else if (name == FirebaseMessaging.notifyWalletAddIlliniCashNotification) {
      _onFirebaseWaletNotification(WalletContentType.addIlliniCash);
    }
    else if (name == FirebaseMessaging.notifyInboxNotification) {
      _onFirebaseInboxNotification();
    }
    else if (name == FirebaseMessaging.notifyPollNotification) {
      _onFirebasePollNotification(param);
    }
    else if (name == FirebaseMessaging.notifyCanvasAppDeepLinkNotification) {
      _onFirebaseCanvasAppDeepLinkNotification(param);
    }
    else if (name == FirebaseMessaging.notifyAppointmentNotification) {
      _onFirebaseAppointmentNotification(param);
    }
    else if (name == FirebaseMessaging.notifyWellnessToDoItemNotification) {
      _onFirebaseWellnessToDoItemNotification(param);
    }
    else if (name == FirebaseMessaging.notifyProfileMyNotification) {
      _onFirebaseProfileNotification(profileContent: ProfileContentType.profile);
    }
    else if (name == FirebaseMessaging.notifyProfileWhoAreYouNotification) {
      _onFirebaseProfileNotification(profileContent: ProfileContentType.who_are_you);
    }
    else if (name == FirebaseMessaging.notifyProfileLoginNotification) {
      _onFirebaseProfileNotification(profileContent: ProfileContentType.login);
    }
    else if (name == FirebaseMessaging.notifySettingsSectionsNotification) { //TBD deprecate use notifyProfileLoginNotification instead
      _onFirebaseProfileNotification(profileContent: ProfileContentType.login);
    }
    else if (name == FirebaseMessaging.notifySettingsFoodFiltersNotification) {
      _onFirebaseSettingsNotification(settingsContent: SettingsContentType.food_filters);
    }
    else if (name == FirebaseMessaging.notifySettingsSportsNotification) {
      _onFirebaseSettingsNotification(settingsContent: SettingsContentType.sports);
    }
    else if (name == FirebaseMessaging.notifySettingsFavoritesNotification) {
      _onFirebaseSettingsNotification(settingsContent: SettingsContentType.favorites);
    }
    else if (name == FirebaseMessaging.notifySettingsAssessmentsNotification) {
      _onFirebaseSettingsNotification(settingsContent: SettingsContentType.assessments);
    }
    else if (name == FirebaseMessaging.notifySettingsCalendarNotification) {
      _onFirebaseSettingsNotification(settingsContent: SettingsContentType.calendar);
    }
    else if (name == FirebaseMessaging.notifySettingsAppointmentsNotification) {
      _onFirebaseSettingsNotification(settingsContent: SettingsContentType.appointments);
    }
    else if (name == FirebaseMessaging.notifySettingsMapsNotification) {
      _onFirebaseSettingsNotification(settingsContent: SettingsContentType.maps);
    }
    else if (name == FirebaseMessaging.notifySettingsContactsNotification) {
      _onFirebaseSettingsNotification(settingsContent: SettingsContentType.contact);
    }
    else if (name == FirebaseMessaging.notifySettingsResearchNotification) {
      _onFirebaseSettingsNotification(settingsContent: SettingsContentType.research);
    }
    else if (name == FirebaseMessaging.notifySettingsPrivacyNotification) {
      _onFirebaseSettingsNotification(settingsContent: SettingsContentType.privacy);
    }
    else if (name == FirebaseMessaging.notifySettingsNotificationsNotification) {
      _onFirebaseSettingsNotification(settingsContent: SettingsContentType.notifications);
    }
    else if (name == FirebaseMessaging.notifyGuideArticleDetailNotification) {
      _onFirebaseGuideArticleNotification(param);
    }
    else if (name == Events.notifyEventDetail) {
      _onFirebaseEventDetail(param);
    }
    else if (name == Events2.notifyLaunchDetail) {
      _onFirebaseEventDetail(param);
    }
    else if (name == Events2.notifyLaunchQuery) {
      _onFirebaseEventsQuery(param);
    }
    else if (name == Events2.notifySelfCheckIn) {
      _onFirebaseEventSelfCheckIn(param);
    }
    else if (name == Sports.notifyGameDetail) {
      _onFirebaseGameDetail(param);
    }
    else if (name == Groups.notifyGroupDetail) {
      _onGroupDetail(param);
    }
    else if (name == Social.notifyMessageDetail) {
      _onSocialMessageDetail(param);
    }
    else if (name == Appointments.notifyAppointmentDetail) {
      _onAppointmentDetail(param);
    }
    else if (name == Guide.notifyGuide) {
      _onGuide();
    }
    else if (name == Guide.notifyGuideDetail) {
      _onGuideDetail(param);
    }
    else if (name == Guide.notifyGuideList) {
      _onGuideList(param);
    }
    else if (name == Wellness.notifyCategorySelect) {
      _onWellnessCategorySelect(param);
    }
    else if (name == Canvas.notifyCanvasEventDetail) {
      _onCanvasEventDetail(param);
    }
    else if (name == SkillsSelfEvaluation.notifyLaunchSkillsSelfEvaluation) {
      _onFirebaseAcademicsNotification(AcademicsContentType.skills_self_evaluation);
    }
    else if (name == Gateway.notifyBuildingDetail) {
      _onGatewayBuildingDetail(param);
    }
    else if (name == Safety.notifySafeWalkDetail) {
      _onSafetySafeWalkDetail(param);
    }
    else if (name == Places.notifyPlacesDetail) {
      _onPlaceDetail(param);
    }
    else if (name == Localization.notifyStringsUpdated) {
        setStateIfMounted(() { });
    }
    else if (name == Styles.notifyChanged) {
      setStateIfMounted(() { });
    }
    else if (name == FlexUI.notifyChanged) {
      _updateTabsContent();
      _updateQuickActionItems();
    }
    else if (name == Polls.notifyPresentVote) {
      _presentPollVote(param);
    }
    else if (name == Polls.notifyPresentResult) {
      _presentPollResult(param);
    }
    else if (name == HomePanel.notifySelect) {
      _onSelectHome(param);
    }
    else if (name == HomeFavoritesPanel.notifySelect) {
      _onSelectTab(RootTab.Favorites);
    }
    else if (name == BrowsePanel.notifySelect) {
      _onSelectTab(RootTab.Browse);
    }
    else if (name == ExploreMapPanel.notifySelect) {
      _onSelectMaps(param);
    }
    else if (name == uiuc.TabBar.notifySelectionChanged) {
      _onTabSelectionChanged(param);
    }

  }


  @override
  Widget build(BuildContext context) {
    List<Widget> panels = [];
    for (RootTab? rootTab in _tabs) {
      panels.add(_panels[rootTab] ?? Container());
    }

    return PopScopeFix(onBack: _onBack, child:
      Container(color: Colors.white, child:
        Scaffold(
          body: TabBarView(
            controller: _tabBarController,
            physics: NeverScrollableScrollPhysics(), //disable scrolling
            children: panels,
          ),
          bottomNavigationBar: uiuc.TabBar(tabController: _tabBarController),
          backgroundColor: Styles().colors.background,
        ),
      ),
    );
  }

  // TabBar

  void _selectTab(int tabIndex) {

    RootTab? rootTab = getRootTabByIndex(tabIndex);

    //Treat Assistant tab differently because it is modal bottom sheet
    if (rootTab == RootTab.Assistant) {
      AssistantHomePanel.present(context);
    }
    else if (rootTab == RootTab.Wallet) {
      WalletHomePanel.present(context);
    }
    else if ((0 <= tabIndex) && (tabIndex < _tabs.length) && (tabIndex != _currentTabIndex)) {
      _tabBarController!.animateTo(tabIndex);

      if (getRootTabByIndex(_currentTabIndex) == RootTab.Maps) {
        Analytics().logMapHide();
      }

      if (mounted) {
        setState(() {
          _currentTabIndex = tabIndex;
        });
      }
      else {
        _currentTabIndex = tabIndex;
      }

      Widget? tabPanel = _getTabPanelAtIndex(tabIndex);
      Analytics().logPageWidget(tabPanel);

      if (getRootTabByIndex(_currentTabIndex) == RootTab.Maps) {
        Analytics().logMapShow();
      }

      NotificationService().notify(RootPanel.notifyTabChanged, rootTab);
    }
  }

  RootTab? getRootTabByIndex(int index) {
    return ((0 <= index) && (index < _tabs.length)) ? _tabs[index] : null;
  }

  int? _getIndexByRootTab(RootTab? rootTab) {
    int index = (rootTab != null) ? _tabs.indexOf(rootTab) : -1;
    return (0 <= index) ? index : null;
  }

  Widget? _getTabPanelAtIndex(int index) {
    RootTab? rootTab = getRootTabByIndex(index);
    return (rootTab != null) ? _panels[rootTab] : null;
  }

  Widget? get currentTabPanel {
    return _getTabPanelAtIndex(_currentTabIndex);
  }

  static List<RootTab> _getTabs() {
    List<RootTab> tabs = [];
    List<String>? codes = _getTabbarCodes();
    if (codes != null) {
      for (String code in codes) {
        ListUtils.add(tabs, rootTabFromString(code));
      }
    }
    return tabs;
  }

  static List<String>? _getTabbarCodes() {
    try {
      dynamic tabsList = FlexUI()['tabbar'];
      return (tabsList is List) ? tabsList.cast<String>() : null;
    }
    catch(e) {
      print(e.toString());
    }
    return null;
  }

  static Widget? _createPanelForTab(RootTab? rootTab) {
    if (rootTab == RootTab.Home) {
      return HomePanel();
    }
    else if (rootTab == RootTab.Favorites) {
      return HomeFavoritesPanel();
    }
    else if (rootTab == RootTab.Browse) {
      return BrowsePanel();
    }
    else if (rootTab == RootTab.Maps) {
      return ExploreMapPanel();
    }
    else if (rootTab == RootTab.Academics) {
      return AcademicsHomePanel(rootTabDisplay: true,);
    }
    else if (rootTab == RootTab.Wellness) {
      return WellnessHomePanel(rootTabDisplay: true,);
    }
    else if (rootTab == RootTab.Wallet) {
      return null;
    }
    else if (rootTab == RootTab.Assistant) {
      return null;
    }
    else {
      return null;
    }
  }

  int? get _defaultTabIndex {
    dynamic defaultTabCode = FlexUI()['tabbar.default'];
    return (defaultTabCode is String) ? _getIndexByRootTab(rootTabFromString(defaultTabCode)) : null;
  }

  void _updateTabsContent() {
    List<RootTab> tabs = _getTabs();
    if (!DeepCollectionEquality().equals(_tabs, tabs)) {
      _updateTabPanels(tabs);

      RootTab? currentRootTab = getRootTabByIndex(_currentTabIndex);
      if (mounted) {
        setState(() {
          _tabs = tabs;
          _currentTabIndex = (currentRootTab != null) ? (_getIndexByRootTab(currentRootTab) ?? 0)  : 0;

          // Do not initialize _currentTabIndex as initialIndex because we get empty panel content.
          // Initialize TabController with initialIndex = 0 and then manually animate to desired tab index.
          _tabBarController = TabController(length: _tabs.length, animationDuration: Duration.zero, vsync: this);
        });
        _tabBarController!.animateTo(_currentTabIndex);
      }
      else {
        _tabs = tabs;
        _currentTabIndex = (currentRootTab != null) ? (_getIndexByRootTab(currentRootTab) ?? 0)  : 0;
        _tabBarController = TabController(length: _tabs.length, initialIndex: _currentTabIndex, animationDuration: Duration.zero, vsync: this);
      }
    }
  }

  void _updateTabPanels(List<RootTab> tabs) {
    for (RootTab rootTab in tabs) {
      if (_panels[rootTab] == null) {
        Widget? panel = _createPanelForTab(rootTab);
        _panels[rootTab] = panel;
      }
    }
  }

  void _onTabSelectionChanged(int tabIndex) {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      _selectTab(tabIndex);
    }
  }

  void _onSelectTab(RootTab? tab) {
    if (mounted) {
      int? tabIndex = _getIndexByRootTab(tab);
      if ((tabIndex == null) && (tab == RootTab.Home)) {
        tabIndex = 0;
      }
      if (tabIndex != null) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        _selectTab(tabIndex);
      }
      else if (tab == RootTab.Favorites) {
        _onFirebaseHomeNotification(HomeContentType.favorites);
      }
      else if (tab == RootTab.Browse) {
        _onFirebaseHomeNotification(HomeContentType.browse);
      }
    }
  }

  // Exit Prompt

  void _onBack() {
    if (_currentTabIndex != 0) {
      _selectTab(0);
    }
    else if (Platform.isAndroid) {
      showDialog<bool>(context: context, barrierDismissible: false, builder: _buildExitDialog,).then((bool? result) {
        if ((result == true) && mounted) {
          SystemNavigator.pop();
        }
      });
    }
  }

  Widget _buildExitDialog(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    color: Styles().colors.fillColorPrimary,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          Localization().getStringEx("app.title", "Illinois"),
                          style: Styles().textStyles.getTextStyle("widget.dialog.message.regular"),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(height: 26,),
            Text(
              Localization().getStringEx(
                  "common.message.exit_app", "Are you sure you want to exit?"),
              textAlign: TextAlign.center,
              style: Styles().textStyles.getTextStyle("widget.dialog.message.dark.regular.fat")
            ),
            Container(height: 26,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RoundedButton(
                      onTap: () {
                        Analytics().logAlert(
                            text: "Exit", selection: "Yes");
                        Navigator.of(context).pop(true);
                      },
                      backgroundColor: Colors.transparent,
                      borderColor: Styles().colors.fillColorSecondary,
                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                      label: Localization().getStringEx("dialog.yes.title", 'Yes')),
                  Container(height: 10,),
                  RoundedButton(
                      onTap: () {
                        Analytics().logAlert(
                            text: "Exit", selection: "No");
                        Navigator.of(context).pop(false);
                      },
                      backgroundColor: Colors.transparent,
                      borderColor: Styles().colors.fillColorSecondary,
                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                      label: Localization().getStringEx("dialog.no.title", 'No'))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Quick Actions

  List<ShortcutItem> _buildQuickActionItems() => <ShortcutItem>[
    if (FlexUI().isSafeWalkAvailable)
      ShortcutItem(
        type: Safety.safeWalkRequestAction,
        localizedTitle: Localization().getStringEx('model.safety.safewalks.request.action.text', 'Request a SafeWalk'),
        icon: Platform.isAndroid ? 'paper_plane' : 'paper-plane',
      ),
  ];

  void _updateQuickActionItems() {
    List<ShortcutItem> quickActionItems = _buildQuickActionItems();
    if (!DeepCollectionEquality().equals(_quickActionItems, quickActionItems)) {
      _quickActions.setShortcutItems(_quickActionItems = _buildQuickActionItems());
    }
  }

  void _onQuickAction(String action) {
    if (action == Safety.safeWalkRequestAction) {
      _onSafetySafeWalkDetail(null);
    }
  }

  // Polls

  void _showPresentPoll() {
    Poll? presentingPoll = Polls().presentingPoll;
    if (presentingPoll != null) {
      Timer(Duration(milliseconds: 500), (){
        if (presentingPoll.status == PollStatus.opened) {
          _presentPollVote(presentingPoll.pollId);
        }
        else if (presentingPoll.status == PollStatus.closed) {
          _presentPollResult(presentingPoll.pollId);
        }
      });
    }
  }

  void _presentPollVote(String? pollId) {
    Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => PollBubblePromptPanel(pollId: pollId)));
  }

  void _presentPollResult(String? pollId) {
    Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => PollBubbleResultPanel(pollId: pollId)));
  }

  // ActionBuilder

  Future<Function?> _checkDidNotificationLaunch() async {
    ActionData? notificationResponseAction = await LocalNotifications().getNotificationResponseAction();
    return ActionBuilder.getAction(context, notificationResponseAction, dismissContext: context);
  }

  void _showPanel(Map<String, dynamic> content) {
    switch (content['panel']) {
      case "GuideDetailPanel":
        _onGuideDetail(content);
    }
  }

  // Local Notifications

  void _onLocalNotification(dynamic param) {
    if (param is ActionData) {
      ActionBuilder.getAction(context, param)?.call();
    }
    /*else if (param is NotificationResponse) {
      // TBD
    }*/
  }

  // Firebase Notifications

  void _onFirebaseForegroundMessage(Map<String, dynamic> content) {
    String? body = content["body"];
    void Function()? completion = content["onComplete"];
    if (body != null) {
      FToast toast = FToast();
      AppToast.show(context,
        toast: toast,
        gravity: ToastGravity.TOP,
        duration: Duration(seconds: Config().inAppNotificationToastTimeout),
        child: InAppNotificationToast.message(StringUtils.truncate(value: body, atLength: Config().notificationBodyMaxLength),
          actionText: Localization().getStringEx('dialog.show.title', 'Show'),
          onAction: (completion != null) ? () => _onFirebaseForegroundMessageCompletition(toast, completion) : null,
          onMessage: (completion != null) ? () => _onFirebaseForegroundMessageCompletition(toast, completion) : null,
        )
      );
      /*AppAlert.showDialogResult(context, body, buttonTitle: Localization().getStringEx('dialog.show.title', 'Show')).then((bool? result) {
        if ((result == true) && (completion != null)) {
          completion();
        }
      });*/
    }
  }

  void _onFirebaseForegroundMessageCompletition(FToast toast, void Function() completion) {
    toast.removeCustomToast();
    completion.call();
  }

  void _onFirebasePopupMessage(Map<String, dynamic> content) {
    PopupMessage.show(context: context,
      title: Localization().getStringEx("app.title", "Illinois"),
      message: JsonUtils.stringValue(content["display_text"]),
      buttonTitle: JsonUtils.stringValue(content["positive_button_text"]) ?? Localization().getStringEx("dialog.ok.title", "OK")
    );
  }

  Future<void> _onFirebaseEvents(Map<String, dynamic>? content) async {
    Map<String, dynamic>? attributes = (content != null) ? JsonUtils.mapValue(JsonUtils.decode(JsonUtils.stringValue(content['attributes']))) : null;
    List<String>? types = (content != null) ? JsonUtils.listStringsValue(content['types']) : null;
    String? time =  (content != null) ? JsonUtils.stringValue(content['time']) : null;

    LinkedHashSet<Event2TypeFilter>? typeFilters = types != null ? LinkedHashSetUtils.from<Event2TypeFilter>(Event2TypeFilterListImpl.listFromJson(types)) : null;
    Event2TimeFilter? timeFilter = time != null ? Event2TimeFilterImpl.fromJson(time) : null;

    if (attributes != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2HomePanel(attributes: attributes, types: typeFilters, timeFilter: timeFilter,)));
    }
  }

  Future<void> _onFirebaseEventDetail(Map<String, dynamic>? content) async {
    String? eventId = (content != null) ? JsonUtils.stringValue(content['event_id']) ?? JsonUtils.stringValue(content['entity_id'])  : null;
    if (StringUtils.isNotEmpty(eventId)) {
      //ExplorePanel.presentDetailPanel(context, eventId: eventId);
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(eventId: eventId,)));
    }
  }

  Future<void> _onFirebaseEventsQuery(Map<String, dynamic>? content) async {
    Event2FilterParam? eventFilterParam = (content != null) ? Event2FilterParam.fromUriParams(content.cast()) : null;
    if (eventFilterParam != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2HomePanel.withFilter(eventFilterParam)));
    }
  }

  Future<void> _onFirebaseEventSelfCheckIn(Map<String, dynamic>? content) async {
    String? eventId = (content != null) ? (JsonUtils.stringValue(content['event_id']) ?? JsonUtils.stringValue(content['entity_id'])) : null;
    if (StringUtils.isNotEmpty(eventId)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(eventId: eventId, onInitialized: (Event2DetailPanelState state) {
        if ((eventId != null) && eventId.isNotEmpty) {
          state.selfCheckIn(eventId, secret: JsonUtils.stringValue(content?['secret']));
        }
      },)));
    }
  }

  void _onFirebaseEventAttendeeSurveyInvitation(Map<String, dynamic>? content) {
    String? eventId = (content != null) ? JsonUtils.stringValue(content['entity_id']) : null;
    if (StringUtils.isNotEmpty(eventId)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(eventId: eventId)));
    }
  }
  
  Future<void> _onFirebaseGameDetail(Map<String, dynamic>? content) async {
    String? gameId = (content != null) ? JsonUtils.stringValue(content['game_id']) : null;
    String? sport = (content != null) ? JsonUtils.stringValue(content['sport']) : null;
    if (StringUtils.isNotEmpty(gameId) && StringUtils.isNotEmpty(sport)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(sportName: sport, gameId: gameId,)));
    }
  }

  void _onFirebaseGroupsNotification(param) {
    if (param is Map<String, dynamic>) {
      String? groupId = JsonUtils.stringValue(param["entity_id"]);
      _presentGroupDetailPanel(groupId: groupId);
    }
  }

  void _onFirebaseGroupPostNotification(param) {
    if (param is Map<String, dynamic>) {
      String? groupId = JsonUtils.stringValue(param["entity_id"]);
      String? groupPostId = JsonUtils.stringValue(param["post_id"]);
      String? commentId = JsonUtils.stringValue(param["comment_id"]);
      _presentGroupDetailPanel(groupId: groupId, groupPostId: groupPostId, commentId: commentId);
    }
  }

  void _onFirebaseGroupPostReactionNotification(param) {
    if (param is Map<String, dynamic>) {
      String? groupId =JsonUtils.stringValue(param["group_id"]);
      String? groupPostId = JsonUtils.stringValue(param["post_id"]);
      String? commentId = JsonUtils.stringValue(param["comment_id"]);
      _presentGroupDetailPanel(groupId: groupId, groupPostId: groupPostId, commentId: commentId);
    }
  }

  void _presentGroupDetailPanel({String? groupId, String? groupPostId, String? commentId}) {
    if (StringUtils.isNotEmpty(groupId)) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: GroupDetailPanel.routeName), builder: (context) => GroupDetailPanel(groupIdentifier: groupId, groupPostId: groupPostId, groupPostCommentId: commentId)));
    } else {
      AppAlert.showDialogResult(context, Localization().getStringEx("panel.group_detail.label.error_message", "Failed to load group data."));
    }
  }

  void _onFirebaseSocialMessageNotification(param) {
    if (param is Map<String, dynamic>) {
      _presentSocialMessagePanel(
        conversationId: JsonUtils.stringValue(param["entity_id"]),
        messageId: JsonUtils.stringValue(param["message_id"]),
        messageGlobalId: JsonUtils.stringValue(param["message_global_id"]),
      );
    }
  }

  void _presentSocialMessagePanel({String? conversationId, String? messageId, String? messageGlobalId}) {
    if (StringUtils.isNotEmpty(conversationId)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => MessagesConversationPanel(
        conversationId: conversationId,
        targetMessageId: messageId,
        targetMessageGlobalId: messageGlobalId,
      )));
    } else {
      AppAlert.showDialogResult(context, Localization().getStringEx("", "Failed to load conversation data."));
    }
  }

  void _onFirebaseAthleticsNewsNotification(param) {
    if (param is Map<String, dynamic>) {
      String? newsId = param["news_id"];
      if (StringUtils.isNotEmpty(newsId)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsNewsArticlePanel(articleId: newsId)));
      }
    }
  }

  void _onFirebaseAthleticsTeamNotification(param) {
    if (param is Map<String, dynamic>) {
      String? sportName = JsonUtils.stringValue(param["sport"]);
      if (StringUtils.isNotEmpty(sportName)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsTeamPanel(Sports().getSportByShortName(sportName))));
      }
    }
  }
  void _onFirebaseAthleticsTeamRosterNotification(param) {
    if (param is Map<String, dynamic>) {
      String? sportName = JsonUtils.stringValue(param["sport"]);
      if (StringUtils.isNotEmpty(sportName)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsRosterListPanel(Sports().getSportByShortName(sportName), null)));
      }
    }
  }

  void _onFirebaseTabNotification(RootTab? tab) =>
    _onSelectTab(tab);

  void _onFirebaseHomeNotification(HomeContentType homeType) {
    NotificationService().notify(HomePanel.notifySelect, homeType);
  }

  void _onFirebaseMapNotification(ExploreMapType mapType) {
    NotificationService().notify(ExploreMapPanel.notifySelect, mapType);
  }

  void _onFirebaseInboxNotification() {
    NotificationsHomePanel.present(context, content: (Inbox().unreadMessagesCount > 0) ? NotificationsContent.unread : NotificationsContent.all);
  }

  void _onFirebasePollNotification(dynamic param) {
    if (param is Map<String, dynamic>) {
      String? pollId = JsonUtils.stringValue(param['entity_id']);
      if (StringUtils.isNotEmpty(pollId)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => PollDetailPanel(pollId: pollId)));
      }
    }
  }

  void _onFirebaseCanvasAppDeepLinkNotification(dynamic param) {
    if (param is Map<String, dynamic>) {
      String? deepLink = JsonUtils.stringValue(param['deep_link']);
      Canvas().openCanvasAppDeepLink(StringUtils.ensureNotEmpty(deepLink));
    }
  }

  void _onFirebaseAppointmentNotification(dynamic param) {
    if (param is Map<String, dynamic>) {
      String? appointmentId = JsonUtils.stringValue(param['appointment_id']);
      if (StringUtils.isNotEmpty(appointmentId)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentDetailPanel(appointmentId: appointmentId)));
      } else {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(contentType: WellnessContentType.appointments)));
      }
    }
  }

  void _onFirebaseWellnessToDoItemNotification(dynamic param) {
    if (param is Map<String, dynamic>) {
      String? todoItemId = JsonUtils.stringValue(param['entity_id']);
      if (StringUtils.isNotEmpty(todoItemId)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessToDoItemDetailPanel(itemId: todoItemId, optionalFieldsExpanded: true)));
      } else {
        _onFirebaseAcademicsNotification(AcademicsContentType.todo_list);
      }
    }
  }

  void _onFirebaseGuideArticleNotification(dynamic param) async {
    _onGuideDetail(param);
  }

  void _onFirebaseProfileNotification({required ProfileContentType profileContent}) {
    ProfileHomePanel.present(context, contentType: profileContent);
  }

  void _onFirebaseSettingsNotification({required SettingsContentType settingsContent}) {
    if (settingsContent == SettingsContentType.favorites) {
      HomeCustomizeFavoritesPanel.present(context).then((_) => NotificationService().notify(HomePanel.notifySelect));
    } else {
      SettingsHomePanel.present(context, content: settingsContent);
    }
  }

  void _onFirebaseWaletNotification(WalletContentType contentType) {
    WalletHomePanel.present(context, contentType: contentType);
  }

  void _onFirebaseAcademicsNotification(AcademicsContentType content) {
    if (AcademicsHomePanel.hasState) {
      NotificationService().notify(AcademicsHomePanel.notifySelectContent, content);
    } else {
      AcademicsHomePanel.push(context, content);
    }
  }

  void _onFirebaseWellnessNotification(WellnessContentType content) {
    if (WellnessHomePanel.hasState) {
      NotificationService().notify(WellnessHomePanel.notifySelectContent, content);
    } else {
      WellnessHomePanel.push(context, content);
    }
  }

  // Service Notifications

  Future<void> _onGroupDetail(Map<String, dynamic>? content) async {
    String? groupId = (content != null) ? JsonUtils.stringValue(content['group_id']) ?? JsonUtils.stringValue(content['entity_id'])  : null;
    _presentGroupDetailPanel(groupId: groupId);
  }

  Future<void> _onSocialMessageDetail(Map<String, dynamic>? content) async {
    if ((content != null)) {
      _presentSocialMessagePanel(
        conversationId: JsonUtils.stringValue(content['conversation_id']) ?? JsonUtils.stringValue(content['entity_id']),
        messageId: JsonUtils.stringValue(content['message_id']),
        messageGlobalId: JsonUtils.stringValue(content['message_global_id']),
      );
    }
  }

  Future<void> _onAppointmentDetail(Map<String, dynamic>? content) async {
    String? appointmentId = (content != null) ? JsonUtils.stringValue(content['appointment_id']) ?? JsonUtils.stringValue(content['entity_id']) : null;
    if (StringUtils.isNotEmpty(appointmentId)) {
      Navigator.of(context).push(CupertinoPageRoute(builder: (context) => AppointmentDetailPanel(appointmentId: appointmentId)));
    }
  }

  Future<void> _onGuide() async {
    WidgetsBinding.instance.addPostFrameCallback((_) { // Fix navigator.dart failed assertion line 5307
      Navigator.of(context).push(CupertinoPageRoute(builder: (context) =>
          CampusGuidePanel()));
    });
    if (mounted) {
      setState(() {}); // Force the postFrameCallback invokation.
    }
  }

  Future<void> _onGuideDetail(Map<String, dynamic>? content) async {
    if (content != null) {
      String? guideId = JsonUtils.stringValue(content['guide_id']) ?? JsonUtils.stringValue(content['entity_id']);
      if (StringUtils.isNotEmpty(guideId)){
        WidgetsBinding.instance.addPostFrameCallback((_) { // Fix navigator.dart failed assertion line 5307
          Navigator.of(context).push(CupertinoPageRoute(builder: (context) =>
            GuideDetailPanel(guideEntryId: guideId, analyticsFeature: AnalyticsFeature.fromName(JsonUtils.stringValue(content['analytics_feature'])),)));
        });
        if (mounted) {
          setState(() {}); // Force the postFrameCallback invokation.
        }
      }
    }
  }

  Future<void> _onGuideList(Map<String, dynamic>? content) async {
    if (content != null) {
      String? guide = JsonUtils.stringValue(content['guide']);
      String? section = JsonUtils.stringValue(content['section']);
      String? category = JsonUtils.stringValue(content['category']);
      if ((guide != null) || (section != null) || (category != null)){
        WidgetsBinding.instance.addPostFrameCallback((_) { // Fix navigator.dart failed assertion line 5307
          Navigator.of(context).push(CupertinoPageRoute(builder: (context) =>
            GuideListPanel(guide: guide, category: category, section: GuideSection(name: section),)));
        });
        if (mounted) {
          setState(() {}); // Force the postFrameCallback invokation.
        }
      }
    }
  }

  Future<void> _onWellnessCategorySelect(Map<String, dynamic>? content) async {
    String? categoryCode = (content != null) ? JsonUtils.stringValue(content['id']) : null;
    WellnessContentType? category = WellnessContentTypeImpl.fromJsonString(categoryCode);
    if (category != null) {
      _onFirebaseWellnessNotification(category);
    }
  }

  Future<void> _onCanvasEventDetail(Map<String, dynamic>? content) async {
    String? eventId = (content != null) ? JsonUtils.stringValue(content['event_id']) ?? JsonUtils.stringValue(content['entity_id'])  : null;
    if (StringUtils.isNotEmpty(eventId)) {
      int? eventIdValue = int.tryParse(eventId!);
      if (eventIdValue != null) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCalendarEventDetailPanel(eventId: eventIdValue)));
      }
    }
  }

  Future<void> _onGatewayBuildingDetail(Map<String, dynamic>? content) async {
    String? buildingNumber = (content != null) ? JsonUtils.stringValue(content['building_number']) : null;
    if (StringUtils.isNotEmpty(buildingNumber)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) =>
        ExploreBuildingDetailPanel(buildingNumber: buildingNumber)
      ));
    }
  }

  Future<void> _onSafetySafeWalkDetail(Map<String, dynamic>? content) async {
    if (FlexUI().isSafeWalkAvailable) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) =>
          SafetyHomePanel(
            contentType: SafetyContentType.safeWalkRequest,
            safeWalkRequestOrigin: (content != null) ? JsonUtils.decodeMap(content['origin']) : null,
            safeWalkRequestDestination: (content != null) ? JsonUtils.decodeMap(content['destination']) : null,
          )
      ));
    }
    else {
      AppAlert.showDialogResult(context, Localization().getStringEx("model.safety.safewalks.not_available.text", "Failed to load group data."));
    }
  }

  Future<void> _onPlaceDetail(Map<String, dynamic>? content) async {
    String? placeId = (content != null) ? JsonUtils.stringValue(content['place_id']) : null;
    if (StringUtils.isNotEmpty(placeId)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) =>
        ExplorePlaceDetailPanel(placeId: placeId)
      ));
    }
  }

  void _onAthleticsGameDetail(Map<String, dynamic>? athleticsGameDetails) {
    if (athleticsGameDetails == null) {
      return;
    }
    String? sportShortName = athleticsGameDetails["Path"];
    String? gameId = athleticsGameDetails["GameId"];
    if (StringUtils.isEmpty(sportShortName) || StringUtils.isEmpty(gameId)) {
      return;
    }
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(sportName: sportShortName, gameId: gameId,)));
  }
  
  void _onSelectHome(dynamic param) {
    int? homeIndex = _getIndexByRootTab(RootTab.Home);
    if (mounted && (homeIndex != null)) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      if (homeIndex != _currentTabIndex) {
        _selectTab(homeIndex);
        if ((param is HomeContentType) && !HomePanel.hasState) {
          Widget? homeWidget = _panels[RootTab.Home];
          HomePanel? homePanel = (homeWidget is HomePanel) ? homeWidget : null;
          homePanel?.initialContentType = param;
        }
      }
    }
  }

  void _onSelectMaps(dynamic param) {
    int? mapsIndex = _getIndexByRootTab(RootTab.Maps);
    if (mounted && (mapsIndex != null)) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      if (mapsIndex != _currentTabIndex) {
        _selectTab(mapsIndex);
        if ((param != null) && !ExploreMapPanel.hasState) {
          Widget? mapsWidget = _panels[RootTab.Maps];
          ExploreMapPanel? mapsPanel = (mapsWidget is ExploreMapPanel) ? mapsWidget : null;
          mapsPanel?.params[ExploreMapPanel.selectParamKey] = param;
        }
      }
    }
  }

}

RootTab? rootTabFromString(String? value) {
  if (value != null) {
    if (value == 'home') {
      return RootTab.Home;
    }
    else if (value == 'favorites') {
      return RootTab.Favorites;
    }
    else if (value == 'browse') {
      return RootTab.Browse;
    }
    else if (value == 'maps') {
      return RootTab.Maps;
    }
    else if (value == 'academics') {
      return RootTab.Academics;
    }
    else if (value == 'wellness') {
      return RootTab.Wellness;
    }
    else if (value == 'wallet') {
      return RootTab.Wallet;
    }
    else if (value == 'assistant') {
      return RootTab.Assistant;
    }
  }
  return null;
}

