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
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

import 'package:sprintf/sprintf.dart';

class Onboarding2LoginPhoneConfirmPanel extends StatefulWidget with Onboarding2Panel {

  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  Onboarding2LoginPhoneConfirmPanel({ this.onboardingCode = '', this.onboardingContext });

  GlobalKey<_Onboarding2LoginPhoneConfirmPanelState>? get globalKey => (super.key is GlobalKey<_Onboarding2LoginPhoneConfirmPanelState>) ?
    (super.key as GlobalKey<_Onboarding2LoginPhoneConfirmPanelState>) : null;

  @override
  bool get onboardingProgress => (globalKey?.currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => globalKey?.currentState?.onboardingProgress = value;
  @override
  Future<bool> isOnboardingEnabled() async => (onboardingContext?['login'] == true) && (phoneNumber?.isNotEmpty == true);

  String? get phoneNumber => JsonUtils.stringValue(onboardingContext?['phoneNumber']);
  bool get link => JsonUtils.boolValue(onboardingContext?['link']) == true;

  @override
  _Onboarding2LoginPhoneConfirmPanelState createState() => _Onboarding2LoginPhoneConfirmPanelState();
}

class _Onboarding2LoginPhoneConfirmPanelState extends State<Onboarding2LoginPhoneConfirmPanel> {
  TextEditingController _codeController = TextEditingController();
  String? _verificationErrorMsg;

  bool _isLoading = false;
  bool _link = false;
  bool _onboardingProgress = false;
  bool get _hasProgress => _onboardingProgress || _isLoading;

