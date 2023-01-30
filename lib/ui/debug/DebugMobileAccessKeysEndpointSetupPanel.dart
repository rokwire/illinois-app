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
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class DebugMobileAccessKeysEndpointSetupPanel extends StatefulWidget {
  DebugMobileAccessKeysEndpointSetupPanel();

  _DebugMobileAccessKeysEndpointSetupPanelState createState() => _DebugMobileAccessKeysEndpointSetupPanelState();
}

class _DebugMobileAccessKeysEndpointSetupPanelState extends State<DebugMobileAccessKeysEndpointSetupPanel> {
  TextEditingController? _invitationCodeController;

  bool? _setupProcessing;

  @override
  void initState() {
    super.initState();
    _invitationCodeController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _invitationCodeController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: "Mobile Access Keys Endpoint Setup"),
        body: SafeArea(
            child: Column(children: <Widget>[
          Expanded(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(16), child: _buildContent()))),
          _buildSetup()
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

  Widget _buildSetup() {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: <Widget>[
          Expanded(child: Container()),
          RoundedButton(
              label: "Setup",
              textColor: Styles().colors!.fillColorPrimary,
              borderColor: Styles().colors!.fillColorSecondary,
              backgroundColor: Styles().colors!.white,
              fontFamily: Styles().fontFamilies!.bold,
              contentWeight: 0.0,
              fontSize: 16,
              borderWidth: 2,
              progress: _setupProcessing,
              onTap: _onSetup),
          Expanded(child: Container())
        ]));
  }

  void _onSetup() {
    final String regExPattern = '[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}';
    String? invitationCode = _invitationCodeController?.text;
    if (StringUtils.isNotEmpty(invitationCode) && (invitationCode!.length == 19) && RegExp(regExPattern).hasMatch(invitationCode)) {
      _setSetupProcessing(true);
      NativeCommunicator().mobileAccessKeysEndpointSetup(invitationCode).then((success) {
        _setSetupProcessing(false);
      });
    } else {
      AppAlert.showMessage(context, 'Please, fill valid code in format XXXX-XXXX-XXXX-XXXX');
    }
  }

  void _setSetupProcessing(bool processing) {
    setStateIfMounted(() {
      _setupProcessing = processing;
    });
  }
}
