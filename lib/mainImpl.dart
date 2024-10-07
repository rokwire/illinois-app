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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:neom/service/AppDateTime.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/Questionnaire.dart';
import 'package:neom/service/DeepLink.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/Content.dart';
import 'package:neom/service/FirebaseMessaging.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:neom/service/IlliniCash.dart';
import 'package:neom/service/NativeCommunicator.dart';
import 'package:neom/service/Onboarding.dart';
import 'package:neom/service/Onboarding2.dart';
import 'package:neom/service/RecentItems.dart';
import 'package:neom/service/Services.dart' as neom;
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Storage.dart';

import 'package:neom/ui/onboarding/OnboardingErrorPanel.dart';
import 'package:neom/ui/onboarding/OnboardingUpgradePanel.dart';

import 'package:neom/ui/RootPanel.dart';
import 'package:neom/ui/profile/ProfileLoginPasskeyPanel.dart';
import 'package:neom/ui/widgets/FlexContent.dart';

import 'package:rokwire_plugin/service/config.dart' as rokwire;
import 'package:rokwire_plugin/service/device_calendar.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/app_navigation.dart';
import 'package:rokwire_plugin/service/firebase_core.dart';
import 'package:rokwire_plugin/service/firebase_crashlytics.dart';
import 'package:rokwire_plugin/service/local_notifications.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
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
import 'package:rokwire_plugin/utils/utils.dart';

final AppExitListener appExitListener = AppExitListener();

