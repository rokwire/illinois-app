
import 'package:rokwire_plugin/utils/utils.dart';

class Reference{
  final String? name;
  final String? type;
  final String? referenceKey;

  Reference({this.name, this.type, this.referenceKey});

  static Reference? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Reference(
      name: JsonUtils.stringValue(json['name']),
      type: JsonUtils.stringValue(json['type']),
      referenceKey: JsonUtils.stringValue(json['reference_key']),

    );

  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'type': type,
      'reference_key': referenceKey
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }
}