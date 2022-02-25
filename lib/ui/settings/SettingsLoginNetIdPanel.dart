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
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class SettingsLoginNetIdPanel extends StatefulWidget{
  
  _SettingsLoginNetIdPanelState createState() => _SettingsLoginNetIdPanelState();
}

class _SettingsLoginNetIdPanelState extends State<SettingsLoginNetIdPanel> implements NotificationsListener {
  bool _progress = false;

  @override
  void initState() {
    NotificationService().subscribe(this, []);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String titleString = Localization().getStringEx('panel.settings.login.netid.label.title', 'Connect your NetID');
    String skipTitle = Localization().getStringEx('panel.settings.login.netid.button.dont_continue.title', 'Not right now');
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
                  hint: Localization().getStringEx('panel.settings.login.netid.label.title.hint', ''),
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
                    child: Text(Localization().getStringEx('panel.settings.login.netid.label.description', 'Log in with your NetID to use academic and dorm specific features.'),
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
                        label: Localization().getStringEx('panel.settings.login.netid.button.continue.title', 'Log in with NetID'),
                        hint: Localization().getStringEx('panel.settings.login.netid.button.continue.hint', ''),
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
                              hint: Localization().getStringEx('panel.settings.login.netid.button.dont_continue.hint', 'Skip verification'),
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
    Analytics().logSelect(target: 'Log in with NetID');
    if (_progress != true) {
      setState(() { _progress = true; });
      Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
        if (mounted) {
          if (result == Auth2OidcAuthenticateResult.succeeded) {
            FlexUI().update().then((_) {
              if (mounted) {
                setState(() { _progress = false; });
                Navigator.pop(context, true);
              }
            });
          } else if (result == Auth2OidcAuthenticateResult.failed) {
            setState(() { _progress = false; });
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          } else {
            setState(() { _progress = false; });
          }
        }
      });
    }
  }

  void _onSkipTapped() {
    Analytics().logSelect(target: 'Not right now');
    Navigator.pop(context);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
  }


}