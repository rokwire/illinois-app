// Copyright 2024 Board of Trustees of the University of Illinois.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SignInInfoPopup extends StatelessWidget {
  static const String _signInUrl = 'profile://sign_in';
  static const String _privacyUrl = 'settings://privacy';
  static const String _signInUrlMacro = '{{profile_sign_in_url}}';
  static const String _privacyUrlMacro = '{{settings_privacy_url}}';

  final String message;

  const SignInInfoPopup({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formattedMessage = message
        .replaceAll(_signInUrlMacro, _signInUrl)
        .replaceAll(_privacyUrlMacro, _privacyUrl);
    return AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
            decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.circular(10.0)),
            child: Stack(alignment: Alignment.center, children: [
              Padding(
                  padding: EdgeInsets.only(top: 30, bottom: 22),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28),
                      child: Column(children: [
                        Padding(
                            padding: EdgeInsets.only(top: 14),
                            child:
                            HtmlWidget(formattedMessage,
                                onTapUrl: (url) => _onTapUrl(context, url),
                                textStyle: Styles().textStyles.getTextStyle("panel.assistant.popup.detail.small"),
                                customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null))
                      ]),
                    ),
                  ])),
              Positioned.fill(
                  child: Align(
                      alignment: Alignment.topRight,
                      child: Semantics(
                          button: true,
                          label: "close",
                          child: InkWell(
                              onTap: () {
                                Analytics().logSelect(target: 'Close Wallet Sign-In info popup');
                                Navigator.of(context).pop();
                              },
                              child: Padding(padding: EdgeInsets.all(12), child: Styles().images.getImage('close-circle', excludeFromSemantics: true)))))),
            ])));
  }

  bool _onTapUrl(BuildContext context, String url) {
    if (url == _privacyUrl) {
      Analytics().logSelect(target: 'Settings: My App Privacy', source: 'SignInInfoPopup');
      Navigator.of(context).pop();
      SettingsHomePanel.present(context, content: SettingsContentType.privacy);
      return true;
    } else if (url == _signInUrl) {
      Analytics().logSelect(target: 'Profile: Sign In / Sign Out', source: 'SignInInfoPopup');
      Navigator.of(context).pop();
      ProfileHomePanel.present(context, contentType: ProfileContentType.login);
      return true;
    } else {
      return false;
    }
  }
}
