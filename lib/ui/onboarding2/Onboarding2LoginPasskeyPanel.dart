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
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/onboarding.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Onboarding2LoginPasskeyPanel extends StatefulWidget with OnboardingPanel {

  final Auth2PasskeyAccountState? state;
  final Map<String, dynamic>? onboardingContext;

  Onboarding2LoginPasskeyPanel({this.state, this.onboardingContext});

  @override
  _Onboarding2LoginPasskeyPanelState createState() => _Onboarding2LoginPasskeyPanelState();
}

class _Onboarding2LoginPasskeyPanelState extends State<Onboarding2LoginPasskeyPanel> implements Onboarding2ProgressableState {

  static final Color _successColor = Colors.green.shade800;
  static final Color _errorColor = Colors.red.shade700;
  static final Color? _messageColor = Styles().colors!.fillColorPrimary;
  
  TextEditingController _usernameController = TextEditingController();
  FocusNode _usernameFocusNode = FocusNode();
  TextEditingController _nameController = TextEditingController();
  FocusNode _nameFocusNode = FocusNode();

  String? _validationErrorText;
  Color? _validationErrorColor;
  GlobalKey _validationErrorKey = GlobalKey();

  Auth2PasskeyAccountState? _state;
  bool _isLoading = false;
  bool _link = false;

