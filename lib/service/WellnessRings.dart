import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/WellnessReing.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessRings with Service{
  static const String notifyUserRingsUpdated = "edu.illinois.rokwire.wellness.user.ring.updated";
  static const String notifyUserRingsAccomplished = "edu.illinois.rokwire.wellness.user.ring.accomplished";

  static const String _cacheFileName = "wellness.json";
  static const int MAX_RINGS = 4;

  File? _cacheFile;

  Map<String,WellnessRingData>? _activeWellnessRings;
  List<WellnessRingData>? _wellnessRingsRecords;
  List<WellnessRingRecord>? _wellnessRecords;

  // Singletone Factory

  static WellnessRings? _instance;

  static WellnessRings? get instance => _instance;

  @protected
  static set instance(WellnessRings? value) => _instance = value;

  factory WellnessRings() => _instance ?? (_instance = WellnessRings.internal());

  @protected
  WellnessRings.internal();

  @override
  Future<void> initService() async {
    _cacheFile = await _getCacheFile();
    await _initFromCache();
    await _loadFromNet();
    _initActiveRingsData();
    return super.initService();
  }

  //Init
  Future<bool> _initFromCache() async{
    return _loadContentJsonFromCache().then((Map<String, dynamic>? storedValues) {
        _wellnessRingsRecords = WellnessRingData.listFromJson(storedValues?["wellness_rings_data"]) ?? [];
        _wellnessRecords = WellnessRingRecord.listFromJson(storedValues?["wellness_ring_records"] ?? []);
        return true;
      });
  }

  bool _initActiveRingsData (){
    _activeWellnessRings = {};
    if(_wellnessRingsRecords?.isNotEmpty ?? false){
      for (WellnessRingData data in _wellnessRingsRecords!){
        if(_activeWellnessRings!.containsKey(data.id)){
          WellnessRingData? storedData = _activeWellnessRings![data.id];
          if((storedData?.timestamp ?? 0) < data.timestamp){
              _activeWellnessRings![data.id] = data; //TBD try storedData = data;
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

  Future<bool> _loadFromNet() async{
    //TBD network API
    // _storeWellnessRingData();
    return true;
  }
  /////

  //APIS
  Future<bool> addRing(WellnessRingData data) async {
    //TBD replace network API
    bool success = false;
    if(_wellnessRingsRecords == null){
      _wellnessRingsRecords = [];
    }
    if(canAddRing && (!(_activeWellnessRings?.containsKey(data.id) ?? false))){
      _wellnessRingsRecords!.add(data);
      _updateActiveRingsData();
      success = true;
    }
    _storeWellnessRingData();
    NotificationService().notify(notifyUserRingsUpdated);
    return success;
  }

  Future<bool> updateRing(WellnessRingData data) async {
    //TBD replace network API
    bool success = false;
    WellnessRingData? currentRingData = _activeWellnessRings?[data.id];
    if(currentRingData == null || currentRingData != data){
      if(_wellnessRingsRecords == null){
        _wellnessRingsRecords = [];
      }
      _wellnessRingsRecords!.add(data);
      _updateActiveRingsData();
      success = true;
      _storeWellnessRingData();
      NotificationService().notify(notifyUserRingsUpdated);
    }
    return success;
  }

  Future<bool> removeRing(WellnessRingData data) async {
    //TBD network API
    WellnessRingData? ringData = _activeWellnessRings?[data.id];
    if(ringData != null){
      _wellnessRingsRecords?.removeWhere((ringRecord) => ringRecord.id == data.id);
      _wellnessRecords?.removeWhere((ringRecord) => ringRecord.wellnessRingId == data.id);
      _updateActiveRingsData();
      _storeWellnessRingData();
      NotificationService().notify(notifyUserRingsUpdated);
      return true;
    }

    return false;
  }

  void addRecord(WellnessRingRecord record){
    Log.d("addRecord ${record.toJson()}");
    //TBD store
    bool alreadyAccomplished = _isAccomplished(record.wellnessRingId);
    _wellnessRecords?.add(record);
    NotificationService().notify(notifyUserRingsUpdated); //TBD add separate constant for Records updated
    if(alreadyAccomplished == false) {
      _checkForAccomplishment(record.wellnessRingId);
    }
    _storeWellnessRecords();
  }

  Future<List<WellnessRingData>?> loadWellnessRings() async {
    //TBD load from net
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
        WellnessRingData? ringData;
        try {
          ringData = (ringRecords?.isNotEmpty ?? false) ? _getActiveRingDataForDay(id: ringId, timestamp: ringRecords!.first.timestamp) : null;
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
      String? recordDayName = record.date != null? DateTimeUtils.localDateTimeToString(DateTimeUtils.midnight(record.date!)) : null;
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

  List<WellnessRingData>? _findRingData({required String id, int? beforeTimestamp, int? afterTimestamp}){
    if(_wellnessRingsRecords?.isNotEmpty ?? false){
      List<WellnessRingData> result = [];
      for(WellnessRingData record in _wellnessRingsRecords!){
        if(record.id == id
          && (beforeTimestamp == null || record.timestamp < beforeTimestamp)
          && (afterTimestamp == null  || record.timestamp > afterTimestamp)
        ){
          result.add(record);
        }
      }

      return result;
    }

    return null;
  }

  WellnessRingData? _getActiveRingDataForDay({required String id, int? timestamp}){
    if(timestamp!=null){
      DateTime? midnight = DateTimeUtils.midnight(DateTime.fromMillisecondsSinceEpoch(timestamp).add(Duration(days: 1))); //Border is at midnight the next day
      var foundData = _findRingData(id: id, beforeTimestamp: midnight?.millisecondsSinceEpoch);
      if(foundData?.isNotEmpty ?? false){
        return foundData!.last; // last to be the most up to date
      }
    }

    return null;
  }

  WellnessRingData? getRingData(String? id){
    return (id != null )? (_activeWellnessRings?[id] ): null;
  }

  //Total Completion
  int getTotalCompletionCount(String id){
    //Split records by date
    Map<String, List<WellnessRingRecord>> ringDateRecords = {};
    _wellnessRecords?.forEach((record) {
      String? recordDayName = record.date != null? DateFormat("yyyy-MM-dd").format(DateUtils.dateOnly(record.date!)) : null;
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
        WellnessRingData? ringData = _getActiveRingDataForDay(id: id,
            timestamp: dayRecords.first
                .timestamp); //We've filtered per day, so all records should return the same DayRingData, so just take the first one
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
        && ((DateTimeUtils.midnight(DateTime.now())?.millisecondsSinceEpoch ?? 0) < record.timestamp)));
    // ?.where((record) => ((DateTimeUtils.midnight(DateTime.now())?.millisecondsSinceEpoch ?? 0) < record.timestamp));// Today records

    double value = 0.0;
    selection?.forEach((record) {
      value += record.value;
    });
    return value;
  }

  List<WellnessRingData>? get wellnessRings{
    return _activeWellnessRings?.values.toList();
  }

  bool get canAddRing{
    return (_activeWellnessRings?.length ?? 0) < MAX_RINGS;
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

  //TBD Remove unnecessary public methods
  //TBD Reorder methods
  //TBD clan up
}