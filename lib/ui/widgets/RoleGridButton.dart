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
  static final double  minimumTitleRowsCount = 2;
  static final double  fontSizeHeightFactor = 1.2;

  final double scaleFactor;

  RoleGridButton({
    required String title,
    required String hint,
    required String iconKey,
    required String selectedIconKey,
    Color? selectedTitleColor,
    Color? selectedBackgroundColor,
    required bool selected,
    dynamic data,
    double? sortOrder,
    void Function(RoleGridButton)? onTap,
    this.scaleFactor = 1.0,
  }) : super(
    title: title,
    hint: hint,
    iconKey: iconKey,
    selectedIconKey: selectedIconKey,
    selectedTitleColor: selectedTitleColor,
    selectedBackgroundColor: selectedBackgroundColor,
    selected: selected, 
    selectionMarkerKey: 'check-circle-filled',
    iconFit: BoxFit.fitWidth,
    iconWidth: 38,
    semanticsValue: "${Localization().getStringEx("toggle_button.status.unchecked", "unchecked",)}, ${Localization().getStringEx("toggle_button.status.checkbox", "checkbox")}",
    selectedSemanticsValue: "${Localization().getStringEx("toggle_button.status.checked", "checked",)}, ${Localization().getStringEx("toggle_button.status.checkbox", "checkbox")}",
    data: data,
    sortOrder: sortOrder,
    onTap: (BuildContext context, TileToggleButton button) => _handleTap(context, button, onTap),
  );

  @protected Widget get defaultIconWidget =>  Container(constraints: BoxConstraints(minHeight: 40), child: super.defaultIconWidget);
  @protected Widget get displayTitleWidget =>  Container(constraints: BoxConstraints(minHeight: _titleMinHeight), child: super.displayTitleWidget);
  double get _titleMinHeight => (minimumTitleRowsCount * titleFontSize * fontSizeHeightFactor * scaleFactor) ;


  static RoleGridButton? fromRole(UserRole? role, { bool? selected, double? sortOrder, double? scaleFactor, void Function(RoleGridButton)? onTap }) {
    if (role == UserRole.student) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.student.title', 'University Student'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.student.hint', ''),
        iconKey: 'role-student',
        selectedIconKey: 'role-student',
        selectedBackgroundColor: Styles().colors!.white,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
        scaleFactor: scaleFactor ?? 1,
      );
    }
    else if (role == UserRole.visitor) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.visitor.title', 'Visitor'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.visitor.hint', ''),
        iconKey: 'role-visitor',
        selectedIconKey:  'role-visitor',
        selectedBackgroundColor: Styles().colors!.white,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
        scaleFactor: scaleFactor ?? 1,
      );
    }
    else if (role == UserRole.fan) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.fan.title', 'Athletics Fan'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.fan.hint', ''),
        iconKey: 'role-athletics',
        selectedIconKey:  'role-athletics',
        selectedBackgroundColor: Styles().colors!.white,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
        scaleFactor: scaleFactor ?? 1,
      );
    }
    else if (role == UserRole.employee) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.employee.title', 'University Employee'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.employee.hint', ''),
        iconKey: 'role-employee',
        selectedIconKey: 'role-employee',
        selectedBackgroundColor: Styles().colors!.white,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
        scaleFactor: scaleFactor ?? 1,
      );
    }
    else if (role == UserRole.alumni) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.alumni.title', 'Alumni'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.alumni.hint', ''),
        iconKey: 'role-alumni',
        selectedIconKey: 'role-alumni',
        selectedBackgroundColor: Styles().colors!.white,
        selected:(selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
        scaleFactor: scaleFactor ?? 1,
      );
    }
    else if (role == UserRole.parent) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.parent.title', 'Parent'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.parent.hint', ''),
        iconKey: 'role-parent',
        selectedIconKey:  'role-parent',
        selectedBackgroundColor: Styles().colors!.white,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
        scaleFactor: scaleFactor ?? 1,
      );
    }

    else if (role == UserRole.gies) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.gies.title', 'GIES Student'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.gies.hint', ''),
        iconKey: 'role-alumni',
        selectedIconKey: 'role-alumni',
        selectedBackgroundColor: Styles().colors!.white,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
        scaleFactor: scaleFactor ?? 1,
      );
    }
    else {
      return null;
    }
  }

  static Widget gridFromFlexUI({ Set<UserRole>? selectedRoles, double gridSpacing = 5, void Function(RoleGridButton)? onTap, double? scaleFactor }) {
    List<Widget> roleButtons1 = <Widget>[], roleButtons2 = <Widget>[];
    List<String> codes = JsonUtils.listStringsValue(FlexUI()['roles']) ?? [];
    int index = 1;
    for (String code in codes) {
      
      UserRole? role = UserRole.fromString(code);
      bool selected = selectedRoles?.contains(role) ?? false;
      RoleGridButton? button = RoleGridButton.fromRole(role,
        selected: selected,
        sortOrder: index.toDouble(),
        scaleFactor: scaleFactor,
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
