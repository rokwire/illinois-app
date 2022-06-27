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
  static const List<Map<String,dynamic>> predefinedRings = [
    {'name': "Hobby", 'goal': 2, 'color': 'e45434', 'id': "id_predefined_0", 'unit':'session', "description":"description"},
    {'name': "Physical Activity", 'goal': 16, 'color': 'FF4CAF50', 'id': "id_predefined_1", 'unit':'activity', "description":"description"},
    {'name': "Mindfulness", 'goal': 10, 'color': 'FF2196F3' , 'id': "id_predefined_2", 'unit':'moment', "description":"description"},
  ];

  // ignore: unused_field
  final List <WellnessRingRecord> _mocWellnessRecords = [
    WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: "id_0",),
    WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: "id_0"),
    WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: "id_0"),
    WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: "id_1"),
    WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: "id_1"),
    WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: "id_2"),
  ];

  File? _cacheFile;

  List<WellnessRingData>? _wellnessRings;
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
    _loadFromNet();
    return super.initService();
  }

  Future<void> _initFromCache() async{
    _loadContentJsonFromCache().then((Map<String, dynamic>? storedValues) {
      _wellnessRings = WellnessRingData.listFromJson(storedValues?["wellness_rings_data"]) ?? [];
      _wellnessRecords = WellnessRingRecord.listFromJson(storedValues?["wellness_ring_records"] ?? []);
    }
    );
    // _wellnessRings =  WellnessRingData.listFromJson(predefinedRings);//Storage().userWellnessRings; //TBD implement from file //TBD Moc for now
    // _wellnessRecords = []; //_mocWellnessRecords; //TBD Implement from file //TBD Moc for now
  }

  void _loadFromNet(){
    //TBD network API
    // _storeWellnessRingData();
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
      "wellness_rings_data": _wellnessRings,
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

  void addRing(WellnessRingData data) async {
    //TBD replace network API
    if(_wellnessRings == null){
      _wellnessRings = [];
    }
    if(canAddRing){
      _wellnessRings!.add(data);
    }
    NotificationService().notify(notifyUserRingsUpdated);
    _storeWellnessRingData();
  }

  void updateRing(WellnessRingData data) async {
    //TBD replace network API
    WellnessRingData? ringData = _wellnessRings?.firstWhere((ring) => ring.id == data.id);
    if(ringData != null && ringData != data){
      ringData.updateFromOther(data);
    }
    NotificationService().notify(notifyUserRingsUpdated);
    _storeWellnessRingData();
  }

  void removeRing(WellnessRingData data) async {
    //TBD network API
    WellnessRingData? ringData = _wellnessRings?.firstWhere((ring) => ring.id == data.id);
    if(ringData != null){
      _wellnessRings?.remove(ringData);
    }
    NotificationService().notify(notifyUserRingsUpdated);
    _storeWellnessRingData();
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

  double getRingDailyValue(String wellnessRingId){
    Iterable<WellnessRingRecord>? selection = _wellnessRecords?.where((record) =>
    ((record.wellnessRingId == wellnessRingId)
        && ((DateTimeUtils.midnight(DateTime.now())?.millisecondsSinceEpoch ?? 0) < record.timestamp)));
    // ?.where((record) => ((DateTimeUtils.midnight(DateTime.now())?.millisecondsSinceEpoch ?? 0) < record.timestamp));// Today records

    double value = 0.0;
    selection?.forEach((record) {
      value += record.value;
    });
    return value; //TBD implement
  }

  void _checkForAccomplishment(String id){
    if(_isAccomplished(id)){
      NotificationService().notify(notifyUserRingsAccomplished, id);
    }
  }

  bool _isAccomplished(String id){
    return(getRingData(id)?.goal ?? 0) <= getRingDailyValue(id);
  }

  bool get canAddRing{
    return (_wellnessRings?.length ?? 0) < MAX_RINGS;
  }

  void _storeWellnessRingData(){
    _saveRingsDataToCache();
  }

  void _storeWellnessRecords(){
    _saveRingsDataToCache();
  }

  Future<List<WellnessRingData>?> getWellnessRings() async {
    if(_wellnessRings == null){ //TBD REMOVE workaround while we are not added to the Services
      _initFromCache();
    }
    return _wellnessRings; //TBD load from net
  }

  List<WellnessRingData>? get wellnessRings{
    return _wellnessRings;
  }

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
    WellnessRingData? ringData = _wellnessRings?.firstWhere((element) => element.id == id);
    if(ringData!=null){
      double goal = ringData.goal;//TBD implement updated Rings(will be list of data with update time) get the Data matching the ime period
      for (List<WellnessRingRecord> dayRecords in ringDateRecords.values){
        int dayCount = 0;
        for(WellnessRingRecord record in dayRecords){
          dayCount += record.value.toInt();
        }
        if(dayCount >= goal){
          //Match
          count++;
        }
      }
    }
    return count;
  }

  Map<String, List<WellnessRingAccomplishment>>? getAccomplishmentsHistory(){
    Map<String, List<WellnessRingAccomplishment>> history = {/*"2022-06014":[WellnessRingData(id: '0', timestamp: DateTime.now().millisecondsSinceEpoch, goal: 1, name: "Test" )]*/};

    //First split by day and id
    Map<String, Map<String, List<WellnessRingRecord>>> splitedRecords = _splitRecordsByDay();

    //get Ring data for completed ones
    for (var dayRecords in splitedRecords.entries){

      for(var ringDayRecords in dayRecords.value.entries){
        String ringId = ringDayRecords.key;
        WellnessRingData? ringData = WellnessRings()._wellnessRings?.firstWhere((element) => element.id == ringId);
        if(ringData!=null) {
          double goal = ringData.goal;
          List<WellnessRingRecord>? ringRecords = dayRecords.value[ringData.id];
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

              WellnessRingAccomplishment? completionData = accomplishmentsForThatDay.firstWhere((element) => element.ringData.id == ringData.id,
                  orElse: () => WellnessRingAccomplishment(ringData: ringData, achievedValue: dayCount)
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
      String? recordDayName = record.date != null? DateFormat("dddd,MMMM dd").format(DateUtils.dateOnly(record.date!)) : null;
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

  String getTotalCompletionCountString(String id){
    int count = getTotalCompletionCount(id);
    switch(count){
      case 1 : return "1st";
      case 2 : return "2nd";
      default :return "${count}rd";
    }
  }

  double getRingDailyCompletion(String id) {
    double value = getRingDailyValue(id);
    double goal = 1;
    try{ goal = getRingData(id)?.goal ?? 0;
    } catch (e){
      print(e);
      return 0;// if we have no records yet

    }
    return goal == 0 || value == 0 ? 0 :
    value / goal;
  }

  WellnessRingData? getRingData(String id){
    return wellnessRings?.firstWhere((ring) => ring.id == id);
  }
}