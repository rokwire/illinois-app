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

class ProfileRolesPage extends StatefulWidget {
  final EdgeInsetsGeometry margin;

  ProfileRolesPage({super.key, this.margin = const EdgeInsets.all(16) });

  @override
  _ProfileRolesPageState createState() => _ProfileRolesPageState();
}

class _ProfileRolesPageState extends State<ProfileRolesPage> {
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
    return Container(color: Styles().colors.background, padding: widget.margin,  child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.only(top: 16, left: 4, right: 4), child:
          Text(Localization().getStringEx('panel.onboarding.roles.label.description', 'Please check all that apply to create a personalized experience for you'),
            style: Styles().textStyles.getTextStyle("widget.item.small.thin")
          ),
        ),
        Padding(padding: EdgeInsets.only(top: 10,  left: 4, right: 4), child:
          Text(Localization().getStringEx('panel.onboarding.roles.label.description2', 'I am a...'),
            style: Styles().textStyles.getTextStyle("widget.title.medium.extra_fat")
          ),
        ),
        Padding(padding: EdgeInsets.only(left: 0, top: 8, right: 8, bottom: 0), child:
          RoleGridButton.gridFromFlexUI(selectedRoles: _selectedRoles, onTap: _onRoleGridButton, textScaler: MediaQuery.of(context).textScaler,),
        ),
      ],),
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

