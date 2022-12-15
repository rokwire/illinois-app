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

  const AccessCard({required this.resource,});

  static AccessCard? builder({required String resource}) => _AccessContent.mayAccessResource(resource) ? null : AccessCard(resource: resource);

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
    String titleRuleKey = _AccessContent.titleStringRuleKey(widget.resource) ?? '';
    String defaultTitle = _AccessContent.defaultStringKey(titleRuleKey);

    return Padding(padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0), child:
      Container(
        decoration: BoxDecoration(color: Styles().colors!.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
        child: Column(children: <Widget>[
          Row(children: <Widget>[
            Expanded(child:
              Padding(padding: EdgeInsets.only(top: 16, left: 16, right: 16), child:
                Text(sprintf(Localization().getStringEx('widget.access.$titleRuleKey.title', defaultTitle), [Localization().getStringEx('widget.access.${widget.resource}.name', widget.resource)]),
                  style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary), semanticsLabel: '',
                )
              ),
            )
          ]),
          _AccessContent(resource: widget.resource,),
        ])
      )
    );
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
    String titleRuleKey = _AccessContent.titleStringRuleKey(widget.resource) ?? '';
    String defaultTitle = _AccessContent.defaultStringKey(titleRuleKey);
    
    return ActionsMessage(
      title: sprintf(Localization().getStringEx('widget.access.$titleRuleKey.title', defaultTitle), [Localization().getStringEx('widget.access.${widget.resource}.name', widget.resource)]),
      titleTextStyle: Styles().textStyles?.getTextStyle('widget.heading.regular.fat'),
      titleBarColor: Styles().colors?.fillColorPrimary,
      bodyWidget: _AccessContent(resource: widget.resource),
    );
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
  static const List<String> rulePriority = ['roles', 'privacy', 'auth'];
  static const Map<String, String> authRuleStringKeys = {
    'loggedIn': 'widget.access.auth.login.message',
    'shibbolethLoggedIn': 'widget.access.auth.netid.login.message',
    'phoneLoggedIn': 'widget.access.auth.phone.login.message',
    'emailLoggedIn': 'widget.access.auth.email.login.message',
    'shibbolethLinked': 'widget.access.auth.netid.linked.message',
    'phoneLinked': 'widget.access.auth.phone.linked.message',
    'emailLinked': 'widget.access.auth.email.linked.message',
  };

  final String resource;

  const _AccessContent({required this.resource});

  @override
  Widget build(BuildContext context) {
    List<String>? features = JsonUtils.stringListValue(FlexUI()[resource]);

    String message = '';
    Widget? button;
    int stepNum = 1;
    for (String ruleType in rulePriority) {
      if (features?.contains('${ruleType}_access') == false) {
        if (message.isNotEmpty) {
          message += '\n';
        }

        dynamic unsatisfied = MapPathKey.entry(FlexUI().defaultRules, '$ruleType.$resource.${ruleType}_access') ?? MapPathKey.entry(FlexUI().defaultRules, '$ruleType.${ruleType}_access');
        message += '$stepNum. ';
        if (unsatisfied is Map) {
          String authKey = unsatisfied.keys.first;
          message += Localization().getStringEx(authRuleStringKeys[authKey] ?? 'widget.access.auth.login.message', 'Sign in');
        } else if (unsatisfied is List) {
          message += Localization().getStringEx('widget.access.$resource.roles.unsatisfied.message', 'You must be ${unsatisfied.join(' ')}');
        } else {
          message += Localization().getStringEx('widget.access.privacy.unsatisfied.message', 'Update your privacy level to at least ') + unsatisfied.toString();
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
        } else {
          // roles rule is unsatisfied, so show only roles message with no action button
          break;
        }
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
    List<String>? features = JsonUtils.stringListValue(FlexUI()[resource]);
    return ListUtils.contains(features, ['roles_access', 'privacy_access', 'auth_access'], checkAll: true) ?? true;
  }

  static String? titleStringRuleKey(String resource) {
    List<String>? features = JsonUtils.stringListValue(FlexUI()[resource]);
    if (features?.contains('roles_access') == false) {
      return 'roles';
    }
    if (features?.contains('auth_access') == false) {
      return 'auth';
    }
    if (features?.contains('privacy_access') == false) {
      return 'privacy';
    }
    return null;
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