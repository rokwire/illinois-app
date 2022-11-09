import 'package:collection/collection.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class MTDStop {
  final String? id;
  final String? name;
  final String? code;
  final double? distance;
  final double? latitude;
  final double? longitude;
  final List<MTDStop>? points;

  MTDStop({this.id, this.name, this.code, this.distance, this.latitude, this.longitude, this.points});

  // JSON serialization

  static MTDStop? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDStop(
      id: JsonUtils.stringValue(json['stop_id']),
      name: JsonUtils.stringValue(json['stop_name']),
      code: JsonUtils.stringValue(json['code']),
      distance: JsonUtils.doubleValue(json['distance']),
      latitude: JsonUtils.doubleValue(json['stop_lat']),
      longitude: JsonUtils.doubleValue(json['stop_lon']),
      points: MTDStop.listFromJson(JsonUtils.listValue(json['stop_points'])),
    ) : null;
  }

  toJson() => {
    'stop_id': id,
    'stop_name': name,
    'code': code,
    'distance': distance,
    'stop_lat': latitude,
    'stop_lon': longitude,
    'stop_points': MTDStop.listToJson(points),
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDStop) &&
    (id == other.id) &&
    (name == other.name) &&
    (code == other.code) &&
    (distance == other.distance) &&
    (latitude == other.latitude) &&
    (longitude == other.longitude) &&
    (DeepCollectionEquality().equals(points, other.points));

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (code?.hashCode ?? 0) ^
    (distance?.hashCode ?? 0) ^
    (latitude?.hashCode ?? 0) ^
    (longitude?.hashCode ?? 0) ^
    DeepCollectionEquality().hash(points);

  // JSON List Serialization

  static List<MTDStop>? listFromJson(List<dynamic>? jsonList) {
    List<MTDStop>? values;
    if (jsonList != null) {
      values = <MTDStop>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, MTDStop.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<MTDStop>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (MTDStop value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  // List Lookup

  static MTDStop? stopInList(List<MTDStop>? stops, { String? name, double? latitude, double? longitude, double locationPrecision = 0.000001 }) {
    if (stops != null) {
      for (MTDStop stop in stops) {
        MTDStop? stopPoint = stopInList(stop.points, name: name, latitude: latitude, longitude: longitude, locationPrecision: locationPrecision );
        if (stopPoint != null) {
          return stopPoint;
        }
        if (stop.match(name: name, latitude: latitude, longitude: longitude, locationPrecision: locationPrecision)) {
          return stop;
        }
      }
    }
    return null;
  }

  bool match({ String? name, double? latitude, double? longitude, double locationPrecision = 0.000001 }) {
    
    if ((name != null) && (name != this.name)) {
      return false;
    }
    
    if ((latitude != null) && ((this.latitude == null) || ((latitude - this.latitude!).abs() > locationPrecision))) {
      return false;
    }
    
    if ((longitude != null) && ((this.longitude == null) || ((longitude - this.longitude!).abs() > locationPrecision))) {
      return false;
    }

    return true;
  }
}

class MTDStops {
  final String? changesetId;
  final List<MTDStop>? stops;
  
  MTDStops({this.changesetId, this.stops});

  // JSON serialization

  static MTDStops? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDStops(
      changesetId: JsonUtils.stringValue(json['changeset_id']),
      stops: MTDStop.listFromJson(JsonUtils.listValue(json['stops'])),
    ) : null;
  }

  toJson() => {
    'changeset_id': changesetId,
    'stops': stops,
 };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDStops) &&
    (changesetId == other.changesetId) &&
    (DeepCollectionEquality().equals(stops, other.stops));

  @override
  int get hashCode =>
    (changesetId?.hashCode ?? 0) ^
    DeepCollectionEquality().hash(stops);

  // Operations

  MTDStop? findStop({ String? name, double? latitude, double? longitude, double locationPrecision = 0.000001 }) {
    return MTDStop.stopInList(stops, name: name, latitude: latitude, longitude: longitude, locationPrecision: locationPrecision);
  }
}