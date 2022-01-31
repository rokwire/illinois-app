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


import 'package:flutter/foundation.dart';

abstract class Service {

  bool? _isInitialized;

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

  Set<Service>? get serviceDependsOn {
    return null;
  }
}

class Services {
  static Services? _instance;
  
  @protected
  Services.internal();
  
  factory Services() {
    return _instance ?? (_instance = Services.internal());
  }

  static Services? get instance => _instance;
  
  @protected
  static set instance(Services? value) => _instance = value;

  List<Service>? _services;

  void create(List<Service> services) {
    if (_services == null) {
      _services = _sort(services);
      for (Service service in _services!) {
        service.createService();
      }
    }
  }

  void destroy() {
    if (_services != null) {
      for (Service service in _services!) {
        service.destroyService();
      }
      _services = null;
    }
  }

  Future<ServiceError?> init() async {

    if (_services != null) {
      for (Service service in _services!) {
        if (service.isInitialized != true) {
          ServiceError? error = await initService(service);
          if (error?.severity == ServiceErrorSeverity.fatal) {
            return error;
          }
        }
      }
    }

    return null;

    /*TMP:
    return ServiceError(
      source: null,
      severity: ServiceErrorSeverity.fatal,
      title: 'Text Initialization Error',
      description: 'This is a test initialization error.',
    );*/
  }

  @protected
  Future<ServiceError?> initService(Service service) async {
    try {
      await service.initService();
    }
    on ServiceError catch (error) {
      return error;
    }
    return null;
  }

  void initUI() {
    if (_services != null) {
      for (Service service in _services!) {
        service.initServiceUI();
      }
    }
  }

  static List<Service> _sort(List<Service> inputServices) {
    
    List<Service> queue = [];
    List<Service> services = List.from(inputServices);
    while (services.isNotEmpty) {
      // start with lowest priority service
      Service svc = services.last;
      services.removeLast();
      
      // Move to TBD anyone from Queue that depends on svc
      Set<Service>? svcDependents = svc.serviceDependsOn;
      if (svcDependents != null) {
        for (int index = queue.length - 1; index >= 0; index--) {
          Service queuedSvc = queue[index];
          if (svcDependents.contains(queuedSvc)) {
            queue.removeAt(index);
            services.add(queuedSvc);
          }
        }
      }

      // Move svc from TBD to Queue, mark it as processed
      queue.add(svc);
    }
    
    return queue.reversed.toList();
  }

}

class ServiceError implements Exception {
  final String? title;
  final String? description;
  final Service? source;
  final ServiceErrorSeverity? severity;

  ServiceError({this.title, this.description, this.source, this.severity});

  @override
  String toString() {
    return "ServiceError: ${source?.runtimeType.toString()}: $title\n$description";
  }

  @override
  bool operator ==(other) =>
    (other is ServiceError) &&
      (other.title == title) &&
      (other.description == description) &&
      (other.source == source) &&
      (other.severity == severity);

  @override
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