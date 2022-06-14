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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/config.dart' as rokwire;
import 'package:rokwire_plugin/utils/utils.dart';

class Config extends rokwire.Config {

  static String get notifyUpgradeRequired     => rokwire.Config.notifyUpgradeRequired;
  static String get notifyUpgradeAvailable    => rokwire.Config.notifyUpgradeAvailable;
  static String get notifyOnboardingRequired  => rokwire.Config.notifyOnboardingRequired;
  static String get notifyConfigChanged       => rokwire.Config.notifyConfigChanged;
  static String get notifyEnvironmentChanged  => rokwire.Config.notifyEnvironmentChanged;

  static const String twitterDefaultAccountKey = '';

  // Singletone Factory

  @protected
  Config.internal() : super.internal();

  factory Config() => ((rokwire.Config.instance is Config) ? (rokwire.Config.instance as Config) : (rokwire.Config.instance = Config.internal()));

  // Getters: compound entries

  Map<String, dynamic> get thirdPartyServices  => JsonUtils.mapValue(content['thirdPartyServices']) ?? {};

  Map<String, dynamic> get secretShibboleth => JsonUtils.mapValue(secretKeys['shibboleth']) ?? {};
  Map<String, dynamic> get secretIlliniCash => JsonUtils.mapValue(secretKeys['illini_cash']) ?? {};
  Map<String, dynamic> get secretParkhub => JsonUtils.mapValue(secretKeys['parkhub']) ?? {};
  Map<String, dynamic> get secretPadaapi => JsonUtils.mapValue(secretKeys['padaapi']) ?? {};
  Map<String, dynamic> get secretTwitter => JsonUtils.mapValue(secretKeys['twitter']) ?? {};
  
  Map<String, dynamic> get twitter => JsonUtils.mapValue(content['twitter']) ?? {};
  Map<String, dynamic> get onboardingInfo => JsonUtils.mapValue(content['onboarding']) ?? {};

  Map<String, dynamic> get safer => JsonUtils.mapValue(content['safer']) ?? {};
  Map<String, dynamic> get saferMcKinley => JsonUtils.mapValue(safer['mckinley']) ?? {};
  Map<String, dynamic> get saferWellness => JsonUtils.mapValue(safer['wellness']) ?? {};

  Map<String, dynamic> get stateFarm => JsonUtils.mapValue(content['state_farm']) ?? {};
  Map<String, dynamic> get stateFarmWayfinding => JsonUtils.mapValue(stateFarm['wayfinding']) ?? {};

  Map<String, dynamic> get canvas => JsonUtils.mapValue(content['canvas']) ?? {};
  Map<String, dynamic> get canvasDeepLink => JsonUtils.mapValue(canvas['deep_link']) ?? {};

  // Getters: Secret Keys

  String? get shibbolethClientId     => JsonUtils.stringValue(secretShibboleth['client_id']);
  String? get shibbolethClientSecret => JsonUtils.stringValue(secretShibboleth['client_secret']);

  String? get illiniCashAppKey       => JsonUtils.stringValue(secretIlliniCash['app_key']);
  String? get illiniCashHmacKey      => JsonUtils.stringValue(secretIlliniCash['hmac_key']);
  String? get illiniCashSecretKey    => JsonUtils.stringValue(secretIlliniCash['secret_key']);

  String? get padaapiApiKey          => JsonUtils.stringValue(secretPadaapi['api_key']);

  String? get twitterToken           => JsonUtils.stringValue(secretTwitter['token']);
  String? get twitterTokenType       => JsonUtils.stringValue(secretTwitter['token_type']);


  // Getters: Other University Services
  String? get shibbolethAuthTokenUrl => JsonUtils.stringValue(otherUniversityServices['shibboleth_auth_token_url']);
  String? get shibbolethOauthHostUrl => JsonUtils.stringValue(otherUniversityServices['shibboleth_oauth_host_url']);
  String? get shibbolethOauthPathUrl => JsonUtils.stringValue(otherUniversityServices['shibboleth_oauth_path_url']);
  String? get userAuthUrl            => JsonUtils.stringValue(otherUniversityServices['user_auth_url']);
  String? get assetsUrl              => JsonUtils.stringValue(otherUniversityServices['assets_url']);
  String? get eatSmartUrl            => JsonUtils.stringValue(otherUniversityServices['eat_smart_url']);
  String? get iCardUrl               => JsonUtils.stringValue(otherUniversityServices['icard_url']);
  String? get iCardBoardingPassUrl   => JsonUtils.stringValue(otherUniversityServices['icard_boarding_pass_url']);
  String? get illiniCashBaseUrl      => JsonUtils.stringValue(otherUniversityServices['illini_cash_base_url']);
  String? get illiniCashTrustcommerceHost => JsonUtils.stringValue(otherUniversityServices['illini_cash_trustcommerce_host']);
  String? get illiniCashTokenHost    => JsonUtils.stringValue(otherUniversityServices['illini_cash_token_host']);
  String? get illiniCashPaymentHost  => JsonUtils.stringValue(otherUniversityServices['illini_cash_payment_host']);
  String? get illiniCashTosUrl       => JsonUtils.stringValue(otherUniversityServices['illini_cash_tos_url']);
  String? get myIlliniUrl            => JsonUtils.stringValue(otherUniversityServices['myillini_url']);
  String? get feedbackUrl            => JsonUtils.stringValue(otherUniversityServices['feedback_url']);
  String? get crisisHelpUrl          => JsonUtils.stringValue(otherUniversityServices['crisis_help_url']);
  String? get privacyPolicyUrl       => JsonUtils.stringValue(otherUniversityServices['privacy_policy_url']);
  String? get padaapiUrl             => JsonUtils.stringValue(otherUniversityServices['padaapi_url']);
  String? get canvasZoomMeetingUrl   => JsonUtils.stringValue(otherUniversityServices['canvas_zoom_meeting_url']);
  String? get dateCatalogUrl         => JsonUtils.stringValue(otherUniversityServices['date_catalog_url']);
  String? get faqsUrl                => JsonUtils.stringValue(otherUniversityServices['faqs_url']);
  String? get videoTutorialUrl       => JsonUtils.stringValue(otherUniversityServices['video_tutorial_url']);
  String? get videoTutorialCcUrl     => JsonUtils.stringValue(otherUniversityServices['video_tutorial_cc_url']);
  String? get wpgufmRadioUrl         => JsonUtils.stringValue(otherUniversityServices['wpgufm_radio_url']);

