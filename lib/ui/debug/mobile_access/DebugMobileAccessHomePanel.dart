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
import 'package:flutter/cupertino.dart';
import 'package:illinois/ui/debug/mobile_access/DebugMobileAccessKeysEndpointSetupPanel.dart';
import 'package:illinois/ui/debug/mobile_access/DebugMobileAccessLockServicesCodesPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/styles.dart';

class DebugMobileAccessHomePanel extends StatefulWidget {
  @override
  _DebugMobileAccessHomePanelState createState() => _DebugMobileAccessHomePanelState();
}

class _DebugMobileAccessHomePanelState extends State<DebugMobileAccessHomePanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: 'Mobile Access'),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar(),
        body: Column(children: <Widget>[
          Expanded(
              child: SingleChildScrollView(
                  child: Container(
                      color: Styles().colors!.background,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Container(height: 16),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            child: RoundedButton(
                                label: 'Register Device',
                                backgroundColor: Styles().colors!.background,
                                fontSize: 16.0,
                                textColor: Styles().colors!.fillColorPrimary,
                                borderColor: Styles().colors!.fillColorPrimary,
                                onTap: _onTapRegisterDevice)),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            child: RoundedButton(
                                label: 'Lock Service Codes',
                                backgroundColor: Styles().colors!.background,
                                fontSize: 16.0,
                                textColor: Styles().colors!.fillColorPrimary,
                                borderColor: Styles().colors!.fillColorPrimary,
                                onTap: _onTapLockServiceCodes)),
                        Container(height: 16)
                      ]))))
        ]));
  }

  void _onTapRegisterDevice() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugMobileAccessKeysEndpointSetupPanel()));
  }

  void _onTapLockServiceCodes() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugMobileAccessLockServicesCodesPanel()));
  }
}
