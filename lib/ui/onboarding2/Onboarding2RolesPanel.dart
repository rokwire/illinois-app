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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/ui/widgets/SlantedWidget.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:neom/service/Onboarding2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/ui/widgets/RoleGridButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'Onboarding2Widgets.dart';

class Onboarding2RolesPanel extends StatefulWidget with Onboarding2Panel {
  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  Onboarding2RolesPanel({ this.onboardingCode = 'roles', this.onboardingContext });

  GlobalKey<_Onboarding2RoleSelectionPanelState>? get globalKey => (super.key is GlobalKey<_Onboarding2RoleSelectionPanelState>) ?
    (super.key as GlobalKey<_Onboarding2RoleSelectionPanelState>) : null;

  @override
  bool get onboardingProgress => (globalKey?.currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => globalKey?.currentState?.onboardingProgress = value;
  @override
  Future<bool> isOnboardingEnabled() async => !(ListUtils.contains(Auth2().prefs?.roles, UserRole.values) ?? false);

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
      SafeArea(
        child: Scaffold(
          backgroundColor: Styles().colors.background,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: kIsWeb ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(hint: Localization().getStringEx("common.heading.one.hint","Header 1"), header: true, child:
                  Onboarding2TitleWidget(),
                ),
                Padding(padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: Config().webContentMaxWidth),
                    child: Column(children: <Widget>[
                      Semantics(
                        label: Localization().getStringEx('panel.onboarding2.roles.label.title', 'WHO ARE YOU?').toLowerCase(),
                        hint: Localization().getStringEx('panel.onboarding2.roles.label.title.hint', 'Header 1').toLowerCase(),
                        excludeSemantics: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(Localization().getStringEx('panel.onboarding2.roles.label.title', 'WHO ARE YOU?'),
                            style: Styles().textStyles.getTextStyle('panel.onboarding2.roles.heading.title'),
                          ),
                        ),
                      ),
                      // Padding(padding: EdgeInsets.only(top: 8, left: 16.0, right: 16.0),
                      //   child: Text(Localization().getStringEx('panel.onboarding2.roles.label.description', 'Please check all that apply to create a personalized experience for you'),
                      //     style: Styles().textStyles.getTextStyle('widget.title.light.regular.thin'),
                      //   ),
                      // ),
                      Padding(
                        padding: EdgeInsets.only(top: 8, left: 16.0, right: 16.0),
                        child: Text(
                          Localization().getStringEx('panel.onboarding2.roles.label.description2', 'I am part of the following ERI Sector...'),
                          style: Styles().textStyles.getTextStyle("widget.title.medium.extra_fat"),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ],),
                  ),
                ),
            
                Padding(padding: EdgeInsets.only(left: 16, right: 8, ), child:
                  RoleGridButton.gridFromFlexUI(selectedRoles: _selectedRoles, onTap: _onRoleGridButton, textScaler: MediaQuery.of(context).textScaler,),
                ),
            
                Padding(padding: EdgeInsets.all(24), child:
                Container(
                  constraints: BoxConstraints(maxWidth: Config().webContentMaxWidth),
                  child: SlantedWidget(
                    color: _allowNext ? Styles().colors.fillColorSecondary : Styles().colors.textMedium,
                    child: RibbonButton(
                      label: Localization().getStringEx('panel.onboarding2.roles.button.continue.title', 'Continue'),
                      hint: Localization().getStringEx('panel.onboarding2.roles.button.continue.hint', ''),
                      textStyle: Styles().textStyles.getTextStyle("widget.button.light.title.large.fat"),
                      textAlign: TextAlign.center,
                      backgroundColor: _allowNext ? Styles().colors.fillColorSecondary : Styles().colors.textMedium,
                      progress: _onboardingProgress,
                      progressColor: Styles().colors.textLight,
                      onTap: _allowNext ? () => _onTapContinue() : null,
                      rightIconKey: null,
                    ),
                  ),
                ),
                )
              ],
            ),
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

  void _onboardingNext() {
    if (_selectedRoles.isNotEmpty) {
      Auth2().prefs?.roles = _selectedRoles;
      Onboarding2().next(context, widget);
    }
  }
}
