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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';

class Onboarding2GetStartedPanel extends StatefulWidget with Onboarding2Panel {
  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  Onboarding2GetStartedPanel({ this.onboardingCode = '', this.onboardingContext }) :
    super(key: GlobalKey<_Onboarding2GetStartedPanelState>());

  GlobalKey<_Onboarding2GetStartedPanelState>? get globalKey => (super.key is GlobalKey<_Onboarding2GetStartedPanelState>) ?
    (super.key as GlobalKey<_Onboarding2GetStartedPanelState>) : null;

  @override
  bool get onboardingProgress => (globalKey?.currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => globalKey?.currentState?.onboardingProgress = value;

  @override
  State<StatefulWidget> createState() => _Onboarding2GetStartedPanelState();
}

class _Onboarding2GetStartedPanelState extends State<Onboarding2GetStartedPanel> {

  bool _onboardingProgress = false;

  @override
  Widget build(BuildContext context) =>
    Scaffold(backgroundColor: Styles().colors.background, body:
      SwipeDetector(onSwipeLeft: () => _onboardingNext(), child:
        Column(children: [
          Expanded(child:
            SingleChildScrollView(child:
              Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
                Semantics(hint: Localization().getStringEx("common.heading.one.hint","Header 1"), header: true, child:
                  Onboarding2TitleWidget(title: Localization().getStringEx("panel.onboarding2.get_started.title", "A Smart Campus\nIn Your Pocket",)),
                ),
                Container(height: 14,),
                Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
                  Text(Localization().getStringEx("panel.onboarding2.get_started.description", "From Memorial Stadium to the Quad and beyond, the {{app_title}} app connects you to our campus ecosystem.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
                    textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.onboarding2.get_started.description"),),
                ),
              ]),
            )
          ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8), child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              RoundedButton(
                label: Localization().getStringEx("panel.onboarding2.get_started.button.continue.title", 'Continue'),
                hint: Localization().getStringEx("panel.onboarding2.get_started.button.continue.hint", ''),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                borderColor: Styles().colors.fillColorSecondary,
                backgroundColor: Styles().colors.white,
                progress: _onboardingProgress,
                onTap: () => _onTapContinue(context),
              ),
              Onboarding2UnderlinedButton(
                title: Localization().getStringEx("panel.onboarding2.get_started.button.returning_user.title", "Returning user?"),
                hint: Localization().getStringEx("panel.onboarding2.get_started.button.returning_user.hint", ""),
                onTap: () => _onReturningUser(context),
              )
            ],),
          ),
        ]),
      ),
    );

  void _onReturningUser(BuildContext context){
    Analytics().logSelect(target: Localization().getStringEx("panel.onboarding2.get_started.button.continue.title", 'Continue', language: 'en'));
    _onboardingNext(true);
  }

  void _onTapContinue(BuildContext context) {
    Analytics().logSelect(target: Localization().getStringEx("panel.onboarding2.get_started.button.returning_user.title", "Returning user?", language: 'en'));
    _onboardingNext(false);
  }

  // Onboarding

  bool get onboardingProgress => _onboardingProgress;
  set onboardingProgress(bool value) {
    setStateIfMounted(() {
      _onboardingProgress = value;
    });
  }

  void _onboardingNext([bool returningUser = false]) async {
    Onboarding2().privacyReturningUser = returningUser;
    Onboarding2().next(context, widget);
  }
}
