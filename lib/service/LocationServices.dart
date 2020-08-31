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

import 'package:flutter/widgets.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:location/location.dart';

enum LocationServicesStatus {
  ServiceDisabled,
  PermissionNotDetermined,
  PermissionDenied,
  PermissionAllowed
}

class LocationServices with Service implements NotificationsListener {

  static const String notifyStatusChanged  = "edu.illinois.rokwire.locationservices.status.changed";
  static const String notifyLocationChanged  = "edu.illinois.rokwire.locationservices.location.changed";

  LocationServicesStatus _lastStatus;
  LocationData _lastLocation;
  StreamSubscription<LocationData> _locationMonitor;

  // Singletone Instance

  LocationServices._internal();
  static final LocationServices _instance = LocationServices._internal();
  
  factory LocationServices() {
    return _instance;
  }

  static LocationServices get instance {
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
    _closeLocationMonitor();
  }

  @override
  Future<void> initService() async {
    this.status.then((_){});
  }

  Future<LocationServicesStatus> get status async {

    if (!await Location().serviceEnabled()) {
      _lastStatus = LocationServicesStatus.ServiceDisabled;
    }
    else if (!Storage().locationServicesPermisionRequested) {
      _lastStatus = LocationServicesStatus.PermissionNotDetermined;
    }
    else {
      _lastStatus = await Location().hasPermission() == PermissionStatus.granted ? LocationServicesStatus.PermissionAllowed : LocationServicesStatus.PermissionDenied;
    }

    _updateLocationMonitor();
    return _lastStatus;
  }

  Future<LocationServicesStatus> requestService() async {
    
    if (!await Location().serviceEnabled()) {
      if (!await Location().requestService()) {
        _lastStatus = LocationServicesStatus.ServiceDisabled;
      }
      else {
        _lastStatus = await this.status;
        _notifyStatusChanged();
      }
    }
    else {
      _lastStatus = await this.status;
    }

    _updateLocationMonitor();
    return status;
  }

  Future<LocationServicesStatus> requestPermission() async {

    if (!await Location().serviceEnabled()) {
      _lastStatus = LocationServicesStatus.ServiceDisabled;
    }
    else if (Storage().locationServicesPermisionRequested) {
      _lastStatus = await Location().hasPermission() == PermissionStatus.granted ? LocationServicesStatus.PermissionAllowed : LocationServicesStatus.PermissionDenied;
    }
    else {
      _lastStatus = _locationServicesStatusFromString(await NativeCommunicator().queryLocationServicesPermission('request'));
      Storage().locationServicesPermisionRequested = true;
      _notifyStatusChanged();
    }

    _updateLocationMonitor();
    return _lastStatus;
  }

  Future<LocationData> get location async {
    return (await this.status == LocationServicesStatus.PermissionAllowed) ? await Location().getLocation() : null;
  }

  // Location Monitor

  LocationData get lastLocation {
    return _lastLocation;
  }

  void _updateLocationMonitor() {

    if ((_lastStatus == LocationServicesStatus.PermissionAllowed) && (_locationMonitor == null)) {
      _openLocationMonitor();
    }
    else if ((_lastStatus != LocationServicesStatus.PermissionAllowed) && (_locationMonitor != null)) {
      _closeLocationMonitor();
    }
  }

  void _openLocationMonitor() {
    if (_locationMonitor == null) {
      _locationMonitor = Location().onLocationChanged.listen((LocationData location) {
        _lastLocation = location;
        _notifyLocationChanged();
      });
    }
  }

  void _closeLocationMonitor() {
    if (_locationMonitor != null) {
      _locationMonitor.cancel();
      _locationMonitor = null;
    }
  }

  // Helpers

  void _notifyStatusChanged() {
    NotificationService().notify(notifyStatusChanged, _lastStatus);
  }

  void _notifyLocationChanged() {
    NotificationService().notify(notifyLocationChanged, _lastLocation);
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
      LocationServicesStatus lastStatus = _lastStatus;
      this.status.then((_) {
        if (lastStatus != _lastStatus) {
          _notifyStatusChanged();
        }
      });

    }
    else if (state == AppLifecycleState.paused) {
      this.status.then((_) {
      });
    }
  }
}


LocationServicesStatus _locationServicesStatusFromString(String value) {
  if (value == 'disabled') {
    return LocationServicesStatus.ServiceDisabled;
  } else if (value == 'not_determined') {
    return LocationServicesStatus.PermissionNotDetermined;
  } else if (value == 'denied') {
    return LocationServicesStatus.PermissionDenied;
  } else if (value == 'allowed') {
    return LocationServicesStatus.PermissionAllowed;
  }
  else {
    return null;
  }
}
