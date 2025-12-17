
import 'package:rokwire_plugin/utils/utils.dart';

extension PayloadData on Map<String, dynamic> {

  String? get entityType => JsonUtils.stringValue(this['entity_type']);

  static const String groupEntityType = 'group';
  bool get isGroupEntityType => (entityType == groupEntityType);
  String? get groupEntityId => isGroupEntityType ? JsonUtils.stringValue(this['entity_id']) : null;
  String? get groupEntityName => isGroupEntityType ? JsonUtils.stringValue(this['entity_name']) : null;

  static const String eventEntityType = 'event';
  bool get isEventEntityType => (entityType?.startsWith(eventEntityType) == true); // 'event', 'event.self_checkin', 'event_attendance'
  String? get eventEntityId => isEventEntityType ? JsonUtils.stringValue(this['entity_id']) : null;
  String? get eventEntityName => isEventEntityType ? JsonUtils.stringValue(this['entity_name']) : null;
}