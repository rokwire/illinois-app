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
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';

class LoginPrivacyCard extends StatefulWidget {
  final int requiredPrivacyLevel;
  final Auth2LoginType? requiredLoginType;
  final String? resource;
  final EdgeInsetsGeometry margin;

  const LoginPrivacyCard({this.requiredPrivacyLevel = 4, this.requiredLoginType, this.resource, this.margin = const EdgeInsets.only(left: 16, right: 16, bottom: 16),});

  @override
  _LoginPrivacyCardState createState() => _LoginPrivacyCardState();
}

class _LoginPrivacyCardState extends State<LoginPrivacyCard> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2.notifyLoginChanged,
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
    return Padding(padding: widget.margin, child:
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
    if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      setState(() {});
    } else if (name == Auth2.notifyLoginChanged) {
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
    String? title,
    TextStyle? titleTextStyle,
    Color? titleTextColor,
    String? titleFontFamily,
    double titleFontSize = 20,
    TextAlign? titleTextAlign,
    EdgeInsetsGeometry titlePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    Color? titleBarColor,
    Widget? closeButtonIcon,
    
    String? message,
    TextStyle? messageTextStyle,
    Color? messageTextColor,
    String? messageFontFamily,
    double messageFontSize = 16.0,
    TextAlign? messageTextAlign,
    EdgeInsetsGeometry messagePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    
    List<Widget> buttons = const [],
    EdgeInsetsGeometry buttonsPadding = const EdgeInsets.only(left: 16, right: 16, bottom: 16),
    Axis buttonAxis = Axis.horizontal,

    ShapeBorder? border,
    BorderRadius? borderRadius,

    required BuildContext context,
    bool barrierDismissible = true,
  }) => showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) => ActionsMessage(
      title: title,
      titleTextStyle: titleTextStyle,
      titleTextColor: titleTextColor,
      titleFontFamily: titleFontFamily,
      titleFontSize: titleFontSize,
      titleTextAlign: titleTextAlign,
      titlePadding: titlePadding,
      titleBarColor: titleBarColor,
      closeButtonIcon: closeButtonIcon,
  
      message: message,
      messageTextStyle: messageTextStyle,
      messageTextColor: messageTextColor,
      messageFontFamily: messageFontFamily,
      messageFontSize: messageFontSize,
      messageTextAlign: messageTextAlign,
      messagePadding: messagePadding,
  
      buttons: buttons,
      buttonAxis: buttonAxis,
      buttonsPadding: buttonsPadding,

      border: border,
      borderRadius: borderRadius,
    )
  );
}

class _LoginPrivacyDialogState extends State<LoginPrivacyDialog> implements NotificationsListener {
  
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2.notifyLoginChanged,
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
    if (name == polls.Polls.notifySurveyResponseCreated) {
      _refreshHistory();
    } else if (name == FlexUI.notifyChanged) {
      setState(() {
        _sectionEntryCodes = JsonUtils.setStringsValue(FlexUI()['wellness.health_screener']);
      });
    }
  }
}

class _LoginPrivacyContent extends StatelessWidget {
  final int requiredPrivacyLevel;
  final Auth2LoginType? requiredLoginType;
  final String? resource;

  const _LoginPrivacyContent({this.requiredPrivacyLevel = 4, this.requiredLoginType, this.resource});

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      StringUtils.isNotEmpty(title) ? Row(children: <Widget>[
        Expanded(child:
          Padding(padding: StringUtils.isNotEmpty(message) ? EdgeInsets.only(bottom: 8) : EdgeInsets.zero, child:
            Text(title ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary), semanticsLabel: '',)
          ),
        )
      ]) : Container(),
      StringUtils.isNotEmpty(message) ? Row(children: <Widget>[
        Expanded(child:
          Text(message ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground), semanticsLabel: '',)
        )
      ]) : Container(),
    ]);
  }

  /*
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