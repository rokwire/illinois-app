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
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/IlliniAppDateTime.dart';
import 'package:illinois/service/Assets.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/IlliniDeepLink.dart';
import 'package:illinois/service/DeviceCalendar.dart';
import 'package:illinois/service/DiningService.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/GeoFence.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/HttpProxy.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/service/Inbox.dart';
import 'package:illinois/service/LiveStats.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Onboarding.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Polls.dart';
import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/service/IlliniServices.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Voter.dart';
import 'package:illinois/ui/onboarding/OnboardingErrorPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingUpgradePanel.dart';

import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/ui/RootPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2GetStartedPanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/widgets/FlexContentWidget.dart';
import 'package:illinois/service/Styles.dart';

import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/app_navigation.dart';
import 'package:rokwire_plugin/service/firebase_core.dart';
import 'package:rokwire_plugin/service/firebase_crashlytics.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/utils/utils.dart';


final AppExitListener appExitListener = AppExitListener();

void main() async {

  // https://stackoverflow.com/questions/57689492/flutter-unhandled-exception-servicesbinding-defaultbinarymessenger-was-accesse
  WidgetsFlutterBinding.ensureInitialized();

  String? platformVersion = await RokwirePlugin.platformVersion;
  Log.d("RokwirePlugin.platformVersion: $platformVersion");

  NotificationService().subscribe(appExitListener, AppLivecycle.notifyStateChanged);

  IlliniServices().create([
    // Add highest priority services at top

    FirebaseCore(),
    FirebaseCrashlytics(),
    AppLivecycle(),
    IlliniAppDateTime(),
    Connectivity(),
    LocationServices(),
    IlliniDeepLink(),

    Storage(),
    HttpProxy(),

    Config(),
    NativeCommunicator(),

    Auth2(),
    Localization(),
    Assets(),
    Styles(),
    Analytics(),
    FirebaseMessaging(),
    Sports(),
    LiveStats(),
    RecentItems(),
    DiningService(),
    IlliniCash(),
    FlexUI(),
    Onboarding(),
    Polls(),
    GeoFence(),
    Voter(),
    Guide(),
    Inbox(),
    DeviceCalendar(),
    ExploreService(),
    Groups(),
    Canvas()

    // These do not rely on Service initialization API so they are not registered as services.
    // LaundryService(),
    // Content(),
  ]);
  
  ServiceError? serviceError = await IlliniServices().init();

  // do not show the red error widget when release mode
  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) => Container();
  }

  // Log app create analytics event
  Analytics().logLivecycle(name: Analytics.LogLivecycleEventCreate);

  runZonedGuarded(() async {
    runApp(App(initializeError: serviceError));
  }, FirebaseCrashlytics().handleZoneError);
}

class AppExitListener implements NotificationsListener {
  
  // NotificationsListener
  @override
  void onNotification(String name, param) {
    if ((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.detached)) {
      Future.delayed(Duration(), () {
        NotificationService().unsubscribe(appExitListener);
        IlliniServices().destroy();
      });
    }
  }
}

class _AppData {
  _AppState? _panelState;
  BuildContext? _homeContext;
}

class App extends StatefulWidget {

  final _AppData _data = _AppData();
  final ServiceError? initializeError;
  static App? _instance;

  App({this.initializeError}) {
    _instance = this;
  }

  static get instance {
    return _instance;
  }

  get panelState {
    return _data._panelState;
  }

  @override
  _AppState createState() {
    _AppState appState = _AppState();
    if ((_data._homeContext != null) && (_data._panelState == null)) {
      _presentLaunchPopup(appState, _data._homeContext);
    }
    return _data._panelState = appState;
  }

  BuildContext? get homeContext {
    return _data._homeContext;
  }

  set homeContext(BuildContext? context) {
    if ((_data._homeContext == null) && (_data._panelState != null)) {
      _presentLaunchPopup(_data._panelState, context);
    }
    _data._homeContext = context;
  }

  void _presentLaunchPopup(_AppState? appState, BuildContext? context) {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      appState!._presentLaunchPopup(context);
    });
  }
}

class _AppState extends State<App> implements NotificationsListener {

