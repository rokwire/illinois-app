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

import 'dart:async';

import 'package:connectivity/connectivity.dart' as ConnectivityPlugin;
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';

enum ConnectivityStatus { wifi, mobile, none }

class Connectivity with Service {

  static const String notifyStatusChanged  = "edu.illinois.rokwire.connectivity.status.changed";

  ConnectivityStatus _connectivityStatus;
  StreamSubscription _connectivitySubscription;

  // Singleton Factory

  Connectivity._internal();
  static final Connectivity _instance = Connectivity._internal();

  factory Connectivity() {
    return _instance;
  }

  Connectivity get instance {
    return _instance;
  }

  // Initialization

  @override
  void createService() {
    _connectivitySubscription = ConnectivityPlugin.Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    ConnectivityPlugin.Connectivity().checkConnectivity().then((ConnectivityPlugin.ConnectivityResult result) {
      _setConnectivityStatus(_statusFromResult(result));
    });
  }

  @override
  void destroyService() {
    if (_connectivitySubscription != null) {
      _connectivitySubscription.cancel();
      _connectivitySubscription = null;
    }
  }

  void _onConnectivityChanged(ConnectivityPlugin.ConnectivityResult result) {
    _setConnectivityStatus(_statusFromResult(result));
  }

  void _setConnectivityStatus(ConnectivityStatus status) {
    if (_connectivityStatus != status) {
      _connectivityStatus = status;
      Log.d("Connectivity: ${_connectivityStatus?.toString()}" );
      NotificationService().notify(notifyStatusChanged, null);
    }
  }

  ConnectivityStatus _statusFromResult(ConnectivityPlugin.ConnectivityResult result) {
    switch(result) {
      case ConnectivityPlugin.ConnectivityResult.wifi: return ConnectivityStatus.wifi;
      case ConnectivityPlugin.ConnectivityResult.mobile: return ConnectivityStatus.mobile;
      case ConnectivityPlugin.ConnectivityResult.none: return ConnectivityStatus.none;
    }
    return null;
  }

  // Connectivity

  ConnectivityStatus get status {
    return _connectivityStatus;
  }  

  bool get isOnline {
    return (_connectivityStatus != null) && (_connectivityStatus != ConnectivityStatus.none);
  }

  bool get isOffline {
    return (_connectivityStatus == ConnectivityStatus.none);
  }

  bool get isNotOffline {
    return (_connectivityStatus != ConnectivityStatus.none);
  }

  bool get isDetermined {
    return (_connectivityStatus != null);
  }

}
