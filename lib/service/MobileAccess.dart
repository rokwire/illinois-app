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
import 'package:rokwire_plugin/utils/utils.dart';

class MobileAccess with Service implements NotificationsListener {
  static const String notifyStartFinished  = "edu.illinois.rokwire.mobile_access.start.finished";
  static const String notifyDeviceRegistrationFinished  = "edu.illinois.rokwire.mobile_access.device.registration.finished";
  static const String notifyMobileStudentIdChanged  = "edu.illinois.rokwire.mobile_access.student_id.changed";

  static const MethodChannel _methodChannel = const MethodChannel('edu.illinois.rokwire/mobile_access');

  static const String _tag = 'MobileAccess';

  late MobileAccessOpenType _selectedOpenType;
  StudentId? _lastStudentId;
  bool _isStarted = false;
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
        .subscribe(this, [AppLivecycle.notifyStateChanged, Auth2.notifyLoginChanged, Storage.notifySettingChanged]);
  }

  @override
  Future<void> initService() async {
    _selectedOpenType = _openTypeFromString(Storage().mobileAccessOpenType) ?? MobileAccessOpenType.opened_app;
    await loadStudentId();
    _startSilently();
    _shouldScan();
    if (Storage().debugAutomaticCredentials == true) {
      requestDeviceRegistration();
    }
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

  // Accessories

  bool get isMobileAccessAvailable => ((_lastMobileIdStatus != null) && (_lastMobileIdStatus != MobileIdStatus.ineligible));

  bool get isMobileAccessPending => (_lastMobileIdStatus == MobileIdStatus.pending);

  bool get isMobileAccessIssuing => (_lastMobileIdStatus == MobileIdStatus.issuing);

  bool get isMobileAccessWaiting => (isMobileAccessPending || isMobileAccessIssuing);

  bool get canRenewMobileId => (_lastStudentId?.canRenewMobileId == true);

  MobileIdStatus? get _lastMobileIdStatus => _lastStudentId?.mobileIdStatus;

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
    return Auth2().isLoggedIn && isMobileAccessAvailable;
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
    }
  }

  bool get isStarted => _isStarted;

  bool get canStart => isMobileAccessAvailable;

  // APIs

  Future<bool> startIfNeeded() async =>
    isStarted || (canStart && await _start(force: true));

  Future<bool> _startSilently() async =>
    isStarted || (canStart && await _start(force: false));

  Future<bool> _start({ required bool force }) async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('start', force);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

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
    try {
      return JsonUtils.listIntsValue(await _methodChannel.invokeMethod('getLockServiceCodes', null));
    } catch (e) {
      print(e.toString());
    }
    return null;
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
    bool allowScan = _canHaveMobileIcard && _isAllowedToOpenDoors && _isStarted;
    if (_isScanning != allowScan) {
      _allowScanning(allowScan);
    }
  }

  Future<StudentId?> loadStudentId() async {
    if (!Auth2().isLoggedIn) {
      _onStudentId(null);
      return null;
    }
    StudentId? studentId = await Identity().loadStudentId();
    _onStudentId(studentId);
    return studentId;
  }

  Future<StudentId?> renewMobileId() async {
    if (!Auth2().isLoggedIn) {
      _onStudentId(null);
      return null;
    }
    StudentId? studentId = await Identity().renewMobileId();
    _onStudentId(studentId);
    return studentId;
  }

  void _onStudentId(StudentId? studentId) {
    if (studentId != _lastStudentId) {
      _lastStudentId = studentId;
      NotificationService().notify(notifyMobileStudentIdChanged);
    }
  }

  ///
  /// Initiate device registration via Identity BB API
  ///
  /// This method uses more prints for debug purposes.
  ///
  /// returns MobileAccessRequestDeviceRegistrationError if there is an error, null - otherwise
  ///
  Future<MobileAccessRequestDeviceRegistrationError?> requestDeviceRegistration() async {
    // 1. Check if debug setting is on
    if (Storage().debugUseIdentityBb != true) {
      _print('Use mobile icard native sdk implementation for registration flow.');
      return MobileAccessRequestDeviceRegistrationError.not_using_bb;
    }
    // 2. Check if user can have mobile card
    if (!_canHaveMobileIcard) {
      _print('User cannot have mobile icard (not signed in or not a member of a group), so do not try to register device.');
      return MobileAccessRequestDeviceRegistrationError.icard_not_allowed;
    }

    // 3. Load mobile credential
    MobileCredential? mobileCredential = await Identity().loadMobileCredential();
    if (mobileCredential == null) {
      _print('No mobile identity credential available.');
      return MobileAccessRequestDeviceRegistrationError.no_mobile_credential;
    }

    // 4. Get last pending invitation
    UserInvitation? invitation = mobileCredential.lastPendingInvitation;
    if (invitation == null) {
      _print('No mobile identity invitation available.');
      return MobileAccessRequestDeviceRegistrationError.no_pending_invitation;
    }

    // 5. Get the invitation code from the last pending invitation
    String? invitationCode = invitation.invitationCode;
    if (invitationCode == null) {
      _print('There is no mobile identity invitation code.');
      return MobileAccessRequestDeviceRegistrationError.no_invitation_code;
    }

    // 6. Allow registration if the expiration date is null or is after now
    DateTime? expirationDateUtc = invitation.expirationDateUtc;
    DateTime nowUtc = DateTime.now().toUtc();
    if ((expirationDateUtc != null) && expirationDateUtc.isBefore(nowUtc)) {
      _print('Mobile identity invitation has been expired.');
      return MobileAccessRequestDeviceRegistrationError.invitation_code_expired;
    }
    // 7. Check if the device/endpoint is registered in the sdk
    bool registered = await isEndpointRegistered();
    if (registered) {
      _print('Device has already been registered - do not try to register it again.');
      return MobileAccessRequestDeviceRegistrationError.device_already_registered;
    }

    // 8. Initiate endpoint registration
    bool? registrationInitiated = await registerEndpoint(invitationCode);
    if (registrationInitiated == true) {
      _print('Mobile identity registration initiated successfully.');
      _shouldScan();
      return null;
    } else {
      // result = Localization().getStringEx('key8', 'Failed to initiate device registration.');
      _print('Failed to initiate mobile identity registration');
      return MobileAccessRequestDeviceRegistrationError.registration_initiation_failed;
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case "start.finished":
        _onStartFinished(call.arguments);
        break;
      case "endpoint.register.finished":
        _onEndpointRegistrationFinished(call.arguments);
        break;
      case "device.scanning":
        _onScanning(call.arguments);
        break;
      default:
        break;
    }
    return null;
  }

  void _onStartFinished(dynamic arguments) {
    bool? success = (arguments is bool) ? arguments : null;
    if (success == true) {
      _isStarted = true;
      NotificationService().notify(notifyStartFinished);
      _shouldScan();
    }
  }

  void _onEndpointRegistrationFinished(dynamic arguments) {
    bool? success = (arguments is bool) ? arguments : null;
    if (success == true) {
      _shouldScan();
    }
    NotificationService().notify(notifyDeviceRegistrationFinished, arguments);
  }

  void _onScanning(dynamic arguments) {
    bool scanning = (arguments is bool) ? arguments : false;
    if (_isScanning != scanning) {
      _isScanning = scanning;
    }
  }

  // Open Type

  static MobileAccessOpenType? _openTypeFromString(String? value) {
    switch (value) {
      case 'opened_app':
        return MobileAccessOpenType.opened_app;
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
      loadStudentId().then((_) {
        _shouldScan();
      });
    } else if (name == AppLivecycle.notifyStateChanged) {
      _shouldScan();
    }
  }

  // Utilities

  void _print(String msg) {
    debugPrint('$_tag: $msg');
  }
}

enum MobileAccessBleRssiSensitivity { high, normal, low }

enum MobileAccessOpenType { opened_app, always }

enum MobileAccessRequestDeviceRegistrationError {
  not_using_bb,
  icard_not_allowed,
  device_already_registered,
  no_mobile_credential,
  no_pending_invitation,
  no_invitation_code,
  invitation_code_expired,
  registration_initiation_failed
}
