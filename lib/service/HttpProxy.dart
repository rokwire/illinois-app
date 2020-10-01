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

import 'package:illinois/service/Config.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/Utils.dart';

class HttpProxy extends Service implements NotificationsListener{
  
  HttpProxy._internal();
  static final HttpProxy _instance = HttpProxy._internal();

  factory HttpProxy() {
    return _instance;
  }

  HttpProxy get instance {
    return _instance;
  }

  @override
  void createService() {
    super.createService();

    NotificationService().subscribe(this, [Config.notifyEnvironmentChanged]);
  }

  @override
  Future<void> initService() {
    _handleChanged();
    return super.initService();
  }

  @override
  void destroyService() {
    super.destroyService();
    NotificationService().unsubscribe(this);
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(),Config()]);
  }

  void onNotification(String name, dynamic param){
    if(name == Config.notifyEnvironmentChanged){
      _handleChanged();
    }
  }


  bool get httpProxyEnabled{
    return Storage().httpProxyEnabled;
  }

  set httpProxyEnabled(bool value){
    if(Storage().httpProxyEnabled != value) {
      Storage().httpProxyEnabled = value;
      _handleChanged();
    }
  }

  String get httpProxyHost{
    return Storage().httpProxyHost;
  }

  set httpProxyHost(String value){
    if(Storage().httpProxyHost != value) {
      Storage().httpProxyHost = value;
      _handleChanged();
    }
  }

  String get httpProxyPort{
    return Storage().httpProxyPort;
  }

  set httpProxyPort(String value){
    if(Storage().httpProxyPort != value) {
      Storage().httpProxyPort = value;
      _handleChanged();
    }
  }

  void _handleChanged(){
    if(httpProxyEnabled &&
        AppString.isStringNotEmpty(httpProxyHost) &&
        AppString.isStringNotEmpty(httpProxyPort) &&
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

  final String host;
  final String port;

  _MyHttpOverrides({this.host, this.port});

  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..findProxy = (uri) {
        return "PROXY $host:$port;";
      }
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}