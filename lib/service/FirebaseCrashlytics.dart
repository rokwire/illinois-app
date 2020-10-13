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

import 'package:firebase_crashlytics/firebase_crashlytics.dart' as GoogleFirebase;
import 'package:flutter/material.dart';
import 'package:illinois/service/FirebaseService.dart';
import 'package:illinois/service/Service.dart';

class FirebaseCrashlytics with Service {
  static final FirebaseCrashlytics _crashlytics = new FirebaseCrashlytics._internal();

  factory FirebaseCrashlytics() {
    return _crashlytics;
  }

  FirebaseCrashlytics._internal();

  @override
  Future<void> initService() async{
    await super.initService();

    // Enable automatic data collection
    GoogleFirebase.FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Pass all uncaught errors to Firebase.Crashlytics.
    FlutterError.onError = handleFlutterError;
  }

  void handleFlutterError(FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    GoogleFirebase.FirebaseCrashlytics.instance.recordFlutterError(details);
  }

  void handleZoneError(dynamic exception, StackTrace stack) {
    print(exception);
    GoogleFirebase.FirebaseCrashlytics.instance.recordError(exception, stack);
  }

  void recordError(dynamic exception, StackTrace stack) {
    print(exception);
    GoogleFirebase.FirebaseCrashlytics.instance.recordError(exception, stack);
  }

  void log(String message) {
    GoogleFirebase.FirebaseCrashlytics.instance.log(message);
  }

  @override
  Set<Service> get serviceDependsOn =>  Set.from([FirebaseService()]);
}