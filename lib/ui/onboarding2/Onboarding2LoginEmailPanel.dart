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

class Onboarding2LoginEmailPanel extends StatefulWidget with OnboardingPanel {

  final String? email;
  final Auth2AccountState? state;
  final Map<String, dynamic>? onboardingContext;

  Onboarding2LoginEmailPanel({this.email, this.state, this.onboardingContext});

  @override
  _Onboarding2LoginEmailPanelState createState() => _Onboarding2LoginEmailPanelState();
}

class _Onboarding2LoginEmailPanelState extends State<Onboarding2LoginEmailPanel> implements Onboarding2ProgressableState {

  static final Color _successColor = Colors.green.shade800;
  static final Color _errorColor = Colors.red.shade700;
  static final Color? _messageColor = Styles().colors.fillColorPrimary;
  
  TextEditingController _emailController = TextEditingController();
  FocusNode _emailFocusNode = FocusNode();
  TextEditingController _passwordController = TextEditingController();
  FocusNode _passwordFocusNode = FocusNode();
  TextEditingController _confirmPasswordController = TextEditingController();
  FocusNode _confirmPasswordFocusNode = FocusNode();
  
  String? _validationErrorText;
  Color? _validationErrorColor;
  GlobalKey _validationErrorKey = GlobalKey();

