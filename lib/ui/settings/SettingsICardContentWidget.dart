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
import 'package:illinois/service/MobileAccess.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class SettingsICardContentWidget extends StatefulWidget {
  @override
  _SettingsICardContentWidgetState createState() => _SettingsICardContentWidgetState();
}

class _SettingsICardContentWidgetState extends State<SettingsICardContentWidget> {
  bool _twistAndGoEnabled = false;
  bool _twistAndGoLoading = false;

  bool _vibrationEnabled = false;

  MobileAccessBleRssiSensitivity? _rssiSensitivity;
  bool _rssiLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadTwistAndGoEnabled();
    _loadUnlockVibrationEnabled();
    _rssiSensitivity = MobileAccess.bleRssiSensitivityFromString(Storage().mobileAccessBleRssiSensitivity);
  }

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
                    _buildRssiContentWidget(),
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
                            toggled: _vibrationEnabled,
                            border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            onTap: _onTapVibrate)),
                  ]))),
          Padding(padding: EdgeInsets.only(top: 16), child: _buildTwistAndGoWidget()),
          Visibility(visible: _isAndroid, child: Padding(padding: EdgeInsets.only(top: 16), child: _buildNotificationDrawerWidget())),
          Visibility(visible: _isIOS, child: Padding(padding: EdgeInsets.only(top: 16), child: _buildOpenIOSSystemSettingsWidget()))
        ]));
  }

  Widget _buildRssiContentWidget() {
    return Stack(alignment: Alignment.center, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(Localization().getStringEx('panel.settings.icard.bluetooth.sensitivity.label', 'Bluetooth sensitivity'),
            style: Styles().textStyles?.getTextStyle('widget.message.regular.fat')),
        _buildRadioButtonEntry(
            title: Localization().getStringEx('panel.settings.icard.bluetooth.sensitivity.high.label', 'High'),
            onTap: () => _onTapBluetoothSensitivity(MobileAccessBleRssiSensitivity.high),
            selected: (_rssiSensitivity == MobileAccessBleRssiSensitivity.high)),
        _buildDividerWidget(),
        _buildRadioButtonEntry(
            title: Localization().getStringEx('panel.settings.icard.bluetooth.sensitivity.normal.label', 'Normal'),
            onTap: () => _onTapBluetoothSensitivity(MobileAccessBleRssiSensitivity.normal),
            selected: (_rssiSensitivity == null) || (_rssiSensitivity == MobileAccessBleRssiSensitivity.normal)),
        _buildDividerWidget(),
        _buildRadioButtonEntry(
            title: Localization().getStringEx('panel.settings.icard.bluetooth.sensitivity.low.label', 'Low'),
            onTap: () => _onTapBluetoothSensitivity(MobileAccessBleRssiSensitivity.low),
            selected: (_rssiSensitivity == MobileAccessBleRssiSensitivity.low)),
      ]),
      Visibility(visible: _rssiLoading, child: CircularProgressIndicator(color: Styles().colors!.fillColorSecondary))
    ]);
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
    return Stack(alignment: Alignment.center, children: [
      InkWell(
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
                              child: Styles().images?.getImage(_twistAndGoEnabled ? 'toggle-on' : 'toggle-off'))
                        ]))))
          ])),
      Visibility(visible: _twistAndGoLoading, child: CircularProgressIndicator(color: Styles().colors!.fillColorSecondary))
    ]);
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

  void _loadTwistAndGoEnabled() {
    setStateIfMounted(() {
      _twistAndGoLoading = true;
    });
    MobileAccess().isTwistAndGoEnabled().then((enabled) {
      setStateIfMounted(() {
        _twistAndGoEnabled = enabled;
        _twistAndGoLoading = false;
      });
    });
  }

  void _enableTwistAndGo(bool enable) {
    if (_twistAndGoEnabled == enable) {
      return;
    }
    setStateIfMounted(() {
      _twistAndGoLoading = true;
    });
    MobileAccess().enableTwistAndGo(enable).then((success) {
      setStateIfMounted(() {
        _twistAndGoLoading = false;
      });
      if (!success) {
        String msg = sprintf(
            Localization()
                .getStringEx('panel.settings.icard.twist_n_go.change.failed.msg', 'Failed to %s Twist And Go. Please, try again later.'),
            enable
                ? [Localization().getStringEx('panel.settings.icard.enable.label', 'enable')]
                : [Localization().getStringEx('panel.settings.icard.disable.label', 'disable')]);
        AppAlert.showDialogResult(context, msg);
      } else {
        _loadTwistAndGoEnabled();
      }
    });
  }

  void _loadUnlockVibrationEnabled() {
    MobileAccess().isUnlockVibrationEnabled().then((enabled) {
      setStateIfMounted(() {
        _vibrationEnabled = enabled;
      });
    });
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

  void _onTapBluetoothSensitivity(MobileAccessBleRssiSensitivity rssiSensitivity) {
    if ((_rssiLoading) || (_rssiSensitivity == rssiSensitivity)) {
      return;
    }
    setStateIfMounted(() {
      _rssiLoading = true;
    });
    MobileAccess().setBleRssiSensitivity(rssiSensitivity).then((success) {
      if (success) {
        _rssiSensitivity = rssiSensitivity;
        Storage().mobileAccessBleRssiSensitivity = MobileAccess.bleRssiSensitivityToString(_rssiSensitivity);
      }
      if (!success) {
        AppAlert.showDialogResult(
            context,
            Localization().getStringEx(
                'panel.settings.icard.rssi.change.failed.msg', 'Failed to change Bluetooth sensitivity.'));
      }
      setStateIfMounted(() {
        _rssiLoading = false;
      });
    });
  }

  void _onTapPlaySound() {
    //TBD: DD - implement
  }

  void _onTapVibrate() {
    bool enable = !_vibrationEnabled;
    MobileAccess().enableUnlockVibration(enable).then((success) {
      if (!success) {
        String msg = sprintf(
            Localization().getStringEx('panel.settings.icard.unlock_vibration.change.failed.msg',
                'Failed to %s vibration when unlocking. Please, try again later.'),
            enable
                ? [Localization().getStringEx('panel.settings.icard.enable.label', 'enable')]
                : [Localization().getStringEx('panel.settings.icard.disable.label', 'disable')]);
        AppAlert.showDialogResult(context, msg);
      } else {
        _loadUnlockVibrationEnabled();
      }
    });
  }

  void _onTapTwistAndGo() {
    if (_twistAndGoLoading) {
      return;
    }
    _enableTwistAndGo(!_twistAndGoEnabled);
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
