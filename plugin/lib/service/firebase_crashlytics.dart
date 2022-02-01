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

import 'package:firebase_crashlytics/firebase_crashlytics.dart' as google;
import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/firebase_core.dart';
import 'package:rokwire_plugin/service/service.dart';

class FirebaseCrashlytics with Service {
  
  // Singletone Factory

  static FirebaseCrashlytics? _instance;

  static FirebaseCrashlytics? get instance => _instance;

  @protected
  static set instance(FirebaseCrashlytics? value) => _instance = value;

  factory FirebaseCrashlytics() => _instance ?? (_instance = FirebaseCrashlytics.internal());

  @protected
  FirebaseCrashlytics.internal();
  
  // Service

  @override
  Future<void> initService() async{

    // Enable automatic data collection
    google.FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Pass all uncaught errors to Firebase.Crashlytics.
    FlutterError.onError = handleFlutterError;

    await super.initService();
  }

  void handleFlutterError(FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    google.FirebaseCrashlytics.instance.recordFlutterError(details);
  }

  void handleZoneError(dynamic exception, StackTrace stack) {
    debugPrint(exception?.toString());
    google.FirebaseCrashlytics.instance.recordError(exception, stack);
  }

  void recordError(dynamic exception, StackTrace? stack) {
    debugPrint(exception?.toString());
    google.FirebaseCrashlytics.instance.recordError(exception, stack);
  }

  void log(String message) {
    google.FirebaseCrashlytics.instance.log(message);
  }

  @override
  Set<Service> get serviceDependsOn => { FirebaseCore() };
}