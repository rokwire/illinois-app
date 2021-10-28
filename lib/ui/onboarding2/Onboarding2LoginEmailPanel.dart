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
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class Onboarding2LoginEmailPanel extends StatefulWidget with OnboardingPanel {

  final bool signUp;
  final String email;
  final Map<String, dynamic> onboardingContext;

  Onboarding2LoginEmailPanel({this.email, this.signUp, this.onboardingContext});

  @override
  _Onboarding2LoginEmailPanelState createState() => _Onboarding2LoginEmailPanelState();
}

class _Onboarding2LoginEmailPanelState extends State<Onboarding2LoginEmailPanel> {
  
  TextEditingController _emailController;
  TextEditingController _passwordController;
  TextEditingController _confirmPasswordController;
  
  String _validationErrorMsg;
  GlobalKey _validationErrorKey = GlobalKey();

  bool _isLoading = false;
  bool _showingPassword = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = (widget.signUp == true) ?
      Localization().getStringEx('panel.onboarding2.email.sign_up.title.text', 'Sign up with email') :
      Localization().getStringEx('panel.onboarding2.email.sign_in.title.text', 'Sign in with email');

    String description = (widget.signUp == true) ?
      Localization().getStringEx('panel.onboarding2.email.sign_up.description.text', 'Please enter a password to create a new account for your email.') :
      Localization().getStringEx('panel.onboarding2.email.sign_in.description.text', 'Please enter your password to sign in with your email.');

    String buttonTitle = (widget.signUp == true) ?
      Localization().getStringEx('panel.onboarding2.email.button.sign_up.text', 'Sign Up') :
      Localization().getStringEx('panel.onboarding2.email.button.sign_in.text', 'Sign In');

    String buttonHint = (widget.signUp == true) ?
      Localization().getStringEx('panel.onboarding2.email.button.sign_up.hint', '') :
      Localization().getStringEx('panel.onboarding2.email.button.sign_in.hint', '');

    EdgeInsetsGeometry backButtonInsets = EdgeInsets.only(left: 10, top: 20 + MediaQuery.of(context).padding.top, right: 20, bottom: 20);

