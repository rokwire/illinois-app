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
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/ui/laundry/LaundrySubmittedIssuePanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class LaundryIssueContactInfoPanel extends StatefulWidget {
  final LaundryIssueRequest issueRequest;

  LaundryIssueContactInfoPanel({required this.issueRequest});

  @override
  _LaundryIssueContactInfoPanelState createState() => _LaundryIssueContactInfoPanelState();
}

class _LaundryIssueContactInfoPanelState extends State<LaundryIssueContactInfoPanel> {
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: Localization().getStringEx('panel.laundry.issues_contact_info.header.title', 'Laundry')),
        body: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [_buildLaundryColorSection(), _buildContactInfoHeader(), _buildInputFieldsSection(), _buildCompleteSection()])),
        backgroundColor: Styles().colors?.background,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildLaundryColorSection() {
    return Container(color: Styles().colors?.accentColor2, height: 4);
  }

  Widget _buildContactInfoHeader() {
    return Padding(
        padding: EdgeInsets.only(top: 40, bottom: 30),
        child: Text(Localization().getStringEx('panel.laundry.issues_contact_info.contact_info.label', 'Contact Information'),
            style: Styles().textStyles?.getTextStyle("widget.title.semi_huge")));
  }

  Widget _buildInputFieldsSection() {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          _buildSingleInputField(
              hintText: Localization().getStringEx('panel.laundry.issues_contact_info.first_name.hint', 'First Name*'),
              controller: _firstNameController),
          _buildSingleInputField(
              hintText: Localization().getStringEx('panel.laundry.issues_contact_info.last_name.hint', 'Last Name*'),
              controller: _lastNameController),
          _buildSingleInputField(
              hintText: Localization().getStringEx('panel.laundry.issues_contact_info.email.hint', 'Email*'), controller: _emailController),
          _buildSingleInputField(
              hintText: Localization().getStringEx('panel.laundry.issues_contact_info.phone.hint', 'Phone Number'),
              controller: _phoneController)
        ]));
  }

  Widget _buildSingleInputField({required String hintText, required TextEditingController controller}) {
    return Padding(
        padding: EdgeInsets.only(top: 10),
        child: Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors!.disabledTextColor!, width: 2))),
            child: TextField(
                controller: controller,
                cursorColor: Styles().colors!.mediumGray2!,
                style: Styles().textStyles?.getTextStyle("widget.input_field.dark.text.large"),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: Styles().textStyles?.getTextStyle("widget.input_field.disable.text.large")))));
  }

  Widget _buildCompleteSection() {
    return Padding(
        padding: EdgeInsets.only(top: 40),
        child: Stack(alignment: Alignment.center, children: [
          RoundedButton(
            backgroundColor: Styles().colors!.fillColorPrimary,
            textStyle: Styles().textStyles?.getTextStyle("widget.colourful_button.title.large.accent"),
            contentWeight: 0.73,
            borderColor: Styles().colors!.fillColorPrimary,
            label: Localization().getStringEx('panel.laundry.issues_contact_info.complete.button', 'Complete Request'),
            onTap: _onTapComplete,
            rightIcon: Styles().images?.getImage('chevron-right-white', excludeFromSemantics: true)),
            Visibility(visible: _isLoading, child: CircularProgressIndicator())
        ]));
  }

  void _onTapComplete() {
    if (_isLoading) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    String? firstName = _firstNameController.text;
    if (StringUtils.isEmpty(firstName)) {
      AppAlert.showDialogResult(
          context, Localization().getStringEx('panel.laundry.issues_contact_info.missing.first_name.msg', 'Please, fill First Name.'));
      return;
    }
    String? lastName = _lastNameController.text;
    if (StringUtils.isEmpty(lastName)) {
      AppAlert.showDialogResult(
          context, Localization().getStringEx('panel.laundry.issues_contact_info.missing.last_name.msg', 'Please, fill Last Name.'));
      return;
    }
    String? email = _emailController.text;
    if (!StringUtils.isEmailValid(email)) {
      AppAlert.showDialogResult(
          context, Localization().getStringEx('panel.laundry.issues_contact_info.missing.email.msg', 'Please, fill valid email.'));
      return;
    }
    String? phone = StringUtils.isNotEmpty(_phoneController.text) ? _phoneController.text : null;
    if (phone != null) {
      if (!StringUtils.isPhoneValid(phone)) {
        AppAlert.showDialogResult(
            context, Localization().getStringEx('panel.laundry.issues_contact_info.missing.phone.msg', 'Please, fill valid phone number.'));
        return;
      }
    }
    _setLoading(true);
    LaundryIssueRequest request = LaundryIssueRequest(
        machineId: widget.issueRequest.machineId,
        issueCode: widget.issueRequest.issueCode,
        comments: widget.issueRequest.comments,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone);
    Laundries().submitIssueRequest(issueRequest: request).then((issueResponse) {
      if (issueResponse?.isSucceeded == true) {
        Analytics().logSelect(target: "Laundry: Submitted Issue");
        Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundrySubmittedIssuePanel()));
      } else {
        String failedMsg = StringUtils.ensureNotEmpty(issueResponse?.message,
            defaultValue: Localization()
                .getStringEx('panel.laundry.issues_contact_info.submit.failed.msg', 'Failed to submit issue. Please, try again.'));
        AppAlert.showDialogResult(context, failedMsg);
      }
      _setLoading(false);
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (mounted) {
      setState(() {});
    }
  }
}
