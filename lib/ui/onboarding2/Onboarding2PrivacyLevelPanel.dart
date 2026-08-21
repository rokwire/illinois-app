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
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Onboarding2PrivacyLevelPanel extends StatefulWidget with Onboarding2Panel {
  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  Onboarding2PrivacyLevelPanel({ super.key, this.onboardingCode = '', this.onboardingContext });

  _Onboarding2PrivacyLevelPanelState? get _currentState => JsonUtils.cast(globalKey?.currentState);

  @override
  bool get onboardingProgress => (_currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => _currentState?.onboardingProgress = value;

  @override
  State<StatefulWidget> createState() => _Onboarding2PrivacyLevelPanelState();
}


class _Onboarding2PrivacyLevelPanelState extends State<Onboarding2PrivacyLevelPanel> {
  bool _onboardingProgress = false;

  @override
  Widget build(BuildContext context) =>
    Scaffold(backgroundColor: Styles().colors.background,
      body: SwipeDetector(onSwipeLeft: _onboardingNext, onSwipeRight: _onboardingBack, child:
        Column(children: [
          Stack(children: [
            Styles().images.getImage("header-privacy", fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true) ?? Container(),
            Visibility(visible: Navigator.canPop(context), child:
              Positioned(top: 0, left: 0, child:
                SafeArea(child:
                  OnboardingBackButton(padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20), onTap: _onTapBack),
                ),
              ),
            ),
          ],),
          Expanded(child:
            SafeArea(top: false, child:
              SingleChildScrollView(child:
                Column(children:[
                  Container(height: 8,),
                  Text(Localization().getStringEx('panel.onboarding2.privacy.level.label.eyebrow.title', 'PRIVACY LEVEL'), textAlign: TextAlign.center,
                    style: Styles().textStyles.getTextStyle("widget.button.title.extra_large"),
                  ),
                  Container(height: 16,),
                  _privacyBadge,
                  Container(height: 20,),
                  Semantics(
                    label: _privacyTitle,
                    hint: Localization().getStringEx("common.heading.one.hint","Header 1"),
                    header: true,
                    excludeSemantics: true,
                    child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                      Text(_privacyTitle, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.title.extra_huge.fat"),)
                    )
                  ),
                  Container(height: 16,),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 28), child:
                    Text(_privacyLongDescription ?? '', textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.description.regular"),)
                  ),
                  Container(height: 24,),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 28), child:
                    _privacyNoteText,
                  ),
                  Container(height: 24,),
                ]),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8), child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              RoundedButton(
                label: _continueButtonLabel,
                hint: Localization().getStringEx('panel.onboarding2.privacy_statement.button.continue.hint', ''),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Styles().colors.white,
                borderColor: Styles().colors.fillColorSecondaryVariant,
                progress: _onboardingProgress,
                onTap: _onTapContinue,
              ),
              Semantics(
                label: Localization().getStringEx('panel.onboarding2.privacy.level.button.privacy_policy.title', "Privacy Notice "),
                hint: Localization().getStringEx('panel.onboarding2.privacy.level.button.privacy_policy.hint', ''),
                button: true,
                excludeSemantics: true,
                child: _buildPrivacyPolicyButton(context)
              ),
            ],),
          ),
        ])
      )
    );

  Widget get _privacyBadge =>
    Semantics(label: Localization().getStringEx('panel.onboarding2.privacy.level.badge.privacy_level.title', "Privacy Level: ") + _privacyLevel.toString(), excludeSemantics: true, child:
      Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        Styles().images.getImage("lock-illustration", excludeFromSemantics: true, width: 120, fit: BoxFit.fitWidth) ?? Container(),
        Positioned(right: -20, bottom: 0, child:
          Container(
              height: 70,
              width: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  border: Border.all(color: Styles().colors.fillColorPrimary, width: 2),
                  color: Styles().colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(100))),
              child: Container(
                  height: 60,
                  width: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      border: Border.all(color: Styles().colors.fillColorSecondary, width: 2),
                      color: Styles().colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(100))),
                  child: Text(_privacyLevel.toString(), textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.title.extra_large.extra_fat")))),
        ),
      ],)
    );

  Widget get _privacyNoteText =>
    RichText(textAlign: TextAlign.center, text:
      TextSpan(children: [
        TextSpan(text: Localization().getStringEx('panel.onboarding2.privacy.level.label.note.title', 'NOTE: '),
          style: Styles().textStyles.getTextStyle("widget.description.regular.fat"),
        ),
        if (_privacyLevel < 4)
          TextSpan(text: Localization().getStringEx('panel.onboarding2.privacy.level.label.netid_required.description', 'To sign in with your NetID, privacy level must be 4 or 5. '),
            style: Styles().textStyles.getTextStyle("widget.description.regular"),
          ),
        TextSpan(text: Localization().getStringEx("panel.onboarding2.privacy.level.label.continue.description", "You can adjust your privacy at any time under Settings."),
          style: Styles().textStyles.getTextStyle("widget.description.regular"),
        ),
      ]),
    );

  Widget _buildPrivacyPolicyButton(BuildContext context) =>
    InkWell(onTap: () => _onTapPrivacyPolicy(context), child:
      Padding(padding: EdgeInsets.symmetric(vertical: 19, horizontal: 16), child:
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors.fillColorSecondary, width: 1, ),)),
          padding: EdgeInsets.only(bottom: 2),
          child: Wrap(children: [
            Text(Localization().getStringEx('panel.onboarding2.privacy.level.button.privacy_policy.title', "Privacy Notice "), style: Styles().textStyles.getTextStyle("widget.title.small")),
            Padding(padding: EdgeInsets.only(bottom: 3), child:
              Styles().images.getImage("external-link", excludeFromSemantics: true)
            ),
          ],)
        )
      )
    );

  int get _privacyLevel {
    //TBD refactoring
    if (Onboarding2().privacyLocationServicesSelection) {
      if (Onboarding2().privacyStoreActivitySelection) {
        if (Onboarding2().privacyShareActivitySelection) {
          return 5;
        } else {
          //!privacyImprove
          return 3;
        }
      } else {
        //!getPersonalizeChoice
        return 2;
      }
    } else {
      //!privacyEnableLocationServices
      if (Onboarding2().privacyStoreActivitySelection) {
        if (Onboarding2().privacyShareActivitySelection) {
          return 5;
        } else {
          //!privacyImprove
          return 3;
        }
      }else {
        //!getPersonalizeChoice
        return 1;
      }
    }
  }

  String get _privacyTitle {
    switch (_privacyLevel) {
      case 1 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_short.1.title', "Browse privately");
      case 2 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_short.2.title', "Explore privately ");
      case 3 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_short.3.title', "Personalized for you");
      case 4 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_short.4.title', "Personalized for you");
      case 5 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_short.5.title', "Full Access");
      default: return Localization().getStringEx('panel.onboarding2.privacy.level.description_short.unknown.title', "Unknown privacy level");
    }
  }

  String? get _privacyLongDescription {
    switch(_privacyLevel) {
      case 1 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_long.1.title', "Based on your choices, no personal information will be stored or shared.");
      case 2 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_long.2.title', "Based on your choices, your data will not be stored or shared.");
      case 3 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_long.3.title', "Based on your choices, your data will be securely stored for you to access.");
      case 4 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_long.4.title', "Based on your choices, your data will be securely stored for you to access.");
      case 5 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_long.5.title', "Based on your choices, your data will be securely stored and shared to enable the full features of the {{app_title}} app.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
      default: return Localization().getStringEx('panel.onboarding2.privacy.level.description_long.unknown.title', "Unknown privacy level");
    }
  }

  String get _continueButtonLabel =>
    Localization().getStringEx('panel.onboarding2.privacy.level.button.save_privacy.title', "Save Privacy Level");

  void _onTapPrivacyPolicy(BuildContext context) {
    Analytics().logSelect(target: "Privacy Statement");
    AppPrivacyPolicy.launch(context);
  }

  void _onTapBack() {
    Analytics().logSelect(target: "Back");
    _onboardingBack();
  }

  void _onTapContinue() {
    Analytics().logSelect(target: "Continue");
    _onboardingNext();
  }

  // Onboarding

  bool get onboardingProgress => _onboardingProgress;
  set onboardingProgress(bool value) {
    setStateIfMounted(() {
      _onboardingProgress = value;
    });
  }

  void _onboardingBack() => Navigator.of(context).pop();
  void _onboardingNext() {
    Auth2().prefs?.privacyLevel = _privacyLevel;
    Storage().privacyUpdateVersion = Config().appPrivacyVersion;
    Onboarding2().next(context, widget);
  }
}
