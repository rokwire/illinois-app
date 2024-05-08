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
import 'package:neom/service/Storage.dart';
import 'package:neom/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:neom/ui/settings/SettingsLoginEmailPanel.dart';
import 'package:neom/ui/settings/SettingsLoginPhoneOrEmailPanel.dart';
import 'package:neom/ui/settings/SettingsSignInOptionsPanel.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/ui/widgets/SlantedWidget.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/onboarding.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'package:neom/service/Analytics.dart';

class SettingsLoginPasskeyPanel extends StatefulWidget with OnboardingPanel {
  @override
  final Map<String, dynamic>? onboardingContext;

  final bool? link;

  SettingsLoginPasskeyPanel({super.key, this.onboardingContext, this.link});

  @override
  State<StatefulWidget> createState() => _SettingsLoginPasskeyPanelState();

  @override
  bool get onboardingCanDisplay {
    return !Auth2().isPasskeyLinked;
    // return onboardingContext?['auth_type'] == 'passkey';
  }
}

enum ResponseType { success, error, message }

class _SettingsLoginPasskeyPanelState extends State<SettingsLoginPasskeyPanel> {
  final TextEditingController _identifierController = TextEditingController();
  final FocusNode _identifierFocusNode = FocusNode();

  String? _responseMessage;
  ResponseType _responseType = ResponseType.message;

  Auth2PasskeyAccountState _state = Auth2PasskeyAccountState.exists;
  String? _passkeyCreationOptions;

  late bool _link;
  bool _loading = false;

  @override
  void initState() {
    _link = widget.onboardingContext?["link"] ?? widget.link ?? (Auth2().isLoggedIn && !Auth2().isPasskeyLinked);

    if ((Storage().auth2PasskeySaved ?? false) && (widget.onboardingContext?["afterLogout"] != true) && !_link) {
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
          body: SingleChildScrollView(
            child: _link ? _buildPasskeyInfo() : Column(children: [
                Semantics(hint: Localization().getStringEx("common.heading.one.hint","Header 1"), header: true, child:
                  Onboarding2TitleWidget()
                ),
              _buildContent(context),
            ]),
          )
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildText(),
          Container(height: 48),
          if (_state == Auth2PasskeyAccountState.unverified || StringUtils.isNotEmpty(_responseMessage))
            _buildContentWidget(context),
          _buildPrimaryActionButton(),
          Container(height: 8),
          _buildSignUpButton(),
          // _buildSkipButton(context),
        ],
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
      switch (_state) {
        case Auth2PasskeyAccountState.nonExistent:
          title = Localization().getStringEx('panel.settings.passkey.sign_up.title.text', 'Sign up to continue.');
          // description = Localization().getStringEx('panel.settings.passkey.sign_up.description.text',
          //     'Choose a username. This is how you will be known in the Vogue community. The username must not already be in use by someone else.\n\nYou may use an email address or email address instead and choose a username later.');
          break;
        case Auth2PasskeyAccountState.alternatives:
          title = Localization().getStringEx('panel.settings.passkey.sign_in.alternative.title.text', 'Try another way');
          // description = Localization().getStringEx('panel.settings.passkey.sign_in.alternative.description.text',
          //     'Please enter the username of the account you are trying to sign in with. You will then be able to choose an alternative sign-in option.');
          break;
        default:
          title = Localization().getStringEx('panel.settings.passkey.sign_in.title.text', 'Sign in to continue.');
          // description = Localization().getStringEx('panel.settings.passkey.sign_in.description.text', 'Sign in with your passkey.');
          break;
      }
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
    String primaryButtonText = '';
    switch (_state) {
      case Auth2PasskeyAccountState.nonExistent:
        primaryButtonText = Localization().getStringEx('panel.settings.passkey.button.sign_up.text', 'Sign Up');
        break;
      case Auth2PasskeyAccountState.alternatives:
        primaryButtonText = Localization().getStringEx('panel.settings.passkey.button.sign_in.alternative.text', 'Continue');
        break;
      default:
        primaryButtonText = Localization().getStringEx('panel.settings.passkey.button.sign_in.text', 'Sign In');
        break;
    }

    return SlantedWidget(
      color: Styles().colors.fillColorSecondary,
      child: RibbonButton(
        label: primaryButtonText,
        textAlign: TextAlign.center,
        backgroundColor: Styles().colors.fillColorSecondary,
        textStyle: Styles().textStyles.getTextStyle('widget.button.title.large.fat'),
        onTap: () => _primaryButtonAction(context),
        progress: _loading,
        progressColor: Styles().colors.fillColorPrimary,
        rightIconKey: null,
      ),
    );
  }

