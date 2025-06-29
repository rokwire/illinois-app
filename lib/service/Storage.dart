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

import 'package:flutter/foundation.dart';
import 'package:illinois/model/Assistant.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/storage.dart' as rokwire;
import 'package:rokwire_plugin/utils/utils.dart';

class Storage extends rokwire.Storage with NotificationsListener {

  static String get notifySettingChanged => rokwire.Storage.notifySettingChanged;
  static String get notifyHomeFavoriteExpandedChanged => 'edu.illinois.rokwire.storage.home.favorite.expanded.changed';

  late Map<String, bool> _homeFavoriteExpandedStates;

  // Singletone Factory

  @protected
  Storage.internal() : super.internal();

  factory Storage() => ((rokwire.Storage.instance is Storage) ? (rokwire.Storage.instance as Storage) : (rokwire.Storage.instance = Storage.internal()));

  // Service Overrides

  void createService() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoriteChanged
    ]);
    super.createService();
  }

  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Future<void> initService() async {
    await super.initService();
    _homeFavoriteExpandedStates = _loadHomeFavoriteExpandedStates() ?? <String, bool>{};
  }

  // NotificationsListener Overrides

  @override
  void onNotification(String name, param) {
    if ((name == Auth2UserPrefs.notifyFavoriteChanged) && (param is HomeFavorite)) {
      _handleFavoriteChanged(param);
    }
    super.onNotification(name, param);
  }

  // Overrides

  @override String get configEnvKey => 'config_environment';
  @override String get reportedUpgradeVersionsKey  => 'reported_upgrade_versions';

  // User: readonly, backward compatability only.

  static const String _userKey  = 'user';

  Map<String, dynamic>? get userProfile {
    return JsonUtils.decodeMap(getStringWithName(_userKey));
  }

  // Dining: readonly, backward compatability only.

  static const String excludedFoodIngredientsPrefsKey  = 'excluded_food_ingredients_prefs';

  Set<String>? get excludedFoodIngredientsPrefs {
    List<String>? list = getStringListWithName(excludedFoodIngredientsPrefsKey);
    return (list != null) ? Set.from(list) : null;
  }

  static const String includedFoodTypesPrefsKey  = 'included_food_types_prefs';

  Set<String>? get includedFoodTypesPrefs {
    List<String>? list = getStringListWithName(includedFoodTypesPrefsKey);
    return (list != null) ? Set.from(list) : null;
  }

  // Notifications

  bool? getNotifySetting(String name) {
    return getBoolWithName(name);
  }

  void setNotifySetting(String name, bool? value) {
    return setBoolWithName(name, value);
  }

  // Polls
  static const String selectedPollTypeKey  = 'selected_poll_type';
  int? get selectedPollType => getIntWithName(selectedPollTypeKey);
  set selectedPollType(int? value) => setIntWithName(selectedPollTypeKey, value);

  // On Boarding
  static const String onBoardingPassedKey  = 'on_boarding_passed';
  bool? get onBoardingPassed => getBoolWithName(onBoardingPassedKey, defaultValue: false);
  set onBoardingPassed(bool? showOnBoarding) => setBoolWithName(onBoardingPassedKey, showOnBoarding);

  // On Boarding2
  static const String onBoarding2PrivacyReturningUserKey  = 'onBoarding2PrivacyReturningUser';
  bool? get onBoarding2PrivacyReturningUser => getBoolWithName(onBoarding2PrivacyReturningUserKey, defaultValue: false);
  set onBoarding2PrivacyReturningUser(bool? value) => setBoolWithName(onBoarding2PrivacyReturningUserKey, value);

  static const String onBoarding2PrivacyLocationServicesSelectionKey  = 'onBoarding2PrivacyLocationServicesSelection';
  bool? get onBoarding2PrivacyLocationServicesSelection => getBoolWithName(onBoarding2PrivacyLocationServicesSelectionKey, defaultValue: true);
  set onBoarding2PrivacyLocationServicesSelection(bool? value) => setBoolWithName(onBoarding2PrivacyLocationServicesSelectionKey, value);

  static const String onBoarding2PrivacyStoreActivitySelectionKey  = 'onBoarding2PrivacyStoreActivitySelection';
  bool? get onBoarding2PrivacyStoreActivitySelection => getBoolWithName(onBoarding2PrivacyStoreActivitySelectionKey, defaultValue: true);
  set onBoarding2PrivacyStoreActivitySelection(bool? value) => setBoolWithName(onBoarding2PrivacyStoreActivitySelectionKey, value);

  static const String onBoarding2PrivacyShareActivitySelectionKey  = 'onBoarding2PrivacyShareActivitySelection';
  bool? get onBoarding2PrivacyShareActivitySelection => getBoolWithName(onBoarding2PrivacyShareActivitySelectionKey, defaultValue: true);
  set onBoarding2PrivacyShareActivitySelection(bool? value) => setBoolWithName(onBoarding2PrivacyShareActivitySelectionKey, value);

  static const String onBoarding2ShowTutorialKey  = 'onBoarding2ShowTutorial';
  bool? get onBoarding2ShowTutorial => getBoolWithName(onBoarding2ShowTutorialKey, defaultValue: false);
  set onBoarding2ShowTutorial(bool? value) => setBoolWithName(onBoarding2ShowTutorialKey, value);

  // Privacy Update Version
  static const String privacyUpdateVersionKey  = 'privacy_update_version';
  String? get privacyUpdateVersion => getStringWithName(privacyUpdateVersionKey);
  set privacyUpdateVersion(String? value) => setStringWithName(privacyUpdateVersionKey, value);

  // Last Run Version
  static const String lastRunVersionKey  = 'last_run_version';
  String? get lastRunVersion => getStringWithName(lastRunVersionKey);
  set lastRunVersion(String? value) => setStringWithName(lastRunVersionKey, value);

  // IlliniCash
  static const String illiniCashEligibilityKey  = '_illinicash_ballance';
  String? get illiniCashEligibility => getEncryptedStringWithName(illiniCashEligibilityKey);
  set illiniCashEligibility(String? value) =>  setEncryptedStringWithName(illiniCashEligibilityKey, value);

  static const String illiniCashBallanceKey  = '_illinicash_ballance';
  String? get illiniCashBallance => getEncryptedStringWithName(illiniCashBallanceKey);
  set illiniCashBallance(String? value) =>  setEncryptedStringWithName(illiniCashBallanceKey, value);

  static const String illiniStudentClassificationKey  = '_illini_student_classification';
  String? get illiniStudentClassification => getEncryptedStringWithName(illiniStudentClassificationKey);
  set illiniStudentClassification(String? value) =>  setEncryptedStringWithName(illiniStudentClassificationKey, value);

  // Date offset
  static const String offsetDateKey  = 'settings_offset_date';

  DateTime? get offsetDate {
    String? dateString = getStringWithName(offsetDateKey);
    return StringUtils.isNotEmpty(dateString) ? DateTimeUtils.dateTimeFromString(dateString) : null;
  }

  set offsetDate(DateTime? value) {
    setStringWithName(offsetDateKey, AppDateTime().formatDateTime(value, ignoreTimeZone: true));
  }

  // Recent Items - backward compatability
  static const String recentItemsKey  = '_recent_items_json_string';
  String? get recentItemsSource => getStringWithName(recentItemsKey);
  List<dynamic>? get recentItems => JsonUtils.decodeList(recentItemsSource);
