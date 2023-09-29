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
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasFeedbackPanel extends StatefulWidget {
  @override
  _CanvasFeedbackPanelState createState() => _CanvasFeedbackPanelState();
}

class _CanvasFeedbackPanelState extends State<CanvasFeedbackPanel> {
  TextEditingController _subjectController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: Localization().getStringEx('panel.canvas_feedback.header.title', 'Feedback')),
        body: _buildContent(),
        backgroundColor: Styles().colors!.white,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildContent() {
    return SafeArea(
        child: SingleChildScrollView(
            child: Stack(alignment: Alignment.center, children: [
      Padding(
          padding: EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                Localization()
                    .getStringEx('panel.canvas_feedback.file_ticket.label', 'File a ticket for a personal response from our support team.'),
                style: Styles().textStyles?.getTextStyle("widget.message.medium.thin")),
            Padding(
                padding: EdgeInsets.only(top: 25),
                child: Text(Localization().getStringEx('panel.canvas_feedback.subject.label', 'Subject'),
                    style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"))),
            Padding(
                padding: EdgeInsets.only(top: 10),
                child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                        border: Border.all(color: Styles().colors!.fillColorSecondary!, width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(7))),
                    child: TextField(
                        controller: _subjectController,
                        cursorColor: Styles().colors!.fillColorSecondary,
                        keyboardType: TextInputType.text,
                        style: Styles().textStyles?.getTextStyle("widget.input_field.text.regular"),
                        decoration: InputDecoration(border: InputBorder.none)))),
            Padding(
                padding: EdgeInsets.only(top: 25),
                child: Text(Localization().getStringEx('panel.canvas_feedback.description.label', 'Description'),
                    style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"))),
            Padding(
                padding: EdgeInsets.only(top: 10),
                child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                        border: Border.all(color: Styles().colors!.fillColorSecondary!, width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(7))),
                    child: TextField(
                        maxLines: 8,
                        controller: _descriptionController,
                        cursorColor: Styles().colors!.fillColorSecondary,
                        keyboardType: TextInputType.text,
                        style: Styles().textStyles?.getTextStyle("widget.input_field.text.regular"),
                        decoration: InputDecoration(border: InputBorder.none)))),
            Padding(
                padding: EdgeInsets.only(top: 20),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Expanded(child: Container()),
                  RoundedButton(
                      label: Localization().getStringEx('panel.canvas_feedback.submit.button', 'Submit'),
                      hint: Localization().getStringEx('panel.canvas_feedback.submit.hint', ''),
                      textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                      onTap: _onTapSubmit,
                      contentWeight: 0.0,
                      backgroundColor: Styles().colors!.white,
                      borderColor: Styles().colors!.fillColorSecondary)
                ]))
          ])),
      Visibility(visible: _loading, child: CircularProgressIndicator())
    ])));
  }

  void _onTapSubmit() {
    FocusScope.of(context).requestFocus(FocusNode());
    if (_loading) {
      return;
    }
    String subject = _subjectController.text;
    if (StringUtils.isEmpty(subject)) {
      AppAlert.showDialogResult(
          context, Localization().getStringEx('panel.canvas_feedback.subject.empty.message', 'Please, fill the subject.'));
      return;
    }
    setStateIfMounted(() {
      _loading = true;
    });
    Canvas().reportError(subject: subject, description: _descriptionController.text).then((success) {
      late String message;
      if (success) {
        message = Localization().getStringEx('panel.canvas_feedback.report.succeeded.message', 'Successfully reported a ticket.');
      } else {
        message = Localization()
            .getStringEx('panel.canvas_feedback.report.failed.message', 'Failed to report a ticket. Please, try again later.');
      }
      AppAlert.showDialogResult(context, message).then((_) {
        if (success) {
          Navigator.of(context).pop();
        }
      });
      setStateIfMounted(() {
        _loading = false;
      });
    });
  }
}
