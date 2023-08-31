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
import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ImprovePanel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

import 'Onboarding2PrivacyPanel.dart';
import 'Onboarding2Widgets.dart';

class Onboarding2PersonalizePanel extends StatefulWidget{

  Onboarding2PersonalizePanel();
  _Onboarding2PersonalizePanelState createState() => _Onboarding2PersonalizePanelState();
}

class _Onboarding2PersonalizePanelState extends State<Onboarding2PersonalizePanel> {
  bool? _toggled = false;

  @override
  void initState() {
    _toggled = Onboarding2().getPersonalizeChoice;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Styles().colors!.background,
        body: SafeArea(child:SwipeDetector(
            onSwipeLeft: () => _goNext(context),
            onSwipeRight: () => _goBack(context),
            child:
            Column(children: [
              Expanded(child: SingleChildScrollView(child:
                Container(
                    color: Styles().colors!.white,
                    child:Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Container(
                              height: 8,
                              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                              child:Row(children: [
                                Expanded(
                                    flex:1,
                                    child: Container(color: Styles().colors!.fillColorPrimary,)
                                ),
                                Container(width: 2,),
                                Expanded(
                                    flex:1,
                                    child: Container(color: Styles().colors!.fillColorPrimary,)
                                ),
                                Container(width: 2,),
                                Expanded(
                                    flex:1,
                                    child: Container(color: Styles().colors!.backgroundVariant,)
                                ),
                              ],)
                          ),
                          Row(children:[
                            Onboarding2BackButton(padding: const EdgeInsets.only(left: 17, top: 11, right: 20, bottom: 15),
                                onTap: () {
                                  Analytics().logSelect(target: "Back");
                                  _goBack(context);
                                }),
                          ],),
                          Semantics(
                              label: _title,
                              hint: Localization().getStringEx("common.heading.one.hint","Header 1"),
                              header: true,
                              excludeSemantics: true,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 17, right: 17, top: 0, bottom: 12),
                                child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      _title!,
                                      textAlign: TextAlign.center,
                                      style: Styles().textStyles?.getTextStyle("panel.onboarding2.improve.heading.title"))
                                ),
                              )),
                          Semantics(
                              label: _description,
                              excludeSemantics: true,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Text(
                                      _description!,
                                      textAlign: TextAlign.center,
                                      style: Styles().textStyles?.getTextStyle("widget.description.regular"),
                                    )),
                              )),
                          Container(height: 10,),
                          Onboarding2UnderlinedButton(
                            title: Localization().getStringEx('panel.onboarding2.improve.button.title.learn_more', 'Learn More'),
                            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.small.semi_fat.underline"),
                            onTap: _onTapLearnMore,
                          ),
                          Container(height: 12,),
                          Container(
                              height: 200,
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      height: 160,
                                      child:Column(
                                          children:[
                                            CustomPaint(
                                              painter: TrianglePainter(painterColor: Styles().colors!.background, horzDir: TriangleHorzDirection.leftToRight),
                                              child: Container(
                                                height: 100,
                                              ),
                                            ),
                                            Container(height: 60, color: Styles().colors!.background,)
                                          ]),
                                    ),
                                  ),
                                  Align(
                                      alignment: Alignment.center,
                                      child:Container(
                                        child: Styles().images?.getImage("personalize-illustration", excludeFromSemantics: true),
                                      )
                                  )
                                ],
                              )
                          )
                        ])),
              )),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child:
                      Onboarding2ToggleButton(
                        toggledTitle: _toggledButtonTitle,
                        unToggledTitle: _unToggledButtonTitle,
                        toggled: _toggled,
                        onTap: _onToggleTap,
                        context: context,
                      ),
                    ),
                    RoundedButton(
                      label: Localization().getStringEx('panel.onboarding2.personalize.button.continue.title', 'Continue'),
                      hint: Localization().getStringEx('panel.onboarding2.personalize.button.continue.hint', ''),
                      textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Styles().colors!.white,
                      borderColor: Styles().colors!.fillColorSecondaryVariant,
                      onTap: () => _goNext(context),
                    )
                  ],
                ),
              ),
            ]))));
  }

  void _onToggleTap(){
    setState(() {
      _toggled = !_toggled!;
    });
  }

  void _goNext(BuildContext context) {
    Onboarding2().storePersonalizeChoice(_toggled);
    if (Onboarding2().getPersonalizeChoice) {
      Navigator.push(context,
          CupertinoPageRoute(builder: (context) => Onboarding2ImprovePanel()));
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2PrivacyPanel()));
    }
  }

  void _goBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onTapLearnMore(){
    Onboarding2InfoDialog.show(
        context: context,
        content: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              Localization().getStringEx('panel.onboarding2.personalize.learn_more.title1',"App activity"),
              style: Onboarding2InfoDialog.titleStyle,),
            Container(height: 8,),
            Text(Localization().getStringEx('panel.onboarding2.personalize.learn_more.location_services.content1',"Storing your app activity means that the app collects and remembers data about how you interact with it. The app stores your food preferences, your favorite teams, events you have starred, and other filters. Storing this information helps you use the app more efficiently."),
              style: Onboarding2InfoDialog.contentStyle,
            ),
            Container(height: 24,),
            Text(
              Localization().getStringEx('panel.onboarding2.personalize.learn_more.title2',"Personal information"),
              style: Onboarding2InfoDialog.titleStyle,),
            Container(height: 8,),
            Text(Localization().getStringEx('panel.onboarding2.personalize.learn_more.location_services.content2',"The app also stores personal information you provide. This may include your name, telephone number, email address, NetID, and Illini ID information."),
              style: Onboarding2InfoDialog.contentStyle,
            ),
            Container(height: 24,),
            Text(
              Localization().getStringEx('panel.onboarding2.personalize.learn_more.title3',"Storage"),
              style: Onboarding2InfoDialog.titleStyle,),
            Container(height: 8,),
            Text(Localization().getStringEx('panel.onboarding2.personalize.learn_more.location_services.content3',"Your data is stored safely on your mobile device and on our secure servers. Your stored information is not given or sold to any third parties. The app activity information is associated with your personal information only when you are signed in."),
              style: Onboarding2InfoDialog.contentStyle,
            ),
            Container(height: 24,),
            Text(
              Localization().getStringEx('panel.onboarding2.personalize.learn_more.title4',"Opting Out"),
              style: Onboarding2InfoDialog.titleStyle,),
            Container(height: 8,),
            Text(Localization().getStringEx('panel.onboarding2.personalize.learn_more.location_services.content4',"The Privacy Center allows you to opt out of information collection at any time and provides the option to remove your data."),
              style: Onboarding2InfoDialog.contentStyle,
            ),
          ]
        )
    );
  }

  String? get _title{
    return Localization().getStringEx('panel.onboarding2.personalize.label.title', 'Store your app activity and personal information?');
  }

  String? get _description{
    return Localization().getStringEx('panel.onboarding2.personalize.label.description', 'This includes content you view, teams you follow, and sign-in information. ');
  }

  String? get _toggledButtonTitle{
    return Localization().getStringEx('panel.onboarding2.personalize.button.toggle.title', 'Store my app activity and my preferences.');
  }

  String? get _unToggledButtonTitle{
    return Localization().getStringEx('panel.onboarding2.personalize.button.untoggle.title', 'Don\'t store my app activity or information.');
  }
}