
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';

class BluetoothServices with Service implements NotificationsListener {

  static const String notifyStatusChanged  = "edu.illinois.rokwire.bluetoothservices.status.changed";

  BluetoothStatus _status;

  // Singletone Instance

  BluetoothServices._internal();
  static final BluetoothServices _instance = BluetoothServices._internal();
  
  factory BluetoothServices() {
    return _instance;
  }

  static BluetoothServices get instance {
    return _instance;
  }

  // Iniitlaization   

  @override
  void createService() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _status = await _getStatus();
  }

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  // API

  BluetoothStatus get status {
    return _status;
  }

  Future<BluetoothStatus> _getStatus() async {
    if (Platform.isIOS) {
      return _bluetoothStatusFromString(await NativeCommunicator().queryBluetoothAuthorization('query'));
    }
    else {
      return BluetoothStatus.PermissionAllowed;
    }
  }

  void _checkStatus() {
    _getStatus().then((BluetoothStatus status){
      if (_status != status) {
        _status = status;
        NotificationService().notify(notifyStatusChanged, null);
      }
    });
  }

  Future<BluetoothStatus> requestStatus() async {
    if (Platform.isIOS && (_status == BluetoothStatus.PermissionNotDetermined)) {
      BluetoothStatus status = _bluetoothStatusFromString(await NativeCommunicator().queryBluetoothAuthorization('request'));
      if (_status != status) {
        _status = status;
        NotificationService().notify(notifyStatusChanged, null);
      }
    }
    return _status;
  }
}

enum BluetoothStatus {
  PermissionNotDetermined,
  PermissionNotSupported, // iOS Emulator
  PermissionDenied,
  PermissionAllowed
}

BluetoothStatus _bluetoothStatusFromString(String value){
  if("not_determined" == value)
    return BluetoothStatus.PermissionNotDetermined;
  if("not_supported" == value)
    return BluetoothStatus.PermissionNotSupported; // iOS Emulator
  else if("denied" == value)
    return BluetoothStatus.PermissionDenied;
  else if("allowed" == value)
    return BluetoothStatus.PermissionAllowed;
  else
    return null;
}
