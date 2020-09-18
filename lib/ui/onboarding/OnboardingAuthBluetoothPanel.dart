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
import 'package:illinois/service/BluetoothServices.dart';
import 'package:illinois/service/Onboarding.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/SwipeDetector.dart';

class OnboardingAuthBluetoothPanel extends StatefulWidget with OnboardingPanel {
  final Map<String, dynamic> onboardingContext;
  OnboardingAuthBluetoothPanel({this.onboardingContext});

  _OnboardingAuthBluetoothPanelState createState() => _OnboardingAuthBluetoothPanelState();
}

class _OnboardingAuthBluetoothPanelState extends State<OnboardingAuthBluetoothPanel> {

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
    String notRightNow = Localization().getStringEx(
        'panel.onboarding.bluetooth.button.dont_allow.title',
        'Not right now');
    return Scaffold(
        backgroundColor: Styles().colors.background,
        body: SwipeDetector(
            onSwipeLeft: () => _goNext(),
            onSwipeRight: () => _goBack(),
            child: ScalableScrollView( scrollableChild: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Stack(children: <Widget>[
                  Image.asset(
                    'images/enable-bluetooth-header.png',
                    fit: BoxFit.fitWidth,
                    width: MediaQuery.of(context).size.width,
                    excludeFromSemantics: true,
                  ),
                  OnboardingBackButton(
                    padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20),
                    onTap:() {
                      Analytics.instance.logSelect(target: "Back");
                      _goBack();
                    }),
                ]),
                Semantics(
                    label: getTitleText(),
                    hint: getTitleHint(),
                    excludeSemantics: true,
                    child:
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                          alignment: Alignment.center,
                          child: Text(getTitleText(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: Styles().fontFamilies.bold,
                                fontSize: 32,
                                color: Styles().colors.fillColorPrimary),
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
                            'panel.onboarding.bluetooth.label.description',
                            "Use Bluetooth to navigate campus buildings, find polls from friends, and board MTD buses."),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies.regular,
                            fontSize: 20,
                            color: Styles().colors.fillColorPrimary),
                  ))),
                ]),
                bottomNotScrollableWidget:
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24,vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ScalableRoundedButton(
                        label: Localization().getStringEx(
                            'panel.onboarding.bluetooth.button.allow.title',
                            'Share my location'),
                        hint: Localization().getStringEx(
                            'panel.onboarding.bluetooth.button.allow.hint',
                            ''),
                        borderColor: Styles().colors.fillColorSecondary,
                        backgroundColor: Styles().colors.background,
                        textColor: Styles().colors.fillColorPrimary,
                        onTap: () => _requestBluetooth(context),
                      ),
                      GestureDetector(
                        onTap: () {
                          Analytics.instance.logSelect(target: 'Not right now') ;
                         return  _goNext();
                        },
                        child: Semantics(
                            label: notRightNow,
                            hint: Localization().getStringEx(
                                'panel.onboarding.bluetooth.button.dont_allow.hint',
                                ''),
                            button: true,
                            excludeSemantics: true,
                            child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  notRightNow,
                                  style: TextStyle(
                                      fontFamily: Styles().fontFamilies.medium,
                                      fontSize: 16,
                                      color: Styles().colors.fillColorPrimary,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Styles().colors.fillColorSecondary,
                                      decorationThickness: 1,
                                      decorationStyle:
                                          TextDecorationStyle.solid),
                                ))),
                      )
                    ],
                  ),
                ),
            )));
  }

  void _requestBluetooth(BuildContext context) {

    Analytics.instance.logSelect(target: 'Enable Bluetooth') ;

    BluetoothStatus authStatus = BluetoothServices().status;
    if (authStatus == BluetoothStatus.PermissionNotDetermined) {
      BluetoothServices().requestStatus().then((_){
        _goNext();
      });
    }
    else if (authStatus == BluetoothStatus.PermissionDenied) {
      String message = Localization().getStringEx('panel.onboarding.bluetooth.label.access_denied', 'You have already denied access to this app.');
      showDialog(context: context, builder: (context) => _buildDialogWidget(context, message: message, pushNext: false));
    }
    else if (authStatus == BluetoothStatus.PermissionAllowed) {
      String message = Localization().getStringEx('panel.onboarding.bluetooth.label.access_granted', 'You have already granted access to this app.');
      showDialog(context: context, builder: (context) => _buildDialogWidget(context, message: message, pushNext: true));
    }
  }

  Widget _buildDialogWidget(BuildContext context, {String message, bool pushNext}) {
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
                    fontFamily: Styles().fontFamilies.medium,
                    fontSize: 16,
                    color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlatButton(
                    onPressed: () {
                      Analytics.instance.logAlert(text: message, selection:okTitle);
                      if (pushNext) {
                        _goNext(replace : true);
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

  void _goNext({bool replace = false}) {
    Onboarding().next(context, widget, replace: replace);
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  getTitleText() {
    return Localization().getStringEx(
        'panel.onboarding.bluetooth.label.title',
        "Know what's nearby");
  }

  getTitleHint() {
    return Localization().getStringEx(
        'panel.onboarding.bluetooth.label.title.hint',
        "");
  }
}
