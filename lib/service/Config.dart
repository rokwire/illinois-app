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
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/config.dart' as rokwire;
import 'package:rokwire_plugin/utils/utils.dart';

class Config extends rokwire.Config {

  static String get notifyUpgradeRequired     => rokwire.Config.notifyUpgradeRequired;
  static String get notifyUpgradeAvailable    => rokwire.Config.notifyUpgradeAvailable;
  static String get notifyOnboardingRequired  => rokwire.Config.notifyOnboardingRequired;
  static String get notifyConfigChanged       => rokwire.Config.notifyConfigChanged;
  static String get notifyEnvironmentChanged  => rokwire.Config.notifyEnvironmentChanged;

  // Singletone Factory

  @protected
  Config.internal() : super.internal();

  factory Config() => ((rokwire.Config.instance is Config) ? (rokwire.Config.instance as Config) : (rokwire.Config.instance = Config.internal()));

  // Getters: compound entries

  Map<String, dynamic> get thirdPartyServices  => JsonUtils.mapValue(content['thirdPartyServices']) ?? {};

  Map<String, dynamic> get secretShibboleth => JsonUtils.mapValue(secretKeys['shibboleth']) ?? {};
  Map<String, dynamic> get secretIlliniCash => JsonUtils.mapValue(secretKeys['illini_cash']) ?? {};
  Map<String, dynamic> get secretLaundry => JsonUtils.mapValue(secretKeys['laundry']) ?? {};
  Map<String, dynamic> get secretParkhub => JsonUtils.mapValue(secretKeys['parkhub']) ?? {};
  Map<String, dynamic> get secretPadaapi => JsonUtils.mapValue(secretKeys['padaapi']) ?? {};
  Map<String, dynamic> get secretTwitter => JsonUtils.mapValue(secretKeys['twitter']) ?? {};
  Map<String, dynamic> get secretCanvas => JsonUtils.mapValue(secretKeys['canvas']) ?? {};
  
  Map<String, dynamic> get twitter => JsonUtils.mapValue(content['twitter']) ?? {};
  Map<String, dynamic> get onboardingInfo => JsonUtils.mapValue(content['onboarding']) ?? {};

  Map<String, dynamic> get safer => JsonUtils.mapValue(content['safer']) ?? {};
  Map<String, dynamic> get saferMcKinley => JsonUtils.mapValue(safer['mckinley']) ?? {};
  Map<String, dynamic> get saferWellness => JsonUtils.mapValue(safer['wellness']) ?? {};

  // Getters: Secret Keys

  String? get shibbolethClientId     => JsonUtils.stringValue(secretShibboleth['client_id']);
  String? get shibbolethClientSecret => JsonUtils.stringValue(secretShibboleth['client_secret']);

  String? get illiniCashAppKey       => JsonUtils.stringValue(secretIlliniCash['app_key']);
  String? get illiniCashHmacKey      => JsonUtils.stringValue(secretIlliniCash['hmac_key']);
  String? get illiniCashSecretKey    => JsonUtils.stringValue(secretIlliniCash['secret_key']);

  String? get laundryApiKey          => JsonUtils.stringValue(secretLaundry['api_key']);

  String? get padaapiApiKey          => JsonUtils.stringValue(secretPadaapi['api_key']);

  String? get twitterToken           => JsonUtils.stringValue(secretTwitter['token']);
  String? get twitterTokenType       => JsonUtils.stringValue(secretTwitter['token_type']);

  String? get canvasToken            => JsonUtils.stringValue(secretCanvas['token']);
  String? get canvasTokenType        => JsonUtils.stringValue(secretCanvas['token_type']);