void mainImpl({ rokwire.ConfigEnvironment? configEnvironment }) async {

  runZonedGuarded(() async {

    // https://stackoverflow.com/questions/57689492/flutter-unhandled-exception-servicesbinding-defaultbinarymessenger-was-accesse
    WidgetsFlutterBinding.ensureInitialized();

    NotificationService().subscribe(appExitListener, AppLifecycle.notifyStateChanged);

    neom.Services().create([
      // Add highest priority services at top

      FirebaseCore(),
      FirebaseCrashlytics(),
      AppLifecycle(),
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
      if (!kIsWeb)
        LocalNotifications(),
      // Sports(),
      // LiveStats(),
      RecentItems(),
      // Dinings(),
      IlliniCash(),
      FlexUI(),
      Onboarding(),
      // Polls(),
      GeoFence(),
      // Guide(),
      Inbox(),
      DeviceCalendar(),
      Events(),
      Events2(),
      Groups(),
      // CheckList(CheckList.giesOnboarding),
      // CheckList(CheckList.uiucOnboarding),
      // Canvas(),
      // CustomCourses(),
      // Rewards(),
      // OnCampus(),
      // Wellness(),
      // WellnessRings(),
      // RadioPlayer(),
      // AppReview(),
      // StudentCourses(),
      // Appointments(),
      // MTD(),
      // SpeechToText(),
      // Assistant(),
      // MobileAccess(),
    ]);

    ServiceError? serviceError = await neom.Services().init();

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

class AppExitListener implements NotificationsListener {
  
  // NotificationsListener
  @override
  void onNotification(String name, param) {
    if ((name == AppLifecycle.notifyStateChanged) && (param == AppLifecycleState.detached)) {
      Future.delayed(Duration(), () {
        NotificationService().unsubscribe(appExitListener);
        neom.Services().destroy();
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

class _AppState extends State<App> with TickerProviderStateMixin implements NotificationsListener {

  Key _key = UniqueKey();
  String? _lastRunVersion;
  String? _upgradeRequiredVersion;
  String? _upgradeAvailableVersion;
  Widget? _launchPopup;
  ServiceError? _initializeError;
  Future<ServiceError?>? _retryInitialzeFuture;
  DateTime? _pausedDateTime;

  final Map<String, dynamic> _onboardingContext = {};

  @override
  void initState() {
    Log.d("App UI initialized");

    NotificationService().subscribe(this, [
      Onboarding2.notifyFinished,
      Localization.notifyLocaleChanged,
      Config.notifyUpgradeAvailable,
      Config.notifyUpgradeRequired,
      Config.notifyOnboardingRequired,
      Config.notifyResetUI,
      Storage.notifySettingChanged,
      Auth2.notifyLogout,
      Auth2.notifyUserDeleted,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      AppLifecycle.notifyStateChanged,
    ]);

    _initializeError = widget.initializeError;

    _lastRunVersion = Storage().lastRunVersion;
    _upgradeRequiredVersion = Config().upgradeRequiredVersion;
    _upgradeAvailableVersion = Config().upgradeAvailableVersion;

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
        ],
        supportedLocales: Localization().supportedLocales(),
        navigatorObservers:[AppNavigation()],
        //onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        title: Localization().getStringEx('app.title', 'Illinois'),
        theme: ThemeData(
          appBarTheme: AppBarTheme(backgroundColor: Styles().colors.fillColorPrimaryVariant),
          dialogTheme: DialogTheme(
            backgroundColor: Styles().colors.surface,
            contentTextStyle: Styles().textStyles.getTextStyle('widget.message.medium.thin'),
            titleTextStyle: Styles().textStyles.getTextStyle('widget.message.medium'),
          ),
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(textStyle: WidgetStateProperty.all(Styles().textStyles.getTextStyle('widget.message.medium.thin'))),
          ),
          primaryColor: Styles().colors.fillColorPrimaryVariant,
          colorScheme: ColorScheme.dark(primary: Styles().colors.fillColorSecondary,
              secondary: Styles().colors.fillColorPrimary),
          fontFamily: Styles().fontFamilies.regular),
        home: _homePanel,
      ),
    );
  }

  Widget get _homePanel {
    if (_initializeError != null) {
      return OnboardingErrorPanel(error: _initializeError, retryHandler: _retryInitialze);
    }
    if (_upgradeRequiredVersion != null) {
      return OnboardingUpgradePanel(requiredVersion:_upgradeRequiredVersion);
    }
    else if (_upgradeAvailableVersion != null) {
      return OnboardingUpgradePanel(availableVersion:_upgradeAvailableVersion);
    }
    else if (!Storage().onBoardingPassed! || !Auth2().isLoggedIn) {
      return ProfileLoginPasskeyPanel(onboardingContext: _onboardingContext,);
    }
    // else if ((Storage().privacyUpdateVersion == null) || (AppVersion.compareVersions(Storage().privacyUpdateVersion, Config().appPrivacyVersion) < 0)) {
    //   return SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.update,);
    // }
    // else if (Auth2().prefs?.privacyLevel == null) {
    //   return SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.update,); // regular?
    // }
    else if ((Storage().participateInResearchPrompted != true) && (Questionnaires().participateInResearch == null) && Auth2().isOidcLoggedIn) {
      return Onboarding2().researhQuestionnairePromptPanel(invocationContext: {
        "onFinishResearhQuestionnaireActionEx": (BuildContext context) {
          if (mounted) {
            setState(() {
              Storage().participateInResearchPrompted = true;
            });
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      });
    }
    else {
      return RootPanel();
    }
  }

  void _resetUI() async {
    this.setState(() {
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
      _retryInitialzeFuture = neom.Services().init();
      ServiceError? serviceError = await _retryInitialzeFuture;
      _retryInitialzeFuture = null;

      if (_initializeError != serviceError) {
        Future.delayed(Duration(milliseconds: 300)).then((_) {
          setState(() {
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

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Onboarding2.notifyFinished) {
      Future.delayed(Duration(milliseconds: 100), () {
        _finishOnboarding(param);
      });
    }
    else if (name == Config.notifyUpgradeRequired) {
      setState(() {
        _upgradeRequiredVersion = param;
      });
    }
    else if (name == Config.notifyUpgradeAvailable) {
      setState(() {
        _upgradeAvailableVersion = param;
      });
    }
    else if (name == Config.notifyOnboardingRequired) {
      if (_checkForceOnboarding()) {
        _resetUI();
      }
    }
    else if (name == Config.notifyResetUI) {
      _resetUI();
    }
    else if (name == Auth2.notifyUserDeleted) {
      _resetUI();
    }
    else if (name == Localization.notifyLocaleChanged) {
      _resetUI();
    }
    else if (name == Auth2.notifyLogout) {
      _onboardingContext.clear();
      _onboardingContext['afterLogout'] = true;
      _resetUI();
    }
    else if (name == Storage.notifySettingChanged) {
      if (param == Storage.privacyUpdateVersionKey) {
        setState(() {});
      }
    }
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      setState(() { });
    }
    else if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
    }
  }

  void _onAppLifecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_initializeError != null) {
        _retryInitialze();
      }
      else if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          if (mounted) {
            setState(() {}); // setState could present Participate In Research, in case the user has logged in recently
          }
          _presentLaunchPopup();
        }
      }
    }
  }
}

/*void _testSecretKeys() {
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
  
  secretKeysDev ??= '{...}';
  secretKeysDevEnc = AESCrypt.encrypt(secretKeysDev, key: encryptionKey, iv: encryptionIV);
  Log.d("$secretKeysDevEnc", lineLength: 912);

  secretKeysProd ??= '{...}';
  secretKeysProdEnc = AESCrypt.encrypt(secretKeysProd, key: encryptionKey, iv: encryptionIV);
  Log.d("$secretKeysProdEnc", lineLength: 912);

  secretKeysTest ??= '{...}';
  secretKeysTestEnc = AESCrypt.encrypt(secretKeysTest, key: encryptionKey, iv: encryptionIV);
  Log.d("$secretKeysTestEnc", lineLength: 912);
}*/
