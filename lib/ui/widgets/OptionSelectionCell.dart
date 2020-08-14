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
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';

class OptionSelectionCell extends StatelessWidget {
  final String iconPath;
  final String selectedIconPath;
  final Color selectedBackgroundColor;
  final Color selectedTextColor;
  final String label;
  final String hint;
  final bool selected;

  final bool isButton;
  final bool isCustomToggle;
  static final Color defaultTextColor = Styles().colors.fillColorPrimary;

  OptionSelectionCell(
      {@required this.iconPath,
      @required this.selectedIconPath,
      @required this.label,
      this.hint = '',
      this.selected = false,
      this.selectedBackgroundColor,
      this.selectedTextColor, this.isButton = true, this.isCustomToggle= true});

  @override
  Widget build(BuildContext context) {
    String hint = "";
    if(isCustomToggle){
      hint = this.hint + (selected?Localization().getStringEx("toggle_button.status.checked", "checked",) :
                                  Localization().getStringEx("toggle_button.status.unchecked", "unchecked"));

      hint += ", "+ Localization().getStringEx("toggle_button.status.checkbox", "checkbox");
    }
    return  Semantics(label: label /*+", "+hint,*/, /*hint: hint,*/button: isButton, /*checked: selected,*/ excludeSemantics: true, value: hint,child:
        Stack(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
                color: (selected ? selectedBackgroundColor : Colors.white),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color:
                        (selected ? Styles().colors.fillColorPrimary : Colors.white),
                    width: 2)),
            width: 140,
            child:Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child:
                        Image.asset((selected ? selectedIconPath : iconPath)),
                  ),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.bold,
                        fontSize: 17,
                        color: (selected
                            ? selectedTextColor ?? Styles().colors.fillColorPrimary
                            : OptionSelectionCell.defaultTextColor)),
                  )
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 146,
          child: Visibility(
              visible: selected,
              child: Align(
                alignment: Alignment.topRight,
                child: Image.asset('images/icon-check.png'),
              )),
        )
      ],
    ));
  }
}