  // Getters: Other University Services
  String? get shibbolethAuthTokenUrl => JsonUtils.stringValue(otherUniversityServices['shibboleth_auth_token_url']);  // "https://{shibboleth_client_id}:{shibboleth_client_secret}@shibboleth.illinois.edu/idp/profile/oidc/token"
  String? get shibbolethOauthHostUrl => JsonUtils.stringValue(otherUniversityServices['shibboleth_oauth_host_url']);  // "shibboleth.illinois.edu"
  String? get shibbolethOauthPathUrl => JsonUtils.stringValue(otherUniversityServices['shibboleth_oauth_path_url']);  // "/idp/profile/oidc/authorize"
  String? get userAuthUrl            => JsonUtils.stringValue(otherUniversityServices['user_auth_url']);              // "https://shibboleth.illinois.edu/idp/profile/oidc/userinfo"
  String? get assetsUrl              => JsonUtils.stringValue(otherUniversityServices['assets_url']);                 // "https://rokwire-assets.s3.us-east-2.amazonaws.com"
  String? get eatSmartUrl            => JsonUtils.stringValue(otherUniversityServices['eat_smart_url']);              // "https://eatsmart.housing.illinois.edu/NetNutrition/46"
  String? get iCardUrl               => JsonUtils.stringValue(otherUniversityServices['icard_url']);                  // "https://www.icard.uillinois.edu/rest/rw/rwIDData/rwCardInfo"
  String? get illiniCashBaseUrl      => JsonUtils.stringValue(otherUniversityServices['illini_cash_base_url']);       // "https://shibtest.housing.illinois.edu/MobileAppWS/api"
  String? get illiniCashTrustcommerceHost => JsonUtils.stringValue(otherUniversityServices['illini_cash_trustcommerce_host']); // "https://vault.trustcommerce.com"
  String? get illiniCashTokenHost    => JsonUtils.stringValue(otherUniversityServices['illini_cash_token_host']);     // "https://webservices.admin.uillinois.edu"
  String? get illiniCashPaymentHost  => JsonUtils.stringValue(otherUniversityServices['illini_cash_payment_host']);   //"https://web.housing.illinois.edu"
  String? get illiniCashTosUrl       => JsonUtils.stringValue(otherUniversityServices['illini_cash_tos_url']);        // "https://housing.illinois.edu/resources/illini-cash/terms"
  String? get myIlliniUrl            => JsonUtils.stringValue(otherUniversityServices['myillini_url']);               // "https://myillini.illinois.edu/Dashboard"
  String? get feedbackUrl            => JsonUtils.stringValue(otherUniversityServices['feedback_url']);               // "https://forms.illinois.edu/sec/1971889"
  String? get crisisHelpUrl          => JsonUtils.stringValue(otherUniversityServices['crisis_help_url']);            // "https://wellness.web.illinois.edu/help/im-not-sure-where-to-start/"
  String? get privacyPolicyUrl       => JsonUtils.stringValue(otherUniversityServices['privacy_policy_url']);         // "https://go.illinois.edu/illinois-app-privacy"
  String? get padaapiUrl             => JsonUtils.stringValue(otherUniversityServices['padaapi_url']);                // "https://api-test.test-compliance.rokwire.illinois.edu/padaapi"
  String? get canvasUrl              => JsonUtils.stringValue(otherUniversityServices['canvas_url']);                 // "https://canvas.illinois.edu"

  // Getters: Platform Building Blocks
  String? get rokwireAuthUrl         => JsonUtils.stringValue(platformBuildingBlocks['rokwire_auth_url']);            // "https://api-dev.rokwire.illinois.edu/authentication"
  String? get sportsServiceUrl       => JsonUtils.stringValue(platformBuildingBlocks['sports_service_url']);          // "https://api-dev.rokwire.illinois.edu/sports-service";
  String? get eventsUrl              => JsonUtils.stringValue(platformBuildingBlocks['events_url']);                  // "https://api-dev.rokwire.illinois.edu/events"
  String? get transportationUrl      => JsonUtils.stringValue(platformBuildingBlocks["transportation_url"]);          // "https://api-dev.rokwire.illinois.edu/transportation"
  String? get groupsUrl              => JsonUtils.stringValue(platformBuildingBlocks["groups_url"]);                  // "https://api-dev.rokwire.illinois.edu/gr/api";
  String? get contentUrl             => JsonUtils.stringValue(platformBuildingBlocks["content_url"]);                 // "https://api-dev.rokwire.illinois.edu/content";
  
