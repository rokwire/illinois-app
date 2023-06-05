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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/onboarding.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/onboarding/OnboardingLoginPhoneConfirmPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class OnboardingLoginPhoneVerifyPanel extends StatefulWidget with OnboardingPanel {

  final Map<String, dynamic>? onboardingContext;
  final ValueSetter<dynamic>? onFinish;

  OnboardingLoginPhoneVerifyPanel({this.onboardingContext, this.onFinish});

  @override
  _OnboardingLoginPhoneVerifyPanelState createState() =>
      _OnboardingLoginPhoneVerifyPanelState();

  @override
  bool get onboardingCanDisplay {
    return (onboardingContext != null) && onboardingContext!['shouldVerifyPhone'] == true;
  }
}

class _OnboardingLoginPhoneVerifyPanelState
    extends State<OnboardingLoginPhoneVerifyPanel> {
  TextEditingController _phoneNumberController = TextEditingController();
  Auth2PhoneVerificationMethod? _verificationMethod = Auth2PhoneVerificationMethod.sms;
  String? _validationErrorMsg;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Styles().colors!.background,
        body: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
          child: Stack(children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 18, right: 18, top: 28, bottom: 24),
              child: SafeArea(child: SingleChildScrollView(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 36),
                      child: Text(
                          Localization().getStringEx(
                              'panel.onboarding.verify_phone.title',
                              'Connect to Illinois'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: Styles().fontFamilies!.bold,
                              fontSize: 36,
                              color: Styles().colors!.fillColorPrimary))),
                  Container(
                    height: 48,
                  ),
                  Padding(
                      padding: EdgeInsets.only(left: 12, right: 12, bottom: 32),
                      child: Text(
                          Localization().getStringEx(
                              "panel.onboarding.verify_phone.description",
                              "To verify your phone number, choose your preferred contact channel, and we'll send you a one-time authentication code."),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: Styles().fontFamilies!.regular,
                              fontSize: 18,
                              color: Styles().colors!.fillColorPrimary))),
                  Padding(
                    padding: EdgeInsets.only(left: 12, top: 12, bottom: 6),
                    child: Text(
                      Localization().getStringEx(
                          "panel.onboarding.verify_phone.phone_number.label",
                          "Phone number"),
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontSize: 16,
                          color: Styles().colors!.fillColorPrimary,
                          fontFamily: Styles().fontFamilies!.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
                    child: Semantics(
                      label: Localization().getStringEx(
                          "panel.onboarding.verify_phone.phone_number.label",
                          "Phone number"),
                      hint: Localization().getStringEx(
                          "panel.onboarding.verify_phone.phone_number.hint",
                          ""),
                      textField: true,
                      excludeSemantics: true,
                      value: _phoneNumberController.text,
                      child: TextField(
                        controller: _phoneNumberController,
                        autofocus: false,
                        onSubmitted: (_) => _clearErrorMsg,
                        cursorColor: Styles().colors!.textBackground,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                            fontSize: 16,
                            fontFamily: Styles().fontFamilies!.regular,
                            color: Styles().colors!.textBackground),
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.0,
                                style: BorderStyle.solid),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 2.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Semantics(
                            excludeSemantics: true,
                            label: Localization().getStringEx("panel.onboarding.verify_phone.text_me.label", "Text me"),
                            hint: Localization().getStringEx("panel.onboarding.verify_phone.text_me.hint", ""),
                            selected: _verificationMethod == Auth2PhoneVerificationMethod.sms,
                            button: true,
                            child: Radio(
                              activeColor: Styles().colors!.fillColorSecondary,
                              value: Auth2PhoneVerificationMethod.sms,
                              groupValue: _verificationMethod,
                              onChanged: _onMethodChanged,
                            ),
                          ),
                          ExcludeSemantics(child:
                            Text(
                              Localization().getStringEx(
                                  "panel.onboarding.verify_phone.text_me.label",
                                  "Text me"),
                              style: TextStyle(
                                  fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                            ))
                        ],
                      ),
                    ],
                  ),
                  Visibility(
                    visible: StringUtils.isNotEmpty(_validationErrorMsg),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        StringUtils.ensureNotEmpty(_validationErrorMsg),
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontFamily: Styles().fontFamilies!.medium),
                      ),
                    ),
                  ),
                  Container(
                    height: 48,
                  ),
                ],
              ),),),
            ),
            Visibility(
              visible: _isLoading,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            OnboardingBackButton(
                padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20),
                onTap: () {
                  Analytics().logSelect(target: "Back");
                  Navigator.pop(context);
                }), Align(alignment: Alignment.bottomCenter, child:
            Padding(padding: EdgeInsets.only(left: 18, right: 18, bottom: 24),child: RoundedButton(
                label: Localization().getStringEx(
                    "panel.onboarding.verify_phone.button.next.label",
                    "Next"),
                hint: Localization().getStringEx(
                    "panel.onboarding.verify_phone.button.next.hint", ""),
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                borderColor: Styles().colors!.fillColorSecondary,
                backgroundColor: Styles().colors!.background,
                onTap: () => _onTapNext()),),)
          ],),
        ));
  }

  void _onTapNext() {
    if (_isLoading) {
      return;
    }

    Analytics().logSelect(target: "Next");
    _clearErrorMsg();
    _validateUserInput();
    if (StringUtils.isNotEmpty(_validationErrorMsg)) {
      return;
    }

    String? phoneNumber = _phoneNumberController.text;
    if(kReleaseMode) {
      if (StringUtils.isUsPhoneValid(phoneNumber)) {
        phoneNumber = StringUtils.constructUsPhone(phoneNumber);
        if (StringUtils.isUsPhoneNotValid(phoneNumber)) {
          AppAlert.showDialogResult(context, Localization().getStringEx("panel.onboarding.verify_phone.validation.server_error.text", "Please enter a valid phone number"));
          return;
        }
      }
      else {
        AppAlert.showDialogResult(context, Localization().getStringEx("panel.onboarding.verify_phone.validation.server_error.text", "Please enter a valid phone number"));
        return;
      }
    }

    setState(() { _isLoading = true; });
    
    Auth2().authenticateWithPhone(phoneNumber).then((result) {
      if (mounted) {
        setState(() { _isLoading = false; });
        _onPhoneInitiated(phoneNumber, result);
      }
    });
  }

  void _onMethodChanged(Auth2PhoneVerificationMethod? method) {
    Analytics().logSelect(target: method?.toString());
    FocusScope.of(context).requestFocus(new FocusNode());
    setState(() {
      _verificationMethod = method;
    });
  }

  void _onPhoneInitiated(String? phoneNumber, Auth2PhoneRequestCodeResult result) {
    if (result == Auth2PhoneRequestCodeResult.failed) {
      setState(() {
        _validationErrorMsg = Localization().getStringEx(
            "panel.onboarding.verify_phone.validation.failed.text",
            "Failed to send authentication code. An unexpected error occurred.");
      });
    }
    else if (result == Auth2PhoneRequestCodeResult.failedAccountExist) {
      setState(() {
        _validationErrorMsg = Localization().getStringEx(
            "panel.onboarding.verify_phone.validation.exists.text",
            "Failed to send authentication code. An existing account is already using this phone number.");
      });
    }
    else if (widget.onboardingContext != null) {
      widget.onboardingContext!["phone"] = phoneNumber;
      Onboarding().next(context, widget);
    }
    else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => OnboardingLoginPhoneConfirmPanel(phoneNumber: phoneNumber, onFinish: widget.onFinish)));
    }
  }

  void _validateUserInput() {
    String phoneNumberValue = _phoneNumberController.text;
    if (StringUtils.isEmpty(phoneNumberValue)) {
      setState(() {
        _validationErrorMsg = Localization().getStringEx(
            'panel.onboarding.verify_phone.validation.phone_number.text',
            "Please, type your phone number");
      });
      return;
    }
    if (_verificationMethod == null) {
      setState(() {
        _validationErrorMsg = Localization().getStringEx(
            "panel.onboarding.verify_phone.validation.channel_selection.text",
            "Please, select verification method");
      });
      return;
    }
  }

  void _clearErrorMsg() {
    setState(() {
      _validationErrorMsg = null;
    });
  }
}
