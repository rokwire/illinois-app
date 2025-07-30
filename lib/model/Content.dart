import 'package:rokwire_plugin/utils/utils.dart';

class ContentAlert {
  final String? title;
  final String? titleHtml;
  final String? message;
  final String? messageHtml;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool? enabled;

  ContentAlert({
    this.title, this.titleHtml,
    this.message, this.messageHtml,
    this.startTime, this.endTime,
    this.enabled
  });

  static ContentAlert? fromJson(Map<String, dynamic>? json) => (json != null) ? ContentAlert(
    title: JsonUtils.stringValue(json['title']),
    titleHtml: JsonUtils.stringValue(json['titleHtml']),
    message: JsonUtils.stringValue(json['message']),
    messageHtml: JsonUtils.stringValue(json['messageHtml']),
    startTime: DateTimeUtils.dateTimeFromSecondsSinceEpoch(JsonUtils.intValue(json['startTime']), isUtc: true),
    endTime: DateTimeUtils.dateTimeFromSecondsSinceEpoch(JsonUtils.intValue(json['endTime']), isUtc: true),
    enabled: JsonUtils.boolValue(json['enabled']),
  ) : null;

  @override
  bool operator ==(other) =>
    (other is ContentAlert) &&
      (other.title == title) &&
      (other.titleHtml == titleHtml) &&
      (other.message == message) &&
      (other.messageHtml == messageHtml) &&
      (other.startTime == startTime) &&
      (other.endTime == endTime) &&
      (other.enabled == enabled);

  @override
  int get hashCode =>
    (title?.hashCode ?? 0) ^
    (titleHtml?.hashCode ?? 0) ^
    (message?.hashCode ?? 0) ^
    (messageHtml?.hashCode ?? 0) ^
    (startTime?.hashCode ?? 0) ^
    (endTime?.hashCode ?? 0) ^
    (enabled?.hashCode ?? 0);

  bool get isCurrent =>
    ((title?.isNotEmpty == true) || (titleHtml?.isNotEmpty == true) || (message?.isNotEmpty == true) || (messageHtml?.isNotEmpty == true)) &&
    (enabled != false) &&
    (startTime?.isBefore(DateTime.now().toUtc()) != false) &&
    (endTime?.isAfter(DateTime.now().toUtc()) != false);

  bool get hasTimeLimits => (startTime != null) || (endTime != null);
}