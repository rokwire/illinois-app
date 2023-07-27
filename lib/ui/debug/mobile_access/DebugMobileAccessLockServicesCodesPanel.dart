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
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class DebugMobileAccessLockServicesCodesPanel extends StatefulWidget {
  DebugMobileAccessLockServicesCodesPanel();

  _DebugMobileAccessLockServicesCodesPanelState createState() => _DebugMobileAccessLockServicesCodesPanelState();
}

class _DebugMobileAccessLockServicesCodesPanelState extends State<DebugMobileAccessLockServicesCodesPanel> {
  static final String _codeDelimiter = ',';
  late TextEditingController _codesController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _codesController = TextEditingController();
    _initCodes();
  }

  @override
  void dispose() {
    _codesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: "Lock Service Codes"),
        body: SafeArea(
            child: Column(children: <Widget>[
          Expanded(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(16), child: _buildContent()))),
          Padding(
              padding: EdgeInsets.all(16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                RoundedButton(
                    label: "Change",
                    enabled: !_loading,
                    textColor: (!_loading) ? Styles().colors!.fillColorPrimary : Styles().colors!.disabledTextColor,
                    borderColor: (!_loading) ? Styles().colors!.fillColorSecondary : Styles().colors!.disabledTextColor,
                    backgroundColor: Styles().colors!.white,
                    fontFamily: Styles().fontFamilies!.bold,
                    contentWeight: 0.0,
                    fontSize: 16,
                    borderWidth: 2,
                    progress: _loading,
                    onTap: _onTapChange)
              ]))
        ])),
        backgroundColor: Styles().colors!.background);
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text("Lock Service Codes (comma separated integers):",
                style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary))),
        Stack(children: <Widget>[
          Semantics(
              textField: true,
              child: Container(
                  color: Styles().colors!.white,
                  child: TextField(
                      maxLines: 2,
                      controller: _codesController,
                      decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
                      style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground)))),
          Align(
              alignment: Alignment.topRight,
              child: Semantics(
                  button: true,
                  label: "Clear",
                  child: GestureDetector(
                      onTap: () {
                        _codesController.text = '';
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

  void _initCodes() {
    setStateIfMounted(() {
      _loading = true;
    });
    MobileAccess().getLockServiceCodes().then((value) {
      late String controllerText;
      if (value != null) {
        controllerText = value.join(_codeDelimiter);
      } else {
        controllerText = '';
      }
      setStateIfMounted(() {
        _codesController.text = controllerText;
        _loading = false;
      });
    });
  }

  void _onTapChange() {
    if (_loading) {
      return;
    }
    String codesStringValue = _codesController.text.trim();
    if (StringUtils.isEmpty(codesStringValue)) {
      AppAlert.showMessage(context, 'Please, type value for lock service codes.');
      return;
    }
    List<String>? codesStringList = codesStringValue.split(_codeDelimiter);
    if (CollectionUtils.isEmpty(codesStringList)) {
      AppAlert.showMessage(context, 'Please, fill valid comma separated integers.');
      return;
    }

    List<int>? lockServiceCodes;
    try {
      lockServiceCodes = codesStringList.map(int.parse).toList();
    } catch (e) {
      debugPrint('Failed to parse value {$codesStringValue} to list of integers. Reason: $e');
    }

    if (CollectionUtils.isEmpty(lockServiceCodes)) {
      AppAlert.showMessage(context, 'Please, fill valid comma separated integers.');
      return;
    }

    setStateIfMounted(() {
      _loading = true;
    });
    MobileAccess().setLockServiceCodes(lockServiceCodes!).then((success) {
      late String msg;
      if (success == true) {
        msg = 'Successfully changed lock service codes.';
      } else {
        msg = 'Failed to change lock service codes.';
      }
      AppAlert.showMessage(context, msg);
      setStateIfMounted(() {
        _loading = false;
      });
    });
  }
}
