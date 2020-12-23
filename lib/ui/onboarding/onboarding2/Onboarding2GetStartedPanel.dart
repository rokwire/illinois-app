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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/ui/onboarding/onboarding2/Onboadring2RolesPanel.dart';
import 'package:illinois/ui/onboarding/onboarding2/Onboarding2Widgets.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/service/Styles.dart';

class Onboarding2GetStartedPanel extends StatelessWidget {
  Onboarding2GetStartedPanel();

  @override
  Widget build(BuildContext context) {
    
    Analytics().accessibilityState = MediaQuery.of(context).accessibleNavigation;

    return Scaffold(body: SafeArea(child:
            Container(
              color: Styles().colors.background,
              child:ScalableScrollView(
              scrollableChild: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Onboarding2TitleWidget(title: "A smart campus in your pocket.",),
                  Container(height: 14,),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("From Memorial Stadium to the Quad and beyond, the Illinois app connects you to our campus ecosystem.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontFamily: Styles().fontFamilies.regular,
                            fontSize: 16,
                            color: Styles().colors.fillColorPrimary,
                            ),
                    ),
                  ),
              ]),
              bottomNotScrollableWidget:
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24,vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ScalableRoundedButton(
                      label: 'Continue',
                      hint: '',
                      fontSize: 16,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      borderColor: Styles().colors.fillColorSecondary,
                      backgroundColor: Styles().colors.white,
                      textColor: Styles().colors.fillColorPrimary,
                      onTap: () => _onGoNext(context),
                    ),
                    GestureDetector(
                      onTap: () {
                        Analytics.instance.logSelect(target: 'Returning User') ;
                        _onReturningUser(context);
                      },
                      child: Semantics(
                          label: "Returning user?",
                          hint: '',
                          button: true,
                          excludeSemantics: true,
                          child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                "Returning user?",
                                style: TextStyle(
                                    fontFamily: Styles().fontFamilies.medium,
                                    fontSize: 16,
                                    color: Styles().colors.fillColorPrimary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Styles().colors.fillColorSecondary,
                                    decorationThickness: 1,
                                    decorationStyle:
                                    TextDecorationStyle.solid),
                              ))),
                    )
                  ],
                ),
              ),
            )))
    );
  }

  void _onReturningUser(BuildContext context){
    Onboarding2().finish(context);
  }

  void _onGoNext(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2RolesPanel()));
  }
}
