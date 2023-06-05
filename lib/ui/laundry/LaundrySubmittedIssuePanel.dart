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
import 'package:illinois/ui/laundry/LaundryRequestIssuePanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class LaundrySubmittedIssuePanel extends StatefulWidget {
  LaundrySubmittedIssuePanel();

  @override
  _LaundrySubmittedIssuePanelState createState() => _LaundrySubmittedIssuePanelState();
}

class _LaundrySubmittedIssuePanelState extends State<LaundrySubmittedIssuePanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            HeaderBar(title: Localization().getStringEx('panel.laundry.issues_submitted.header.title', 'Laundry'), onLeading: _onTapBack),
        body: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _buildLaundryColorSection(),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [_buildSuccessHeader(), _buildSuccessDescription(), _buildReturnWidget()]))
        ])),
        backgroundColor: Styles().colors?.background,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildLaundryColorSection() {
    return Container(color: Styles().colors?.accentColor2, height: 4);
  }

  Widget _buildSuccessHeader() {
    return Padding(
        padding: EdgeInsets.only(top: 40, bottom: 30),
        child: Text(
            Localization()
                .getStringEx('panel.laundry.issues_submitted.success.header.label', 'Thank You! Your Service Request has been received.'),
            textAlign: TextAlign.center,
            style: Styles().textStyles?.getTextStyle("widget.title.semi_huge")));
  }

  Widget _buildSuccessDescription() {
    return Padding(
        padding: EdgeInsets.only(bottom: 30),
        child: Text(
            Localization().getStringEx('panel.laundry.issues_submitted.success.description.label',
                'One of our technicians will arrive at your property within 3 business days to service the machine. We apologize for any inconvenience you may have experienced.'),
            textAlign: TextAlign.center,
            style: Styles().textStyles?.getTextStyle("widget.description.medium_large")));
  }

  Widget _buildReturnWidget() {
    return RoundedButton(
        label: Localization().getStringEx('panel.laundry.issues_submitted.return.button', 'Return'),
        textStyle: Styles().textStyles?.getTextStyle("widget.colourful_button.title.large.accent"),
        backgroundColor: Styles().colors!.fillColorPrimary,
        contentWeight: 0.5,
        borderColor: Styles().colors!.fillColorPrimary,
        onTap: _onTapBack,
        leftIcon: Styles().images?.getImage('chevron-left-white', excludeFromSemantics: true));
  }

  void _onTapBack() {
    Navigator.of(context).popUntil((route) {
      return route.settings.name == LaundryRequestIssuePanel.routeSettingsName;
    });
  }
}
