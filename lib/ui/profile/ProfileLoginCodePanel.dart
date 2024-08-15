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
import 'package:neom/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:neom/ui/profile/ProfileLoginPasskeyPanel.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/ui/widgets/SlantedWidget.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/onboarding.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

import 'package:neom/service/Analytics.dart';

class ProfileLoginCodePanel extends StatefulWidget with OnboardingPanel {
  @override
  final Map<String, dynamic>? onboardingContext;
  final bool? linkIdentifier;
  final String? defaultIdentifierType;
  final String? identifier;
  final String? identifierId;
  final Function()? onFinish;

  ProfileLoginCodePanel({super.key, this.onboardingContext, this.defaultIdentifierType, this.identifier, this.identifierId, this.linkIdentifier, this.onFinish});

  @override
  State<StatefulWidget> createState() => _ProfileLoginCodePanelState();

  @override
  bool get onboardingCanDisplay => !Auth2().isLoggedIn;

  String? get identifierType => onboardingContext?["identifier_type"] ?? defaultIdentifierType;
}

class _ProfileLoginCodePanelState extends State<ProfileLoginCodePanel> {
  final TextEditingController _codeController = TextEditingController();

  String? _identifier;
  String? _errorMessage;
  bool? _linkIdentifier;
  bool _isLoading = false;

