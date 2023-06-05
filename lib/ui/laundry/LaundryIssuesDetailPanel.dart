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
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/laundry/LaundryIssueContactInfoPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class LaundryIssuesDetailPanel extends StatefulWidget {
  final LaundryMachineServiceIssues issues;

  LaundryIssuesDetailPanel({required this.issues});

  @override
  _LaundryIssuesDetailPanelState createState() => _LaundryIssuesDetailPanelState();
}

class _LaundryIssuesDetailPanelState extends State<LaundryIssuesDetailPanel> {
  String? _selectedIssue;
  TextEditingController _commentsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: Localization().getStringEx('panel.laundry.issues_detail.header.title', 'Laundry')),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLaundryColorSection(), _buildMachineHeaderSection(), Expanded(child: _buildIssuesContentSection())]),
        backgroundColor: Styles().colors?.background,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildLaundryColorSection() {
    return Container(color: Styles().colors?.accentColor2, height: 4);
  }

  Widget _buildMachineHeaderSection() {
    return Container(
        decoration: BoxDecoration(
            color: Styles().colors!.disabledTextColor,
            boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]),
        child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              _buildMachineImageWidget(),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: Text(Localization().getStringEx('panel.laundry.issues_detail.machine_id.label', 'Machine ID:'),
                              style: Styles().textStyles?.getTextStyle("widget.title.medium"))),
                      Text(StringUtils.ensureNotEmpty(widget.issues.machineId),
                          style: Styles().textStyles?.getTextStyle("widget.title.medium.fat"))
                    ])),
                Row(children: [
                  Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Text(Localization().getStringEx('panel.laundry.issues_detail.machine_type.label', 'Machine Type:'),
                          style: Styles().textStyles?.getTextStyle("widget.title.medium"))),
                  Text(StringUtils.ensureNotEmpty(widget.issues.typeString),
                      style: Styles().textStyles?.getTextStyle("widget.title.medium.fat"))
                ])
              ])
            ])));
  }

  Widget _buildMachineImageWidget() {
    Widget? machineImagePlaceHolder;
    switch (widget.issues.type) {
      case LaundryApplianceType.washer:
        machineImagePlaceHolder = Styles().images?.getImage('washer-large', excludeFromSemantics: true) ?? Container();
        break;
      case LaundryApplianceType.dryer:
        machineImagePlaceHolder = Styles().images?.getImage('dryer-large', excludeFromSemantics: true) ?? Container();
        break;
      default:
    }
    return Padding(padding: EdgeInsets.only(right: 20), child: machineImagePlaceHolder);
  }

  Widget _buildIssuesContentSection() {
    return SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 26, horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(Localization().getStringEx('panel.laundry.issues_detail.select_issue.label', 'Select the issue you wish to report:'),
                  style: Styles().textStyles?.getTextStyle("widget.label.regular.fat")),
              Padding(
                  padding: EdgeInsets.only(top: 20, left: 10),
                  child: Column(children: [_buildIssuesWidget(), _buildCommentsSection(), _buildSubmitSection()]))
            ])));
  }

  Widget _buildIssuesWidget() {
    List<Widget> widgetList = <Widget>[];
    if (CollectionUtils.isNotEmpty(widget.issues.problemCodes)) {
      for (String issueCode in widget.issues.problemCodes!) {
        bool selected = (_selectedIssue == issueCode);
        widgetList.add(GestureDetector(
            onTap: () => _onTapIssueCode(issueCode),
            child: Padding(
                padding: EdgeInsets.only(top: 15),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Styles().images?.getImage(selected ? "check-box-filled" : "box-outline-gray", excludeFromSemantics: true) ?? Container(),
                  Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: Text(StringUtils.ensureNotEmpty(issueCode),
                          style: Styles().textStyles?.getTextStyle("widget.detail.small.semi_fat")))
                ]))));
      }
    }
    return Column(children: widgetList);
  }

  Widget _buildCommentsSection() {
    return Padding(
        padding: EdgeInsets.only(top: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(Localization().getStringEx('panel.laundry.issues_detail.comments.label', 'Additional Comments'),
                  style: Styles().textStyles?.getTextStyle("widget.detail.small.semi_fat"))),
          Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                  color: Styles().colors!.white,
                  boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]),
              child: TextField(
                  maxLines: 8,
                  style: Styles().textStyles?.getTextStyle("widget.text.medium"),
                  controller: _commentsController,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: Localization().getStringEx('panel.laundry.issues_detail.comments.hint', 'Let us know what the issue is.'),
                      hintStyle: Styles().textStyles?.getTextStyle("widget.message.light.variant.small"))))
        ]));
  }

  Widget _buildSubmitSection() {
    return Padding(
        padding: EdgeInsets.only(top: 40),
        child: RoundedButton(
            label: Localization().getStringEx('panel.laundry.issues_detail.continue.button', 'Continue'),
            textStyle: Styles().textStyles?.getTextStyle("widget.colourful_button.title.large.accent"),
            backgroundColor: Styles().colors!.fillColorPrimary,
            contentWeight: 0.6,
            borderColor: Styles().colors!.fillColorPrimary,
            onTap: _onTapContinue,
            rightIcon: Styles().images?.getImage('chevron-right-white', excludeFromSemantics: true)));
  }

  void _onTapIssueCode(String? issueCode) {
    if (_selectedIssue != issueCode) {
      _selectedIssue = issueCode;
    } else {
      _selectedIssue = null;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onTapContinue() {
    if(_selectedIssue == null) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.laundry.issues_detail.missing_issue.err.msg', 'Please, select an issue.'));
      return;
    }
    String? additionalComments = StringUtils.isNotEmpty(_commentsController.text) ? _commentsController.text : null;
    LaundryIssueRequest request = LaundryIssueRequest(machineId: widget.issues.machineId!, issueCode: _selectedIssue!, comments: additionalComments);
    Analytics().logSelect(target: "Laundry: Issue Contact Information");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryIssueContactInfoPanel(issueRequest: request)));
  }
}
