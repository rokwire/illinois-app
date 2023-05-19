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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';

class MobileAccess with Service implements NotificationsListener {
  static const String notifyDeviceRegistrationFinished  = "edu.illinois.rokwire.mobile_access.device.registration.finished";

  static const MethodChannel _methodChannel = const MethodChannel('edu.illinois.rokwire/mobile_access');

  bool _isAllowedToScan = false;

  // Singleton
  static final MobileAccess _instance = MobileAccess._internal();

  MobileAccess._internal();

  factory MobileAccess() {
    return _instance;
  }

  // Initialization

  @override
  void createService() {
    super.createService();
    _methodChannel.setMethodCallHandler(_handleMethodCall);
    NotificationService().subscribe(this, [AppLivecycle.notifyStateChanged, Auth2.notifyLoginChanged, FlexUI.notifyChanged]);
  }

  @override
  Future<void> initService() async {
    _checkAllowedScanning();
    await super.initService();
  }

  @override
  void destroyService() {
    super.destroyService();
    NotificationService().unsubscribe(this);
  }

  // APIs

  Future<List<dynamic>?> getAvailableKeys() async {
    List<dynamic>? mobileAccessKeys;
    try {
      mobileAccessKeys = await _methodChannel.invokeMethod('availableKeys');
    } catch (e) {
      print(e.toString());
    }
    return mobileAccessKeys;
  }

  Future<bool> registerEndpoint(String invitationCode) async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('registerEndpoint', invitationCode);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<bool> unregisterEndpoint() async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('unregisterEndpoint', null);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<bool> isEndpointRegistered() async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('isEndpointRegistered', null);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<bool> setBleRssiSensitivity(MobileAccessBleRssiSensitivity rssi) async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('setRssiSensitivity', MobileAccess.bleRssiSensitivityToString(rssi));
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<List<int>?> getLockServiceCodes() async {
    List<int>? result;
    try {
      result = await _methodChannel.invokeMethod('getLockServiceCodes', null);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<bool> setLockServiceCodes(List<int> lockServiceCodes) async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('setLockServiceCodes', lockServiceCodes);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<bool> isTwistAndGoEnabled() async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('isTwistAndGoEnabled', null);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<bool> enableTwistAndGo(bool enable) async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('enableTwistAndGo', enable);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<bool> isUnlockVibrationEnabled() async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('isUnlockVibrationEnabled', null);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<bool> enableUnlockVibration(bool enable) async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('enableUnlockVibration', enable);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<bool> isUnlockSoundEnabled() async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('isUnlockSoundEnabled', null);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<bool> enableUnlockSound(bool enable) async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('enableUnlockSound', enable);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<bool> _allowScanning(bool allow) async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('allowScanning', allow);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  void _checkAllowedScanning() {
    _isAllowedToScan = Auth2().isLoggedIn && FlexUI().isIcardMobileAvailable;
    _allowScanning(_isAllowedToScan);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case "endpoint.register.finished":
        _notifyEndpointRegistrationFinished(call.arguments);
        break;
      default:
        break;
    }
    return null;
  }

  void _notifyEndpointRegistrationFinished(dynamic arguments) {
    NotificationService().notify(notifyDeviceRegistrationFinished, arguments);
  }

  // BLE Rssi Sensitivity
  
  static String? bleRssiSensitivityToString(MobileAccessBleRssiSensitivity? sensitivity) {
    switch (sensitivity) {
      case MobileAccessBleRssiSensitivity.high:
        return 'high';
      case MobileAccessBleRssiSensitivity.normal:
        return 'normal';
      case MobileAccessBleRssiSensitivity.low:
        return 'low';
      default:
        return null;
    }
  }

  static MobileAccessBleRssiSensitivity? bleRssiSensitivityFromString(String? value) {
    switch (value) {
      case 'high':
        return MobileAccessBleRssiSensitivity.high;
      case 'normal':
        return MobileAccessBleRssiSensitivity.normal;
      case 'low':
        return MobileAccessBleRssiSensitivity.low;
      default:
        return null;
    }
  }
  
  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      _checkAllowedScanning();
    } else if (name == FlexUI.notifyChanged) {
      _checkAllowedScanning();
    } else if (name == AppLivecycle.notifyStateChanged) {
      AppLifecycleState? state = (param is AppLifecycleState) ? param : null;
      if (state == AppLifecycleState.resumed) {
        _checkAllowedScanning();
      } else {
        _allowScanning(false);
      }
    }
  }
}

enum MobileAccessBleRssiSensitivity { high, normal, low }
