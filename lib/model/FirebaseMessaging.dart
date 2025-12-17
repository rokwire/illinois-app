
import 'package:rokwire_plugin/utils/utils.dart';

extension PayloadData on Map<String, dynamic> {
  static const String groupEntityType = 'group';

  String? get entityType => JsonUtils.stringValue(this['entity_type']);
  bool get isGroupEntityType => (entityType == groupEntityType);

  String? get groupEntityId => isGroupEntityType ? JsonUtils.stringValue(this['entity_id']) : null;
  String? get groupEntityName => isGroupEntityType ? JsonUtils.stringValue(this['entity_name']) : null;
}