import 'package:collection/collection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/model/Location.dart';
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

  static MTDStop? nearestStopInList(List<MTDStop>? stops, { LatLng? location }) {
    MTDStop? nearestStop;
    if ((stops != null) && (location != null) && (location.latitude != null) && (location.longitude != null)) {
      double? nearestDistance;
      for (MTDStop stop in stops) {
        if ((stop.latitude != null) && (stop.longitude != null)) {
          double distance = Geolocator.distanceBetween(location.latitude!, location.longitude!, stop.latitude!, stop.longitude!);
          if ((nearestDistance == null) || (nearestDistance > distance)) {
            nearestStop = stop;
            nearestDistance = distance;
          }
        }
      }
    }
    return nearestStop;
  }

  static List<MTDStop>? stopInList(List<MTDStop>? stops, { String? name, LatLng? location, double locationThresholdDistance = 1 /* in meters */ }) {
    List<MTDStop>? result;
    if (stops != null) {
      for (MTDStop stop in stops) {
        List<MTDStop>? pointsResult = stopInList(stop.points, name: name, location: location, locationThresholdDistance: locationThresholdDistance);
        if ((pointsResult != null) && pointsResult.isNotEmpty) {
          if (result != null) {
            result.addAll(pointsResult);
          }
          else {
            result = pointsResult;
          }
        }
        if (stop.match(name: name, location: location, locationThresholdDistance: locationThresholdDistance)) {
          if (result != null) {
            result.add(stop);
          }
          else {
            result = <MTDStop>[stop];
          }
        }
      }
    }
    return result;
  }

  bool match({ String? name, LatLng? location, double locationThresholdDistance = 1 /* in meters */ }) {
    
    if ((name != null) && (name != this.name)) {
      return false;
    }
    
    if ((location != null) && (location.latitude != null) && (location.longitude != null) &&
        ((this.latitude == null) || (this.longitude == null) ||
         (Geolocator.distanceBetween(location.latitude!, location.longitude!, this.latitude!, this.longitude!) > locationThresholdDistance)))
    {
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

  MTDStop? findStop({ String? name, LatLng? location, double locationThresholdDistance = 10 /* in meters */ }) {
    List<MTDStop>? result = MTDStop.stopInList(stops, name: name, location: location, locationThresholdDistance: locationThresholdDistance);
    if ((result != null) && result.isNotEmpty) {
      MTDStop? nearestStop = (1 < result.length) ? MTDStop.nearestStopInList(result, location: location) : null;
      return nearestStop ?? result.first;
    }
    return null;
  }
}