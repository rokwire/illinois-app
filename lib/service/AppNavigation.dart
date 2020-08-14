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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/NotificationService.dart';

enum AppNavigationEvent { push, pop, remove, replace }

class AppNavigation extends NavigatorObserver {

  static const String notifyEvent  = 'edu.illinois.rokwire.appnavigation.event';

  static const String notifyParamEvent  = 'event';
  static const String notifyParamRoute  = 'route';
  static const String notifyParamPreviousRoute  = 'previous_route';

  // Singletone Instance

  AppNavigation._internal();
  static final AppNavigation _instance = AppNavigation._internal();
  
  factory AppNavigation() {
    return _instance;
  }

  static AppNavigation get instance {
    return _instance;
  }

  @override
  void didPush(Route route, Route previousRoute) {
    NotificationService().notify(notifyEvent, {
      notifyParamEvent: AppNavigationEvent.push,
      notifyParamRoute : route,
      notifyParamPreviousRoute : previousRoute,
    });
  }

  @override
  void didPop(Route route, Route previousRoute) {
    NotificationService().notify(notifyEvent, {
      notifyParamEvent: AppNavigationEvent.pop,
      notifyParamRoute: route,
      notifyParamPreviousRoute: previousRoute,
    });
  }

  @override
  void didRemove(Route route, Route previousRoute) {
      NotificationService().notify(notifyEvent, {
      notifyParamEvent: AppNavigationEvent.remove,
      notifyParamRoute : route,
      notifyParamPreviousRoute : previousRoute,
    });
}

  @override
  void didReplace({Route newRoute, Route oldRoute }) {
      NotificationService().notify(notifyEvent, {
      notifyParamEvent: AppNavigationEvent.replace,
      notifyParamRoute : newRoute,
      notifyParamPreviousRoute : oldRoute,
    });
  }

  static Widget routeRootWidget(Route route, {BuildContext context}) {
    WidgetBuilder builder;
    if (route is CupertinoPageRoute) {
      builder = route.builder;
    }
    else if (route is MaterialPageRoute) {
      builder = route.builder;
    }
    return (builder != null) ? builder(context) : null;
  }
}