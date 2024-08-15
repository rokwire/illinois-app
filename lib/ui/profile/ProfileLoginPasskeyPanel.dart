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
import 'package:neom/service/Config.dart';
import 'package:neom/service/Storage.dart';
import 'package:neom/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:neom/ui/profile/ProfileLoginPhoneOrEmailPanel.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/ui/widgets/SlantedWidget.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/onboarding.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'package:neom/service/Analytics.dart';

class ProfileLoginPasskeyPanel extends StatefulWidget with OnboardingPanel {
  @override
  final Map<String, dynamic>? onboardingContext;

  final bool? link;

  ProfileLoginPasskeyPanel({super.key, this.onboardingContext, this.link});

  @override
  State<StatefulWidget> createState() => _ProfileLoginPasskeyPanelState();

  @override
  bool get onboardingCanDisplay {
    return !Auth2().isPasskeyLinked;
  }
}

enum ResponseType { success, error, message }

class _ProfileLoginPasskeyPanelState extends State<ProfileLoginPasskeyPanel> {
  String? _responseMessage;
  ResponseType _responseType = ResponseType.message;

  Auth2PasskeyAccountState _state = Auth2PasskeyAccountState.exists;

  late bool _link;
  bool _loading = false;

  @override
  void initState() {
    _link = widget.onboardingContext?["link"] ?? widget.link ?? (Auth2().isLoggedIn && !Auth2().isPasskeyLinked);

    if ((Storage().auth2PasskeySaved ?? false) && (widget.onboardingContext?["afterLogout"] != true) && !_link && !kIsWeb) {
      _loading = true;
      Auth2().authenticateWithPasskey().then((result) {
        _loading = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _trySignInCallback(context, result);
        });
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Styles().colors.background,
          body: _link ? _buildPasskeyInfo() : SingleChildScrollView(
            child: Column(children: [
                Semantics(hint: Localization().getStringEx("common.heading.one.hint","Header 1"), header: true, child:
                  Onboarding2TitleWidget()
                ),
              const SizedBox(height: 16),
              _buildContent(context),
            ]),
          )
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        constraints: BoxConstraints(maxWidth: Config().webContentMaxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: kIsWeb ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: <Widget>[
            _buildText(),
            if (StringUtils.isNotEmpty(_responseMessage))
              _buildContentWidget(context),
            _buildPrimaryActionButton(),
            Container(height: 16),
            _buildSignUpButton(),
            // _buildSkipButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildText() {
    String title = '';
    String description = '';
    if (_link) {
      title = Localization().getStringEx('panel.settings.passkey.add.title', 'Add a Passkey');
      // description = Localization().getStringEx('panel.settings.passkey.add.description', 'Add a new passkey on this device to sign in faster next time.');
    } else {
      title = Localization().getStringEx('panel.settings.passkey.sign_in.title.text', 'Sign in to continue.');
      // description = Localization().getStringEx('panel.settings.passkey.sign_in.description.text', 'Sign in with your passkey.');
    }

    return Column(children: [
      Semantics(header: true, label: title, excludeSemantics: true, focused: true,
        child: Text(title, style: Styles().textStyles.getTextStyle('widget.description.medium.light'),)
      ),
      if (description.isNotEmpty)
        const SizedBox(height: 16),
      Text(description, style: Styles().textStyles.getTextStyle('widget.description.medium.light'),)
    ]);
  }

  // Widget _buildSkipButton(BuildContext context) {
  //   return Semantics(button: true,
  //       child: TextButton(
  //           onPressed: () => _onSkip(context),
  //           child: Text(Localization().getStringEx('panel.onboarding.button.not_now.title', 'Not right now'),
  //               style: Styles().textStyles.getTextStyle('widget.item.small.semi_fat'))
  //       )
  //   );
  // }
  //
  // void _onSkip(BuildContext context) {
  //   Analytics().logSelect(target: 'Not right now') ;
  //   if (_link) {
  //     _skip(context);
  //   }
  // }

  Widget _buildPrimaryActionButton() {
    return SlantedWidget(
      color: Styles().colors.fillColorSecondary,
      child: RibbonButton(
        label: _state == Auth2PasskeyAccountState.failed ?
          Localization().getStringEx('panel.settings.passkey.button.sign_in.alternative.text', 'Sign In With Passkey') :
          Localization().getStringEx('panel.settings.passkey.button.sign_in.text', 'Sign In'),
        textAlign: TextAlign.center,
        backgroundColor: Styles().colors.fillColorSecondary,
        textStyle: Styles().textStyles.getTextStyle('widget.button.light.title.large.fat'),
        onTap: () => _primaryButtonAction(context),
        progress: _loading,
        progressColor: Styles().colors.textLight,
        rightIconKey: null,
      ),
    );
  }

  Widget _buildPasskeyInfo() {
    bool linkCrossPlatform = Auth2().isPasskeyLinked && !Auth2().hasPasskeyForPlatform;
    String primaryButtonText = Localization().getStringEx('panel.settings.passkey.add.button.label', 'Add Passkey');
    return Container(
      decoration: BoxDecoration(
        color: Styles().colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 32.0),
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 8.0),
      constraints: BoxConstraints(maxWidth: Config().webContentMaxWidth),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Styles().images.getImage('university-logo-dark-script') ?? Container(),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      linkCrossPlatform ? Localization().getStringEx('', 'CREATE A PASSKEY FOR THIS DEVICE') : Localization().getStringEx('', 'PASSKEYS ARE A BETTER WAY TO SIGN IN'),
                      style: Styles().textStyles.getTextStyle('panel.onboarding2.login_passkey.link.title'),
                    ),
                  ),
                  if (!linkCrossPlatform)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Styles().images.getImage('fingerprint') ?? Container(),
                            ),
                          ),
                          Flexible(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Localization().getStringEx('', 'No need to remember a password'),
                                      style: Styles().textStyles.getTextStyle('widget.heading.large.dark'),
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      Localization().getStringEx('', 'With passkeys, you can use things like your fingerprint or face to login'),
                                      style: Styles().textStyles.getTextStyle('widget.item.tiny.medium'),
                                    ),
                                  ]
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Styles().images.getImage('mobile') ?? Container(),
                          ),
                        ),
                        Flexible(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    linkCrossPlatform ? Localization().getStringEx('', 'Easier login on this device') : Localization().getStringEx('', 'Works on all of your devices'),
                                    style: Styles().textStyles.getTextStyle('widget.heading.large.dark'),
                                  ),
                                  SizedBox(height: 8.0),
                                  Text(
                                    linkCrossPlatform ? Localization().getStringEx('', 'Your new passkey will be available without your other device') : Localization().getStringEx('', 'Passkeys will automatically be available across your synced devices'),
                                    style: Styles().textStyles.getTextStyle('widget.item.tiny.medium'),
                                  ),
                                ]
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  if (!linkCrossPlatform)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Styles().images.getImage('shield-halved') ?? Container(),
                            ),
                          ),
                          Flexible(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Localization().getStringEx('', 'Keeps your account safer'),
                                      style: Styles().textStyles.getTextStyle('widget.heading.large.dark'),
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      Localization().getStringEx('', 'Passkeys offer state-of-the-art phishing resistance'),
                                      style: Styles().textStyles.getTextStyle('widget.item.tiny.medium'),
                                    ),
                                  ]
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SlantedWidget(
              color: Styles().colors.fillColorSecondary,
              child: RibbonButton(
                label: primaryButtonText,
                textAlign: TextAlign.center,
                backgroundColor: Styles().colors.fillColorSecondary,
                textStyle: Styles().textStyles.getTextStyle('widget.button.light.title.large.fat'),
                rightIconKey: null,
                onTap: () => _primaryButtonAction(context),
                progress: _loading,
                progressColor: Styles().colors.textLight,
              ),
            ),
          )
        ]
      )
    );
  }

  Widget _buildContentWidget(BuildContext context) {
    TextStyle? responseTextStyle;
    switch(_responseType) {
      case ResponseType.error:
        responseTextStyle = Styles().textStyles.getTextStyle('widget.error.regular.fat');
        break;
      case ResponseType.success:
        responseTextStyle = Styles().textStyles.getTextStyle('widget.success.regular.fat');
        break;
      default:
        responseTextStyle = Styles().textStyles.getTextStyle('widget.message.regular.fat.light');
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(_responseMessage ?? '', style: responseTextStyle,),
    );
  }

  Future<void> _primaryButtonAction(BuildContext context) async {
    if (_link) {
      _tryLink(context);
    } else {
      _trySignIn(context);
    }
  }

  Widget _buildSignUpButton() {
    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        children: [
          TextSpan(
            text: _state == Auth2PasskeyAccountState.failed ?
              Localization().getStringEx("panel.settings.passkey.sign_up.alternative.text", "Don't have a passkey or can't use it?") :
              Localization().getStringEx("panel.settings.passkey.sign_up.text", "Don't have an account?"),
            style: Styles().textStyles.getTextStyle('widget.description.medium.light'),
          ),
          WidgetSpan(
            child: TextButton(
              style: ButtonStyle(overlayColor: WidgetStatePropertyAll(Styles().colors.gradientColorPrimary), splashFactory: NoSplash.splashFactory),
              onPressed: _onTapSignUp,
              child: Text(
                _state == Auth2PasskeyAccountState.failed ?
                  Localization().getStringEx('panel.settings.passkey.sign_up.alternative.button.text', 'Try another way or sign up') :
                  Localization().getStringEx("panel.settings.passkey.sign_up.button.text", "Sign up"),
                textAlign: TextAlign.center,
                style: Styles().textStyles.getTextStyle('widget.button.title.regular.secondary.underline'),
              )
            ),
            alignment: PlaceholderAlignment.middle
          ),
        ],
      ),
    );
  }

  void _onTapSignUp() {
    Navigator.push(context, CupertinoPageRoute(builder: (BuildContext context) {
      return ProfileLoginPhoneOrEmailPanel(onboardingContext: widget.onboardingContext,);
    }));
  }

  Future<void> _tryLink(BuildContext context) async {
    if (!_loading) {
      Analytics().logSelect(target: "Sign Up");
      _clearResponseMessage();

      Map<String, dynamic> creds = {};  //TODO: change to use different identifier type?
      String? identifier = '';
      if (StringUtils.isNotEmpty(Auth2().username)) {
        creds['username'] = identifier = Auth2().username;
      } else if (Auth2().phones.isNotEmpty) {
        creds['phone'] = identifier = Auth2().phones.first;
      } else if (Auth2().emails.isNotEmpty) {
        creds['email'] = identifier = Auth2().emails.first;
      } else {
        _setResponseMessage(Localization().getStringEx("", "Your account could not be identified. Please try again later.")); //TODO: better error message for this case
        return;
      }
      Map<String, dynamic> params = {'display_name': StringUtils.isNotEmpty(Auth2().fullName) ? Auth2().fullName : identifier};
      setState(() {
        _loading = true;
      });
      Auth2LinkResult auth2linkResult = await Auth2().linkAccountAuthType(Auth2Type.typePasskey, creds, params);
      if (auth2linkResult.status == Auth2LinkResultStatus.succeeded) {
        try {
          creds['response'] = await RokwirePlugin.createPasskey(auth2linkResult.message);
          auth2linkResult = await Auth2().linkAccountAuthType(Auth2Type.typePasskey, creds, params);
          if (mounted) {
            _tryLinkCallback(context, auth2linkResult);
          }
        } catch (e) {
          debugPrint(e.toString());
        }
      }
      setState(() {
        _loading = false;
      });
    }
  }

  void _tryLinkCallback(BuildContext context, Auth2LinkResult result) {
    if (result.status == Auth2LinkResultStatus.succeeded) {
      _state = Auth2PasskeyAccountState.exists;

      Storage().auth2PasskeySaved = true;
      _next(context);
    }
    else if (result.status == Auth2LinkResultStatus.failedAccountExist) {
      _state = Auth2PasskeyAccountState.exists;
      _setResponseMessage(Localization().getStringEx('panel.settings.passkey.already_exists.failed.text', 'Passkey already exists'));
    }
    else {
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_up.failed.text", "Passkey creation failed. An unexpected error occurred."));
    }
  }

  Future<void> _trySignIn(BuildContext context) async {
    if (!_loading) {
      Analytics().logSelect(target: "Sign In");
      _clearResponseMessage();

      setState(() {
        _loading = true;
      });
      Auth2PasskeySignInResult result = await Auth2().authenticateWithPasskey();
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _trySignInCallback(context, result);
      }
    }
  }

  Future<void> _trySignInCallback(BuildContext context, Auth2PasskeySignInResult result) async {
    if (result.status == Auth2PasskeySignInResultStatus.succeeded) {
      Storage().auth2PasskeySaved = true;
    }

    if (result.status == Auth2PasskeySignInResultStatus.failed) {
      _state = Auth2PasskeyAccountState.failed;
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_in.failed.text", "Sign in failed. An unexpected error occurred."));
    }
    else if (result.status == Auth2PasskeySignInResultStatus.failedNotSupported) {
      _state = Auth2PasskeyAccountState.failed;
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_in.failed.not_supported.text", "Sign in failed. Passkeys are not supported on this device."));
    }
    else if (result.status == Auth2PasskeySignInResultStatus.failedNotFound) {
      _state = Auth2PasskeyAccountState.failed;
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_in.failed.not_found.text", "An account with this passkey does not exist. Try signing up instead."));
    }
    else if (result.status == Auth2PasskeySignInResultStatus.failedNoCredentials) {
      _state = Auth2PasskeyAccountState.failed;
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_in.failed.no_credentials.text", "No credentials found."));
    }
    else if (result.status == Auth2PasskeySignInResultStatus.failedCancelled) {
      _state = Auth2PasskeyAccountState.failed;
      _clearResponseMessage();
    }
    else if (result.status == Auth2PasskeySignInResultStatus.failedBlocked) {
      _state = Auth2PasskeyAccountState.failed;
      //TODO: parse error message to make it more user-friendly? (e.g., During begin sign in, failure response from one tap: 16: Caller has been temporarily blocked due to too many canceled sign-in prompts.)
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_in.failed.blocked.text", "Sign in blocked by device. Please try again later."));
    }
    else {
      _next(context);
    }
  }

  // void _skip(BuildContext context) {
  //   _next(context);
  // }

  void _next(BuildContext context) {
    // Hook this panels to Onboarding2
    Function? onContinue = widget.onboardingContext?["onContinueAction"];
    Function? onContinueEx = widget.onboardingContext?["onContinueActionEx"];
    if (onContinueEx != null) {
      onContinueEx(this);
    }
    else if (onContinue != null) {
      onContinue();
    }
    else if (!Config().isDebugWeb && !Auth2().hasPasskeyForPlatform && mounted) {
      // direct user to link a passkey if no passkey has been linked for the current platform
      setState(() {
        _link = true;
      });
    }
    else {
      Onboarding().next(context, widget);
    }
  }

  void _setResponseMessage(String? msg, {ResponseType type = ResponseType.error}) {
    if (mounted) {
      setState(() {
        _responseMessage = msg;
        _responseType = type;
      });
    }
  }

  void _clearResponseMessage() {
    if (mounted) {
      setState(() {
        _responseMessage = null;
        _responseType = ResponseType.message;
      });
    }
  }

  // void _resetAccessibilityFocus() {
  //   if(!MediaQuery.of(context).accessibleNavigation){
  //     return;
  //   }
  //
  //   if (mounted) {
  //     setState(() {
  //       _resettingAccessibility = true;
  //     });
  //   }
  //
  //   Future.delayed(const Duration(milliseconds: 400)).then((val) {
  //     if (mounted) {
  //       setState(() {
  //         _resettingAccessibility = false;
  //       });
  //     }
  //   });
  // }
}

enum Auth2PasskeyAccountState {
  exists,
  failed,
}
