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
import 'package:flutter/services.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class LaundryRequestIssuePanel extends StatefulWidget {
  @override
  _LaundryRequestIssuePanelState createState() => _LaundryRequestIssuePanelState();
}

class _LaundryRequestIssuePanelState extends State<LaundryRequestIssuePanel> {
  final Color _inputDecorationColor = Styles().colors!.mediumGray2!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: Localization().getStringEx('panel.laundry.request_issue.header.title', 'Laundry')),
        body: SingleChildScrollView(
            child: Column(children: [
          _buildLaundryColorSection(),
          Padding(
              padding: EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                _buildMachineIdSection(),
                _buildSubmitSection(),
                _buildIdExampleSection()
              ]))
        ])),
        backgroundColor: Styles().colors?.background,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildLaundryColorSection() {
    return Container(color: Styles().colors?.accentColor2, height: 4);
  }

  Widget _buildMachineIdSection() {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 22),
              child: Text(Localization().getStringEx('panel.laundry.request_issue.machine_id.enter.label', 'Please enter the Machine ID'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 26, fontFamily: Styles().fontFamilies!.medium))),
          Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Styles().colors!.white,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _buildSymbolInputField(),
                _buildSymbolInputField(),
                _buildSymbolInputField(),
                Center(child: Container(height: 2, width: 20, color: _inputDecorationColor)),
                _buildSymbolInputField(),
                _buildSymbolInputField(),
                _buildSymbolInputField(),
              ]))
        ]));
  }

  Widget _buildSymbolInputField() {
    return Container(
        width: 40,
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _inputDecorationColor, width: 2))),
        child: Center(
            child: TextField(
                inputFormatters: [LengthLimitingTextInputFormatter(1)],
                cursorColor: _inputDecorationColor,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, color: Colors.black, fontFamily: Styles().fontFamilies!.medium),
                decoration: InputDecoration(border: InputBorder.none))));
  }

  Widget _buildSubmitSection() {
    return Padding(
        padding: EdgeInsets.only(bottom: 40),
        child: RoundedButton(
            backgroundColor: Styles().colors!.fillColorPrimary,
            textColor: Styles().colors!.white,
            contentWeight: 0.5,
            borderColor: Styles().colors!.fillColorPrimary,
            label: Localization().getStringEx('panel.laundry.request_issue.button.submit.label', 'Submit'),
            onTap: _onTapSubmit,
            rightIcon: Image.asset('images/chevron-right-white.png')));
  }

  Widget _buildIdExampleSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Padding(
          padding: EdgeInsets.only(bottom: 18),
          child: Text(Localization().getStringEx('panel.laundry.request_issue.machine_id.example.label', 'Machine ID Example'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold))),
      Image.asset('images/icon-laundry-machine-placeholder.png')
    ]);
  }

  void _onTapSubmit() {
    //TBD implement
  }
}
