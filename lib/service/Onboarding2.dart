

import 'package:flutter/cupertino.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/onboarding2/Onboarding2RolesPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2GetStartedPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2PrivacyLevelPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2PrivacyLocationServicesPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2PrivacyStatementPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ProfileInfoPanel.dart';
import 'package:illinois/ui/profile/ProfileLoginCodePanel.dart';
import 'package:illinois/ui/profile/ProfileLoginPasskeyPanel.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/ui/onboarding2/Onboarding2AuthNotificationsPanel.dart';

class Onboarding2 with Service implements NotificationsListener {

  static const String notifyFinished  = "edu.illinois.rokwire.onboarding.finished";

  // Singleton Factory
  Onboarding2._internal();
  static final Onboarding2 _instance = Onboarding2._internal();
  factory Onboarding2() => _instance;

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this,[
      FlexUI.notifyChanged,
    ]);
    super.createService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Future<void> initService() async {
    _contentCodes = List<String>.from(_contentSource);
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn => <Service>{ FlexUI() };

  // Notification Listener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _contentCodes = List<String>.from(_contentSource);
    }
  }

  // Content

  late List<String> _contentCodes;

  @protected
  String get flexUIEntry => 'onboarding2';

  List<String> get _contentSource => FlexUI()[flexUIEntry]?.cast<String>() ?? <String>[];

  // Flow

  Widget? get first => _contentCodes.isNotEmpty ? Onboarding2Panel._fromCode(_contentCodes.first, context: {})?.asWidget : null;

  Future<void> next(BuildContext context, Onboarding2Panel panel) async {
    int index = _contentCodes.indexOf(panel.onboardingCode);
    while ((0 <= index) && ((index + 1) < _contentCodes.length)) {
      Onboarding2Panel? nextPanel = Onboarding2Panel._fromCode(_contentCodes[index + 1], context: panel.onboardingContext);
      Widget? nextWidget = nextPanel?.asWidget;
      if ((nextPanel != null) && (nextWidget != null)) {
        if (panel.onboardingProgress != true) {
          panel.onboardingProgress = true;
        }
        if (await nextPanel.isOnboardingEnabled()) {
          panel.onboardingProgress = false;
          if (context.mounted) {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => nextWidget));
            return;
          }
        }
      }
      index++;
    }
    if (panel.onboardingProgress != true) {
      panel.onboardingProgress = false;
    }
    if (context.mounted) {
      NotificationService().notify(notifyFinished, context);;
    }
  }

  // Privacy Selection

  bool get privacyReturningUser => Storage().onBoarding2PrivacyReturningUser == true;
  set privacyReturningUser(bool value) => Storage().onBoarding2PrivacyReturningUser = value;

  bool get privacyLocationServicesSelection => Storage().onBoarding2PrivacyLocationServicesSelection == true;
  set privacyLocationServicesSelection(bool value) => Storage().onBoarding2PrivacyLocationServicesSelection = value;

  bool get privacyStoreActivitySelection => Storage().onBoarding2PrivacyStoreActivitySelection == true;
  set privacyStoreActivitySelection(bool value) => Storage().onBoarding2PrivacyStoreActivitySelection = value;

  bool get  privacyShareActivitySelection => Storage().onBoarding2PrivacyShareActivitySelection == true;
  set privacyShareActivitySelection(bool value) => Storage().onBoarding2PrivacyShareActivitySelection = value;
}

typedef Onboarding2Context = Map<String, dynamic>;

class Onboarding2Panel {
  String get onboardingCode => '';
  Onboarding2Context? get onboardingContext => null;

  Future<bool> isOnboardingEnabled() async => true;

  Widget? get asWidget => (this is Widget) ? (this as Widget) : null;

  bool get onboardingProgress => false;
  set onboardingProgress(bool value) {}

  static Onboarding2Panel? _fromCode(String code, { Onboarding2Context? context }) {
    if (code == "get_started") {
      return Onboarding2GetStartedPanel(onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "privacy_statement") {
      return Onboarding2PrivacyStatementPanel(onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "privacy_level") {
      return Onboarding2PrivacyLevelPanel(onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "privacy_location_services") {
      return Onboarding2PrivacyLocationServicesPanel(onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "notifications_auth") {
      return Onboarding2AuthNotificationsPanel(onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "roles") {
      return Onboarding2RolesPanel(onboardingCode: code, onboardingContext: context,);
    }
    else if (code == 'login_passkey') {
      return ProfileLoginPasskeyPanel(onboardingCode: code, onboardingContext: context);
    }
    else if (code == 'login_code') {
      return ProfileLoginCodePanel(onboardingCode: code, onboardingContext: context);
    }
    else if (code == 'profile_info') {
      return Onboarding2ProfileInfoPanel(onboardingCode: code, onboardingContext: context);
    }
    else {
      return null;
    }
  }

}

abstract class Onboarding2ProgressableState {
  bool get onboarding2Progress;
  set onboarding2Progress(bool progress);
}