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
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class PrivacyTicketsDialog extends StatefulWidget {
  final Function? onContinueTap;

  PrivacyTicketsDialog({this.onContinueTap});

  @override
  _PrivacyTicketsDialogState createState() => _PrivacyTicketsDialogState();

  static show(BuildContext context, {Function? onContinueTap}){
    showDialog(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
          child: PrivacyTicketsDialog(onContinueTap: onContinueTap,),
        )
    );
  }

  static bool get shouldConfirm {
    return !FlexUI().isPaymentInfornationAvailable;
  }
}

class _PrivacyTicketsDialogState extends State<PrivacyTicketsDialog> {
  var _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    String title = Localization().getStringEx("widget.privacy_tickets_modal.label.header", "Buy Tickets");
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
              //Header
              Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Styles().colors!.fillColorPrimary,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                  ),
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                          height: 50,
                          width: double.infinity,
                          child: Stack(children: <Widget>[
                            Container(
                                height: 50,
                                width: double.infinity,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Semantics(
                                      label: title,
                                      hint: Localization().getStringEx("widget.privacy_tickets_modal.label.header.hint", "Header 1"),
                                      header: true,
                                      excludeSemantics: true,
                                      child: Text(
                                        title,
                                        style: Styles().textStyles?.getTextStyle("widget.dialog.message.large"),
                                        textAlign: TextAlign.center,
                                      )),
                                )),
                            Container(
                                height: 50,
                                width: double.infinity,
                                alignment: Alignment.centerRight,
                                child: Semantics(
                                    label: Localization().getStringEx("widget.privacy_tickets_modal.label.close", "Close"),
                                    button: true,
                                    excludeSemantics: true,
                                    child: InkWell(
                                        onTap: () {
                                          _onTapClose();
                                        },
                                        child: Container(child: Styles().images?.getImage('close-circle-white', excludeFromSemantics: true)))))
                          ])))),
              Container(
                  width: double.infinity,
                  color: Styles().colors!.white,
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Text(Localization().getStringEx("widget.privacy_tickets_modal.label.your_privacy", "Your privacy setting"),
                            style: Styles().textStyles?.getTextStyle("widget.item.medium.extra_fat")
                        ),
                        Padding(
                            padding: EdgeInsets.all(15),
                            child: CustomPaint(
                              painter: ShapesPainter(),
                              child: Text(Auth2().prefs?.privacyLevel?.toString() ?? "",
                                  style: Styles().textStyles?.getTextStyle("widget.dialog.message.small")),
                            )),
                        Container(
                          height: 10,
                        ),
                        Text(
                          Localization().getStringEx("widget.privacy_tickets_modal.label.not_allowed", "Does not allow us to collect payment information"),
                          textAlign: TextAlign.center,
                          style: Styles().textStyles?.getTextStyle("widget.item.medium.extra_fat")
                        ),
                        Container(
                          height: 10,
                        ),
                        Text(
                            Localization().getStringEx("widget.privacy_tickets_modal.label.understand",
                                "I understand that my information will be collected in the purchase process for any tickets I purchase."),
                            style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")
                        ),
                        Container(
                          height: 10,
                        ),
                        RoundedButton(
                          label: Localization().getStringEx("widget.privacy_tickets_modal.button.continue.label", "Continue to buy tickets"),
                          hint: Localization().getStringEx("widget.privacy_tickets_modal.button.continue.hint", ""),
                          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
                          backgroundColor: Colors.white,
                          borderColor: Styles().colors!.fillColorSecondary,
                          onTap: () {
                            Analytics().logAlert(text: "Buy Tickets Privacy Alert", selection: "Continue");
                            _closeModal();
                            widget.onContinueTap!();
                          },
                        ),
                        Container(
                          height: 20,
                        ),
                        Text(
                            Localization().getStringEx("widget.privacy_tickets_modal.label.change_privacy", "Change my privacy setting to allow tickets purchase"),
                            style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")
                        ),
                        Container(
                          height: 10,
                        ),
                        RoundedButton(
                          label: Localization().getStringEx("widget.privacy_tickets_modal.button.change_privacy.label", "Change my settings"),
                          hint: Localization().getStringEx("widget.privacy_tickets_modal.button.change_privacy.hint", ""),
                          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
                          backgroundColor: Colors.white,
                          borderColor: Styles().colors!.fillColorSecondary,
                          onTap: () {
                            _onTapChangePrivacySettings();
                          },
                        ),
                        Container(
                          height: 20,
                        ),
                      ])))
            ])));
  }

  _onTapChangePrivacySettings() {
    Analytics().logAlert(text: "Buy Tickets Privacy Alert", selection: "Edit my privacy");
    _closeModal();
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel()));
  }

  _onTapClose() {
    Analytics().logAlert(text: "Buy Tickets Privacy Alert", selection: "Close");
    _closeModal();
  }

  _closeModal() {
    Navigator.of(context).pop();
  }
}

class ShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Offset thumbCenter = size.center(Offset(0, 0));
    canvas.drawCircle(thumbCenter, 20, Paint()..color = Styles().colors!.fillColorSecondaryVariant!);
    canvas.drawCircle(thumbCenter, 18, Paint()..color = Styles().colors!.white!);
    canvas.drawCircle(thumbCenter, 15, Paint()..color = Styles().colors!.fillColorPrimary!);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
