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


import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Assets.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/BluetoothServices.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Connectivity.dart';
import 'package:illinois/service/DeviceCalendar.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/FirebaseCrashlytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/DiningService.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FirebaseService.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/GeoFence.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/HttpProxy.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/service/Inbox.dart';
import 'package:illinois/service/LiveStats.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/LocationServices.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Onboarding.dart';
import 'package:illinois/service/Polls.dart';
import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/StudentGuide.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/service/Voter.dart';

abstract class Service {

  bool _isInitialized;

  void createService() {
  }

  void destroyService() {
  }

  Future<void> initService() async {
    _isInitialized = true;
  }

  void initServiceUI() async {
  }

  bool get isInitialized => _isInitialized ?? false;

  Set<Service> get serviceDependsOn {
    return null;
  }
}

class Services {
  static final Services _instance = Services._internal();
  
  factory Services() {
    return _instance;
  }

  Services._internal();
  
  static Services get instance {
    return _instance;
  }

  List<Service> _services = [
    // Add highest priority services at top

    FirebaseService(),
    FirebaseCrashlytics(),
    AppLivecycle(),
    AppDateTime(),
    Connectivity(),
    LocationServices(),
    BluetoothServices(),
    DeepLink(),

    Storage(),
    HttpProxy(),

    Config(),
    NativeCommunicator(),

    Auth2(),
    Localization(),
    Assets(),
    Styles(),
    Analytics(),
    FirebaseMessaging(),
    Sports(),
    LiveStats(),
    RecentItems(),
    DiningService(),
    IlliniCash(),
    FlexUI(),
    Onboarding(),
    Polls(),
    GeoFence(),
    Voter(),
    StudentGuide(),
    Inbox(),
    DeviceCalendar(),
    ExploreService(),
    Groups()
    // These do not rely on Service initialization API so they are not registered as services.
    // LaundryService(),
    // Content(),
  ];

  void create() {
    _sort();
    for (Service service in _services) {
      service.createService();
    }
  }

  void destroy() {
    for (Service service in _services) {
      service.destroyService();
    }
  }

  Future<ServiceError> init() async {
    bool offlineChecked = false;
    for (Service service in _services) {

      if (service.isInitialized != true) {
        try { await service.initService(); }
        on ServiceError catch (error) {
          print(error?.toString());
          if (error?.severity == ServiceErrorSeverity.fatal) {
            return error;
          }
        }
        catch(e) {
          print(e?.toString());
        }
      }

      if ((offlineChecked != true) && Storage().isInitialized && Connectivity().isInitialized) {
        if ((Storage().lastRunVersion == null) && Connectivity().isOffline) {
          return ServiceError(
            source: null,
            severity: ServiceErrorSeverity.fatal,
            title: 'Initialization Failed',
            description: 'You must be online when you start this product for first time.',
          );
        }
        else {
          offlineChecked = true;
        }
      }
    }

    /*TMP:
    return ServiceError(
      source: null,
      severity: ServiceErrorSeverity.fatal,
      title: 'Text Initialization Error',
      description: 'This is a test initialization error.',
    );*/
    return null;
  }

  void initUI() {
    for (Service service in _services) {
      service.initServiceUI();
    }
  }

  void _sort() {
    
    List<Service> queue = [];
    while (_services.isNotEmpty) {
      // start with lowest priority service
      Service svc = _services.last;
      _services.removeLast();
      
      // Move to TBD anyone from Queue that depends on svc
      Set<Service> svcDependents = svc.serviceDependsOn;
      if (svcDependents != null) {
        for (int index = queue.length - 1; index >= 0; index--) {
          Service queuedSvc = queue[index];
          if (svcDependents.contains(queuedSvc)) {
            queue.removeAt(index);
            _services.add(queuedSvc);
          }
        }
      }

      // Move svc from TBD to Queue, mark it as processed
      queue.add(svc);
    }
    
    _services = queue.reversed.toList();
  }

}

class ServiceError {
  final String title;
  final String description;
  final Service source;
  final ServiceErrorSeverity severity;

  ServiceError({this.title, this.description, this.source, this.severity});

  String toString() {
    return "ServiceError: ${source?.runtimeType?.toString()}: $title\n$description";
  }

  bool operator ==(o) =>
    (o is ServiceError) &&
      (o.title == title) &&
      (o.description == description) &&
      (o.source == source) &&
      (o.severity == severity);

  int get hashCode =>
    (title?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (source?.hashCode ?? 0) ^
    (severity?.hashCode ?? 0);
}

enum ServiceErrorSeverity {
  fatal,
  nonFatal
}