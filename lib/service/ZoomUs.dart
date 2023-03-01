/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ZoomUs /* with Service */ {
  static const MethodChannel _methodChannel = const MethodChannel('edu.illinois.rokwire/zoom_us');

  // Singleton
  static final ZoomUs _instance = ZoomUs._internal();

  ZoomUs._internal();

  factory ZoomUs() {
    return _instance;
  }

  // APIs

  Future<String?> test() async {
    try {
      return await _methodChannel.invokeMethod('test') as String;
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }
}
