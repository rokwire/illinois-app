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
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/onboarding.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/RoleGridButton.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class OnboardingRolesPanel extends StatefulWidget with OnboardingPanel {
  final Map<String, dynamic>? onboardingContext;
  OnboardingRolesPanel({this.onboardingContext});

  @override
  _OnboardingRoleSelectionPanelState createState() =>
      _OnboardingRoleSelectionPanelState();
}

class _OnboardingRoleSelectionPanelState extends State<OnboardingRolesPanel> {
  Set<UserRole>? _selectedRoles;
  bool _updating = false;

  bool get _allowNext => _selectedRoles != null && _selectedRoles!.isNotEmpty;

  @override
  void initState() {
    _selectedRoles = (Auth2().prefs?.roles != null) ? Set.from(Auth2().prefs!.roles!) : Set<UserRole>();
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors!.white,
      body: SafeArea(child: Column( children: <Widget>[
        Padding(padding: EdgeInsets.only(top: 10, bottom: 10),
          child: Row(children: <Widget>[
            OnboardingBackButton(padding: const EdgeInsets.only(left: 10,),
              onTap:() {
                Analytics().logSelect(target: "Back");
                Navigator.pop(context);
              }),
            Expanded(child: Column(children: <Widget>[
              Semantics(
                label: Localization().getStringEx('panel.onboarding.roles.label.title', 'Who Are You?').toLowerCase(),
                hint: Localization().getStringEx('panel.onboarding.roles.label.title.hint', 'Header 1').toLowerCase(),
                excludeSemantics: true,
                child: Text(Localization().getStringEx('panel.onboarding.roles.label.title', 'Who Are You?'),
                  style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 24, color: Styles().colors!.fillColorPrimary),
                ),
              ),
              Padding(padding: EdgeInsets.only(top: 8),
                child: Text(Localization().getStringEx('panel.onboarding.roles.label.description', 'Please check all that apply to create a personalized experience for you'),
                  style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground),
                ),
              )
            ],),),
            Padding(padding: EdgeInsets.only(left: 42),),
          ],),
        ),

        Expanded(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.only(left: 16, right: 8, ), child:
          RoleGridButton.gridFromFlexUI(selectedRoles: _selectedRoles, onTap: _onRoleGridButton, scaleFactor: MediaQuery.of(context).textScaleFactor,),
        ),),),        

        Padding(padding: EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 20), child:
          RoundedButton(
            label: Localization().getStringEx('panel.onboarding.roles.button.continue.title', 'Explore Illinois'),
            hint: Localization().getStringEx('panel.onboarding.roles.button.continue.hint', ''),
            textStyle: _allowNext ? Styles().textStyles?.getTextStyle("widget.button.title.large.fat.secondary") : Styles().textStyles?.getTextStyle("widget.button.disabled.title.large.fat.variant"),
            enabled: _allowNext,
            backgroundColor: (Styles().colors!.background),
            borderColor: (_allowNext
                ? Styles().colors!.fillColorSecondary
                : Styles().colors!.fillColorPrimaryTransparent03),
            progress: _updating,
            onTap: () => _onExploreClicked()),
        )

      ],),),
    );
  }

  void _onRoleGridButton(RoleGridButton button) {

    if ((button.data is UserRole) && (_selectedRoles != null)) {

      UserRole role = button.data;

      Analytics().logSelect(target: "Role: $role" + role.toString());
      
        if (_selectedRoles!.contains(role)) {
          _selectedRoles!.remove(role);
        } else {
          _selectedRoles!.add(role);
        }

      setState(() {});

    }
  }

  void _onExploreClicked() {
    Analytics().logSelect(target:"Explore Illinois");
    if (_selectedRoles != null && _selectedRoles!.isNotEmpty && !_updating) {
      Auth2().prefs?.roles = _selectedRoles;
      setState(() { _updating = true; });
      FlexUI().update().then((_){
        if (mounted) {
          setState(() { _updating = false; });
          Onboarding().next(context, widget);
        }
      });
    }
  }
}
