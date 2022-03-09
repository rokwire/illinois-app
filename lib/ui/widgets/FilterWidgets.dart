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
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/filter_widgets.dart' as rokwire;

class FilterListItemWidget extends rokwire.FilterListItemWidget {

  FilterListItemWidget({ Key? key,
    String? title,
    TextStyle? titleTextStyle,
    TextStyle? selectedTitleTextStyle,

    String? description,
    TextStyle? descriptionTextStyle,
    TextStyle? selectedDescriptionTextStyle,

    bool selected = false,
    GestureTapCallback? onTap,
  
    Widget? icon,
    String? iconAsset = 'images/icon-unselected.png',
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(left: 10),

    Widget? selectedIcon,
    String? selectedIconAsset = 'images/icon-selected.png',
    EdgeInsetsGeometry selectedIconPadding = const EdgeInsets.only(left: 10),
  }) : super(key: key,
    title: title,
    titleTextStyle: titleTextStyle,
    selectedTitleTextStyle: selectedTitleTextStyle,

    description: description,
    descriptionTextStyle: descriptionTextStyle,
    selectedDescriptionTextStyle: selectedDescriptionTextStyle,

    selected: selected,
    onTap: onTap,
  
    icon: icon,
    iconAsset: iconAsset,
    iconPadding: iconPadding,

    selectedIcon: selectedIcon,
    selectedIconAsset: selectedIconAsset,
    selectedIconPadding: selectedIconPadding,
  );
}

class FilterSelectorWidget extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? labelFontFamily;
  final double labelFontSize;
  final bool active;
  final EdgeInsets padding;
  final bool visible;
  final GestureTapCallback? onTap;

  FilterSelectorWidget(
      {required this.label,
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
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          label!,
                          style: TextStyle(
                              fontSize: labelFontSize, color: (active ? Styles().colors!.fillColorSecondary : Styles().colors!.fillColorPrimary), fontFamily: labelFontFamily ?? Styles().fontFamilies!.bold),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Image.asset(active ? 'images/icon-up.png' : 'images/icon-down.png', excludeFromSemantics: true),
                        )
                      ],
                    ),
                  ),
                ))));
  }
}