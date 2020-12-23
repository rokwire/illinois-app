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
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/ui/onboarding/onboarding2/Onboarding2PrivacyPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/SwipeDetector.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';

import 'Onboarding2Widgets.dart';

class Onboarding2ImprovePanel extends StatefulWidget{

  Onboarding2ImprovePanel();
  _Onboarding2ImprovePanelState createState() => _Onboarding2ImprovePanelState();
}

class _Onboarding2ImprovePanelState extends State<Onboarding2ImprovePanel> {
  bool _toggled = false;

  @override
  void initState() {
    _toggled = Onboarding2().getImproveChoice;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String titleText = Localization().getStringEx(
        'panel.onboarding2.improve.label.title',
        'Improve');
    String descriptionText = Localization().getStringEx(
        'panel.onboarding2.improve.label.description',
        'Do you want to share your activity? ');

    return Scaffold(
        backgroundColor: Styles().colors.background,
        body: SafeArea(child:SwipeDetector(
            onSwipeLeft: () => _goNext(context),
            onSwipeRight: () => _goBack(context),
            child:
            ScalableScrollView(
              scrollableChild:
              Container(
                  color: Styles().colors.white,
                  child:Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                            height: 8,
                            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            child:Row(children: [
                              Expanded(
                                  flex:1,
                                  child: Container(color: Styles().colors.fillColorPrimary,)
                              ),
                              Container(width: 2,),
                              Expanded(
                                  flex:1,
                                  child: Container(color: Styles().colors.fillColorPrimary,)
                              ),
                              Container(width: 2,),
                              Expanded(
                                  flex:1,
                                  child: Container(color: Styles().colors.fillColorPrimary,)
                              ),
                            ],)
                        ),
                        Row(children:[
                          Onboarding2BackButton(padding: const EdgeInsets.only(
                              left: 17, top: 19, right: 20, bottom: 27),
                              onTap: () {
                                Analytics.instance.logSelect(target: "Back");
                                _goBack(context);
                              }),
                        ],),
                        Semantics(
                            label: titleText,
                            hint: Localization().getStringEx(
                                'panel.onboarding2.improve.label.title.hint', ''),
                            excludeSemantics: true,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: 17, right: 17, top: 0, bottom: 12),
                              child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                      titleText,
                                      style: TextStyle(
                                          color: Styles().colors.textSurface,
                                          fontSize: 28,
                                          fontFamily: Styles().fontFamilies.bold
                                      ))
                              ),
                            )),
                        Semantics(
                            label: descriptionText,
                            excludeSemantics: true,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Text(
                                    descriptionText,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: Styles().fontFamilies.regular,
                                        fontSize: 16,
                                        color: Styles().colors.fillColorPrimary),
                                  )),
                            )),
                        Container(height: 24,),
                        Container(
                            height: 180,
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 100,
                                    child:Column(
                                        children:[
                                          CustomPaint(
                                            painter: TrianglePainter(painterColor: Styles().colors.background,),
                                            child: Container(
                                              height: 80,
                                            ),
                                          ),
                                          Container(height: 20, color: Styles().colors.background,)
                                        ]),
                                  ),
                                ),
                                Align(
                                    alignment: Alignment.center,
                                    child:Container(
                                      child: Image.asset("images/improve_illustration.png", excludeFromSemantics: true,),
                                    )
                                )
                              ],
                            )
                        )
                      ])),
              bottomNotScrollableWidget:
              Column(children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child:Text(
                    "The more you and others share, the more relevant events, places and info you get. Don't worry, you'll remain anonymous.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.regular,
                        fontSize: 14,
                        color: Styles().colors.textSurface),
                  )
                ),
                Container(height: 12,),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Styles().colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ToggleRibbonButton(
                            label: _toggleButtonLabel,
                            toggled: _toggled,
                            padding: EdgeInsets.all(0),
                            onTap: _onToggleTap,
                          ),
                          Container(height: 16,),
                          Text(
                            _toggleButtonDescription,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                fontFamily: Styles().fontFamilies.regular,
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: Styles().colors.textSurface),
                          ),
                          Container(height: 12,),
                          ScalableRoundedButton(
                            label: Localization().getStringEx('panel.onboarding2.improve.button.continue.title', 'Continue'),
                            hint: Localization().getStringEx('panel.onboarding2.improve.button.continue.hint', ''),
                            backgroundColor: Styles().colors.white,
                            borderColor: Styles().colors.fillColorSecondaryVariant,
                            textColor: Styles().colors.fillColorPrimary,
                            fontSize: 16,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            onTap: () => _goNext(context),
                          )
                        ],
                      ),
                    )
                ),
              ],),
            ))));
  }

  String get _toggleButtonLabel{
    return _toggled? "Yes." : "Not now.";
  }

  String get _toggleButtonDescription{
    return _toggled? "Anonymously share my activity." : "Don’t improve recommendations.";
  }

  void _onToggleTap(){
    setState(() {
      _toggled = !_toggled;
    });
  }

  void _goNext(BuildContext context) {
    Onboarding2().storeImproveChoice(_toggled);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2PrivacyPanel()));
  }

  void _goBack(BuildContext context) {
    Navigator.of(context).pop();
  }
}