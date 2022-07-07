import 'package:flutter/material.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessRingDefinition {
  static final String _dateTimeFormat = 'yyyy-MM-ddTHH:mm:sssZ';

  String id;
  double goal;
  String? colorHex;
  String? name;
  String? unit;
  DateTime? dateCreatedUtc;

  WellnessRingDefinition({required this.id , this.name, required this.goal, this.dateCreatedUtc, this.unit = "times" , this.colorHex = "FF000000"});

  static WellnessRingDefinition? fromJson(dynamic json){
    if(json!=null && json is Map) {
      return WellnessRingDefinition(
          id:     JsonUtils.stringValue(json['id']) ?? "",
          goal:   JsonUtils.doubleValue(json['value']) ?? 1.0,
          name:   JsonUtils.stringValue(json['name']),
          unit:   JsonUtils.stringValue(json['unit']),
          colorHex:  JsonUtils.stringValue(json['color_hex']),
          dateCreatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_created']), format: _dateTimeFormat, isUtc: true),
      );
    }
    return null;
  }

  Map<String, dynamic> toJson(){
    Map<String, dynamic> json = {};
    json['id']     = id;
    json['value']   = goal;
    json['name']   = name;
    json['unit']   = unit;
    json['color_hex']  = colorHex;
    json['date_created']  = DateTimeUtils.utcDateTimeToString(dateCreatedUtc);
    return json;
  }

  void updateFromOther(WellnessRingDefinition other){
    this.id = other.id;
    this.goal = other.goal;
    this.colorHex = other.colorHex;
    this.name= other.name;
    this.unit = other.unit;
    this.dateCreatedUtc = other.dateCreatedUtc != null ? DateTimeUtils().copyDateTime(other.dateCreatedUtc!): null;
  }

  @override
  bool operator ==(dynamic other) =>
      (other is WellnessRingDefinition) &&
          (id == other.id) &&
          (goal == other.goal) &&
          (colorHex == other.colorHex) &&
          (name == other.name) &&
          (dateCreatedUtc == other.dateCreatedUtc) &&
          (unit == other.unit);

  @override
  int get hashCode =>
      (id.hashCode) ^
      (goal.hashCode) ^
      (colorHex?.hashCode ?? 0) ^
      (name?.hashCode ?? 0) ^
      (dateCreatedUtc.hashCode) ^
      (unit?.hashCode ?? 0);
  
  Color? get color{
    return this.colorHex!= null ? ColorUtils.fromHex(colorHex) : null;
  }

  DateTime get date{
    return dateCreatedUtc?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  int get timestamp{
    return this.dateCreatedUtc?.millisecondsSinceEpoch ?? 0;
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
  static final String _dateTimeFormat = 'yyyy-MM-ddTHH:mm:sssZ';
  final String wellnessRingId;
  final double value;
  final DateTime? dateCreatedUtc;

  WellnessRingRecord({required this.value, required this.wellnessRingId, this.dateCreatedUtc,});

  static WellnessRingRecord? fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      return WellnessRingRecord(
        wellnessRingId: JsonUtils.stringValue(json['wellnessRingId']) ?? "",
        value: JsonUtils.doubleValue(json['value']) ?? 0.0,
        dateCreatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_created']), format: _dateTimeFormat, isUtc: true),
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['wellnessRingId'] = wellnessRingId;
    json['value'] = value;
    json['date_created']  = DateTimeUtils.utcDateTimeToString(dateCreatedUtc);
    return json;
  }

  @override
  bool operator ==(dynamic other) =>
      (other is WellnessRingRecord) &&
          (wellnessRingId == other.wellnessRingId) &&
          (value == other.value) &&
          (dateCreatedUtc == other.dateCreatedUtc);

  @override
  int get hashCode =>
      (wellnessRingId.hashCode) ^
      (value.hashCode) ^
      (dateCreatedUtc.hashCode);

  DateTime get date{
    return dateCreatedUtc?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

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