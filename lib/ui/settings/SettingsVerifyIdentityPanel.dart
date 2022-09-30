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
import 'package:illinois/ui/settings/SettingsLoginPhoneOrEmailPanel.dart';
import 'package:rokwire_plugin/service/app_navigation.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';

class SettingsVerifyIdentityPanel extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _SettingsVerifyIdentityPanelState();

}

class _SettingsVerifyIdentityPanelState extends State<SettingsVerifyIdentityPanel> {

  bool? _loading;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.settings.verify_identity.label.title", "Verify your Identity"),
      ),
      body: SingleChildScrollView(child: _buildContent()),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    return Stack(alignment: Alignment.center, children: [
      // Content Widgets
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(height: 41),
          Container(padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              Localization().getStringEx("panel.settings.verify_identity.label.description", "Connect to {{app_title}}").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
              style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 24, fontFamily: Styles().fontFamilies!.extraBold),
            ),
          ),
          Container(height: 8,),
          Container(padding: EdgeInsets.symmetric(horizontal: 24),
              child:RichText(
                text: TextSpan(
                  style: TextStyle(color: Styles().colors!.textSurface, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),
                  children: <TextSpan>[
                    TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.connect_id.desription1", "Are you a ")),
                    TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.connect_id.desription2", "university student"),
                        style: TextStyle(color: Styles().colors!.textSurface, fontFamily: Styles().fontFamilies!.bold, fontSize: 16)),
                    TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.connect_id.desription3", " or ")),
                    TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.connect_id.desription4", "employee"),
                        style: TextStyle(color: Styles().colors!.textSurface, fontFamily: Styles().fontFamilies!.bold, fontSize: 16)),
                    TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.connect_id.desription5", "? Log in with your NetID to see {{app_title}} information specific to you, like your Illini Cash and meal plan.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'))),
                  ],
                ),
              )
          ),
          Container(height: 12,),
          Container(padding: EdgeInsets.symmetric(horizontal: 16),
              child:RibbonButton(
                  label: Localization().getStringEx("panel.settings.verify_identity.button.connect_net_id.title", "Connect Your NetID"),
                  borderRadius: BorderRadius.circular(4),
                  onTap: _onTapConnectNetId
              )),
          Container(height: 16,),
          Container(padding: EdgeInsets.symmetric(horizontal: 24),
              child:RichText(
                text: TextSpan(
                  style: TextStyle(color: Styles().colors!.textSurface, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),
                  children: <TextSpan>[
                    TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.phone_or_email.desription1", "Don’t have a NetID"),
                        style: TextStyle(color: Styles().colors!.textSurface, fontFamily: Styles().fontFamilies!.bold, fontSize: 16)),
                    TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.phone_or_email.desription2", "? Verify your phone number or sign in by email to save your preferences and have the same experience on more than one device.")),
                  ],
                ),
              )
          ),
          Container(height: 12,),
          Container(padding: EdgeInsets.symmetric(horizontal: 16),
              child:RibbonButton(
                  label: Localization().getStringEx("panel.settings.verify_identity.button.phone_or_phone.title", "Proceed"),
                  borderRadius: BorderRadius.circular(4),
                  onTap: _onTapProceed
              )),
        ],),
      // Loading indicator widgets
      Visibility(visible: (_loading == true), child: CircularProgressIndicator())
    ]);
  }

  void _onTapConnectNetId() {
    if (_loading != true) {
      _setLoading(true);
      Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? success) {
        if (mounted) {
          _setLoading(false);
          if (success == Auth2OidcAuthenticateResult.succeeded) {
            _didLogin(context);
          }
          else if (success == Auth2OidcAuthenticateResult.failed) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }

  void _onTapProceed() {
    _setLoading(true);
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => SettingsLoginPhoneOrEmailPanel(
                  onFinish: () {
                    _setLoading(false);
                    _didLogin(context);
                  }
                )));
  }

  void _didLogin(_) {
    Navigator.of(context).popUntil((Route route) {
      bool isCurrent = (AppNavigation.routeRootWidget(route, context: context)?.runtimeType == widget.runtimeType);
      if (isCurrent) {
        Navigator.of(context).pop();
        return true;
      } else {
        return false;
      }
    });
  }

  void _setLoading(bool loading) {
    if (_loading != loading) {
      _loading = loading;
      if (mounted) {
        setState(() {});
      }
    }
  }

  //TBD consider availability for phone/netId depending on role ()
}