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
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/ui/widgets/tile_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class RoleGridButton extends TileToggleButton {
  RoleGridButton({
    required String title,
    required String hint,
    required String iconAsset,
    required String selectedIconAsset,
    Color? selectedTitleColor,
    Color? selectedBackgroundColor,
    required bool selected,
    dynamic data,
    double? sortOrder,
    void Function(RoleGridButton)? onTap,
  }) : super(
    title: title,
    hint: hint,
    iconAsset: iconAsset,
    selectedIconAsset: selectedIconAsset,
    selectedTitleColor: selectedTitleColor,
    selectedBackgroundColor: selectedBackgroundColor,
    selected: selected, 
    selectionMarkerAsset: 'images/icon-check.png',
    iconFit: BoxFit.fitWidth,
    iconWidth: 38,
    semanticsValue: "${Localization().getStringEx("toggle_button.status.unchecked", "unchecked",)}, ${Localization().getStringEx("toggle_button.status.checkbox", "checkbox")}",
    selectedSemanticsValue: "${Localization().getStringEx("toggle_button.status.checked", "checked",)}, ${Localization().getStringEx("toggle_button.status.checkbox", "checkbox")}",
    data: data,
    sortOrder: sortOrder,
    onTap: (BuildContext context, TileToggleButton button) => _handleTap(context, button, onTap),
  );

  static RoleGridButton? fromRole(UserRole? role, { bool? selected, double? sortOrder, void Function(RoleGridButton)? onTap }) {
    if (role == UserRole.student) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.student.title', 'University Student'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.student.hint', ''),
        iconAsset: 'images/icon-persona-student-normal.png',
        selectedIconAsset: 'images/icon-persona-student-selected.png',
        selectedBackgroundColor: Styles().colors!.fillColorSecondary,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
      );
    }
    else if (role == UserRole.visitor) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.visitor.title', 'Visitor'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.visitor.hint', ''),
        iconAsset: 'images/icon-persona-visitor-normal.png',
        selectedIconAsset: 'images/icon-persona-visitor-selected.png',
        selectedBackgroundColor: Styles().colors!.fillColorSecondary,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
      );
    }
    else if (role == UserRole.fan) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.fan.title', 'Athletics Fan'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.fan.hint', ''),
        iconAsset: 'images/icon-persona-athletics-normal.png',
        selectedIconAsset: 'images/icon-persona-athletics-selected.png',
        selectedBackgroundColor: Styles().colors!.accentColor2,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
      );
    }
    else if (role == UserRole.employee) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.employee.title', 'University Employee'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.employee.hint', ''),
        iconAsset: 'images/icon-persona-employee-normal.png',
        selectedIconAsset: 'images/icon-persona-employee-selected.png',
        selectedBackgroundColor: Styles().colors!.accentColor3,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
      );
    }
    else if (role == UserRole.alumni) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.alumni.title', 'Alumni'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.alumni.hint', ''),
        iconAsset: 'images/icon-persona-alumni-normal.png',
        selectedIconAsset: 'images/icon-persona-alumni-selected.png',
        selectedBackgroundColor: Styles().colors!.fillColorPrimary,
        selectedTitleColor: Colors.white,
        selected:(selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
      );
    }
    else if (role == UserRole.parent) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.parent.title', 'Parent'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.parent.hint', ''),
        iconAsset: 'images/icon-persona-parent-normal.png',
        selectedIconAsset: 'images/icon-persona-parent-selected.png',
        selectedBackgroundColor: Styles().colors!.fillColorSecondary,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
      );
    }
    else if (role == UserRole.resident) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.resident.title', 'Resident'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.resident.hint', ''),
        iconAsset: 'images/icon-persona-resident-normal.png',
        selectedIconAsset: 'images/icon-persona-resident-selected.png',
        selectedBackgroundColor: Styles().colors!.fillColorPrimary,
        selectedTitleColor: Colors.white,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
      );
    }
    else if (role == UserRole.gies) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.gies.title', 'GIES Student'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.gies.hint', ''),
        iconAsset: 'images/icon-persona-alumni-normal.png',
        selectedIconAsset: 'images/icon-persona-alumni-selected.png',
        selectedBackgroundColor: Styles().colors!.fillColorPrimary,
        selectedTitleColor: Colors.white,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
      );
    }
    else {
      return null;
    }
  }

  static Widget gridFromFlexUI({ Set<UserRole>? selectedRoles, double gridSpacing = 5, void Function(RoleGridButton)? onTap }) {
    List<Widget> roleButtons1 = <Widget>[], roleButtons2 = <Widget>[];
    List<String> codes = JsonUtils.listStringsValue(FlexUI()['roles']) ?? [];
    int index = 1;
    for (String code in codes) {
      
      UserRole? role = UserRole.fromString(code);
      bool selected = selectedRoles?.contains(role) ?? false;
      RoleGridButton? button = RoleGridButton.fromRole(role,
        selected: selected,
        sortOrder: index.toDouble(),
        onTap: onTap
      );

      if (button != null) {
        List<Widget> roleButtons = (0 < (index % 2)) ? roleButtons1 : roleButtons2;
        if (roleButtons.isNotEmpty) {
          roleButtons.add(Container(height: gridSpacing,));
        }
        roleButtons.add(button);
        index++;
      }
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Expanded(child: Column(children: roleButtons1)),
      Container(width: gridSpacing,),
      Expanded(child: Column(children: roleButtons2,),),
    ],);
  }

  static void _handleTap(BuildContext context, TileToggleButton button, Function(RoleGridButton)? tapCallback) {
    AppSemantics.announceCheckBoxStateChange(context, !button.selected, button.title);
    if ((tapCallback != null) && (button is RoleGridButton)) {
      tapCallback(button);
    }
  }
}
