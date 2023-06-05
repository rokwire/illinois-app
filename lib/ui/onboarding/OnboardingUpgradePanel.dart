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
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class OnboardingUpgradePanel extends StatefulWidget {
  final String? requiredVersion;
  final String? availableVersion;
  OnboardingUpgradePanel({Key? key, this.requiredVersion, this.availableVersion})
      : super(key: key);

  @override
  _OnboardingUpgradePanelState createState() => _OnboardingUpgradePanelState();
}

class _OnboardingUpgradePanelState extends State<OnboardingUpgradePanel> {

  @override
  Widget build(BuildContext context) {

    String? appName = Localization().getStringEx('app.title', 'Illinois');
    String? appVersion = Config().appVersion;
    String? title, message;
    if (widget.requiredVersion != null) {
      title = Localization().getStringEx('panel.onboarding.upgrade.required.label.title', 'Upgrade Required');
      message = sprintf(Localization().getStringEx('panel.onboarding.upgrade.required.label.description', '%s app version %s requires an upgrade to version %s or later.'), [appName, appVersion, widget.requiredVersion])
      ;
    } else if (widget.availableVersion != null) {
      title = Localization().getStringEx('panel.onboarding.upgrade.available.label.title', 'Upgrade Available');
      message = sprintf(Localization().getStringEx('panel.onboarding.upgrade.available.label.description', '%s app version %s has newer version %s available.'), [appName, appVersion, widget.availableVersion]);
    }
    String notNow = Localization().getStringEx('panel.onboarding.upgrade.button.not_now.title', 'Not right now');
    String dontShow = Localization().getStringEx('panel.onboarding.upgrade.button.dont_show.title', 'Don\'t show again');
    bool canSkip = (widget.requiredVersion == null);

    return Scaffold(
        backgroundColor: Styles().colors!.background,
        body: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Styles().images?.getImage(
              'header-login',
              fit: BoxFit.fitWidth,
              width: MediaQuery.of(context).size.width,
              excludeFromSemantics: true,
            ) ?? Container(),
            Expanded(
                child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies!.bold,
                        fontSize: 32,
                        color: Styles().colors!.fillColorPrimary),
                  )),
            )),
            Expanded(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies!.regular,
                            fontSize: 20,
                            color: Styles().colors!.fillColorPrimary),
                      ),
                    ))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RoundedButton(
                    label: Localization().getStringEx('panel.onboarding.upgrade.button.upgrade.title', 'Upgrade'),
                    hint: Localization().getStringEx('panel.onboarding.upgrade.button.upgrade.hint', ''),
                    textStyle: Styles().textStyles?.getTextStyle("widget.colourful_button.title.large.accent"),
                    borderColor: Styles().colors!.fillColorSecondary,
                    backgroundColor: Styles().colors!.fillColorSecondary,
                    onTap: () => _onUpgradeClicked(context),
                  ),
                  canSkip
                      ? Row(
                          children: <Widget>[
                            GestureDetector(
                              onTap: () => _onDontShowAgainClicked(context),
                              child: Semantics(
                                  label: dontShow,
                                  hint: Localization().getStringEx('panel.onboarding.upgrade.button.dont_show.hint', ''),
                                  button: true,
                                  excludeSemantics: true,
                                  child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: Text(
                                        dontShow,
                                        style: TextStyle(
                                            fontFamily: Styles().fontFamilies!.medium,
                                            fontSize: 16,
                                            color: Styles().colors!.fillColorPrimary,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                Styles().colors!.fillColorSecondary,
                                            decorationThickness: 1,
                                            decorationStyle:
                                                TextDecorationStyle.solid),
                                      ))),
                            ),
                            Expanded(child: Container()),
                            GestureDetector(
                              onTap: () => _onNotRightNowClicked(context),
                              child: Semantics(
                                  label: notNow,
                                  hint: Localization().getStringEx('panel.onboarding.upgrade.button.not_now.hint', ''),
                                  button: true,
                                  excludeSemantics: true,
                                  child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: Text(
                                        notNow,
                                        style: TextStyle(
                                            fontFamily: Styles().fontFamilies!.medium,
                                            fontSize: 16,
                                            color: Styles().colors!.fillColorPrimary,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                Styles().colors!.fillColorSecondary,
                                            decorationThickness: 1,
                                            decorationStyle:
                                                TextDecorationStyle.solid),
                                      ))),
                            ),
                          ],
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                        ),
                ],
              ),
            ),
          ],
        )));
  }

  void _onUpgradeClicked(BuildContext context) async {
    String? upgradeUrl = Config().upgradeUrl;
    Uri? uri = StringUtils.isNotEmpty(upgradeUrl) ? Uri.tryParse(upgradeUrl!) : null;
    if ((uri != null) && await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri);
    }
  }

  void _onNotRightNowClicked(BuildContext context) {
    if (widget.availableVersion != null) {
      Config().setUpgradeAvailableVersionReported(widget.availableVersion,
          permanent: false);
    }
  }

  void _onDontShowAgainClicked(BuildContext context) {
    if (widget.availableVersion != null) {
      Config().setUpgradeAvailableVersionReported(widget.availableVersion,
          permanent: true);
    }
  }
}
