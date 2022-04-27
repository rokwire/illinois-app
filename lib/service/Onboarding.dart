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

import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/service/onboarding.dart' as rokwire;
import 'package:illinois/ui/onboarding/OnboardingLoginPhoneConfirmPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingGetStartedPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingAuthLocationPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingLoginNetIdPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingLoginPhonePanel.dart';
import 'package:illinois/ui/onboarding/OnboardingAuthNotificationsPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingPrivacyStatementPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingRolesPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingSportPrefsPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingLoginPhoneVerifyPanel.dart';
import 'package:illinois/ui/settings/SettingsNewPrivacyPanel.dart';

class Onboarding extends rokwire.Onboarding  {

  static String get notifyFinished => rokwire.Onboarding.notifyFinished;

  // Singletone Factory

  @protected
  Onboarding.internal() : super.internal();

  factory Onboarding() => ((rokwire.Onboarding.instance is Onboarding) ? (rokwire.Onboarding.instance as Onboarding) : (rokwire.Onboarding.instance = Onboarding.internal()));

  // Overrides

  @override
  rokwire.OnboardingPanel? createPanel({String? code, Map<String, dynamic>? context}) {
    if (code == 'get_started') {
      return OnboardingGetStartedPanel(onboardingContext: context);
    }
    else if (code == 'privacy_statement') {
      return OnboardingPrivacyStatementPanel(onboardingContext: context);
    }
    else if (code == 'privacy') {
      return SettingsNewPrivacyPanel(mode: SettingsPrivacyPanelMode.onboarding, onboardingContext: context);
    }
    else if (code == 'notifications_auth') {
      return OnboardingAuthNotificationsPanel(onboardingContext: context);
    }
    else if (code == 'location_auth') {
      return OnboardingAuthLocationPanel(onboardingContext: context);
    }
    else if (code == 'roles') {
      return OnboardingRolesPanel(onboardingContext: context);
    }
    else if (code == 'login_netid') {
      return OnboardingLoginNetIdPanel(onboardingContext: context);
    }
    else if (code == 'login_phone') {
      return OnboardingLoginPhonePanel(onboardingContext: context);
    }
    else if (code == 'verify_phone') {
      return OnboardingLoginPhoneVerifyPanel(onboardingContext: context);
    }
    else if (code == 'confirm_phone') {
      return OnboardingLoginPhoneConfirmPanel(onboardingContext: context);
    }
    else if (code == 'sport_prefs') {
      return OnboardingSportPrefsPanel(onboardingContext: context);
    }
    else {
      return null;
    }
  }

  @override
  String? getPanelCode({rokwire.OnboardingPanel? panel}) {
    if (panel is OnboardingGetStartedPanel) {
      return 'get_started';
    }
    else if (panel is OnboardingPrivacyStatementPanel) {
      return 'privacy_statement';
    }
    else if (panel is SettingsNewPrivacyPanel) {
      return 'privacy';
    }
    else if (panel is OnboardingAuthNotificationsPanel) {
      return 'notifications_auth';
    }
    else if (panel is OnboardingAuthLocationPanel) {
      return 'location_auth';
    }
    else if (panel is OnboardingRolesPanel) {
      return 'roles';
    }
    else if (panel is OnboardingLoginNetIdPanel) {
      return 'login_netid';
    }
    else if (panel is OnboardingLoginPhonePanel) {
      return 'login_phone';
    }
    else if (panel is OnboardingLoginPhoneVerifyPanel) {
      return 'verify_phone';
    }
    else if (panel is OnboardingLoginPhoneConfirmPanel) {
      return 'confirm_phone';
    }
    else if (panel is OnboardingSportPrefsPanel) {
      return 'sport_prefs';
    }
    return null;
  }

}
