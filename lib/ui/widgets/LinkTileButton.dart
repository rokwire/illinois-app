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
import 'package:illinois/service/Styles.dart';

class LinkTileWideButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final String hint;
  final GestureTapCallback onTap;

  static final Color defaultTextColor = Styles().colors.fillColorPrimary;

  LinkTileWideButton({this.iconPath, this.label, this.hint = '', this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(label: label, hint:hint, button:true, child:Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                  color: ( Colors.white),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color:Colors.white,
                      width: 2)),
              child: Padding(
                padding: EdgeInsets.only(top: 16, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies.bold,
                          fontSize: 20,
                          color: LinkTileWideButton.defaultTextColor),
                    ),
                    Image.asset((iconPath)),
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}

class LinkTileSmallButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final String hint;
  final GestureTapCallback onTap;
  final TextStyle textStyle;

  static final Color defaultTextColor = Styles().colors.fillColorPrimary;
  static const Color _boxShadowColor = Color.fromRGBO(19, 41, 75, 0.3);

  final double width;

  LinkTileSmallButton({this.iconPath, this.label, this.hint = '', this.width = 140, this.onTap, this.textStyle});

  @override
  Widget build(BuildContext context) {
    TextStyle style = textStyle??
        TextStyle(
          fontFamily: Styles().fontFamilies.bold,
          fontSize: 20,
          color: LinkTileSmallButton.defaultTextColor
        );

    return GestureDetector(
      onTap: onTap,
      child: Semantics(label: label, hint:hint, button:true, excludeSemantics: true, child:Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(color: (Styles().colors.white),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: _boxShadowColor, spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]),
              width: width,
              child: Padding(
                padding: EdgeInsets.only(top: 16, bottom: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child:
                      Image.asset((iconPath)),
                    ),
                    Container(height: 10,),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: style)
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}