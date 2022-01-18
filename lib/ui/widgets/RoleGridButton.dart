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
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/service/Styles.dart';

class RoleGridButton extends StatelessWidget {
  final String? title;
  final String? hint;
  final String? iconPath;
  final String? selectedIconPath;
  final Color backgroundColor;
  final Color? selectedBackgroundColor;
  final Color borderColor;
  final Color? selectedBorderColor;
  final Color? textColor;
  final Color? selectedTextColor;
  final bool selected;
  final dynamic data;
  final double? sortOrder;
  final Function? onTap;

  RoleGridButton(
      {this.title,
      this.hint,
      this.iconPath,
      this.selectedIconPath,
      this.backgroundColor = Colors.white,
      this.selectedBackgroundColor = Colors.white,
      this.borderColor = Colors.white ,
      this.selectedBorderColor,
      this.textColor,
      this.selectedTextColor,
      this.selected = false,
      this.sortOrder,
      this.data,
      this.onTap,});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () {
      if (this.onTap != null) {
        this.onTap!(this);
        AppSemantics.announceCheckBoxStateChange(context, !selected, title);
    } }, //onTap (this),
    child: Semantics(label: title, excludeSemantics: true, sortKey: sortOrder!=null?OrdinalSortKey(sortOrder!) : null,
        value: (selected?Localization().getStringEx("toggle_button.status.checked", "checked",) :
        Localization().getStringEx("toggle_button.status.unchecked", "unchecked"))! +
            ", "+ Localization().getStringEx("toggle_button.status.checkbox", "checkbox")!,
    child:Stack(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 8, right: 8),
          child: Container(
            decoration: BoxDecoration(
                color: (this.selected ? this.selectedBackgroundColor : this.backgroundColor),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: this.selected ? (this.selectedBorderColor ?? Styles().colors!.fillColorPrimary!) : this.borderColor, width: 2),
                boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, offset: Offset(2, 2), blurRadius: 6),],
                ),
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18), child: Column(children: <Widget>[
              Image.asset((this.selected ? this.selectedIconPath! : this.iconPath!), width: 38, fit: BoxFit.fitWidth, excludeFromSemantics: true),
              Container(height: 18,),
              Text(title!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies!.bold,
                        fontSize: 17,
                        color: (this.selected ? (this.selectedTextColor ?? Styles().colors!.fillColorPrimary) : (this.textColor ?? Styles().colors!.fillColorPrimary))),
                  )

            ],),),
          ),
        ),
        Visibility(
          visible: this.selected,
          child: Align(
            alignment: Alignment.topRight,
            child: Image.asset('images/icon-check.png', excludeFromSemantics: true),
          ),
        ),
      ],
    )));
  }

  static RoleGridButton? fromRole(UserRole? role, { bool? selected, double? sortOrder, Function? onTap }) {
    if (role == UserRole.student) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.student.title', 'University student'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.student.hint', ''),
        iconPath: 'images/icon-persona-student-normal.png',
        selectedIconPath: 'images/icon-persona-student-selected.png',
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
        iconPath: 'images/icon-persona-visitor-normal.png',
        selectedIconPath: 'images/icon-persona-visitor-selected.png',
        selectedBackgroundColor: Styles().colors!.fillColorSecondary,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
      );
    }
    else if (role == UserRole.fan) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.fan.title', 'Athletics fan'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.fan.hint', ''),
        iconPath: 'images/icon-persona-athletics-normal.png',
        selectedIconPath: 'images/icon-persona-athletics-selected.png',
        selectedBackgroundColor: Styles().colors!.accentColor2,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
      );
    }
    else if (role == UserRole.employee) {
      return RoleGridButton(
        title: Localization().getStringEx('panel.onboarding2.roles.button.employee.title', 'University employee'),
        hint: Localization().getStringEx('panel.onboarding2.roles.button.employee.hint', ''),
        iconPath: 'images/icon-persona-employee-normal.png',
        selectedIconPath: 'images/icon-persona-employee-selected.png',
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
        iconPath: 'images/icon-persona-alumni-normal.png',
        selectedIconPath: 'images/icon-persona-alumni-selected.png',
        selectedBackgroundColor: Styles().colors!.fillColorPrimary,
        selectedTextColor: Colors.white,
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
        iconPath: 'images/icon-persona-parent-normal.png',
        selectedIconPath: 'images/icon-persona-parent-selected.png',
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
        iconPath: 'images/icon-persona-resident-normal.png',
        selectedIconPath: 'images/icon-persona-resident-selected.png',
        selectedBackgroundColor: Styles().colors!.fillColorPrimary,
        selectedTextColor: Colors.white,
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
        iconPath: 'images/icon-persona-alumni-normal.png',
        selectedIconPath: 'images/icon-persona-alumni-selected.png',
        selectedBackgroundColor: Styles().colors!.fillColorPrimary,
        selectedTextColor: Colors.white,
        selected: (selected == true),
        data: role,
        sortOrder: sortOrder,
        onTap: onTap,
      );
    }
  }

  static Widget gridFromFlexUI({ Set<UserRole>? selectedRoles, double gridSpacing = 5, Function? onTap }) {
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
}
