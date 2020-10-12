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

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Service.dart';

class Crashlytics with Service {
  static final Crashlytics _crashlytics = new Crashlytics._internal();

  factory Crashlytics() {
    return _crashlytics;
  }

  Crashlytics._internal();

  @override
  void createService() {

    // Enable automatic data collection
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Pass all uncaught errors to Firebase.Crashlytics.
    FlutterError.onError = handleFlutterError;
  }

  void handleFlutterError(FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    FirebaseCrashlytics.instance.recordFlutterError(details);
  }

  void handleZoneError(dynamic exception, StackTrace stack) {
    print(exception);
    FirebaseCrashlytics.instance.recordError(exception, stack);
  }

  void recordError(dynamic exception, StackTrace stack) {
    print(exception);
    FirebaseCrashlytics.instance.recordError(exception, stack);
  }

  void log(String message) {
    FirebaseCrashlytics.instance.log(message);
  }
}