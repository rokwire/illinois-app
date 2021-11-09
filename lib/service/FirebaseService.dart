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

import 'package:firebase_core/firebase_core.dart';
import 'package:illinois/service/Service.dart';

class FirebaseService extends Service{

  static final FirebaseService _service = FirebaseService._internal();
  FirebaseService._internal();
  factory FirebaseService() {
    return _service;
  }

  FirebaseApp _firebaseApp;

  @override
  Future<ServiceError> initService() async{
    await initFirebase();
    return (_firebaseApp == null) ? ServiceError(
      source: this,
      severity: ServiceErrorSeverity.nonFatal,
      title: 'Firebase initialization failed',
      description: 'Failed to initialize Firebase application.',
    ) : null;
  }

  Future<void> initFirebase() async{
    if(_firebaseApp == null) {
      _firebaseApp = await Firebase.initializeApp();
    }
  }
}