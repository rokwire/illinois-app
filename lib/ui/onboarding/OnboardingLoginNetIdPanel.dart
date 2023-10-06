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
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/onboarding.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class OnboardingLoginNetIdPanel extends StatefulWidget with OnboardingPanel {
  final Map<String, dynamic>? onboardingContext;
  OnboardingLoginNetIdPanel({this.onboardingContext});
  _OnboardingLoginNetIdPanelState createState() => _OnboardingLoginNetIdPanelState();
}

class _OnboardingLoginNetIdPanelState extends State<OnboardingLoginNetIdPanel> implements Onboarding2ProgressableState {
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
    String titleString = Localization().getStringEx('panel.onboarding.login.netid.label.title', 'Connect your NetID');
    String? skipTitle = Localization().getStringEx('panel.onboarding.login.netid.button.dont_continue.title', 'Not Right Now');
    return Scaffold(
        backgroundColor: Styles().colors!.background,
        body: Stack(
          children: <Widget>[
        Column(children: [
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
                    hint: Localization().getStringEx('panel.onboarding.login.netid.label.title.hint', ''),
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
                      child: Text(Localization().getStringEx('panel.onboarding.login.netid.label.description', 'Log in with your NetID to use academic and residence hall specific features.'),
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
                  label: Localization().getStringEx('panel.onboarding.login.netid.button.continue.title', 'Sign In with NetID'),
                  hint: Localization().getStringEx('panel.onboarding.login.netid.button.continue.hint', ''),
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
/*                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: RoundedButton(
                            label: Localization().getStringEx('panel.onboarding.login.netid.button.continue.title', 'Log in with NetID'),
                            hint: Localization().getStringEx('panel.onboarding.login.netid.button.continue.hint', ''),
                            borderColor: Styles().colors.fillColorSecondary,
                            backgroundColor: Styles().colors.background,
                            textColor: Styles().colors.fillColorPrimary,
                            onTap: () => _onLoginTapped()),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                            child: GestureDetector(
                          onTap: () => _onSkipTapped(),
                          child: Semantics(
                              label: skipTitle,
                              hint: Localization().getStringEx('panel.onboarding.login.netid.button.dont_continue.hint', 'Skip verification'),
                              button: true,
                              excludeSemantics: true,
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 24),
                                child: Text(
                                  skipTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Styles().colors.fillColorPrimary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Styles().colors.fillColorSecondary,
                                    fontFamily: Styles().fontFamilies.medium,
                                    fontSize: 16,
                                  ),
                                ),
                              )),
                        )),
                      ],
                    )
                ]),*/
          ]),
            _progress
            ? Container(
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
            )
                : Container(),
        ]
    ));
  }

  Widget _buildDialogWidget(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              Localization().getStringEx('app.title', 'Illinois'),
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Text(
                Localization().getStringEx('logic.general.login_failed', 'Unable to login. Please try again later.'),
                textAlign: TextAlign.left,
                style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                    onPressed: () {
                      Analytics().logAlert(text: "Unable to login", selection: "Ok");
                      Navigator.pop(context);
                      //_finish();
                    },
                    child: Text(Localization().getStringEx('dialog.ok.title', 'OK')))
              ],
            )
          ],
        ),
      ),
    );
  }

  void _onLoginTapped() {
    Analytics().logSelect(target: 'Log in with NetID');
    if (_progress != true) {
      setState(() { _progress = true; });
      Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
        if (mounted) {
          if (result == Auth2OidcAuthenticateResult.succeeded) {
            FlexUI().update().then((_) {
              if (mounted) {
                setState(() { _progress = false; });
                _onContinue();
              }
            });
          }
          else if (result == Auth2OidcAuthenticateResult.failed) {
            setState(() { _progress = false; });
            showDialog(context: context, builder: (context) => _buildDialogWidget(context));
          }
          else {
            // login canceled
            setState(() { _progress = false; });
          }
        }
      });
    }
  }

  void _onSkipTapped() {
    Analytics().logSelect(target: 'Not right now');
    _onContinue();
  }

  void _onContinue() {
    // Hook this panels to Onboarding2
    Function? onContinue = (widget.onboardingContext != null) ? widget.onboardingContext!["onContinueAction"] : null;
    Function? onContinueEx = (widget.onboardingContext != null) ? widget.onboardingContext!["onContinueActionEx"] : null; 
    if (onContinueEx != null) {
      onContinueEx(this);
    }
    else if (onContinue != null) {
      onContinue();
    }
    else {
      Onboarding().next(context, widget);
    }
  }

  // Onboarding2ProgressableState

  @override
  bool get onboarding2Progress => _progress;
  
  @override
  set onboarding2Progress(bool progress) {
    if (mounted) {
      setState(() {
        _progress = progress;
      });
    }
  }

}
