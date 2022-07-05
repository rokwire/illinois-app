import 'package:flutter/material.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessRingDefinition {
//  static final String _dateTimeFormat = 'yyyy-MM-ddTHH:mm:sssZ';
  String id;
  double goal;
  String? colorHex;
  String? name;
  String? unit;
  int timestamp;

  //helper property to avoid creating date everytime
  DateTime? date;

  WellnessRingDefinition({required this.id , this.name, required this.goal, this.date, this.unit = "times" , this.colorHex = "FF000000", required this.timestamp});

  static WellnessRingDefinition? fromJson(Map<String, dynamic>? json){
    if(json!=null) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(JsonUtils.intValue(json['timestamp'])??0);
      return WellnessRingDefinition(
          id:     JsonUtils.stringValue(json['id']) ?? "",
          goal:   JsonUtils.doubleValue(json['goal']) ?? 1.0,
          name:   JsonUtils.stringValue(json['name']),
          unit:   JsonUtils.stringValue(json['unit']),
          timestamp:   JsonUtils.intValue(json['timestamp']) ?? DateTime.now().millisecondsSinceEpoch,
          colorHex:  JsonUtils.stringValue(json['color']),
          date: date
      );
    }
    return null;
  }

  Map<String, dynamic> toJson(){
    Map<String, dynamic> json = {};
    json['id']     = id;
    json['goal']   = goal;
    json['name']   = name;
    json['unit']   = unit;
    json['color']  = colorHex;
    json['timestamp']  = timestamp;
    return json;
  }

  void updateFromOther(WellnessRingDefinition other){
    this.id = other.id;
    this.goal = other.goal;
    this.colorHex = other.colorHex;
    this.name= other.name;
    this.unit = other.unit;
    this.timestamp = other.timestamp;
    this.date = other.date != null ? DateTimeUtils().copyDateTime(other.date!): null;
  }

  @override
  bool operator ==(dynamic other) =>
      (other is WellnessRingDefinition) &&
          (id == other.id) &&
          (goal == other.goal) &&
          (colorHex == other.colorHex) &&
          (name == other.name) &&
          (timestamp == other.timestamp) &&
          (unit == other.unit);

  @override
  int get hashCode =>
      (id.hashCode) ^
      (goal.hashCode) ^
      (colorHex?.hashCode ?? 0) ^
      (name?.hashCode ?? 0) ^
      (timestamp.hashCode) ^
      (unit?.hashCode ?? 0);
  
  Color? get color{
    return this.colorHex!= null ? ColorUtils.fromHex(colorHex) : null;
  }

  static List<WellnessRingDefinition>? listFromJson(List<dynamic>? json) {
    List<WellnessRingDefinition>? values;
    if (json != null) {
      values = <WellnessRingDefinition>[];
      for (dynamic entry in json) {
        ListUtils.add(values, WellnessRingDefinition.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<WellnessRingDefinition>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (WellnessRingDefinition? value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }
}

class WellnessRingRecord {
  final String wellnessRingId;
  final double value;
  final int timestamp;

  //helper property to avoid creating date everytime
  DateTime? date;

  WellnessRingRecord(
      {required this.value, required this.timestamp, required this.wellnessRingId}){
    if(date==null){
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
  }

  static WellnessRingRecord? fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      return WellnessRingRecord(
        wellnessRingId: JsonUtils.stringValue(json['wellnessRingId']) ?? "",
        value: JsonUtils.doubleValue(json['value']) ?? 0.0,
        timestamp: JsonUtils.intValue(json['timestamp']) ?? 0,
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['wellnessRingId'] = wellnessRingId;
    json['value'] = value;
    json['timestamp'] = timestamp;
    return json;
  }

  @override
  bool operator ==(dynamic other) =>
      (other is WellnessRingRecord) &&
          (wellnessRingId == other.wellnessRingId) &&
          (value == other.value) &&
          (timestamp == other.timestamp);

  @override
  int get hashCode =>
      (wellnessRingId.hashCode) ^
      (value.hashCode) ^
      (timestamp.hashCode);

  static List<WellnessRingRecord>? listFromJson(List<dynamic>? json) {
    List<WellnessRingRecord>? values;
    if (json != null) {
      values = <WellnessRingRecord>[];
      for (dynamic entry in json) {
        ListUtils.add(values, WellnessRingRecord.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<WellnessRingRecord>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (WellnessRingRecord? value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }
}

class WellnessRingAccomplishment{
  WellnessRingDefinition ringData;
  double achievedValue;

  WellnessRingAccomplishment({required this.ringData, required this.achievedValue});
}