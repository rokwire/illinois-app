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
import 'package:illinois/ui/onboarding/OnboardingMessagePanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingUpgradePanel extends StatelessWidget {
  final String? requiredVersion;
  final String? availableVersion;

  OnboardingUpgradePanel({Key? key, this.requiredVersion, this.availableVersion}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {

    String? appName = Localization().getStringEx('app.title', 'Illinois');
    String? appVersion = Config().appVersion;
    String? title, message;
    if (requiredVersion != null) {
      title = Localization().getStringEx('panel.onboarding.upgrade.required.label.title', 'Upgrade Required');
      message = sprintf(Localization().getStringEx('panel.onboarding.upgrade.required.label.description', '%s app version %s requires an upgrade to version %s or later.'), [appName, appVersion, requiredVersion])
      ;
    } else if (availableVersion != null) {
      title = Localization().getStringEx('panel.onboarding.upgrade.available.label.title', 'Upgrade Available');
      message = sprintf(Localization().getStringEx('panel.onboarding.upgrade.available.label.description', '%s app version %s has newer version %s available.'), [appName, appVersion, availableVersion]);
    }

    return OnboardingMessagePanel(title: title, message: message, footer: _footerWidget(context),);
  }

  Widget _footerWidget(BuildContext context) {
    String notNow = Localization().getStringEx('panel.onboarding.upgrade.button.not_now.title', 'Not right now');
    String dontShow = Localization().getStringEx('panel.onboarding.upgrade.button.dont_show.title', 'Don\'t show again');
    bool canSkip = (requiredVersion == null);

    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      RoundedButton(
        label: Localization().getStringEx('panel.onboarding.upgrade.button.upgrade.title', 'Upgrade'),
        hint: Localization().getStringEx('panel.onboarding.upgrade.button.upgrade.hint', ''),
        textStyle: Styles().textStyles.getTextStyle("widget.colourful_button.title.large.accent"),
        borderColor: Styles().colors.fillColorSecondary,
        backgroundColor: Styles().colors.fillColorSecondary,
        onTap: () => _onUpgradeClicked(context),
      ),

      canSkip ? Row(children: <Widget>[
        Expanded(child:
          Align(alignment: Alignment.centerLeft, child:
            InkWell(onTap: () => _onDontShowAgainClicked(context), child:
              Semantics(label: dontShow, hint: Localization().getStringEx('panel.onboarding.upgrade.button.dont_show.hint', ''), button: true, excludeSemantics: true, child:
                Padding(padding: EdgeInsets.symmetric(vertical: 20), child:
                  Text(dontShow, style:
                  _linkTextStyle,
                  )
                )
              ),
            ),
          ),
        ),

        Expanded(child:
          Align(alignment: Alignment.centerRight, child:
            InkWell(onTap: () => _onNotRightNowClicked(context), child:
              Semantics(label: notNow, hint: Localization().getStringEx('panel.onboarding.upgrade.button.not_now.hint', ''), button: true, excludeSemantics: true, child:
                Padding(padding:EdgeInsets.symmetric(vertical: 20), child:
                  Text(notNow, style: _linkTextStyle)
                )
              ),
            ),
          ),
        ),

      ],) : Padding(padding: EdgeInsets.symmetric(vertical: 32),),
    ]);
  }

  TextStyle? get _linkTextStyle => TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Styles().colors.fillColorPrimary, decoration: TextDecoration.underline, decorationColor: Styles().colors.fillColorSecondary, decorationThickness: 1, decorationStyle: TextDecorationStyle.solid);

  void _onUpgradeClicked(BuildContext context) async {
    String? upgradeUrl = Config().upgradeUrl;
    Uri? uri = StringUtils.isNotEmpty(upgradeUrl) ? Uri.tryParse(upgradeUrl!) : null;
    if ((uri != null) && await canLaunchUrl(uri)) {
      try { await launchUrl(uri, mode: LaunchMode.externalApplication); }
      catch(e) { debugPrint(e.toString()); }
    }
  }

  void _onNotRightNowClicked(BuildContext context) {
    if (availableVersion != null) {
      Config().setUpgradeAvailableVersionReported(availableVersion, permanent: false);
    }
  }

  void _onDontShowAgainClicked(BuildContext context) {
    if (availableVersion != null) {
      Config().setUpgradeAvailableVersionReported(availableVersion, permanent: true);
    }
  }
}
