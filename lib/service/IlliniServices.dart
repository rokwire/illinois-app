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
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/service.dart';

class IlliniServices extends Services {
  
  // Singletone Factory
  
  @protected
  IlliniServices.internal() : super.internal();

  factory IlliniServices() {
    return ((Services.instance is IlliniServices) ? (Services.instance as IlliniServices) : (Services.instance = IlliniServices.internal()));
  }

  bool _offlineChecked = false;

  @override
  Future<ServiceError?> initService(Service service) async {
    
    if ((_offlineChecked != true) && Storage().isInitialized && Connectivity().isInitialized) {
      if ((Storage().lastRunVersion == null) && Connectivity().isOffline) {
        return ServiceError(
          source: null,
          severity: ServiceErrorSeverity.fatal,
          title: 'Initialization Failed',
          description: 'You must be online when you start this product for first time.',
        );
      }
      else {
        _offlineChecked = true;
      }
    }

    if (kDebugMode) {
      await NativeCommunicator().setLaunchScreenStatus(service.runtimeType.toString());
    }

    ServiceError? error;
    try { error = await super.initService(service); }
    catch(e) { print(e.toString()); }

    if (error != null) {
      print(error.toString());
    }
  
    if (kDebugMode) {
      await NativeCommunicator().setLaunchScreenStatus(null);
    }

    return error;
  }

}
