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


import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class IlliniAppDateTime extends AppDateTime {

  // Singletone Factory
  
  @protected
  IlliniAppDateTime.internal() : super.internal();

  factory IlliniAppDateTime() {
    return ((AppDateTime.instance is IlliniAppDateTime) ? (AppDateTime.instance as IlliniAppDateTime) : (AppDateTime.instance = IlliniAppDateTime.internal()));
  }

  @protected
  Future<Uint8List?> get timezoneDatabase async {
    ByteData? byteData = await AppBundle.loadBytes('assets/timezone2019a.tzf');
    return byteData?.buffer.asUint8List();
  }

  @protected
  String? get universityLocationName  => 'America/Chicago';

  @protected
  bool get useDeviceLocalTimeZone => (Storage().useDeviceLocalTimeZone == true);

  @override
  DateTime get now  => Storage().offsetDate ?? super.now;
}