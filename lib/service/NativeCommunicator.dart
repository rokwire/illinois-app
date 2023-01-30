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

import 'package:flutter/services.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class NativeCommunicator with Service {
  
  static const String notifyMapSelectExplore  = "edu.illinois.rokwire.nativecommunicator.map.explore.select";
  static const String notifyMapSelectLocation   = "edu.illinois.rokwire.nativecommunicator.map.location.select";
  
  static const String notifyMapRouteStart  = "edu.illinois.rokwire.nativecommunicator.map.route.start";
  static const String notifyMapRouteFinish = "edu.illinois.rokwire.nativecommunicator.map.route.finish";
  
  static const String notifyMapSelectPOI  = "edu.illinois.rokwire.nativecommunicator.map.poi.select";

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
    try {
      await _platformChannel.invokeMethod('init', { "config": Config().content });
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<void> launchExploreMapDirections({dynamic target, Map<String, dynamic>? options}) async {
    dynamic jsonData;
    try {
      if (target != null) {
        if (target is List) {
          jsonData = [];
          for (dynamic entry in target) {
            jsonData.add(entry.toJson());
          }
        }
        else {
          jsonData = target.toJson();
        }
      }
    } on PlatformException catch (e) {
      print(e.message);
    }
    
    if (jsonData != null) {
      await launchMapDirections(jsonData: jsonData, options: options);
    }
  }

  Future<void> launchMapDirections({dynamic jsonData, Map<String, dynamic>? options}) async {
    try {
      String? lastPageName = Analytics().currentPageName;
      Map<String, dynamic>? lastPageAttributes = Analytics().currentPageAttributes;
      Analytics().logPage(name: 'MapDirections');
      Analytics().logMapShow();

      Map<String, dynamic> optionsParam = {
        'showDebugLocation': Storage().debugMapLocationProvider,
        'enableLevels': Storage().debugMapShowLevels,
      };
      if (options != null) {
        optionsParam.addAll(options);
      }
      
      await _platformChannel.invokeMethod('directions', {
        'explore': jsonData,
        'options': optionsParam
      });

      Analytics().logMapHide();
      Analytics().logPage(name: lastPageName, attributes: lastPageAttributes);
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<String?> launchSelectLocation({dynamic explore}) async {
    try {

      String? lastPageName = Analytics().currentPageName;
      Map<String, dynamic>? lastPageAttributes = Analytics().currentPageAttributes;
      Analytics().logPage(name: 'MapSelectLocation');
      Analytics().logMapShow();

      dynamic jsonData = (explore != null) ? explore.toJson() : null;
      String? result = await _platformChannel.invokeMethod('pickLocation', {"explore": jsonData});

      Analytics().logMapHide();
      Analytics().logPage(name: lastPageName, attributes: lastPageAttributes);
      return result;

    } on PlatformException catch (e) {
      print(e.message);
    }

    return null;
  }

  Future<void> launchMap({dynamic target, dynamic markers}) async {
    try {
      String? lastPageName = Analytics().currentPageName;
      Map<String, dynamic>? lastPageAttributes = Analytics().currentPageAttributes;
      Analytics().logPage(name: 'Map');
      Analytics().logMapShow();

      await _platformChannel.invokeMethod('map', {
        'target': target,
        'options': {
          'showDebugLocation': Storage().debugMapLocationProvider,
        },
        'markers': markers,
      });

      Analytics().logMapHide();
      Analytics().logPage(name: lastPageName, attributes: lastPageAttributes);

    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<void> dismissLaunchScreen() async {
    try {
      await _platformChannel.invokeMethod('dismissLaunchScreen');
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<void> setLaunchScreenStatus(String? status) async {
    try {
      await _platformChannel.invokeMethod('setLaunchScreenStatus', {
        'status': status
      });
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<List<DeviceOrientation>?> enabledOrientations(List<DeviceOrientation> orientationsList) async {
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

  Future<List<dynamic>?> getMobileAccessKeys() async {
    List<dynamic>? mobileAccessKeys;
    try {
      mobileAccessKeys = await _platformChannel.invokeMethod('mobileAccessKeys');
    } catch (e) {
      print(e.toString());
    }
    return mobileAccessKeys;
  }

  Future<bool> mobileAccessKeysEndpointSetup(String invitationCode) async {
    bool result = false;
    try {
      result = await _platformChannel.invokeMethod('mobileAccessKeysEndpointSetup', invitationCode);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<String?> getDeepLinkScheme() async {
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
      case "map.explore.select":
        _notifyMapSelectExplore(call.arguments);
        break;
      case "map.poi.select":
        _notifyMapSelectPOI(call.arguments);
        break;
      case "map.location.select":
        _notifyMapLocationSelect(call.arguments);
        break;
      
      case "map.route.start":
        _notifyMapRouteStart(call.arguments);
        break;
      case "map.route.finish":
        _notifyMapRouteFinish(call.arguments);
        break;
      

      case "firebase_message":
        //PS use firebase messaging plugin!
        //FirebaseMessaging().onMessage(call.arguments);
        break;

      default:
        break;
    }
    return null;
  }

  void _notifyMapSelectExplore(dynamic arguments) {
    NotificationService().notify(notifyMapSelectExplore, (arguments is String) ? JsonUtils.decodeMap(arguments) : null);
  }
  
  void _notifyMapLocationSelect(dynamic arguments) {
    NotificationService().notify(notifyMapSelectLocation, (arguments is String) ? JsonUtils.decodeMap(arguments) : null);
  }

  void _notifyMapSelectPOI(dynamic arguments) {
    NotificationService().notify(notifyMapSelectPOI, (arguments is String) ? JsonUtils.decodeMap(arguments) : null);
  }

  void _notifyMapRouteStart(dynamic arguments) {
    NotificationService().notify(notifyMapRouteStart, (arguments is String) ? JsonUtils.decodeMap(arguments) : null);
  }

  void _notifyMapRouteFinish(dynamic arguments) {
    NotificationService().notify(notifyMapRouteFinish, (arguments is String) ? JsonUtils.decodeMap(arguments) : null);
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
