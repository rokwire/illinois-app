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

class ModalImageDialog extends StatelessWidget{
  final String imageUrl;
  final GestureTapCallback onClose;

  ModalImageDialog({this.imageUrl, this.onClose});

  @override
  Widget build(BuildContext context) {
    return  Column(children: <Widget>[
      Expanded(
        child: Container(
          color: Styles().colors.blackTransparent06,
          child: Dialog(
              //backgroundColor: Color(0x00ffffff),
              child:Container(
                child: Column(
                  children: <Widget>[
                    Container(
                      color: Styles().colors.fillColorPrimary,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          GestureDetector(
                            onTap: onClose,
                            child: Padding(
                              padding: EdgeInsets.only(right: 10, top: 10),
                              child: Text('\u00D7',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: Styles().fontFamilies.medium,
                                    fontSize: 50
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        //margin: EdgeInsets.only(right: horizontalMargin + photoMargin, top: photoMargin),
                        child: AppString.isStringNotEmpty(imageUrl) ? Image.network(imageUrl, fit: BoxFit.cover,): Container(),
                      ),
                    )
                  ],
                ),
              )
          ),

        ),
      )
    ],
    );
  }
}