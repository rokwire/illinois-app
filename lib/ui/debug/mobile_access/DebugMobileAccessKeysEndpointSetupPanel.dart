/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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
import 'package:illinois/service/MobileAccess.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class DebugMobileAccessKeysEndpointSetupPanel extends StatefulWidget {
  DebugMobileAccessKeysEndpointSetupPanel();

  _DebugMobileAccessKeysEndpointSetupPanelState createState() => _DebugMobileAccessKeysEndpointSetupPanelState();
}

class _DebugMobileAccessKeysEndpointSetupPanelState extends State<DebugMobileAccessKeysEndpointSetupPanel> implements NotificationsListener {
  TextEditingController? _invitationCodeController;

  int _loadingProgress = 0;
  bool? _isRegistered;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [MobileAccess.notifyDeviceRegistrationFinished]);
    _invitationCodeController = TextEditingController();
    _increaseProgress();
    MobileAccess().isEndpointRegistered().then((registered) {
      _isRegistered = registered;
      _decreaseProgress();
    });
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _invitationCodeController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: "Mobile Access Keys Endpoint Setup"),
        body: SafeArea(
            child: Column(children: <Widget>[
          Expanded(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(16), child: _buildContent()))),
          Padding(padding: EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            RoundedButton(
                label: "Register",
                enabled: (_isRegistered == false),
                textColor: (_isRegistered == false) ? Styles().colors!.fillColorPrimary : Styles().colors!.disabledTextColor,
                borderColor: (_isRegistered == false) ? Styles().colors!.fillColorSecondary : Styles().colors!.disabledTextColor,
                backgroundColor: Styles().colors!.white,
                fontFamily: Styles().fontFamilies!.bold,
                contentWeight: 0.0,
                fontSize: 16,
                borderWidth: 2,
                progress: _isLoading,
                onTap: _onRegister),
            RoundedButton(
                label: "Unregister",
                enabled: (_isRegistered == true),
                textColor: (_isRegistered == true) ? Styles().colors!.fillColorPrimary : Styles().colors!.disabledTextColor,
                borderColor: (_isRegistered == true) ? Styles().colors!.fillColorSecondary : Styles().colors!.disabledTextColor,
                backgroundColor: Styles().colors!.white,
                fontFamily: Styles().fontFamilies!.bold,
                contentWeight: 0.0,
                fontSize: 16,
                borderWidth: 2,
                progress: _isLoading,
                onTap: _onUnregister)
          ]))
        ])),
        backgroundColor: Styles().colors!.background);
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text("Invitation Code:",
                style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary))),
        Stack(children: <Widget>[
          Semantics(
              textField: true,
              child: Container(
                  color: Styles().colors!.white,
                  child: TextField(
                      maxLines: 2,
                      controller: _invitationCodeController,
                      decoration: InputDecoration(
                          hintText: 'XXXX-XXXX-XXXX-XXXX',
                          border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
                      style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground)))),
          Align(
              alignment: Alignment.topRight,
              child: Semantics(
                  button: true,
                  label: "Clear",
                  child: GestureDetector(
                      onTap: () {
                        _invitationCodeController!.text = '';
                      },
                      child: Container(
                          width: 36,
                          height: 36,
                          child: Align(
                              alignment: Alignment.center,
                              child: Semantics(
                                  excludeSemantics: true,
                                  child: Text('X',
                                      style: TextStyle(
                                          fontFamily: Styles().fontFamilies!.regular,
                                          fontSize: 16,
                                          color: Styles().colors!.fillColorPrimary))))))))
        ])
      ])
    ]);
  }

  void _onRegister() {
    if (_isLoading || (_isRegistered == true)) {
      return;
    }
    final String regExPattern = '[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}';
    String? invitationCode = _invitationCodeController?.text;
    if (StringUtils.isNotEmpty(invitationCode) && (invitationCode!.length == 19) && RegExp(regExPattern).hasMatch(invitationCode)) {
      _increaseProgress();
      MobileAccess().registerEndpoint(invitationCode).then((success) {
        late String msg;
        if (success == true) {
          msg = 'Device registering was successfully initiated. Please wait until a confirmation message is received.';
        } else {
          msg = 'Failed to initiate device registration.';
        }
        AppAlert.showMessage(context, msg);
        _decreaseProgress();
      });
    } else {
      AppAlert.showMessage(context, 'Please, fill valid code in format XXXX-XXXX-XXXX-XXXX');
    }
  }

  void _onUnregister() {
    if (_isLoading || (_isRegistered == false)) {
      return;
    }
    _increaseProgress();
    MobileAccess().unregisterEndpoint().then((success) {
      _decreaseProgress();
    });
  }

  void _onDeviceRegistrationFinished(bool? succeeded) {
    late String msg;
    if (succeeded == true) {
      msg = "Device registration finished successfully.";
    } else {
      msg = "Failed to register device.";
    }
    AppAlert.showDialogResult(context, msg);
  }

  bool get _isLoading {
    return (_loadingProgress > 0);
  }

  void _increaseProgress() {
    setStateIfMounted(() {
      _loadingProgress++;
    });
  }

  void _decreaseProgress() {
    setStateIfMounted(() {
      _loadingProgress--;
    });
  }
  
  @override
  void onNotification(String name, param) {
    if (name == MobileAccess.notifyDeviceRegistrationFinished) {
      bool? succeeded = (param is bool) ? param : null;
      _onDeviceRegistrationFinished(succeeded);
    }
  }
}
