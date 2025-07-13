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
import 'package:rokwire_plugin/utils/utils.dart';

import 'Onboarding2Widgets.dart';

class Onboarding2RolesPanel extends StatefulWidget with Onboarding2Panel {
  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  Onboarding2RolesPanel({ super.key, this.onboardingCode = '', this.onboardingContext });

  _Onboarding2RoleSelectionPanelState? get _currentState => JsonUtils.cast(globalKey?.currentState);

  @override
  bool get onboardingProgress => (_currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => _currentState?.onboardingProgress = value;

  @override
  State<StatefulWidget> createState() => _Onboarding2RoleSelectionPanelState();
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

            Expanded(child:
              SingleChildScrollView(child:
                Padding(padding: EdgeInsets.only(left: 16, right: 8, ), child:
                  RoleGridButtonGrid.fromFlexUI(
                    selectedRoles: _selectedRoles,
                    onTap: _onRoleGridButton,
                  )
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

  void _onRoleGridButton(UserRole role) {
    Analytics().logSelect(target: "Role: ${role}");
    setState(() {
      if (_selectedRoles.contains(role)) {
        _selectedRoles.remove(role);
      } else {
        _selectedRoles.add(role);
      }
    });
    AppSemantics.announceCheckBoxStateChange(context, _selectedRoles.contains(role), role.displayTitle);
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
