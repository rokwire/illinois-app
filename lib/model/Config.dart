
import 'package:rokwire_plugin/utils/utils.dart';

class ConfigAlert {
  final String? title;
  final String? message;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool? enabled;

  ConfigAlert({this.title, this.message, this.startTime, this.endTime, this.enabled });

  static ConfigAlert? fromJson(Map<String, dynamic>? json) => (json != null) ? ConfigAlert(
    title: JsonUtils.stringValue(json['title']),
    message: JsonUtils.stringValue(json['message']),
    startTime: DateTimeUtils.dateTimeFromSecondsSinceEpoch(JsonUtils.intValue(json['startTime']), isUtc: true),
    endTime: DateTimeUtils.dateTimeFromSecondsSinceEpoch(JsonUtils.intValue(json['endTime']), isUtc: true),
    enabled: JsonUtils.boolValue(json['enabled']),
  ) : null;

  @override
  bool operator ==(other) =>
    (other is ConfigAlert) &&
      (other.title == title) &&
      (other.message == message) &&
      (other.startTime == startTime) &&
      (other.endTime == endTime) &&
      (other.enabled == enabled);

  @override
  int get hashCode =>
    (title?.hashCode ?? 0) ^
    (message?.hashCode ?? 0) ^
    (startTime?.hashCode ?? 0) ^
    (endTime?.hashCode ?? 0) ^
    (enabled?.hashCode ?? 0);

  bool get isCurrent =>
    ((title?.isNotEmpty == true) || (message?.isNotEmpty == true)) &&
    (enabled != false) &&
    (startTime?.isBefore(DateTime.now().toUtc()) != false) &&
    (endTime?.isAfter(DateTime.now().toUtc()) != false);

  bool get hasTimeLimits => (startTime != null) || (endTime != null);
}