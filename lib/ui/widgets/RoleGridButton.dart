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
import 'package:flutter/semantics.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum RoleGridButtonUsage { regular, standalone }

class RoleGridButton extends StatelessWidget {
  final UserRole userRole;
  final String? title;
  final String? hint;
  final String? iconKey;
  final TextStyle? textStyle;
  final double? sortOrder;
  final bool selected;
  final double aspectRatio;
  final RoleGridButtonUsage usage;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final void Function(UserRole)? onTap;

  RoleGridButton(this.userRole, {
    this.title, this.hint, this.iconKey,
    this.textStyle, this.sortOrder,
    this.selected = false,
    this.aspectRatio = 1,
    this.usage = RoleGridButtonUsage.regular,
    this.margin = const EdgeInsets.only(top: 4, right: 4),
    this.padding = const EdgeInsets.symmetric(horizontal: 24), // TMP: 16
    this.onTap,
  });

  factory RoleGridButton.regular(UserRole role, {
    bool? selected,
    double? sortOrder,
    void Function(UserRole)? onTap,
  }) => RoleGridButton(role,
    title: role.displayTitle,
    hint: role.displayHint,
    iconKey: role.displayIconKey,
    textStyle: Styles().textStyles.getTextStyleEx('widget.button.title.medium.fat', fontHeight: 1.10),
    aspectRatio: 300 / 200,
    selected: selected == true,
    sortOrder: sortOrder,
    usage: RoleGridButtonUsage.regular,
    onTap: onTap,
  );

  factory RoleGridButton.standalone(UserRole role, {
    bool? selected,
    double? sortOrder,
    void Function(UserRole)? onTap,
  }) => RoleGridButton(role,
    title: role.displayTitle,
    hint: role.displayHint,
    iconKey: role.displayIconKey,
    textStyle: Styles().textStyles.getTextStyleEx('widget.button.title.medium.fat', fontHeight: 1.10),
    aspectRatio: 800 / 200,
    selected: selected == true,
    sortOrder: sortOrder,
    usage: RoleGridButtonUsage.standalone,
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) =>
    GestureDetector(onTap: _onTap, child:
      Semantics(label: title, excludeSemantics: true, sortKey: _semanticsSortKey, value: _semanticsValue, child:
        selected ? Stack(children: [
          _contentWidget,
          Positioned.fill(child:
            Align(alignment: Alignment.topRight, child:
              _selectionMarker
            )
          )
        ],) : _contentWidget
     )
    );

  Widget get _contentWidget => Padding(padding: margin, child:
    Padding(padding: margin, child:
      AspectRatio(aspectRatio: aspectRatio, child:
        Container(decoration: _contentFrame, child:
          Padding(padding: padding, child:
            Column(children: [
              Expanded(flex: _flex[0], child: Container()),
              Expanded(flex: _flex[1], child:
                AspectRatio(aspectRatio: 1, child:
                  Styles().images.getImage(iconKey, fit: BoxFit.contain) ?? Container(),
                )
              ),
              Expanded(flex: _flex[2], child: Container()),
              Expanded(flex: _flex[3], child:
                Text(title ?? '', style: textStyle, textAlign: TextAlign.center,)
              ),
              Expanded(flex: _flex[4], child: Container()),
            ],),
          ),
        ),
      )
    ),
  );

  List<int> get _flex {
    switch (usage) {
      case RoleGridButtonUsage.regular: return _regularFlex;
      case RoleGridButtonUsage.standalone: return _standaloneFlex;
    }
  }

  static const List<int> _regularFlex    = [15, 30, 10, 30, 15];
  static const List<int> _standaloneFlex = [10, 50, 10, 30, 10];

  Decoration get _contentFrame => BoxDecoration(
      color: Styles().colors.white,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
        color: selected ? Styles().colors.fillColorPrimary : Styles().colors.white,
        width: 2
      ),
      boxShadow: [
        const BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))
      ]
  );

  Widget get _selectionMarker =>
    Styles().images.getImage('check-circle-filled', excludeFromSemantics: true) ?? Container();

  SemanticsSortKey? get _semanticsSortKey => (sortOrder != null) ? OrdinalSortKey(sortOrder ?? 0) : null;

  String? get _semanticsValue => "$_semanticsStatus, $_semanticsControl";
  String? get _semanticsStatus => selected ?
    Localization().getStringEx("toggle_button.status.unchecked", "unchecked",) :
    Localization().getStringEx("toggle_button.status.checked", "checked",);
  String? get _semanticsControl =>
    Localization().getStringEx("toggle_button.status.checkbox", "checkbox");

  void _onTap() => onTap?.call(userRole);
}

extension RoleGridButtonGrid on RoleGridButton {

  static Widget fromFlexUI({
    Set<UserRole>? selectedRoles,
    double gridSpacing = 5,
    void Function(UserRole)? onTap,
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
}


extension UserRoleUI on UserRole {

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