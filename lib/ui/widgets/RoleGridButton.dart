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
import 'package:illinois/service/Localization.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class RoleGridButton extends StatelessWidget {
  final String title;
  final String hint;
  final String iconPath;
  final String selectedIconPath;
  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final Color borderColor;
  final Color selectedBorderColor;
  final Color textColor;
  final Color selectedTextColor;
  final bool selected;
  final dynamic data;
  final double sortOrder;
  final Function onTap;

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
        this.onTap(this);
        AppSemantics.announceCheckBoxStateChange(context, !selected, title);
    } }, //onTap (this),
    child: Semantics(label: title, excludeSemantics: true, sortKey: sortOrder!=null?OrdinalSortKey(sortOrder) : null,
        value: (selected?Localization().getStringEx("toggle_button.status.checked", "checked",) :
        Localization().getStringEx("toggle_button.status.unchecked", "unchecked")) +
            ", "+ Localization().getStringEx("toggle_button.status.checkbox", "checkbox"),
    child:Stack(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 8, right: 8),
          child: Container(
            decoration: BoxDecoration(
                color: (this.selected ? this.selectedBackgroundColor : this.backgroundColor),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: this.selected ? (this.selectedBorderColor ?? Styles().colors.fillColorPrimary) : this.borderColor, width: 2),
                boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, offset: Offset(2, 2), blurRadius: 6),],
                ),
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18), child: Column(children: <Widget>[
              Image.asset((this.selected ? this.selectedIconPath : this.iconPath)),
              Container(height: 18,),
              Text(title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.bold,
                        fontSize: 17,
                        color: (this.selected ? (this.selectedTextColor ?? Styles().colors.fillColorPrimary) : (this.textColor ?? Styles().colors.fillColorPrimary))),
                  )

            ],),),
          ),
        ),
        Visibility(
          visible: this.selected,
          child: Align(
            alignment: Alignment.topRight,
            child: Image.asset('images/icon-check.png'),
          ),
        ),
      ],
    )));
  }
}
