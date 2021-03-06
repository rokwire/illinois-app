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
import 'package:illinois/main.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/ui/onboarding/onboarding2/Onboadring2RolesPanel.dart';
import 'package:illinois/ui/onboarding/onboarding2/Onboarding2Widgets.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/service/Styles.dart';

class Onboarding2GetStartedPanel extends StatelessWidget {
  Onboarding2GetStartedPanel();

  @override
  Widget build(BuildContext context) {
    
    App.instance.homeContext = context;
    Analytics().accessibilityState = MediaQuery.of(context).accessibleNavigation;

    return Scaffold(body: SafeArea(child:
            Container(
              color: Styles().colors.background,
              child:ScalableScrollView(
              scrollableChild: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Semantics(
                    hint: Localization().getStringEx("app.common.heading.one.hint","Header 1"),
                    header: true,
                    child: Onboarding2TitleWidget(title: Localization().getStringEx("panel.onboarding2.get_started.title", "A smart campus in your pocket",)),
                  ),
                  Container(height: 14,),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(Localization().getStringEx("panel.onboarding2.get_started.description", "From Memorial Stadium to the Quad and beyond, the Illinois app connects you to our campus ecosystem."),
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
                      label: Localization().getStringEx("panel.onboarding2.get_started.button.continue.title", 'Continue'),
                      hint: Localization().getStringEx("panel.onboarding2.get_started.button.continue.hint", ''),
                      fontSize: 16,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      borderColor: Styles().colors.fillColorSecondary,
                      backgroundColor: Styles().colors.white,
                      textColor: Styles().colors.fillColorPrimary,
                      onTap: () => _onGoNext(context),
                    ),
                   Onboarding2UnderlinedButton(
                     title: Localization().getStringEx("panel.onboarding2.get_started.button.returning_user.title", "Returning user?"),
                     hint: Localization().getStringEx("panel.onboarding2.get_started.button.returning_user.hint", ""),
                     onTap: (){_onReturningUser(context);},
                   )
                  ],
                ),
              ),
            )))
    );
  }

  void _onReturningUser(BuildContext context){
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2RolesPanel(returningUser: true,)));
  }

  void _onGoNext(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2RolesPanel()));
  }
}
