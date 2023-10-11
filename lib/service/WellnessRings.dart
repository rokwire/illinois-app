import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/WellnessRing.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:http/http.dart' as http;

enum WellnessRingsStatus {unknown, initializing, initialized, failed}

class WellnessRings with Service implements NotificationsListener{
  static const String notifyUserRingsUpdated = "edu.illinois.rokwire.wellness.user.ring.updated";
  static const String notifyUserRingsAccomplished = "edu.illinois.rokwire.wellness.user.ring.accomplished";

  static const String _cacheFileName = "wellness.json";
  static const int MAX_RINGS = 4;
  static const int HISTORY_LIMIT_DAYS = 14;

  WellnessRingsStatus status = WellnessRingsStatus.unknown;
  final List<Completer<void>> _loadCompleters = [];

  Map<String,WellnessRingDefinition>? _activeWellnessRings;
  List<WellnessRingDefinition>? _wellnessRingsRecords = [];
  List<WellnessRingRecord>? _wellnessRecords = [];

  File? _cacheFile;
  DateTime? _pausedDateTime;

  // Singletone Factory

  static WellnessRings? _instance;

  static WellnessRings? get instance => _instance;

  @protected
  static set instance(WellnessRings? value) => _instance = value;

  factory WellnessRings() => _instance ?? (_instance = WellnessRings.internal());

  @protected
  WellnessRings.internal();

