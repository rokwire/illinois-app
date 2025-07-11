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
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/tile_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum RoleGridButtonUsage { regular, standalone }

class RoleGridButton extends TileToggleButton {
  static final double  minimumTitleRowsCount = 2;
  static final double  fontSizeHeightFactor = 1.2;

  final TextScaler textScaler;
  final RoleGridButtonUsage usage;

  RoleGridButton({
    required super.title,
    required super.hint,
    required super.iconKey,
    required super.selectedIconKey,
    required UserRole role,
    required super.selected,
    super.selectedTitleColor,
    super.selectedBackgroundColor,
    super.sortOrder,
    super.contentSpacing = 18,
    super.margin = const EdgeInsets.only(top: 8, right: 8),
    super.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.textScaler = TextScaler.noScaling,
    this.usage = RoleGridButtonUsage.regular,
    void Function(RoleGridButton)? onTap,
  }) : super(
    selectionMarkerKey: 'check-circle-filled',
    iconFit: BoxFit.fitWidth,
    iconWidth: 38,
    semanticsValue: "${Localization().getStringEx("toggle_button.status.unchecked", "unchecked",)}, ${Localization().getStringEx("toggle_button.status.checkbox", "checkbox")}",
    selectedSemanticsValue: "${Localization().getStringEx("toggle_button.status.checked", "checked",)}, ${Localization().getStringEx("toggle_button.status.checkbox", "checkbox")}",
    data: role,
    onTap: (BuildContext context, TileToggleButton button) => _handleTap(context, button, onTap),
  );

  factory RoleGridButton.regular(UserRole role, {
    bool? selected,
    double? sortOrder,
    TextScaler? textScaler,
    void Function(RoleGridButton)? onTap
  }) => RoleGridButton(
      title: role.displayTitle ?? '',
      hint: role.displayHint ?? '',
      iconKey: role.displayIconKey ?? '',
      selectedIconKey: role.displayIconKey ?? '',
      role: role,
      selected: selected == true,
      sortOrder: sortOrder,
      textScaler: textScaler ?? TextScaler.noScaling,
      usage: RoleGridButtonUsage.regular,
      onTap: onTap,
  );

  factory RoleGridButton.standalone(UserRole role, {
    bool? selected,
    double? sortOrder,
    TextScaler? textScaler,
    void Function(RoleGridButton)? onTap
  }) => RoleGridButton(
      title: role.displayTitle ?? '',
      hint: role.displayHint ?? '',
      iconKey: role.displayIconKey ?? '',
      selectedIconKey: role.displayIconKey ?? '',
      role: role,
      selected: selected == true,
      sortOrder: sortOrder,
      textScaler: textScaler ?? TextScaler.noScaling,
      usage: RoleGridButtonUsage.standalone,
      contentSpacing: 4,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      onTap: onTap,
  );


  @protected
  Widget get defaultIconWidget {
    switch (usage) {
      case RoleGridButtonUsage.regular: return Container(constraints: BoxConstraints(minHeight: 40), child:
        super.defaultIconWidget
      );
      default: return super.defaultIconWidget;
    }
  }

  @protected
  Widget get displayTitleWidget {
    switch (usage) {
      case RoleGridButtonUsage.regular: return Container(constraints: BoxConstraints(minHeight: _regularTitleMinHeight), child: super.displayTitleWidget);
      default: return super.displayTitleWidget;
    }
  }

  double get _regularTitleMinHeight => textScaler.scale(minimumTitleRowsCount * titleFontSize * fontSizeHeightFactor) ;
  UserRole get role => (data as UserRole);

