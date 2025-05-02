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
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/app_datetime.dart' as rokwire;
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AppDateTime extends rokwire.AppDateTime {

  // Singletone Factory
  
  @protected
  AppDateTime.internal() : super.internal();

  factory AppDateTime() => ((rokwire.AppDateTime.instance is AppDateTime) ? (rokwire.AppDateTime.instance as AppDateTime) : (rokwire.AppDateTime.instance = AppDateTime.internal()));

  // Service

  @override

  Set<Service>? get serviceDependsOn {
    Set<Service> dependants = super.serviceDependsOn ?? <Service>{};
    dependants.add(Config());
    return dependants;
  }

  // Overrides

  @protected
  Future<Uint8List?> get timezoneDatabase async {
    ByteData? byteData = await AppBundle.loadBytes('assets/timezone.tzf');
    return byteData?.buffer.asUint8List();
  }

  @protected
  String? get universityLocationName  => Config().timezoneLocation; //TMP: 'Europe/Sofia';

  @protected
  bool get useDeviceLocalTimeZone => (Storage().useDeviceLocalTimeZone == true);

  @override
  DateTime get now  => Storage().offsetDate ?? super.now;
}