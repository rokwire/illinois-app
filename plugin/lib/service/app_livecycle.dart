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
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';

typedef AppLifecycleCallback = void Function(AppLifecycleState state);

class AppLivecycleWidgetsBindingObserver extends WidgetsBindingObserver {
  final AppLifecycleCallback? onAppLivecycleChange;
  AppLivecycleWidgetsBindingObserver({this.onAppLivecycleChange});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (onAppLivecycleChange != null) {
      onAppLivecycleChange!(state);
    }
  }
}

class AppLivecycle with Service {

  static const String notifyStateChanged  = "edu.illinois.rokwire.applivecycle.state.changed";

  WidgetsBindingObserver? _bindingObserver;
  AppLifecycleState _state = AppLifecycleState.resumed; // initial value
  AppLifecycleState get state => _state;

  // Singletone Factory

  static AppLivecycle? _instance;

  static AppLivecycle? get instance => _instance;

  @protected
  static set instance(AppLivecycle? value) => _instance = value;

  factory AppLivecycle() => _instance ?? (_instance = AppLivecycle.internal());

  @protected
  AppLivecycle.internal();
  
  // Service

  @override
  void createService() {
    _initBinding();
  }

  @override
  void destroyService() {
    _closeBinding();
  }

  @override
  void initServiceUI() {
    _initBinding();
  }

  void _initBinding() {
    if ((WidgetsBinding.instance != null) && (_bindingObserver == null)) {
      _bindingObserver = AppLivecycleWidgetsBindingObserver(onAppLivecycleChange:_onAppLivecycleChangeState);
      WidgetsBinding.instance!.addObserver(_bindingObserver!);
    }
  }

  void _closeBinding() {
    if ((WidgetsBinding.instance != null) && (_bindingObserver != null)) {
      WidgetsBinding.instance!.removeObserver(_bindingObserver!);
      _bindingObserver = null;
    }
  }

  void _onAppLivecycleChangeState(AppLifecycleState state) {
    _state = state;
    NotificationService().notify(notifyStateChanged, state);
  }
}