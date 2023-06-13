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
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

import 'Onboarding2PersonalizePanel.dart';
import 'Onboarding2Widgets.dart';

class Onboarding2ExploreCampusPanel extends StatefulWidget{

  Onboarding2ExploreCampusPanel();
  _Onboarding2ExploreCampusPanelState createState() => _Onboarding2ExploreCampusPanelState();
}

class _Onboarding2ExploreCampusPanelState extends State<Onboarding2ExploreCampusPanel> {
  bool _toggled = false;

  @override
  void initState() {
    _toggled = Onboarding2().getExploreCampusChoice;
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
            child: Column(children: [
              Expanded(child:
                SingleChildScrollView(child:
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
                                child: Container(color: Styles().colors!.backgroundVariant,)
                            ),
                            Container(width: 2,),
                            Expanded(
                                flex:1,
                                child: Container(color: Styles().colors!.backgroundVariant,)
                            ),
                          ],)
                        ),
                        Row(children:[
                          Onboarding2BackButton(padding: const EdgeInsets.only(left: 17, top: 11, right: 20, bottom: 27),
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
                                    style: Styles().textStyles?.getTextStyle("panel.onboarding2.explore_campus.title"))
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
                                    style: Styles().textStyles?.getTextStyle("widget.detail.regular")
                                  )),
                            )),
                        Container(height: 10,),
                        Onboarding2UnderlinedButton(
                          title: Localization().getStringEx('panel.onboarding2.improve.button.title.learn_more', 'Learn More'),
                          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.small.semi_fat.underline"),
                          onTap: _onTapLearnMore,
                        ),
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
                                          painter: TrianglePainter(painterColor: Styles().colors!.background,),
                                          child: Container(
                                            height: 80,
                                          ),
                                        ),
                                        Container(height: 20, color: Styles().colors!.background,)
                                    ]),
                                  ),
                                ),
                              Align(
                                alignment: Alignment.center,
                                child:Container(
                                  child: Styles().images?.getImage('explore-illustration', excludeFromSemantics: true),
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
                      label: Localization().getStringEx('panel.onboarding2.explore_campus.button.continue.title', 'Continue'),
                      hint: Localization().getStringEx('panel.onboarding2.explore_campus.button.continue.hint', ''),
                      textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Styles().colors!.white,
                      borderColor: Styles().colors!.fillColorSecondaryVariant,
                      onTap: () => _goNext(context),
                    )
                  ],
                ),
              ),                
            ],)
          )));
  }

  void _onToggleTap(){
    setState(() {
      _toggled = !_toggled;
    });
  }

  void _goNext(BuildContext context) {
    Onboarding2().storeExploreCampusChoice(_toggled);
    _requestLocationPermissionsIfNeeded().then((_) {
      if (mounted) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2PersonalizePanel()));
      }
    });
  }

  Future<void> _requestLocationPermissionsIfNeeded() async {
    if (_toggled) {
      LocationServicesStatus? status = await LocationServices().status;
      /* This seems nonsence:
      if (status == LocationServicesStatus.serviceDisabled) {
        status = await LocationServices().requestService();
      }*/
      if (status == LocationServicesStatus.permissionNotDetermined) {
        await LocationServices().requestPermission();
      }
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
          Localization().getStringEx('panel.onboarding2.explore_campus.learn_more.location_services.title',"Location Specific Services "),
          style: Onboarding2InfoDialog.titleStyle,),
        Container(height: 8,),
        Text(Localization().getStringEx('panel.onboarding2.explore_campus.learn_more.location_services.content1',"When Location Services is enabled, the app can find events and services near you and provide interactive maps. "),
          style: Onboarding2InfoDialog.contentStyle,
        ),
        Container(height: 10,),
        Text(
          Localization().getStringEx('panel.onboarding2.explore_campus.learn_more.location_services.content2',"When Bluetooth is enabled, the app can exchange information with other devices for MTD pass. Bluetooth helps you find your seat, parking spot, in-building messaging and outdoor services that may be near you."),
          style: Onboarding2InfoDialog.contentStyle,),
        ]
      )
    );
  }

  String? get _title{
    return Localization().getStringEx('panel.onboarding2.explore_campus.label.title', 'Enable location specific services?');
  }

  String? get _description{
    return Localization().getStringEx('panel.onboarding2.explore_campus.label.description', 'Easily find events on campus and connect to nearby users.');
  }

  String? get _toggledButtonTitle{
    return Localization().getStringEx('panel.onboarding2.explore_campus.button.toggle.title', 'Enable location services.');
  }

  String? get _unToggledButtonTitle{
    return Localization().getStringEx('panel.onboarding2.explore_campus.button.untoggle.title', 'Don\'t enable location services.');
  }
}