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
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart' as firebase;
import 'package:rokwire_plugin/utils/utils.dart';

class Onboarding2AuthNotificationsPanel extends StatefulWidget with Onboarding2Panel {
  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  Onboarding2AuthNotificationsPanel({ super.key, this.onboardingCode = '', this.onboardingContext });

  _Onboarding2AuthNotificationsPanelState? get _currentState => JsonUtils.cast(globalKey?.currentState);

  @override
  bool get onboardingProgress => (_currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => _currentState?.onboardingProgress = value;

  @override
  Future<bool> isOnboardingEnabled() async {
    firebase.NotificationSettings settings = await firebase.FirebaseMessaging.instance.getNotificationSettings();
    firebase.AuthorizationStatus authorizationStatus = settings.authorizationStatus;
    // There is not "notDetermined" status for android. Threat "denied" in Android like "notDetermined" in iOS
    if (Platform.isAndroid) {
      return (authorizationStatus == firebase.AuthorizationStatus.denied);
    } else if (Platform.isIOS) {
      return (authorizationStatus == firebase.AuthorizationStatus.notDetermined);
    } else {
      return false;
    }
  }

  @override
  State<StatefulWidget> createState() => _Onboarding2AuthNotificationsPanelState();
}

class _Onboarding2AuthNotificationsPanelState extends State<Onboarding2AuthNotificationsPanel> {

  bool _onboardingProgress = false;

  @override
  Widget build(BuildContext context) {
    String titleText = Localization().getStringEx('panel.onboarding.notifications.label.title', 'Event info when you need it');
    String notRightNow = Localization().getStringEx('panel.onboarding.notifications.button.dont_allow.title', 'Not right now');
    return Scaffold(backgroundColor: Styles().colors.background, body:
      SwipeDetector(onSwipeLeft: _onboardingNext, onSwipeRight: _onboardingBack, child:
        Column(children: [
          Expanded(child:
            SingleChildScrollView(child:
              Column(children: <Widget>[
                Stack(children: <Widget>[
                  Styles().images.getImage('header-notifications', fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true,) ?? Container(),
                  OnboardingBackButton(padding: const EdgeInsets.all(16), onTap:_onTapBack),
                ]),
                Semantics(label: titleText, hint: Localization().getStringEx('panel.onboarding.notifications.label.title.hint', 'Header 1'), excludeSemantics: true, child:
                  Padding(padding: EdgeInsets.symmetric(horizontal: 24), child:
                    Align(alignment: Alignment.center, child:
                      Text(titleText, textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 32, color: Styles().colors.fillColorPrimary),),
                    )
                  )
                ),
                Container(height: 12,),
                Padding(padding: EdgeInsets.symmetric(horizontal: 24), child:
                  Align(alignment: Alignment.topCenter, child:
                    Text(Localization().getStringEx('panel.onboarding.notifications.label.description', 'Get notified about your “starred” events.'), textAlign: TextAlign.center, style:TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 20, color: Styles().colors.fillColorPrimary),)
                  ),
                ),
              ]),
            )
          ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 24,vertical: 8), child:
            Column(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
              RoundedButton(
                label: Localization().getStringEx('panel.onboarding.notifications.button.allow.title', 'Receive Notifications'),
                hint: Localization().getStringEx('panel.onboarding.notifications.button.allow.hint', ''),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                borderColor: Styles().colors.fillColorSecondary,
                backgroundColor: Styles().colors.white,
                progress: _onboardingProgress,
                onTap: _onTapReceiveNotifications,
              ),
              InkWell(onTap: _onTapSkip, child:
                Semantics(label: notRightNow, hint:Localization().getStringEx('panel.onboarding.notifications.button.dont_allow.hint', ''), button: true, excludeSemantics: true, child:
                  Padding(padding: EdgeInsets.symmetric(vertical: 20), child:
                    Text(notRightNow, style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Styles().colors.fillColorPrimary, decoration: TextDecoration.underline, decorationColor: Styles().colors.fillColorSecondary, decorationThickness: 1, decorationStyle: TextDecorationStyle.solid),)
                  )
                ),
              ),
            ],),
          ),
        ],)
      )
    );
  }

  void _onTapReceiveNotifications() {
    Analytics().logSelect(target: 'Receive Notifications') ;
    _onboardingNext(true);
  }

Future<bool> _requestAuthorization() async {
    firebase.FirebaseMessaging messagingInstance = firebase.FirebaseMessaging.instance;
    firebase.NotificationSettings settings = await messagingInstance.getNotificationSettings();
    firebase.AuthorizationStatus authorizationStatus = settings.authorizationStatus;
    // There is not "notDetermined" status for android. Threat "denied" in Android like "notDetermined" in iOS
    if ((Platform.isAndroid && (authorizationStatus != firebase.AuthorizationStatus.denied)) || (Platform.isIOS && (authorizationStatus != firebase.AuthorizationStatus.notDetermined))) {
      await showDialog(context: context, builder: (context) => _buildDialogWidget(authorizationStatus));
      return (authorizationStatus == firebase.AuthorizationStatus.authorized);
    } else {
      firebase.NotificationSettings requestSettings = await messagingInstance.requestPermission(alert: true, announcement: false, badge: true, carPlay: false, criticalAlert: false, provisional: false, sound: true);
      if (requestSettings.authorizationStatus == firebase.AuthorizationStatus.authorized) {
        Analytics().updateNotificationServices();
      }
      return true;
    }
  }

  Widget _buildDialogWidget(firebase.AuthorizationStatus authorizationStatus) {
    String? message;
    if (authorizationStatus == firebase.AuthorizationStatus.authorized) {
      message = Localization().getStringEx('panel.onboarding.notifications.label.access_granted', 'You already have granted access to this app.');
    }
    else if (authorizationStatus == firebase.AuthorizationStatus.denied) {
      message = Localization().getStringEx('panel.onboarding.notifications.label.access_denied', 'You already have denied access to this app.');
    }
    return Dialog(child:
      Padding(padding: EdgeInsets.all(18), child:
        Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(Localization().getStringEx('app.title', 'Illinois'), style: TextStyle(fontSize: 24, color: Colors.black),),
          Padding(padding: EdgeInsets.symmetric(vertical: 26), child:
            Text(message ?? '', textAlign: TextAlign.left, style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Colors.black),),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
            TextButton(onPressed: _onTapDialogOK, child:
              Text(Localization().getStringEx('dialog.ok.title', 'OK'))
            )
          ],)
        ],),
      ),
    );
  }

  void _onTapDialogOK() {
    Analytics().logAlert(text:"Already have access", selection: "Ok");
    Navigator.of(context).pop();
  }

  void _onTapBack() {
    Analytics().logSelect(target: 'Not right now') ;
    _onboardingBack();
  }

  void _onTapSkip() {
    Analytics().logSelect(target: 'Not right now') ;
    _onboardingNext(false);
  }

  // Onboarding

  bool get onboardingProgress => _onboardingProgress;
  set onboardingProgress(bool value) {
    setStateIfMounted(() {
      _onboardingProgress = value;
    });
  }

  void _onboardingBack() => Navigator.of(context).pop();
  void _onboardingNext([bool requestAuthorization = false]) async {
    bool goNext = requestAuthorization ? await _requestAuthorization() : true;
    if (goNext && mounted) {
      Onboarding2().next(context, widget);
    }
  }
}