//set recentItems(List<dynamic>? recentItems) => setStringWithName(recentItemsKey, JsonUtils.encode(recentItems));

  String get recentItemsEnabledKey => 'edu.illinois.rokwire.recent_items.enabled';
  bool? get recentItemsEnabled => getBoolWithName(recentItemsEnabledKey);
  set recentItemsEnabled(bool? value) => setBoolWithName(recentItemsEnabledKey, value);

  // Local Date/Time
  static const String useDeviceLocalTimeZoneKey  = 'use_device_local_time_zone';
  bool? get useDeviceLocalTimeZone => getBoolWithName(useDeviceLocalTimeZoneKey, defaultValue: true);
  set useDeviceLocalTimeZone(bool? value) => setBoolWithName(useDeviceLocalTimeZoneKey, value);

  // Debug
  @override String get debugGeoFenceRegionRadiusKey  => 'debug_geo_fence_region_radius';

  static const String debugMapThresholdDistanceKey  = 'debug_map_threshold_distance';
  int? get debugMapThresholdDistance => getIntWithName(debugMapThresholdDistanceKey, defaultValue: null);
  set debugMapThresholdDistance(int? value) => setIntWithName(debugMapThresholdDistanceKey, value);

  static const String debugDisableLiveGameCheckKey  = 'debug_disable_live_game_check';
  bool? get debugDisableLiveGameCheck => getBoolWithName(debugDisableLiveGameCheckKey, defaultValue: false);
  set debugDisableLiveGameCheck(bool? value) => setBoolWithName(debugDisableLiveGameCheckKey, value);

  static const String debugMapLocationProviderKey  = 'debug_map_location_provider';
  bool? get debugMapLocationProvider => getBoolWithName(debugMapLocationProviderKey, defaultValue: false);
  set debugMapLocationProvider(bool? value) => setBoolWithName(debugMapLocationProviderKey, value);

  static const String debugMapShowLevelsKey  = 'debug_map_show_levels';
  bool? get debugMapShowLevels => getBoolWithName(debugMapShowLevelsKey, defaultValue: false);
  set debugMapShowLevels(bool? value) => setBoolWithName(debugMapShowLevelsKey, value);

  static const String debugLastInboxMessageKey  = 'debug_last_inbox_message';
  String? get debugLastInboxMessage => getStringWithName(debugLastInboxMessageKey);
  set debugLastInboxMessage(String? value) => setStringWithName(debugLastInboxMessageKey, value);

  static const String debugUseStudentCoursesContentKey  = 'debug_use_student_courses_content';
  bool? get debugUseStudentCoursesContent => getBoolWithName(debugUseStudentCoursesContentKey);
  set debugUseStudentCoursesContent(bool? value) => setBoolWithName(debugUseStudentCoursesContentKey, value);

  static const String debugUseCanvasLmsKey  = 'debug_use_canvas_lms';
  bool? get debugUseCanvasLms => getBoolWithName(debugUseCanvasLmsKey);
  set debugUseCanvasLms(bool? value) => setBoolWithName(debugUseCanvasLmsKey, value);

  static const String debugUseSampleAppointmentsKey  = 'debug_use_sample_appontments';
  bool? get debugUseSampleAppointments => getBoolWithName(debugUseSampleAppointmentsKey);
  set debugUseSampleAppointments(bool? value) => setBoolWithName(debugUseSampleAppointmentsKey, value);

  static const String debugUseIdentityBbKey  = 'debug_mobile_icard_use_identity_bb';
  bool? get debugUseIdentityBb => getBoolWithName(debugUseIdentityBbKey, defaultValue: true);
  set debugUseIdentityBb(bool? value) => setBoolWithName(debugUseIdentityBbKey, value);

  static const String debugAutomaticCredentialsKey  = 'debug_mobile_icard_automatic_credentials';
  bool? get debugAutomaticCredentials => getBoolWithName(debugAutomaticCredentialsKey);
  set debugAutomaticCredentials(bool? value) => setBoolWithName(debugAutomaticCredentialsKey, value);

  static const String debugAssistantLocationKey  = 'debug_assistant_location';
  AssistantLocation? get debugAssistantLocation => AssistantLocation.fromJson(JsonUtils.decodeMap(getStringWithName(debugAssistantLocationKey)));
  set debugAssistantLocation(AssistantLocation? location) => setStringWithName(debugAssistantLocationKey, JsonUtils.encode(location?.toJson()));

  static const String debugMessagesDisabledKey  = 'debugMessagesDisabled';
  bool? get debugMessagesDisabled => getBoolWithName(debugMessagesDisabledKey);
  set debugMessagesDisabled(bool? value) => setBoolWithName(debugMessagesDisabledKey, value);

  static const String debugUseIlliniCashTestUrlKey  = 'debugUseIlliniCashTestUrl';
  bool? get debugUseIlliniCashTestUrl => getBoolWithName(debugUseIlliniCashTestUrlKey);
  set debugUseIlliniCashTestUrl(bool? value) => setBoolWithName(debugUseIlliniCashTestUrlKey, value);

  // Firebase