  Widget _buildPasskeyInfo() {
    String primaryButtonText = Localization().getStringEx('panel.settings.passkey.add.button.label', 'Add Passkey');
    return Container(
      decoration: BoxDecoration(
        color: Styles().colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 32.0),
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Styles().images.getImage('university-logo-dark-script') ?? Container(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              Localization().getStringEx('', 'PASSKEYS ARE A BETTER WAY TO SIGN IN'),
              style: Styles().textStyles.getTextStyle('panel.onboarding2.login_passkey.link.title'),
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
                            Localization().getStringEx('', 'Works on all of your devices'),
                            style: Styles().textStyles.getTextStyle('widget.heading.large.dark'),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            Localization().getStringEx('', 'Passkeys will automatically be available across your synced devices'),
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
          SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SlantedWidget(
              color: Styles().colors.fillColorSecondary,
              child: RibbonButton(
                label: primaryButtonText,
                textAlign: TextAlign.center,
                backgroundColor: Styles().colors.fillColorSecondary,
                textStyle: Styles().textStyles.getTextStyle('widget.button.title.large.fat'),
                rightIconKey: null,
                onTap: () => _primaryButtonAction(context),
                progress: _loading,
                progressColor: Styles().colors.fillColorPrimary,
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Visibility(
        visible: StringUtils.isNotEmpty(_responseMessage),
        child: Align(alignment: Alignment.center, child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Text(
            _responseMessage ?? '',
            style: responseTextStyle,
          ),
        ),),
      ),
      // Align(alignment: Alignment.center, child: Visibility(
      //   visible: _state == Auth2PasskeyAccountState.failed && !_link,
      //   child: _buildTryAnotherWayButton(),
      // )),
      Visibility(
        visible: (_state == Auth2PasskeyAccountState.unverified),
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: InkWell(
            onTap: () => _onTapResendEmail(context),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        Localization().getStringEx("panel.settings.passkey.label.resend_email.text", "Resend Verification"),
                        textAlign: TextAlign.right,
                        style: Styles().textStyles.getTextStyle('widget.info.regular.light')
                    )
                  ],
                )),
          ),
        ),
      ),
    ]);
  }

  Future<void> _primaryButtonAction(BuildContext context) async {
    if (_state == Auth2PasskeyAccountState.nonExistent || _link) {
      _trySignUp(context);
    } else if (_state == Auth2PasskeyAccountState.exists || _state == Auth2PasskeyAccountState.unverified || _state == Auth2PasskeyAccountState.failed) {
      _trySignIn(context);
    } else if (_state == Auth2PasskeyAccountState.alternatives && !_link) {
      _handleSignInOptions(context);
    }
  }

  Widget _buildSignUpButton() {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: Localization().getStringEx("panel.settings.passkey.label.switch_mode.sign_up.text", "Don't have an account?"),
            style: Styles().textStyles.getTextStyle('widget.description.medium.light'),
          ),
          WidgetSpan(
            child: TextButton(
              style: ButtonStyle(overlayColor: MaterialStatePropertyAll(Styles().colors.gradientColorPrimary), splashFactory: NoSplash.splashFactory),
              onPressed: _onTapSignUp,
              child: Text(
                Localization().getStringEx("panel.settings.passkey.label.switch_mode.sign_up.button.text", "Sign up"),
                textAlign: TextAlign.center,
                style: Styles().textStyles.getTextStyle('widget.button.title.regular.secondary.underline'),
              )
            ),
            alignment: PlaceholderAlignment.middle
          ),
        ],
      )
    );
  }

  // Widget _buildTryAnotherWayButton() {
  //   return TextButton(
  //     onPressed: _onTapSignUp,
  //     child: Text(
  //         Localization().getStringEx("panel.settings.passkey.label.another_way.text", "Try another way"),
  //         textAlign: TextAlign.center,
  //         style: Styles().textStyles.getTextStyle('widget.info.regular.light'),
  //   ));
  // }

  void _onTapSignUp() {
    Navigator.push(context, CupertinoPageRoute(builder: (BuildContext context) {
      return SettingsLoginPhoneOrEmailPanel(/*onFinish: () => _next(context), identifier: _identifierController.text*/);
    }));
  }

  void _onTapResendEmail(BuildContext context) {
    Analytics().logSelect(target: "Resend Email");
    _clearResponseMessage();
    Auth2().resendIdentifierVerification(_identifierController.text).then((bool result) {
      if (result == true) {
        _identifierFocusNode.unfocus();
        _setResponseMessage(Localization().getStringEx("panel.settings.passkey.resend_email.succeeded.text", "Verification email has been resent."));
      }
      else {
        _setResponseMessage(Localization().getStringEx("panel.settings.passkey.resend_email.failed.text", "Failed to resend verification email."));
      }
    });
  }

  Future<void> _trySignUp(BuildContext context) async {
    if (!_loading) {
      Analytics().logSelect(target: "Sign Up");
      _clearResponseMessage();

      String identifier = _identifierController.text.trim();
      if (!_link) {
        if (identifier.isEmpty) {
          _setResponseMessage(Localization().getStringEx("panel.settings.passkey.validation.identifier_empty.text", "Please enter an email address."));
          return;
        }

        String? identifierType = _getIdentifierType(identifier);
        if (identifierType == null) {
          _setResponseMessage(Localization().getStringEx('panel.settings.passkey.validation.identifier.invalid.text', 'Invalid email address.'));
          return;
        }

        Auth2PasskeySignUpResult result = Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failed);
        setState(() {
          _loading = true;
        });
        if (_passkeyCreationOptions == null) {
          result = await Auth2().signUpWithPasskey(identifier, displayName: identifier, identifierType: identifierType,
              public: true, verifyIdentifier: identifierType == Auth2Identifier.typeEmail);
        } else if (identifierType == Auth2Identifier.typeUsername || (await Auth2().canSignIn(identifier, identifierType) == true)) {
          // canSignIn will return true once the identifier has been verified (verification not required for usernames)
          try {
            String? responseData = await RokwirePlugin.createPasskey(_passkeyCreationOptions);
            result = await Auth2().completeSignUpWithPasskey(identifier, responseData, identifierType: identifierType);
          } catch(error) {
            Log.e(error.toString());
          }
        } else {
          _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_in.failed.not_activated.text", "Your account is not activated yet. Please confirm the email sent to your email address."));
          return;
        }

        setState(() {
          _loading = false;
        });
        if (mounted) {
          _trySignUpCallback(context, result);
        }
      } else {
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
  }

  void _trySignUpCallback(BuildContext context, Auth2PasskeySignUpResult result) {
    if (result.status == Auth2PasskeySignUpResultStatus.succeeded) {
      _identifierFocusNode.unfocus();
      _state = Auth2PasskeyAccountState.exists;
      if (result.creationOptions != null) {
        // received creation options, so identifier must be verified before creating passkey
        _passkeyCreationOptions = result.creationOptions;
        _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_up.require_validation.text",
            "A verification email has been sent to your email address. To activate your account you need to confirm it. Then you will be able to create a passkey."));
      }
    }
    else if (result.status == Auth2PasskeySignUpResultStatus.failedNotSupported) {
      _state = Auth2PasskeyAccountState.nonExistent;
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_up.failed.not_supported.text",
          "Sign up failed. Passkeys are not supported on this device."));
    }
    else if (result.status == Auth2PasskeySignUpResultStatus.failedAccountExist) {
      _state = Auth2PasskeyAccountState.exists;
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_up.failed.account_exists.text", "An account with this email address already exists. Please select a different email address."));
    }
    else if (result.status == Auth2PasskeySignUpResultStatus.failedNoCredentials) {
      _state = Auth2PasskeyAccountState.failed;
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_up.failed.no_credentials.text", "An account with this email address already exists, so sign in was attempted, but no credentials were found."));
    }
    else if (result.status == Auth2PasskeySignUpResultStatus.failedCancelled) {
      _state = Auth2PasskeyAccountState.failed;
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_up.failed.user_cancelled.text", "Sign up cancelled."));
    }
    else {
      _state = Auth2PasskeyAccountState.failed;
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_up.failed.text", "Sign up failed. An unexpected error occurred."));
    }
  }

  void _tryLinkCallback(BuildContext context, Auth2LinkResult result) {
    if (result.status == Auth2LinkResultStatus.succeeded) {
      _identifierFocusNode.unfocus();
      _state = Auth2PasskeyAccountState.exists;

      Storage().auth2PasskeySaved = true;
      _next(context);
    }
    else if (result.status == Auth2LinkResultStatus.failedAccountExist) {
      _state = Auth2PasskeyAccountState.exists;
      _setResponseMessage(Localization().getStringEx('panel.settings.passkey.already_exists.failed.text', 'Passkey already exists'));
    }
    else {
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_up.failed.text", "Sign up failed. An unexpected error occurred."));
    }
  }

  Future<void> _trySignIn(BuildContext context) async {
    if (!_loading) {
      Analytics().logSelect(target: "Sign In");
      _clearResponseMessage();

      setState(() {
        _loading = true;
      });
      String identifier = _identifierController.text.trim();
      Auth2PasskeySignInResult result = await Auth2().authenticateWithPasskey(identifier: identifier, identifierType: _getIdentifierType(identifier) ?? Auth2Identifier.typeUsername);
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
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_in.failed.text", "Sign in failed. An unexpected error occurred."));
    }
    else if (result.status == Auth2PasskeySignInResultStatus.failedNotSupported) {
      //TODO: go to sign up?
      _state = Auth2PasskeyAccountState.exists;
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_in.failed.not_supported.text", "Sign in failed. Passkeys are not supported on this device."));
    }
    else if (result.status == Auth2PasskeySignInResultStatus.failedNotFound) {
      _state = Auth2PasskeyAccountState.failed;
      _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_in.failed.not_found.text", "An account with this passkey does not exist. Try signing up instead."));
    }
    else if (result.status == Auth2PasskeySignInResultStatus.failedNoCredentials) {
      //TODO: go to sign up (or sign in) with email/phone and code or passkey on another device
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

  Future<void> _handleSignInOptions(BuildContext context) async {
    if (!_loading) {
      Analytics().logSelect(target: "Sign In Options");
      _clearResponseMessage();

      String identifierText = _identifierController.text.trim();
      if (identifierText.isEmpty) {
        _setResponseMessage(Localization().getStringEx("panel.settings.passkey.validation.identifier_empty.text", "Please enter an email address."));
        return;
      }

      String? identifierType = _getIdentifierType(identifierText);
      if (identifierType == null) {
        _setResponseMessage(Localization().getStringEx('panel.settings.passkey.validation.identifier.invalid.text', 'Invalid email address.'));
        return;
      }

      _loading = true;
      Auth2SignInOptionsResult? optionsResult = await Auth2().signInOptions(identifierText, identifierType);
      _loading = false;
      optionsResult?.authTypeOptions?.removeWhere((element) => element.code == Auth2Type.typePasskey); // already know we cannot sign in with passkey
      Auth2Type? authType;
      Auth2Identifier? identifier;

      if (optionsResult?.authTypeOptions?.length == 1) {
        authType = optionsResult?.authTypeOptions?[0];
      }
      if ((authType == null || authType.code == Auth2Type.typeCode) && mounted) {
        String? authIdentifierIds = await Navigator.push<String?>(context, CupertinoPageRoute(builder: (BuildContext context) {
          return SettingsSignInOptionsPanel(options: optionsResult!.authTypeOptions!, identifiers: optionsResult.identifierOptions);
        }));

        List<String> idParts = authIdentifierIds?.split('_') ?? [];
        if (idParts.length == 1) {
          try {
            authType = optionsResult!.authTypeOptions?.singleWhere((element) => element.id == idParts[0]);
          } catch (e) {
            debugPrint(e.toString());
          }
        } else if (idParts.length == 2) {
          try {
            authType = optionsResult!.authTypeOptions?.singleWhere((element) => element.id == idParts[0]);
            identifier = optionsResult.identifierOptions?.singleWhere((element) => element.id == idParts[1]);
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      }

      try {
        bool success = false;
        switch (authType?.code) {
          case Auth2Type.typeCode:
            if (identifier == null) {
              _setResponseMessage(Localization().getStringEx("panel.settings.passkey.code.identifier_missing.text", "Failed to determine where to send an authentication code."));
              break;
            }
            try {
              _loading = true;
              Auth2RequestCodeResult codeResult = await Auth2().authenticateWithCode(null, identifierId: identifier.id);
              _loading = false;
              if (codeResult == Auth2RequestCodeResult.succeeded && mounted) {
                await Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsLoginPhoneOrEmailPanel(
                    identifier: identifier?.identifier,
                    mode: SettingsLoginPhoneOrEmailMode.phone,
                )));
                success = (Auth2().account != null);
              }
            } catch (e) {
              debugPrint(e.toString());
            }
            break;
          case Auth2Type.typePassword:
            if (mounted) {
              // use username if password auth type is only option
              try {
                identifier = optionsResult?.identifierOptions?.firstWhere((element) => element.code == Auth2Identifier.typeUsername);

                await Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsLoginEmailPanel(
                    email: identifier?.identifier,
                    state: Auth2AccountState.verified,
                )));
                success = (Auth2().account != null);
              } catch (e) {
                debugPrint(e.toString());
              }
            }
            break;
          case Auth2Type.typeOidcIllinois:
            _loading = true;
            Auth2OidcAuthenticateResult? result = await Auth2().authenticateWithOidc();
            _loading = false;
            success = (result?.status == Auth2OidcAuthenticateResultStatus.succeeded);
            break;
          default: return;
        }

        if (success) {
          // try linking a new passkey if the alternative authentication was successful
          if (mounted) {
            _link = true;
            _clearResponseMessage();
          }
        } else if (identifier != null && authType != null) {
          _setResponseMessage(Localization().getStringEx("panel.settings.passkey.sign_in.alternative.failed.text", "Alternative sign-in failed. Please try again later."));
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  // void _skip(BuildContext context) {
  //   _next(context);
  // }

  void _next(BuildContext context) {
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

  String? _getIdentifierType(String identifier) {
    if (StringUtils.isEmailValid(identifier)) {
      return Auth2Identifier.typeEmail;
    } else if (StringUtils.isPhoneValid(identifier)) {
      return Auth2Identifier.typePhone;
    }
    return null;
  }

  void _setResponseMessage(String? msg, {ResponseType type = ResponseType.error}) {
    if (mounted) {
      setState(() {
        _responseMessage = msg;
        _responseType = type;
      });
    }

    // if (StringUtils.isNotEmpty(msg)) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (_validationErrorKey.currentContext != null) {
    //       Scrollable.ensureVisible(_validationErrorKey.currentContext!, duration: Duration(milliseconds: 300)).then((_) {
    //       });
    //     }
    //   });
    // }
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
  nonExistent,
  unverified,
  exists,
  failed,
  alternatives,
}