  @override
  void initState() {
    super.initState();
    _link = widget.link;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? phoneNumber = widget.phoneNumber;
    String maskedPhoneNumber = StringUtils.getMaskedPhoneNumber(phoneNumber);
    String description = sprintf(
        Localization().getStringEx(
            'panel.onboarding.confirm_phone.description.send', 'A one time code has been sent to %s. Enter your code below to continue.'),
        [maskedPhoneNumber]);
    return Scaffold(
      body: GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.translucent,
        onTap: ()=>FocusScope.of(context).requestFocus(new FocusNode()),
        child: Stack(children: <Widget>[

          Padding(
            padding: EdgeInsets.only(left: 18, right: 18, top: 24, bottom: 24),
            child: SafeArea( child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
            Expanded(child:SingleChildScrollView(child: Column(children: [
                Padding(
                  padding: EdgeInsets.only(left: 64, right: 64, bottom: 12),
                  child: Text(
                    Localization().getStringEx("panel.onboarding.confirm_phone.title",
                        "Confirm your code"),
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 36, color: Styles().colors.fillColorPrimary),
                  ),
                ),
                Container(
                  height: 48,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 12, right: 12, bottom: 32),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        color: Styles().colors.fillColorPrimary,
                        fontFamily: Styles().fontFamilies.regular),
                  ),
                ),
                Container(
                  height: 26,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 12, right: 12, bottom: 6),
                  child: Text(
                    Localization().getStringEx("panel.onboarding.confirm_phone.code.label", "One-time code"),
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 16,
                        color: Styles().colors.fillColorPrimary,
                        fontFamily: Styles().fontFamilies.bold),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
                    child: Semantics(
                      excludeSemantics: true,
                      label: Localization().getStringEx("panel.onboarding.confirm_phone.code.label", "One-time code"),
                      hint: Localization().getStringEx("panel.onboarding.confirm_phone.code.hint", ""),
                      value: _codeController.text,
                      child: TextField(
                        controller: _codeController,
                        autofocus: false,
                        onSubmitted: (_) => _clearErrorMsg,
                        cursorColor: Styles().colors.textDark,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            fontSize: 16,
                            fontFamily: Styles().fontFamilies.regular,
                            color: Styles().colors.textDark),
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
                    )),
                Visibility(
                  visible: StringUtils.isNotEmpty(_verificationErrorMsg),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    child: Text(
                      StringUtils.ensureNotEmpty(
                          _verificationErrorMsg),
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontFamily: Styles().fontFamilies.medium),
                    ),
                  ),
                ),
                ]))),
                Container(child:
                RoundedButton(
                    label: Localization().getStringEx(
                        "panel.onboarding.confirm_phone.button.confirm.label",
                        "Confirm phone number"),
                    hint: Localization().getStringEx(
                        "panel.onboarding.confirm_phone.button.confirm.hint", ""),
                    textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                    borderColor: Styles().colors.fillColorSecondary,
                    backgroundColor: Styles().colors.background,
                    onTap: () => _onTapConfirm())
                ),
                Visibility(
                  visible: _link,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: RoundedButton(
                      label: Localization().getStringEx(
                          "panel.onboarding.confirm_phone.button.link.cancel.label", "Cancel"),
                      hint: Localization().getStringEx(
                          "panel.onboarding.confirm_phone.button.link.cancel.hint", ""),
                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                      borderColor: Styles().colors.fillColorSecondary,
                      backgroundColor: Styles().colors.background,
                      onTap: () => _onTapCancel())
                  ),
                ),
              ],
            ),),),
          Visibility(
            visible: _hasProgress,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          OnboardingBackButton(
            padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20),
            onTap:() {
              Analytics().logSelect(target: "Back");
              Navigator.pop(context);
            }),

          ],),
        ),
      );
  }

  void _onTapConfirm() {

    if(_hasProgress){
      return;
    }

    Analytics().logSelect(target: "Confirm phone number");
    _clearErrorMsg();
    _validateCode();
    if (StringUtils.isNotEmpty(_verificationErrorMsg)) {
      return;
    }
    String? phoneNumber = widget.phoneNumber;
    setState(() {
      _isLoading = true;
    });

    if (!_link) {
      Auth2().handleCodeAuthentication(phoneNumber, _codeController.text).then((result) {
        _onPhoneVerified(result);
      });
    } else {
      Auth2Identifier? unverified = Auth2().account?.getIdentifier(phoneNumber, Auth2Identifier.typePhone);
      if (unverified != null) {
        Auth2().verifyAccountIdentifier(unverified.id, _codeController.text).then((result) {
          _onPhoneVerified(result ? Auth2SendCodeResult.succeeded : Auth2SendCodeResult.failedInvalid);
        });
      }
    }
  }

  void _onPhoneVerified(Auth2SendCodeResult result) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result == Auth2SendCodeResult.failed) {
        setState(() {
          _verificationErrorMsg = Localization().getStringEx("panel.onboarding.confirm_phone.validation.server_error.text", "Failed to verify code. An unexpected error occurred.");
        });
      } else if (result == Auth2SendCodeResult.failedInvalid) {
        setState(() {
          _verificationErrorMsg = Localization().getStringEx("panel.onboarding.confirm_phone.validation.invalid.text", "Incorrect code.");
        });
      } else {
        _finishedPhoneVerification();
      }
    }
  }

  void _finishedPhoneVerification() {
    // Hook this panels to Onboarding2
    _onboardingNext();
  }

  void _onTapCancel() {
    String phoneNumber = widget.phoneNumber ?? '';
    setState(() {
      _isLoading = true;
    });

    Auth2Identifier? accountIdentifier = Auth2().account?.getIdentifier(phoneNumber, Auth2Identifier.typePhone);
    if (accountIdentifier != null) {
      Auth2().unlinkAccountIdentifier(accountIdentifier.id).then((success) {
        if(mounted) {
          setState(() {
            _isLoading = false;
          });
          if (!success) {
            setState(() {
              _verificationErrorMsg = Localization().getStringEx("panel.onboarding.confirm_phone.link.cancel.text", "Failed to remove phone number from your account.");
            });
          }
          else {
            _finishedPhoneVerification();
          }
        }
      });
    }
  }

  void _validateCode() {
    String phoneNumberValue = _codeController.text;
    if (StringUtils.isEmpty(phoneNumberValue)) {
      setState(() {
        _verificationErrorMsg = Localization().getStringEx(
            "panel.onboarding.confirm_phone.validation.phone_number.text",
            "Please, fill your code");
      });
      return;
    }
  }

  void _clearErrorMsg() {
    setState(() {
      _verificationErrorMsg = null;
    });
  }

  // Onboarding

  bool get onboardingProgress => _onboardingProgress;
  set onboardingProgress(bool value) {
    setStateIfMounted(() {
      _onboardingProgress = value;
    });
  }

  //void _onboardingBack() => Navigator.of(context).pop();
  void _onboardingNext() {
    Onboarding2().next(context, widget);
  }
}