  static Widget gridFromFlexUI({
    Set<UserRole>? selectedRoles,
    Set<UserRole>? standaloneRoles,
    double gridSpacing = 5,
    void Function(RoleGridButton)? onTap,
    TextScaler? textScaler
  }) {
    final int numberOfColumns = 2;
    final Widget hSpacer = Container(width: gridSpacing,);
    final Widget vSpacer = Container(height: gridSpacing,);

    List<Widget> rows = <Widget>[];
    List<Widget> row = <Widget>[];

    List<String> regularCodes = JsonUtils.listStringsValue(FlexUI()['roles.regular']) ?? [];
    for (String code in regularCodes) {
      UserRole? role = UserRole.fromString(code);
      RoleGridButton? button = (role != null) ? RoleGridButton.regular(role,
        selected: selectedRoles?.contains(role) == true,
        sortOrder: (rows.length * numberOfColumns + row.length + 1).toDouble(),
        textScaler: textScaler,
        onTap: onTap
      ) : null;

      if (button != null) {
        if (row.isNotEmpty) {
          row.add(hSpacer);
        }
        row.add(Expanded(child: button));

        if (row.length >= (2 * numberOfColumns - 1)) {
          if (rows.isEmpty) {
            rows.add(Text(_regularLabel, style: _gridLabelTextStyle,),);
          }
          else {
            rows.add(vSpacer,);
          }
          rows.add(Row(children: row,));
          row = <Widget>[];
        }
      }
    }

    if (row.isNotEmpty) {
      while (row.length < (2 * numberOfColumns - 1)) {
        row.addAll(<Widget>[
          hSpacer,
          Expanded(child: Container())
        ]);
      }
      if (rows.isNotEmpty) {
        rows.add(vSpacer,);
      }
      rows.add(Row(children: row,));
      row = <Widget>[];
    }

    List<String> standaloneCodes = JsonUtils.listStringsValue(FlexUI()['roles.standalone']) ?? [];
    for (String code in standaloneCodes) {
      UserRole? role = UserRole.fromString(code);
      RoleGridButton? button = (role != null) ? RoleGridButton.standalone(role,
        selected: selectedRoles?.contains(role) == true,
        sortOrder: (rows.length * numberOfColumns + row.length + 1).toDouble(),
        textScaler: textScaler,
        onTap: onTap
      ) : null;
      if (button != null) {
        rows.add(Container(height: 24,));

        String? roleLabel = role?.displayLabel;
        if (roleLabel != null) {
          rows.add(Text(roleLabel, style: _gridLabelTextStyle,),);
        }
        rows.add(button);
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows,);
  }

  static String get _regularLabel =>
    Localization().getStringEx("panel.onboarding2.roles.regular.label", "Check all that apply to personalize your app experience.");

  static TextStyle? get _gridLabelTextStyle =>
    Styles().textStyles.getTextStyle("widget.item.small.thin");

  static void _handleTap(BuildContext context, TileToggleButton button, Function(RoleGridButton)? tapCallback) {
    AppSemantics.announceCheckBoxStateChange(context, !button.selected, button.title);
    if ((tapCallback != null) && (button is RoleGridButton)) {
      tapCallback(button);
    }
  }
}

extension _UserRoleUI on UserRole {

  String? get displayTitle {
    switch (this) {
      case UserRole.student: return Localization().getStringEx('panel.onboarding2.roles.button.student.title', 'University Student');
      case UserRole.visitor: return Localization().getStringEx('panel.onboarding2.roles.button.visitor.title', 'Visitor');
      case UserRole.fan: return Localization().getStringEx('panel.onboarding2.roles.button.fan.title', 'Athletics Fan');
      case UserRole.employee: return Localization().getStringEx('panel.onboarding2.roles.button.employee.title', 'University Employee');
      case UserRole.alumni: return Localization().getStringEx('panel.onboarding2.roles.button.alumni.title', 'Alumni');
      case UserRole.parent: return Localization().getStringEx('panel.onboarding2.roles.button.parent.title', 'Parent');
      case UserRole.gies: return Localization().getStringEx('panel.onboarding2.roles.button.gies.title', 'GIES Student');
      case UserRole.prospective: return Localization().getStringEx('panel.onboarding2.roles.button.prospective.title', 'Prospective Student');
    }
    return null;
  }

  String? get displayHint {
    switch (this) {
      case UserRole.student: return Localization().getStringEx('panel.onboarding2.roles.button.student.hint', '');
      case UserRole.visitor: return Localization().getStringEx('panel.onboarding2.roles.button.visitor.hint', '');
      case UserRole.fan: return Localization().getStringEx('panel.onboarding2.roles.button.fan.hint', '');
      case UserRole.employee: return Localization().getStringEx('panel.onboarding2.roles.button.employee.hint', '');
      case UserRole.alumni: return Localization().getStringEx('panel.onboarding2.roles.button.alumni.hint', '');
      case UserRole.parent: return Localization().getStringEx('panel.onboarding2.roles.button.parent.hint', '');
      case UserRole.gies: return Localization().getStringEx('panel.onboarding2.roles.button.gies.hint', '');
      case UserRole.prospective: return Localization().getStringEx('panel.onboarding2.roles.button.prospective.hint', '');
    }
    return null;
  }

  String? get displayIconKey {
    switch (this) {
      case UserRole.student: return 'role-student';
      case UserRole.visitor: return 'role-visitor';
      case UserRole.fan: return 'role-athletics';
      case UserRole.employee: return 'role-employee';
      case UserRole.alumni: return 'role-alumni';
      case UserRole.parent: return 'role-parent';
      case UserRole.gies: return 'role-alumni';
      case UserRole.prospective: return 'role-prospective';
    }
    return null;
  }

  String? get displayLabel {
    switch (this) {
      case UserRole.prospective: return Localization().getStringEx('panel.onboarding2.roles.button.prospective.label', 'Are you considering attending the Univeristy of Illinois? Choose this option:');
      default: return null;
    }
  }
}