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
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';

class MobileAccess with Service {
  static const String notifyDeviceRegistrationFinished  = "edu.illinois.rokwire.mobile_access.device.registration.finished";

  static const MethodChannel _methodChannel = const MethodChannel('edu.illinois.rokwire/mobile_access');

  // Singleton
  static final MobileAccess _instance = MobileAccess._internal();

  MobileAccess._internal();

  factory MobileAccess() {
    return _instance;
  }

  // Initialization

  @override
  void createService() {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
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

  Future<bool> setBleRssiSensitivity(BleRssiSensitivity rssi) async {
    bool result = false;
    try {
      result = await _methodChannel.invokeMethod('setRssiSensitivity', null);
    } catch (e) {
      print(e.toString());
    }
    return result;
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
}

enum BleRssiSensitivity { high, normal, low }
