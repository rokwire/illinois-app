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
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AthleticsSportItemWidget extends StatelessWidget {
  final SportDefinition sport;
  final String? label;
  final GestureTapCallback? onLabelTap;
  final GestureTapCallback? onCheckTap;
  final bool checkMarkVisibility;
  final bool selected;
  final bool showChevron;

  AthleticsSportItemWidget(
      {required this.label,
      required this.sport,
      this.onLabelTap,
      this.onCheckTap,
      this.showChevron = true,
      this.selected = false,
      this.checkMarkVisibility = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onLabelTap,
        child: Semantics(
          label: label,
          value: (selected?Localization().getStringEx("toggle_button.status.checked", "checked",) :
                Localization().getStringEx("toggle_button.status.unchecked", "unchecked")) +
                ", "+ Localization().getStringEx("toggle_button.status.checkbox", "checkbox"),
          button:true,
          excludeSemantics: true,
          child: Container(
//            height: 50,
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.only(left: 10, top: 0, bottom: 0),
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Styles().images?.getImage(sport.iconPath, excludeFromSemantics: true),
                  ),
                  Expanded(child:
                  Text(
                    label!,
                    style: Styles().textStyles?.getTextStyle("widget.title.regular.fat")
                  ),),
                  showChevron
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Styles().images?.getImage('chevron-right-bold', excludeFromSemantics: true),
                        )
                      : Container(),
                  checkMarkVisibility ? GestureDetector(
                    onTap: onCheckTap,
                    child: Container(
                        child: Padding(
                      padding: EdgeInsets.only(
                          right: 10, top: 15, bottom: 15, left: 25),
                      child: Styles().images?.getImage(selected ? 'check-circle-filled' : 'check-circle-outline-gray', excludeFromSemantics: true),
                    )),
                  ) : Container(height: 54,),
                ],
              ),
            ),
          ),
        ));
  }
}
