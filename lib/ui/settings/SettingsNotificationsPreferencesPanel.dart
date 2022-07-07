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
import 'package:illinois/ui/settings/SettingsNotificationsContentPanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/settings/SettingsBluetoothPanel.dart';
import 'package:illinois/ui/settings/SettingsLocationPanel.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

class SettingsNotificationsPreferencesPanel extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.settings.notification_prefferences.label.title", "Notifications Preferences"),
      ),
      body: SingleChildScrollView(child: _buildContent(context)),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent(BuildContext context) {
    return
      Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child:Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(height: 24),
              InfoButton(
                title: Localization().getStringEx("panel.settings.notification_prefferences.button.location.title", "Location"),
                description: Localization().getStringEx("panel.settings.notification_prefferences.button.location.description", "Manage your location settings"),
                iconRes: "images/m.png",
                onTap: (){_onTapLocation(context);},
              ),
              Container(height: 8,),
              InfoButton(
                title: Localization().getStringEx("panel.settings.notification_prefferences.button.notifications.title", "Notifications"),
                description: Localization().getStringEx("panel.settings.notification_prefferences.button.notifications.description", "Customize your notifications"),
                iconRes: "images/notifications-blue.png",
                onTap: (){_onTapNotifications(context);},
              ),
              Container(height: 8,),
              InfoButton(
                title: Localization().getStringEx("panel.settings.notification_prefferences.button.bluetooth.title", "Bluetooth"),
                description: Localization().getStringEx("panel.settings.notification_prefferences.button.bluetooth.description", "Manage your bluetooth settings"),
                iconRes: "images/bluetooth.png",
                onTap: (){_onTapBluetooth(context);},
              ),
            ],));
  }



  void _onTapLocation(BuildContext context) {
    Analytics().logSelect(target: "Location");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsLocationPanel()));
  }

  void _onTapNotifications(BuildContext context) {
    Analytics().logSelect(target: "Notifications");
    SettingsNotificationsContentPanel.present(context, content: SettingsNotificationsContent.preferences);
  }

  void _onTapBluetooth(BuildContext context) {
    Analytics().logSelect(target: "Bluetooth");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsBluetoothPanel()));
  }
}