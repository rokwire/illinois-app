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

import 'package:connectivity/connectivity.dart' as connectivity;
import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';

enum ConnectivityStatus { wifi, mobile, none }

class Connectivity with Service {

  static const String notifyStatusChanged  = "edu.illinois.rokwire.connectivity.status.changed";

  ConnectivityStatus? _connectivityStatus;
  StreamSubscription? _connectivitySubscription;

  // Singleton Factory

  static Connectivity? _instance;

  static Connectivity? get instance => _instance;

  @protected
  static set instance(Connectivity? value) => _instance = value;

  factory Connectivity() => _instance ?? (_instance = Connectivity.internal());

  @protected
  Connectivity.internal();

  // Service

  @override
  void createService() {
    _connectivitySubscription = connectivity.Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  @override
  Future<void> initService() async {
    _connectivityStatus = _statusFromResult(await connectivity.Connectivity().checkConnectivity());

    if (_connectivityStatus != null) {
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'Connectivity Initialization Failed',
        description: 'Failed to retrieve connectivity status.',
      );
    }
  }

  @override
  void destroyService() {
    _connectivitySubscription?.cancel();
  }

  void _onConnectivityChanged(connectivity.ConnectivityResult result) {
    _setConnectivityStatus(_statusFromResult(result));
  }

  void _setConnectivityStatus(ConnectivityStatus? status) {
    if (_connectivityStatus != status) {
      _connectivityStatus = status;
      Log.d("Connectivity: ${_connectivityStatus?.toString()}" );
      NotificationService().notify(notifyStatusChanged, null);
    }
  }

  ConnectivityStatus? _statusFromResult(connectivity.ConnectivityResult? result) {
    switch(result) {
      case connectivity.ConnectivityResult.wifi: return ConnectivityStatus.wifi;
      case connectivity.ConnectivityResult.mobile: return ConnectivityStatus.mobile;
      case connectivity.ConnectivityResult.none: return ConnectivityStatus.none;
      default: break;
    }
    return null;
  }

  // Connectivity

  ConnectivityStatus? get status {
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