  @override
  void initState() {
    _linkIdentifier = widget.onboardingContext?["link_identifier"] ?? widget.linkIdentifier;
    _identifier = widget.onboardingContext?["identifier"] ?? widget.identifier;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Styles().colors.background,
          body: SingleChildScrollView(
            child: Column(children: [
              Stack(
                children: [
                  Semantics(hint: Localization().getStringEx("common.heading.one.hint","Header 1"), header: true, child:
                    Onboarding2TitleWidget(),
                  ),
                  Positioned(
                    top: 32,
                    left: 0,
                    child: Onboarding2BackButton(padding: const EdgeInsets.all(16.0,),
                        onTap:() {
                          Analytics().logSelect(target: "Back");
                          Navigator.pop(context);
                        }),
                  ),
                ],
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
      child: Container(
        constraints: BoxConstraints(maxWidth: Config().webContentMaxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: kIsWeb ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: <Widget>[
            _buildText(),
            Container(height: 48),
            _buildContentWidget(),
            Container(height: 24),
            _buildPrimaryActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildText() {
    String maskedIdentifier = _identifier ?? '';
    if (_identifier?.startsWith('***') != true) {
      if (widget.identifierType == Auth2Identifier.typePhone) {
        maskedIdentifier = StringUtils.getMaskedPhoneNumber(_identifier);
      } else if (widget.identifierType == Auth2Identifier.typeEmail) {
        maskedIdentifier = StringUtils.getMaskedEmailAddress(_identifier);
      }
    }

    // String title = Localization().getStringEx("panel.settings.confirm_identifier.title", "Confirm your code");
    // return Padding(
    //   padding: const EdgeInsets.symmetric(horizontal: 24),
    //   child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
    //     Semantics(header: true, label: title, excludeSemantics: true, focused: true,
    //         child: Text(title, textAlign: TextAlign.center,
    //           style: Styles().textStyles.getTextStyle('widget.info.regular.light'),
    //         )),
    //     const SizedBox(height: 16),
    //     Text(sprintf(
    //         Localization().getStringEx(
    //             'panel.settings.confirm_identifier.description.send', 'A one-time code has been sent to %s. Enter your code below to continue.'),
    //         [maskedIdentifier]), textAlign: TextAlign.center,
    //       style: Styles().textStyles.getTextStyle('widget.info.regular.light'),
    //     )
    //   ]),
    // );
    return Text(sprintf(
        Localization().getStringEx(
            'panel.settings.confirm_identifier.description.send', 'A one-time code has been sent to %s. Enter your code below to continue.'),
        [maskedIdentifier]),
      style: Styles().textStyles.getTextStyle('widget.description.medium.light'),
    );
  }

  Widget _buildPrimaryActionButton() {
    return SlantedWidget(
      color: Styles().colors.fillColorSecondary,
      child: RibbonButton(
        label: Localization().getStringEx("panel.settings.confirm_identifier.button.confirm.label", "Confirm"),
        textAlign: TextAlign.center,
        backgroundColor: Styles().colors.fillColorSecondary,
        textStyle: Styles().textStyles.getTextStyle('widget.button.light.title.large.fat'),
        onTap: () => _primaryButtonAction(context),
        progress: _isLoading,
        progressColor: Styles().colors.textLight,
        rightIconKey: null,
      ),
    );
  }

  Widget _buildContentWidget() {
    return Column(children: [
      Visibility(
        visible: StringUtils.isNotEmpty(_errorMessage),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage ?? '',
            style: Styles().textStyles.getTextStyle('widget.error.regular.fat'),
          ),
        ),
      ),
      Row(children: [ Expanded(child:
        Text(Localization().getStringEx("panel.settings.confirm_identifier.code.label", "One-Time Code:"), style: Styles().textStyles.getTextStyle("widget.title.light.medium.fat"),)
      )],),
      Container(height: 6),
      Semantics(
        excludeSemantics: true,
        label: Localization().getStringEx("panel.settings.confirm_identifier.code.label", "One-Time Code"),
        hint: Localization().getStringEx("panel.settings.confirm_identifier.code.hint", ""),
        value: _codeController.text,
        child: TextField(
          controller: _codeController,
          autofocus: false,
          onSubmitted: (_) => _clearErrorMessage(),
          cursorColor: Styles().colors.fillColorSecondary,
          keyboardType: TextInputType.number,
          style: Styles().textStyles.getTextStyle('widget.description.regular'),
          decoration: InputDecoration(
            filled: true,
            fillColor: Styles().colors.surface,
            border: OutlineInputBorder(),
          ),
        ),
      ),
    ]);
  }

  Future<void> _primaryButtonAction(BuildContext context) async {
    if (!_isLoading) {
      setState(() { _isLoading = true; });

      Analytics().logSelect(target: "Confirm ${widget.identifierType}");
      _clearErrorMessage();
      _validateCode();
      if (StringUtils.isNotEmpty(_errorMessage)) {
        return;
      }

      String? identifier = widget.onboardingContext?["identifier"] ?? widget.identifier;
      if (_linkIdentifier == null) {
        Auth2SendCodeResult result = await Auth2().handleCodeAuthentication(
            widget.identifierId == null ? identifier : null,
            _codeController.text,
            identifierType: widget.defaultIdentifierType ?? Auth2Identifier.typePhone,
            identifierId: widget.identifierId
        );
        _onIdentifierVerified(result);
      } else {
        Auth2LinkResult result = await Auth2().linkAccountIdentifier(identifier, widget.identifierType ?? '');
        _onIdentifierVerified(auth2SendCodeResultFromAuth2LinkResult(result));
      }
    }
  }

  void _onIdentifierVerified(Auth2SendCodeResult result) {
    if (mounted) {
      if (result == Auth2SendCodeResult.failed) {
        _setErrorMessage(Localization().getStringEx("panel.settings.confirm_identifier.validation.server_error.text",
            "Failed to verify code. An unexpected error occurred."));
      } else if (result == Auth2SendCodeResult.failedInvalid) {
        _setErrorMessage(Localization().getStringEx("panel.settings.confirm_identifier.validation.invalid.text",
            "Incorrect code."));
      } else {
        // Create new passkey if link is false
        // if (_linkIdentifier == null) {
        //   Navigator.of(context).popUntil((Route route){
        //     return route.settings.name == SettingsLoginPasskeyPanel.route;
        //   });
        //   return;
        // }
        setState(() { _isLoading = false; });
        _next();
      }
    }
  }

  void _validateCode() {
    if (StringUtils.isEmpty(_codeController.text.trim())) {
      _setErrorMessage(Localization().getStringEx("panel.settings.confirm_identifier.validation.phone_number.text", "Please enter your code"));
      return;
    }
  }

  void _next() {
    // Hook this panels to Onboarding2
    Function? onContinue = widget.onboardingContext?["onContinueAction"];
    Function? onContinueEx = widget.onboardingContext?["onContinueActionEx"];
    if (onContinueEx != null) {
      onContinueEx(this);
    }
    else if (onContinue != null) {
      onContinue();
    }
    else if (widget.onFinish != null) {
      widget.onFinish?.call();
    }
    else if (!Config().isDebugWeb && (!Auth2().isPasskeyLinked || !Auth2().hasPasskeyForPlatform)) {
      // direct user to link a passkey if no passkey has been linked for the current platform
      Navigator.push(context, CupertinoPageRoute(builder: (BuildContext context) {
        return ProfileLoginPasskeyPanel(link: true, onboardingContext: widget.onboardingContext,);
      }));
    } else {
      // just login if a passkey is already linked
      Onboarding().next(context, widget);
    }
  }

  void _setErrorMessage(String? msg) {
    setState(() {
      _isLoading = false;
      _errorMessage = msg;
    });
  }

  void _clearErrorMessage() {
    setState(() {
      _errorMessage = null;
    });
  }
}
