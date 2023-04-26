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
import 'package:sprintf/sprintf.dart';

class AccessCard extends StatefulWidget {
  final String resource;
  final EdgeInsetsGeometry padding;

  const AccessCard({
    required this.resource,
    required this.padding,
  });

  static AccessCard? builder({
    required String resource,
    EdgeInsetsGeometry padding = const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0)
  }) => _AccessContent.mayAccessResource(resource) ? null : AccessCard(resource: resource, padding: padding);

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
    List<String> messageKeys = _AccessContent.getMessageKeys(widget.resource);
    if (messageKeys.isNotEmpty) {
      String titleKey = messageKeys.last.split('.').first;
      String defaultTitle = _AccessContent.defaultStringKey(titleKey);
      String resourceName = Localization().getStringEx('widget.access.${widget.resource}.name', widget.resource);

      return Padding(padding: widget.padding, child:
        Container(
          decoration: BoxDecoration(color: Styles().colors!.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
          child: Column(children: <Widget>[
            Row(children: <Widget>[
              Expanded(child:
                Padding(padding: EdgeInsets.only(top: 16, left: 16, right: 16), child:
                  Text(sprintf(Localization().getStringEx('widget.access.$titleKey.unsatisfied.title', defaultTitle), [resourceName]),
                    style: Styles().textStyles?.getTextStyle("widget.card.title.medium.fat"), semanticsLabel: '',
                  )
                ),
              )
            ]),
            _AccessContent(messageKeys: messageKeys, resourceName: resourceName,),
          ])
        )
      );
    }
    return Container();
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == FlexUI.notifyChanged && mounted) {
      setState(() {});
    }
  }
}

class AccessDialog extends StatefulWidget {
  static final String routeName = 'access_dialog';
  final String resource;

  const AccessDialog({required this.resource});

  @override
  _AccessDialogState createState() => _AccessDialogState();

  static Future<void>? show({
    required String resource,
    required BuildContext context,

    bool barrierDismissible = true,
  }) => _AccessContent.mayAccessResource(resource) ? null : showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    routeSettings: RouteSettings(name: routeName),
    builder: (BuildContext context) => AccessDialog(resource: resource)
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
    List<String> messageKeys = _AccessContent.getMessageKeys(widget.resource);
    if (messageKeys.isNotEmpty) {
      String titleKey = messageKeys.last.split('.').first;
      String defaultTitle = _AccessContent.defaultStringKey(titleKey);
      String resourceName = Localization().getStringEx('widget.access.${widget.resource}.name', widget.resource);

      return ActionsMessage(
        title: sprintf(Localization().getStringEx('widget.access.$titleKey.title', defaultTitle), [resourceName]),
        titleTextStyle: Styles().textStyles?.getTextStyle('widget.heading.regular.fat'),
        titleBarColor: Styles().colors?.fillColorPrimary,
        bodyWidget: _AccessContent(messageKeys: messageKeys, resourceName: resourceName,),
      );
    }
    return Container();
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == FlexUI.notifyChanged && mounted) {
      if (_AccessContent.mayAccessResource(widget.resource)) {
        Navigator.popUntil(context, (route) {
          return route.settings.name == AccessDialog.routeName;
        });
        Navigator.pop(context);
        return;
      }
      setState(() {});
    }
  }
}

class _AccessContent extends StatelessWidget {
  final List<String> messageKeys;
  final String resourceName;

  const _AccessContent({required this.messageKeys, required this.resourceName});

  @override
  Widget build(BuildContext context) {
    String message = '';
    Widget? button;
    int stepNum = 1;
    for (String messageKey in messageKeys) {
      if (message.isNotEmpty) {
        message += '\n';
      }
      message += '$stepNum. ';

      String ruleType = messageKey.split('.').first;
      dynamic rule = MapPathKey.entry(FlexUI().defaultRules, messageKey);
      switch (ruleType) {
        case 'roles': message += sprintf(Localization().getStringEx('widget.access.$messageKey.unsatisfied.message', '%s is currently only available to ${(rule as List).join(' ')}'), [resourceName]); break;
        case 'privacy': message += Localization().getStringEx('widget.access.$messageKey.unsatisfied.message', 'Update your privacy level to at least ') + rule.toString(); break;
        case 'auth': message += Localization().getStringEx('widget.access.$messageKey.unsatisfied.message', 'Sign in'); break;
      }
      stepNum++;

      if (ruleType != 'roles') {
        button ??= Padding(padding: const EdgeInsets.only(top: 16), child: RoundedButton(
          label: Localization().getStringEx('widget.access.$ruleType.unsatisfied.button.label', ruleType == 'privacy' ? 'Update privacy level' : 'Sign in'),
          borderColor: Styles().colors?.fillColorSecondary,
          backgroundColor: Styles().colors?.surface,
          textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
          onTap: () => _onTapUpdateButton(context, ruleType),
        ));
      }
    }

    // if message only contains one step, strip numbering
    if (stepNum == 2) {
      message = message.substring(3);
    }

    List<Widget> content = [
      Row(children: [Expanded(child:
        Text(message, style: Styles().textStyles?.getTextStyle('widget.description.regular'), semanticsLabel: '',)
      )])
    ];
    if (button != null) {
      content.add(button);
    }
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: content));
  }

  void _onTapUpdateButton(BuildContext context, String ruleType) {
    switch (ruleType) {
      case 'privacy': Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,))); break;
      case 'auth': SettingsHomeContentPanel.present(context, content: SettingsContent.sections); break;
    }
  }

  static bool mayAccessResource(String resource) {
    List<String>? requiredFeatures = JsonUtils.stringListValue(FlexUI()['$resource.features']);
    for (String feature in requiredFeatures ?? []) {
      if (!FlexUI().hasFeature(feature)) {
        return false;
      }
    }
    return true;
  }

  static List<String> getMessageKeys(String resource) {
    List<String> messageKeys = [];
    List<String>? requiredFeatures = JsonUtils.stringListValue(FlexUI()['$resource.features']);
    for (String feature in requiredFeatures ?? []) {
      if (!FlexUI().hasFeature(feature)) {
        for (MapEntry<String, dynamic> ruleCategory in FlexUI().defaultRules.entries) {
          if (ruleCategory.value is Map) {
            dynamic rule = MapPathKey.entry(ruleCategory.value, 'features.$feature');
            if (rule != null) {
              messageKeys.add('${ruleCategory.key}.features.$feature');
              if (ruleCategory.key == 'roles') {
                // roles rule is unsatisfied, so show only roles message
                return messageKeys;
              }
              break;
            }
          }
        }
      }
    }
    return messageKeys;
  }

  static String defaultStringKey(String titleStringRuleKey) {
    switch (titleStringRuleKey) {
      case 'roles': return '%s is unavailable';
      case 'auth': return 'Sign in to access %s';
      case 'privacy': return 'Update privacy level to access %s';
      default: return '%s';
    }
  }
}