  Key _key = UniqueKey();
  String? _lastRunVersion;
  String? _upgradeRequiredVersion;
  String? _upgradeAvailableVersion;
  Widget? _launchPopup;
  ServiceError? _initializeError;
  Future<ServiceError?>? _retryInitialzeFuture;
  DateTime? _pausedDateTime;
  RootPanel? rootPanel;

  @override
  void initState() {
    Log.d("App UI initialized");

    NotificationService().subscribe(this, [
      Onboarding2.notifyFinished,
      Config.notifyUpgradeAvailable,
      Config.notifyUpgradeRequired,
      Config.notifyOnboardingRequired,
      Storage.notifySettingChanged,
      Auth2.notifyUserDeleted,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      AppLivecycle.notifyStateChanged,
    ]);

    rootPanel = RootPanel();
    _initializeError = widget.initializeError;

    _lastRunVersion = Storage().lastRunVersion;
    _upgradeRequiredVersion = Config().upgradeRequiredVersion;
    _upgradeAvailableVersion = Config().upgradeAvailableVersion;

    _checkForceOnboarding();

    if ((_lastRunVersion == null) || (_lastRunVersion != Config().appVersion)) {
      Storage().lastRunVersion = Config().appVersion;
    }

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      NativeCommunicator().dismissLaunchScreen();
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
    return MaterialApp(
      key: _key,
      localizationsDelegates: [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: Localization().supportedLocales(),
      navigatorObservers:[AppNavigation()],
      //onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      title: Localization().getStringEx('app.title', 'Illinois')!,
      theme: ThemeData(
          appBarTheme: AppBarTheme(backgroundColor: Styles().colors?.fillColorPrimaryVariant ?? Color(0xFF0F2040)),
          primaryColor: Styles().colors?.fillColorPrimaryVariant ?? Color(0xFF0F2040),
          fontFamily: Styles().fontFamilies?.extraBold ?? 'ProximaNovaExtraBold'),
      home: _homePanel,
    );
  }

  Widget? get _homePanel {
    if (_initializeError != null) {
      return OnboardingErrorPanel(error: _initializeError, retryHandler: _retryInitialze);
    }
    if (_upgradeRequiredVersion != null) {
      return OnboardingUpgradePanel(requiredVersion:_upgradeRequiredVersion);
    }
    else if (_upgradeAvailableVersion != null) {
      return OnboardingUpgradePanel(availableVersion:_upgradeAvailableVersion);
    }
    else if (!Storage().onBoardingPassed!) {
      return Onboarding2GetStartedPanel();
    }
    else if ((Storage().privacyUpdateVersion == null) || (AppVersion.compareVersions(Storage().privacyUpdateVersion, Config().appPrivacyVersion) < 0)) {
      return SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.update,);
    }
    else if (Auth2().prefs?.privacyLevel == null) {
      return SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.update,); // regular?
    }
    else {
      return rootPanel;
    }
  }

  void _resetUI() async {
    this.setState(() {
      rootPanel = RootPanel();
      _key = UniqueKey();
    });
  }

  void _finishOnboarding(BuildContext context) {
    Storage().onBoardingPassed = true;
    Route routeToHome = CupertinoPageRoute(builder: (context) => rootPanel!);
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
      _retryInitialzeFuture = IlliniServices().init();
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

  void _presentLaunchPopup(BuildContext? context) {
    if ((_launchPopup == null) && (context != null)) {
      dynamic launch = FlexUI()['launch'];
      List<dynamic>? launchList = (launch is List) ? launch : null;
      if (launchList != null) {
        for (dynamic launchEntry in launchList) {
          Widget? launchPopup = FlexContentWidget.fromAssets(launchEntry, onClose: (BuildContext context) {
            _launchPopup = null;
            Navigator.of(context).pop();
          },);
          if (launchPopup != null) {
            _launchPopup = launchPopup;
            showDialog(context: context, builder: (BuildContext context) {
              return Dialog(child:
                Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  launchPopup
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
    else if (name == Auth2.notifyUserDeleted) {
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
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
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
          _presentLaunchPopup(App.instance.homeContext);
        }
      }
    }
  }
}

