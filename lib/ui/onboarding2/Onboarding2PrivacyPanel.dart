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
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/PrivacySlider.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

import 'Onboarding2Widgets.dart';

class Onboarding2PrivacyPanel extends StatefulWidget{

  Onboarding2PrivacyPanel();
  _Onboarding2PrivacyPanelState createState() => _Onboarding2PrivacyPanelState();
}

class _Onboarding2PrivacyPanelState extends State<Onboarding2PrivacyPanel>{

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
    return Scaffold(backgroundColor: Styles().colors.background,
      appBar: AppBar(backgroundColor: Styles().colors.fillColorPrimary, toolbarHeight: 0,),
      body: SwipeDetector(onSwipeLeft: _goNext, onSwipeRight: _goBack, child:
        Column(children: [
          Expanded(child:
            SingleChildScrollView(child:
              Column(children:[
                Container(color: Styles().colors.fillColorPrimary, child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
                    Row(children: [
                      Onboarding2BackButton(padding: const EdgeInsets.only(top:19,left: 17, right: 20, bottom: 19), color: Styles().colors.white, onTap: _goBack,),
                      Expanded(child: Container()),
                      Semantics(
                        label: Localization().getStringEx('panel.onboarding2.privacy.button.privacy_policy.title', "Privacy Notice "),
                        hint: Localization().getStringEx('panel.onboarding2.privacy.button.privacy_policy.hint', ''),
                        button: true,
                        excludeSemantics: true,
                        child: _buildPrivacyPolicyButton()
                      ),
                      Container(width: 16,)
                    ],),
                    Container(height: 18,),
                    Semantics(
                      label: _privacyDescription,
                      hint: Localization().getStringEx("common.heading.one.hint","Header 1"),
                      header: true,
                      excludeSemantics: true,
                      child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                        Align(alignment: Alignment.topCenter, child:
                          Text(_privacyDescription ?? '', textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.onboarding2.heading.title"),)
                        ),
                      )
                    ),
                    Container(height: 35,),
                    Container(height: 90, child:
                      Stack(children: [
                        Align(alignment: Alignment.topCenter, child:
                          Container(height: 90, child:
                            Column(children: [
                              CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background,), child:
                                Container(height: 90,),
                              ),
                              Container(height: 0, color: Styles().colors.background,)
                            ]),
                          ),
                        ),
                        Align(alignment: Alignment.topRight, child:
                          _buildPrivacyBadge(),
                        )
                      ],)
                    )
                  ])
                ),
                Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
                  Text(_privacyLongDescription ?? '', textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.description.regular"),)
                ),
                _buildPrivacySlider(),
              ]),
            )
          ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 24), child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Container(height: 16,),
              Text(Localization().getStringEx("panel.onboarding2.privacy.label.continue.description", "You can adjust what you store and share at any time in the Privacy Center."), textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.info.small"),),
              Padding(padding: EdgeInsets.only(bottom: 20, top: 16), child:
                RoundedButton(
                  label: _continueButtonLabel,
                  hint: Localization().getStringEx('panel.onboarding2.privacy_statement.button.continue.hint', ''),
                  textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Styles().colors.white,
                  borderColor: Styles().colors.fillColorSecondaryVariant,
                  onTap: _goNext,
                ),
              ),
              Container(height: 16,)
            ],),
          ),
        ])
      )
    );
  }

  Widget _buildPrivacyBadge(){
    return
      Semantics(
        label: Localization().getStringEx('panel.onboarding2.privacy.badge.privacy_level.title', "Privacy Level: ") + _privacyLevel.toString(),
        excludeSemantics: true,
        child:Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Container()),
              Container(
                width: 50 ,
                child: Stack(
                  children: [
                    Align(
                        child: Container(
                          width:50,
                          child: Styles().images.getImage(_privacyLevel==5?"images/privacy_box_selected.png" :"images/privacy_box_deselected.png", fit: BoxFit.fitWidth, excludeFromSemantics: true,),
                        )
                    ),
                    Align(
                        alignment: Alignment.center,
                        child:Container(
                          alignment: Alignment.center,
                          height: 50,
                          child:
                        Text(
                          _privacyLevel.toString(),
                          textAlign: TextAlign.center,
                          style: Styles().textStyles.getTextStyle("panel.onboarding2.privacy.badge")
                        ))
                    )
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildPrivacyPolicyButton(){
    return
      GestureDetector(
        onTap: _openPrivacyPolicy,
        child:
        Container(
          padding: EdgeInsets.symmetric(vertical: 19),
          child:Container(
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Styles().colors.fillColorSecondary, width: 1, ),)
            ),
            padding: EdgeInsets.only(bottom: 2),
            child:
            Row(children: [
              Text(
                Localization().getStringEx('panel.onboarding2.privacy.button.privacy_policy.title', "Privacy Notice "),
                style: Styles().textStyles.getTextStyle("widget.colourful_button.title.regular")

              ),
              Container(padding: EdgeInsets.only(bottom: 3),
                  child: Styles().images.getImage("external-link", excludeFromSemantics: true)
              ),
            ],)
          )
        )
      );
  }

  Widget _buildPrivacySlider(){
    return
      Container(
          padding: EdgeInsets.symmetric(vertical:24, horizontal: 20),
          color: Styles().colors.background,
          child: SafeArea(
              top: false,
              child: Column(children: <Widget>[
                Container(height: 6,),
                PrivacyLevelSlider(
                  color: Styles().colors.background,
                  readOnly: true,
                  initialValue: _privacyLevel.toDouble()),
              ],)
          ));
  }

  int get _privacyLevel{
    return Onboarding2().getPrivacyLevel;
  }

  String? get _privacyDescription{
    String? description = Localization().getStringEx('panel.onboarding2.privacy.description_short.unknown.title', "Unknown privacy level");
    int privacyLevel = _privacyLevel;
    switch(privacyLevel){
      case 1 : return Localization().getStringEx('panel.onboarding2.privacy.description_short.1.title', "Browse privately");
      case 2 : return Localization().getStringEx('panel.onboarding2.privacy.description_short.2.title', "Explore privately ");
      case 3 : return Localization().getStringEx('panel.onboarding2.privacy.description_short.3.title', "Personalized for you");
      case 4 : return Localization().getStringEx('panel.onboarding2.privacy.description_short.4.title', "Personalized for you");
      case 5 : return Localization().getStringEx('panel.onboarding2.privacy.description_short.5.title', "Full Access");
    }
    return description;
  }

  String? get _privacyLongDescription{
    String? description = Localization().getStringEx('panel.onboarding2.privacy.description_long.unknown.title', "Unknown privacy level");
    int privacyLevel = _privacyLevel;
    switch(privacyLevel){
      case 1 : return Localization().getStringEx('panel.onboarding2.privacy.description_long.1.title', "Based on your answers, no personal information will be stored or shared. You can only browse information in the app.");
      case 2 : return Localization().getStringEx('panel.onboarding2.privacy.description_long.2.title', "Based on your answers, your location is used to explore campus and find things nearby. Your data will not be stored or shared.");
      case 3 : return Localization().getStringEx('panel.onboarding2.privacy.description_long.3.title', "Based on your answers, your data will be securely stored for you to access.");
      case 4 : return Localization().getStringEx('panel.onboarding2.privacy.description_long.4.title', "Based on your answers, your data will be securely stored for you to access.");
      case 5 : return Localization().getStringEx('panel.onboarding2.privacy.description_long.5.title', "Based on your answers, your data will be securely stored and shared to enable the full smarts of the {{app_title}} app.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
    }
    return description;
  }

  String get _continueButtonLabel{
    switch(_privacyLevel){
      case 1 : return Localization().getStringEx('panel.onboarding2.privacy.button.start_browsing.title', "Start browsing");
      case 2 : return Localization().getStringEx('panel.onboarding2.privacy.button.start_exploring.title', "Start exploring");
    }
    return Localization().getStringEx('panel.onboarding2.privacy.button.save_privacy.title', "Save Privacy Level");
  }

  void _goNext() {
    Analytics().logSelect(target: "Next");
    Auth2().prefs?.privacyLevel = _privacyLevel;
    Storage().privacyUpdateVersion = Config().appVersion;
    Onboarding2().finalize(context);
  }

  void _goBack() {
    Analytics().logSelect(target: "Back");
    Navigator.of(context).pop();
  }

  void _openPrivacyPolicy(){
    Analytics().logSelect(target: "Privacy Statement");
    AppPrivacyPolicy.launch(context);
  }
}
