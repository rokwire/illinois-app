/*
 * Copyright 2025 Board of Trustees of the University of Illinois.
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
import 'package:illinois/ui/RootPanel.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:web/web.dart' as web;

class WebLoginNetIdPanel extends StatefulWidget {
  WebLoginNetIdPanel();

  @override
  State<StatefulWidget> createState() => _WebLoginNetIdPanelState();
}

class _WebLoginNetIdPanelState extends State<WebLoginNetIdPanel> {
  bool _loginProgress = false;

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
      backgroundColor: Styles().colors.background,
      body: Column(children: [
        Expanded(
            child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Styles().images.getImage(
                      "header-login",
                      fit: BoxFit.fitWidth,
                      width: MediaQuery.of(context).size.width,
                      excludeFromSemantics: true,
                    ) ??
                Container(),
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
                    child: Text(titleString, textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 36, color: Styles().colors.fillColorPrimary)),
                  )),
            ),
            Container(
              height: 24,
            ),
            Padding(padding: EdgeInsets.symmetric(horizontal: 32), child: Text(Localization().getStringEx('panel.onboarding.login.netid.label.description', 'Sign in with your NetID to view features specific to you such as your Illini ID or your course schedule and locations.'), textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 20, color: Styles().colors.fillColorPrimary))),
            Container(
              height: 32,
            ),
          ]),
        )),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RoundedButton(
                label: Localization().getStringEx('panel.onboarding.login.netid.button.continue.title', 'Sign In with NetID'),
                hint: Localization().getStringEx('panel.onboarding.login.netid.button.continue.hint', ''),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                borderColor: Styles().colors.fillColorSecondary,
                backgroundColor: Styles().colors.white,
                progress: _loginProgress,
                onTap: _onLoginTapped,
              ),
              Onboarding2UnderlinedButton(
                title: skipTitle,
                hint: Localization().getStringEx('panel.onboarding.login.netid.button.dont_continue.hint', 'Skip verification'),
                onTap: () {
                  _onSkipTapped();
                },
              )
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildDialogWidget(BuildContext context) {
    return Dialog(child:
    Padding(padding: EdgeInsets.all(18), child:
    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Text(Localization().getStringEx('app.title', 'Illinois'), style: TextStyle(fontSize: 24, color: Colors.black),),
      Padding(padding: EdgeInsets.symmetric(vertical: 26), child:
      Text(Localization().getStringEx('logic.general.login_failed', 'Unable to login. Please try again later.'), textAlign: TextAlign.left, style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Colors.black),),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
        TextButton(onPressed: _onTapDialogOK, child:
        Text(Localization().getStringEx('dialog.ok.title', 'OK')))
      ],)
    ],),
    ),
    );
  }

  void _onTapDialogOK() {
    Analytics().logAlert(text: "Unable to login", selection: "Ok");
    Navigator.pop(context);
  }

  void _onLoginTapped() {
    Analytics().logSelect(target: 'Log in with NetID');
    if (_loginProgress != true) {
      setState(() { _loginProgress = true; });
      web.Window? webWindow = WebUtils.createIosWebWindow();
      Auth2().authenticateWithOidc(iosWebWindow: webWindow).then((Auth2OidcAuthenticateResult? result) {
        if (mounted) {
          if (result == Auth2OidcAuthenticateResult.succeeded) {
            FlexUI().update().then((_) {
              if (mounted) {
                setState(() { _loginProgress = false; });
                _goNext();
              }
            });
          }
          else if (result == Auth2OidcAuthenticateResult.failed) {
            setState(() { _loginProgress = false; });
            showDialog(context: context, builder: (context) => _buildDialogWidget(context));
          }
          else {
            // login canceled
            setState(() { _loginProgress = false; });
          }
        }
      });
    }
  }

  void _onSkipTapped() {
    Analytics().logSelect(target: 'Not right now');
    _goNext();
  }

  void _goNext() {
    Route routeToHome = CupertinoPageRoute(builder: (context) => RootPanel());
    Navigator.pushAndRemoveUntil(context, routeToHome, (_) => false);
  }
}
