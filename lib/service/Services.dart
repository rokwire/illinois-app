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
import 'package:rokwire_plugin/service/service.dart' as rokwire;

class Services extends rokwire.Services {
  
  bool _offlineChecked = false;

  // Singletone Factory
  
  @protected
  Services.internal() : super.internal();

  factory Services() =>  ((rokwire.Services.instance is Services) ? (rokwire.Services.instance as Services) : (rokwire.Services.instance = Services.internal()));

  @override
  Future<rokwire.ServiceError?> initService(rokwire.Service service) async {
    
    if ((_offlineChecked != true) && Storage().isInitialized && Connectivity().isInitialized) {
      if ((Storage().lastRunVersion == null) && Connectivity().isOffline) {
        return rokwire.ServiceError(
          source: null,
          severity: rokwire.ServiceErrorSeverity.fatal,
          title: 'Initialization Failed',
          description: 'You must be online when you start this product for first time.',
        );
      }
      else {
        _offlineChecked = true;
      }
    }

    if (kDebugMode) {
      await NativeCommunicator().setLaunchScreenStatus(service.debugDisplayName);
    }

    rokwire.ServiceError? error;
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
