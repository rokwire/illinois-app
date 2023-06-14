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
import 'package:rokwire_plugin/service/onboarding.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/onboarding/OnboardingLoginPhoneVerifyPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class OnboardingLoginPhonePanel extends StatefulWidget with OnboardingPanel {

  final Map<String, dynamic>? onboardingContext;
  final ValueSetter<dynamic>? onFinish;

  OnboardingLoginPhonePanel({this.onboardingContext, this.onFinish});

  _OnboardingLoginPhonePanelState createState() => _OnboardingLoginPhonePanelState();
}

class _OnboardingLoginPhonePanelState extends State<OnboardingLoginPhonePanel> {
  bool _progress = false;

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
    String titleString = Localization().getStringEx('panel.onboarding.login.phone.label.title', 'Verify your phone number');
    String? skipTitle = Localization().getStringEx('panel.onboarding.login.phone.button.dont_continue.title', 'Not right now');
    return Scaffold(
        backgroundColor: Styles().colors!.background,
        body: Stack(
          children: <Widget>[
            Column(children:[
              Expanded(child:
                SingleChildScrollView(child:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Stack(
                        children: <Widget>[
                          Styles().images?.getImage(
                            "header-login",
                            fit: BoxFit.fitWidth,
                            width: MediaQuery.of(context).size.width,
                            excludeFromSemantics: true,
                          ) ?? Container(),
                          OnboardingBackButton(
                              padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20),
                              onTap: () {
                                Analytics().logSelect(target: "Back");
                                Navigator.pop(context);
                              }),
                        ],
                      ),
                      Container(
                        height: 24,
                      ),
                      Semantics(
                        label: titleString,
                        hint: Localization().getStringEx('panel.onboarding.login.phone.label.title.hint', ''),
                        excludeSemantics: true,
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18),
                            child: Center(
                              child: Text(titleString,
                                  textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 36, color: Styles().colors!.fillColorPrimary)),
                            )),
                      ),
                      Container(
                        height: 24,
                      ),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(Localization().getStringEx('panel.onboarding.login.phone.label.description', 'This saves your preferences so you can have the same experience on more than one device.'),
                              textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 20, color: Styles().colors!.fillColorPrimary))),
                      Container(
                        height: 32,
                      ),
                      ]),
              )),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24,vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RoundedButton(
                      label: Localization().getStringEx('panel.onboarding.login.phone.button.continue.title', 'Verify My Phone Number'),
                      hint: Localization().getStringEx('panel.onboarding.login.phone.button.continue.hint', ''),
                      textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      borderColor: Styles().colors!.fillColorSecondary,
                      backgroundColor: Styles().colors!.white,
                      onTap: _onLoginTapped,
                    ),
                    Onboarding2UnderlinedButton(
                      title: skipTitle,
                      hint: Localization().getStringEx('panel.onboarding.login.netid.button.dont_continue.hint', 'Skip verification'),
                      onTap: (){_onSkipTapped();},
                    )
                  ],
                ),
              )
          ]),
                    _progress
                    ? Container(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                    )
                        : Container(),
              ],
            ),);
  }

  void _onLoginTapped() {
    Analytics().logSelect(target: 'Verify My Phone Number');
    if (widget.onboardingContext != null) {
      widget.onboardingContext!['shouldVerifyPhone'] = true;
      Onboarding().next(context, widget);
    }
    else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => OnboardingLoginPhoneVerifyPanel(onFinish: widget.onFinish)));
    }
  }

  void _onSkipTapped() {
    Analytics().logSelect(target: 'Not right now');
    Function? onSuccess = widget.onboardingContext!=null? widget.onboardingContext!["onContinueAction"] : null; // Hook this panels to Onboarding2
    if(onSuccess!=null){
      onSuccess();
    } else if (widget.onboardingContext != null) {
      widget.onboardingContext!['shouldVerifyPhone'] = false;
      Onboarding().next(context, widget);
    }
    else if (widget.onFinish != null) {
      widget.onFinish!(null);
    }
  }
}
