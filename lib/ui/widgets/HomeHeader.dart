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

class HomeHeader extends StatelessWidget {
  final String? title;
  final subTitle;
  final String? imageRes;
  final void Function()? onSettingsTap;

  HomeHeader({this.title, this.subTitle, this.imageRes, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    bool hasSubTitle = AppString.isStringNotEmpty(subTitle);

    return Container(
      color: Styles().colors!.fillColorPrimary,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: ((imageRes != null) && imageRes!.isNotEmpty)
                    ? Image.asset(
                        imageRes!,
                        excludeFromSemantics: true,
                      )
                    : Container(),
              ),
              Expanded(child:
                Semantics(
                  label: title,
                  header: true,
                  excludeSemantics: true,
                  child: Text(
                    title ?? '',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  )),
              ),
              (onSettingsTap == null) ? Container() :
                Semantics(label: "Settings", button: true,
                  child: GestureDetector(
                    onTap: onSettingsTap,
                    child: Container(
                      padding: EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        child: Image.asset(
                              'images/settings-white.png',
                              excludeFromSemantics: true,
                            ))))
            ],
          ),
          Visibility(
              visible: hasSubTitle,
              child: Semantics(
                label: AppString.getDefaultEmptyString(subTitle),
                header: true,
                excludeSemantics: true,
                child: Padding(
                  padding: EdgeInsets.only(left: 30),
                  child: Text(
                    AppString.getDefaultEmptyString(subTitle),
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: Styles().fontFamilies!.regular),
                  ),
                ),
              ))
        ],
      ),
    );
  }
}
