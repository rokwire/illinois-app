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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:illinois/model/Config.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:illinois/model/Questionnaire.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/AppReview.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Assistant.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/CustomCourses.dart';
import 'package:illinois/service/CheckList.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/service/MobileAccess.dart';
import 'package:illinois/service/Questionnaire.dart';
import 'package:illinois/service/Safety.dart';
import 'package:illinois/service/SkillsSelfEvaluation.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/service/LiveStats.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/OnCampus.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/service/Polls.dart';
import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/service/Rewards.dart';
import 'package:illinois/service/Services.dart' as illinois;
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/RadioPlayer.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/service/WellnessRings.dart';
import 'package:illinois/ui/onboarding/OnboardingAlertPanel.dart';

import 'package:illinois/ui/onboarding/OnboardingErrorPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingUpgradePanel.dart';

import 'package:illinois/ui/RootPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnaireAcknowledgementPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnairePromptPanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/widgets/FlexContent.dart';
import 'package:illinois/utils/AppUtils.dart';


import 'package:rokwire_plugin/service/config.dart' as rokwire;
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/device_calendar.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/app_navigation.dart';
import 'package:rokwire_plugin/service/firebase_core.dart';
import 'package:rokwire_plugin/service/firebase_crashlytics.dart';
import 'package:rokwire_plugin/service/local_notifications.dart';
import 'package:rokwire_plugin/service/places.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/app_notification.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/http_proxy.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/utils/crypt.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'ui/onboarding2/Onboarding2ResearchQuestionnairePanel.dart';

final AppExitListener appExitListener = AppExitListener();

void mainImpl({ rokwire.ConfigEnvironment? configEnvironment }) async {

  runZonedGuarded(() async {

    // https://stackoverflow.com/questions/57689492/flutter-unhandled-exception-servicesbinding-defaultbinarymessenger-was-accesse
    WidgetsFlutterBinding.ensureInitialized();

    //Set your preferred orientations. To allow all standard orientations (portrait up/down, landscape left/right):
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    NotificationService().subscribe(appExitListener, AppLivecycle.notifyStateChanged);

    illinois.Services().create([
      // Add highest priority services at top

      FirebaseCore(),
      FirebaseCrashlytics(),
      AppLivecycle(),
      Connectivity(),
      LocationServices(),

      Storage(),

      Config(defaultEnvironment: configEnvironment),
      AppDateTime(),
      NativeCommunicator(),
      DeepLink(),
      HttpProxy(),

      Auth2(),
      Localization(),
      Styles(),
      Content(),
      Analytics(),
      FirebaseMessaging(),
      LocalNotifications(),
      Sports(),
      LiveStats(),
      RecentItems(),
      Dinings(),
      IlliniCash(),
      FlexUI(),
      Polls(),
      GeoFence(),
      Guide(),
      Inbox(),
      DeviceCalendar(),
      Events(),
      Events2(),
      Groups(),
      Social(),
      CheckList(CheckList.giesOnboarding),
      CheckList(CheckList.uiucOnboarding),
      Canvas(),
      CustomCourses(),
      Rewards(),
      OnCampus(),
      Wellness(),
      WellnessRings(),
      RadioPlayer(),
      AppReview(),
      StudentCourses(),
      Appointments(),
      MTD(),
      Assistant(),
      MobileAccess(),
      SkillsSelfEvaluation(),
      Gateway(),
      Places(),
      Safety(),
      Onboarding2(),
    ]);

    ServiceError? serviceError = await illinois.Services().init();

    //_testSecretKeys();

    // do not show the red error widget when release mode
    if (kReleaseMode) {
      ErrorWidget.builder = (FlutterErrorDetails details) => Container();
    }

    // Log app create analytics event
    Analytics().logLivecycle(name: Analytics.LogLivecycleEventCreate);

    runApp(App(initializeError: serviceError));
  }, FirebaseCrashlytics().handleZoneError);
}

class AppExitListener with NotificationsListener {
  
