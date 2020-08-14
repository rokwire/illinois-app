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
import 'package:flutter/rendering.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class RibbonButton extends StatelessWidget {
  final String label;

  final GestureTapCallback onTap;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final BoxBorder border;
  final TextStyle style;
  final double height;
  final String leftIcon;
  final String icon;
  final BuildContext context;
  final String hint;

  RibbonButton({
    @required this.label,
    this.onTap,
    this.borderRadius = BorderRadius.zero,
    this.border,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.style,
    this.height = 48.0,
    this.icon = 'images/chevron-right.png',
    this.leftIcon,
    this.context,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return getSemantics();
  }

  Semantics getSemantics() {
    return Semantics(label: label, hint : hint, button: true, excludeSemantics: true, child: _content());
  }

  Widget _content() {
    Widget image = getImage();
    return GestureDetector(
      onTap: () { onTap(); anaunceChange(); },
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[ Expanded(
        child: Container(
          decoration: BoxDecoration(color: Colors.white, border:border, borderRadius: borderRadius),
          height: this.height,
          child: Padding(
            padding: padding,
            child:  Row(
              children: <Widget>[
                AppString.isStringNotEmpty(leftIcon) ? Padding(padding: EdgeInsets.only(right: 7), child: Image.asset(leftIcon)) : Container(),
                Expanded(child:
                  Text(label,
                    style: style ?? TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold),
                  )
                ),
                (image != null) ? Padding(padding: EdgeInsets.only(left: 7), child: image) : Container(),
              ],
            ),
          ),
        )
      ),],),
    );
  }

  Widget getImage() {
    return (icon != null) ? Image.asset(icon) : null;
  }

  void anaunceChange() {}
}

class ToggleRibbonButton extends RibbonButton {
  final String label;
  final GestureTapCallback onTap;
  final bool toggled;
  final BorderRadius borderRadius;
  final BoxBorder border;
  final BuildContext context; //Required in order to announce the VO status change
  final TextStyle style;
  final double height;

  ToggleRibbonButton ({
    @required this.label,
    this.onTap,
    this.toggled = false,
    this.borderRadius = BorderRadius.zero,
    this.border,
    this.context,
    this.height = 48.0,
    this.style
  });

  @override
  Widget getImage() {
    return Image.asset(toggled ? 'images/switch-on.png' : 'images/switch-off.png');
  }

  @override
  Semantics getSemantics() {
    return Semantics(
        label: label,
        value: (toggled
                ? Localization().getStringEx(
                    "toggle_button.status.checked",
                    "checked",
                  )
                : Localization().getStringEx("toggle_button.status.unchecked", "unchecked")) +
            ", " +
            Localization().getStringEx("toggle_button.status.checkbox", "checkbox"),
        excludeSemantics: true,
        child: _content());
  }

  @override
  void anaunceChange() {
    AppSemantics.announceCheckBoxStateChange(context, !toggled, label); // !toggled because we announce before the state got updated
    super.anaunceChange();
  }
}
