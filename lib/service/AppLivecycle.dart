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

import 'package:flutter/widgets.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';

typedef AppLifecycleCallback = void Function(AppLifecycleState state);

class AppLivecycleWidgetsBindingObserver extends WidgetsBindingObserver {
  final AppLifecycleCallback onAppLivecycleChange;
  AppLivecycleWidgetsBindingObserver({this.onAppLivecycleChange});

  @override
  Future<Null> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (onAppLivecycleChange != null) {
      onAppLivecycleChange(state);
    }
  }
}

class AppLivecycle with Service {

  static const String notifyStateChanged  = "edu.illinois.rokwire.applivecycle.state.changed";

  WidgetsBindingObserver _bindingObserver;
  AppLifecycleState _state;

  // Singletone Instance

  AppLivecycle._internal();
  static final AppLivecycle _instance = AppLivecycle._internal();
  
  factory AppLivecycle() {
    return _instance;
  }

  static AppLivecycle get instance {
    return _instance;
  }

  AppLifecycleState get state {
    return _state;
  }

  // Initialization

  @override
  void createService() {
    _initBinding();
  }

  @override
  void destroyService() {
    _closeBinding();
  }

  void ensureBinding() {
    _initBinding();
  }

  void _initBinding() {
    if ((WidgetsBinding.instance != null) && (_bindingObserver == null)) {
      _bindingObserver = new AppLivecycleWidgetsBindingObserver(onAppLivecycleChange:_onAppLivecycleChangeState);
      WidgetsBinding.instance.addObserver(_bindingObserver);
    }
  }

  void _closeBinding() {
    if (_bindingObserver != null) {
      WidgetsBinding.instance.removeObserver(_bindingObserver);
      _bindingObserver = null;
    }
  }

  void _onAppLivecycleChangeState(AppLifecycleState state) {
    _state = state;
    NotificationService().notify(notifyStateChanged, state);
  }
}