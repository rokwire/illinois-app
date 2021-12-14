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
import 'package:flutter/material.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Onboarding.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/RoleGridButton.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';

class OnboardingRolesPanel extends StatefulWidget with OnboardingPanel {
  final Map<String, dynamic>? onboardingContext;
  OnboardingRolesPanel({this.onboardingContext});

  @override
  _OnboardingRoleSelectionPanelState createState() =>
      _OnboardingRoleSelectionPanelState();
}

class _OnboardingRoleSelectionPanelState extends State<OnboardingRolesPanel> {
  Set<UserRole?>? _selectedRoles;
  bool _updating = false;

  bool get _allowNext => _selectedRoles != null && _selectedRoles!.isNotEmpty;

  @override
  void initState() {
    _selectedRoles = (Auth2().prefs?.roles != null) ? Set.from(Auth2().prefs!.roles!) : Set<UserRole>();
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    final double gridSpacing = 5;
    return Scaffold(
      backgroundColor: Styles().colors!.white,
      body: SafeArea(child: Column( children: <Widget>[
        Padding(padding: EdgeInsets.only(top: 10, bottom: 10),
          child: Row(children: <Widget>[
            OnboardingBackButton(padding: const EdgeInsets.only(left: 10,),
              onTap:() {
                Analytics.instance.logSelect(target: "Back");
                Navigator.pop(context);
              }),
            Expanded(child: Column(children: <Widget>[
              Semantics(
                label: Localization().getStringEx('panel.onboarding.roles.label.title', 'Who are you?')!.toLowerCase(),
                hint: Localization().getStringEx('panel.onboarding.roles.label.title.hint', 'Header 1')!.toLowerCase(),
                excludeSemantics: true,
                child: Text(Localization().getStringEx('panel.onboarding.roles.label.title', 'Who are you?')!,
                  style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 24, color: Styles().colors!.fillColorPrimary),
                ),
              ),
              Padding(padding: EdgeInsets.only(top: 8),
                child: Text(Localization().getStringEx('panel.onboarding.roles.label.description', 'Select all that apply')!,
                  style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground),
                ),
              )
            ],),),
            Padding(padding: EdgeInsets.only(left: 42),),
          ],),
        ),

        Expanded(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.only(left: 16, right: 8, ), child:
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Expanded(child: Column(children: <Widget>[
                  RoleGridButton(
                    title: Localization().getStringEx('panel.onboarding.roles.button.student.title', 'University Student'),
                    hint: Localization().getStringEx('panel.onboarding.roles.button.student.hint', ''),
                    iconPath: 'images/icon-persona-student-normal.png',
                    selectedIconPath: 'images/icon-persona-student-selected.png',
                    selectedBackgroundColor: Styles().colors!.fillColorSecondary,
                    selected: (_selectedRoles!.contains(UserRole.student)),
                    data: UserRole.student,
                    sortOrder: 1,
                    onTap: _onRoleGridButton,
                  ),
                  Container(height: gridSpacing,),
                  RoleGridButton(
                    title: Localization().getStringEx('panel.onboarding.roles.button.fan.title', 'Athletics Fan'),
                    hint: Localization().getStringEx('panel.onboarding.roles.button.fan.hint', ''),
                    iconPath: 'images/icon-persona-athletics-normal.png',
                    selectedIconPath: 'images/icon-persona-athletics-selected.png',
                    selectedBackgroundColor: Styles().colors!.accentColor2,
                    selected: _selectedRoles!.contains(UserRole.fan),
                    data: UserRole.fan,
                    sortOrder: 3,
                    onTap: _onRoleGridButton,
                  ),
                  Container(height: gridSpacing,),
                  RoleGridButton(
                    title: Localization().getStringEx('panel.onboarding.roles.button.alumni.title', 'Alumni'),
                    hint: Localization().getStringEx('panel.onboarding.roles.button.alumni.hint', ''),
                    iconPath: 'images/icon-persona-alumni-normal.png',
                    selectedIconPath: 'images/icon-persona-alumni-selected.png',
                    selectedBackgroundColor: Styles().colors!.fillColorPrimary,
                    selectedTextColor: Colors.white,
                    selected:(_selectedRoles!.contains(UserRole.alumni)),
                    data: UserRole.alumni,
                    sortOrder: 5,
                    onTap: _onRoleGridButton,
                  ),
                  Container(height: gridSpacing,),
                  RoleGridButton(
                    title: Localization().getStringEx('panel.onboarding.roles.button.resident.title', 'Resident'),
                    hint: Localization().getStringEx('panel.onboarding.roles.button.resident.hint', ''),
                    iconPath: 'images/icon-persona-resident-normal.png',
                    selectedIconPath: 'images/icon-persona-resident-selected.png',
                    selectedBackgroundColor: Styles().colors!.fillColorPrimary,
                    selectedTextColor: Colors.white,
                    selected:(_selectedRoles!.contains(UserRole.resident)),
                    data: UserRole.resident,
                    sortOrder: 7,
                    onTap: _onRoleGridButton,
                  ),
                ],)),
              Container(width: gridSpacing,),
              Expanded(child: Column(children: <Widget>[
                  RoleGridButton(
                    title: Localization().getStringEx('panel.onboarding.roles.button.visitor.title', 'Visitor'),
                    hint: Localization().getStringEx('panel.onboarding.roles.button.visitor.hint', ''),
                    iconPath: 'images/icon-persona-visitor-normal.png',
                    selectedIconPath: 'images/icon-persona-visitor-selected.png',
                    selectedBackgroundColor: Styles().colors!.fillColorSecondary,
                    selected: (_selectedRoles!.contains(UserRole.visitor)),
                    data: UserRole.visitor,
                    sortOrder: 2,
                    onTap: _onRoleGridButton,
                  ),
                  Container(height: gridSpacing,),
                  RoleGridButton(
                    title: Localization().getStringEx('panel.onboarding.roles.button.employee.title', 'University Employee'),
                    hint: Localization().getStringEx('panel.onboarding.roles.button.employee.hint', ''),
                    iconPath: 'images/icon-persona-employee-normal.png',
                    selectedIconPath: 'images/icon-persona-employee-selected.png',
                    selectedBackgroundColor: Styles().colors!.accentColor3,
                    selected: (_selectedRoles!.contains(UserRole.employee)),
                    data: UserRole.employee,
                    sortOrder: 4,
                    onTap: _onRoleGridButton,
                  ),
                  Container(height: gridSpacing,),
                  RoleGridButton(
                    title: Localization().getStringEx('panel.onboarding.roles.button.parent.title', 'Parent'),
                    hint: Localization().getStringEx('panel.onboarding.roles.button.parent.hint', ''),
                    iconPath: 'images/icon-persona-parent-normal.png',
                    selectedIconPath: 'images/icon-persona-parent-selected.png',
                    selectedBackgroundColor: Styles().colors!.fillColorSecondary,
                    selected: (_selectedRoles!.contains(UserRole.parent)),
                    data: UserRole.parent,
                    sortOrder: 6,
                    onTap: _onRoleGridButton,
                  ),
                  Container(height: gridSpacing,),
                  RoleGridButton(
                    title: Localization().getStringEx('panel.onboarding.roles.button.gies.title', 'GIES Student'),
                    hint: Localization().getStringEx('panel.onboarding.roles.button.gies.hint', ''),
                    iconPath: 'images/icon-persona-alumni-normal.png',
                    selectedIconPath: 'images/icon-persona-alumni-selected.png',
                    selectedBackgroundColor: Styles().colors!.fillColorPrimary,
                    selectedTextColor: Colors.white,
                    selected:(_selectedRoles!.contains(UserRole.gies)),
                    data: UserRole.gies,
                    sortOrder: 8,
                    onTap: _onRoleGridButton,
                  ),
                ],),),
              ],),),),),        

        Padding(padding: EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 20),
          child: Stack(children:<Widget>[
            ScalableRoundedButton(
              label: Localization().getStringEx('panel.onboarding.roles.button.continue.title', 'Explore Illinois'),
              hint: Localization().getStringEx('panel.onboarding.roles.button.continue.hint', ''),
              enabled: _allowNext,
              backgroundColor: (Styles().colors!.background),
              borderColor: (_allowNext
                  ? Styles().colors!.fillColorSecondary
                  : Styles().colors!.fillColorPrimaryTransparent03),
              textColor: (_allowNext
                  ? Styles().colors!.fillColorPrimary
                  : Styles().colors!.fillColorPrimaryTransparent03),
              onTap: () => _onExploreClicked()),
            Visibility(
              visible: _updating,
              child: Container(
                height: 48, 
                child: Align(
                  alignment:Alignment.center,
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorPrimary),),),),),),
          ]),
        )

      ],),),
    );
  }

  void _onRoleGridButton(RoleGridButton button) {

    if (button != null) {

      UserRole? role = button.data as UserRole?;

      Analytics.instance.logSelect(target: "Role: " + role.toString());
      
        if (_selectedRoles!.contains(role)) {
          _selectedRoles!.remove(role);
        } else {
          _selectedRoles!.add(role);
        }

      setState(() {});

    }
  }

  void _onExploreClicked() {
    Analytics.instance.logSelect(target:"Explore Illinois");
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