// static const String firebaseMessagingSubscriptionTopisKey  = 'firebase_subscription_topis';
// Replacing "firebase_subscription_topis" with "firebase_messaging_subscription_topis" key ensures that
// all subsciptions will be applied again through Notifications BB APIs
  @override String get inboxFirebaseMessagingSubscriptionTopicsKey => 'firebase_messaging_subscription_topis';

  @override String get inboxFirebaseMessagingTokenKey => 'inbox_firebase_messaging_token';
  @override String get inboxFirebaseMessagingUserIdKey => 'inbox_firebase_messaging_user_id';
  @override String get inboxUserInfoKey => 'inbox_user_info';

  // Polls
  @override String get activePollsKey  => 'active_polls';

  // Voter
  static const String _voterHiddenForPeriodKey = 'voter_hidden_for_period';
  bool? get voterHiddenForPeriod => getBoolWithName(_voterHiddenForPeriodKey, defaultValue: false);
  set voterHiddenForPeriod(bool? value) => setBoolWithName(_voterHiddenForPeriodKey, value);

  // Http Proxy
  @override String get httpProxyEnabledKey => 'http_proxy_enabled';
  @override String get httpProxyHostKey => 'http_proxy_host';
  @override String get httpProxyPortKey => 'http_proxy_port';
  
  // Guide
  static const String _guideContentSourceKey = 'guide_content_source';
  String? get guideContentSource => getStringWithName(_guideContentSourceKey);
  set guideContentSource(String? value) => setStringWithName(_guideContentSourceKey, value);

  //////////////////
  // Auth2

  @override String get auth2AnonymousIdKey => 'auth2AnonymousId';
  @override String get auth2AnonymousTokenKey => 'auth2AnonymousToken';
  @override String get auth2AnonymousPrefsKey => 'auth2AnonymousPrefs';
  @override String get auth2AnonymousProfileKey => 'auth2AnonymousProfile';
  @override String get auth2TokenKey => 'auth2Token';
  @override String get auth2AccountKey => 'auth2Account';
  
  String get auth2UiucTokenKey => 'auth2UiucToken';
  Auth2Token? get auth2UiucToken => Auth2Token.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(auth2UiucTokenKey)));
  set auth2UiucToken(Auth2Token? value) => setEncryptedStringWithName(auth2UiucTokenKey, JsonUtils.encode(value?.toJson()));

  String get auth2CardTimeKey => 'auth2CardTime';
  int? get auth2CardTime => getIntWithName(auth2CardTimeKey);
  set auth2CardTime(int? value) => setIntWithName(auth2CardTimeKey, value);

  // Calendar
  String get calendarShouldPromptKey => 'calendar_enabled_to_prompt';
  bool get calendarShouldPrompt => getBoolWithName(calendarShouldPromptKey, defaultValue: true) ?? true;
  set calendarShouldPrompt(bool value) => setBoolWithName(calendarShouldPromptKey, value);

  // Checklist
  static const String _navPagesKey  = 'checklist_nav_pages';
  List<String>? getCheckListNavPages(String contentKey) => getStringListWithName("${contentKey}_$_navPagesKey");
  setCheckListNavPages(String contentKey, List<String>? value) => setStringListWithName("${contentKey}_$_navPagesKey", value);

  static const String _checkListCompletedPagesKey  = 'checklist_completed_pages';
  
  Set<String>? getChecklistCompletedPages(String contentKey) {
    List<String>? pagesList = getStringListWithName("${contentKey}_$_checkListCompletedPagesKey");
    return (pagesList != null) ? Set.from(pagesList) : null;
  }

  setChecklistCompletedPages(String contentKey, Set<String>? value) {
    List<String>? pagesList = (value != null) ? List.from(value) : null;
    setStringListWithName("${contentKey}_$_checkListCompletedPagesKey", pagesList);
  }

  static const String _giesNotesKey = 'checklist_notes';
  String? getChecklistNotes(String contentKey) => getStringWithName("${contentKey}_$_giesNotesKey");
  setChecklistNotes(String contentKey, String? value) => setStringWithName("${contentKey}_$_giesNotesKey", value);

  //Groups
  static const String _groupMemberSelectionTableKey = 'group_members_selection';

  Map<String, List<List<Member>>>? get groupMembersSelection {
    Map<String, List<List<Member>>> result = Map();
    Map<String, dynamic>? table = JsonUtils.decodeMap(getStringWithName(_groupMemberSelectionTableKey));
    // try { return table?.cast<String, List<List<Member>>>(); }
    // catch(e) { debugPrint(e.toString()); return null; }
    if(table != null){
      table.forEach((key, selections) {
        List<List<Member>> groupSelections = <List<Member>>[];
        if(selections is List && CollectionUtils.isNotEmpty(selections)){
          selections.forEach((selection) {
            List<Member>? groupSelection;
            if(CollectionUtils.isNotEmpty(selection)){
              groupSelection = Member.listFromJson(selection);
            }
            if(groupSelection != null) {
              groupSelections.add(groupSelection);
              result[key] = groupSelections;
            }
          });
        }
      });
    // if(table != null){
    //   table.forEach((key, value) {
    //     List<List<Member>> groupSelections = <List<Member>>[];
    //     List<dynamic>? selections = JsonUtils.decodeList(value);
    //     if(CollectionUtils.isNotEmpty(selections)){
    //       selections!.forEach((element) {
    //         List<Member>? groupSelection;
    //         List<dynamic>? selection = JsonUtils.decodeList(value);
    //         if(CollectionUtils.isNotEmpty(selection)){
    //           groupSelection = Member.listFromJson(selection);
    //         }
    //
    //         if(groupSelection != null) {
    //           groupSelections.add(groupSelection);
    //         }
    //       });
    //     }
    //   });
    }

    return result;
  }

  set groupMembersSelection(Map<String, List<List<Member>>>? selection) {
    setStringWithName(_groupMemberSelectionTableKey, JsonUtils.encode(selection));
  }


  // On Campus
  String get onCampusRegionIdKey => 'edu.illinois.rokwire.on_campus.region_id';
  String? get onCampusRegionId => getStringWithName(onCampusRegionIdKey);
  set onCampusRegionId(String? value) => setStringWithName(onCampusRegionIdKey, value);

  String get onCampusRegionMonitorEnabledKey => 'edu.illinois.rokwire.on_campus.region_monitor.enabled';
  bool? get onCampusRegionMonitorEnabled => getBoolWithName(onCampusRegionMonitorEnabledKey);
  set onCampusRegionMonitorEnabled(bool? value) => setBoolWithName(onCampusRegionMonitorEnabledKey, value);

  String get onCampusRegionManualInsideKey => 'edu.illinois.rokwire.on_campus.region_manual.inside';
  bool? get onCampusRegionManualInside => getBoolWithName(onCampusRegionManualInsideKey);
  set onCampusRegionManualInside(bool? value) => setBoolWithName(onCampusRegionManualInsideKey, value);

  // Home Tout
  String get homeToutImageUrlKey => 'edu.illinois.rokwire.home.tout.image.url';
  String? get homeToutImageUrl => getStringWithName(homeToutImageUrlKey);
  set homeToutImageUrl(String? value) => setStringWithName(homeToutImageUrlKey, value);

  String get homeToutImageTimeKey => 'edu.illinois.rokwire.home.tout.image.time';
  int? get homeToutImageTime => getIntWithName(homeToutImageTimeKey);
  set homeToutImageTime(int? value) => setIntWithName(homeToutImageTimeKey, value);

  // Home

  String get homeWelcomeMessageVisibleKey => 'edu.illinois.rokwire.home.welcome_message.visible';
  bool? get homeWelcomeMessageVisible => getBoolWithName(homeWelcomeMessageVisibleKey);
  set homeWelcomeMessageVisible(bool? value) => setBoolWithName(homeWelcomeMessageVisibleKey, value);

  String get homeLoginVisibleKey => 'edu.illinois.rokwire.home.login.visible';
  bool? get homeLoginVisible => getBoolWithName(homeLoginVisibleKey);
  set homeLoginVisible(bool? value) => setBoolWithName(homeLoginVisibleKey, value);

  String get homeContentTypeKey => 'edu.illinois.rokwire.home.content_type';
  String? get homeContentType => getStringWithName(homeContentTypeKey);
  set homeContentType(String? value) => setStringWithName(homeContentTypeKey, value);

  String get _homeFavoriteExpandedStatesMapKey => 'edu.illinois.rokwire.home.favorite.expanded.state';
  Map<String, bool>? _loadHomeFavoriteExpandedStates() => JsonUtils.mapCastValue(JsonUtils.decode(getStringWithName(_homeFavoriteExpandedStatesMapKey)));
  void _saveHomeFavoriteExpandedStatesMap(Map<String, bool>? value) => setStringWithName(_homeFavoriteExpandedStatesMapKey, JsonUtils.encode(value));

  void _handleFavoriteChanged(HomeFavorite favorite) {
    if (Auth2().isFavorite(favorite) != true) {
      setHomeFavoriteExpanded(favorite.favoriteId, null);
    }
  }

  bool? isHomeFavoriteExpanded(String? key) => _homeFavoriteExpandedStates[key];
  void setHomeFavoriteExpanded(String? key, bool? value) {
    if ((key != null) && (value != isHomeFavoriteExpanded(key))) {
      if (value != null) {
        _homeFavoriteExpandedStates[key] = value;
      }
      else {
        _homeFavoriteExpandedStates.remove(key);
      }
      _saveHomeFavoriteExpandedStatesMap(_homeFavoriteExpandedStates);
      NotificationService().notify(notifyHomeFavoriteExpandedChanged, key);
    }
  }


  // Browse Tout
  String get browseToutImageUrlKey => 'edu.illinois.rokwire.browse.tout.image.url';
  String? get browseToutImageUrl => getStringWithName(browseToutImageUrlKey);
  set browseToutImageUrl(String? value) => setStringWithName(browseToutImageUrlKey, value);

  String get browseToutImageTimeKey => 'edu.illinois.rokwire.browse.tout.image.time';
  int? get browseToutImageTime => getIntWithName(browseToutImageTimeKey);
  set browseToutImageTime(int? value) => setIntWithName(browseToutImageTimeKey, value);

  // Home Campus Reminders
  String get homeCampusRemindersCategoryKey => 'edu.illinois.rokwire.home.campus_reminders.category';
  String? get homeCampusRemindersCategory => getStringWithName(homeCampusRemindersCategoryKey);
  set homeCampusRemindersCategory(String? value) => setStringWithName(homeCampusRemindersCategoryKey, value);

  String get homeCampusRemindersCategoryTimeKey => 'edu.illinois.rokwire.home.campus_reminders.category.time';
  int? get homeCampusRemindersCategoryTime => getIntWithName(homeCampusRemindersCategoryTimeKey);
  set homeCampusRemindersCategoryTime(int? value) => setIntWithName(homeCampusRemindersCategoryTimeKey, value);

  // Wellness Daily Tips
  String get wellnessDailyTipIdKey => 'edu.illinois.rokwire.wellness.daily_tips.id';
  String? get wellnessDailyTipId => getStringWithName(wellnessDailyTipIdKey);
  set wellnessDailyTipId(String? value) => setStringWithName(wellnessDailyTipIdKey, value);

  String get wellnessDailyTipTimeKey => 'edu.illinois.rokwire.wellness.daily_tips.time';
  int? get wellnessDailyTipTime => getIntWithName(wellnessDailyTipTimeKey);
  set wellnessDailyTipTime(int? value) => setIntWithName(wellnessDailyTipTimeKey, value);

  // App Review
  String? get _appReviewVersion  => Config().appMajorVersion;
  
  String get appReviewSessionsCountKey  => 'edu.illinois.rokwire.$_appReviewVersion.app_review.sessions.count';
  int get appReviewSessionsCount => getIntWithName(appReviewSessionsCountKey, defaultValue: 0)!;
  set appReviewSessionsCount(int? value) => setIntWithName(appReviewSessionsCountKey, value);

  // Courses
  String get selectedCourseTermIdKey => 'edu.illinois.rokwire.courses.selected.term.id';
  String? get selectedCourseTermId => getStringWithName(selectedCourseTermIdKey);
  set selectedCourseTermId(String? value) => setStringWithName(selectedCourseTermIdKey, value);

  // Explore
  String get selectedMapExploreTypeKey => 'edu.illinois.rokwire.explore.map.selected.type';
  String? get selectedMapExploreType => getStringWithName(selectedMapExploreTypeKey);
  set selectedMapExploreType(String? value) => setStringWithName(selectedMapExploreTypeKey, value);

  // Appointments
  String get appointmentsDisplayEnabledKey => 'edu.illinois.rokwire.appointments.display_enabled';
  bool? get appointmentsCanDisplay => getBoolWithName(appointmentsDisplayEnabledKey, defaultValue: true);
  set appointmentsCanDisplay(bool? value) => setBoolWithName(appointmentsDisplayEnabledKey, value);

  String get selectedAppointmentProviderIdKey => 'edu.illinois.rokwire.appointments.selected.provider_id';
  String? get selectedAppointmentProviderId => getStringWithName(selectedAppointmentProviderIdKey);
  set selectedAppointmentProviderId(String? value) => setStringWithName(selectedAppointmentProviderIdKey, value);

  // MTD Map instructions
  String get showMtdStopsMapInstructionsKey => 'edu.illinois.rokwire.explore.map.mtd_stops.show_instructions';
  bool? get showMtdStopsMapInstructions => getBoolWithName(showMtdStopsMapInstructionsKey);
  set showMtdStopsMapsInstructions(bool? value) => setBoolWithName(showMtdStopsMapInstructionsKey, value);

  String get showMyLocationsMapInstructionsKey => 'edu.illinois.rokwire.explore.map.my_locations.show_instructions';
  bool? get showMyLocationsMapInstructions => getBoolWithName(showMyLocationsMapInstructionsKey);
  set showMyLocationsMapInstructions(bool? value) => setBoolWithName(showMyLocationsMapInstructionsKey, value);

  // Participate In Research
  static const String participateInResearchPromptedKey  = 'participate_in_research_prompted';
  bool? get participateInResearchPrompted => getBoolWithName(participateInResearchPromptedKey);
  set participateInResearchPrompted(bool? value) => setBoolWithName(participateInResearchPromptedKey, value);

  // Mobile Access
  static const String mobileAccessBleRssiSensitivityKey = 'mobile_access_ble_rssi_sensitivity';
  String? get mobileAccessBleRssiSensitivity => getStringWithName(mobileAccessBleRssiSensitivityKey);
  set mobileAccessBleRssiSensitivity(String? value) => setStringWithName(mobileAccessBleRssiSensitivityKey, value);

  static const String mobileAccessOpenTypeKey = 'mobile_access_open_type';
  String? get mobileAccessOpenType => getStringWithName(mobileAccessOpenTypeKey);
  set mobileAccessOpenType(String? value) => setStringWithName(mobileAccessOpenTypeKey, value);

  static const String mobileAccessDeleteTimeoutInMillisKey = 'mobile_access_delete_timeout_millis';
  int? get mobileAccessDeleteTimeoutUtcInMillis => getIntWithName(mobileAccessDeleteTimeoutInMillisKey);
  set mobileAccessDeleteTimeoutUtcInMillis(int? value) => setIntWithName(mobileAccessDeleteTimeoutInMillisKey, value);

  // Events2
  static const String events2AttributesKey = 'events2_attributes';
  Map<String, dynamic>? get events2Attributes => JsonUtils.decodeMap(getStringWithName(events2AttributesKey));
  set events2Attributes(Map<String, dynamic>? value) => setStringWithName(events2AttributesKey, JsonUtils.encode(value));

  static const String events2TypesKey = 'events2_types';
  List<String>? get events2Types => getStringListWithName(events2TypesKey);
  set events2Types(List<String>? value) => setStringListWithName(events2TypesKey, value);

  static const String events2TimeKey = 'events2_time';
  String? get events2Time => getStringWithName(events2TimeKey);
  set events2Time(String? value) => setStringWithName(events2TimeKey, value);

  static const String events2CustomStartTimeKey = 'events2_custom_start_time';
  String? get events2CustomStartTime => getStringWithName(events2CustomStartTimeKey);
  set events2CustomStartTime(String? value) => setStringWithName(events2CustomStartTimeKey, value);

  static const String events2CustomEndTimeKey = 'events2_custom_end_time';
  String? get events2CustomEndTime => getStringWithName(events2CustomEndTimeKey);
  set events2CustomEndTime(String? value) => setStringWithName(events2CustomEndTimeKey, value);

  static const String events2SortTypeKey = 'events2_sort_type';
  String? get events2SortType => getStringWithName(events2SortTypeKey);
  set events2SortType(String? value) => setStringWithName(events2SortTypeKey, value);

  // Essential Skills Coach
  static const String essentialSkillsCoachModuleKey = 'essential_skills_coach_module';
  String? get essentialSkillsCoachModule => getStringWithName(essentialSkillsCoachModuleKey);
  set essentialSkillsCoachModule(String? value) => setStringWithName(essentialSkillsCoachModuleKey, value);

  // Wallet
  static const String walletContentTypeKey = 'edu.illinois.rokwire.wallet.content_type';
  String? get walletContentType => getStringWithName(walletContentTypeKey);
  set walletContentType(String? value) => setStringWithName(walletContentTypeKey, value);

  // Wellness
  static const String wellnessContentTypeKey = 'edu.illinois.rokwire.wellness.content_type';
  String? get wellnessContentType => getStringWithName(wellnessContentTypeKey);
  set wellnessContentType(String? value) => setStringWithName(wellnessContentTypeKey, value);

  // Settings
  static const String settingsContentTypeKey = 'edu.illinois.rokwire.settings.content_type';
  String? get settingsContentType => getStringWithName(settingsContentTypeKey);
  set settingsContentType(String? value) => setStringWithName(settingsContentTypeKey, value);

  // Profile
  static const String profileContentTypeKey = 'edu.illinois.rokwire.profile.content_type';
  String? get profileContentType => getStringWithName(profileContentTypeKey);
  set profileContentType(String? value) => setStringWithName(profileContentTypeKey, value);

  // Academics
  static const String academicsContentTypeKey = 'edu.illinois.rokwire.academics.content_type';
  String? get academicsContentType => getStringWithName(academicsContentTypeKey);
  set academicsContentType(String? value) => setStringWithName(academicsContentTypeKey, value);

  // Athletics
  static const String athleticsContentTypeKey = 'edu.illinois.rokwire.athletics.content_type';
  String? get athleticsContentType => getStringWithName(athleticsContentTypeKey);
  set athleticsContentType(String? value) => setStringWithName(athleticsContentTypeKey, value);

  // Assistant
  static const String assistantContentTypeKey = 'edu.illinois.rokwire.assistant.content_type';
  String? get assistantContentType => getStringWithName(assistantContentTypeKey);
  set assistantContentType(String? value) => setStringWithName(assistantContentTypeKey, value);

  static const String _assistantEventsPromptHiddenKey = 'edu.illinois.rokwire.assistant.events.prompt.hidden';
  bool? get assistantEventsPromptHidden => getBoolWithName(_assistantEventsPromptHiddenKey);
  set assistantEventsPromptHidden(bool? value) => setBoolWithName(_assistantEventsPromptHiddenKey, value);
}