  // NotificationsListener
  @override
  void onNotification(String name, param) {
    if ((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.detached)) {
      Future.delayed(Duration(), () {
        NotificationService().unsubscribe(appExitListener);
        illinois.Services().destroy();
      });
    }
  }
}

class App extends StatefulWidget {

  final ServiceError? initializeError;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final Map<String, dynamic> _data = <String, dynamic>{};
  final String _stateKey = 'state';
  static App? _instance;

  App({this.initializeError}) {
    _instance = this;
  }

  static App? get instance => _instance;
  _AppState? get state => _data[_stateKey];

  BuildContext? get currentContext => navigatorKey.currentContext;

  @override
  _AppState createState() => (_data[_stateKey] = _AppState());
}

class _AppState extends State<App> with NotificationsListener, TickerProviderStateMixin {

  Key _key = UniqueKey();
  String? _lastRunVersion;
  String? _upgradeRequiredVersion;
  String? _upgradeAvailableVersion;
  ConfigAlert? _configAlert;
  Widget? _launchPopup;
  ServiceError? _initializeError;
  Future<ServiceError?>? _retryInitialzeFuture;
  DateTime? _pausedDateTime;

  @override
  void initState() {
    Log.d("App UI initialized");

    NotificationService().subscribe(this, [
      Onboarding2.notifyFinished,
      Localization.notifyLocaleChanged,
      Config.notifyUpgradeAvailable,
      Config.notifyUpgradeRequired,
      Config.notifyOnboardingRequired,
      Config.notifyConfigChanged,
      Storage.notifySettingChanged,
      Auth2.notifyUserDeleted,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      OnboardingConfigAlertPanel.notifyCheckAgain,
      AppLivecycle.notifyStateChanged,
    ]);

    _initializeError = widget.initializeError;

    _lastRunVersion = Storage().lastRunVersion;
    _upgradeRequiredVersion = Config().upgradeRequiredVersion;
    _upgradeAvailableVersion = Config().upgradeAvailableVersion;
    _configAlert = Config().alert;

    _checkForceOnboarding();

    if ((_lastRunVersion == null) || (_lastRunVersion != Config().appVersion)) {
      Storage().lastRunVersion = Config().appVersion;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NativeCommunicator().dismissLaunchScreen().then((_) {
        _presentLaunchPopup();
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<Notification>(
      onNotification: AppNotification().handleNotification,
      child: MaterialApp(
        key: _key,
        navigatorKey: widget.navigatorKey,
        localizationsDelegates: [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: Localization().supportedLocales(),
        navigatorObservers:[AppNavigation()],
        //onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        title: Localization().getStringEx('app.title', 'Illinois'),
        theme: _appTheme,
        home: _homePanel,
      ),
    );
  }

  Widget get _homePanel {

    if (_initializeError != null) {
      return OnboardingErrorPanel(error: _initializeError, retryHandler: _retryInitialze);
    }
    else if (_upgradeRequiredVersion != null) {
      return OnboardingUpgradePanel(requiredVersion:_upgradeRequiredVersion);
    }
    else if (_upgradeAvailableVersion != null) {
      return OnboardingUpgradePanel(availableVersion:_upgradeAvailableVersion);
    }
    else if (_configAlert?.isCurrent == true) {
      return OnboardingConfigAlertPanel(alert: _configAlert,);
    }
    else if (Storage().onBoardingPassed != true) {
      return Onboarding2().first ?? Container();
    }
    else if ((Storage().privacyUpdateVersion == null) || (AppVersion.compareVersions(Storage().privacyUpdateVersion, Config().appPrivacyVersion) < 0)) {
      return SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.update,);
    }
    else if (Auth2().prefs?.privacyLevel == null) {
      return SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.update,); // regular?
    }
    else if ((Storage().participateInResearchPrompted != true) && (Questionnaires().participateInResearch == null) && Auth2().isOidcLoggedIn) {
      return Onboarding2ResearchQuestionnairePromptPanel(
        onContinue: _didPromptParticipateInResearch,
      );
    }
    else {
      return RootPanel();
    }
  }

  void _didPromptParticipateInResearch(BuildContext context, Onboarding2Panel panel, bool? participateInResearch) async {
    if (participateInResearch == true) {
      panel.onboardingProgress = true;
      Questionnaire? questionnaire = await Questionnaires().loadResearch();
      Map<String, LinkedHashSet<String>>? questionnaireAnswers = Auth2().profile?.getResearchQuestionnaireAnswers(questionnaire?.id);
      panel.onboardingProgress = false;
      if (questionnaireAnswers?.isNotEmpty ?? false) {
        _didFinishParticipateInResearch(context);
      }
      else if (context.mounted) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2ResearchQuestionnairePanel(
          onContinue: () => _didResearchQuestionnaire(context),
        )));
      }
    }
    else {
      _didFinishParticipateInResearch(context);
    }
  }

  void _didResearchQuestionnaire(BuildContext context) {
    if (context.mounted) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2ResearchQuestionnaireAcknowledgementPanel(
        onContinue: () => _didResearchQuestionnaire(context),
      )));
    }
  }

  void _didFinishParticipateInResearch(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setStateIfMounted(() {});
  }

  void _resetUI() async {
    this.setStateIfMounted(() {
      _key = UniqueKey();
    });
  }

  void _finishOnboarding(BuildContext context) {
    Storage().onBoardingPassed = true;
    Route routeToHome = CupertinoPageRoute(builder: (context) => RootPanel());
    Navigator.pushAndRemoveUntil(context, routeToHome, (_) => false);
  }

  bool _checkForceOnboarding() {
    // Action: Force unboarding to concent vaccination (#651, #681)
    String? onboardingRequiredVersion = Config().onboardingRequiredVersion;
    if ((Storage().onBoardingPassed == true) &&
        (_lastRunVersion != null) &&
        (onboardingRequiredVersion != null) &&
        (AppVersion.compareVersions(_lastRunVersion, onboardingRequiredVersion) < 0) &&
        (AppVersion.compareVersions(onboardingRequiredVersion, Config().appVersion) <= 0)) {
      Storage().onBoardingPassed = false;
      return true;
    }
    return false;
  }

  Future<ServiceError?> _retryInitialze() async {
    if (_retryInitialzeFuture != null) {
      return await _retryInitialzeFuture;
    }
    else {
      _retryInitialzeFuture = illinois.Services().init();
      ServiceError? serviceError = await _retryInitialzeFuture;
      _retryInitialzeFuture = null;

      if (_initializeError != serviceError) {
        Future.delayed(Duration(milliseconds: 300)).then((_) {
          setStateIfMounted(() {
            _initializeError = serviceError;
          });
        });
      }

      return serviceError;
    }
    
  }

  void _presentLaunchPopup() {
    BuildContext? launchContext = App.instance?.currentContext;
    if ((_launchPopup == null) && (launchContext != null)) {
      List<String>? launchList = JsonUtils.stringListValue(FlexUI()['launch']);
      if (launchList != null) {
        for (dynamic launchEntry in launchList) {
          _launchPopup = FlexContent(contentKey: launchEntry, onClose: (BuildContext context) {
            _launchPopup = null;
            Navigator.of(context).pop();
          },);
          showDialog(context: launchContext, builder: (BuildContext context) {
            return Dialog(child:
              Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                _launchPopup ?? Container()
              ]),
            );
          }).then((_) {
            _launchPopup = null;
          });
          break;
        }
      }
    }
  }

  // App Theme

  ThemeData get _appTheme => ThemeData(
    appBarTheme: AppBarTheme(backgroundColor: Styles().colors.fillColorPrimaryVariant),
    dialogTheme: DialogThemeData(
      backgroundColor: Styles().colors.surface,
      contentTextStyle: Styles().textStyles.getTextStyle('widget.message.medium.thin'),
      titleTextStyle: Styles().textStyles.getTextStyle('widget.message.medium'),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(textStyle: WidgetStateProperty.all(Styles().textStyles.getTextStyle('widget.message.medium.thin'))),
    ),
    primaryColor: Styles().colors.fillColorPrimaryVariant,
    fontFamily: Styles().fontFamilies.regular
  );

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Onboarding2.notifyFinished) {
      Future.delayed(Duration(milliseconds: 100), () {
        _finishOnboarding(param);
      });
    }
    else if (name == Config.notifyUpgradeRequired) {
      setStateIfMounted(() {
        _upgradeRequiredVersion = param;
      });
    }
    else if (name == Config.notifyUpgradeAvailable) {
      setStateIfMounted(() {
        _upgradeAvailableVersion = param;
      });
    }
    else if (name == Config.notifyOnboardingRequired) {
      if (_checkForceOnboarding()) {
        _resetUI();
      }
    }
    else if (name == Config.notifyConfigChanged) {
      _updateConfigAlert();
    }
    else if (name == Auth2.notifyUserDeleted) {
      _resetUI();
    }
    else if (name == Localization.notifyLocaleChanged) {
      _resetUI();
    }
    else if (name == Storage.notifySettingChanged) {
      if (param == Storage.privacyUpdateVersionKey) {
        setStateIfMounted(() {});
      }
    }
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      setStateIfMounted(() { });
    }
    else if (name == OnboardingConfigAlertPanel.notifyCheckAgain) {
      setStateIfMounted(() {

      });
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
      /* TMP:
      setState(() {
        Storage().onBoardingPassed = false;
        _key = UniqueKey();
      });*/
    }
    else if (state == AppLifecycleState.resumed) {
      if (_initializeError != null) {
        _retryInitialze();
      }
      else if (_configAlert?.hasTimeLimits == true) {
        setStateIfMounted(() {}); // setState will acknolwedge the time limits
      }
      else if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          setStateIfMounted(() {}); // setState could present Participate In Research, in case the user has logged in recently
          _presentLaunchPopup();
        }
      }
    }
  }

  void _updateConfigAlert() {
    ConfigAlert? configAlert = Config().alert;
    if ((_configAlert != configAlert) && mounted) {
      setState(() {
        _configAlert = configAlert;
      });
    }
  }
}

