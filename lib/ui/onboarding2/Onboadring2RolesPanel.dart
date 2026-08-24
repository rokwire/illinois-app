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

import 'dart:collection';

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
  late LinkedHashSet<UserRole> _selectedRoles;
  bool _onboardingProgress = false;

  @override
  void initState() {
    Set<UserRole>? savedRoles = Auth2().prefs?.roles;
    _selectedRoles = (savedRoles != null) ? LinkedHashSet<UserRole>.from(savedRoles) : LinkedHashSet<UserRole>();
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
                Visibility(visible: Navigator.canPop(context), maintainSize: true, maintainAnimation: true, maintainState: true, child:
                  Onboarding2BackButton(padding: const EdgeInsets.all(16), onTap: _onTapBack),
                ),
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

            Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child:
              Column(mainAxisSize: MainAxisSize.min, children: [
                RoundedButton(
                  label: Localization().getStringEx('panel.onboarding2.roles.button.continue.title', 'Continue'),
                  hint: Localization().getStringEx('panel.onboarding2.roles.button.continue.hint', ''),
                  textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Styles().colors.white,
                  borderColor: Styles().colors.fillColorSecondary,
                  progress: _onboardingProgress,
                  onTap: _onTapContinue,
                ),
                Onboarding2UnderlinedButton(
                  title: Localization().getStringEx("panel.onboarding2.get_started.button.returning_user.title", "Returning user?"),
                  hint: Localization().getStringEx("panel.onboarding2.get_started.button.returning_user.hint", ""),
                  onTap: _onTapReturningUser,
                ),
              ],),
            )
          ],),
        ),
      ),
    );

  void _onRoleGridButton(UserRole role) {
    Analytics().logSelect(target: "Role: ${role}");
    int selectedCount = _selectedRoles.length;
    setState(() {
      UserRoleGroup.toggleSelection(_selectedRoles, role);
    });
    if (selectedCount != _selectedRoles.length) {
      AppSemantics.announceCheckBoxStateChange(context, _selectedRoles.contains(role), role.displayTitle);
    }
  }

  void _onTapBack() {
    Analytics().logSelect(target: "Back");
    _onboardingBack();
  }

  void _onTapContinue() {
    Analytics().logSelect(target: "Continue");
    _onboardingNext();
  }

  void _onTapReturningUser() {
    Analytics().logSelect(target: "Returning user?");
    Onboarding2().privacyReturningUser = true;
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
    Auth2().prefs?.roles = _selectedRoles;
    Onboarding2().next(context, widget);
  }
}
