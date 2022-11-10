

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Config.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class MTD with Service implements NotificationsListener {

  static const String notifyStopsChanged = 'edu.illinois.rokwire.mtd.stops.changed';
  static const String _mtdStopsName = "mtdStops.json";

  late Directory _appDocDir;
  DateTime? _pausedDateTime;
  
  MTDStops? _stops;

  // Singleton Factory

  static final MTD _instance = MTD._internal();
  factory MTD() => _instance;
  MTD._internal();

  // Service

  void createService() {
    NotificationService().subscribe(this,[
      AppLivecycle.notifyStateChanged,
    ]);
    super.createService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Future<void> initService() async {
    _appDocDir = await getApplicationDocumentsDirectory();
    
    // Init stops
    _stops = await _loadStopsFromCache();
    if (_stops != null) {
      _updateStops();
    }
    else {
      String? stopsJsonString = await _loadStopsStringFromNet();
      _stops = MTDStops.fromJson(JsonUtils.decodeMap(stopsJsonString));
      if (_stops != null) {
        _saveStopsStringToCache(stopsJsonString);
      }
    }

    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config()]);
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
          _updateStops();
        }
      }
    }
  }

  // Stops

  MTDStops? get stops => _stops;

  File _getStopsCacheFile() => File(join(_appDocDir.path, _mtdStopsName));

  Future<String?> _loadStopsStringFromCache() async {
    File stopsFile = _getStopsCacheFile();
    return await stopsFile.exists() ? await stopsFile.readAsString() : null;
  }

  Future<void> _saveStopsStringToCache(String? value) async {
    await _getStopsCacheFile().writeAsString(value ?? '', flush: true);
  }

  Future<MTDStops?> _loadStopsFromCache() async {
    return MTDStops.fromJson(JsonUtils.decodeMap(await _loadStopsStringFromCache()));
  }

  Future<String?> _loadStopsStringFromNet({ String? changesetId}) async {
    if (StringUtils.isNotEmpty(Config().mtdUrl) && StringUtils.isNotEmpty(Config().mtdApiKey)) {
      String url = "${Config().mtdUrl}/getstops?key=${Config().mtdApiKey}";
      if (changesetId != null) {
        url += "&changeset_id=$changesetId";
      }
      Response? response = await Network().get(url);
      return (response?.statusCode == 200) ? response?.body : null;
    }
    return null;
  }

  Future<void> _updateStops() async {
    String? stopsJsonString = await _loadStopsStringFromNet(changesetId: _stops?.changesetId);
    MTDStops? stops = MTDStops.fromJson(JsonUtils.decodeMap(stopsJsonString));
    if ((stops != null) && (stops.changesetId != _stops?.changesetId)) {
      _stops = stops;
      _saveStopsStringToCache(stopsJsonString);
      NotificationService().notify(notifyStopsChanged);
    }
  }

  // Routes

  Future<List<MTDRoute>?> getRoutes({String? stopId}) async {
    if (StringUtils.isNotEmpty(Config().mtdUrl) && StringUtils.isNotEmpty(Config().mtdApiKey)) {
      String url = StringUtils.isNotEmpty(stopId) ?
        "${Config().mtdUrl}/getroutesbystop?key=${Config().mtdApiKey}&stop_id=$stopId" :
        "${Config().mtdUrl}/getroutes?key=${Config().mtdApiKey}";
      Response? response = await Network().get(url);
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body)  : null;
      return (responseJson != null) ? MTDRoute.listFromJson(JsonUtils.listValue(responseJson['routes'])) : null;
    }
    return null;
  }
}