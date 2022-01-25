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

import 'dart:collection';
import 'dart:core';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as Http;

import 'package:illinois/model/GeoFence.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:illinois/service/Assets.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class GeoFence with Service implements NotificationsListener {

  static const String notifyCurrentRegionsUpdated  = "edu.illinois.rokwire.geofence.regions.current.updated";
  static const String notifyCurrentBeaconsUpdated  = "edu.illinois.rokwire.geofence.beacons.current.updated";
  
  static const String _geoFenceName   = "geoFence.json";

  static const String _currentRegionsName = "currentRegions";
  static const String _monitorRegionsName = "monitorRegions";

  static const String _startRangingBeaconsInRegionName = "startRangingBeaconsInRegion";
  static const String _stopRangingBeaconsInRegionName = "stopRangingBeaconsInRegion";
  static const String _beaconsInRegionName = "beaconsInRegion";

  static const String _enterRegionName = "onEnterRegion";
  static const String _exitRegionName = "onExitRegion";
  static const String _currentRegionsChangedName = "onCurrentRegionsChanged";
  static const String _beaconsInRegionChangedName = "onBeaconsInRegionChanged";

  static const MethodChannel _channel = const MethodChannel('edu.illinois.rokwire/geoFence');

  static const bool _useAssets = false;

  LinkedHashMap<String, GeoFenceRegion>? _regions;
  Set<String> _currentRegions = Set();
  Map<String, List<GeoFenceBeacon>> _currentBeacons = Map();

  File?      _cacheFile;
  DateTime? _pausedDateTime;

  static final GeoFence _service = GeoFence._internal();
  GeoFence._internal() {
    _channel.setMethodCallHandler(this._handleChannelCall);
  }

  factory GeoFence() {
    return _service;
  }

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Storage.notifySettingChanged,
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _cacheFile = await _getCacheFile();

    _regions = _useAssets ? _loadRegionsFromAssets() : await _loadRegionsFromCache();
    if (_regions != null) {
      _updateRegions();
    }
    else {
      String? jsonString = await _loadRegionsStringFromNet();
      _regions = _regionsFromJsonString(jsonString);
      if (_regions != null) {
        _saveRegionsStringToCache(jsonString);
      }      
    }
    
    _monitorRegions();
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config(), Auth2(), Assets()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Storage.notifySettingChanged) {
      if (param == Storage.debugGeoFenceRegionRadiusKey) {
        _monitorRegions();
      }
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateRegions();
        }
      }
    }
  }

  // Accessories

  LinkedHashMap<String, GeoFenceRegion>? get regions {
    return _regions;
  }

  Set<String> get currentRegionIds {
    return _currentRegions;
  }

  List<GeoFenceRegion> regionsList({String? type, bool? enabled, GeoFenceRegionType? regionType, bool? inside}) {
    List<GeoFenceRegion> regions = [];
    if (_regions != null) {
      _regions!.forEach((String? regionId, GeoFenceRegion? region){
        if ((region != null) &&
            ((type == null) || (region.types?.contains(type) ?? false)) &&
            ((enabled == null) || (enabled == region.enabled)) &&
            ((regionType == null) || (regionType == region.regionType)) &&
            ((inside == null) || (inside == (_currentRegions.contains(regionId)))))
        {
          regions.add(region);
        }
      });
    }
    return regions;
  }

  List<GeoFenceBeacon>? currentBeaconsInRegion(String regionId) {
    return _currentBeacons[regionId];
  }

  Future<bool?> startRangingBeaconsInRegion(String regionId) async {
    return JsonUtils.boolValue(await _channel.invokeMethod(_startRangingBeaconsInRegionName, regionId));
  }

  Future<bool?> stopRangingBeaconsInRegion(String regionId) async {
    return JsonUtils.boolValue(await _channel.invokeMethod(_stopRangingBeaconsInRegionName, regionId));
  }

  Future<List<GeoFenceBeacon>?> beaconsInRegion(String regionId) async {
    return GeoFenceBeacon.listFromJsonList(JsonUtils.listValue( await _channel.invokeMethod(_beaconsInRegionName, regionId)));
  }

  // Implementation

  Future<File> _getCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _geoFenceName);
    return File(cacheFilePath);
  }

  Future<String?> _loadRegionsStringFromCache() async {
    return ((_cacheFile != null) && await _cacheFile!.exists()) ? await _cacheFile!.readAsString() : null;
  }

  Future<void> _saveRegionsStringToCache(String? regionsString) async {
    await _cacheFile?.writeAsString(regionsString ?? '', flush: true);
  }

  Future<LinkedHashMap<String, GeoFenceRegion>?> _loadRegionsFromCache() async {
    return _regionsFromJsonString(await _loadRegionsStringFromCache());
  }

  LinkedHashMap<String, GeoFenceRegion>? _loadRegionsFromAssets() {
    return GeoFenceRegion.mapFromJsonList(Assets()['geo_fence.regions']);
  }


  Future<String?> _loadRegionsStringFromNet() async {
    if (_useAssets) {
      return null;
    }
    else {
      try {
        Http.Response? response = await Network().get("${Config().locationsUrl}/regions", auth: Auth2NetworkAuth());
        return ((response != null) && (response.statusCode == 200)) ? response.body : null;
        } catch (e) {
          print(e.toString());
        }
        return null;
      }
    }

  Future<void> _updateRegions() async {
    String? jsonString = await _loadRegionsStringFromNet();
    LinkedHashMap<String, GeoFenceRegion>? regions = _regionsFromJsonString(jsonString);
    if ((regions != null) && !_areRegionsEqual(_regions, regions)) { // DeepCollectionEquality().equals(_regions, regions)
      _regions = regions;
      _monitorRegions();
      _saveRegionsStringToCache(jsonString);
    }
  }

  static LinkedHashMap<String, GeoFenceRegion>? _regionsFromJsonString(String? jsonString) {
    List<dynamic>? jsonList = JsonUtils.decode(jsonString);
    return (jsonList != null) ? GeoFenceRegion.mapFromJsonList(jsonList) : null;
  }

  static bool _areRegionsEqual(LinkedHashMap<String, GeoFenceRegion>? regions1, LinkedHashMap<String, GeoFenceRegion>? regions2) {
    if ((regions1 != null) && (regions2 != null)) {
      if (regions1.length == regions2.length) {
        for (String? regionId in regions1.keys) {
          GeoFenceRegion? region1 = regions1[regionId];
          GeoFenceRegion? region2 = regions2[regionId];
          if (((region1 != null) && (region2 == null)) ||
              ((region1 == null) && (region2 != null)) ||
              ((region1 != null) && (region2 != null) && !(region1 == region1))
          ) {
            return false;
          }
        }
        return true;
      }
    }
    else if ((regions1 == null) && (regions2 == null)) {
      return true;
    }
    return false;
  }

  // ignore: unused_element
  static Future<List<String>?> _currentRegionIds() async {
    return JsonUtils.listStringsValue(await _channel.invokeMethod(_currentRegionsName));
  }

  Future<void> _monitorRegions() async {
    await _channel.invokeMethod(_monitorRegionsName, GeoFenceRegion.listToJsonList(GeoFenceRegion.filterList(_regions?.values, enabled: true), locationRadius: Storage().debugGeoFenceRegionRadius?.toDouble()));
  }

  void _updateCurrentRegions(List<String>? regionIds) {
    if (regionIds != null) {
      Set<String> currentRegions = Set.from(regionIds);
      if (_currentRegions != currentRegions) {
        _currentRegions = currentRegions;
        NotificationService().notify(notifyCurrentRegionsUpdated, null);
      }
    }
  }

  void _updateCurrentBeacons({String? regionId, List<GeoFenceBeacon>? beacons}) {
    try {
      if (regionId != null) {
        if (beacons != null) {
          _currentBeacons[regionId] = beacons;
        }
        else {
          _currentBeacons.remove(regionId);
        }
        NotificationService().notify(notifyCurrentBeaconsUpdated, regionId);
      }
    }
    catch(e) {
      print(e.toString());
    }
  }

  // Plugin

  Future<dynamic> _handleChannelCall(MethodCall call) async {
    if (call.method == _enterRegionName) {
      print("GeoFence didEnterRegion: ${JsonUtils.stringValue(call.arguments)}");
      return null;
    }
    else if (call.method == _exitRegionName) {
      print("GeoFence didExitRegion: ${JsonUtils.stringValue(call.arguments)}");
      return null;
    }
    else if (call.method == _currentRegionsChangedName) {
      _updateCurrentRegions(JsonUtils.listStringsValue(call.arguments));
      return null;
    }
    else if (call.method == _beaconsInRegionChangedName) {
      Map<String, dynamic>? params = JsonUtils.mapValue(call.arguments);
      String? regionId = (params != null) ? JsonUtils.stringValue(params['regionId']) : null;
      List<GeoFenceBeacon>? beacons = (params != null) ? GeoFenceBeacon.listFromJsonList(params['beacons']) : null;
      _updateCurrentBeacons(regionId: regionId, beacons: beacons);
      return null;
    }
    else {
      return null;
    }
  }

}