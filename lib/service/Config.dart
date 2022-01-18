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
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/utils/Crypt.dart';
import 'package:package_info/package_info.dart';
import 'package:collection/collection.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class Config with Service implements NotificationsListener {

  static const String _configsAsset       = "configs.json.enc";
  static const String _configKeysAsset    = "config.keys.json";

  static const String notifyUpgradeRequired     = "edu.illinois.rokwire.config.upgrade.required";
  static const String notifyUpgradeAvailable    = "edu.illinois.rokwire.config.upgrade.available";
  static const String notifyOnboardingRequired  = "edu.illinois.rokwire.config.onboarding.required";
  static const String notifyConfigChanged       = "edu.illinois.rokwire.config.changed";
  static const String notifyEnvironmentChanged  = "edu.illinois.rokwire.config.environment.changed";

  Map<String, dynamic>? _config;
  Map<String, dynamic>? _configAsset;
  Map<String, dynamic>? _encryptionKeys;
  ConfigEnvironment?    _configEnvironment;
  PackageInfo?          _packageInfo;
  Directory?            _appDocumentsDir; 
  String?               _appCanonicalId;
  String?               _appPlatformId;
  DateTime?             _pausedDateTime;
  
  final Set<String>    _reportedUpgradeVersions = Set<String>();

  // Singletone Instance

  Config._internal();
  static final Config _instance = Config._internal();

  factory Config() {
    return _instance;
  }
  
  static Config get instance {
    return _instance;
  }

  // Initialization

  @override
  void createService() {

    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      FirebaseMessaging.notifyConfigUpdate
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {

    _configEnvironment = configEnvFromString(Storage().configEnvironment) ?? defaultConfigEnvironment;

    _packageInfo = await PackageInfo.fromPlatform();
    _appDocumentsDir = await getApplicationDocumentsDirectory();
    Log.d('Application Documents Directory: ${_appDocumentsDir!.path}');

    await _init();
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Connectivity()]);
  }
  
  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == FirebaseMessaging.notifyConfigUpdate) {
      _updateFromNet();
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (refreshTimeout < pausedDuration.inSeconds) {
          _updateFromNet();
        }
      }
    }
  }

  // Implementation

  String get _configName {
    String? configTarget = configEnvToString(_configEnvironment);
    return "config.$configTarget.json";
  }

  File get _configFile {
    String configFilePath = join(_appDocumentsDir!.path, _configName);
    return File(configFilePath);
  }

  Future<Map<String, dynamic>?> _loadFromFile(File? configFile) async {
    try {
      String? configContent = (await configFile?.exists() == true) ? await configFile?.readAsString() : null;
      return _configFromJsonString(configContent);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadFromAssets() async {
    try {
      String configsStrEnc = await rootBundle.loadString('assets/$_configsAsset');
      String? configsStr = AESCrypt.decrypt(configsStrEnc, key: encryptionKey, iv: encryptionIV);
      Map<String, dynamic>? configs = JsonUtils.decode(configsStr);
      String? configTarget = configEnvToString(_configEnvironment);
      return (configs != null) ? configs[configTarget] : null;
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<String?> _loadAsStringFromNet() async {
    try {
      http.Response? response = await Network().get(appConfigUrl, auth: NetworkAuth.ApiKey);
      return ((response != null) && (response.statusCode == 200)) ? response.body : null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Map<String, dynamic>? _configFromJsonString(String? configJsonString) {
    dynamic configJson =  JsonUtils.decode(configJsonString);
    List<dynamic>? jsonList = (configJson is List) ? configJson : null;
    if (jsonList != null) {
      
      jsonList.sort((dynamic cfg1, dynamic cfg2) {
        return ((cfg1 is Map) && (cfg2 is Map)) ? AppVersionUtils.compareVersions(cfg1['mobileAppVersion'], cfg2['mobileAppVersion']) : 0;
      });

      for (int index = jsonList.length - 1; index >= 0; index--) {
        Map<String, dynamic> cfg = jsonList[index];
        if (AppVersionUtils.compareVersions(cfg['mobileAppVersion'], _packageInfo!.version) <= 0) {
          _decryptSecretKeys(cfg);
          return cfg;
        }
      }
    }

    return null;
  }

  void _decryptSecretKeys(Map<String, dynamic>? config) {
    dynamic secretKeys = (config != null) ? config['secretKeys'] : null;
    if (secretKeys is String) {
      config!['secretKeys'] = JsonUtils.decodeMap(AESCrypt.decrypt(secretKeys, key: encryptionKey, iv: encryptionIV));
    }
  }

  Future<Map<String, dynamic>?> _loadEncryptionKeysFromAssets() async {
    try {
      return JsonUtils.decode(await rootBundle.loadString('assets/$_configKeysAsset'));
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<void> _init() async {
    
    _encryptionKeys = await _loadEncryptionKeysFromAssets();
    if (_encryptionKeys == null) {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.fatal,
        title: 'Config Initialization Failed',
        description: 'Failed to load config encryption keys.',
      );
    }

    _config = await _loadFromFile(_configFile);

    if (_config == null) {
      _configAsset = await _loadFromAssets();
      String? configString = await _loadAsStringFromNet();
      _configAsset = null;

      _config = (configString != null) ? _configFromJsonString(configString) : null;
      if (_config != null) {
        _configFile.writeAsStringSync(configString!, flush: true);
        NotificationService().notify(notifyConfigChanged, null);
        
        _checkUpgrade();
        _checkOnboarding();
      }
      else {
        throw ServiceError(
          source: this,
          severity: ServiceErrorSeverity.fatal,
          title: 'Config Initialization Failed',
          description: 'Failed to initialize application configuration.',
        );
      }
    }
    else {
      _checkUpgrade();
      _checkOnboarding();
      _updateFromNet();
    }
  }

  void _updateFromNet() {
    _loadAsStringFromNet().then((String? configString) {
      Map<String, dynamic>? config = _configFromJsonString(configString);
      if ((config != null) && (AppVersionUtils.compareVersions(_config!['mobileAppVersion'], config['mobileAppVersion']) <= 0) && !DeepCollectionEquality().equals(_config, config))  {
        _config = config;
        _configFile.writeAsString(configString!, flush: true);
        NotificationService().notify(notifyConfigChanged, null);

        _checkUpgrade();
        _checkOnboarding();
      }
    });
  }

  // App Id & Version

  String? get appId {
    return _packageInfo?.packageName;
  }

  String? get appCanonicalId {
    if (_appCanonicalId == null) {
      _appCanonicalId = appId;
      
      String platformSuffix = ".${Platform.operatingSystem.toLowerCase()}";
      if ((_appCanonicalId != null) && _appCanonicalId!.endsWith(platformSuffix)) {
        _appCanonicalId = _appCanonicalId!.substring(0, _appCanonicalId!.length - platformSuffix.length);
      }
    }
    return _appCanonicalId;
  }

  String? get appPlatformId {
    if (_appPlatformId == null) {
      _appPlatformId = appId;

      String platformSuffix = ".${Platform.operatingSystem.toLowerCase()}";
      if ((_appPlatformId != null) && !_appPlatformId!.endsWith(platformSuffix)) {
        _appPlatformId = _appPlatformId! + platformSuffix;
      }
    }
    return _appPlatformId;
  }

  String? get appVersion {
    return _packageInfo?.version;
  }

  // Getters: compound entries

  Map<String, dynamic> get otherUniversityServices { return (_config != null) ? (_config!['otherUniversityServices'] ?? {}) : {}; }
  Map<String, dynamic> get platformBuildingBlocks  { return (_config != null) ? (_config!['platformBuildingBlocks'] ?? {}) : {}; }
  Map<String, dynamic> get thirdPartyServices      { return (_config != null) ? (_config!['thirdPartyServices'] ?? {}) : {}; }

  Map<String, dynamic> get secretKeys              { return (_config != null) ? (_config!['secretKeys'] ?? {}) : {}; }
  Map<String, dynamic> get secretRokwire           { return secretKeys['rokwire'] ?? {}; }
  Map<String, dynamic> get secretCore              { return secretKeys['core'] ?? {}; }
  Map<String, dynamic> get secretShibboleth        { return secretKeys['shibboleth'] ?? {}; }
  Map<String, dynamic> get secretIlliniCash        { return secretKeys['illini_cash'] ?? {}; }
  Map<String, dynamic> get secretLaundry           { return secretKeys['laundry'] ?? {}; }
  Map<String, dynamic> get secretParkhub           { return secretKeys['parkhub'] ?? {}; }
  Map<String, dynamic> get secretPadaapi           { return secretKeys['padaapi'] ?? {}; }
  Map<String, dynamic> get secretTwitter           { return secretKeys['twitter'] ?? {}; }
  
  Map<String, dynamic> get settings                { return (_config != null) ? (_config!['settings'] ?? {}) : {}; }
  List<dynamic>? get supportedLocales               { return (_config != null) ? (_config!['languages']) : null; }
  Map<String, dynamic> get twitter                 { return (_config != null) ? (_config!['twitter'] ?? {}) : {}; }
  Map<String, dynamic> get upgradeInfo             { return (_config != null) ? (_config!['upgrade'] ?? {}) : {}; }
  Map<String, dynamic> get onboardingInfo          { return (_config != null) ? (_config!['onboarding'] ?? {}) : {}; }

  Map<String, dynamic> get safer                   { return (_config != null) ? (_config!['safer'] ?? {}) : {}; }
  Map<String, dynamic> get saferMcKinley           { return safer['mckinley'] ?? {}; }
  Map<String, dynamic> get saferWellness           { return safer['wellness'] ?? {}; }

  // Getters: Encryption Keys

  String? get encryptionKey                         { return (_encryptionKeys != null) ? _encryptionKeys!['key'] : null; }
  String? get encryptionIV                          { return (_encryptionKeys != null) ? _encryptionKeys!['iv'] : null; }

  // Getters: Config Asset Ackwowledgement

  String? get appConfigUrl           {                                                                 // "https://api-dev.rokwire.illinois.edu/app/configs"
    String? assetUrl = (_configAsset != null) ? _configAsset!['config_url'] : null;
    return assetUrl ?? platformBuildingBlocks['appconfig_url'];
  } 
  
  String? get rokwireApiKey          {
    String? assetKey = (_configAsset != null) ? _configAsset!['api_key'] : null;
    return assetKey ?? secretRokwire['api_key'];
  }

  // Getters: Secret Keys
  String? get coreOrgId              { return secretCore['org_id']; }

  String? get shibbolethClientId     { return secretShibboleth['client_id']; }
  String? get shibbolethClientSecret { return secretShibboleth['client_secret']; }

  String? get illiniCashAppKey       { return secretIlliniCash['app_key']; }
  String? get illiniCashHmacKey      { return secretIlliniCash['hmac_key']; }
  String? get illiniCashSecretKey    { return secretIlliniCash['secret_key']; }

  String? get laundryApiKey          { return secretLaundry['api_key']; }

  String? get padaapiApiKey          { return secretPadaapi['api_key']; }

  String? get twitterToken          { return secretTwitter['token']; }
  String? get twitterTokenType      { return secretTwitter['token_type']; }

  // Getters: Other University Services
  String? get shibbolethAuthTokenUrl { return otherUniversityServices['shibboleth_auth_token_url']; }  // "https://{shibboleth_client_id}:{shibboleth_client_secret}@shibboleth.illinois.edu/idp/profile/oidc/token"
  String? get shibbolethOauthHostUrl { return otherUniversityServices['shibboleth_oauth_host_url']; }  // "shibboleth.illinois.edu"
  String? get shibbolethOauthPathUrl { return otherUniversityServices['shibboleth_oauth_path_url']; }  // "/idp/profile/oidc/authorize"
  String? get userAuthUrl            { return otherUniversityServices['user_auth_url']; }              // "https://shibboleth.illinois.edu/idp/profile/oidc/userinfo"
  String? get assetsUrl              { return otherUniversityServices['assets_url']; }                 // "https://rokwire-assets.s3.us-east-2.amazonaws.com"
  String? get eatSmartUrl            { return otherUniversityServices['eat_smart_url']; }              // "https://eatsmart.housing.illinois.edu/NetNutrition/46"
  String? get illiniCashBaseUrl      { return otherUniversityServices['illini_cash_base_url']; }       // "https://shibtest.housing.illinois.edu/MobileAppWS/api"
  String? get illiniCashTrustcommerceHost { return otherUniversityServices['illini_cash_trustcommerce_host']; } // "https://vault.trustcommerce.com"
  String? get illiniCashTokenHost    { return otherUniversityServices['illini_cash_token_host']; }     // "https://webservices.admin.uillinois.edu"
  String? get illiniCashPaymentHost  { return otherUniversityServices['illini_cash_payment_host']; }   //"https://web.housing.illinois.edu"
  String? get illiniCashTosUrl       { return otherUniversityServices['illini_cash_tos_url']; }        // "https://housing.illinois.edu/resources/illini-cash/terms"
  String? get myIlliniUrl            { return otherUniversityServices['myillini_url']; }               // "https://myillini.illinois.edu/Dashboard"
  String? get feedbackUrl            { return otherUniversityServices['feedback_url']; }               // "https://forms.illinois.edu/sec/1971889"
  String? get crisisHelpUrl          { return otherUniversityServices['crisis_help_url']; }            // "https://wellness.web.illinois.edu/help/im-not-sure-where-to-start/"
  String? get iCardUrl               { return otherUniversityServices['icard_url']; }                  // "https://www.icard.uillinois.edu/rest/rw/rwIDData/rwCardInfo"
  String? get privacyPolicyUrl       { return otherUniversityServices['privacy_policy_url']; }         // "https://go.illinois.edu/illinois-app-privacy"
  String? get padaapiUrl             { return otherUniversityServices['padaapi_url']; }                // "https://api-test.test-compliance.rokwire.illinois.edu/padaapi"

  // Getters: Platform Building Blocks
  String? get coreUrl                { return platformBuildingBlocks['core_url']; }                    // "https://api-dev.rokwire.illinois.edu/core"
  String? get loggingUrl             { return platformBuildingBlocks['logging_url']; }                 // "https://api-dev.rokwire.illinois.edu/logs"
  String? get rokwireAuthUrl         { return platformBuildingBlocks['rokwire_auth_url']; }            // "https://api-dev.rokwire.illinois.edu/authentication"
  String? get sportsServiceUrl       { return platformBuildingBlocks['sports_service_url']; }          // "https://api-dev.rokwire.illinois.edu/sports-service";
  String? get eventsUrl              { return platformBuildingBlocks['events_url']; }                  // "https://api-dev.rokwire.illinois.edu/events"
  String? get transportationUrl      { return platformBuildingBlocks["transportation_url"]; }          // "https://api-dev.rokwire.illinois.edu/transportation"
  String? get quickPollsUrl          { return platformBuildingBlocks["polls_url"]; }                   // "https://api-dev.rokwire.illinois.edu/poll/api";
  String? get locationsUrl           { return platformBuildingBlocks["locations_url"]; }               // "https://api-dev.rokwire.illinois.edu/location/api";
  String? get groupsUrl              { return platformBuildingBlocks["groups_url"]; }                  // "https://api-dev.rokwire.illinois.edu/gr/api";
  String? get contentUrl             { return platformBuildingBlocks["content_url"]; }                 // "https://api-dev.rokwire.illinois.edu/content";
  String? get notificationsUrl       { return platformBuildingBlocks["notifications_url"]; }           // "https://api-dev.rokwire.illinois.edu/notifications";
  
  // Getters: Third Party Services
  String? get instagramHostUrl       { return thirdPartyServices['instagram_host_url']; }        // "https://instagram.com/"
  String? get twitterHostUrl         { return thirdPartyServices['twitter_host_url']; }          // "https://twitter.com/"
  String? get laundryHostUrl         { return thirdPartyServices['launtry_host_url']; }          // "http://api.laundryview.com/"
  String? get ticketsUrl             { return thirdPartyServices['tickets_url']; }               // "https://ev11.evenue.net/cgi-bin/ncommerce3/SEGetGroupList?groupCode=EOS&linkID=illinois&shopperContext=&caller=&appCode=&utm_source=FI.com&utm_medium=TicketsPage&utm_content=MainImage&utm_campaign=AllTickets"
  String? get youtubeUrl             { return thirdPartyServices['youtube_url']; }               // "https://www.youtube.com/c/fightingilliniathletics"
  String? get gameDayFootballUrl     { return thirdPartyServices['gameday_football_url']; }      // "https://fightingillini.com/sports/2015/7/31/football_gamedayguide.aspx"
  String? get gameDayBasketballUrl   { return thirdPartyServices['gameday_basketball_url']; }    // "https://fightingillini.com/sports/2015/11/30/sfc_fanguide.aspx"
  String? get gameDayTennisUrl       { return thirdPartyServices['gameday_tennis_url']; }        // "https://fightingillini.com/sports/2015/6/27/tennis_facilities.aspx#eventinfo"
  String? get gameDayVolleyballUrl   { return thirdPartyServices['gameday_volleyball_url']; }    // "https://fightingillini.com/sports/2015/3/24/huffhall_volleyball.aspx#eventinfo"
  String? get gameDaySoftballUrl     { return thirdPartyServices['gameday_softball_url']; }      // "https://fightingillini.com/sports/2015/3/24/eichelbergerfield.aspx#eventinfo"
  String? get gameDaySwimDiveUrl     { return thirdPartyServices['gameday_swim_dive_url']; }     // "https://fightingillini.com/sports/2015/3/24/arcpool.aspx#eventinfo"
  String? get gameDayCrossCountryUrl { return thirdPartyServices['gameday_cross_country_url']; } // "https://fightingillini.com/sports/2015/3/24/arboretum.aspx#eventinfo"
  String? get gameDayBaseballUrl     { return thirdPartyServices['gameday_baseball_url']; }      // "https://fightingillini.com/sports/2015/3/24/illinoisfield.aspx#eventinfo"
  String? get gameDayGymnasticsUrl   { return thirdPartyServices['gameday_gymnastics_url']; }    // "https://fightingillini.com/sports/2015/6/27/huffhall_gymnastics.aspx#eventinfo"
  String? get gameDayWrestlingUrl    { return thirdPartyServices['gameday_wrestling_url']; }     // "https://fightingillini.com/sports/2015/6/27/huffhall_wrestling.aspx#eventinfo"
  String? get gameDaySoccerUrl       { return thirdPartyServices['gameday_soccer_url']; }        // "https://fightingillini.com/sports/2015/8/19/soccerstadium.aspx#eventinfo"
  String? get gameDayTrackFieldUrl   { return thirdPartyServices['gameday_track_field_url']; }   // "https://fightingillini.com/sports/2015/3/24/armory.aspx#eventinfo"
  String? get gameDayAllUrl          { return thirdPartyServices['gameday_all_url']; }           // "https://fightingillini.com/sports/2015/7/25/gameday.aspx"
  String? get convergeUrl            { return thirdPartyServices['converge_url']; }              // "https://api.converge-engine.com/v1/rokwire"

  // Getters: Twitter
  String? get twitterUrl             { return twitter['url']; }                                  // "https://api.twitter.com/2"
  int?    get twitterTweetsCount     { return twitter['tweets_count']; }                         // 5
  
  // ""     : { "id":"18165866", "name":"illinois_alma" },
  // "gies" : { "id":"19615559", "name":"giesbusiness" }
  Map<String, dynamic>? twitterUserAccount([String? category]) {
    Map<String, dynamic>? users = twitter['users'];
    return (users != null) ? users[category ?? ''] : null;
  }
  
  String? twitterUserId([String? category]) {
    Map<String, dynamic>? userAccount = twitterUserAccount(category);
    return (userAccount != null) ? userAccount['id'] : null;
  }
  
  String? twitterUserName([String? category]) {
    Map<String, dynamic>? userAccount = twitterUserAccount(category);
    return (userAccount != null) ? userAccount['name'] : null;
  }

  // Getters: Other Entries

  String? get eventsOrConvergeUrl    {
    String? convergeURL = FlexUI().hasFeature('converge') ? convergeUrl : null;
    return ((convergeURL != null) && convergeURL.isNotEmpty) ? convergeURL : eventsUrl;
  }

  String? deepLinkRedirectUrl(String? deepLink) {
    Uri? assetsUri = StringUtils.isNotEmpty(assetsUrl) ? Uri.tryParse(assetsUrl!) : null;
    String? redirectUrl = (assetsUri != null) ? "${assetsUri.scheme}://${assetsUri.host}/html/redirect.html" : null;
    return StringUtils.isNotEmpty(redirectUrl) ? "$redirectUrl?target=$deepLink" : deepLink;
  }

  int get refreshTimeout {
    return kReleaseMode ? (settings['refreshTimeout'] ?? 0) : 0;
  }

  int get refreshTokenRetriesCount {
    return (settings['refreshTokenRetriesCount'] ?? 3);
  }

  String get appPrivacyVersion {
    return settings['privacyVersion'] ?? (_config!['mobileAppVersion'] ?? '0.0.0');
  }

  // Upgrade

  String? get upgradeRequiredVersion {
    dynamic requiredVersion = _upgradeStringEntry('required_version');
    if ((requiredVersion is String) && (AppVersionUtils.compareVersions(_packageInfo!.version, requiredVersion) < 0)) {
      return requiredVersion;
    }
    return null;
  }

  String? get upgradeAvailableVersion {
    dynamic availableVersion = _upgradeStringEntry('available_version');
    bool upgradeAvailable = (availableVersion is String) &&
        (AppVersionUtils.compareVersions(_packageInfo!.version, availableVersion) < 0) &&
        !Storage().reportedUpgradeVersions.contains(availableVersion) &&
        !_reportedUpgradeVersions.contains(availableVersion);
    return upgradeAvailable ? availableVersion : null;
  }

  String? get upgradeUrl {
    return _upgradeStringEntry('url');
  }

  void setUpgradeAvailableVersionReported(String? version, { permanent : false }) {
    if (permanent) {
      Storage().reportedUpgradeVersion = version;
    }
    else if (version != null) {
      _reportedUpgradeVersions.add(version);
    }
  }

  void _checkUpgrade() {
    String? value;
    if ((value = this.upgradeRequiredVersion) != null) {
      NotificationService().notify(notifyUpgradeRequired, value);
    }
    else if ((value = this.upgradeAvailableVersion) != null) {
      NotificationService().notify(notifyUpgradeAvailable, value);
    }
  }

  String? _upgradeStringEntry(String key) {
    dynamic entry = upgradeInfo[key];
    if (entry is String) {
      return entry;
    }
    else if (entry is Map) {
      dynamic value = entry[Platform.operatingSystem.toLowerCase()];
      return (value is String) ? value : null;
    }
    else {
      return null;
    }
  }

  // Onboarding

  String? get onboardingRequiredVersion {
    dynamic requiredVersion = onboardingInfo['required_version'];
    if ((requiredVersion is String) && (AppVersionUtils.compareVersions(requiredVersion, appVersion) <= 0)) {
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

  // Environment

  set configEnvironment(ConfigEnvironment? configEnvironment) {
    if (_configEnvironment != configEnvironment) {
      _configEnvironment = configEnvironment;
      Storage().configEnvironment = configEnvToString(_configEnvironment);

      _init().catchError((e){
        print(e.toString());
      }).whenComplete((){
        NotificationService().notify(notifyEnvironmentChanged, null);
      });
    }
  }

  ConfigEnvironment? get configEnvironment {
    return _configEnvironment;
  }

  static ConfigEnvironment get defaultConfigEnvironment {
    return kReleaseMode ? ConfigEnvironment.production : ConfigEnvironment.dev;
  }

  // Assets cache path

  Directory? get appDocumentsDir {
    return _appDocumentsDir;
  }

  Directory? get assetsCacheDir  {

    String? assetsUrl = this.assetsUrl;
    String? assetsCacheDir = _appDocumentsDir?.path;
    if ((assetsCacheDir != null) && (assetsUrl != null)) {
      try {
        Uri assetsUri = Uri.parse(assetsUrl);
        for (String pathSegment in assetsUri.pathSegments) {
          assetsCacheDir = join(assetsCacheDir!, pathSegment);
        }
      }
      on Exception catch(e) {
        print(e.toString());
      }
    }

    return (assetsCacheDir != null) ? Directory(assetsCacheDir) : null;
  }
}

enum ConfigEnvironment { production, test, dev }

String? configEnvToString(ConfigEnvironment? env) {
  if (env == ConfigEnvironment.production) {
    return 'production';
  }
  else if (env == ConfigEnvironment.test) {
    return 'test';
  }
  else if (env == ConfigEnvironment.dev) {
    return 'dev';
  }
  else {
    return null;
  }
}

ConfigEnvironment? configEnvFromString(String? value) {
  if ('production' == value) {
    return ConfigEnvironment.production;
  }
  else if ('test' == value) {
    return ConfigEnvironment.test;
  }
  else if ('dev' == value) {
    return ConfigEnvironment.dev;
  }
  else {
    return null;
  }
}
