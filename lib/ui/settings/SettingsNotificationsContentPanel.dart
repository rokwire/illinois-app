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
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';

//TODO: implement
class SettingsNotificationsContentPanel extends StatefulWidget {

  @override
  _SettingsNotificationsContentPanelState createState() => _SettingsNotificationsContentPanelState();
}

class _SettingsNotificationsContentPanelState extends State<SettingsNotificationsContentPanel> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: 'Notifications'),
        body: Container(child: Text('TBD implement')),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar());
  }

}
