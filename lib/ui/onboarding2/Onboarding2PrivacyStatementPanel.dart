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
import 'package:neom/service/Onboarding2.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';


class Onboarding2PrivacyStatementPanel extends StatefulWidget with Onboarding2Panel {

  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  Onboarding2PrivacyStatementPanel({ this.onboardingCode = '', this.onboardingContext });

  GlobalKey<_Onboarding2PrivacyStatementPanelState>? get globalKey => (super.key is GlobalKey<_Onboarding2PrivacyStatementPanelState>) ?
    (super.key as GlobalKey<_Onboarding2PrivacyStatementPanelState>) : null;

  @override
  bool get onboardingProgress => (globalKey?.currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => globalKey?.currentState?.onboardingProgress = value;

  @override
  State<StatefulWidget> createState() => _Onboarding2PrivacyStatementPanelState();
}


class _Onboarding2PrivacyStatementPanelState extends State<Onboarding2PrivacyStatementPanel> {

  bool _onboardingProgress = false;

  @override
  Widget build(BuildContext context) {
    String titleText = Localization().getStringEx('panel.onboarding2.privacy_statement.label.title', 'Control Your Data Privacy');
    String titleText2 = Localization().getStringEx('panel.onboarding2.privacy_statement.label.title2', '');
    String descriptionText = Localization().getStringEx('panel.onboarding2.privacy_statement.label.description', 'Choose what information you want to store and share to get a recommended privacy level.');

    String descriptionText1 = Localization().getStringEx('panel.onboarding2.privacy_statement.label.description1', 'Please read the ');
    String descriptionText2 = Localization().getStringEx('panel.onboarding2.privacy_statement.label.description2', 'Privacy Notice ');
    String descriptionText3 = Localization().getStringEx('panel.onboarding2.privacy_statement.label.description3', '. Your continued use of the app assumes that you have read and agree with it.');

    return Scaffold(
      backgroundColor: Styles().colors.background,
      body: SafeArea(child:
        SwipeDetector(
          onSwipeLeft: _onboardingNext,
          onSwipeRight: _onboardingBack,
          child: Column(children: [
            Expanded(child:
              SingleChildScrollView(child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
                  Align(alignment: Alignment.centerLeft, child:
                    Onboarding2BackButton( padding: const EdgeInsets.all(16), onTap: _onTapBack,),
                  ),

                  Styles().images.getImage("lock-illustration", excludeFromSemantics: true, width: 130, fit: BoxFit.fitWidth) ?? Container(),

                  Semantics(
                    label: titleText + titleText2,
                    hint: Localization().getStringEx("common.heading.one.hint","Header 1"),
                    header: true,
                    excludeSemantics: true,
                    child: Padding(padding: EdgeInsets.symmetric(horizontal: 42, vertical: 12), child:
                      RichText(textAlign: TextAlign.center, text:
                        TextSpan(children: <TextSpan>[
                          TextSpan(text:titleText , style: Styles().textStyles.getTextStyle("panel.onboarding2.privacy_statement.title.fat")),
                          TextSpan(text:titleText2, style: Styles().textStyles.getTextStyle("panel.onboarding2.privacy_statement.title.regular")),
                        ])
                      ),
                    ),
                  ),

                  Semantics(label: descriptionText, excludeSemantics: true, child:
                    Padding(padding: EdgeInsets.symmetric(horizontal: 24), child:
                      Text(descriptionText, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.onboarding2.privacy_statement.description.regular"))
                    )
                  ),
                ]),
              ),
            ),
            Padding(padding: EdgeInsets.symmetric(horizontal: 24), child:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                Container(height: 16,),
                Semantics(
                  container: true,
                  label: descriptionText1 + ", "+ descriptionText2+","+descriptionText3,
                  button: true,
                  child: InkWell(onTap: _onTapPrivacyPolicy, child:
                    Padding(padding: EdgeInsets.symmetric(horizontal: 24), child:
                      RichText(textAlign: TextAlign.center, text:
                        TextSpan(style: Styles().textStyles.getTextStyle("widget.info.small"), children: <TextSpan>[
                          TextSpan(text:descriptionText1, semanticsLabel: "",),
                          TextSpan(text:descriptionText2, semanticsLabel: "", style: Styles().textStyles.getTextStyle("widget.button.title.small.underline"), children: [
                            WidgetSpan(child:
                              Container(padding: EdgeInsets.only(bottom: 4), child:
                                Styles().images.getImage("external-link", excludeFromSemantics: true,)
                              )
                            )
                          ]),
                          TextSpan(text:descriptionText3, semanticsLabel: ""),
                        ])
                      ),
                    )
                  )
                ),
                Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
                  RoundedButton(
                    label: Localization().getStringEx('panel.onboarding2.privacy_statement.button.continue.title', 'Begin'),
                    hint: Localization().getStringEx('panel.onboarding2.privacy_statement.button.continue.hint', ''),
                    textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Styles().colors.surface,
                    borderColor: Styles().colors.fillColorSecondaryVariant,
                    progress: _onboardingProgress,
                    onTap: () => _onTapContinue(context),
                  ),
                ),
              ],),
            ),
          ],)
        )
      )
    );
  }

  void _onTapPrivacyPolicy() {
    Analytics().logSelect(target: "Privacy Statement");
    AppPrivacyPolicy.launch(context);
  }

  void _onTapBack() {
    Analytics().logSelect(target: "Back");
    _onboardingBack();
  }

  void _onTapContinue(BuildContext context) {
    Analytics().logSelect(target: "Begin");
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
  void _onboardingNext() => Onboarding2().next(context, widget);
}
