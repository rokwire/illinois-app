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
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/Config.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/ui/widgets/tile_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class RoleGridButton extends TileToggleButton {
  static final double  minimumTitleRowsCount = 2;
  static final double  fontSizeHeightFactor = 1.2;

  final TextScaler textScaler;

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
    this.textScaler = TextScaler.noScaling,
    EdgeInsetsGeometry? margin,
  }) : super(
    title: title,
    hint: hint,
    iconKey: iconKey,
    selectedIconKey: selectedIconKey,
    selectedTitleColor: selectedTitleColor,
    selectedBackgroundColor: selectedBackgroundColor,
    selectedBorderColor: Styles().colors.fillColorSecondary,
    selected: selected,
    selectionMarkerKey: 'check-circle-filled',
    iconFit: BoxFit.fitWidth,
    iconWidth: 38,
    contentSpacing: 10,
    semanticsValue: "${Localization().getStringEx("toggle_button.status.unchecked", "unchecked",)}, ${Localization().getStringEx("toggle_button.status.checkbox", "checkbox")}",
    selectedSemanticsValue: "${Localization().getStringEx("toggle_button.status.checked", "checked",)}, ${Localization().getStringEx("toggle_button.status.checkbox", "checkbox")}",
    data: data,
    sortOrder: sortOrder,
    onTap: (BuildContext context, TileToggleButton button) => _handleTap(context, button, onTap),
    margin: margin ?? const EdgeInsets.only(top: 8, right: 8),
  );

  @protected Widget get defaultIconWidget =>  Container(constraints: BoxConstraints(minHeight: 40), child: super.defaultIconWidget);
  @protected Widget get displayTitleWidget =>  Container(constraints: BoxConstraints(minHeight: _titleMinHeight), child: super.displayTitleWidget);
  double get _titleMinHeight => textScaler.scale(minimumTitleRowsCount * titleFontSize * fontSizeHeightFactor) ;


  static RoleGridButton? fromRole(UserRole? role, { bool? selected, double? sortOrder, TextScaler? textScaler, void Function(RoleGridButton)? onTap, EdgeInsetsGeometry? margin }) {
    if (role == UserRole.neomU) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.neom_u.title', 'NEOM U'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.neom_u.hint', ''),
        iconKey: 'role-staff',
        selectedIconKey: 'role-staff',
        selectedBackgroundColor: Styles().colors.surface,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
        textScaler: textScaler ?? TextScaler.noScaling,
        margin: margin,
      );
    }
    else if (role == UserRole.talentAcademy) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.talent_academy.title', 'Talent Academy'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.talent_academy.hint', ''),
        iconKey: 'role-staff',
        selectedIconKey:  'role-staff',
        selectedBackgroundColor: Styles().colors.surface,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
        textScaler: textScaler ?? TextScaler.noScaling,
        margin: margin,
      );
    }
    else if (role == UserRole.eriF) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.eri_f.title', 'ERI F'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.eri_f.hint', ''),
        iconKey: 'role-staff',
        selectedIconKey:  'role-staff',
        selectedBackgroundColor: Styles().colors.surface,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
        textScaler: textScaler ?? TextScaler.noScaling,
        margin: margin,
      );
    }
    else if (role == UserRole.ec12) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.ec_12.title', 'EC-12'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.ec_12.hint', ''),
        iconKey: 'role-staff',
        selectedIconKey:  'role-staff',
        selectedBackgroundColor: Styles().colors.surface,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
        textScaler: textScaler ?? TextScaler.noScaling,
        margin: margin,
      );
    }
    else if (role == UserRole.debug && (kDebugMode || Auth2().isDebugManager)) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.debug.title', 'Debug'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.debug.hint', ''),
        iconKey: 'role-debug',
        selectedIconKey:  'role-debug',
        selectedBackgroundColor: Styles().colors.surface,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
        textScaler: textScaler ?? TextScaler.noScaling,
        margin: margin,
      );
    }
    else {
      return null;
    }
  }

  static Widget gridFromFlexUI({ Set<UserRole>? selectedRoles, double gridSpacing = 5, void Function(RoleGridButton)? onTap, TextScaler? textScaler }) {
    List<Widget> roleButtons1 = <Widget>[], roleButtons2 = <Widget>[];
    List<String> codes = JsonUtils.listStringsValue(FlexUI()['roles']) ?? [];
    int index = 1;
    for (String code in codes) {

      UserRole? role = UserRole.fromString(code);
      bool selected = selectedRoles?.contains(role) ?? false;
      bool isLeftColumn = 0 < (index % 2);
      RoleGridButton? button = RoleGridButton.fromRole(role,
        selected: selected,
        sortOrder: index.toDouble(),
        textScaler: textScaler,
        onTap: onTap,
        margin: EdgeInsets.only(top: 8, left: isLeftColumn ? 0 : 4, right: isLeftColumn ? 4 : 0),
      );

      if (button != null) {
        List<Widget> roleButtons = isLeftColumn ? roleButtons1 : roleButtons2;
        if (roleButtons.isNotEmpty) {
          roleButtons.add(Container(height: gridSpacing,));
        }
        roleButtons.add(button);
        index++;
      }
    }

    return Container(
      constraints: BoxConstraints(maxWidth: Config().webContentMaxWidth),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Expanded(child: Column(children: roleButtons1)),
        Container(width: gridSpacing,),
        Expanded(child: Column(children: roleButtons2,),),
      ],),
    );
  }

  static void _handleTap(BuildContext context, TileToggleButton button, Function(RoleGridButton)? tapCallback) {
    AppSemantics.announceCheckBoxStateChange(context, !button.selected, button.title);
    if ((tapCallback != null) && (button is RoleGridButton)) {
      tapCallback(button);
    }
  }
}