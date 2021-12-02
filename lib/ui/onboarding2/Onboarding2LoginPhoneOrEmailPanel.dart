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
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Onboarding.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/onboarding/OnboardingLoginPhoneConfirmPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/ui/onboarding2/Onboarding2LoginEmailPanel.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class Onboarding2LoginPhoneOrEmailPanel extends StatefulWidget with OnboardingPanel {

  final Map<String, dynamic>? onboardingContext;

  Onboarding2LoginPhoneOrEmailPanel({this.onboardingContext});

  @override
  _Onboarding2LoginPhoneOrEmailPanelState createState() => _Onboarding2LoginPhoneOrEmailPanelState();
}

class _Onboarding2LoginPhoneOrEmailPanelState extends State<Onboarding2LoginPhoneOrEmailPanel> {
  TextEditingController? _phoneOrEmailController;
  
  String? _validationErrorMsg;
  GlobalKey _validationErrorKey = GlobalKey();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneOrEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneOrEmailController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    EdgeInsetsGeometry backButtonInsets = EdgeInsets.only(left: 10, top: 20 + MediaQuery.of(context).padding.top, right: 20, bottom: 20);

    return Scaffold(backgroundColor: Styles().colors!.background, body:
      Stack(children: <Widget>[
        Image.asset("images/login-header.png", fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true, ),
        SafeArea(child:
          Column(children:[
            Expanded(child:
              SingleChildScrollView(child:
                Padding(padding: EdgeInsets.only(left: 18, right: 18, top: (148 + 24).toDouble(), bottom: 24), child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Semantics(
                      header: true,
                      child: Padding(padding: EdgeInsets.symmetric(horizontal: 36), child:
                        Text(Localization().getStringEx('panel.onboarding2.phone_or_email.title.text', 'Login by phone or email')!, textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 36, color: Styles().colors!.fillColorPrimary))
                    )),
                    Container(height: 24,),
                    Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 32), child:
                      Text(Localization().getStringEx("panel.onboarding2.phone_or_email.description", "Please enter your phone number and we will send you a verification code. Or, you can enter your email address to sign in by email.")!, textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 18, color: Styles().colors!.fillColorPrimary)),
                    ),
                    Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 3), child:
                      Text(Localization().getStringEx("panel.onboarding2.phone_or_email.phone_or_email.text", "Phone number or email address:")!, textAlign: TextAlign.left, style: TextStyle(fontSize: 16, color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold),),
                    ),
                    Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 12), child:
                      Semantics(
                        label: Localization().getStringEx("panel.onboarding2.phone_or_email.phone_or_email.text", "Phone number or email address:"),
                        hint: Localization().getStringEx("panel.onboarding2.phone_or_email.phone_or_email.hint", ""),
                        textField: true,
                        excludeSemantics: true,
                        value: _phoneOrEmailController!.text,
                        child: Container(
                          color: Styles().colors!.white,
                          child: TextField(
                            controller: _phoneOrEmailController,
                            autofocus: false,
                            autocorrect: false,
                            onSubmitted: (_) => _clearErrorMsg,
                            cursorColor: Styles().colors!.textBackground,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textBackground),
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0, style: BorderStyle.solid),),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0),),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Visibility(visible: AppString.isStringNotEmpty(_validationErrorMsg), child:
                      Padding(key: _validationErrorKey, padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), child:
                        Text(AppString.getDefaultEmptyString(value: _validationErrorMsg ?? '')!, style: TextStyle(color: Colors.red, fontSize: 16, fontFamily: Styles().fontFamilies!.bold),),
                      ),
                    ),
                  ],),
                ),
              ),
            ),
            
            Padding(padding: EdgeInsets.only(left: 24, right: 24, bottom: 8), child:
              ScalableRoundedButton(
                label: Localization().getStringEx("panel.onboarding2.phone_or_email.next.text", "Next"),
                hint: Localization().getStringEx("panel.onboarding2.phone_or_email.next.hint", ""),
                borderColor: Styles().colors!.fillColorSecondary,
                backgroundColor: Styles().colors!.background,
                textColor: Styles().colors!.fillColorPrimary,
                onTap: () => _onTapNext()
              ),
            ),
          ]),
        ),
        OnboardingBackButton(padding: backButtonInsets, onTap: () { Analytics.instance.logSelect(target: "Back"); Navigator.pop(context); }),
        Visibility(visible: _isLoading, child:
          Center(child:
            CircularProgressIndicator(),
          ),
        ),
      ],),


    );
  }

  void _onTapNext() {
    Analytics.instance.logSelect(target: "Next");

    if (_isLoading != true) {
      _clearErrorMsg();

      String phoneOrEmailValue = _phoneOrEmailController!.text;
      String? phone = _validatePhoneNumber(phoneOrEmailValue);
      String? email = AppString.isEmailValid(phoneOrEmailValue) ? phoneOrEmailValue : null;

      if (AppString.isStringNotEmpty(phone)) {
        _loginByPhone(phone);
      }
      else if (AppString.isStringNotEmpty(email)) {
        _loginByEmail(email);
      }
      else {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.phone_or_email.validation.text", "Please enter your phone number or email address."));
      }
    }
  }


  void _loginByPhone(String? phoneNumber) {
    setState(() { _isLoading = true; });

    Auth2().authenticateWithPhone(phoneNumber).then((success) {
      if (mounted) {
        setState(() { _isLoading = false; });
        _onPhoneInitiated(phoneNumber, success);
      }
    });
  }

  void _onPhoneInitiated(String? phoneNumber, bool success) {
    if (!success) {
      setErrorMsg(Localization().getStringEx("panel.onboarding2.phone_or_email.phone.failed", "Failed to send phone verification code."));
    }
    else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => OnboardingLoginPhoneConfirmPanel(phoneNumber: phoneNumber, onboardingContext: widget.onboardingContext)));
    }
  }

  void _loginByEmail(String? email) {
    setState(() { _isLoading = true; });
    
    Auth2().checkEmailAccountState(email).then((Auth2EmailAccountState? state) {
      if (mounted) {
        setState(() { _isLoading = false; });
        if (state != null) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2LoginEmailPanel(email: email, state: state, onboardingContext: widget.onboardingContext)));
        }
        else {
          setErrorMsg(Localization().getStringEx("panel.onboarding2.phone_or_email.email.failed", "Failed to verify email address."));
        }
      }
    });
  }

  void setErrorMsg(String? msg) {
    setState(() {
      _validationErrorMsg = msg;
    });

    if (AppString.isStringNotEmpty(msg)) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        if (_validationErrorKey.currentContext != null) {
          Scrollable.ensureVisible(_validationErrorKey.currentContext!, duration: Duration(milliseconds: 300)).then((_) {
          });
        }
      });
    }
  }

  void _clearErrorMsg() {
    setState(() {
      _validationErrorMsg = null;
    });
  }

  static String? _validatePhoneNumber(String? phoneNumber) {
    if (kReleaseMode) {
      if (AppString.isUsPhoneValid(phoneNumber)) {
        phoneNumber = AppString.constructUsPhone(phoneNumber);
        if (AppString.isUsPhoneValid(phoneNumber)) {
          return phoneNumber;
        }
      }
    }
    else {
      if (AppString.isPhoneValid(phoneNumber)) {
        return phoneNumber;
      }
    }
    return null;
  }
}
