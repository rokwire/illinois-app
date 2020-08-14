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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Onboarding.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/LocalNotifications.dart';
import 'package:illinois/ui/widgets/SwipeDetector.dart';
import 'dart:io' show Platform;

class OnboardingAuthNotificationsPanel extends StatelessWidget with OnboardingPanel {
  final Map<String, dynamic> onboardingContext;
  OnboardingAuthNotificationsPanel({this.onboardingContext});

  @override
  Widget build(BuildContext context) {
    String titleText = Localization().getStringEx('panel.onboarding.notifications.label.title', 'Event info when you need it');
    String notRightNow = Localization().getStringEx(
        'panel.onboarding.notifications.button.dont_allow.title',
        'Not right now');
    return Scaffold(
        backgroundColor: Styles().colors.background,
        body: SwipeDetector(
            onSwipeLeft: () => _goNext(context) ,
            onSwipeRight: () => _goBack(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Stack(children: <Widget>[
                  Image.asset(
                    'images/allow-notifications-header.png',
                    fit: BoxFit.fitWidth,
                    width: MediaQuery.of(context).size.width,
                    excludeFromSemantics: true,
                  ),
                  OnboardingBackButton(
                    padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20),
                    onTap:() {
                      Analytics.instance.logSelect(target: "Back");
                      _goBack(context);
                    }),
                ]),
                Semantics(
                    label: titleText,
                    hint: Localization().getStringEx('panel.onboarding.notifications.label.title.hint', 'Header 1'),
                    excludeSemantics: true,
                    child:
                    Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        titleText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies.bold,
                            fontSize: 32,
                            color: Styles().colors.fillColorPrimary),
                      ),
                    ))),
                Container(height: 12,),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    Localization().getStringEx('panel.onboarding.notifications.label.description', 'Get notified about your “starred” events.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.regular,
                        fontSize: 20,
                        color: Styles().colors.fillColorPrimary),
                  )),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        RoundedButton(
                          label: Localization().getStringEx('panel.onboarding.notifications.button.allow.title', 'Receive Notifications'),
                          hint: Localization().getStringEx('panel.onboarding.notifications.button.allow.hint', ''),
                          borderColor: Styles().colors.fillColorSecondary,
                          backgroundColor: Styles().colors.background,
                          textColor: Styles().colors.fillColorPrimary,
                          onTap: () => _onReceiveNotifications(context),
                        ),
                        GestureDetector(
                          onTap: () {
                            Analytics.instance.logSelect(target: 'Not right now') ;
                            return _goNext(context);
                          },
                          child: Semantics(
                            label:notRightNow,
                            hint:Localization().getStringEx('panel.onboarding.notifications.button.dont_allow.hint', ''),
                            button: true,
                            excludeSemantics: true,
                            child:Padding(
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
                                    decorationStyle: TextDecorationStyle.solid),
                              ))),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            )));
  }

  void _onReceiveNotifications(BuildContext context) {
    Analytics.instance.logSelect(target: 'Receive Notifications') ;

    //Android does not need for permission for user notifications
    if (Platform.isAndroid) {
      _goNext(context);
    } else if (Platform.isIOS) {
      _requestAuthorization(context);
    }
  }

void _requestAuthorization(BuildContext context) async {
    bool notificationsAuthorized = await NativeCommunicator().queryNotificationsAuthorization("query");
    if (notificationsAuthorized) {
      showDialog(context: context, builder: (context) => _buildDialogWidget(context));
    } else {
      bool granted = await NativeCommunicator().queryNotificationsAuthorization("request");
      if (granted) {
        LocalNotifications().initPlugin();
        Analytics.instance.updateNotificationServices();
      }
      print('Notifications granted: $granted');
      _goNext(context);
    }
  }

Widget _buildDialogWidget(BuildContext context) {
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
                Localization().getStringEx('panel.onboarding.notifications.label.access_granted', 'Your settings have been changed.'),
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
                      Analytics.instance.logAlert(text:"Already have access", selection: "Ok");
                      _goNext(context, replace : true);
                    },
                    child: Text(Localization().getStringEx('dialog.ok.title', 'OK')))
              ],
            )
          ],
        ),
      ),
    );
  }

  void _goNext(BuildContext context, {bool replace = false}) {
    Onboarding().next(context, this, replace: replace);
  }

  void _goBack(BuildContext context) {
    Navigator.of(context).pop();
  }
}
