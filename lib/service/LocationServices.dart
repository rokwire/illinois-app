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
import 'package:geolocator/geolocator.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:rokwire_plugin/service/service.dart';

enum LocationServicesStatus {
  ServiceDisabled,
  PermissionNotDetermined,
  PermissionDenied,
  PermissionAllowed
}

class LocationServices with Service implements NotificationsListener {

  static const String notifyStatusChanged  = "edu.illinois.rokwire.locationservices.status.changed";
  static const String notifyLocationChanged  = "edu.illinois.rokwire.locationservices.location.changed";

  LocationServicesStatus? _lastStatus;
  Position? _lastLocation;
  StreamSubscription<Position>? _locationMonitor;

  // Singletone Instance

  LocationServices._internal();
  static final LocationServices _instance = LocationServices._internal();
  
  factory LocationServices() {
    return _instance;
  }

  static LocationServices get instance {
    return _instance;
  }

  // Initialization

  @override
  void createService() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    _locationMonitor?.cancel();
    _locationMonitor = null;
  }

  @override
  Future<void> initService() async {
    _lastStatus = await this.status;
    
    if (_lastStatus != null) {
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'Location Services Initialization Failed',
        description: 'Failed to retrieve location services status.',
      );
    }
  }

  Future<LocationServicesStatus?> get status async {
    _lastStatus = _locationServicesStatusFromString(await NativeCommunicator().queryLocationServicesPermission('query'));
    _updateLocationMonitor();
    return _lastStatus;
  }

  Future<LocationServicesStatus?> requestService() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    }

    _lastStatus = await this.status;
    _updateLocationMonitor();
    return _lastStatus;
  }

  Future<LocationServicesStatus?> requestPermission() async {
    _lastStatus = await this.status;
    if (_lastStatus == LocationServicesStatus.PermissionNotDetermined) {
      _lastStatus = _locationServicesStatusFromString(await NativeCommunicator().queryLocationServicesPermission('request'));
      _notifyStatusChanged();
    }

    _updateLocationMonitor();
    return _lastStatus;
  }

  Future<Position?> get location async {
    return (await this.status == LocationServicesStatus.PermissionAllowed) ? await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high) : null;
  }

  // Location Monitor

  Position? get lastLocation {
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
      try {
        final LocationSettings locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 100);
        _locationMonitor = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
          _lastLocation = position;
          _notifyLocationChanged();
        },
        onError: (e) {
          print(e?.toString());  
        });
      }
      catch(e) {
        print(e.toString());
      }
    }
  }

  void _closeLocationMonitor() {
    if (_locationMonitor != null) {
      _locationMonitor!.cancel();
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

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.resumed) {
      LocationServicesStatus? lastStatus = _lastStatus;
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


LocationServicesStatus? _locationServicesStatusFromString(String? value) {
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
