/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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

import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SettingsICardContentWidget extends StatefulWidget {
  @override
  _SettingsICardContentWidgetState createState() => _SettingsICardContentWidgetState();
}

class _SettingsICardContentWidgetState extends State<SettingsICardContentWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(16),
        color: Styles().colors?.background,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(Localization().getStringEx('panel.settings.icard.mobile_access.label', 'Allow mobile access when'),
              style: Styles().textStyles?.getTextStyle('widget.message.regular.fat')),
          _buildRadioButtonEntry(
              title: Localization().getStringEx('panel.settings.icard.mobile_access.opened_app.title.label', 'App is open'),
              description: Localization()
                  .getStringEx('panel.settings.icard.mobile_access.opened_app.description.label', 'Open doors only when app is open.'),
              onTap: _onTapOpenedApp),
          _buildDividerWidget(),
          _buildRadioButtonEntry(
              title: Localization().getStringEx('panel.settings.icard.mobile_access.unlocked_device.title.label', 'Device is unlocked'),
              description: Localization().getStringEx(
                  'panel.settings.icard.mobile_access.unlocked_device.description.label', 'Open doors only when smartphone is unlocked.'),
              onTap: _onTapUnlockedDevice),
          _buildDividerWidget(),
          _buildRadioButtonEntry(
              title: Localization().getStringEx('panel.settings.icard.mobile_access.always.title.label', 'Always'),
              description: Localization().getStringEx('panel.settings.icard.mobile_access.always.description.label',
                  'Open doors regardless of whether app is open or smartphone is unlocked.'),
              onTap: _onTapAlways,
              selected: true),
          Visibility(
              visible: _isAndroid,
              child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Localization().getStringEx('panel.settings.icard.bluetooth.sensitivity.label', 'Bluetooth sensitivity'),
                        style: Styles().textStyles?.getTextStyle('widget.message.regular.fat')),
                    _buildRadioButtonEntry(
                        title: Localization().getStringEx('panel.settings.icard.bluetooth.sensitivity.high.label', 'High'),
                        onTap: () => _onTapBluetoothSensitivity(_BluetoothSensitivity.high)),
                    _buildDividerWidget(),
                    _buildRadioButtonEntry(
                        title: Localization().getStringEx('panel.settings.icard.bluetooth.sensitivity.normal.label', 'Normal'),
                        onTap: () => _onTapBluetoothSensitivity(_BluetoothSensitivity.normal),
                        selected: true),
                    _buildDividerWidget(),
                    _buildRadioButtonEntry(
                        title: Localization().getStringEx('panel.settings.icard.bluetooth.sensitivity.low.label', 'Low'),
                        onTap: () => _onTapBluetoothSensitivity(_BluetoothSensitivity.low)),
                    Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: ToggleRibbonButton(
                            label: Localization().getStringEx('panel.settings.icard.play_sound.button', 'Play sound when unlocking'),
                            toggled: false, //TBD: DD - implement
                            border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            onTap: _onTapPlaySound)),
                    Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: ToggleRibbonButton(
                            label: Localization().getStringEx('panel.settings.icard.vibrate.button', 'Vibrate when unlocking'),
                            toggled: true, //TBD: DD - implement
                            border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            onTap: _onTapVibrate))
                  ]))),
          Padding(padding: EdgeInsets.only(top: 16), child: _buildTwistAndGoWidget()),
          Visibility(visible: _isAndroid, child: Padding(padding: EdgeInsets.only(top: 16), child: _buildNotificationDrawerWidget())),
          Visibility(visible: _isIOS, child: Padding(padding: EdgeInsets.only(top: 16), child: _buildOpenIOSSystemSettingsWidget()))
        ]));
  }

  Widget _buildRadioButtonEntry({required String title, String? description, bool? selected, void Function()? onTap}) {
    return InkWell(
        onTap: onTap,
        child: Padding(
            padding: EdgeInsets.only(left: 16, top: 10, bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: Styles().textStyles?.getTextStyle('widget.message.regular.fat'), overflow: TextOverflow.ellipsis, maxLines: 2),
                Visibility(
                    visible: StringUtils.isNotEmpty(description),
                    child: Text(StringUtils.ensureNotEmpty(description),
                        style: Styles().textStyles?.getTextStyle('widget.message.light.regular'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 4))
              ])),
              Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Styles().images?.getImage((selected == true) ? 'radio-button-on' : 'radio-button-off'))
            ])));
  }

  Widget _buildDividerWidget() {
    return Padding(padding: EdgeInsets.only(left: 16), child: Divider(color: Styles().colors?.mediumGray, height: 1));
  }

  Widget _buildTwistAndGoWidget() {
    bool twistAndGoToggled = false; //TBD: DD - implement
    return InkWell(
        onTap: _onTapTwistAndGo,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
              child: Container(
                  decoration: BoxDecoration(
                      color: Styles().colors?.white,
                      border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(Localization().getStringEx('panel.settings.icard.twist_n_go.title.label', 'Twist And Go'),
                              style: Styles().textStyles?.getTextStyle('panel.settings.toggle_button.title.small.enabled')),
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                                Localization().getStringEx('panel.settings.icard.twist_n_go.description.label',
                                    'Rotate your mobile device 90\u00B0 to the right and left, as if turning a door knob.'),
                                maxLines: 4,
                                style: Styles().textStyles?.getTextStyle('panel.settings.toggle_button.title.small.variant.enabled')),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                                Localization().getStringEx('panel.settings.icard.twist_n_go.description2.label',
                                    'Doors must be enabled for Twist and Go to work.'),
                                maxLines: 4,
                                style: Styles().textStyles?.getTextStyle('panel.settings.toggle_button.title.small.variant.disabled')),
                          )
                        ])),
                        Padding(
                            padding: EdgeInsets.only(left: 16),
                            // ignore: dead_code
                            child: Styles().images?.getImage(twistAndGoToggled ? 'toggle-on' : 'toggle-off'))
                      ]))))
        ]));
  }

  Widget _buildOpenIOSSystemSettingsWidget() {
    return InkWell(
        onTap: _onTapIOSSystemSettings,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
              child: Container(
                  decoration: BoxDecoration(
                      color: Styles().colors?.white,
                      border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(Localization().getStringEx('panel.settings.icard.ios_settings.title.label', 'Open System Settings'),
                              style: Styles().textStyles?.getTextStyle('panel.settings.toggle_button.title.small.enabled')),
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                                Localization()
                                    .getStringEx('panel.settings.icard.ios_settings.description.label',
                                        'Return to the {{app_title}} app by tapping the return arrow at top of the page.')
                                    .replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
                                maxLines: 4,
                                style: Styles().textStyles?.getTextStyle('panel.settings.toggle_button.title.small.variant.enabled')),
                          )
                        ])),
                        Padding(padding: EdgeInsets.only(left: 16), child: Styles().images?.getImage('chevron-right'))
                      ]))))
        ]));
  }

  Widget _buildNotificationDrawerWidget() {
    bool notificationDrawerSelected = false; //TBD: DD - implement
    return InkWell(
        onTap: _onTapNotificationDrawer,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
              child: Container(
                  decoration: BoxDecoration(
                      color: Styles().colors?.white,
                      border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(Localization().getStringEx('panel.settings.icard.notification_drawer.title.label', 'Notification ???'),
                              style: Styles().textStyles?.getTextStyle('panel.settings.toggle_button.title.small.enabled')),
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                                Localization().getStringEx(
                                    'panel.settings.icard.notification_drawer.description.label', 'Unlock doors from notification drawer.'),
                                maxLines: 4,
                                style: Styles().textStyles?.getTextStyle('panel.settings.toggle_button.title.small.variant.enabled')),
                          )
                        ])),
                        Padding(
                            padding: EdgeInsets.only(left: 16),
                            // ignore: dead_code
                            child: Styles().images?.getImage(notificationDrawerSelected ? 'toggle-on' : 'toggle-off'))
                      ]))))
        ]));
  }

  void _onTapOpenedApp() {
    //TBD: DD - implement
  }

  void _onTapUnlockedDevice() {
    //TBD: DD - implement
  }

  void _onTapAlways() {
    //TBD: DD - implement
  }

  void _onTapBluetoothSensitivity(_BluetoothSensitivity sensitivity) {
    //TBD: DD - implement
  }

  void _onTapPlaySound() {
    //TBD: DD - implement
  }

  void _onTapVibrate() {
    //TBD: DD - implement
  }

  void _onTapTwistAndGo() {
    //TBD: DD - implement
  }

  void _onTapNotificationDrawer() {
    //TBD: DD - implement
  }

  void _onTapIOSSystemSettings() {
    Analytics().logSelect(target: 'Open System Settings');
    AppSettings.openAppSettings();
  }

  bool get _isAndroid {
    return Platform.isAndroid;
  }

  bool get _isIOS {
    return Platform.isIOS;
  }
}

enum _BluetoothSensitivity { high, normal, low }