  Auth2AccountState? _state;
  bool _isLoading = false;
  bool _showingPassword = false;
  bool _link = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email!;
    _state = widget.state;
    _link = widget.onboardingContext?["link"] ?? false;
    if (_state == Auth2AccountState.unverified) {
      _validationErrorText = Localization().getStringEx("panel.onboarding2.email.sign_up.succeeded.text", "A verification email has been sent to your email address. To activate your account you need to confirm it. Then you will be able to login with your new credential.");
      _validationErrorColor = _messageColor;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordController.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = (_state == Auth2AccountState.nonExistent) ?
      _link ? Localization().getStringEx('panel.onboarding2.email.link.title.text', 'Add Your Email Address') :
      Localization().getStringEx('panel.onboarding2.email.sign_up.title.text', 'Sign Up with Email') :
      Localization().getStringEx('panel.onboarding2.email.sign_in.title.text', 'Sign In with Email');

    String description = (_state == Auth2AccountState.nonExistent) ?
      _link ? Localization().getStringEx('panel.onboarding2.email.link.description.text', 'Please enter a password to add your email address.') :
      Localization().getStringEx('panel.onboarding2.email.sign_up.description.text', 'Please enter a password to create a new account for your email.') :
      Localization().getStringEx('panel.onboarding2.email.sign_in.description.text', 'Please enter your password to sign in with your email.');

    String showPassword = (_state == Auth2AccountState.nonExistent) ?
      Localization().getStringEx("panel.onboarding2.email.label.show_passwords.text", "Show Passwords") :
      Localization().getStringEx("panel.onboarding2.email.label.show_password.text", "Show Password");

    String buttonTitle = (_state == Auth2AccountState.nonExistent) ?
      _link ? Localization().getStringEx('panel.onboarding2.email.button.link.text', 'Add') :
      Localization().getStringEx('panel.onboarding2.email.button.sign_up.text', 'Sign Up') :
      Localization().getStringEx('panel.onboarding2.email.button.sign_in.text', 'Sign In');

    String buttonHint = (_state == Auth2AccountState.nonExistent) ?
      _link ? Localization().getStringEx('panel.onboarding2.email.button.link.hint', '') :
      Localization().getStringEx('panel.onboarding2.email.button.sign_up.hint', '') :
      Localization().getStringEx('panel.onboarding2.email.button.sign_in.hint', '');

    EdgeInsetsGeometry backButtonInsets = EdgeInsets.only(left: 10, top: 20 + MediaQuery.of(context).padding.top, right: 20, bottom: 20);

    return Scaffold(backgroundColor: Styles().colors.background, body:
      Stack(children: <Widget>[
        Styles().images.getImage("header-login", fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true) ?? Container(),
        SafeArea(child:
          Column(children:[
            Expanded(child:
              SingleChildScrollView(child:
                Padding(padding: EdgeInsets.only(left: 18, right: 18, top: (148 + 24).toDouble(), bottom: 24), child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Padding(padding: EdgeInsets.symmetric(horizontal: 36), child:
                      Semantics( header: true,
                        child: Text(title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.onboarding2.login_email.heading.title"))),
                    ),
                    Container(height: 24,),
                    Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 32), child:
                      Text(description, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.description.medium")),
                    ),
                    Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 3), child:
                      Text(Localization().getStringEx("panel.onboarding2.email.label.email.text", "Email Address:"), textAlign: TextAlign.left, style: Styles().textStyles.getTextStyle("widget.detail.regular.fat"),),
                    ),
                    Padding(padding: EdgeInsets.only(left: 12, right: 12), child:
                      Semantics(
                        label: Localization().getStringEx("panel.onboarding2.email.label.email.text", "Email Address:"),
                        hint: Localization().getStringEx("panel.onboarding2.email.label.email.hint", ""),
                        textField: true,
                        excludeSemantics: true,
                        value: _emailController.text,
                        child: Container(
                          color: Styles().colors.background,
                          child: TextField(
                            enabled: false,
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            autofocus: false,
                            autocorrect: false,
                            style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
                            decoration: InputDecoration(
                              disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0, style: BorderStyle.solid),),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0, style: BorderStyle.solid),),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0),),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 3), child:
                      Text(Localization().getStringEx("panel.onboarding2.email.label.password.text", "Password:"), textAlign: TextAlign.left, style: Styles().textStyles.getTextStyle("widget.detail.regular.fat"),),
                    ),
                    Padding(padding: EdgeInsets.only(left: 12, right: 12), child:
                      Semantics(
                        label: Localization().getStringEx("panel.onboarding2.email.label.password.text", "Password:"),
                        hint: Localization().getStringEx("panel.onboarding2.email.label.password.hint", ""),
                        textField: true,
                        excludeSemantics: true,
                        value: _passwordController.text,
                        child: Container(
                          color: Styles().colors.surface,
                          child: TextField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            autofocus: false,
                            autocorrect: false,
                            obscureText: !_showingPassword,
                            onSubmitted: (_) => _clearErrorMsg,
                            cursorColor: Styles().colors.textDark,
                            keyboardType: TextInputType.text,
                            style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0, style: BorderStyle.solid),),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0),),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Visibility(visible: (_state == Auth2AccountState.nonExistent), child:
                      Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 3), child:
                        Text(Localization().getStringEx("panel.onboarding2.email.label.confirm_password.text", "Confirm Password:"), textAlign: TextAlign.left, style: Styles().textStyles.getTextStyle("widget.detail.regular.fat"),),
                      ),
                    ),
                    Visibility(visible: (_state == Auth2AccountState.nonExistent), child:
                      Padding(padding: EdgeInsets.only(left: 12, right: 12), child:
                        Semantics(
                          label: Localization().getStringEx("panel.onboarding2.email.label.confirm_password.text", "Confirm Password:"),
                          hint: Localization().getStringEx("panel.onboarding2.email.label.confirm_password.hint", ""),
                          textField: true,
                          excludeSemantics: true,
                          value: _confirmPasswordController.text,
                          child: Container(
                            color: Styles().colors.surface,
                            child: TextField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              autofocus: false,
                              autocorrect: false,
                              obscureText: !_showingPassword,
                              onSubmitted: (_) => _clearErrorMsg,
                              cursorColor: Styles().colors.textDark,
                              keyboardType: TextInputType.text,
                              style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0, style: BorderStyle.solid),),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0),),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Row(children: [
                      Expanded(child:
                        AppSemantics.buildCheckBoxSemantics( selected: _showingPassword, title: showPassword,
                          child: InkWell(onTap: () => _onTapShowPassword(), child:
                            Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 12), child:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Styles().images.getImage(_showingPassword ? 'check-circle-filled' : 'check-circle-outline-gray', excludeFromSemantics: true) ?? Container(),
                                Container(width: 6),
                                Text(showPassword, textAlign: TextAlign.left, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),),
                              ],)
                            ),
                          ),
                        )
                      ),
                      Visibility(visible: (_state != Auth2AccountState.nonExistent), child:
                        Expanded(child:
                          Padding(padding: EdgeInsets.only(left: 12), child:
                            InkWell(onTap: () => (_state == Auth2AccountState.unverified) ? _onTapResendEmail() : _onTapForgotPassword(), child:
                              Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 12), child:
                                Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
                                  (_state == Auth2AccountState.unverified) ?
                                    Text(Localization().getStringEx("panel.onboarding2.email.label.resend_email.text", "Resend Verification"), textAlign: TextAlign.right, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.underline")) :
                                    Text(Localization().getStringEx("panel.onboarding2.email.label.forgot_password.text", "Forgot Password?"), textAlign: TextAlign.right, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.underline")),
                                ],)
                              ),
                            ),
                          ),
                        ),
                      ),

                    ],),

                    Visibility(visible: StringUtils.isNotEmpty(_validationErrorText), child:
                      Padding(key:_validationErrorKey, padding: EdgeInsets.only(left: 12, right: 12, bottom: 12), child:
                        Text(StringUtils.ensureNotEmpty(_validationErrorText ?? ''), style: _validationErrorColor != null ? Styles().textStyles.getTextStyle("panel.settings.login.validation.text")?.copyWith(color: _validationErrorColor)  : Styles().textStyles.getTextStyle("panel.settings.login.validation.text"),),
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
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                borderColor: Styles().colors.fillColorSecondary,
                backgroundColor: Styles().colors.background,
                onTap: () => _onTapLogin()
              ),
            ),
            Visibility(
              visible: _link,
              child: Padding(padding: EdgeInsets.only(left: 24, right: 24, bottom: 8), child:
              RoundedButton(
                  label: Localization().getStringEx("panel.onboarding2.email.button.link.cancel.label", "Cancel"),
                  hint: Localization().getStringEx("panel.onboarding2.email.button.link.cancel.hint", ""),
                  textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                  borderColor: Styles().colors.fillColorSecondary,
                  backgroundColor: Styles().colors.background,
                  onTap: () => _onTapCancel())
              ),
            )
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

  void _onTapShowPassword() {
    setState(() {
      _showingPassword = !_showingPassword;
      AppSemantics.announceCheckBoxStateChange(context, _showingPassword, "Show Password");
    });
  }

  void _onTapForgotPassword() {
    Analytics().logSelect(target: "Forgot Password");

    if (_isLoading != true) {
      _clearErrorMsg();

      setState(() { _isLoading = true; });

      Auth2().resetPassword(widget.email).then((result) {
        if (mounted) {
          setState(() { _isLoading = false; });
          
          if (result == Auth2ForgotPasswordResult.succeeded) {
            _emailFocusNode.unfocus();
            _passwordFocusNode.unfocus();
            _confirmPasswordFocusNode.unfocus();
            _passwordController.text = '';
            setErrorMsg(Localization().getStringEx("panel.onboarding2.email.forgot_password.succeeded.text", "A password reset link had been sent to your email address. Please reset your password and then try to login."), color: _successColor);
            setState(() {
              _showingPassword = false;
            });
          } else if (result == Auth2ForgotPasswordResult.failedActivationExpired) {
            setErrorMsg(Localization().getStringEx("panel.onboarding2.email.forgot_password.failed.activation_expired.text", "Your activation link has already expired. A verification email has been resent to your email address. Please confirm it in order to activate your account."));
          } else if (result == Auth2ForgotPasswordResult.failedNotActivated) {
            setErrorMsg(Localization().getStringEx("panel.onboarding2.email.forgot_password.failed.not_activated.text", "Your account is not activated yet. Please confirm the email sent to your email address."));
          } else {
            setErrorMsg(Localization().getStringEx("panel.onboarding2.email.forgot_password.failed.text", "Failed to send password reset email. An unexpected error occurred."));
          }
        }
      });
    }
  }

  void _onTapResendEmail() {
    Analytics().logSelect(target: "Resend Email");

    if (_isLoading != true) {
      _clearErrorMsg();

      setState(() { _isLoading = true; });

      Auth2().resendIdentifierVerification(widget.email).then((bool result) {

        if (mounted) {
          setState(() { _isLoading = false; });
          
          if (result == true) {
            _emailFocusNode.unfocus();
            _passwordFocusNode.unfocus();
            _confirmPasswordFocusNode.unfocus();
            setErrorMsg(Localization().getStringEx("panel.onboarding2.email.resend_email.succeeded.text", "Verification email has been resent."), color: _successColor);
            setState(() {
              _showingPassword = false;
            });
          }
          else {
            setErrorMsg(Localization().getStringEx("panel.onboarding2.email.resend_email.failed.text", "Failed to resend verification email."));
          }
        }
      });
    }
  }

  void _onTapLogin() {
    if (_state == Auth2AccountState.nonExistent) {
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

      String password = _passwordController.text;
      String confirmPassword = _confirmPasswordController.text;

      String strengthRegEx = r'^(?=(.*[a-z]){1,})(?=(.*[A-Z]){1,})(?=(.*[0-9]){1,})(?=(.*[!@#$%^&*()\-__+.]){1,}).{8,}$';
      if (password.isEmpty) {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.email.validation.password_empty.text", "Please enter your password."));
      }
      else if (!RegExp(strengthRegEx).hasMatch(password)) {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.email.validation.password_weak.text", "Password must be at least 8 characters long and must contain a lowercase letter, uppercase letter, number, and a special character."));
      }
      else if (password != confirmPassword) {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.email.validation.passwords_dont_match.text", "Passwords do not match."));
      }
      else {
        setState(() { _isLoading = true; });

        if (!_link) {
          Auth2().signUpWithPassword(widget.email, password).then((Auth2PasswordSignUpResult result) {
            _trySignUpCallback(result);
          } );
        } else {
          Auth2().linkAccountIdentifier(widget.email, Auth2Identifier.typeEmail).then((Auth2LinkResult result) {
            _trySignUpCallback(auth2PasswordSignUpResultFromAuth2LinkResult(result));
          });
        }
      }
    }
  }

  void _trySignUpCallback(Auth2PasswordSignUpResult result) {
    if (mounted) {
      setState(() { _isLoading = false; });

      if (result == Auth2PasswordSignUpResult.succeeded) {
        _emailFocusNode.unfocus();
        _passwordFocusNode.unfocus();
        _confirmPasswordFocusNode.unfocus();
        setState(() {
          _state = Auth2AccountState.unverified;
          _showingPassword = false;
        });
        setErrorMsg(Localization().getStringEx("panel.onboarding2.email.sign_up.succeeded.text", "A verification email has been sent to your email address. To activate your account you need to confirm it. Then you will be able to login with your new credential."), color: _successColor);
      }
      else if (result == Auth2PasswordSignUpResult.failedAccountExist) {
        setState(() {
          _state = Auth2AccountState.unverified;
          _showingPassword = false;
        });
        setErrorMsg(Localization().getStringEx("panel.onboarding2.email.sign_up.failed.account_exists.text", "Sign up failed. An existing account is already using this email address."));
      }
      else /*if (result == Auth2PasswordSignUpResult.failed)*/ {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.email.sign_up.failed.text", "Sign up failed. An unexpected error occurred."));
      }
    }
  }

  void _trySignIn() {
    Analytics().logSelect(target: "Sign In");

    if (_isLoading != true) {
      _clearErrorMsg();

      String password = _passwordController.text;

      if (password.isEmpty) {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.email.validation.password_empty.text", "Please enter your password."));
      }
      else {
        setState(() { _isLoading = true; });

        if (!_link) {
          Auth2().authenticateWithPassword(widget.email, password).then((Auth2PasswordSignInResult result) {
            _trySignInCallback(result);
          });
        } else {
          Auth2().linkAccountIdentifier(widget.email, Auth2Identifier.typeEmail).then((Auth2LinkResult result) {
            _trySignInCallback(auth2PasswordSignInResultFromAuth2LinkResult(result));
          });
        }
      }
    }
  }
  
  void _trySignInCallback(Auth2PasswordSignInResult result) {
    if (mounted) {
      setState(() { _isLoading = false; });
      
      if (result == Auth2PasswordSignInResult.failed) {
        setErrorMsg(Localization().getStringEx("panel.onboarding2.email.sign_in.failed.text", "Sign in failed. An unexpected error occurred."));
      }
      else if (result == Auth2PasswordSignInResult.failedNotActivated) {
        setState(() {
          _state = Auth2AccountState.unverified;
        });
        setErrorMsg(Localization().getStringEx("panel.onboarding2.email.sign_in.failed.not_activated.text", "Your account is not activated yet. Please confirm the email sent to your email address."));
      }
      else if (result == Auth2PasswordSignInResult.failedActivationExpired) {
        setState(() {
          _state = Auth2AccountState.unverified;
        });
        setErrorMsg(Localization().getStringEx("panel.onboarding2.email.sign_in.failed.activation_expired.text", "Your activation link has already expired. Please resend verification email again and confirm it in order to activate your account."));
      }
      else if (result == Auth2PasswordSignInResult.failedInvalid) {
        setState(() {
          _state = Auth2AccountState.verified;
        });
        setErrorMsg(Localization().getStringEx("panel.onboarding2.email.sign_in.failed.invalid.text", "Incorrect password."));
      }
      else {
        _onContinue();
      }
    }
  }

  void _onTapCancel() {
    setState(() { _isLoading = true; });

    Auth2Identifier? accountIdentifier = Auth2().account?.getIdentifier(widget.email, Auth2Identifier.typeEmail);
    if (accountIdentifier != null) {
      Auth2().unlinkAccountIdentifier(accountIdentifier.id).then((success) {
        if(mounted) {
          setState(() {
            _isLoading = false;
          });
          if (!success) {
            setState(() {
              setErrorMsg(Localization().getStringEx("panel.onboarding2.email.link.cancel.text", "Failed to remove email address from your account."));
            });
          }
          else {
            _onContinue();
          }
        }
      });
      return;
    }

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
