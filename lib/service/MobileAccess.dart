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
import 'package:illinois/model/Identity.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Identity.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';

class MobileAccess with Service implements NotificationsListener {
  static const String notifyDeviceRegistrationFinished  = "edu.illinois.rokwire.mobile_access.device.registration.finished";

  static const MethodChannel _methodChannel = const MethodChannel('edu.illinois.rokwire/mobile_access');

  static const String _tag = 'MobileAccess';

  late MobileAccessOpenType _selectedOpenType;
  bool _screenUnlocked = true; // When application is started up this means that the device is unlocked
  bool _isScanning = false;

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
    NotificationService()
        .subscribe(this, [AppLivecycle.notifyStateChanged, Auth2.notifyLoginChanged, FlexUI.notifyChanged, Storage.notifySettingChanged]);
  }

  @override
  Future<void> initService() async {
    _selectedOpenType = _openTypeFromString(Storage().mobileAccessOpenType) ?? MobileAccessOpenType.opened_app;
    _shouldScan();
    _checkNeedsRegistration();
    await super.initService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Auth2(), FlexUI(), Storage(), AppLivecycle()]);
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
    _print('Allow scan: $allow');
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('allowScanning', allow);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  void _shouldScan() {
    bool allowScan = _canHaveMobileIcard && _isAllowedToOpenDoors;
    if (_isScanning != allowScan) {
      _allowScanning(allowScan);
    }
  }

  ///
  /// This method uses more prints for debug purposes.
  ///
  void _checkNeedsRegistration() {
    // 1. Check if debug setting is on
    if (Storage().debugUseIdentityBb != true) {
      _print('Use mobile icard native sdk implementation for registration flow.');
      return;
    }
    // 2. Check if user can have mobile card
    if (!_canHaveMobileIcard) {
      _print('User cannot have mobile icard, so do not try to register device.');
      return;
    }
    // 3. Check if the device/endpoint is registered in the sdk
    isEndpointRegistered().then((registered) {
      // 4. Device/endpoint has already been registered - do nothing.
      if (registered) {
        _print('Device has already been registered - do not try to register it again.');
        return;
      }
      // 5. Load mobile identity credential.
      Identity().loadMobileCredential().then((mobileCredential) {
        if (mobileCredential == null) {
          _print('No mobile identity credential available.');
          return;
        }
        UserInvitation? invitation = mobileCredential.lastPendingInvitation;
        if (invitation == null) {
          _print('No mobile identity invitation available.');
          return;
        }
        String? invitationCode = invitation.invitationCode;
        if (invitationCode == null) {
          _print('There is no mobile identity invitation code.');
          return;
        }
        DateTime? expirationDateUtc = invitation.expirationDateUtc;
        // Allow registration if the expiration date is null or is after now
        DateTime nowUtc = DateTime.now().toUtc();
        if ((expirationDateUtc != null) && expirationDateUtc.isBefore(nowUtc)) {
          _print('Mobile identity invitation has been expired.');
          return;
        }
        // 6. Register endpoint / device
        registerEndpoint(invitationCode).then((registrationInitiated) {
          late String resultMsg;
          if (registrationInitiated == true) {
            resultMsg = 'Mobile identity registration initiated successfully.';
            _shouldScan();
          } else {
            resultMsg = 'Failed to initiate mobile identity registration';
          }
          _print(resultMsg);
        });
      });
    });
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case "endpoint.register.finished":
        _onEndpointRegistrationFinished(call.arguments);
        break;
      case "device.screen.unlocked":
        _onScreenUnlocked(call.arguments);
        break;
      case "device.scanning":
        _onScanning(call.arguments);
        break;
      default:
        break;
    }
    return null;
  }

  void _onEndpointRegistrationFinished(dynamic arguments) {
    bool? success = (arguments is bool) ? arguments : null;
    if (success == true) {
      _shouldScan();
    }
    NotificationService().notify(notifyDeviceRegistrationFinished, arguments);
  }

  void _onScreenUnlocked(dynamic arguments) {
    bool screenUnlocked = (arguments is bool) ? arguments : false;
    if (screenUnlocked != _screenUnlocked) {
      _screenUnlocked = screenUnlocked;
      _shouldScan();
    }
  }

  void _onScanning(dynamic arguments) {
    bool scanning = (arguments is bool) ? arguments : false;
    if (_isScanning != scanning) {
      _isScanning = scanning;
    }
  }

  // Open Type

  MobileAccessOpenType get selectedOpenType {
    return _selectedOpenType;
  }

  set selectedOpenType(MobileAccessOpenType openType) {
    if (_selectedOpenType != openType) {
      _selectedOpenType = openType;
      Storage().mobileAccessOpenType = _openTypeToString(_selectedOpenType);
      _shouldScan();
    }
  }

  bool get _canHaveMobileIcard {
    return Auth2().isLoggedIn && FlexUI().isIcardMobileAvailable;
  }

  bool get _isAllowedToOpenDoors {
    if (AppLivecycle().state == AppLifecycleState.detached) {
      // Do not allow scanning / opening doors when app is in detached state
      return false;
    }
    switch (_selectedOpenType) {
      case MobileAccessOpenType.always:
        return true;
      case MobileAccessOpenType.opened_app:
        return (AppLivecycle().state == AppLifecycleState.resumed);
      case MobileAccessOpenType.unlocked_device:
        return _screenUnlocked;
    }
  }

  static MobileAccessOpenType? _openTypeFromString(String? value) {
    switch (value) {
      case 'opened_app':
        return MobileAccessOpenType.opened_app;
      case 'unlocked_device':
        return MobileAccessOpenType.unlocked_device;
      case 'always':
        return MobileAccessOpenType.always;
      default:
        return null;
    }
  }

  static String? _openTypeToString(MobileAccessOpenType? type) {
    switch (type) {
      case MobileAccessOpenType.opened_app:
        return 'opened_app';
      case MobileAccessOpenType.unlocked_device:
        return 'unlocked_device';
      case MobileAccessOpenType.always:
        return 'always';
      default:
        return null;
    }
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
      _shouldScan();
      _checkNeedsRegistration();
    } else if (name == FlexUI.notifyChanged) {
      _shouldScan();
      _checkNeedsRegistration();
    } else if (name == AppLivecycle.notifyStateChanged) {
      AppLifecycleState? state = (param is AppLifecycleState) ? param : null;
      _shouldScan();
      if (state == AppLifecycleState.resumed) {
        _checkNeedsRegistration();
      }
    } else if (name == Storage.notifySettingChanged) {
      if (param == Storage.debugUseIdentityBbKey) {
        _checkNeedsRegistration();
      }
    }
  }

  // Utilities

  void _print(String msg) {
    debugPrint('$_tag: $msg');
  }
}

enum MobileAccessBleRssiSensitivity { high, normal, low }

enum MobileAccessOpenType { opened_app, unlocked_device, always }