  @override
  void createService() {
    NotificationService().subscribe(this,[
      AppLivecycle.notifyStateChanged,
      Auth2.notifyLoginSucceeded
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _initRecords();
    return super.initService();
  }

  //Init
  Future<void> _initRecords() async {
    await _initFromCache();
    await _initFromNet();
  }

  Future<bool> _initFromCache() async{
    _cacheFile = await _getCacheFile();
    return _loadContentJsonFromCache().then((Map<String, dynamic>? storedValues) {
        _wellnessRingsRecords = WellnessRingDefinition.listFromJson(storedValues?["wellness_rings_data"]) ?? [];
        _wellnessRecords = WellnessRingRecord.listFromJson(storedValues?["wellness_ring_records"] ?? []);
        //Log.d("Wellness Rings Init from cache finished!");
        return true;
      });
  }

  Future<void> _waitForInitFromNet() async{
    if(!serviceDataInitialized && Auth2().isLoggedIn) {
      try {
        if (_loadCompleters.isEmpty) {
          Completer<void> completer = Completer<void>();
          _loadCompleters.add(completer);
          _initFromNet().whenComplete(() {
            for (var completer in _loadCompleters) {
              completer.complete();
            }
            _loadCompleters.clear();
          });
          return completer.future;
        } else {
          Completer<void> completer = Completer<void>();
          _loadCompleters.add(completer);
          return completer.future;
        }
      } catch(err){
        Log.e("Failed to invoke Rings INIT API");
        debugPrint(err.toString());
      }
    }
  }

  Future<void> _initFromNet() async{
    //Log.d("_initFromNet status = $status!");
    if(status  == WellnessRingsStatus.initializing){
      return; //Wait for previous call
    }

    status = WellnessRingsStatus.initializing;

    //Log.d("_initFromNet Start Loading status = $status!");
    _loadFromNet().then((success) {
      //Log.d("Wellness Rings _loadFromNet().then((success) = $success");
      status = success ? WellnessRingsStatus.initialized : WellnessRingsStatus.failed;
      NotificationService().notify(notifyUserRingsUpdated);
      //Log.d("Wellness Rings _initRecords finished! status = $status");
    }).onError((error, stackTrace){
      Log.d("loadFromNet().onError((error, = $error");
      status = WellnessRingsStatus.failed;
    });
  }

  Future<bool> _loadFromNet() async{
    List<bool> results = await Future.wait([
      _loadRingDefinitions(),
      _loadRingRecords(),
    ]);

    _saveRingsDataToCache(); //Consider update
    //Log.d("Wellness Rings _loadFromNet finished!  status = $status, results: $results" );

    return results.isNotEmpty ? !results.contains(false) : false;
  }

  Future<void> initIfNeeded() async {
    //Log.d("initIfNeeded status = $status!");
    if(status == WellnessRingsStatus.failed || status == WellnessRingsStatus.unknown){
      await _waitForInitFromNet();
    }
  }

  Future<void> _reInit() async {
    //Log.d("_reInit status = $status!");
    status = WellnessRingsStatus.unknown;
    _wellnessRecords = [];
    _wellnessRingsRecords = [];
    _activeWellnessRings = {};
    _saveRingsDataToCache();
    await _waitForInitFromNet();
  }

  Future<void> _refreshFromNet() async {
    _loadFromNet();
    //TBD consider update instead of rewrite the whole content
  }

  Future<bool> _loadRingDefinitions() async {
    var definitionHistory = await _requestGetRingDefinition();
    if(definitionHistory!=null)
      _wellnessRingsRecords = definitionHistory;
    _updateActiveRingsData();
    // NotificationService().notify(notifyUserRingsUpdated);
    //Log.d("Wellness Rings _loadRingDefinitions finished! success: ${definitionHistory != null}");
    return definitionHistory != null;
  }

  Future<bool> _loadRingRecords() async {
    var recordsHistory = await _requestGetRingRecord(
        startPeriod: DateTimeUtils.midnight(DateTime.now())?.subtract(Duration(days: HISTORY_LIMIT_DAYS))); //Consider do we want to load full history from the beginning
    if(recordsHistory != null)
      _wellnessRecords = recordsHistory;
    // NotificationService().notify(notifyUserRingsUpdated);
    //Log.d("Wellness Rings loadRingRecords finished! success: ${recordsHistory != null}");
    return recordsHistory != null;
  }
  /////

  //Active Rings:
  bool _initActiveRingsData (){
    _activeWellnessRings = {};
    if(_wellnessRingsRecords?.isNotEmpty ?? false){
      for (WellnessRingDefinition data in _wellnessRingsRecords!){
        if(_activeWellnessRings!.containsKey(data.id)){
          WellnessRingDefinition? storedDefinition = _activeWellnessRings![data.id];
          if((storedDefinition?.timestamp ?? 0) < data.timestamp){
            _activeWellnessRings![data.id] = data;
          }
        } else {
          _activeWellnessRings![data.id] = data;
        }
      }
      NotificationService().notify(notifyUserRingsUpdated); //TBD use separate key
    }
    return true;
  }

  void _updateActiveRingsData (){
    _initActiveRingsData();
    //TBD implement
    // NotificationService().notify(notifyUserRingsUpdated); //TBD use separate key
  }

  //APIS
  Future<bool> addRing(WellnessRingDefinition definition) async {
    await initIfNeeded();
    if(!serviceDataInitialized){//Do not allow performing action while we don't have actual data
      return false;
    }

    bool success = false;
    if(_wellnessRingsRecords == null){
      _wellnessRingsRecords = [];
    }
    if(canAddRing && (!(_activeWellnessRings?.containsKey(definition.id) ?? false))){
      var updatedDefinition = await _requestAddRingDefinition(definition);
      if(updatedDefinition != null){
        _wellnessRingsRecords!.add(updatedDefinition); //TBD make refresh from net
        _updateActiveRingsData();
        success = true;
      }
    }
    return success;
  }

  Future<bool> updateRing(WellnessRingDefinition data) async {
    await initIfNeeded();
    if(!serviceDataInitialized){//Do not allow performing action while we don't have actual data
      return false;
    }

    bool success = false;
    WellnessRingDefinition? currentRingData = _activeWellnessRings?[data.id];
    if(currentRingData == null || currentRingData != data){
      if(_wellnessRingsRecords == null){
        _wellnessRingsRecords = [];
      }
      success = await _requestAddRingDefinitionHistory(data);
      if(success) {
        _wellnessRingsRecords!.add(data);
        _updateActiveRingsData();
        _storeWellnessRingData();
        NotificationService().notify(notifyUserRingsUpdated);
      }
    }
    return success;
  }

  Future<bool> removeRing(WellnessRingDefinition data) async {
    await initIfNeeded();
    if(!serviceDataInitialized){//Do not allow performing action while we don't have actual data
      return false;
    }
    WellnessRingDefinition? ringData = _activeWellnessRings?[data.id];
    bool success = await _requestDeleteRingDefinition(data.id);
    if(success) {
      if (ringData != null) {
        _wellnessRingsRecords?.removeWhere((ringRecord) =>
        ringRecord.id == data.id);
        _wellnessRecords?.removeWhere((ringRecord) =>
        ringRecord.wellnessRingId == data.id);
        _updateActiveRingsData();
        _storeWellnessRingData();
        NotificationService().notify(notifyUserRingsUpdated);
        return true;
      }
    }
    return false;
  }

  Future<bool> addRecord(WellnessRingRecord record) async {
    await initIfNeeded();
    if(!serviceDataInitialized){//Do not allow performing action while we don't have actual data
      return false;
    }
     //Do not allow performing action while we don't have actual data)
    if(!_canAddRingRecord(record)){
      //Log.d("addRecord not allowed${record.toJson()}");
      return false;
    }
    //Log.d("addRecord ${record.toJson()}");
    bool success = await _requestAddRingRecord(record);
    if(success) {
      bool alreadyAccomplished = _isAccomplished(record.wellnessRingId);
      _wellnessRecords?.add(record);
      NotificationService().notify(notifyUserRingsUpdated);
      if (alreadyAccomplished == false) {
        _checkForAccomplishment(record.wellnessRingId);
      }
      _storeWellnessRecords();
      return true;
    }
    return false;
  }

  Future<bool> deleteRecords() async {
    bool success = await _requestDeleteRingRecords();
    if(success) {
      _wellnessRecords?.clear();
      NotificationService().notify(notifyUserRingsUpdated);
      _storeWellnessRecords();
      return true;
    }
    return false;
  }

  Future<List<WellnessRingDefinition>?> loadWellnessRings() async {
    await initIfNeeded();
    return _activeWellnessRings?.values.toList();
  }
  /////

  //Accomplishment
  void _checkForAccomplishment(String id){
    if(_isAccomplished(id)){
      NotificationService().notify(notifyUserRingsAccomplished, id);
    }
  }

  bool _isAccomplished(String id){
    return(getRingData(id)?.goal ?? 0) <= getRingDailyValue(id);
  }

  //Accomplishment History
  Map<String, List<WellnessRingAccomplishment>>? getAccomplishmentsHistory(){
    Map<String, List<WellnessRingAccomplishment>> history = {/*"2022-06014":[WellnessRingData(id: '0', timestamp: DateTime.now().millisecondsSinceEpoch, goal: 1, name: "Test" )]*/};

    //First split by day and id
    Map<String, Map<String, List<WellnessRingRecord>>> splitRecords = _splitRecordsByDay();

    //get Ring data for completed ones
    for (var dayRecords in splitRecords.entries){

      for(var ringDayRecords in dayRecords.value.entries){
        String ringId = ringDayRecords.key;
        List<WellnessRingRecord>? ringRecords = dayRecords.value[ringId];
        WellnessRingDefinition? ringData;
        try {
          ringData = (ringRecords?.isNotEmpty ?? false) ? _getActiveRingDataForDay(id: ringId, date: ringRecords!.first.date) : null;
        } catch (e){
          print(e);
        }
        if(ringData!=null) {
          double goal = ringData.goal;
          double dayCount = 0;
          if (ringRecords != null) {
            for (WellnessRingRecord record in ringRecords) {
              dayCount += record.value;
            }
            if (dayCount >= goal) {
              //Match
              List<WellnessRingAccomplishment>? accomplishmentsForThatDay = history[dayRecords.key];
              if(accomplishmentsForThatDay == null){
                accomplishmentsForThatDay = [];
                history[dayRecords.key] = accomplishmentsForThatDay;
              }

              WellnessRingAccomplishment? completionData = accomplishmentsForThatDay.firstWhere((element) => element.ringData.id == ringData!.id,
                  orElse: () => WellnessRingAccomplishment(ringData: ringData!, achievedValue: dayCount)
              );

              if(!accomplishmentsForThatDay.contains(completionData)){
                accomplishmentsForThatDay.add(completionData);
              } else {
                completionData.achievedValue = dayCount; // if we have completed with more than the goal
              }
            }
          }
        }
      }
    }
    return history;
  }

  Map<String, Map<String, List<WellnessRingRecord>>> _splitRecordsByDay(){
    Map<String, Map<String, List<WellnessRingRecord>>> ringDateRecords = {};
    _wellnessRecords?.forEach((record) {
      String? recordDayName =  DateTimeUtils.localDateTimeToString(DateTimeUtils.midnight(record.date));
      if(recordDayName!=null) {
        Map<String, List<WellnessRingRecord>>? recordsForDay = ringDateRecords[recordDayName];
        if (recordsForDay == null) {
          recordsForDay = {};
          ringDateRecords[recordDayName] = recordsForDay;
        }

        String recordId = record.wellnessRingId;
        List<WellnessRingRecord>? recordsForId = recordsForDay[recordId];
        if(recordsForId == null){
          recordsForId = [];
          recordsForDay[recordId] = recordsForId;
        }
        recordsForId.add(record);
      }
    });

    return ringDateRecords;
  }

  List<WellnessRingDefinition>? _findRingData({required String id, DateTime? beforeTimestamp, DateTime? afterTimestamp}){
    if(_wellnessRingsRecords?.isNotEmpty ?? false){
      List<WellnessRingDefinition> result = [];
      for(WellnessRingDefinition record in _wellnessRingsRecords!){
        if(record.id == id
          && (beforeTimestamp == null || record.timestamp < beforeTimestamp.millisecondsSinceEpoch)
          && (afterTimestamp == null  || record.timestamp > afterTimestamp.millisecondsSinceEpoch)
        ){
          result.add(record);
        }
      }

      return result;
    }

    return null;
  }

  WellnessRingDefinition? _getActiveRingDataForDay({required String id, DateTime? date}){
    if(date!=null){
      DateTime? midnight = DateTimeUtils.midnight(date.toLocal().add(Duration(days: 1))); //Border is at midnight the next day (Local Time)
      var foundData = _findRingData(id: id, beforeTimestamp: midnight);
      if(foundData?.isNotEmpty ?? false){
        return foundData!.last; // last to be the most up to date
      }
    }

    return null;
  }

  WellnessRingDefinition? getRingData(String? id){
    return (id != null )? (_activeWellnessRings?[id] ): null;
  }

  //Total Completion TBD remove if we are not going to use it again
  int getTotalCompletionCount(String id){
    //Split records by date
    Map<String, List<WellnessRingRecord>> ringDateRecords = {};
    _wellnessRecords?.forEach((record) {
      String? recordDayName = DateTimeUtils.localDateTimeToString(DateTimeUtils.midnight(record.date));
      if(recordDayName!=null) {
        List<WellnessRingRecord>? recordsForDay = ringDateRecords[recordDayName];
        if (recordsForDay == null) {
          recordsForDay = [];
          ringDateRecords[recordDayName] = recordsForDay;
        }
        recordsForDay.add(record);
      }
    });

    //
    int count = 0;
    for (List<WellnessRingRecord> dayRecords in ringDateRecords.values){
      if(dayRecords.isNotEmpty) {
        WellnessRingDefinition? ringData = _getActiveRingDataForDay(id: id, date: dayRecords.first.date); //We've filtered per day, so all records should return the same DayRingData, so just take the first one
        int dayCount = 0;
        for (WellnessRingRecord record in dayRecords) {
          dayCount += record.value.toInt();
        }
        if (dayCount >= (ringData?.goal ?? 0)) {
          //Match
          count++;
        }
      }
    }
    return count;
  }

  String getTotalCompletionCountString(String id){
    int count = getTotalCompletionCount(id);
    switch(count){
      case 1 : return "1st";
      case 2 : return "2nd";
      default :return "${count}rd";
    }
  }

  //Getters
  double getRingDailyCompletion(String id) {
    double value = getRingDailyValue(id);
    double goal = 1;
    try{
      goal = getRingData(id)?.goal ?? 0;
    } catch (e){
      print(e);
      return 0;// if we have no records yet
    }
    return goal == 0 || value == 0 ? 0 :
    value / goal;
  }

  double getRingDailyValue(String wellnessRingId){
    Iterable<WellnessRingRecord>? selection = _wellnessRecords?.where((record) =>
    ((record.wellnessRingId == wellnessRingId)
        // && (DateTimeUtils.midnight(DateTime.now())?.isBefore(record.date ?? DateTime.now()) ?? false)));
        && (record.date.isAfter(/*today's start*/DateTimeUtils.midnight(DateTime.now()) ?? DateTime.now())))); //records after midnight

    double value = 0.0;
    selection?.forEach((record) {
      value += record.value;
    });
    return value;
  }

  bool _canAddRingRecord(WellnessRingRecord record){
    if(!serviceDataInitialized){ //Do not allow performing action while we don't have actual data
      return false;
    }

    if(record.value > 0){
      return true;
    } else { //Don't allow to become negative
      return getRingDailyValue(record.wellnessRingId) > 0;
    }
  }

  List<WellnessRingDefinition>? get wellnessRings{
    return _activeWellnessRings?.values.toList();
  }

  bool get canAddRing{
    return serviceDataInitialized && //Do not allow performing action while we don't have actual data
      (_activeWellnessRings?.length ?? 0) < MAX_RINGS;
  }

  bool get haveHistory{
    return _wellnessRecords?.isNotEmpty ?? false;
  }

  bool get serviceEnabled{
    return true;
  }

  bool get serviceDataInitialized{
    return status == WellnessRingsStatus.initialized;
  }

  //Cashe
  Future<File> _getCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _cacheFileName);
    return File(cacheFilePath);
  }

