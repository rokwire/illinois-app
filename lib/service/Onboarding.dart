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
import 'package:neom/ui/profile/ProfileLoginCodePanel.dart';
import 'package:neom/ui/profile/ProfileLoginPasskeyPanel.dart';
import 'package:rokwire_plugin/service/onboarding.dart' as rokwire;
import 'package:neom/ui/onboarding/OnboardingGetStartedPanel.dart';
import 'package:neom/ui/onboarding/OnboardingAuthLocationPanel.dart';
import 'package:neom/ui/onboarding/OnboardingAuthNotificationsPanel.dart';
import 'package:neom/ui/onboarding/OnboardingPrivacyStatementPanel.dart';
import 'package:neom/ui/onboarding/OnboardingRolesPanel.dart';
import 'package:neom/ui/settings/SettingsPrivacyPanel.dart';

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
      return SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.onboarding, onboardingContext: context);
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
    else if (code == 'login_passkey') {
      return ProfileLoginPasskeyPanel(onboardingContext: context);
    }
    else if (code == 'login_code') {
      return ProfileLoginCodePanel(onboardingContext: context);
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
    else if (panel is SettingsPrivacyPanel) {
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
    else if (panel is ProfileLoginPasskeyPanel) {
      return 'login_passkey';
    }
    else if (panel is ProfileLoginCodePanel) {
      return 'login_code';
    }
    return null;
  }

}
