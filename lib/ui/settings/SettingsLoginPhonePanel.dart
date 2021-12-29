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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppNavigation.dart';
import 'package:illinois/service/Connectivity.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/ui/onboarding/OnboardingLoginPhoneVerifyPanel.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/utils/Utils.dart';

class SettingsLoginPhonePanel extends StatefulWidget{
  _SettingsLoginPhonePanelState createState() => _SettingsLoginPhonePanelState();
}

class _SettingsLoginPhonePanelState extends State<SettingsLoginPhonePanel> {
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
    String titleString = Localization().getStringEx('panel.settings.login.phone.label.title', 'Verify your phone number')!;
    String skipTitle = Localization().getStringEx('panel.settings.login.phone.button.dont_continue.title', 'Not right now')!;
    return Scaffold(
        backgroundColor: Styles().colors!.background,
        body: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Image.asset(
                      "images/login-header.png",
                      fit: BoxFit.fitWidth,
                      width: MediaQuery.of(context).size.width,
                      excludeFromSemantics: true,
                    ),
                    OnboardingBackButton(
                        padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20),
                        onTap: () {
                          Analytics.instance.logSelect(target: "Back");
                          Navigator.pop(context);
                        }),
                  ],
                ),
                Container(
                  height: 24,
                ),
                Semantics(
                  label: titleString,
                  hint: Localization().getStringEx('panel.settings.login.phone.label.title.hint', ''),
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
                    child: Text(Localization().getStringEx('panel.settings.login.phone.label.description', 'This saves your preferences so you can have the same experience on more than one device.')!,
                        textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 20, color: Styles().colors!.fillColorPrimary))),
                Container(
                  height: 32,
                ),
                Expanded(
                  child: Container(),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: RoundedButton(
                        label: Localization().getStringEx('panel.settings.login.phone.button.continue.title', 'Verify My Phone Number'),
                        hint: Localization().getStringEx('panel.settings.login.phone.button.continue.hint', ''),
                        borderColor: Styles().colors!.fillColorSecondary,
                        backgroundColor: Styles().colors!.background,
                        textColor: Styles().colors!.fillColorPrimary,
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
                              hint: Localization().getStringEx('panel.settings.login.phone.button.dont_continue.hint', 'Skip verification'),
                              button: true,
                              excludeSemantics: true,
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 24),
                                child: Text(
                                  skipTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Styles().colors!.fillColorPrimary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Styles().colors!.fillColorSecondary,
                                    fontFamily: Styles().fontFamilies!.medium,
                                    fontSize: 16,
                                  ),
                                ),
                              )),
                        )),
                  ],
                )
              ],
            ),
            _progress
                ? Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
                : Container(),
          ],
        ));
  }

  void _onLoginTapped() {
    Analytics.instance.logSelect(target: "Phone Verification");
    if (Connectivity().isNotOffline) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => OnboardingLoginPhoneVerifyPanel(onFinish: _didPhoneVer,)));
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.phone_ver', 'Verify Your Phone Number is not available while offline.'));
    }
  }

  void _didPhoneVer(_) {
    Navigator.of(context).popUntil((Route route){
      return AppNavigation.routeRootWidget(route, context: context)?.runtimeType == widget.runtimeType;
    });
    Navigator.pop(context,true);

  }

  void _onSkipTapped() {
    Navigator.pop(context);
  }
}