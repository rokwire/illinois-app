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
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class Onboarding2LoginPhoneOrEmailStatementPanel extends StatefulWidget with Onboarding2Panel {

  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  Onboarding2LoginPhoneOrEmailStatementPanel({ this.onboardingCode = '', this.onboardingContext });

  GlobalKey<_Onboarding2LoginPhoneOrEmailStatementPanelState>? get globalKey => (super.key is GlobalKey<_Onboarding2LoginPhoneOrEmailStatementPanelState>) ?
    (super.key as GlobalKey<_Onboarding2LoginPhoneOrEmailStatementPanelState>) : null;

  @override
  bool get onboardingProgress => (globalKey?.currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => globalKey?.currentState?.onboardingProgress = value;

  @override
  _Onboarding2LoginPhoneOrEmailStatementPanelState createState() => _Onboarding2LoginPhoneOrEmailStatementPanelState();
}

class _Onboarding2LoginPhoneOrEmailStatementPanelState extends State<Onboarding2LoginPhoneOrEmailStatementPanel> {
  bool _onboardingProgress = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String titleString = Localization().getStringEx('panel.onboarding2.phone_or_email_statement.title.text', 'Login by phone or email');
    EdgeInsetsGeometry backButtonInsets = EdgeInsets.only(left: 10, top: 20 + MediaQuery.of(context).padding.top, right: 20, bottom: 20);

    return Scaffold(backgroundColor: Styles().colors.background, body:
      Stack(children: <Widget>[
        Styles().images.getImage("header-login", fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true) ?? Container(),
        Column(children:[
          Expanded(child:
            SingleChildScrollView(child:
              Padding(padding: EdgeInsets.only(left: 18, right: 18, top: 148 + 24 + MediaQuery.of(context).padding.top, bottom: 24), child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Semantics(label: titleString, hint: Localization().getStringEx('panel.onboarding2.phone_or_email_statement.title.hint', ''), excludeSemantics: true, header:true, child:
                    Padding(padding: EdgeInsets.symmetric(horizontal: 18), child:
                      Center(child:
                        Text(titleString, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.onboarding2.login_email.heading.title")),
                      )
                    ),
                  ),
                  Container(height: 24,),
                  Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 32), child:
                    Text(Localization().getStringEx('panel.onboarding2.phone_or_email_statement.description', 'This saves your preferences so you can have the same experience on more than one device.'), textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.description.large"))
                  ),
                ]),
              ),
            )
          ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8), child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              RoundedButton(
                label: Localization().getStringEx('panel.onboarding2.phone_or_email_statement.continue.title', 'Continue'),
                hint: Localization().getStringEx('panel.onboarding2.phone_or_email_statement.continue.hint', ''),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                borderColor: Styles().colors.fillColorSecondary,
                backgroundColor: Styles().colors.surface,
                progress: _onboardingProgress,
                onTap: _onContinueTapped,
              ),
              Onboarding2UnderlinedButton(
                title: Localization().getStringEx('panel.onboarding2.phone_or_email_statement.dont_continue.title', 'Not right now'),
                hint: Localization().getStringEx('panel.onboarding2.phone_or_email_statement.dont_continue.hint', 'Skip verification'),
                onTap: (){_onSkipTapped();},
              )
            ],),
          )
        ]),
        OnboardingBackButton(padding: backButtonInsets, onTap: () { Analytics().logSelect(target: "Back"); Navigator.pop(context); }),
      ],),
    );
  }

  void _onContinueTapped() {
    Analytics().logSelect(target: 'Continue');
    _onboardingNext(true);
  }

  void _onSkipTapped() {
    Analytics().logSelect(target: 'Not right now');
    _onboardingNext();
  }

  // Onboarding

  bool get onboardingProgress => _onboardingProgress;
  set onboardingProgress(bool value) {
    setStateIfMounted(() {
      _onboardingProgress = value;
    });
  }

  //void _onboardingBack() => Navigator.of(context).pop();
  void _onboardingNext([bool login = false]) {
    widget.onboardingContext?['login'] = login;
    Onboarding2().next(context, widget);
  }
}

