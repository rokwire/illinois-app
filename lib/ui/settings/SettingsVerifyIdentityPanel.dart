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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/profile/ProfileLoginPage.dart';
import 'package:illinois/ui/profile/ProfileLoginPhoneOrEmailPanel.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/ui/widgets/web_semantics.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:web/web.dart' as web;

class SettingsVerifyIdentityPanel extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _SettingsVerifyIdentityPanelState();

}

class _SettingsVerifyIdentityPanelState extends State<SettingsVerifyIdentityPanel> {

  bool _connectingNetId = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(policy: OrderedTraversalPolicy(), child: Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx("panel.settings.verify_identity.label.title", "Verify your Identity"),),
      body: SingleChildScrollView(child: _buildContent()),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    ));
  }

  Widget _buildContent() =>
    Column( crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Container(height: 42),
      Container(padding: EdgeInsets.symmetric(horizontal: 24), child:
        Text(Localization().getStringEx("panel.settings.verify_identity.label.description", "Connect to {{app_title}}").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
          style: Styles().textStyles.getTextStyle("widget.title.extra_large.extra_fat"),
        ),
      ),
      Container(height: 8,),
      Container(padding: EdgeInsets.symmetric(horizontal: 24),
        child: _signInWithNetIdWidget
      ),
      Container(height: 24,),
      Container(padding: EdgeInsets.symmetric(horizontal: 42),
        child: _signInWithPhoneOrEmailWidget
      ),
    ],);

  Widget get _signInWithNetIdWidget =>
    ProfileLoginHighlightedBox(child:
        Column(children: [
          Text(Localization().getStringEx('panel.home.connect.not_logged_in.netid.description', 'Sign in with your Illinois NetID to access your Illini ID, course schedule, and other personalized features.'),
            style: Styles().textStyles.getTextStyle('widget.description.regular.thin')
          ),
          SizedBox(height: 16,),
          RoundedButton(
            label: Localization().getStringEx("panel.home.connect.not_logged_in.netid.button.title", "Sign In with Your NetID"),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
            borderColor: Styles().colors.fillColorSecondary,
            backgroundColor: Styles().colors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            contentWeight: 0.75,
            progress: (_connectingNetId == true),
            onTap: _onConnectNetIdClicked,
          )
        ],)
    );

  void _onConnectNetIdClicked() {
    Analytics().logSelect(target: "Connect netId");
    if (!FlexUI().isAuthenticationAvailable) {
      AppAlert.showAuthenticationNAMessage(context);
    }
    else if (_connectingNetId != true) {
      setState(() { _connectingNetId = true; });
      web.Window? webWindow = WebUtils.createIosWebWindow();
      Auth2().authenticateWithOidc(iosWebWindow: webWindow).then((Auth2OidcAuthenticateResult? result) {
        if (mounted) {
          setState(() { _connectingNetId = false; });
          if (result != Auth2OidcAuthenticateResult.succeeded) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          } else {
            Navigator.of(context).pop();
          }
        }
      });
    }
  }

  Widget get _signInWithPhoneOrEmailWidget =>
    HtmlWidget(_signInWithPhoneOrEmailDescriptionHtml,
      onTapUrl : (url) { _onTapSignInWithPhoneOrEmailLink(context, url); return true; },
      textStyle:  Styles().textStyles.getTextStyle("widget.description.small"),
      customStylesBuilder: (element) => _htmlStyleMap[element.localName?.toLowerCase()],
    );

  static const String _localScheme = 'local';
  static const String _signInHost = 'signin';
  static const String _signInUrlMacro = '{{signin_url}}';
  static const String _signInUrl = '$_localScheme://$_signInHost';

  String get _signInWithPhoneOrEmailDescriptionHtml => Localization().getStringEx("panel.home.connect.not_logged_in.phone_or_email.description", "<b>Don’t have a NetID?</b> <a href='$_signInUrlMacro'>Use your mobile phone number or personal (non-Illinois) email address to sign in.</a><p>Once a NetID is issued, sign in above using your NetID.</p>").
    replaceAll(_signInUrlMacro, _signInUrl);

  Map<String, Map<String, String>> get _htmlStyleMap => {
    'a' : _htmlLinkStyle
  };

  Map<String, String> get _htmlLinkStyle => <String, String>{
    'color': _htmlTextColor,
    'text-decoration-color': _htmlLinkColor,
  };

  String get _htmlTextColor => ColorUtils.toHex(Styles().colors.fillColorPrimary);
  String get _htmlLinkColor => ColorUtils.toHex(Styles().colors.fillColorSecondary);

  void _onTapSignInWithPhoneOrEmailLink(BuildContext context, String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if ((uri?.scheme == _localScheme) && (uri?.host == _signInHost)) {
      _connectPhoneOrEmail();
    }
  }

  void _connectPhoneOrEmail() {
    Analytics().logSelect(target: "Phone or Email Login", source: runtimeType.toString());
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.phone_or_email', 'Feature not available when offline.'));
    }
    else if (!FlexUI().isAuthenticationAvailable) {
      AppAlert.showAuthenticationNAMessage(context);
    }
    else {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => ProfileLoginPhoneOrEmailPanel(onFinish: () => Navigator.of(context).pop()),),);
    }
  }
}