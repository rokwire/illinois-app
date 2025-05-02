

import 'package:flutter/cupertino.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/onboarding2/Onboarding2LoginNetIdPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2LoginPhoneOrEmailStatementPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2PrivacyShareActivityPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2PrivacyStoreActivityPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnaireAcknowledgementPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnairePanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnairePromptPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2RolesPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2GetStartedPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2PrivacyLevelPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2PrivacyLocationServicesPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2PrivacyStatementPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ProfileInfoPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2VideoTutorialPanel.dart';
import 'package:illinois/ui/profile/ProfileLoginCodePanel.dart';
import 'package:illinois/ui/profile/ProfileLoginPasskeyPanel.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/ui/onboarding2/Onboarding2AuthNotificationsPanel.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Onboarding2 with Service, NotificationsListener {

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
  Map<String, GlobalKey<State<StatefulWidget>>> _panelKeys = <String, GlobalKey<State<StatefulWidget>>>{};

  @protected
  String get flexUIEntry => 'onboarding2';

  List<String> get _contentSource => FlexUI()[flexUIEntry]?.cast<String>() ?? <String>[];

  // Flow

  Widget? get first => _contentCodes.isNotEmpty ? Onboarding2Panel._fromCode(_contentCodes.first,
    context: {},
    panelKeys: _panelKeys,
  )?.asWidget : null;

  Future<void> next(BuildContext context, Onboarding2Panel panel) async {
    int index = _contentCodes.indexOf(panel.onboardingCode);
    while ((0 <= index) && ((index + 1) < _contentCodes.length)) {
      Onboarding2Panel? nextPanel = Onboarding2Panel._fromCode(_contentCodes[index + 1],
        context: panel.onboardingContext,
        panelKeys: _panelKeys,
      );
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

  // Public API
  String get onboardingCode => '';
  Onboarding2Context? get onboardingContext => null;

  Future<bool> isOnboardingEnabled() async => true;

  bool get onboardingProgress => false;
  set onboardingProgress(bool value) {}

  // Helpers
  Widget? get asWidget => JsonUtils.cast<Widget>(this);
  GlobalKey? get globalKey => JsonUtils.cast<GlobalKey>(this.asWidget?.key);

  // Creation
  static Onboarding2Panel? _fromCode(String code, { Onboarding2Context? context, Map<String, GlobalKey<State<StatefulWidget>>>? panelKeys }) {
    if (code == "get_started") {
      return Onboarding2GetStartedPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "video_tutorial") {
      return Onboarding2VideoTutorialPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "privacy_statement") {
      return Onboarding2PrivacyStatementPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "privacy_location_services") {
      return Onboarding2PrivacyLocationServicesPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "privacy_store_activity") {
      return Onboarding2PrivacyStoreActivityPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "privacy_share_activity") {
      return Onboarding2PrivacyShareActivityPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "privacy_level") {
      return Onboarding2PrivacyLevelPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "roles") {
      return Onboarding2RolesPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "notifications_auth") {
      return Onboarding2AuthNotificationsPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "login_netid") {
      return Onboarding2LoginNetIdPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "login_phone_or_email_statement") {
      return Onboarding2LoginPhoneOrEmailStatementPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == 'login_passkey') {
      return ProfileLoginPasskeyPanel(onboardingCode: code, onboardingContext: context);
    }
    else if (code == 'login_code') {
      return ProfileLoginCodePanel(onboardingCode: code, onboardingContext: context);
    }
    else if (code == "profile_info") {
      return Onboarding2ProfileInfoPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "research_questionnaire_participate_prompt") {
      return Onboarding2ResearchQuestionnairePromptPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "research_questionnaire") {
      return Onboarding2ResearchQuestionnairePanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else if (code == "research_questionnaire_acknowledgement") {
      return Onboarding2ResearchQuestionnaireAcknowledgementPanel(key: _panelKey(code, panelKeys), onboardingCode: code, onboardingContext: context,);
    }
    else {
      return null;
    }
  }

  static GlobalKey<State<StatefulWidget>>? _panelKey(String code, Map<String, GlobalKey<State<StatefulWidget>>>? panelKeys) =>
    (panelKeys != null) ? (panelKeys[code] ??= GlobalKey<State<StatefulWidget>>()) : null;

}

abstract class Onboarding2ProgressableState {
  bool get onboarding2Progress;
  set onboarding2Progress(bool progress);
}