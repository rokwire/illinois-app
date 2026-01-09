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
import 'package:illinois/ui/widgets/PrivacySlider.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'Onboarding2Widgets.dart';

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
      appBar: AppBar(backgroundColor: Styles().colors.fillColorPrimary, toolbarHeight: 0,),
      body: SwipeDetector(onSwipeLeft: _onboardingNext, onSwipeRight: _onboardingBack, child:
        Column(children: [
          Expanded(child:
            SingleChildScrollView(child:
              Column(children:[
                Container(color: Styles().colors.fillColorPrimary, child:
                  Column(children: <Widget>[
                    Row(children: [
                      Onboarding2BackButton(padding: const EdgeInsets.all(16), imageColor: Styles().colors.white, onTap: _onTapBack,),
                      Expanded(child:
                        Align(alignment: Alignment.centerRight, child:
                          Semantics(
                            label: Localization().getStringEx('panel.onboarding2.privacy.level.button.privacy_policy.title', "Privacy Notice "),
                            hint: Localization().getStringEx('panel.onboarding2.privacy.level.button.privacy_policy.hint', ''),
                            button: true,
                            excludeSemantics: true,
                            child: _buildPrivacyPolicyButton(context)
                          ),
                        )
                      ),
                    ],),

                    Container(height: 18,),

                    Semantics(
                      label: _privacyTitle,
                      hint: Localization().getStringEx("common.heading.one.hint","Header 1"),
                      header: true,
                      excludeSemantics: true,
                      child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                        Align(alignment: Alignment.topCenter, child:
                          Text(_privacyTitle, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.onboarding2.heading.title"),)
                        ),
                      )
                    ),
                    Container(height: 35,),
                    Stack(children: [
                      CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background,), child:
                        Container(height: 90,),
                      ),
                      Align(alignment: Alignment.topRight, child:
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                          _privacyBadge,
                        ),
                      )
                    ],)
                  ])
                ),

                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                  Text(_privacyLongDescription ?? '', textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.description.regular"),)
                ),

                Padding(padding: EdgeInsets.symmetric(vertical:24, horizontal: 20), child:
                  PrivacyLevelSlider(initialValue: _privacyLevel.toDouble(), readOnly: true, color: Styles().colors.background,),
                ),
              ]),
            )
          ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 24), child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Container(height: 16,),
              Text(Localization().getStringEx("panel.onboarding2.privacy.level.label.continue.description", "You can adjust what you store and share at any time in the Privacy Center."), textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.info.small"),),
              Padding(padding: EdgeInsets.only(bottom: 48, top: 16), child:
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
              ),
            ],),
          ),
        ])
      )
    );

  Widget get _privacyBadge =>
    Semantics(label: Localization().getStringEx('panel.onboarding2.privacy.level.badge.privacy_level.title', "Privacy Level: ") + _privacyLevel.toString(), excludeSemantics: true, child:
      Stack(children: [
        Styles().images.getImage((_privacyLevel == 5) ? "images/privacy_box_selected.png" : "images/privacy_box_deselected.png", size: 50, fit: BoxFit.fitWidth, excludeFromSemantics: true,) ?? Container(),
        Positioned.fill(child:
          Center(child:
            Text(_privacyLevel.toString(), textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.onboarding2.privacy.badge"))
          )
        )
      ],)
    );

  Widget _buildPrivacyPolicyButton(BuildContext context) =>
    InkWell(onTap: () => _onTapPrivacyPolicy(context), child:
      Padding(padding: EdgeInsets.symmetric(vertical: 19, horizontal: 16), child:
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors.fillColorSecondary, width: 1, ),)),
          padding: EdgeInsets.only(bottom: 2),
          child: Wrap(children: [
            Text(Localization().getStringEx('panel.onboarding2.privacy.level.button.privacy_policy.title', "Privacy Notice "), style: Styles().textStyles.getTextStyle("widget.colourful_button.title.regular")),
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
      case 1 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_long.1.title', "Based on your answers, no personal information will be stored or shared. You can only browse information in the app.");
      case 2 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_long.2.title', "Based on your answers, your location is used to explore campus and find things nearby. Your data will not be stored or shared.");
      case 3 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_long.3.title', "Based on your answers, your data will be securely stored for you to access.");
      case 4 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_long.4.title', "Based on your answers, your data will be securely stored for you to access.");
      case 5 : return Localization().getStringEx('panel.onboarding2.privacy.level.description_long.5.title', "Based on your answers, your data will be securely stored and shared to enable the full smarts of the {{app_title}} app.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
      default: return Localization().getStringEx('panel.onboarding2.privacy.level.description_long.unknown.title', "Unknown privacy level");
    }
  }

  String get _continueButtonLabel {
    switch (_privacyLevel) {
      case 1 : return Localization().getStringEx('panel.onboarding2.privacy.level.button.start_browsing.title', "Start browsing");
      case 2 : return Localization().getStringEx('panel.onboarding2.privacy.level.button.start_exploring.title', "Start exploring");
      default: return Localization().getStringEx('panel.onboarding2.privacy.level.button.save_privacy.title', "Save Privacy Level");
    }

  }

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
