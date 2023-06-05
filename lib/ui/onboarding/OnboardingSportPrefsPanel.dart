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
import 'package:illinois/ui/athletics/AthleticsTeamsWidget.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class OnboardingSportPrefsPanel extends StatefulWidget with OnboardingPanel {
  final Map<String, dynamic>? onboardingContext;
  OnboardingSportPrefsPanel({this.onboardingContext});

  @override
  _OnboardingSportPrefsPanelState createState() => _OnboardingSportPrefsPanelState();
}

class _OnboardingSportPrefsPanelState extends State<OnboardingSportPrefsPanel> {
  bool _allowNext = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                alignment: Alignment.lerp(Alignment.center, Alignment.bottomCenter, 0.3)!,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: <Widget>[
                            Container(decoration: BoxDecoration(color: Styles().colors!.background)),
                            Padding(
                                padding: EdgeInsets.only(left: 64, right: 64, top: 30),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Semantics(
                                    label: getTitleText(),
                                    hint: getTitleHint(),
                                    excludeSemantics: true,
                                    child: Text(
                                      getTitleText(),
                                      style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 24, color: Styles().colors!.fillColorPrimary),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )),
                            Align(
                                alignment: Alignment.topLeft,
                                child: OnboardingBackButton(
                                    padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20),
                                    onTap: () {
                                      Analytics().logSelect(target: "Back");
                                      Navigator.pop(context);
                                    })),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    child: Padding(
                      padding: EdgeInsets.only(top: 108, bottom: 96, left: 16, right: 16),
                      child: ScrollableAthleticTeams(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: RoundedButton(
                          label: Localization().getStringEx('panel.onboarding.sports.button.continue.title', 'Explore Illinois'),
                          hint: Localization().getStringEx('panel.onboarding.sports.button.continue.hint', ''),
                          textStyle: _allowNext ? Styles().textStyles?.getTextStyle("widget.button.title.large.fat.secondary") : Styles().textStyles?.getTextStyle("widget.button.disabled.title.large.fat.variant"),
                          enabled: _allowNext,
                          backgroundColor: (Styles().colors!.background),
                          borderColor: (_allowNext ? Styles().colors!.fillColorSecondary : Styles().colors!.fillColorPrimaryTransparent03),
                          onTap: () => pushNextPanel()),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ],
    ));
  }

  void pushNextPanel() {
    Analytics().logSelect(target: "Explore Illinois");
    Onboarding().next(context, widget);
  }
  
  getTitleText() {
    return Localization().getStringEx('panel.onboarding.sports.label.description', 'Select your favorite Illini sports to follow');
  }

  getTitleHint() {
    return Localization().getStringEx('panel.onboarding.sports.label.description.hint', "Header 1");
  }
}

class ScrollableAthleticTeams extends AthleticsTeamsWidget {
  @override
  AthleticsTeamsWidgetState createState() => _ScrollableAthleticTeamsState();
}

class _ScrollableAthleticTeamsState extends AthleticsTeamsWidgetState {
  @override
  Widget build(BuildContext context) {
    return
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildMenSectionHeader(),
            Expanded(child: SingleChildScrollView(child: Column(children: buildSportList(menSports)))),
            Container(
              height: 20,
            ),
            buildWomenSectionHeader(),
            Expanded(child: SingleChildScrollView(child: Column(children: buildSportList(womenSports)))),
          ],
        );
  }
}
