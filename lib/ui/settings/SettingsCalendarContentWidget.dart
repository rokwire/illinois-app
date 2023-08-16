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
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/flex_ui.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';

class SettingsCalendarContentWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsCalendarContentWidgetState();
}

class _SettingsCalendarContentWidgetState extends State<SettingsCalendarContentWidget> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [AppLivecycle.notifyStateChanged]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.resumed)) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['calendar'] ?? [];
    for (String code in codes) {
      if (code == 'settings') {
        contentList.addAll(_buildCalendarSettings());
      }
    }

    if (contentList.isNotEmpty) {
      contentList.insert(0, Container(height: 8));
      contentList.add(Container(height: 16));
    }

    return Container(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList));
  }

  List<Widget> _buildCalendarSettings() {
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['calendar.settings'] ?? [];
    for (String code in codes) {
      if (code == 'enable') {
        contentList.add(Container(height: 4));
        contentList.add(ToggleRibbonButton(
            label: Localization().getStringEx('panel.settings.home.calendar.settings.enable.label', 'Allow saving to calendar'),
            border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4)),
            textStyle: (Storage().calendarEnabledToSave == true) ? Styles().textStyles?.getTextStyle("widget.message.regular.fat") :   Styles().textStyles?.getTextStyle("widget.message.regular.fat.accent"),
            toggled: Storage().calendarEnabledToSave ?? false,
            onTap: _onEnable));
      } else if (code == 'auto_save') {
        contentList.add(Container(height: 4));
        contentList.add(ToggleRibbonButton(
            label: Localization().getStringEx('panel.settings.home.calendar.settings.add_events.label', 'Add saved events to calendar'),
            border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4)),
            textStyle: (Storage().calendarEnabledToSave == true) ? Styles().textStyles?.getTextStyle("widget.message.regular.fat") :   Styles().textStyles?.getTextStyle("widget.message.regular.fat.accent"),
            toggled: Storage().calendarEnabledToSave == true && Storage().calendarEnabledToAutoSave == true,
            onTap: _onAutoSave));
      } else if (code == 'prompt') {
        contentList.add(Container(height: 4));
        contentList.add(ToggleRibbonButton(
            label: Localization().getStringEx('panel.settings.home.calendar.settings.prompt.label', 'Prompt when saving events to calendar'),
            border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4)),
            textStyle: (Storage().calendarEnabledToSave == true) ? Styles().textStyles?.getTextStyle("widget.message.regular.fat") :   Styles().textStyles?.getTextStyle("widget.message.regular.fat.accent"),
            toggled: Storage().calendarEnabledToSave == true && Storage().calendarCanPrompt == true,
            onTap: _onPrompt));
      }
    }

    if (contentList.isNotEmpty) {
      contentList.insertAll(0, <Widget>[
        Container(height: 16),
        Row(children: [
          Expanded(
              child: Text('Calendar',
                  style:  Styles().textStyles?.getTextStyle("widget.detail.regular.fat")))
        ])
      ]);
    }
    return contentList;
  }

  void _onEnable() {
    Analytics().logSelect(target: 'Add saved events to calendar');
    setState(() {
      Storage().calendarEnabledToSave = !Storage().calendarEnabledToSave!;
    });
  }

  void _onAutoSave() {
    Analytics().logSelect(target: 'Add saved events to calendar');
    setState(() {
      Storage().calendarEnabledToAutoSave = !Storage().calendarEnabledToAutoSave!;
    });
  }

  void _onPrompt() {
    Analytics().logSelect(target: 'Prompt when saving events to calendar');
    if (Storage().calendarEnabledToSave == true) {
      setState(() {
        Storage().calendarCanPrompt = (Storage().calendarCanPrompt != true);
      });
    }
  }
}