// ignore: unused_element
void _testSecretKeys() {
  String? encryptionKey = Config().encryptionKey;
  String? encryptionIV = Config().encryptionIV;
  
  String? secretKeysDev, secretKeysDevEnc, secretKeysProd, secretKeysProdEnc, secretKeysTest, secretKeysTestEnc;
  
  // AESCrypt.decrypt

  secretKeysDevEnc ??= '...';
  secretKeysDev = AESCrypt.decrypt(secretKeysDevEnc, key: encryptionKey, iv: encryptionIV);
  Log.d("$secretKeysDev", lineLength: 912);

  secretKeysProdEnc ??= '...';
  secretKeysProd = AESCrypt.decrypt(secretKeysProdEnc, key: encryptionKey, iv: encryptionIV);
  Log.d("$secretKeysProd", lineLength: 912);

  secretKeysTestEnc ??= '...';
  secretKeysTest = AESCrypt.decrypt(secretKeysTestEnc, key: encryptionKey, iv: encryptionIV);
  Log.d("$secretKeysTest", lineLength: 912);

  // AESCrypt.encrypt
  
  secretKeysDev ??= JsonUtils.encode({...{}}) ?? '';
  secretKeysDevEnc = AESCrypt.encrypt(secretKeysDev, key: encryptionKey, iv: encryptionIV);
  Log.d("$secretKeysDevEnc", lineLength: 912);

  secretKeysProd ??= JsonUtils.encode({...{}}) ?? '';
  secretKeysProdEnc = AESCrypt.encrypt(secretKeysProd, key: encryptionKey, iv: encryptionIV);
  Log.d("$secretKeysProdEnc", lineLength: 912);

  secretKeysTest ??= JsonUtils.encode({...{}}) ?? '';
  secretKeysTestEnc = AESCrypt.encrypt(secretKeysTest, key: encryptionKey, iv: encryptionIV);
  Log.d("$secretKeysTestEnc", lineLength: 912);
}
