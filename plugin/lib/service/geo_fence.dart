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
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart';

import 'package:rokwire_plugin/model/geo_fence.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class GeoFence with Service implements NotificationsListener {

  static const String notifyRegionEnter            = "edu.illinois.rokwire.geofence.region.enter";
  static const String notifyRegionExit             = "edu.illinois.rokwire.geofence.region.exit";
  static const String notifyCurrentRegionsUpdated  = "edu.illinois.rokwire.geofence.regions.current.updated";
  static const String notifyCurrentBeaconsUpdated  = "edu.illinois.rokwire.geofence.beacons.current.updated";
  
  static const String _geoFenceName                = "geoFence.json";

  static const bool _useAssets = false;

  LinkedHashMap<String, GeoFenceRegion>? _regions;
  Set<String> _currentRegions = <String>{};
  final Map<String, List<GeoFenceBeacon>> _currentBeacons = <String, List<GeoFenceBeacon>>{};

  File?      _cacheFile;
  DateTime?  _pausedDateTime;
  int?       _debugRegionRadius;

  // Singletone Factory

  static GeoFence? _instance;

  static GeoFence? get instance => _instance;
  
  @protected
  static set instance(GeoFence? value) => _instance = value;

  factory GeoFence() => _instance ?? (_instance = GeoFence.internal());

  @protected
  GeoFence.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _cacheFile = await getCacheFile();
    _debugRegionRadius = Storage().debugGeoFenceRegionRadius;

    _regions = useAssets ? await loadRegionsFromAssets() : await loadRegionsFromCache();
    if (_regions != null) {
      updateRegions();
    }
    else {
      String? jsonString = await loadRegionsStringFromNet();
      _regions = _regionsFromJsonString(jsonString);
      if (_regions != null) {
        saveRegionsStringToCache(jsonString);
      }      
    }
    
    monitorRegions();
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Storage(), Config(), Auth2()};
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
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
          updateRegions();
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
    return JsonUtils.boolValue(await RokwirePlugin.geoFence('startRangingBeaconsInRegion', regionId));
  }

  Future<bool?> stopRangingBeaconsInRegion(String regionId) async {
    return JsonUtils.boolValue(await RokwirePlugin.geoFence('stopRangingBeaconsInRegion', regionId));
  }

  Future<List<GeoFenceBeacon>?> beaconsInRegion(String regionId) async {
    return GeoFenceBeacon.listFromJsonList(JsonUtils.listValue(await RokwirePlugin.geoFence('getBeaconsInRegion', regionId)));
  }

  int? get debugRegionRadius => _debugRegionRadius;

  set debugRegionRadius(int? value) {
    if (_debugRegionRadius != value) {
      Storage().debugGeoFenceRegionRadius = _debugRegionRadius = value;
      monitorRegions();
    }
  }

  // Implementation

  @protected
  bool get useAssets => _useAssets;

  @protected
  Future<File> getCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _geoFenceName);
    return File(cacheFilePath);
  }

  @protected
  Future<String?> loadRegionsStringFromCache() async {
    return ((_cacheFile != null) && await _cacheFile!.exists()) ? await _cacheFile!.readAsString() : null;
  }

  @protected
  Future<void> saveRegionsStringToCache(String? regionsString) async {
    await _cacheFile?.writeAsString(regionsString ?? '', flush: true);
  }

  @protected
  Future<LinkedHashMap<String, GeoFenceRegion>?> loadRegionsFromCache() async {
    return _regionsFromJsonString(await loadRegionsStringFromCache());
  }

  @protected
  String get resourceAssetsKey => 'assets/$_geoFenceName';

  @protected
  Future<LinkedHashMap<String, GeoFenceRegion>?> loadRegionsFromAssets() async {
    return GeoFenceRegion.mapFromJsonList(JsonUtils.decodeList(await rootBundle.loadString(resourceAssetsKey)));
  }


  @protected
  Future<String?> loadRegionsStringFromNet() async {
    if (_useAssets) {
      return null;
    }
    else {
      try {
        Response? response = await Network().get("${Config().locationsUrl}/regions", auth: Auth2());
        return ((response != null) && (response.statusCode == 200)) ? response.body : null;
        } catch (e) {
          debugPrint(e.toString());
        }
        return null;
      }
    }

  @protected
  Future<void> updateRegions() async {
    String? jsonString = await loadRegionsStringFromNet();
    LinkedHashMap<String, GeoFenceRegion>? regions = _regionsFromJsonString(jsonString);
    if ((regions != null) && !_areRegionsEqual(_regions, regions)) { // DeepCollectionEquality().equals(_regions, regions)
      _regions = regions;
      monitorRegions();
      saveRegionsStringToCache(jsonString);
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
    return JsonUtils.listStringsValue(await RokwirePlugin.geoFence('getCurrentRegions'));
  }

  @protected
  Future<void> monitorRegions() async {
    await RokwirePlugin.geoFence('monitorRegions', GeoFenceRegion.listToJsonList(GeoFenceRegion.filterList(_regions?.values, enabled: true), locationRadius: _debugRegionRadius?.toDouble()));
  }

  void _updateCurrentRegions(List<String>? regionIds) {
    if (regionIds != null) {
      Set<String> currentRegions = Set.from(regionIds);
      if (_currentRegions != currentRegions) {
        _currentRegions = currentRegions;
        NotificationService().notify(notifyCurrentRegionsUpdated);
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
      debugPrint(e.toString());
    }
  }

  // Plugin

  Future<dynamic> onPluginNotification(String? name, dynamic arguments) async {
    if (name == 'onEnterRegion') {
      String? regionId = JsonUtils.stringValue(arguments);
      debugPrint("GeoFence didEnterRegion: $regionId}");
      NotificationService().notify(notifyRegionEnter, regionId);
    }
    else if (name == 'onExitRegion') {
      String? regionId = JsonUtils.stringValue(arguments);
      debugPrint("GeoFence didExitRegion: $regionId}");
      NotificationService().notify(notifyRegionExit, regionId);
    }
    else if (name == 'onCurrentRegionsChanged') {
      _updateCurrentRegions(JsonUtils.listStringsValue(arguments));
    }
    else if (name == 'onBeaconsInRegionChanged') {
      Map<String, dynamic>? params = JsonUtils.mapValue(arguments);
      String? regionId = (params != null) ? JsonUtils.stringValue(params['regionId']) : null;
      List<GeoFenceBeacon>? beacons = (params != null) ? GeoFenceBeacon.listFromJsonList(params['beacons']) : null;
      _updateCurrentBeacons(regionId: regionId, beacons: beacons);
    }
  }
}