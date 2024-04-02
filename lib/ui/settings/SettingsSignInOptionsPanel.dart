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
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/onboarding.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'package:illinois/service/Analytics.dart';

class SettingsSignInOptionsPanel extends StatefulWidget with OnboardingPanel {
  final List<Auth2Type> options;
  final List<Auth2Identifier>? identifiers;

  SettingsSignInOptionsPanel({super.key, required this.options, this.identifiers});

  @override
  State<StatefulWidget> createState() => _SettingsSignInOptionsPanelState();
}

class _SettingsSignInOptionsPanelState extends State<SettingsSignInOptionsPanel> {
  String? _selectedOption;
  bool _inProgress = false;

  // @override
  // Widget build(BuildContext context) {
  //   return OnboardingBasePanel(
  //     title: Localization().getStringEx('panel.settings.sign_in.options.label.title', 'Sign-In Options'),
  //     description: ,
  //     primaryButtonText: Localization().getStringEx('panel.settings.sign_in.options.button.continue.title', 'CONTINUE'),
  //     primaryButtonAction: _primaryButtonAction,
  //     contentWidget: ,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: Column(children: [
            Expanded(child:
              _buildMainContent(context),
            ),
            _buildButtonContent(context, _buildPrimaryActionButton()),
          ])
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildText(),
            const SizedBox(height: 16),
            _buildContent(),
          ]
      ));
  }

  Widget _buildButtonContent(BuildContext context, Widget primaryActionButton) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          primaryActionButton,
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Semantics(button: true, label: Localization().getStringEx('headerbar.back.title', 'Back'), excludeSemantics: true, /*sortKey: const OrdinalSortKey(1.0),*/
        child: IconButton(icon: Styles().images.getImage('chevron-left') ?? Container(),
            tooltip: Localization().getStringEx('headerbar.back.title', 'Back'),
            onPressed: () {
              Analytics().logSelect(target: "Back");
              Navigator.of(context).pop();
            })
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 48),
      child: Column(children: [
        Align(alignment: Alignment.centerLeft, child: _buildBackButton(context)),
        const SizedBox(height: 16),
        Styles().images.getImage('university-logo', excludeFromSemantics: true) ?? Container(),
      ]),
    );
  }

  Widget _buildText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Semantics(header: true, label: Localization().getStringEx('panel.settings.sign_in.options.label.title', 'Sign-In Options'), excludeSemantics: true, focused: true,
            child: Text(Localization().getStringEx('panel.settings.sign_in.options.label.title', 'Sign-In Options'), textAlign: TextAlign.center,
              style: Styles().textStyles.getTextStyle('widget.title.small.semi_fat'),
            )),
        const SizedBox(height: 16),
        Text(Localization().getStringEx('panel.settings.sign_in.options.label.description', 'Please choose an alternative sign-in option.'), textAlign: TextAlign.center,
          style: Styles().textStyles.getTextStyle('widget.title.small.semi_fat'),
        )
      ]),
    );
  }

  Widget _buildPrimaryActionButton() {
    return RibbonButton(
      label: Localization().getStringEx('panel.settings.sign_in.options.button.continue.title', 'CONTINUE').toUpperCase(),
      textAlign: TextAlign.center,
      backgroundColor: Styles().colors.fillColorSecondary,
      textStyle: Styles().textStyles.getTextStyle('widget.item.small.semi_fat'),
      onTap: _performAction,
      progress: _inProgress,
      progressColor: Styles().colors.fillColorPrimary,
    );
  }

  void _performAction() {
    if (!_inProgress) {
      setState(() {
        _inProgress = true;
      });
      _primaryButtonAction(context).then((value) =>
      {
        setStateIfMounted(() {
          _inProgress = false;
          // _error = value;
        })
      }).onError((error, stackTrace) => {
        setStateIfMounted(() {
          _inProgress = false;
        })
      });
    }
  }

  Widget _buildContent() {
    List<Widget> contentList = [];
    for (Auth2Type authType in widget.options) {
      String label = '';
      switch (authType.code) {
        case Auth2Type.typePasskey:
          continue;
        case Auth2Type.typeCode:
          label = Localization().getStringEx('label.auth_type.code.text', 'Authentication Code');
          for (Auth2Identifier identifier in widget.identifiers?.where((element) => element.code == Auth2Identifier.typeEmail || element.code == Auth2Identifier.typePhone) ?? []) {
            contentList.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Card(
                    clipBehavior: Clip.hardEdge,
                    child: RadioListTile<String?>(
                      title: Transform.translate(offset: const Offset(-15, 0),
                          child: Text(label, style: Styles().textStyles.getTextStyle('widget.message.regular.semi_fat'))
                      ),
                      subtitle: Transform.translate(offset: const Offset(-15, 0),
                          child: Text('${StringUtils.capitalize(identifier.code ?? 'Unknown')}: ${identifier.identifier ?? 'Unknown'}', style: Styles().textStyles.getTextStyle('widget.message.regular.fat'))
                      ),
                      activeColor: Styles().colors.fillColorSecondary,
                      value: '${authType.id}_${identifier.id}',
                      groupValue: _selectedOption,
                      onChanged: _onOptionChanged,
                      contentPadding: const EdgeInsets.all(8),
                    )
                )
            ));
          }
          continue;
        case Auth2Type.typePassword:
          label = Localization().getStringEx('label.auth_type.password.text', 'Password');
          break;
        case Auth2Type.typeOidcIllinois:
          label = Localization().getStringEx('label.auth_type.net_id.text', 'Net ID');
          break;
      }
      contentList.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Card(
              clipBehavior: Clip.hardEdge,
              child: RadioListTile<String?>(
                title: Transform.translate(offset: const Offset(-15, 0),
                    child: Text(label, style: Styles().textStyles.getTextStyle('widget.message.regular.semi_fat'))
                ),
                activeColor: Styles().colors.fillColorSecondary,
                value: authType.id,
                groupValue: _selectedOption,
                onChanged: _onOptionChanged,
                contentPadding: const EdgeInsets.all(8),
              )
          )
      ));
    }

    return Column(children: contentList,);
  }

  void _onOptionChanged(String? value) {
    setState(() {
      _selectedOption = value;
    });
  }

  Future<void> _primaryButtonAction(BuildContext context) async {
    Analytics().logSelect(target: 'Log in with alternative');
    if (mounted) {
      if (_selectedOption != null) {
        Navigator.pop(context, _selectedOption);
      }
      else {
        _showDialogWidget(context);
      }
    }
  }

  void _showDialogWidget(BuildContext context) {
    ActionsMessage.show(
        context: context,
        title: Localization().getStringEx('app.title', 'Vogue Runway'),
        message: Localization().getStringEx('panel.settings.sign_in.options.popup.message', 'Please select an alternative to sign in.'),
        buttons: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(Localization().getStringEx('dialog.ok.title', 'OK'), style: Styles().textStyles.getTextStyle('widget.message.regular.fat')))
        ],
        buttonAxis: Axis.horizontal
    );
  }
}