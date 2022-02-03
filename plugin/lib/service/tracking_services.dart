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

import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum TrackingAuthorizationStatus {
  undetermined,
  restricted,
  denied,
  allowed
}

class TrackingServices {

  static Future<TrackingAuthorizationStatus?> queryAuthorizationStatus() async {
    return _trackingAuthorizationFromString(JsonUtils.stringValue(await RokwirePlugin.trackingServices('queryAuthorizationStatus')));
  }

  static Future<TrackingAuthorizationStatus?> requestAuthorization() async {
    return _trackingAuthorizationFromString(JsonUtils.stringValue(await RokwirePlugin.trackingServices('requestAuthorization')));
  }
}

TrackingAuthorizationStatus? _trackingAuthorizationFromString(String? value){
  if("not_determined" == value) {
    return TrackingAuthorizationStatus.undetermined;
  }
  else if("restricted" == value) {
    return TrackingAuthorizationStatus.restricted;
  }
  else if("denied" == value) {
    return TrackingAuthorizationStatus.denied;
  }
  else if("allowed" == value) {
    return TrackingAuthorizationStatus.allowed;
  }
  else {
    return null;
  }
}

