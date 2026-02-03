import 'package:rokwire_plugin/utils/utils.dart';

enum WeekDay { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class CrowdMeterWeek {
  final String? crowdType;
  final List<CrowdMeterDay>? days;

  CrowdMeterWeek({
    this.crowdType, this.days
  });

  static CrowdMeterWeek? fromJson(Map<String, dynamic>? json) => (json != null) ? CrowdMeterWeek(
    crowdType: JsonUtils.stringValue(json['crowdType']),
    days: CrowdMeterDay.listFromJson(JsonUtils.listValue(json['days'])),
  ) : null;

  @override
  bool operator ==(other) =>
      (other is CrowdMeterWeek) &&
          (other.crowdType == crowdType) &&
          (other.days == days);

  @override
  int get hashCode =>
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
    day: _dayFromString(JsonUtils.stringValue(json['day'])),
    busyLevels: JsonUtils.listIntsValue(json['busyLevels']),
  ) : null;

  static WeekDay? _dayFromString(String? day) {
    switch (day) {
      case "monday": return WeekDay.monday;
      case "tuesday": return WeekDay.tuesday;
      case "wednesday": return WeekDay.wednesday;
      case "thursday": return WeekDay.thursday;
      case "friday": return WeekDay.friday;
      case "saturday": return WeekDay.saturday;
      case "sunday": return WeekDay.sunday;
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
