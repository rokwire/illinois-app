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
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/settings/SettingsLoginNetIdPanel.dart';
import 'package:illinois/ui/settings/SettingsLoginPhonePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';

class SettingsVerifyIdentityPanel extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _SettingsVerifyIdentityPanelState();

}

class _SettingsVerifyIdentityPanelState extends State<SettingsVerifyIdentityPanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
          Localization().getStringEx("panel.settings.verify_identity.label.title", "Verify your Identity"),
          style: TextStyle(color: Styles().colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold, letterSpacing: 1.0),
        ),
      ),
      body: SingleChildScrollView(child: _buildContent()),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(height: 41),
        Container(padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            Localization().getStringEx("panel.settings.verify_identity.label.description", "Connect to Illinois"),
            style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 24, fontFamily: Styles().fontFamilies.extraBold),
          ),
        ),
        Container(height: 8,),
        Container(padding: EdgeInsets.symmetric(horizontal: 24),
        child:RichText(
            text: TextSpan(
              style: TextStyle(color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.regular, fontSize: 16),
              children: <TextSpan>[
                TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.connect_id.desription1", "Are you a ")),
                TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.connect_id.desription2", "Student "),
                    style: TextStyle(color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.bold, fontSize: 16)),
                TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.connect_id.desription3", "or ")),
                TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.connect_id.desription4", "faculty member "),
                    style: TextStyle(color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.bold, fontSize: 16)),
                TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.connect_id.desription3", "? Log in with your NetID to see Illinois information specific to you, like your Illini Cash and meal plan.")),
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
                style: TextStyle(color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.regular, fontSize: 16),
                children: <TextSpan>[
                  TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.verify_phone.desription1", "Don’t have a NetID"),
                      style: TextStyle(color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.bold, fontSize: 16)),
                  TextSpan(text: Localization().getStringEx("panel.settings.verify_identity.label.verify_phone.desription2", "? Verify your phone number to save your preferences and have the same experience on more than one device. ")),
                ],
              ),
            )
        ),
        Container(height: 12,),
        Container(padding: EdgeInsets.symmetric(horizontal: 16),
            child:RibbonButton(
                label: Localization().getStringEx("panel.settings.verify_identity.button.verify_phone.title", "Verify Your Phone Number"),
                borderRadius: BorderRadius.circular(4),
                onTap: _onTapVerifyPhone
            )),
    ],);
  }

  _onTapConnectNetId(){
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsLoginNetIdPanel())).then((success){
      if(success??false){
        Navigator.pop(context);
      }
    });
  }
  _onTapVerifyPhone(){
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsLoginPhonePanel())).then((success){
      if(success??false){
        Navigator.pop(context);
      }
    });
  }

  //TBD consider availability for phone/netId depending on role ()
}