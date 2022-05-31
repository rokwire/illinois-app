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


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/RoleGridButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class SettingsRolesContentWidget extends StatefulWidget {
  _SettingsRolesContentWidgetState createState() => _SettingsRolesContentWidgetState();
}

class _SettingsRolesContentWidgetState extends State<SettingsRolesContentWidget> {
  Set<UserRole>? _selectedRoles;

  Timer? _saveRolesTimer;

  @override
  void initState() {
    _selectedRoles = (Auth2().prefs?.roles != null) ? Set.from(Auth2().prefs!.roles!) : Set<UserRole>();
    super.initState();
  }

  @override
  void dispose() {
    if (_saveRolesTimer != null) {
      _stopSaveRolesTimer();
      Timer(Duration(microseconds: 300), () {
        _saveSelectedRoles();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          color: Styles().colors!.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    Localization().getStringEx('panel.onboarding.roles.label.description', 'Select all that apply'),
                    style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16, top: 8, right: 8, bottom: 0),
                child: RoleGridButton.gridFromFlexUI(selectedRoles: _selectedRoles, onTap: _onRoleGridButton),
              ),
            ],
          ),
        );
  }

  /*Widget _buildSaveButton(){
    return
        Padding(
            padding: EdgeInsets.symmetric( vertical: 20,horizontal: 16),
            child: RoundedButton(
              label: Localization().getStringEx("panel.profile_info.button.save.title", "Save Changes"),
              hint: Localization().getStringEx("panel.profile_info.button.save.hint", ""),
              enabled: _canSave,
              fontFamily: Styles().fontFamilies.bold,
              backgroundColor: Styles().colors.white,
              fontSize: 16.0,
              textColor: Styles().colors.fillColorPrimary,
              borderColor: Styles().colors.fillColorSecondary,
              onTap: _onSaveChangesClicked,
            ),
         );
  }*/

  void _onRoleGridButton(RoleGridButton? button) {

    if (button != null) {

      UserRole? role = (button.data is UserRole) ? (button.data as UserRole) : null;

      Analytics().logSelect(target: "Role: " + role.toString());

      if (role != null) {
        if (_selectedRoles!.contains(role)) {
          _selectedRoles!.remove(role);
        } else {
          _selectedRoles!.add(role);
        }
      }

      AppSemantics.announceCheckBoxStateChange(context, _selectedRoles!.contains(role), button.title);

      setState(() {});

      _startSaveRolesTimer();
    }
  }

  /*void _onBack() {
    if (_saveRolesTimer != null) {
      _saveSelectedRoles();
    }
    Navigator.pop(context);
  }*/

  //TBD clear up when sure that timer saving approach won't be needed
  void _startSaveRolesTimer() {
    _stopSaveRolesTimer();
    _saveRolesTimer = Timer(Duration(seconds: 3), () {
      _saveSelectedRoles();
    });
  }

  void _stopSaveRolesTimer() {
    if (_saveRolesTimer != null) {
      _saveRolesTimer!.cancel();
      _saveRolesTimer = null;
    }
  }

  void _saveSelectedRoles() {
    _stopSaveRolesTimer();
    Auth2().prefs?.roles = _selectedRoles;
  }

  /*_onSaveChangesClicked(){
    _saveSelectedRoles();
    Navigator.pop(context);
  }

  bool get _canSave{
    return _selectedRoles != User().roles ;
  }*/
}

