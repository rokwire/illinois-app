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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WebRestrictedMobileDevicesPanel extends StatelessWidget {
  const WebRestrictedMobileDevicesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    String message = _buildMessage();
    return Scaffold(
      backgroundColor: Styles().colors.background,
      body: SafeArea(
          child: Column(children: [
        ExcludeSemantics(child: Onboarding2TitleWidget(title: '')),
        Semantics(
            child: Expanded(
                child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            child: HtmlWidget('<div style=text-align:center>$message</div>',
                onTapUrl: (url) {
                  Uri? uri = UriExt.tryParse(url);
                  if (uri != null) {
                    return launchUrl(uri);
                  } else {
                    return false;
                  }
                },
                textStyle: Styles().textStyles.getTextStyle('widget.detail.regular.fat'),
                customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null),
          ),
        )))
      ])),
    );
  }

  String _buildMessage() {
    String message = Localization().getStringEx('panel.web.restricted_mobile_devices.text', 'Please use the mobile app to open {{app_title}}{{store_href}}. (The website is for desktop and laptop use only.)').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
    final String storeHrefMacro = '{{store_href}}';
    String? storeUrl = _getStoreUrl();
    if (storeUrl != null) {
      String storeText = WebUtils.isIosWeb() ? Localization().getStringEx('panel.web.restricted_mobile_devices.store.apple.label', 'App Store') : Localization().getStringEx('panel.web.restricted_mobile_devices.store.google.label', 'Play Store');
      final String storeHrefValue = ": <a href='$storeUrl'><b>$storeText</b></a>";
      message = message.replaceAll(storeHrefMacro, storeHrefValue);
    } else {
      message = message.replaceAll(storeHrefMacro, '');
    }
    return message;
  }

  String? _getStoreUrl() {
    String? storeUrl;
    if (kIsWeb) {
      if (WebUtils.isIosWeb()) {
        storeUrl = Config().upgradeIOSUrl;
      } else if (WebUtils.isAndroidWeb()) {
        storeUrl = Config().upgradeAndroidUrl;
      }
    }
    return storeUrl;
  }
}
