import 'package:rokwire_plugin/utils/utils.dart';

//////////////////////////////
/// LatLng

class LatLng {
  double? latitude;
  double? longitude;

  LatLng({this.latitude, this.longitude});

  // JSON serialization

  static LatLng? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? LatLng(
      latitude: JsonUtils.doubleValue(json['latitude']),
      longitude: JsonUtils.doubleValue(json['longitude']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "latitude": latitude,
      "longitude": longitude
    };
  }

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is LatLng) &&
    (latitude == other.latitude) &&
    (longitude == other.longitude);

  @override
  int get hashCode =>
    (latitude?.hashCode ?? 0) ^
    (longitude?.hashCode ?? 0);

  // JSON List Serialization

  static List<LatLng>? listFromJson(List<dynamic>? json) {
    List<LatLng>? values;
    if (json != null) {
      values = <LatLng>[];
      for (dynamic entry in json) {
        ListUtils.add(values, LatLng.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<LatLng>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = [];
      for (LatLng value in values) {
        json.add(value.toJson());
      }
    }
    return json;
  }
}