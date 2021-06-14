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
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/model/UserData.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/onboarding/onboarding2/Onboarding2PrivacyStatementPanel.dart';
import 'package:illinois/ui/widgets/RoleGridButton.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';

import 'Onboarding2Widgets.dart';

class Onboarding2RolesPanel extends StatefulWidget{
  final bool returningUser;

  Onboarding2RolesPanel({this.returningUser = false});

  @override
  _Onboarding2RoleSelectionPanelState createState() =>
      _Onboarding2RoleSelectionPanelState();
}

class _Onboarding2RoleSelectionPanelState extends State<Onboarding2RolesPanel> {
  Set<UserRole> _selectedRoles;
  bool _updating = false;

  bool get _allowNext => _selectedRoles != null && _selectedRoles.isNotEmpty;

  @override
  void initState() {
    _selectedRoles = User().roles ?? Set<UserRole>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double gridSpacing = 5;
    return Scaffold(
      backgroundColor: Styles().colors.background,
      body: SafeArea(child: Column( children: <Widget>[
        Container(
          color: Styles().colors.white,
          padding: EdgeInsets.only(top: 19, bottom: 19),
          child: Row(children: <Widget>[
            Onboarding2BackButton(padding: const EdgeInsets.only(left: 17,),
                onTap:() {
                  Analytics.instance.logSelect(target: "Back");
                  Navigator.pop(context);
                }),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
              Semantics(
                label: Localization().getStringEx('panel.onboarding2.roles.label.title', 'Who are you?').toLowerCase(),
                hint: Localization().getStringEx('panel.onboarding2.roles.label.title.hint', 'Header 1').toLowerCase(),
                excludeSemantics: true,
                child: Text(Localization().getStringEx('panel.onboarding2.roles.label.title', 'Who are you?'),
                  style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 24, color: Styles().colors.fillColorPrimary),
                ),
              ),
            ],),),
            Padding(padding: EdgeInsets.only(left: 42),),
          ],),
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 36, vertical: 6),
          child: Text(Localization().getStringEx('panel.onboarding2.roles.label.description', 'Select all that apply to help us understand who you are.'),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: Styles().fontFamilies.regular,
                fontSize: 16,
                color: Styles().colors.fillColorPrimary,
                height: 1.5
            ),
          ),
        ),
        Expanded(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.only(left: 16, right: 8, ), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(child: Column(children: <Widget>[
            RoleGridButton(
              title: Localization().getStringEx('panel.onboarding2.roles.button.student.title', 'University Student'),
              hint: Localization().getStringEx('panel.onboarding2.roles.button.student.hint', ''),
              iconPath: 'images/icon-persona-student-normal.png',
              selectedIconPath: 'images/icon-persona-student-selected.png',
              selectedBackgroundColor: Styles().colors.fillColorSecondary,
              selected: (_selectedRoles.contains(UserRole.student)),
              data: UserRole.student,
              sortOrder: 1,
              onTap: _onRoleGridButton,
            ),
            Container(height: gridSpacing,),
            RoleGridButton(
              title: Localization().getStringEx('panel.onboarding2.roles.button.fan.title', 'Athletics Fan'),
              hint: Localization().getStringEx('panel.onboarding2.roles.button.fan.hint', ''),
              iconPath: 'images/icon-persona-athletics-normal.png',
              selectedIconPath: 'images/icon-persona-athletics-selected.png',
              selectedBackgroundColor: Styles().colors.accentColor2,
              selected: _selectedRoles.contains(UserRole.fan),
              data: UserRole.fan,
              sortOrder: 3,
              onTap: _onRoleGridButton,
            ),
            Container(height: gridSpacing,),
            RoleGridButton(
              title: Localization().getStringEx('panel.onboarding2.roles.button.alumni.title', 'Alumni'),
              hint: Localization().getStringEx('panel.onboarding2.roles.button.alumni.hint', ''),
              iconPath: 'images/icon-persona-alumni-normal.png',
              selectedIconPath: 'images/icon-persona-alumni-selected.png',
              selectedBackgroundColor: Styles().colors.fillColorPrimary,
              selectedTextColor: Colors.white,
              selected:(_selectedRoles.contains(UserRole.alumni)),
              data: UserRole.alumni,
              sortOrder: 5,
              onTap: _onRoleGridButton,
            ),
            Container(height: gridSpacing,),
            RoleGridButton(
              title: Localization().getStringEx('panel.onboarding2.roles.button.resident.title', 'Resident'),
              hint: Localization().getStringEx('panel.onboarding2.roles.button.resident.hint', ''),
              iconPath: 'images/icon-persona-resident-normal.png',
              selectedIconPath: 'images/icon-persona-resident-selected.png',
              selectedBackgroundColor: Styles().colors.fillColorPrimary,
              selectedTextColor: Colors.white,
              selected:(_selectedRoles.contains(UserRole.resident)),
              data: UserRole.resident,
              sortOrder: 7,
              onTap: _onRoleGridButton,
            ),
          ],)),
          Container(width: gridSpacing,),
          Expanded(child: Column(children: <Widget>[
            RoleGridButton(
              title: Localization().getStringEx('panel.onboarding2.roles.button.visitor.title', 'Visitor'),
              hint: Localization().getStringEx('panel.onboarding2.roles.button.visitor.hint', ''),
              iconPath: 'images/icon-persona-visitor-normal.png',
              selectedIconPath: 'images/icon-persona-visitor-selected.png',
              selectedBackgroundColor: Styles().colors.fillColorSecondary,
              selected: (_selectedRoles.contains(UserRole.visitor)),
              data: UserRole.visitor,
              sortOrder: 2,
              onTap: _onRoleGridButton,
            ),
            Container(height: gridSpacing,),
            RoleGridButton(
              title: Localization().getStringEx('panel.onboarding2.roles.button.employee.title', 'University Employee'),
              hint: Localization().getStringEx('panel.onboarding2.roles.button.employee.hint', ''),
              iconPath: 'images/icon-persona-employee-normal.png',
              selectedIconPath: 'images/icon-persona-employee-selected.png',
              selectedBackgroundColor: Styles().colors.accentColor3,
              selected: (_selectedRoles.contains(UserRole.employee)),
              data: UserRole.employee,
              sortOrder: 4,
              onTap: _onRoleGridButton,
            ),
            Container(height: gridSpacing,),
            RoleGridButton(
              title: Localization().getStringEx('panel.onboarding2.roles.button.parent.title', 'Parent'),
              hint: Localization().getStringEx('panel.onboarding2.roles.button.parent.hint', ''),
              iconPath: 'images/icon-persona-parent-normal.png',
              selectedIconPath: 'images/icon-persona-parent-selected.png',
              selectedBackgroundColor: Styles().colors.fillColorSecondary,
              selected: (_selectedRoles.contains(UserRole.parent)),
              data: UserRole.parent,
              sortOrder: 6,
              onTap: _onRoleGridButton,
            ),

          ],),),
        ],),),),),
        !_allowNext? Container():
         Padding(padding: EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 20),
          child: Stack(children:<Widget>[
            ScalableRoundedButton(
                label: Localization().getStringEx('panel.onboarding2.roles.button.continue.title', 'Continue'),
                hint: Localization().getStringEx('panel.onboarding2.roles.button.continue.hint', ''),
                fontSize: 16,
                padding: EdgeInsets.symmetric(vertical: 12),
                enabled: _allowNext,
                backgroundColor: (Styles().colors.white),
                borderColor: (_allowNext
                    ? Styles().colors.fillColorSecondary
                    : Styles().colors.fillColorPrimaryTransparent03),
                textColor: (_allowNext
                    ? Styles().colors.fillColorPrimary
                    : Styles().colors.fillColorPrimaryTransparent03),
                onTap: () => _onGoNext()),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary),),),),),),
          ]),
        )

      ],),),
    );
  }

  void _onRoleGridButton(RoleGridButton button) {

    if (button != null) {

      UserRole role = button.data as UserRole;

      Analytics.instance.logSelect(target: "Role: " + role.toString());

      if (_selectedRoles.contains(role)) {
        _selectedRoles.remove(role);
      } else {
        _selectedRoles.add(role);
      }

      setState(() {});

    }
  }

  void _onGoNext() {
    Analytics.instance.logSelect(target:"Continue");
    if (_selectedRoles != null && _selectedRoles.isNotEmpty && !_updating) {
      User().roles = _selectedRoles;
      setState(() { _updating = true; });
      setState(() { _updating = false; });
      if(widget.returningUser){
        Onboarding2().proceedToLogin(context);
      } else {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2PrivacyStatementPanel()));
      }

    }
  }
}