  // Getters: Platform Building Blocks
  String? get gatewayUrl             => JsonUtils.stringValue(platformBuildingBlocks['gateway_url']);
  String? get lmsUrl                 => JsonUtils.stringValue(platformBuildingBlocks['lms_url']);
  String? get rewardsUrl             => JsonUtils.stringValue(platformBuildingBlocks['rewards_url']);
  String? get rokwireAuthUrl         => JsonUtils.stringValue(platformBuildingBlocks['rokwire_auth_url']);
  String? get sportsServiceUrl       => JsonUtils.stringValue(platformBuildingBlocks['sports_service_url']);
  String? get transportationUrl      => JsonUtils.stringValue(platformBuildingBlocks["transportation_url"]);
  
  // Getters: Third Party Services
  String? get instagramHostUrl       => JsonUtils.stringValue(thirdPartyServices['instagram_host_url']);
  String? get twitterHostUrl         => JsonUtils.stringValue(thirdPartyServices['twitter_host_url']);
  String? get ticketsUrl             => JsonUtils.stringValue(thirdPartyServices['tickets_url']);
  String? get youtubeUrl             => JsonUtils.stringValue(thirdPartyServices['youtube_url']);
  String? get gameDayFootballUrl     => JsonUtils.stringValue(thirdPartyServices['gameday_football_url']);
  String? get gameDayBasketballUrl   => JsonUtils.stringValue(thirdPartyServices['gameday_basketball_url']);
  String? get gameDayAllUrl          => JsonUtils.stringValue(thirdPartyServices['gameday_all_url']);
  String? get convergeUrl            => JsonUtils.stringValue(thirdPartyServices['converge_url']);

  // Getters: Twitter
  String? get twitterUrl             => JsonUtils.stringValue(twitter['url']);
  int?    get twitterTweetsCount     => JsonUtils.intValue(twitter['tweets_count']);
  
  // ""     : { "id":"18165866", "name":"illinois_alma" },
  // "gies" : { "id":"19615559", "name":"giesbusiness" }
  Map<String, dynamic>? twitterAccount([String? accountKey]) {
    Map<String, dynamic>? users = JsonUtils.mapValue(twitter['users']);
    return (users != null) ? JsonUtils.mapValue(users[accountKey ?? twitterDefaultAccountKey]) : null;
  }
  
  String? twitterAccountId([String? accountKey]) {
    Map<String, dynamic>? userAccount = twitterAccount(accountKey);
    return (userAccount != null) ? JsonUtils.stringValue(userAccount['id']) : null;
  }
  
  String? twitterAccountName([String? accountKey]) {
    Map<String, dynamic>? userAccount = twitterAccount(accountKey);
    return (userAccount != null) ? JsonUtils.stringValue(userAccount['name']) : null;
  }

  // Getters: Canvas

  String? get canvasStoreUrl {
    dynamic storeUrlEntry = JsonUtils.mapValue(canvas['store_url']);
    if (storeUrlEntry is Map) {
      return storeUrlEntry[Platform.operatingSystem.toLowerCase()];
    } else if (storeUrlEntry is String) {
      return storeUrlEntry;
    }
    return null;
  }

  String? get canvasCourseDeepLinkFormat => JsonUtils.stringValue(canvasDeepLink['course_format']);
  String? get canvasAssignmentDeepLinkFormat => JsonUtils.stringValue(canvasDeepLink['assignment_format']);

  // Getters: settings
  int  get homeFavoriteItemsCount => JsonUtils.intValue(settings['homeFavoriteItemsCount']) ?? 3;
  int  get recentItemsCount       => JsonUtils.intValue(settings['recentItemsCount']) ?? 32;
  String get appPrivacyVersion    => JsonUtils.stringValue(settings['privacyVersion']) ?? (JsonUtils.stringValue(content['mobileAppVersion']) ?? '0.0.0');

  @override
  int get refreshTimeout=> kReleaseMode ? super.refreshTimeout : 0;

  // Upgrade

  @override
  void checkUpgrade() {
    super.checkUpgrade();
    _checkOnboarding();
  }

  // Onboarding

  String? get onboardingRequiredVersion {
    dynamic requiredVersion = onboardingInfo['required_version'];
    if ((requiredVersion is String) && (AppVersion.compareVersions(requiredVersion, appVersion) <= 0)) {
      return requiredVersion;
    }
    return null;
  }

  void _checkOnboarding() {
    String? value;
    if ((value = this.onboardingRequiredVersion) != null) {
      NotificationService().notify(notifyOnboardingRequired, value);
    }
  }
}

