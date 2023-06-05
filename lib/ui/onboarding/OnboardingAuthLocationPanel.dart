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
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/onboarding.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';

class OnboardingAuthLocationPanel extends StatelessWidget with OnboardingPanel {
  final Map<String, dynamic>? onboardingContext;
  OnboardingAuthLocationPanel({this.onboardingContext});

  @override
  Widget build(BuildContext context) {
    String titleText = Localization().getStringEx('panel.onboarding.location.label.title', "Know what's nearby");
    String notRightNow = Localization().getStringEx(
        'panel.onboarding.location.button.dont_allow.title',
        'Not right now');
    return Scaffold(
        backgroundColor: Styles().colors!.background,
        body: SwipeDetector(
            onSwipeLeft: () => _goNext(context),
            onSwipeRight: () => _goBack(context),
            child: Column(children: [
              Expanded(child:
                SingleChildScrollView(child:
                  Column(mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Stack(children: <Widget>[
                      Styles().images?.getImage(
                        'header-location',
                        fit: BoxFit.fitWidth,
                        width: MediaQuery.of(context).size.width,
                        excludeFromSemantics: true,
                      ) ?? Container(),
                      OnboardingBackButton(
                        padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20),
                        onTap:() {
                          Analytics().logSelect(target: "Back");
                          _goBack(context);
                        }),
                    ]),
                    Semantics(
                        label: titleText,
                        hint: Localization().getStringEx('panel.onboarding.location.label.title.hint', 'Header 1'),
                        excludeSemantics: true,
                        child:
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Align(
                              alignment: Alignment.center,
                              child: Text(titleText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: Styles().fontFamilies!.bold,
                                    fontSize: 32,
                                    color: Styles().colors!.fillColorPrimary),
                              )),
                        )),
                    Container(
                      height: 12,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          Localization().getStringEx(
                              'panel.onboarding.location.label.description',
                              "Share your location to know what's nearest to you while on campus."),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: Styles().fontFamilies!.regular,
                              fontSize: 20,
                              color: Styles().colors!.fillColorPrimary),
                        ),
                      )),
                    ]),
              )),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24,vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RoundedButton(
                      label: Localization().getStringEx(
                          'panel.onboarding.location.button.allow.title',
                          'Share my Location'),
                      hint: Localization().getStringEx(
                          'panel.onboarding.location.button.allow.hint',
                          ''),
                      textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                      borderColor: Styles().colors!.fillColorSecondary,
                      backgroundColor: Styles().colors!.background,
                      onTap: () => _requestLocation(context),
                    ),
                    GestureDetector(
                      onTap: () {
                        Analytics().logSelect(target: 'Not right now') ;
                        return  _goNext(context);
                      },
                      child: Semantics(
                          label: notRightNow,
                          hint: Localization().getStringEx(
                              'panel.onboarding.location.button.dont_allow.hint',
                              ''),
                          button: true,
                          excludeSemantics: true,
                          child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                notRightNow,
                                style: TextStyle(
                                    fontFamily: Styles().fontFamilies!.medium,
                                    fontSize: 16,
                                    color: Styles().colors!.fillColorPrimary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Styles().colors!.fillColorSecondary,
                                    decorationThickness: 1,
                                    decorationStyle:
                                        TextDecorationStyle.solid),
                              ))),
                    )
                  ],
                ),
              ),
            ],),
          ));
  }

  void _requestLocation(BuildContext context) async {
    Analytics().logSelect(target: 'Share My locaiton') ;
    await LocationServices().status.then((LocationServicesStatus? status){
      if (status == LocationServicesStatus.serviceDisabled) {
        LocationServices().requestService();
      }
      else if (status == LocationServicesStatus.permissionNotDetermined) {
        LocationServices().requestPermission().then((LocationServicesStatus? status) {
          _goNext(context);
        });
      }
      else if (status == LocationServicesStatus.permissionDenied) {
        String message = Localization().getStringEx('panel.onboarding.location.label.access_denied', 'You have already denied access to this app.');
        showDialog(context: context, builder: (context) => _buildDialogWidget(context, message:message, pushNext : false ));
      }
      else if (status == LocationServicesStatus.permissionAllowed) {
        String message = Localization().getStringEx('panel.onboarding.location.label.access_granted', 'You have already granted access to this app.');
        showDialog(context: context, builder: (context) => _buildDialogWidget(context, message:message, pushNext : true ));
      }
    });
  }

  Widget _buildDialogWidget(BuildContext context, {required String message, bool? pushNext}) {
    String okTitle = Localization().getStringEx('dialog.ok.title', 'OK');
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              Localization().getStringEx('app.title', 'Illinois'),
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Text(
                message,
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontFamily: Styles().fontFamilies!.medium,
                    fontSize: 16,
                    color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                    onPressed: () {
                      Analytics().logAlert(text: message, selection:okTitle);
                      if (pushNext!) {
                        _goNext(context, replace : true);
                      }
                      else {
                        _closeDialog(context);
                      }
                     },
                    child: Text(okTitle))
              ],
            )
          ],
        ),
      ),
    );
  }

  void _closeDialog(BuildContext context) {
    Navigator.pop(context, true);
  }

  void _goNext(BuildContext context, {bool replace = false}) {
    Onboarding().next(context, this, replace: replace);
  }

  void _goBack(BuildContext context) {
    Navigator.of(context).pop();
  }
}
