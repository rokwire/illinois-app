// Copyright 2022 Board of Trustees of the University of Illinois.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class LoginPrivacyCard extends StatefulWidget {
  final String resource;

  const LoginPrivacyCard({required this.resource,});

  static LoginPrivacyCard? builder({required String resource}) => JsonUtils.stringListValue(FlexUI()[resource])?.contains('may_access') == true ? LoginPrivacyCard(resource: resource) : null;

  @override
  _LoginPrivacyCardState createState() => _LoginPrivacyCardState();
}

class _LoginPrivacyCardState extends State<LoginPrivacyCard> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0), child:
      Container(padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Styles().colors!.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
        child: _LoginPrivacyContent(
          requiredLoginType: widget.requiredLoginType,
          requiredPrivacyLevel: widget.requiredPrivacyLevel,
          resource: widget.resource,
        )
      )
    );
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == FlexUI.notifyChanged) {
      setState(() {});
    }
  }
}

class LoginPrivacyDialog extends StatefulWidget {
  final int requiredPrivacyLevel;
  final Auth2LoginType? requiredLoginType;

  const LoginPrivacyDialog({required this.requiredPrivacyLevel, this.requiredLoginType});

  @override
  _LoginPrivacyDialogState createState() => _LoginPrivacyDialogState();

  static Future<void> show({
    required String resource,
    required BuildContext context,
    EdgeInsetsGeometry titlePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    Color? titleBarColor,

    EdgeInsetsGeometry messagePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    
    EdgeInsetsGeometry buttonsPadding = const EdgeInsets.only(left: 16, right: 16, bottom: 16),

    bool barrierDismissible = true,
  }) => JsonUtils.stringListValue(FlexUI()[resource])?.contains('may_access') == true ? showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) => ActionsMessage(
      titlePadding: titlePadding,
      titleBarColor: titleBarColor,

      messagePadding: messagePadding,
  
      buttonsPadding: buttonsPadding,
    )
  ) : Future.value();
}

class _LoginPrivacyDialogState extends State<LoginPrivacyDialog> implements NotificationsListener {
  
  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //title: You may not access <resource>
    return Scaffold(
      appBar: RootBackHeaderBar(title: Localization().getStringEx('panel.skills_self_evaluation.info.header.title', 'Skills Self-Evaluation'),),
      body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(24.0), child: _buildContent(context))),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: null,
    );
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == FlexUI.notifyChanged) {
      setState(() {});
    }
  }
}

class _LoginPrivacyContent extends StatelessWidget {
  static const List<String> rulePriority = ['roles', 'privacy', 'auth'];
  final String resource;

  const _LoginPrivacyContent({required this.resource});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> unsatisfiedRules = FlexUI().unsatisfiedRulesForEntry(resource);
    //TODO: need to find a way to convert flex ui rule values into readable strings

    String message = '';
    String buttonLabel = '';
    for (String ruleType in rulePriority) {
      
    }

    return Column(children: <Widget>[
      StringUtils.isNotEmpty(title) ? Row(children: <Widget>[
        Expanded(child:
          Padding(padding: StringUtils.isNotEmpty(message) ? EdgeInsets.only(bottom: 8) : EdgeInsets.zero, child:
            Text(title ?? '', style: Styles().textStyles?.getTextStyle('widget.description.regular'), semanticsLabel: '',)
          ),
        )
      ]) : Container(),
      //TODO: build action button
    ]);
  }

  /*
  static bool isAccessGranted({int? requiredPrivacyLevel, Auth2LoginType? requiredLoginType}) {
    return _privacyMatch(requiredPrivacyLevel: requiredPrivacyLevel) && _loginTypeMatch(requiredLoginType: requiredLoginType);
  }

  static bool _privacyMatch({int? requiredPrivacyLevel}) {
    return requiredPrivacyLevel == null || Auth2().privacyMatch(requiredPrivacyLevel);
  }

  static bool _loginTypeMatch({Auth2LoginType? requiredLoginType}) {
    switch (requiredLoginType) {
      case null: return Auth2().isLoggedIn;
      case Auth2LoginType.email: return Auth2().isEmailLoggedIn;
      case Auth2LoginType.phone: return Auth2().isPhoneLoggedIn;
      case Auth2LoginType.phoneTwilio: return Auth2().isPhoneLoggedIn;
      case Auth2LoginType.oidc: return Auth2().isOidcLoggedIn;
      case Auth2LoginType.oidcIllinois: return Auth2().isOidcLoggedIn;
      default: return false;
    }
  }

    TextSpan(
      text: Localization().getStringEx('panel.skills_self_evaluation.auth_dialog.prefix', 'You need to be signed in with your NetID to access Assessments.\n'),
      style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.auth_dialog.text'),
    ),
    WidgetSpan(
      child: InkWell(onTap: _onTapPrivacyLevel, child: Text(
        Localization().getStringEx('panel.skills_self_evaluation.auth_dialog.privacy', 'Set your privacy level to 4 or 5.'),
        style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.auth_dialog.link'),
      )),
    ),
    TextSpan(
      text: Localization().getStringEx('panel.skills_self_evaluation.auth_dialog.suffix', ' Then, sign in with your NetID under Settings.'),
      style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.auth_dialog.text'),
    ),

    title: Localization().getStringEx("common.message.logged_out", "You are not logged in"),
    message: Localization().getStringEx("panel.wellness.sections.health_screener.label.screener.logged_out.text", "You need to be logged in with your NetID to access the Illinois Health Screener."),)
  */
}