    return Scaffold(backgroundColor: Styles().colors.background, body:
      Stack(children: <Widget>[
        Image.asset("images/login-header.png", fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true, ),
        SafeArea(child:
          Column(children:[
            Expanded(child:
              SingleChildScrollView(child:
                Padding(padding: EdgeInsets.only(left: 18, right: 18, top: (148 + 24).toDouble(), bottom: 24), child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Padding(padding: EdgeInsets.symmetric(horizontal: 36), child:
                      Text(title, textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 36, color: Styles().colors.fillColorPrimary))
                    ),
                    Container(height: 24,),
                    Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 32), child:
                      Text(description, textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 18, color: Styles().colors.fillColorPrimary)),
                    ),

                    Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 3), child:
                      Text(Localization().getStringEx("panel.onboarding2.email.label.email.text", "Email Address:"), textAlign: TextAlign.left, style: TextStyle(fontSize: 16, color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold),),
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
                            autofocus: false,
                            style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies.regular, color: Styles().colors.textBackground),
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
                      Text(Localization().getStringEx("panel.onboarding2.email.label.password.text", "Password:"), textAlign: TextAlign.left, style: TextStyle(fontSize: 16, color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold),),
                    ),
                    Padding(padding: EdgeInsets.only(left: 12, right: 12), child:
                      Semantics(
                        label: Localization().getStringEx("panel.onboarding2.email.label.password.text", "Password:"),
                        hint: Localization().getStringEx("panel.onboarding2.email.label.password.hint", ""),
                        textField: true,
                        excludeSemantics: true,
                        value: _passwordController.text,
                        child: Container(
                          color: Styles().colors.white,
                          child: TextField(
                            controller: _passwordController,
                            autofocus: true,
                            obscureText: !_showingPassword,
                            onSubmitted: (_) => _clearErrorMsg,
                            cursorColor: Styles().colors.textBackground,
                            keyboardType: TextInputType.text,
                            style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies.regular, color: Styles().colors.textBackground),
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0, style: BorderStyle.solid),),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0),),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Visibility(visible: (widget.signUp == true), child:
                      Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 3), child:
                        Text(Localization().getStringEx("panel.onboarding2.email.label.confirm_password.text", "Confirm Password:"), textAlign: TextAlign.left, style: TextStyle(fontSize: 16, color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold),),
                      ),
                    ),
                    Visibility(visible: (widget.signUp == true), child:
                      Padding(padding: EdgeInsets.only(left: 12, right: 12), child:
                        Semantics(
                          label: Localization().getStringEx("panel.onboarding2.email.label.confirm_password.text", "Confirm Password:"),
                          hint: Localization().getStringEx("panel.onboarding2.email.label.confirm_password.hint", ""),
                          textField: true,
                          excludeSemantics: true,
                          value: _confirmPasswordController.text,
                          child: Container(
                            color: Styles().colors.white,
                            child: TextField(
                              controller: _confirmPasswordController,
                              autofocus: true,
                              obscureText: !_showingPassword,
                              onSubmitted: (_) => _clearErrorMsg,
                              cursorColor: Styles().colors.textBackground,
                              keyboardType: TextInputType.text,
                              style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies.regular, color: Styles().colors.textBackground),
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0, style: BorderStyle.solid),),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0),),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    InkWell(onTap: () => _onTapShowPassword(), child:
                      Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 12), child:
                        Row(children: [
                          Image.asset(_showingPassword ? 'images/deselected-dark.png' : 'images/deselected.png'),
                          Container(width: 6),
                          Text(Localization().getStringEx("panel.onboarding2.email.label.show_password.text", "Show Password"), textAlign: TextAlign.left, style: TextStyle(fontSize: 16, color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold),),
                        ],)
                      ),
                    ),

                    Visibility(visible: AppString.isStringNotEmpty(_validationErrorMsg), child:
                      Padding(key:_validationErrorKey, padding: EdgeInsets.only(left: 12, right: 12, bottom: 12), child:
                        Text(AppString.getDefaultEmptyString(value: _validationErrorMsg ?? ''), style: TextStyle(color: Colors.red, fontSize: 16, fontFamily: Styles().fontFamilies.bold),),
                      ),
                    ),
                  ],),
                ),
              ),
            ),
            
            Padding(padding: EdgeInsets.only(left: 24, right: 24, bottom: 8), child:
              ScalableRoundedButton(
                label: buttonTitle,
                hint: buttonHint,
                borderColor: Styles().colors.fillColorSecondary,
                backgroundColor: Styles().colors.background,
                textColor: Styles().colors.fillColorPrimary,
                onTap: () => _onTapLogin()
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

  void _onTapShowPassword() {
    setState(() {
      _showingPassword = !_showingPassword;
    });
  }

  void _onTapLogin() {
    Analytics.instance.logSelect(target: (widget.signUp == true) ? "Sign Up" : "Sign In");

    if (_isLoading != true) {
      _clearErrorMsg();

      String password = _passwordController.text;

      String strengthRegEx = kReleaseMode ?
        r'^(?=(.*[a-z]){1,})(?=(.*[A-Z]){1,})(?=(.*[0-9]){1,})(?=(.*[!@#$%^&*()\-__+.]){1,}).{8,}$' :
        r'.';
      if (!RegExp(strengthRegEx).hasMatch(password)) {
        setState(() {
          setErrorMsg(kReleaseMode ?
            Localization().getStringEx("panel.onboarding2.email.validation.passwords_weak.text", "Password must be at least 8 characters long and must contain a lowercase letter, uppercase letter, number, and a special character.") :
            "Password must not be empty.");
        });
      }
      else if ((widget.signUp == true) && (password != _confirmPasswordController.text)) {
        setState(() {
          setErrorMsg(Localization().getStringEx("panel.onboarding2.email.validation.passwords_dont_match.text", "Passwords do not match."));
        });
      }
      else {
        setState(() { _isLoading = true; });

        Auth2().authenticateWithEmail(widget.email, password, signUp: widget.signUp).then((bool result) {
          
          setState(() { _isLoading = false; });
          
          if (result != true) {
            setState(() {
              setErrorMsg((widget.signUp == true) ?
                Localization().getStringEx("panel.onboarding2.email.validation.sign_up.failed.text", "Sign up failed.") :
                Localization().getStringEx("panel.onboarding2.email.validation.sign_in.failed.text", "Sign in failed."));
            });
          }
          else if (widget.onboardingContext != null) {
            Function onSuccess = widget.onboardingContext["onContinueAction"]; // Hook this panels to Onboarding2
            if(onSuccess!=null){
              onSuccess();
            } else {
              Onboarding().next(context, widget);
            }
          }
        });
      }
    }
  }


  void setErrorMsg(String msg) {
    setState(() {
      _validationErrorMsg = msg;
    });

    if (AppString.isStringNotEmpty(msg)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_validationErrorKey.currentContext != null) {
          Scrollable.ensureVisible(_validationErrorKey.currentContext, duration: Duration(milliseconds: 300)).then((_) {
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
}
