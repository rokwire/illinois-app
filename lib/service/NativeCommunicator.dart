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

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class NativeCommunicator with Service {
  
  final MethodChannel _platformChannel = const MethodChannel('edu.illinois.rokwire/native_call');

  // Singletone
  static final NativeCommunicator _communicator = new NativeCommunicator._internal();

  factory NativeCommunicator() {
    return _communicator;
  }

  NativeCommunicator._internal();

  // Initialization

  @override
  void createService() {
    _platformChannel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  Future<void> initService() async {
    await _nativeInit();
    await super.initService();
  }

  @override
  void destroyService() {
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config()]);
  }

  // NotificationsListener


  Future<void> _nativeInit() async {
    if (kIsWeb) {
      debugPrint('WEB: init - not implemented.');
      return;
    }
    try {
      await _platformChannel.invokeMethod('init', { "config": Config().content });
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<void> dismissLaunchScreen() async {
    if (kIsWeb) {
      debugPrint('WEB: dismissLaunchScreen - not implemented.');
      return;
    }
    try {
      await _platformChannel.invokeMethod('dismissLaunchScreen');
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<void> setLaunchScreenStatus(String? status) async {
    if (kIsWeb) {
      AppToast.showMessage(StringUtils.ensureNotEmpty(status), textColor: Styles().colors.black);
    } else {
      try {
        await _platformChannel.invokeMethod('setLaunchScreenStatus', {'status': status});
      } on PlatformException catch (e) {
        print(e.message);
      }
    }
  }

  Future<List<DeviceOrientation>?> enabledOrientations(List<DeviceOrientation> orientationsList) async {
    if (kIsWeb) {
      debugPrint('WEB: enabledOrientations - not implemented');
      return null;
    }
    List<DeviceOrientation>? result;
    try {
      dynamic inputStringsList = _deviceOrientationListToStringList(orientationsList);
      dynamic outputStringsList = await _platformChannel.invokeMethod('enabledOrientations', { "orientations" : inputStringsList });
      result = _deviceOrientationListFromStringList(outputStringsList);
    } on PlatformException catch (e) {
      print(e.message);
    }
    return result;
  }

  Future<Uint8List?> getBarcodeImageData(Map<String, dynamic> params) async {
    Uint8List? result;
    try {
      String? base64String = await _platformChannel.invokeMethod('barcode', params);
      result = (base64String != null) ? base64Decode(base64String) : null;
    }
    catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<String?> getDeepLinkScheme() async {
    if (kIsWeb) {
      debugPrint('WEB: deepLinkScheme - not implemented.');
      return null;
    }
    String? result;
    try {
      result = await _platformChannel.invokeMethod('deepLinkScheme');
    }
    catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<void> launchTest() async {
    try {
      await _platformChannel.invokeMethod('test');
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case "firebase_message":
        //PS use firebase messaging plugin!
        //FirebaseMessaging().onMessage(call.arguments);
        break;

      default:
        break;
    }
    return null;
  }
}

DeviceOrientation? _deviceOrientationFromString(String value) {
  switch (value) {
    case 'portraitUp': return DeviceOrientation.portraitUp;
    case 'portraitDown': return DeviceOrientation.portraitDown;
    case 'landscapeLeft': return DeviceOrientation.landscapeLeft;
    case 'landscapeRight': return DeviceOrientation.landscapeRight;
  }
  return null;
}

String? _deviceOrientationToString(DeviceOrientation value) {
    switch(value) {
      case DeviceOrientation.portraitUp: return "portraitUp";
      case DeviceOrientation.portraitDown: return "portraitDown";
      case DeviceOrientation.landscapeLeft: return "landscapeLeft";
      case DeviceOrientation.landscapeRight: return "landscapeRight";
    }
}

List<DeviceOrientation>? _deviceOrientationListFromStringList(List<dynamic>? stringsList) {
  
  List<DeviceOrientation>? orientationsList;
  if (stringsList != null) {
    orientationsList = <DeviceOrientation>[];
    for (dynamic string in stringsList) {
      if (string is String) {
        DeviceOrientation? orientation = _deviceOrientationFromString(string);
        if (orientation != null) {
          orientationsList.add(orientation);
        }
      }
    }
  }
  return orientationsList;
}

List<String>? _deviceOrientationListToStringList(List<DeviceOrientation>? orientationsList) {
  
  List<String>? stringsList;
  if (orientationsList != null) {
    stringsList = <String>[];
    for (DeviceOrientation orientation in orientationsList) {
      String? orientationString = _deviceOrientationToString(orientation);
      if (orientationString != null) {
        stringsList.add(orientationString);
      }
    }
  }
  return stringsList;
}
