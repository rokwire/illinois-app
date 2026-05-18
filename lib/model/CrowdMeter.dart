import 'package:rokwire_plugin/utils/utils.dart';

enum WeekDay { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class CrowdMeterWeek {
  final String id;
  final String? crowdType;
  final List<CrowdMeterDay>? days;

  CrowdMeterWeek({
    required this.id,
    this.crowdType, this.days
  });

  static CrowdMeterWeek? fromJson(Map<String, dynamic>? json) => (json != null) ? CrowdMeterWeek(
    id: JsonUtils.stringValue(json['LocationID']) ?? '',
    crowdType: JsonUtils.stringValue(json['CrowdType']),
    days: CrowdMeterDay.listFromJson(JsonUtils.listValue(json['days'])),
  ) : null;

  @override
  bool operator ==(other) =>
      (other is CrowdMeterWeek) &&
          (other.id == id) &&
          (other.crowdType == crowdType) &&
          (other.days == days);

  @override
  int get hashCode =>
      id.hashCode ^
      (crowdType?.hashCode ?? 0) ^
      (days?.hashCode ?? 0);
}
class CrowdMeterDay{
  final WeekDay? day;
  final List<int>? busyLevels;

  CrowdMeterDay({
    this.day, this.busyLevels

  });

  static CrowdMeterDay? fromJson(Map<String, dynamic>? json) => (json != null) ? CrowdMeterDay(
    day: _dayFromString(JsonUtils.stringValue(json['Day'])),
    busyLevels: JsonUtils.listIntsValue(json['BusyLevels']),
  ) : null;

  static WeekDay? _dayFromString(String? day) {
    switch (day) {
      case "Monday": return WeekDay.monday;
      case "Tuesday": return WeekDay.tuesday;
      case "Wednesday": return WeekDay.wednesday;
      case "Thursday": return WeekDay.thursday;
      case "Friday": return WeekDay.friday;
      case "Saturday": return WeekDay.saturday;
      case "Sunday": return WeekDay.sunday;
      default: return null;
    }
  }

  static List<CrowdMeterDay> listFromJson(List<dynamic>? jsonList) {
    List<CrowdMeterDay>? values = [];
    if (jsonList != null) {
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, CrowdMeterDay.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  @override
  bool operator ==(other) =>
      (other is CrowdMeterDay) &&
          (other.day == day) &&
          (other.busyLevels == busyLevels);

  @override
  int get hashCode =>
      (day?.hashCode ?? 0) ^
      (busyLevels?.hashCode ?? 0);
}
