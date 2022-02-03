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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HttpProxy extends Service implements NotificationsListener {
  
  // Singletone Factory

  static HttpProxy? _instance;

  static HttpProxy? get instance => _instance;
  
  @protected
  static set instance(HttpProxy? value) => _instance = value;

  factory HttpProxy() => _instance ?? (_instance = HttpProxy.internal());

  @protected
  HttpProxy.internal();

  // Service

  @override
  void createService() {
    super.createService();

    NotificationService().subscribe(this, [Config.notifyEnvironmentChanged]);
  }

  @override
  Future<void> initService() async {
    _handleChanged();
    await super.initService();
  }

  @override
  void destroyService() {
    super.destroyService();
    NotificationService().unsubscribe(this);
  }

  @override
  Set<Service> get serviceDependsOn {
    return {Storage(), Config()};
  }

  @override
  void onNotification(String name, dynamic param){
    if(name == Config.notifyEnvironmentChanged){
      _handleChanged();
    }
  }


  bool? get httpProxyEnabled{
    return Storage().httpProxyEnabled;
  }

  set httpProxyEnabled(bool? value){
    if(Storage().httpProxyEnabled != value) {
      Storage().httpProxyEnabled = value;
      _handleChanged();
    }
  }

  String? get httpProxyHost{
    return Storage().httpProxyHost;
  }

  set httpProxyHost(String? value){
    if(Storage().httpProxyHost != value) {
      Storage().httpProxyHost = value;
      _handleChanged();
    }
  }

  String? get httpProxyPort{
    return Storage().httpProxyPort;
  }

  set httpProxyPort(String? value){
    if(Storage().httpProxyPort != value) {
      Storage().httpProxyPort = value;
      _handleChanged();
    }
  }

  void _handleChanged(){
    if((httpProxyEnabled == true) &&
        StringUtils.isNotEmpty(httpProxyHost) &&
        StringUtils.isNotEmpty(httpProxyPort) &&
        Config().configEnvironment == ConfigEnvironment.dev
    ){
      HttpOverrides.global = _MyHttpOverrides(host: httpProxyHost, port: httpProxyPort);
    }
    else{
      HttpOverrides.global = null;
    }
  }
}

class _MyHttpOverrides extends HttpOverrides {

  final String? host;
  final String? port;

  _MyHttpOverrides({this.host, this.port});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = (uri) {
        return "PROXY $host:$port;";
      }
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}