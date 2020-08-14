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
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class FilterListItemWidget extends StatelessWidget {
  final String label;
  final String subLabel;
  final GestureTapCallback onTap;
  final bool selected;

  FilterListItemWidget({@required this.label, this.subLabel, @required this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) {
    TextStyle labelsStyle = TextStyle(fontSize: 16, color: Styles().colors.fillColorPrimary, fontFamily: (selected ? Styles().fontFamilies.bold : Styles().fontFamilies.medium));
    bool hasSubLabel = AppString.isStringNotEmpty(subLabel);
    return Semantics(
        label: label,
        button: true,
        selected: selected,
        excludeSemantics: true,
        child: InkWell(
            onTap: onTap,
            child: Container(
              color: (selected ? Styles().colors.background : Colors.white),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labelsStyle,
                    ),
                    Expanded(
                      child: Container(),
                    ),
                    hasSubLabel
                        ? Text(
                            subLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: labelsStyle,
                          )
                        : Container(),
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Image.asset((selected ? 'images/icon-selected.png' : 'images/icon-unselected.png')),
                    )
                  ],
                ),
              ),
            )));
  }
}

class FilterSelectorWidget extends StatelessWidget {
  final String label;
  final String hint;
  final String labelFontFamily;
  final double labelFontSize;
  final bool active;
  final EdgeInsets padding;
  final bool visible;
  final GestureTapCallback onTap;

  FilterSelectorWidget(
      {@required this.label,
        this.hint,
        this.labelFontFamily,
        this.labelFontSize = 16,
        this.active = false,
        this.padding = const EdgeInsets.only(left: 4, right: 4, top: 12),
        this.visible = false,
        this.onTap});

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible: visible,
        child: Semantics(
            label: label,
            hint: hint,
            excludeSemantics: true,
            button: true,
            child: InkWell(
                onTap: onTap,
                child: Container(
                  child: Padding(
                    padding: padding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Text(
                          label,
                          style: TextStyle(
                              fontSize: labelFontSize, color: (active ? Styles().colors.fillColorSecondary : Styles().colors.fillColorPrimary), fontFamily: labelFontFamily ?? Styles().fontFamilies.bold),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Image.asset(active ? 'images/icon-up.png' : 'images/icon-down.png'),
                        )
                      ],
                    ),
                  ),
                ))));
  }
}