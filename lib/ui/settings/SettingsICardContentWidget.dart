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
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/MobileAccess.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class SettingsICardContentWidget extends StatefulWidget {
  @override
  _SettingsICardContentWidgetState createState() => _SettingsICardContentWidgetState();
}

class _SettingsICardContentWidgetState extends State<SettingsICardContentWidget> implements NotificationsListener {
  bool _vibrationEnabled = false;
  bool _soundEnabled = false;

  MobileAccessBleRssiSensitivity? _rssiSensitivity;
  bool _rssiLoading = false;
  
  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      MobileAccess.notifyStartFinished,
    ]);
    MobileAccess().startIfNeeded();
    _loadUnlockVibrationEnabled();
    _loadUnlockSoundEnabled();
    _rssiSensitivity = MobileAccess.bleRssiSensitivityFromString(Storage().mobileAccessBleRssiSensitivity);
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
    if (name == MobileAccess.notifyStartFinished) {
      setStateIfMounted(() { });
    }
    else if (name == FlexUI.notifyChanged) {
      MobileAccess().startIfNeeded();
    }
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
              selected: (MobileAccess().selectedOpenType == MobileAccessOpenType.opened_app),
              onTap: () => _onTapMobileAccessType(MobileAccessOpenType.opened_app)),
          _buildDividerWidget(),
          _buildRadioButtonEntry(
              title: Localization().getStringEx('panel.settings.icard.mobile_access.always.title.label', 'Always'),
              description: Localization().getStringEx('panel.settings.icard.mobile_access.always.description.label',
                  'Open doors regardless of whether app is open or smartphone is unlocked.'),
              selected: (MobileAccess().selectedOpenType == MobileAccessOpenType.always),
              onTap: () => _onTapMobileAccessType(MobileAccessOpenType.always)),
          Padding(
                padding: EdgeInsets.only(top: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Visibility(visible: _isAndroid, child:
                    Padding(padding: EdgeInsets.only(bottom: 16), child:
                      _buildRssiContentWidget(),
                    )
                  ),
                  Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: ToggleRibbonButton(
                          label: Localization().getStringEx('panel.settings.icard.play_sound.button', 'Play sound when unlocking'),
                          toggled: _soundEnabled,
                          border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          onTap: _onTapPlaySound)),
                  Padding(
                      padding: EdgeInsets.zero,
                      child: ToggleRibbonButton(
                          label: Localization().getStringEx('panel.settings.icard.vibrate.button', 'Vibrate when unlocking'),
                          toggled: _vibrationEnabled,
                          border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          onTap: _onTapVibrate)),
                ])),
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

  void _loadUnlockVibrationEnabled() {
    MobileAccess().isUnlockVibrationEnabled().then((enabled) {
      setStateIfMounted(() {
        _vibrationEnabled = enabled;
      });
    });
  }

  void _loadUnlockSoundEnabled() {
    MobileAccess().isUnlockSoundEnabled().then((enabled) {
      setStateIfMounted(() {
        _soundEnabled = enabled;
      });
    });
  }

  void _onTapMobileAccessType(MobileAccessOpenType type) {
    setStateIfMounted(() {
      MobileAccess().selectedOpenType = type;
    });
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
    bool enable = !_soundEnabled;
    MobileAccess().enableUnlockSound(enable).then((success) {
      if (!success) {
        String msg = sprintf(
            Localization().getStringEx('panel.settings.icard.unlock.sound.change.failed.msg',
                'Failed to %s sound when unlocking. Please, try again later.'),
            enable
                ? [Localization().getStringEx('panel.settings.icard.enable.label', 'enable')]
                : [Localization().getStringEx('panel.settings.icard.disable.label', 'disable')]);
        AppAlert.showDialogResult(context, msg);
      } else {
        _loadUnlockSoundEnabled();
      }
    });
  }

  void _onTapVibrate() {
    bool enable = !_vibrationEnabled;
    MobileAccess().enableUnlockVibration(enable).then((success) {
      if (!success) {
        String msg = sprintf(
            Localization().getStringEx('panel.settings.icard.unlock.vibration.change.failed.msg',
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
