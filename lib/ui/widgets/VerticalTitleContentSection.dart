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

class VerticalTitleContentSection extends StatelessWidget {
  final String title;
  final String content;
  final double bottomPadding;

  const VerticalTitleContentSection(
      {Key key, this.title, this.content, this.bottomPadding = 16})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      value: content,
      excludeSemantics: true,
      child: Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, bottom: bottomPadding, top: 16),
          child:
          Container(
              decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(color: Styles().colors.fillColorSecondary, width: 3))
              ),
              child: Padding(padding: EdgeInsets.only(left: 10, right: 5),
                  child:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        style: TextStyle(
                            color: Styles().colors.fillColorPrimary,
                            fontSize: 14,
                            fontFamily: Styles().fontFamilies.regular),
                      ),
                      Text(content,
                          style: TextStyle(
                              color: Styles().colors.fillColorPrimary,
                              fontSize: 24,
                              fontFamily: Styles().fontFamilies.extraBold)
                      )
                    ],
                  )
              ))),
    );
  }
}