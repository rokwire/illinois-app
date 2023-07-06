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
import 'package:illinois/service/MobileAccess.dart';
import 'package:illinois/ui/debug/mobile_access/DebugMobileAccessKeysEndpointSetupPanel.dart';
import 'package:illinois/ui/debug/mobile_access/DebugMobileAccessLockServicesCodesPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';

class DebugMobileAccessHomePanel extends StatefulWidget {
  @override
  _DebugMobileAccessHomePanelState createState() => _DebugMobileAccessHomePanelState();
}

class _DebugMobileAccessHomePanelState extends State<DebugMobileAccessHomePanel> {
  bool _twistAndGoEnabled = false;
  bool _twistAndGoLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadTwistAndGoEnabled();
  }

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
                        Padding(padding: EdgeInsets.all(16), child: _buildTwistAndGoWidget()),
                        Container(height: 16)
                      ]))))
        ]));
  }

  Widget _buildTwistAndGoWidget() {
    return Stack(alignment: Alignment.center, children: [
      InkWell(
          onTap: _onTapTwistAndGo,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        color: Styles().colors?.white,
                        border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(4))),
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Twist And Go',
                                style: Styles().textStyles?.getTextStyle('panel.settings.toggle_button.title.small.enabled')),
                            Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text('Rotate your mobile device 90\u00B0 to the right and left, as if turning a door knob.',
                                  maxLines: 4,
                                  style: Styles().textStyles?.getTextStyle('panel.settings.toggle_button.title.small.variant.enabled')),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text('Doors must be enabled for Twist and Go to work.',
                                  maxLines: 4,
                                  style: Styles().textStyles?.getTextStyle('panel.settings.toggle_button.title.small.variant.disabled')),
                            )
                          ])),
                          Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Styles().images?.getImage(_twistAndGoEnabled ? 'toggle-on' : 'toggle-off'))
                        ]))))
          ])),
      Visibility(visible: _twistAndGoLoading, child: CircularProgressIndicator(color: Styles().colors!.fillColorSecondary))
    ]);
  }

  void _loadTwistAndGoEnabled() {
    setStateIfMounted(() {
      _twistAndGoLoading = true;
    });
    MobileAccess().isTwistAndGoEnabled().then((enabled) {
      setStateIfMounted(() {
        _twistAndGoEnabled = enabled;
        _twistAndGoLoading = false;
      });
    });
  }

  void _onTapRegisterDevice() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugMobileAccessKeysEndpointSetupPanel()));
  }

  void _onTapLockServiceCodes() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugMobileAccessLockServicesCodesPanel()));
  }

  void _onTapTwistAndGo() {
    if (_twistAndGoLoading) {
      return;
    }
    _enableTwistAndGo(!_twistAndGoEnabled);
  }

  void _enableTwistAndGo(bool enable) {
    if (_twistAndGoEnabled == enable) {
      return;
    }
    setStateIfMounted(() {
      _twistAndGoLoading = true;
    });
    MobileAccess().enableTwistAndGo(enable).then((success) {
      setStateIfMounted(() {
        _twistAndGoLoading = false;
      });
      if (!success) {
        String msg = sprintf('Failed to %s Twist And Go. Please, try again later.', enable ? ['enable'] : ['disable']);
        AppAlert.showDialogResult(context, msg);
      } else {
        _loadTwistAndGoEnabled();
      }
    });
  }
}
