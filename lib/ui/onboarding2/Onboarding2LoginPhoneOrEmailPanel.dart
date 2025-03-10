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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Onboarding2LoginPhoneOrEmailPanel extends StatefulWidget with Onboarding2Panel {

  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  Onboarding2LoginPhoneOrEmailPanel({ this.onboardingCode = '', this.onboardingContext }) :
    super(key: GlobalKey<_Onboarding2LoginPhoneOrEmailPanelState>());

  GlobalKey<_Onboarding2LoginPhoneOrEmailPanelState>? get globalKey => (super.key is GlobalKey<_Onboarding2LoginPhoneOrEmailPanelState>) ?
    (super.key as GlobalKey<_Onboarding2LoginPhoneOrEmailPanelState>) : null;

  @override
  bool get onboardingProgress => (globalKey?.currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => globalKey?.currentState?.onboardingProgress = value;
  @override
  Future<bool> isOnboardingEnabled() async => onboardingContext?['login'] == true;

  @override
  _Onboarding2LoginPhoneOrEmailPanelState createState() => _Onboarding2LoginPhoneOrEmailPanelState();
}

class _Onboarding2LoginPhoneOrEmailPanelState extends State<Onboarding2LoginPhoneOrEmailPanel> {
  TextEditingController? _phoneOrEmailController;
  
  String? _validationErrorMsg;
  String? _validationErrorDetails;
  GlobalKey _validationErrorKey = GlobalKey();

  bool _isLoading = false;
  _LoginMode _loginMode = _LoginMode.both;
  bool _link = false;
  String? _identifier;

  bool _onboardingProgress = false;

  @override
  void initState() {
    super.initState();
    _phoneOrEmailController = TextEditingController();
    _link = widget.onboardingContext?["link"] ?? false;
    _identifier = widget.onboardingContext?["identifier"];
    if (_identifier != null) {
      _phoneOrEmailController!.text = _identifier!;
    }

    String? panelMode = widget.onboardingContext?["mode"];
    if (panelMode == "phone") {
      _loginMode = _LoginMode.phone;
    } else if (panelMode == "email") {
      _loginMode = _LoginMode.email;
    }
  }

  @override
  void dispose() {
    _phoneOrEmailController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    EdgeInsetsGeometry backButtonInsets = EdgeInsets.only(left: 10, top: 20 + MediaQuery.of(context).padding.top, right: 20, bottom: 20);

    String title, description, entryText;
    switch (_loginMode) {
      case _LoginMode.phone : {
        title = Localization().getStringEx('panel.onboarding2.phone_or_email.phone.title.text', 'Add a phone number');
        description = Localization().getStringEx('panel.onboarding2.phone_or_email.phone.description', 'Please enter your phone number and we will send you a verification code.');
        entryText = Localization().getStringEx("panel.onboarding2.phone_or_email.phone_or_email.phone.text", "Phone number:");
        break;
      }
      case _LoginMode.email : {
        title = Localization().getStringEx('panel.onboarding2.phone_or_email.email.title.text', 'Add an email address');
        description = Localization().getStringEx('panel.onboarding2.phone_or_email.email.description', 'Please enter your email address and we will send you a verification email.');
        entryText = Localization().getStringEx("panel.onboarding2.phone_or_email.phone_or_email.email.text", "Email address:");
        break;
      }
      default : {
        title = Localization().getStringEx('panel.onboarding2.phone_or_email.title.text', 'Sign In with Phone or Email');
        description = Localization().getStringEx("panel.onboarding2.phone_or_email.description", "Please enter your phone number and we will send you a verification code. Or, you can enter your email address to sign in by email.");
        entryText = Localization().getStringEx("panel.onboarding2.phone_or_email.phone_or_email.text", "Phone Number or Email Address:");
      }
    }

    return Scaffold(backgroundColor: Styles().colors.background, body:
      Stack(children: <Widget>[
        Styles().images.getImage("header-login", fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true) ?? Container(),
        SafeArea(child:
          Column(children:[
            Expanded(child:
              SingleChildScrollView(child:
                Padding(padding: EdgeInsets.only(left: 18, right: 18, top: (148 + 24).toDouble(), bottom: 24), child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Semantics(
                      header: true,
                      child: Padding(padding: EdgeInsets.symmetric(horizontal: 36), child:
                        Text(title,
                          textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.onboarding2.login_email.heading.title"))
                    )),
                    Container(height: 24,),
                    Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 32), child:
                      Text(description,
                        textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.description.medium")),
                    ),
                    Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 3), child:
                      Text(entryText, textAlign: TextAlign.left, style: Styles().textStyles.getTextStyle("widget.detail.regular.fat")),
                    ),
                    Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 12), child:
                      Semantics(
                        label: entryText,
                        hint: Localization().getStringEx("panel.onboarding2.phone_or_email.phone_or_email.hint", ""),
                        textField: true,
                        excludeSemantics: true,
                        value: _phoneOrEmailController!.text,
                        child: Container(
                          color: _identifier == null ? Styles().colors.surface: Styles().colors.background,
                          child: TextField(
                            controller: _phoneOrEmailController,
                            readOnly: _identifier != null,
                            autofocus: false,
                            autocorrect: false,
                            onSubmitted: (_) => _clearErrorMsg,
                            cursorColor: Styles().colors.textDark,
                            keyboardType: TextInputType.emailAddress,
                            style: Styles().textStyles.getTextStyle("widget.input_field.text.regular"),
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0, style: BorderStyle.solid),),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0),),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Visibility(visible: StringUtils.isNotEmpty(_validationErrorMsg), child:
                      Padding(key: _validationErrorKey, padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), child:
                        Column(
                          children: [
                            Text(StringUtils.ensureNotEmpty(_validationErrorMsg ?? ''), style:  Styles().textStyles.getTextStyle("panel.settings.error.text")),
                            Visibility(visible: StringUtils.isNotEmpty(_validationErrorDetails), child:
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(StringUtils.ensureNotEmpty(_validationErrorDetails ?? ''), style:  Styles().textStyles.getTextStyle("widget.message.small")),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],),
                ),
              ),
            ),
            
            Padding(padding: EdgeInsets.only(left: 24, right: 24, bottom: 8), child:
              RoundedButton(
                label: Localization().getStringEx("panel.onboarding2.phone_or_email.next.text", "Next"),
                hint: Localization().getStringEx("panel.onboarding2.phone_or_email.next.hint", ""),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                borderColor: Styles().colors.fillColorSecondary,
                backgroundColor: Styles().colors.background,
                onTap: () => _onTapNext()
              ),
            ),
          ]),
        ),
        OnboardingBackButton(padding: backButtonInsets, onTap: () { Analytics().logSelect(target: "Back"); Navigator.pop(context); }),
        Visibility(visible: _isLoading, child:
          Center(child:
            CircularProgressIndicator(),
          ),
        ),
      ],),


    );
  }

  void _onTapNext() {
    Analytics().logSelect(target: "Next");

    if (_isLoading != true) {
      _clearErrorMsg();
      String validationText;
      switch (_loginMode) {
        case _LoginMode.phone : {
          validationText = Localization().getStringEx("panel.onboarding2.phone_or_email.phone.validation.text", "Please enter your phone number.");
          break;
        }
        case _LoginMode.email : {
          validationText = Localization().getStringEx("panel.onboarding2.phone_or_email.email.validation.text", "Please enter your email address.");
          break;
        }
        default : {
          validationText = Localization().getStringEx("panel.onboarding2.phone_or_email.validation.text", "Please enter your phone number or email address.");
        }
      }

      String phoneOrEmailValue = _phoneOrEmailController!.text;
      String? phone, email;
      if (_loginMode == _LoginMode.phone || _loginMode == _LoginMode.both) {
        phone = _validatePhoneNumber(phoneOrEmailValue);
      }
      if (_loginMode == _LoginMode.email || _loginMode == _LoginMode.both) {
        email = StringUtils.isEmailValid(phoneOrEmailValue) ? phoneOrEmailValue : null;
      }

      if (StringUtils.isNotEmpty(phone)) {
        _loginByPhone(phone);
      }
      else if (StringUtils.isNotEmpty(email)) {
        _loginByEmail(email);
      }
      else {
        setErrorMsg(validationText);
      }
    }
  }


  void _loginByPhone(String? phoneNumber) {
    setState(() { _isLoading = true; });

    if (!_link) {
      Auth2().authenticateWithCode(phoneNumber).then((Auth2RequestCodeResult result) {
        _onPhoneInitiated(phoneNumber, result);
      } );
    } else if (!Auth2().isPhoneLinked){ // at most one phone number may be linked at a time
      Auth2().linkAccountIdentifier(phoneNumber, Auth2Identifier.typePhone).then((Auth2LinkResult result) {
        _onPhoneInitiated(phoneNumber, auth2RequestCodeResultFromAuth2LinkResult(result));
      });
    } else {
      setErrorMsg(Localization().getStringEx("panel.onboarding2.phone_or_email.phone.linked.text", "You have already added a phone number to your account."));
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _onPhoneInitiated(String? phoneNumber, Auth2RequestCodeResult result) {
    if (mounted) {
      setState(() { _isLoading = false; });

      if (result == Auth2RequestCodeResult.succeeded) {
        // Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2LoginPhoneConfirmPanel(phoneNumber: phoneNumber, onboardingContext: widget.onboardingContext)));
        widget.onboardingContext?['phoneNumber'] = phoneNumber;
        _onboardingNext();
      } else if (result == Auth2RequestCodeResult.failedAccountExist) {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.phone_or_email.phone.failed.exists", "An account is already using this phone number."),
            details: Localization().getStringEx("panel.onboarding2.phone_or_email.phone.failed.exists.details",
                "1. You will need to sign in to the other account with this phone number.\n2. Go to \"Settings\" and press \"Forget all of my information\".\nYou can now use this as an alternate login."));
      } else {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.phone_or_email.phone.failed", "Failed to send phone verification code. An unexpected error has occurred."));
      }
    }

  }

  void _loginByEmail(String? email) {
    setState(() { _isLoading = true; });

    if (_link) {
      Auth2().canLink(email, Auth2Identifier.typeEmail).then((bool? result) {
        if (mounted) {
          setState(() { _isLoading = false; });
          
          if (result == null) {
            setErrorMsg(Localization().getStringEx("panel.onboarding2.phone_or_email.email.failed", "Failed to verify email address."));
          }
          else if (result == false) {
            setErrorMsg(Localization().getStringEx("panel.settings.link.email.label.failed", "An account is already using this email address."),);
          }
          else if (Auth2().isEmailLinked) { // at most one email address may be linked at a time
            setErrorMsg(Localization().getStringEx("panel.settings.link.email.label.linked", "You have already added an email address to your account."));
          }
          else {
            // Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2LoginEmailPanel(email: email, state: Auth2AccountState.nonExistent, onboardingContext: widget.onboardingContext)));
            widget.onboardingContext?['email'] = email;
            widget.onboardingContext?['state'] = Auth2AccountState.nonExistent;
            _onboardingNext();
          }
        }
      });
    } else {
      Auth2().canSignIn(email, Auth2Identifier.typeEmail).then((bool? result) {
        if (mounted) {
          setState(() { _isLoading = false; });
          if (result != null) {
            // Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2LoginEmailPanel(email: email, state: result ? Auth2AccountState.verified : Auth2AccountState.nonExistent, onboardingContext: widget.onboardingContext)));
            widget.onboardingContext?['email'] = email;
            widget.onboardingContext?['state'] = result ? Auth2AccountState.verified : Auth2AccountState.nonExistent;
            _onboardingNext();
          }
          else {
            setErrorMsg(Localization().getStringEx("panel.onboarding2.phone_or_email.email.failed", "Failed to verify email address."));
          }
        }
      });
    }
  }

  void setErrorMsg(String? msg, {String? details}) {
    setState(() {
      _validationErrorMsg = msg;
      _validationErrorDetails = details;
    });

    if (StringUtils.isNotEmpty(msg)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      if (StringUtils.isUsPhoneValid(phoneNumber)) {
        phoneNumber = StringUtils.constructUsPhone(phoneNumber);
        if (StringUtils.isUsPhoneValid(phoneNumber)) {
          return phoneNumber;
        }
      }
    }
    else {
      if (StringUtils.isPhoneValid(phoneNumber)) {
        return phoneNumber;
      }
    }
    return null;
  }

  // Onboarding

  bool get onboardingProgress => _onboardingProgress;
  set onboardingProgress(bool value) {
    setStateIfMounted(() {
      _onboardingProgress = value;
    });
  }

  //void _onboardingBack() => Navigator.of(context).pop();
  void _onboardingNext() => Onboarding2().next(context, widget);
}

enum _LoginMode {phone, email, both}
