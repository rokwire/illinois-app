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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'Onboarding2Widgets.dart';

class Onboarding2PrivacyLocationServicesPanel extends StatefulWidget with Onboarding2Panel {
  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  Onboarding2PrivacyLocationServicesPanel({ super.key, this.onboardingCode = '', this.onboardingContext });

  _Onboarding2PrivacyLocationServicesPanelState? get _currentState => JsonUtils.cast(globalKey?.currentState);

  @override
  bool get onboardingProgress => (_currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => _currentState?.onboardingProgress = value;

  @override
  State<StatefulWidget> createState() => _Onboarding2PrivacyLocationServicesPanelState();
}

class _Onboarding2PrivacyLocationServicesPanelState extends State<Onboarding2PrivacyLocationServicesPanel> {
  bool _toggled = true;
  bool _onboardingProgress = false;

  @override
  void initState() {
    _toggled = Onboarding2().privacyLocationServicesSelection;
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
        SwipeDetector(onSwipeLeft: _onboardingNext, onSwipeRight: _onboardingBack, child:
          Column(children: [
            Expanded(child:
              SingleChildScrollView(child:
                Container(color: Styles().colors.white, child:
                  Column(children: <Widget>[
                    Padding(padding: EdgeInsets.all(Onboarding2PrivacyProgress.defaultSpacing), child:
                      Onboarding2PrivacyProgress(1)
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
                        Text(_title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.onboarding2.privacy.location_services.title"))
                      )
                    ),

                    Semantics(
                      label: _description,
                      excludeSemantics: true,
                      child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                        Text(_description, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.detail.regular")),
                      )
                  ),

                  Container(height: 10,),

                  Onboarding2UnderlinedButton(
                    title: Localization().getStringEx('panel.onboarding2.privacy.share_activity.button.title.learn_more', 'Learn More'),
                    textStyle: Styles().textStyles.getTextStyle("widget.button.title.small.medium.underline"),
                    onTap: _onTapLearnMore,
                  ),

                  Container(height: 24,),

                  Stack(children: [
                    Column(children:[
                      CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background,), child:
                        Container(height: 80,),
                      ),
                      Container(height: 20, color: Styles().colors.background,)
                    ]),
                    Positioned.fill(child:
                      Center(child:
                        Styles().images.getImage('explore-illustration', excludeFromSemantics: true),
                      )
                    )
                  ],),
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
                label: Localization().getStringEx('panel.onboarding2.privacy.location_services.button.continue.title', 'Continue'),
                hint: Localization().getStringEx('panel.onboarding2.privacy.location_services.button.continue.hint', ''),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Styles().colors.white,
                borderColor: Styles().colors.fillColorSecondaryVariant,
                progress: _onboardingProgress,
                onTap: _onTapContinue,
              )
            ],),
          ),
        ],)
      ),
    )
  );

  String get _title => Localization().getStringEx('panel.onboarding2.privacy.location_services.label.title', 'Enable location specific services?');
  String get _description => Localization().getStringEx('panel.onboarding2.explore_campus.label.description', 'Find nearby events and bus stops or request a SafeWalk from your exact location.');
  String get _toggledButtonTitle => Localization().getStringEx('panel.onboarding2.privacy.location_services.button.toggle.title', 'Enable location services.');
  String get _unToggledButtonTitle => Localization().getStringEx('panel.onboarding2.privacy.location_services.button.untoggle.title', 'Don\'t enable location services.');

  void _onToggleTap(){
    setState(() {
      _toggled = !_toggled;
    });
  }

  void _onTapLearnMore(){
    Analytics().logSelect(target: 'Learn More');
    Onboarding2InfoDialog.show(context: context, content: _learnMoreDialog,);
  }

  Widget get _learnMoreDialog =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(Localization().getStringEx('panel.onboarding2.privacy.location_services.learn_more.location_services.title',"Location Specific Services "), style: Onboarding2InfoDialog.titleStyle,),
      Container(height: 8,),
      Text(Localization().getStringEx('panel.onboarding2.privacy.location_services.learn_more.location_services.content1',"When Location Services is enabled, the app can find events and services near you and provide interactive maps. "), style: Onboarding2InfoDialog.contentStyle,),
      Container(height: 10,),
      Text(Localization().getStringEx('panel.onboarding2.privacy.location_services.learn_more.location_services.content2',"When Bluetooth is enabled, the app can exchange information with other devices for MTD pass. Bluetooth helps you find your seat, parking spot, in-building messaging and outdoor services that may be near you."), style: Onboarding2InfoDialog.contentStyle,),
    ]);

  void _onTapBack() {
    Analytics().logSelect(target: 'Back');
    _onboardingBack();
  }

  void _onTapContinue() {
    Analytics().logSelect(target: 'Continue');
    _onboardingNext();
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

  // Onboarding

  bool get onboardingProgress => _onboardingProgress;
  set onboardingProgress(bool value) {
    setStateIfMounted(() {
      _onboardingProgress = value;
    });
  }

  void _onboardingBack() => Navigator.of(context).pop();
  void _onboardingNext() async {
    Onboarding2().privacyLocationServicesSelection = _toggled;
    await _requestLocationPermissionsIfNeeded();
    if (mounted) {
      Onboarding2().next(context, widget);
    }
  }
}