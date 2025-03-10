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

import 'package:flutter/material.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/RoleGridButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';

import 'Onboarding2Widgets.dart';

class Onboarding2RolesPanel extends StatefulWidget with Onboarding2Panel {
  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  Onboarding2RolesPanel({ this.onboardingCode = '', this.onboardingContext }) :
    super(key: GlobalKey<_Onboarding2RoleSelectionPanelState>());

  GlobalKey<_Onboarding2RoleSelectionPanelState>? get globalKey => (super.key is GlobalKey<_Onboarding2RoleSelectionPanelState>) ?
    (super.key as GlobalKey<_Onboarding2RoleSelectionPanelState>) : null;

  @override
  bool get onboardingProgress => (globalKey?.currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => globalKey?.currentState?.onboardingProgress = value;

  @override
  _Onboarding2RoleSelectionPanelState createState() => _Onboarding2RoleSelectionPanelState();
}

class _Onboarding2RoleSelectionPanelState extends State<Onboarding2RolesPanel> {
  Set<UserRole> _selectedRoles = <UserRole>{};
  bool get _allowNext => _selectedRoles.isNotEmpty;
  bool _onboardingProgress = false;

  @override
  void initState() {
    Set<UserRole>? userRoles = Auth2().prefs?.roles;
    if (userRoles != null) {
      _selectedRoles = Set.from(userRoles);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
    Scaffold(backgroundColor: Styles().colors.background, body:
      SafeArea(child:
        SwipeDetector(onSwipeLeft: _onboardingNext, onSwipeRight: _onboardingBack, child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Padding(padding: EdgeInsets.symmetric(vertical: 24), child:
              Row(children: <Widget>[
                Onboarding2BackButton(padding: const EdgeInsets.all(16), onTap: _onTapBack),
                Expanded(child:
                  Center(child:
                    Semantics(
                      label: Localization().getStringEx('panel.onboarding2.roles.label.title', 'Who Are You?').toLowerCase(),
                      hint: Localization().getStringEx('panel.onboarding2.roles.label.title.hint', 'Header 1').toLowerCase(),
                      excludeSemantics: true,
                      child: Text(Localization().getStringEx('panel.onboarding2.roles.label.title', 'Who Are You?'),
                        style: Styles().textStyles.getTextStyle("widget.title.extra_large.extra_fat"),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.only(left: 46),),
              ],),
            ),

            Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child:
              Text(Localization().getStringEx('panel.onboarding2.roles.label.description', 'Please check all that apply to create a personalized experience for you'),
                style: Styles().textStyles.getTextStyle("panel.onboarding2.roles.description"),
                textAlign: TextAlign.start,
              ),
            ),

            Padding(padding: EdgeInsets.only(bottom:  10, left: 20, right: 20), child:
              Text(Localization().getStringEx('panel.onboarding2.roles.label.description2', 'I am a...'),
                style: Styles().textStyles.getTextStyle("widget.title.medium.extra_fat"),
                textAlign: TextAlign.start,
              ),
            ),

            Expanded(child:
              SingleChildScrollView(child:
                Padding(padding: EdgeInsets.only(left: 16, right: 8, ), child:
                  RoleGridButton.gridFromFlexUI(selectedRoles: _selectedRoles, onTap: _onRoleGridButton, textScaler: MediaQuery.of(context).textScaler,)
                ),
              ),
            ),

            if (_allowNext)
              Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child:
                RoundedButton(
                  label: Localization().getStringEx('panel.onboarding2.roles.button.continue.title', 'Continue'),
                  hint: Localization().getStringEx('panel.onboarding2.roles.button.continue.hint', ''),
                  textStyle: _allowNext ? Styles().textStyles.getTextStyle("widget.button.title.medium.fat") : Styles().textStyles.getTextStyle("widget.button.disabled.title.medium.fat.variant"),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  enabled: _allowNext,
                  backgroundColor: (Styles().colors.white),
                  borderColor: (_allowNext ? Styles().colors.fillColorSecondary : Styles().colors.fillColorPrimaryTransparent03),
                  progress: _onboardingProgress,
                  onTap: _onTapContinue,
                ),
              )
          ],),
        ),
      ),
    );

  void _onRoleGridButton(RoleGridButton button) {
      Analytics().logSelect(target: "Role: ${button.role}");
      setState(() {
        if (_selectedRoles.contains(button.role) == true) {
          _selectedRoles.remove(button.role);
        } else {
          _selectedRoles.add(button.role);
        }
      });
  }

  void _onTapBack() {
    Analytics().logSelect(target: "Back");
    _onboardingBack();
  }

  void _onTapContinue() {
    Analytics().logSelect(target: "Continue");
    _onboardingNext();
  }

  // Onboarding

  bool get onboardingProgress => _onboardingProgress;
  set onboardingProgress(bool value) {
    setStateIfMounted(() {
      _onboardingProgress = value;
    });
  }

  void _onboardingBack() => Navigator.of(context).pop();
  void _onboardingNext() {
    if (_selectedRoles.isNotEmpty) {
      Auth2().prefs?.roles = _selectedRoles;
      Onboarding2().next(context, widget);
    }
  }
}
