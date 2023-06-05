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
import 'package:rokwire_plugin/service/onboarding.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';
import 'package:rokwire_plugin/service/styles.dart';

class OnboardingGetStartedPanel extends StatelessWidget with OnboardingPanel {
  
  final Map<String, dynamic>? onboardingContext;
  OnboardingGetStartedPanel({this.onboardingContext});

  @override
  Widget build(BuildContext context) {

    String? strWelcome = Localization().getStringEx(
        'panel.onboarding.get_started.image.welcome.title',
        'Welcome to {{app_title}}').
          replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
    String strPersonalizedRecommendations = Localization().getStringEx(
        'panel.onboarding.get_started.label.personalized_recommendations',
        'Get personalized recommendations for the');
    String strUniversityofIllinois = Localization().getStringEx(
        'app.univerity_name',
        'University of Illinois');

    return Scaffold(body: SwipeDetector(
        onSwipeLeft: () => _goNext(context),
        child: Column(children: <Widget>[
          Expanded(child:
          Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Styles().images?.getImage('splash', excludeFromSemantics: true, fit: BoxFit.cover, semanticLabel: strWelcome,
                height: double.infinity,
                width: double.infinity,) ?? Container(),
              Column(children: <Widget>[
                Expanded(child: Container(),),
                Padding(
                padding: EdgeInsets.all(24),
                        child: Column(
                          children: <Widget>[
                            Semantics(
                                label:
                                "$strPersonalizedRecommendations $strUniversityofIllinois",
                                excludeSemantics: true,
                                child: Column(children: <Widget>[
                                  Text(
                                    strPersonalizedRecommendations,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: Styles().fontFamilies!.medium,
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    strUniversityofIllinois,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ])
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: RoundedButton(
                                label: Localization().getStringEx(
                                    'panel.onboarding.get_started.button.get_started.title',
                                    'Get Started'),
                                hint: Localization().getStringEx(
                                    'panel.onboarding.get_started.button.get_started.hint',
                                    ''),
                                textStyle: Styles().textStyles?.getTextStyle("widget.colourful_button.title.large.accent"),
                                backgroundColor: Styles().colors!.fillColorPrimary,
                                onTap: () => _goNext(context),
                                borderColor: Styles().colors!.fillColorPrimary,
                                secondaryBorderColor: Styles().colors!.white,
                              ),
                            )
                          ],
              ))
              ],)
            ]))],) ));
  }

  void _goNext(BuildContext context) {
    Analytics().logSelect(target: "Get Started") ;
    return Onboarding().next(context, this);
  }
}
