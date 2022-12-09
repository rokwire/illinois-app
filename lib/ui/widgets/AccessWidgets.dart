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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AccessCard extends StatefulWidget {
  final String resource;

  const AccessCard({required this.resource,});

  static AccessCard? builder({required String resource}) => JsonUtils.stringListValue(FlexUI()[resource])?.contains('may_access') == true ? null : AccessCard(resource: resource);

  @override
  _AccessCardState createState() => _AccessCardState();
}

class _AccessCardState extends State<AccessCard> implements NotificationsListener {

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
        child: _AccessContent(
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

class AccessDialog extends StatefulWidget {
  final String resource;

  const AccessDialog({required this.resource,});

  @override
  _AccessDialogState createState() => _AccessDialogState();

  static Future<void>? show({
    required String resource,
    required BuildContext context,

    bool barrierDismissible = true,
  }) => JsonUtils.stringListValue(FlexUI()[resource])?.contains('may_access') == true ? null : showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) => AccessDialog(
      resource: resource,
    )
  );
}

class _AccessDialogState extends State<AccessDialog> implements NotificationsListener {
  
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
    return ActionsMessage(
      title: Localization().getStringEx('widget.access.dialog.title', 'You may not access ') + widget.resource, //TODO: change resource string to be more readable
      titleTextStyle: Styles().textStyles?.getTextStyle('widget.heading.regular.fat'),
      titleBarColor: Styles().colors?.fillColorPrimary,
      bodyWidget: _AccessContent(resource: widget.resource),
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

class _AccessContent extends StatelessWidget {
  static const List<String> rulePriority = ['roles', 'privacy', 'auth'];
  final String resource;

  const _AccessContent({required this.resource});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> unsatisfiedRules = FlexUI().unsatisfiedRulesForEntry('may_access', group: resource);

    String message = '';
    Widget? button;
    int stepNum = 1;
    for (String ruleType in rulePriority) {
      if (unsatisfiedRules[ruleType] != null) {
        if (message.isNotEmpty) {
          message += '\n';
        }
        //TODO: need to find a way to convert flex ui rule values into readable strings
        //TODO: check privacy level against privacy.connect for signin
        message += '$stepNum. ' + Localization().getStringEx('widget.access.$ruleType.unsatisfied.message', 'You must meet the following $ruleType condition: ') + (JsonUtils.encode(unsatisfiedRules[ruleType]) ?? '');
        stepNum++;

        if (ruleType != 'roles') {
          button ??= RoundedButton(
            label: Localization().getStringEx('widget.access.$ruleType.unsatisfied.button.label', 'Update'),
            borderColor: Styles().colors?.fillColorSecondary,
            backgroundColor: Styles().colors?.surface,
            textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
            onTap: () => _onTapUpdateButton(context, ruleType),
          );
        } else {
          break;
        }
      }
    }

    List<Widget> content = [
      Row(children: [Expanded(child:
        Padding(padding: EdgeInsets.only(bottom: 8), child:
          Text(message, style: Styles().textStyles?.getTextStyle('widget.description.regular'), semanticsLabel: '',)
        ),
      )])
    ];
    if (button != null) {
      content.add(button);
    }
    return Column(children: content);
  }

  void _onTapUpdateButton(BuildContext context, String ruleType) {
    switch (ruleType) {
      case 'privacy': Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,))); break;
      case 'auth': SettingsHomeContentPanel.present(context, content: SettingsContent.sections); break;
    }
  }
}