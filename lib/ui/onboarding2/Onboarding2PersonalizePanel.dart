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
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

import 'Onboarding2PrivacyPanel.dart';
import 'Onboarding2Widgets.dart';

class Onboarding2PersonalizePanel extends StatefulWidget{
  Onboarding2PersonalizePanel();
  _Onboarding2PersonalizePanelState createState() => _Onboarding2PersonalizePanelState();
}

class _Onboarding2PersonalizePanelState extends State<Onboarding2PersonalizePanel> {
  late bool _toggled;

  @override
  void initState() {
    _toggled = Onboarding2().privacyPersonalizeSelection;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    Scaffold(backgroundColor: Styles().colors.background, body:
      SafeArea(child:
        SwipeDetector(onSwipeLeft: _onTapContinue, onSwipeRight: _onTapBack, child:
          Column(children: [
            Expanded(child:
              SingleChildScrollView(child:
                Container(color: Styles().colors.white, child:
                  Column(children: <Widget>[
                    Padding(padding: EdgeInsets.all(Onboarding2PrivacyProgress.defaultSpacing), child:
                      Onboarding2PrivacyProgress(2)
                    ),

                    Align(alignment: Alignment.centerLeft, child:
                      Onboarding2BackButton(padding: const EdgeInsets.all(16), onTap: _onTapBack),
                    ),

                    Semantics(
                      label: _title,
                      hint: Localization().getStringEx("common.heading.one.hint","Header 1"),
                      header: true,
                      excludeSemantics: true,
                      child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
                        Text(_title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.onboarding2.improve.heading.title"))
                      )
                    )
                    ,
                    Semantics(
                      label: _description,
                      excludeSemantics: true,
                      child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                        Text(_description, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.description.regular"),),
                      )
                    ),

                    Container(height: 10,),

                    Onboarding2UnderlinedButton(
                      title: Localization().getStringEx('panel.onboarding2.improve.button.title.learn_more', 'Learn More'),
                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.small.medium.underline"),
                      onTap: _onTapLearnMore,
                    ),

                    Container(height: 12,),

                    Stack(children: [
                      Column(children:[
                        CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background, horzDir: TriangleHorzDirection.leftToRight), child:
                          Container(height: 100,),
                        ),
                        Container(height: 100, color: Styles().colors.background,)
                      ]),
                      Positioned.fill(child:
                        Center(child:
                          Styles().images.getImage("personalize-illustration", excludeFromSemantics: true),
                        )
                      )
                    ],)
                  ])
                ),
              )
            ),

            Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
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
                  textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Styles().colors.white,
                  borderColor: Styles().colors.fillColorSecondaryVariant,
                  onTap: _onTapContinue,
                )
              ],),
            ),
          ])
        )
      )
    );


  String get _title => Localization().getStringEx('panel.onboarding2.personalize.label.title', 'Store your app activity and personal information?');
  String get _description => Localization().getStringEx('panel.onboarding2.personalize.label.description', 'This includes content you view, teams you follow, and sign-in information. ');
  String get _toggledButtonTitle => Localization().getStringEx('panel.onboarding2.personalize.button.toggle.title', 'Store my app activity and my preferences.');
  String? get _unToggledButtonTitle => Localization().getStringEx('panel.onboarding2.personalize.button.untoggle.title', 'Don\'t store my app activity or information.');

  void _onToggleTap(){
    setState(() {
      _toggled = !_toggled;
    });
  }

  void _onTapLearnMore(){
    Analytics().logSelect(target: 'Learn More');
    Onboarding2InfoDialog.show( context: context, content: _learnMoreDialog);
  }

  Widget get _learnMoreDialog =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(Localization().getStringEx('panel.onboarding2.personalize.learn_more.title1',"App activity"), style: Onboarding2InfoDialog.titleStyle,),
      Container(height: 8,),
      Text(Localization().getStringEx('panel.onboarding2.personalize.learn_more.location_services.content1',"Storing your app activity means that the app collects and remembers data about how you interact with it. The app stores your food preferences, your favorite teams, events you have starred, and other filters. Storing this information helps you use the app more efficiently."), style: Onboarding2InfoDialog.contentStyle,),
      Container(height: 24,),
      Text(Localization().getStringEx('panel.onboarding2.personalize.learn_more.title2',"Personal information"), style: Onboarding2InfoDialog.titleStyle,),
      Container(height: 8,),
      Text(Localization().getStringEx('panel.onboarding2.personalize.learn_more.location_services.content2',"The app also stores personal information you provide. This may include your name, telephone number, email address, NetID, and Illini ID information."), style: Onboarding2InfoDialog.contentStyle,),
      Container(height: 24,),
      Text(Localization().getStringEx('panel.onboarding2.personalize.learn_more.title3',"Storage"), style: Onboarding2InfoDialog.titleStyle,),
      Container(height: 8,),
      Text(Localization().getStringEx('panel.onboarding2.personalize.learn_more.location_services.content3',"Your data is stored safely on your mobile device and on our secure servers. Your stored information is not given or sold to any third parties. The app activity information is associated with your personal information only when you are signed in."), style: Onboarding2InfoDialog.contentStyle,),
      Container(height: 24,),
      Text(Localization().getStringEx('panel.onboarding2.personalize.learn_more.title4',"Opting Out"), style: Onboarding2InfoDialog.titleStyle,),
      Container(height: 8,),
      Text(Localization().getStringEx('panel.onboarding2.personalize.learn_more.location_services.content4',"The Privacy Center allows you to opt out of information collection at any time and provides the option to remove your data."), style: Onboarding2InfoDialog.contentStyle,),
    ]);

  void _onTapContinue() {
    Analytics().logSelect(target: 'Continue');
    Onboarding2().privacyPersonalizeSelection = _toggled;
    if (Onboarding2().privacyPersonalizeSelection) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2ImprovePanel()));
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2PrivacyPanel()));
    }
  }

  void _onTapBack() {
    Analytics().logSelect(target: 'Back');
    Navigator.of(context).pop();
  }

}