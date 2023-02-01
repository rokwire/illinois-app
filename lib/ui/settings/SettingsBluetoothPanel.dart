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
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

class SettingsBluetoothPanel extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => _SettingsBluetoothPanelState();
}

class _SettingsBluetoothPanelState extends State<SettingsBluetoothPanel> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.settings.bluetooth.label.title", "Bluetooth"),
      ),
      body: SingleChildScrollView(child: _buildContent()),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: <Widget>[
          Container(height: 24,),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              Localization().getStringEx("panel.settings.bluetooth.label.desctiption", "Create and answer quizzes and polls with people near you."),
              style:  Styles().textStyles?.getTextStyle("widget.description.regular.fat")
          ),),
          Container(height: 24,),
          InfoButton(
            title: Localization().getStringEx("panel.settings.bluetooth.label.desctiption", "Access device's bluetooth"),
            description: _bluetoothStatus,
            additionalInfo: Localization().getStringEx("panel.settings.bluetooth.label.info", "To use Bluetooth enable in your device's settings."),
            iconKey: "bluetooth",
            onTap: _onTapBluetooth(),
          ),
        ],),
      );
  }
  
  _onTapBluetooth(){
    //TBD
  }

  bool get _bluetoothEnabled{
    return false; // tbd
  }
  
  String? get _bluetoothStatus{
      return _bluetoothEnabled?Localization().getStringEx("panel.settings.bluetooth.label.status.enabled", "Enabled"): Localization().getStringEx("panel.settings.bluetooth.label.status.disabled", "Disabled");
  }
}