  Future<String?> _loadContentStringFromCache() async {
    return (await _cacheFile?.exists() == true) ? await _cacheFile?.readAsString() : null;
  }

  Future<void> _saveRingsDataToCache() async{
    String? data = JsonUtils.encode({
      "wellness_rings_data": _wellnessRingsRecords,
      "wellness_ring_records": _wellnessRecords,
    });

    return _saveContentStringToCache(data);
  }

  Future<void> _saveContentStringToCache(String? value) async {
    // TMP: return; //TBD REMOVE
    try {
      if (value != null) {
        await _cacheFile?.writeAsString(value, flush: true);
      }
      else {
        await _cacheFile?.delete();
      }
    }
    catch(e) { print(e.toString()); }
  }

  Future<Map<String, dynamic>?> _loadContentJsonFromCache() async {
    // TMP: return null; //TBD REMOVE
    return JsonUtils.decodeMap(await _loadContentStringFromCache());
  }
///////

  //Store
  void _storeWellnessRingData(){
    _saveRingsDataToCache();
  }

  void _storeWellnessRecords(){
    _saveRingsDataToCache();
  }
///////

  //BB APIS RING DEFINITION
  Future<WellnessRingDefinition?> _requestAddRingDefinition(WellnessRingDefinition definition) async {
    //TBD ENABLED
    String url = '${Config().wellnessUrl}/user/rings';

    String? definitionJson = JsonUtils.encode(definition);

    http.Response? response = await Network().post(url, auth: Auth2(), body: definitionJson);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? responseData = JsonUtils.decodeMap(responseString);
      List<dynamic>? history = JsonUtils.listValue(responseData?["history"]);
      return (history?.isNotEmpty ?? false) ? WellnessRingDefinition.fromJson(history!.last ): null;
    } else {
      Log.w('Failed to add wellness ring definition. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<List<WellnessRingDefinition>?> _requestGetRingDefinition({String? ringId}) async {
    //TBD ENABLED
    String url = '${Config().wellnessUrl}/user/rings';
    if(ringId!=null){
      url += "/$ringId";
    }

    http.Response? response = await Network().get(url, auth: Auth2(),);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<dynamic>? responseData = JsonUtils.decodeList(responseString);
      if(responseData?.isNotEmpty ?? false){
        List<dynamic> fullHistory = [];
        responseData!.forEach((data) { //TBD get response in this format
          List<dynamic>? history = JsonUtils.listValue(data["history"]);
          if(history!=null) {
            fullHistory.addAll(history);
          }
        });
        return WellnessRingDefinition.listFromJson(fullHistory);
      } else {
        return []; //successful but empty
      }
    } else {
      Log.w('Failed to get ring definitions. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<bool> _requestDeleteRingDefinition(String ringId) async {
    //TBD ENABLED
    String url = '${Config().wellnessUrl}/user/rings/$ringId';

    http.Response? response = await Network().delete(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      return true;
    } else {
      Log.w('Failed to delete wellness ring. Response:\n$responseCode: $responseString');
      return false;
    }
  }

  Future<bool> _requestAddRingDefinitionHistory(WellnessRingDefinition definition) async {
    //TBD ENABLED
    String url = '${Config().wellnessUrl}/user/rings/${definition.id}/history';

    String? definitionJson = JsonUtils.encode(definition);

    http.Response? response = await Network().post(url, auth: Auth2(), body: definitionJson);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      return true;
    } else {
      Log.w('Failed to add wellness ring history. Response:\n$responseCode: $responseString');
      return false;
    }
  }

//////

//BB APIS RING RECORDS

  Future<List<WellnessRingRecord>?> _requestGetRingRecord({String? ringId, DateTime? startPeriod, DateTime? endPeriod}) async { //TBD Change on backend to avoid multiple requests
    //TBD ENABLED

    String url = (ringId != null)
      ? '${Config().wellnessUrl}/user/rings/$ringId"/records'
      : '${Config().wellnessUrl}/user/all_rings_records';

    String params = "";
    
    if(startPeriod != null){
      params += params.isNotEmpty ? "&" : "";
      params += "start_date=${startPeriod.millisecondsSinceEpoch.toString()}";
    }

    if(endPeriod != null){
      params += params.isNotEmpty ? "&" : "";
      params += "end_date=${endPeriod.millisecondsSinceEpoch.toString()}";
    }

    url += params.isNotEmpty ? "?$params" : "";

    http.Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<dynamic>? responseData = JsonUtils.decodeList(responseString);
      return (responseData?.isNotEmpty ?? false) ? WellnessRingRecord.listFromJson(responseData): [] /*successful but empty*/;
    } else {
      Log.w('Failed to get wellness ring record. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<bool> _requestAddRingRecord(WellnessRingRecord record) async {
    //TBD ENABLED
    String url = '${Config().wellnessUrl}/user/rings/${record.wellnessRingId}/records';

    String? definitionJson = JsonUtils.encode(record);

    http.Response? response = await Network().post(url, auth: Auth2(), body: definitionJson);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      // List<dynamic>? responseData = JsonUtils.decodeList(responseString);
      return true;
    } else {
      Log.w('Failed to add wellness ring record. Response:\n$responseCode: $responseString');
      return false;
    }
  }

  Future<bool> _requestDeleteRingRecords({String? ringId}) async {
    //TBD ENABLED
    String url = "";
    if(ringId == null) {
      url = '${Config().wellnessUrl}/user/all_rings_records';
    } else {
      url = '${Config().wellnessUrl}/user/rings/$ringId/records';
    }

    http.Response? response = await Network().delete(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    if (responseCode == 200) {
      return true;
    } else {
      String? responseString = response?.body;
      Log.w('Failed to delete wellness ring. Response:\n$responseCode: $responseString');
      return false;
    }
  }

  @override
  void onNotification(String name, param) {
    if(name == Auth2.notifyLoginSucceeded){
      _reInit();
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
            _refreshFromNet();
        }
      }
    }
  }

//////
  //TBD clan up
}