  // Getters: Third Party Services
  String? get instagramHostUrl       => JsonUtils.stringValue(thirdPartyServices['instagram_host_url']);        // "https://instagram.com/"
  String? get twitterHostUrl         => JsonUtils.stringValue(thirdPartyServices['twitter_host_url']);          // "https://twitter.com/"
  String? get laundryHostUrl         => JsonUtils.stringValue(thirdPartyServices['launtry_host_url']);          // "http://api.laundryview.com/"
  String? get ticketsUrl             => JsonUtils.stringValue(thirdPartyServices['tickets_url']);               // "https://ev11.evenue.net/cgi-bin/ncommerce3/SEGetGroupList?groupCode=EOS&linkID=illinois&shopperContext=&caller=&appCode=&utm_source=FI.com&utm_medium=TicketsPage&utm_content=MainImage&utm_campaign=AllTickets"
  String? get youtubeUrl             => JsonUtils.stringValue(thirdPartyServices['youtube_url']);               // "https://www.youtube.com/c/fightingilliniathletics"
  String? get gameDayFootballUrl     => JsonUtils.stringValue(thirdPartyServices['gameday_football_url']);      // "https://fightingillini.com/sports/2015/7/31/football_gamedayguide.aspx"
  String? get gameDayBasketballUrl   => JsonUtils.stringValue(thirdPartyServices['gameday_basketball_url']);    // "https://fightingillini.com/sports/2015/11/30/sfc_fanguide.aspx"
  String? get gameDayTennisUrl       => JsonUtils.stringValue(thirdPartyServices['gameday_tennis_url']);        // "https://fightingillini.com/sports/2015/6/27/tennis_facilities.aspx#eventinfo"
  String? get gameDayVolleyballUrl   => JsonUtils.stringValue(thirdPartyServices['gameday_volleyball_url']);    // "https://fightingillini.com/sports/2015/3/24/huffhall_volleyball.aspx#eventinfo"
  String? get gameDaySoftballUrl     => JsonUtils.stringValue(thirdPartyServices['gameday_softball_url']);      // "https://fightingillini.com/sports/2015/3/24/eichelbergerfield.aspx#eventinfo"
  String? get gameDaySwimDiveUrl     => JsonUtils.stringValue(thirdPartyServices['gameday_swim_dive_url']);     // "https://fightingillini.com/sports/2015/3/24/arcpool.aspx#eventinfo"
  String? get gameDayCrossCountryUrl => JsonUtils.stringValue(thirdPartyServices['gameday_cross_country_url']); // "https://fightingillini.com/sports/2015/3/24/arboretum.aspx#eventinfo"
  String? get gameDayBaseballUrl     => JsonUtils.stringValue(thirdPartyServices['gameday_baseball_url']);      // "https://fightingillini.com/sports/2015/3/24/illinoisfield.aspx#eventinfo"
  String? get gameDayGymnasticsUrl   => JsonUtils.stringValue(thirdPartyServices['gameday_gymnastics_url']);    // "https://fightingillini.com/sports/2015/6/27/huffhall_gymnastics.aspx#eventinfo"
  String? get gameDayWrestlingUrl    => JsonUtils.stringValue(thirdPartyServices['gameday_wrestling_url']);     // "https://fightingillini.com/sports/2015/6/27/huffhall_wrestling.aspx#eventinfo"
  String? get gameDaySoccerUrl       => JsonUtils.stringValue(thirdPartyServices['gameday_soccer_url']);        // "https://fightingillini.com/sports/2015/8/19/soccerstadium.aspx#eventinfo"
  String? get gameDayTrackFieldUrl   => JsonUtils.stringValue(thirdPartyServices['gameday_track_field_url']);   // "https://fightingillini.com/sports/2015/3/24/armory.aspx#eventinfo"
  String? get gameDayAllUrl          => JsonUtils.stringValue(thirdPartyServices['gameday_all_url']);           // "https://fightingillini.com/sports/2015/7/25/gameday.aspx"
  String? get convergeUrl            => JsonUtils.stringValue(thirdPartyServices['converge_url']);              // "https://api.converge-engine.com/v1/rokwire"

  // Getters: Twitter
  String? get twitterUrl             => JsonUtils.stringValue(twitter['url']);                                  // "https://api.twitter.com/2"
  int?    get twitterTweetsCount     => JsonUtils.intValue(twitter['tweets_count']);                            // 5
  
  // ""     : { "id":"18165866", "name":"illinois_alma" },
  // "gies" : { "id":"19615559", "name":"giesbusiness" }
  Map<String, dynamic>? twitterUserAccount([String? category]) {
    Map<String, dynamic>? users = JsonUtils.mapValue(twitter['users']);
    return (users != null) ? JsonUtils.mapValue(users[category ?? '']) : null;
  }
  
  String? twitterUserId([String? category]) {
    Map<String, dynamic>? userAccount = twitterUserAccount(category);
    return (userAccount != null) ? JsonUtils.stringValue(userAccount['id']) : null;
  }
  
  String? twitterUserName([String? category]) {
    Map<String, dynamic>? userAccount = twitterUserAccount(category);
    return (userAccount != null) ? JsonUtils.stringValue(userAccount['name']) : null;
  }

  // Getters: settings

  String get appPrivacyVersion => JsonUtils.stringValue(settings['privacyVersion']) ?? (JsonUtils.stringValue(content['mobileAppVersion']) ?? '0.0.0');

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