  @override
  void initState() {
    super.initState();
    _state = widget.state ?? Auth2PasskeyAccountState.exists;
    _link = widget.onboardingContext?["link"] ?? false;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = (_state == Auth2PasskeyAccountState.nonExistent) ?
      _link ? Localization().getStringEx('panel.onboarding2.passkey.link.title.text', 'Add a Passkey') :
      Localization().getStringEx('panel.onboarding2.passkey.sign_up.title.text', 'Sign Up with Passkey') :
      Localization().getStringEx('panel.onboarding2.passkey.sign_in.title.text', 'Sign In with Passkey');

    String description = (_state == Auth2PasskeyAccountState.nonExistent) ?
      _link ? Localization().getStringEx('panel.onboarding2.passkey.link.description.text', 'Please confirm or enter a username and your fulle name.') :
      Localization().getStringEx('panel.onboarding2.passkey.sign_up.description.text', 'Please enter a username and your full name to sign up.') :
      Localization().getStringEx('panel.onboarding2.passkey.sign_in.description.text', 'Please enter your username to sign in.');

    String buttonTitle = (_state == Auth2PasskeyAccountState.nonExistent) ?
      _link ? Localization().getStringEx('panel.onboarding2.passkey.button.link.text', 'Add') :
      Localization().getStringEx('panel.onboarding2.passkey.button.sign_up.text', 'Sign Up') :
      Localization().getStringEx('panel.onboarding2.passkey.button.sign_in.text', 'Sign In');

    String buttonHint = (_state == Auth2PasskeyAccountState.nonExistent) ?
      _link ? Localization().getStringEx('panel.onboarding2.passkey.button.link.hint', '') :
      Localization().getStringEx('panel.onboarding2.passkey.button.sign_up.hint', '') :
      Localization().getStringEx('panel.onboarding2.passkey.button.sign_in.hint', '');

    EdgeInsetsGeometry backButtonInsets = EdgeInsets.only(left: 10, top: 20 + MediaQuery.of(context).padding.top, right: 20, bottom: 20);

    return Scaffold(backgroundColor: Styles().colors!.background, body:
      Stack(children: <Widget>[
        Column(children:[
          Expanded(child:
            SingleChildScrollView(child:
              Padding(padding: EdgeInsets.only(left: 18, right: 18, bottom: 24), child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Styles().images?.getImage("header-login", fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true) ?? Container(),
                  SizedBox(height: 16,),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 36), child:
                    Semantics( header: true,
                      child: Text(title, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.title.extra_huge.fat"))),
                  ),
                  Container(height: 24,),
                  Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 32), child:
                    Text(description, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.description.medium")),
                  ),
                  Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 3), child:
                    Text(Localization().getStringEx("panel.onboarding2.passkey.label.username.text", "Username:"), textAlign: TextAlign.left, style: Styles().textStyles?.getTextStyle("widget.detail.regular.fat"),),
                  ),
                  Padding(padding: EdgeInsets.only(left: 12, right: 12), child:
                    Semantics(
                      label: Localization().getStringEx("panel.onboarding2.passkey.label.username.text", "Username:"),
                      hint: Localization().getStringEx("panel.onboarding2.passkey.label.username.hint", ""),
                      textField: true,
                      excludeSemantics: true,
                      value: _usernameController.text,
                      child: Container(
                        color: Styles().colors!.surface,
                        child: TextField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          autofocus: false,
                          autocorrect: false,
                          style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),
                          decoration: InputDecoration(
                            disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0, style: BorderStyle.solid),),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0, style: BorderStyle.solid),),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0),),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Visibility(
                    visible: _state == Auth2PasskeyAccountState.nonExistent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 3), child:
                        Text(Localization().getStringEx("panel.onboarding2.passkey.label.name.text", "Full Name:"), textAlign: TextAlign.left, style: Styles().textStyles?.getTextStyle("widget.detail.regular.fat"),),),
                        Padding(padding: EdgeInsets.only(left: 12, right: 12), child:
                          Semantics(
                            label: Localization().getStringEx("panel.onboarding2.passkey.label.name.text", "Full Name:"),
                            hint: Localization().getStringEx("panel.onboarding2.passkey.label.name.hint", ""),
                            textField: true,
                            excludeSemantics: true,
                            value: _nameController.text,
                            child: Container(
                              color: Styles().colors!.surface,
                              child: TextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                autofocus: false,
                                autocorrect: false,
                                onSubmitted: (_) => _clearErrorMsg,
                                cursorColor: Styles().colors!.textBackground,
                                keyboardType: TextInputType.text,
                                textCapitalization: TextCapitalization.words,
                                style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0, style: BorderStyle.solid),),
                                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0),),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(visible: StringUtils.isNotEmpty(_validationErrorText), child:
                    Padding(key:_validationErrorKey, padding: EdgeInsets.only(left: 12, right: 12, bottom: 12), child:
                      Text(StringUtils.ensureNotEmpty(_validationErrorText ?? ''), style: _validationErrorColor != null ? Styles().textStyles?.getTextStyle("panel.settings.login.validation.text")?.copyWith(color: _validationErrorColor)  : Styles().textStyles?.getTextStyle("panel.settings.login.validation.text"),),
                    ),
                  ),
                  Visibility(
                    visible: !_link,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: InkWell(
                          onTap: _onTapSwitchMode,
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                  (_state == Auth2PasskeyAccountState.nonExistent) ? Localization().getStringEx(
                                      "panel.onboarding2.passkey.label.switch_mode.sign_in.text",
                                      "Already have an account? Sign in instead")
                                      : Localization().getStringEx("panel.onboarding2.passkey.label.switch_mode.sign_up.text",
                                      "Don't have an account? Sign up instead"),
                                  textAlign: TextAlign.center,
                                  style: Styles().textStyles?.getTextStyle(
                                      "widget.button.title.medium.underline"))),
                        ),
                      ),
                    ),
                  ),
                ],),
              ),
            ),
          ),

          Padding(padding: EdgeInsets.only(left: 24, right: 24, bottom: 8), child:
            RoundedButton(
              label: buttonTitle,
              hint: buttonHint,
              borderColor: Styles().colors!.fillColorSecondary,
              backgroundColor: Styles().colors!.background,
              textColor: Styles().colors!.fillColorPrimary,
              onTap: () => _onTapLogin()
            ),
          ),
          Visibility(
            visible: _link,
            child: Padding(padding: EdgeInsets.only(left: 24, right: 24, bottom: 8), child:
            RoundedButton(
                label: Localization().getStringEx("panel.onboarding2.passkey.button.link.cancel.label", "Cancel"),
                hint: Localization().getStringEx("panel.onboarding2.passkey.button.link.cancel.hint", ""),
                borderColor: Styles().colors!.fillColorSecondary,
                backgroundColor: Styles().colors!.background,
                textColor: Styles().colors!.fillColorPrimary,
                onTap: () => _onTapCancel())
            ),
          )
        ]),
        OnboardingBackButton(padding: backButtonInsets, onTap: () { Analytics().logSelect(target: "Back"); Navigator.pop(context); }),
        Visibility(visible: _isLoading, child:
          Center(child:
            CircularProgressIndicator(),
          ),
        ),
      ]),
    );
  }

  void _onTapSwitchMode() {
    setState(() {
      if (_state == Auth2PasskeyAccountState.nonExistent) {
        _state = Auth2PasskeyAccountState.exists;
      } else {
        _state = Auth2PasskeyAccountState.nonExistent;
      }
    });
  }

  void _onTapLogin() {
    if (_state == Auth2PasskeyAccountState.nonExistent) {
      _trySignUp();
    }
    else {
      _trySignIn();
    }
  }

  void _trySignUp() {
    Analytics().logSelect(target: "Sign Up");

    if (_isLoading != true) {
      _clearErrorMsg();

      String username = _usernameController.text.trim();
      if (username.isEmpty) {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.passkey.validation.username_empty.text", "Please enter a username."));
      }

      String name = _nameController.text.trim();
      if (name.isEmpty) {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.passkey.validation.name_empty.text", "Please enter your full name."));
      }

      else {
        setState(() { _isLoading = true; });
        if (!_link) {
          Auth2().signUpWithPasskey(username, name).then((Auth2PasskeySignUpResult result) {
            _trySignUpCallback(result);
          });
        } else {
          // Map<String, dynamic> creds = {
          //   "username": username,
          // };
          // Map<String, dynamic> params = {
          //   "sign_up": true,
          //   "display_name": name,
          // };
          // Auth2().linkAccountAuthType(Auth2LoginType.passkey, creds, params).then((Auth2LinkResult result) {
          //   _trySignUpCallback(auth2PasskeySignUpResultFromAuth2LinkResult(result));
          // });
        }
      }
    }
  }

  void _trySignUpCallback(Auth2PasskeySignUpResult result) {
    if (mounted) {
      setState(() { _isLoading = false; });

      if (result == Auth2PasskeySignUpResult.succeeded) {
        _onContinue();
      }
      // else if (result == Auth2PasskeySignUpResult.failed) {
      //   //TODO: Handle existing username correctly
      //   setErrorMsg(Localization().getStringEx("panel.onboarding2.passkey.sign_up.failed.account_exists.text", "Sign up failed. An existing account is already using this username."));
      // }
      else /*if (result == Auth2EmailSignUpResult.failed)*/ {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.passkey.sign_up.failed.text", "Sign up failed. An unexpected error occurred."));
      }
    }
  }

  void _trySignIn() {
    Analytics().logSelect(target: "Sign In");

    if (_isLoading != true) {
      _clearErrorMsg();

      String username = _usernameController.text.trim();

      if (username.isEmpty) {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.passkey.validation.username_empty.text", "Please enter your username."));
      }
      else {
        setState(() { _isLoading = true; });

        if (!_link) {
          Auth2().authenticateWithPasskey(username).then((Auth2PasskeySignInResult result) {
            _trySignInCallback(result);
          });
        }
        else {
          // Map<String, dynamic> creds = {
          //   "username": username,
          // };
          // Map<String, dynamic> params = {};
          // Auth2().linkAccountAuthType(Auth2LoginType.passkey, creds, params).then((Auth2LinkResult result) {
          //   _trySignInCallback(auth2PasskeySignInResultFromAuth2LinkResult(result));
          // });
        }
      }
    }
  }
  
  void _trySignInCallback(Auth2PasskeySignInResult result) {
    if (mounted) {
      setState(() { _isLoading = false; });
      if (result == Auth2PasskeySignInResult.failed) {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.passkey.sign_in.failed.text", "Sign in failed. An unexpected error occurred."));
      }
      else if (result == Auth2PasskeySignInResult.failedNotSupported) {
        setState(() {
          _state = Auth2PasskeyAccountState.exists;
        });
        setErrorMsg(Localization().getStringEx("panel.onboarding2.passkey.sign_in.failed.not_supported.text", "Passkeys are not supported by your device."));
      }
      else if (result == Auth2PasskeySignInResult.failedNotFound) {
        setState(() {
          _state = Auth2PasskeyAccountState.nonExistent;
        });
        setErrorMsg(Localization().getStringEx("panel.onboarding2.passkey.sign_in.failed.not_found.text", "No account was found for this username. Try signing up instead."));
      }
      else if (result == Auth2PasskeySignInResult.failed) {
        setState(() {
          _state = Auth2PasskeyAccountState.exists;
        });
        setErrorMsg(Localization().getStringEx("panel.onboarding2.passkey.sign_in.failed.invalid.text", "Incorrect passkey."));
      }
      else {
        _onContinue();
      }
    }
  }

  void _onTapCancel() {
    setState(() { _isLoading = true; });

    // for (Auth2Type authType in Auth2().linkedEmail) {
    //   if (authType.identifier == widget.email) {
    //     Auth2().unlinkAccountAuthType(Auth2LoginType.email, widget.email!).then((success) {
    //       if(mounted) {
    //         setState(() {
    //           _isLoading = false;
    //         });
    //         if (!success) {
    //           setState(() {
    //             setErrorMsg(Localization().getStringEx("panel.onboarding2.passkey.link.cancel.text", "Failed to remove email address from your account."));
    //           });
    //         }
    //         else {
    //           _onContinue();
    //         }
    //       }
    //     });
    //     return;
    //   }
    // }

    _onContinue();
  }

  void setErrorMsg(String? msg, { Color? color}) {
    setState(() {
      _validationErrorText = msg;
      _validationErrorColor = color ?? _errorColor;
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
      _validationErrorText = null;
    });
  }

  void _onContinue() {
    if (widget.onboardingContext == null) {
      Navigator.pop(context);
    }

    // Hook this panels to Onboarding2
    Function? onContinue = (widget.onboardingContext != null) ? widget.onboardingContext!["onContinueAction"] : null;
    Function? onContinueEx = (widget.onboardingContext != null) ? widget.onboardingContext!["onContinueActionEx"] : null; 
    if (onContinueEx != null) {
      onContinueEx(this);
    }
    else if (onContinue != null) {
      onContinue();
    }
    else {
      Onboarding().next(context, widget);
    }
  }

  // Onboarding2ProgressableState

  @override
  bool get onboarding2Progress => _isLoading;
  
  @override
  set onboarding2Progress(bool progress) {
    if (mounted) {
      setState(() {
        _isLoading = progress;
      });
    }
  }
}
