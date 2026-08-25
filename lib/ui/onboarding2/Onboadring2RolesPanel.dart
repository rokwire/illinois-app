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
      SwipeDetector(onSwipeLeft: _onboardingNext, onSwipeRight: _onboardingBack, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(
            decoration: BoxDecoration(gradient: LinearGradient(
              begin: const Alignment(-0.2, -1.0), end: const Alignment(0.2, 1.0),
              colors: [
                Styles().colors.getColor('onboarding2RolesHeaderGradientStart') ?? const Color(0xFFFF5F05),
                Styles().colors.getColor('onboarding2RolesHeaderGradientEnd') ?? const Color(0xFFC74300),
              ],
              stops: const [0.3901, 0.8467],
            )),
            child: SafeArea(bottom: false, child:
              Column(children: <Widget>[
                Align(alignment: Alignment.topLeft, child:
                  Visibility(visible: _isFirst, child:
                    Onboarding2BackButton(padding: const EdgeInsets.all(16), imageColor: Styles().colors.white, onTap: _onTapBack),
                  ),
                ),
                Container(height: 8,),
                Styles().images.getImage('university-logo-dark', excludeFromSemantics: true) ?? Container(),
                Container(height: 10,),
                Semantics(
                  label: _welcomeTitle,
                  hint: Localization().getStringEx("common.heading.one.hint","Header 1"),
                  header: true,
                  excludeSemantics: true,
                  child: Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
                    Text(_welcomeTitle, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.heading.extra_large.fat")),
                  ),
                ),
                Container(height: 8,),
                Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
                  Text(_welcomeDescription, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.heading.regular")),
                ),
                Container(height: 12,),
                Text(_checkAllLabel, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.dialog.message.small")),
                Container(height: 16,),
              ],),
            ),
          ),

          Expanded(child:
            Column(children: <Widget>[
              Expanded(child:
                SafeArea(top: false, bottom: false, child:
                  SingleChildScrollView(child:
                    Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 24), child:
                      RoleGridButtonGrid.fromFlexUI(
                        selectedRoles: _selectedRoles,
                        showLabel: false,
                        onTap: _onRoleGridButton,
                      )
                    ),
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(color: Styles().colors.white, boxShadow: const [
                  BoxShadow(color: Color(0x12000000), offset: Offset(0, -4), blurRadius: 4),
                ]),
                child: SafeArea(top: false, child:
                  Padding(padding: EdgeInsets.only(left: 18, right: 18, top: 24), child:
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      RoundedButton(
                        label: Localization().getStringEx('panel.onboarding2.roles.button.continue.title', 'Continue'),
                        hint: Localization().getStringEx('panel.onboarding2.roles.button.continue.hint', ''),
                        textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: Styles().colors.white,
                        borderColor: Styles().colors.fillColorSecondary,
                        progress: _onboardingProgress,
                        onTap: _onboardingNext,
                      ),
                      Onboarding2UnderlinedButton(
                        title: Localization().getStringEx("panel.onboarding2.get_started.button.returning_user.title", "Returning user?"),
                        hint: Localization().getStringEx("panel.onboarding2.get_started.button.returning_user.hint", ""),
                        padding: const EdgeInsets.only(top: 8),
                        onTap: () => _onboardingNext(returningUser: true),
                      ),
                    ],),
                  ),
                ),
              )
            ],),
          ),
        ],),
      ),
    );

  String get _welcomeTitle => Localization().getStringEx('panel.onboarding2.roles.label.welcome.title', 'Welcome to the Illinois App');
  String get _welcomeDescription => Localization().getStringEx('panel.onboarding2.roles.label.welcome.description', 'From the Quad to Gies Memorial Stadium and beyond, the Illinois app connects you to campus.');
  String get _checkAllLabel => Localization().getStringEx('panel.onboarding2.roles.label.check_all.title', 'Check all that apply.');

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

  // Onboarding

  bool get onboardingProgress => _onboardingProgress;
  set onboardingProgress(bool value) {
    setStateIfMounted(() {
      _onboardingProgress = value;
    });
  }

  void _onboardingBack() => Navigator.of(context).pop();

  void _onboardingNext({bool returningUser = false}) async {
    Analytics().logSelect(target: returningUser ? "Returning user?" : "Continue");
    Onboarding2().privacyReturningUser = returningUser;
    Auth2().prefs?.roles = _selectedRoles;
    Onboarding2().next(context, widget);
  }

  bool get _isFirst => (widget.asWidget == Onboarding2().first);
}
