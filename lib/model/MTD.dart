import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/model/Location.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

///////////////////////////
// MTDStop

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

///////////////////////////
// MTDStops

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

///////////////////////////
// MTDRoute

class MTDRoute {
  final String? id;
  final String? shortName;
  final String? longName;
  final String? colorCode;
  final String? textColorCode;

  MTDRoute({this.id, this.shortName, this.longName, this.colorCode, this.textColorCode});

  // JSON serialization

  static MTDRoute? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDRoute(
      id: JsonUtils.stringValue(json['route_id']),
      shortName: JsonUtils.stringValue(json['route_short_name']),
      longName: JsonUtils.stringValue(json['route_long_name']),
      colorCode: JsonUtils.stringValue(json['route_color']),
      textColorCode: JsonUtils.stringValue(json['route_text_color']),
    ) : null;
  }

  toJson() => {
    'route_id': id,
    'route_short_name': shortName,
    'route_long_name': longName,
    'route_color': color,
    'route_text_color': textColor,
  };

  // Operations
  
  Color? get color => UiColors.fromHex(colorCode);
  Color? get textColor => UiColors.fromHex(textColorCode);

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDRoute) &&
    (id == other.id) &&
    (shortName == other.shortName) &&
    (longName == other.longName) &&
    (colorCode == other.colorCode) &&
    (textColorCode == other.textColorCode);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (shortName?.hashCode ?? 0) ^
    (longName?.hashCode ?? 0) ^
    (colorCode?.hashCode ?? 0) ^
    (textColorCode?.hashCode ?? 0);

  // JSON List Serialization

  static List<MTDRoute>? listFromJson(List<dynamic>? jsonList) {
    List<MTDRoute>? values;
    if (jsonList != null) {
      values = <MTDRoute>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, MTDRoute.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<MTDRoute>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (MTDRoute value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  // List Operations

  static List<MTDRoute>? mergeUiRoutes(List<MTDRoute>? sourceRoutes) {
    List<MTDRoute>? routes;
    if (sourceRoutes != null) {
      routes = <MTDRoute>[];
      for (MTDRoute route in sourceRoutes) {

        bool routeProcessed = false;
        for (MTDRoute processedRoute in routes) {
          if (route.isUiEqual(processedRoute)) {
            routeProcessed = true;
            break;
          }
        }
        if (!routeProcessed) {
          routes.add(route);
        }
      }

      routes.sort((MTDRoute route1, MTDRoute route2) {
        String? routeName1 = route1.shortName;
        String? routeName2 = route2.shortName;
        if ((routeName1 != null) && (routeName2 != null)) {
          int? routeNumber1 = int.tryParse(routeName1);
          int? routeNumber2 = int.tryParse(routeName2);
          if ((routeNumber1 != null) && (routeNumber2 != null)) {
            return routeNumber1.compareTo(routeNumber2);
          }
          else {
            return routeName1.compareTo(routeName2);
          }
        }
        return 0;
      });
    }
    return routes;
  }

  bool isUiEqual(MTDRoute other) =>
    (shortName == other.shortName) && (colorCode == other.colorCode) && (textColorCode == other.textColorCode);
}

///////////////////////////
// MTDRoutes

class MTDRoutes {
  final String? changesetId;
  final List<MTDRoute>? routes;
  
  MTDRoutes({this.changesetId, this.routes});

  // JSON serialization

  static MTDRoutes? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDRoutes(
      changesetId: JsonUtils.stringValue(json['changeset_id']),
      routes: MTDRoute.listFromJson(JsonUtils.listValue(json['routes'])),
    ) : null;
  }

  toJson() => {
    'changeset_id': changesetId,
    'routes': routes,
 };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDRoutes) &&
    (changesetId == other.changesetId) &&
    (DeepCollectionEquality().equals(routes, other.routes));

  @override
  int get hashCode =>
    (changesetId?.hashCode ?? 0) ^
    DeepCollectionEquality().hash(routes);
}

///////////////////////////
// MTDTrip

class MTDTrip {
  final String? id;
  final String? headsign;
  final String? direction;
  final String? routeId;
  final String? serviceId;
  final String? blockId;
  final String? shapeId;

  MTDTrip({this.id, this.headsign, this.direction, this.routeId, this.serviceId, this.blockId, this.shapeId});

  // JSON serialization

  static MTDTrip? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDTrip(
      id: JsonUtils.stringValue(json['trip_id']),
      headsign: JsonUtils.stringValue(json['trip_headsign']),
      direction: JsonUtils.stringValue(json['direction']),
      routeId: JsonUtils.stringValue(json['route_id']),
      serviceId: JsonUtils.stringValue(json['service_id']),
      blockId: JsonUtils.stringValue(json['block_id']),
      shapeId: JsonUtils.stringValue(json['shape_id']),
    ) : null;
  }

  toJson() => {
    'trip_id': id,
    'trip_headsign': headsign,
    'direction': direction,
    'route_id': routeId,
    'service_id': serviceId,
    'block_id': blockId,
    'shape_id': shapeId,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDTrip) &&
    (id == other.id) &&
    (headsign == other.headsign) &&
    (direction == other.direction) &&
    (routeId == other.routeId) &&
    (serviceId == other.serviceId) &&
    (blockId == other.blockId) &&
    (shapeId == other.shapeId);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (headsign?.hashCode ?? 0) ^
    (direction?.hashCode ?? 0) ^
    (routeId?.hashCode ?? 0) ^
    (serviceId?.hashCode ?? 0) ^
    (blockId?.hashCode ?? 0) ^
    (shapeId?.hashCode ?? 0);

  // JSON List Serialization

  static List<MTDTrip>? listFromJson(List<dynamic>? jsonList) {
    List<MTDTrip>? values;
    if (jsonList != null) {
      values = <MTDTrip>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, MTDTrip.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<MTDTrip>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (MTDTrip value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

///////////////////////////
// MTDStopTime

class MTDStopTime {
  final String? arrivalTimeString;
  final String? departureTimeString;
  final String? stopSequence;
  final String? stopId;
  final MTDTrip? trip;

  MTDStopTime({this.arrivalTimeString, this.departureTimeString, this.stopSequence, this.stopId, this.trip});

  // JSON serialization

  static MTDStopTime? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDStopTime(
      arrivalTimeString: JsonUtils.stringValue(json['arrival_time']),
      departureTimeString: JsonUtils.stringValue(json['departure_time']),
      stopSequence: JsonUtils.stringValue(json['stop_sequence']),
      stopId: JsonUtils.stringValue(json['stop_id']),
      trip: MTDTrip.fromJson(JsonUtils.mapValue(json['trip'])),
    ) : null;
  }

  toJson() => {
    'arrival_time': arrivalTimeString,
    'departure_time': departureTimeString,
    'stop_sequence': stopSequence,
    'stop_id': stopId,
    'trip': trip?.toJson(),
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDStopTime) &&
    (arrivalTimeString == other.arrivalTimeString) &&
    (departureTimeString == other.departureTimeString) &&
    (stopSequence == other.stopSequence) &&
    (stopId == other.stopId) &&
    (trip == other.trip);

  @override
  int get hashCode =>
    (arrivalTimeString?.hashCode ?? 0) ^
    (departureTimeString?.hashCode ?? 0) ^
    (stopSequence?.hashCode ?? 0) ^
    (stopId?.hashCode ?? 0) ^
    (trip?.hashCode ?? 0);

  // JSON List Serialization

  static List<MTDStopTime>? listFromJson(List<dynamic>? jsonList) {
    List<MTDStopTime>? values;
    if (jsonList != null) {
      values = <MTDStopTime>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, MTDStopTime.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<MTDStopTime>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (MTDStopTime value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

///////////////////////////
// MTDOrgDest

class MTDOrgDest {
  final String? stopId;
  
  MTDOrgDest({this.stopId});

  // JSON serialization

  static MTDOrgDest? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDOrgDest(
      stopId: JsonUtils.stringValue(json['stop_id']),
    ) : null;
  }

  toJson() => {
    'stop_id': stopId,
 };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDOrgDest) &&
    (stopId == other.stopId);

  @override
  int get hashCode =>
    (stopId?.hashCode ?? 0);
}

///////////////////////////
// MTDLocation

class MTDLocation {
  final double? latitude;
  final double? longitude;
  
  MTDLocation({this.latitude, this.longitude});

  // JSON serialization

  static MTDLocation? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDLocation(
      latitude: JsonUtils.doubleValue(json['lat']),
      longitude: JsonUtils.doubleValue(json['lon']),
    ) : null;
  }

  toJson() => {
    'lat': latitude,
    'lon': longitude,
 };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDLocation) &&
    (latitude == other.latitude) &&
    (longitude == other.longitude);

  @override
  int get hashCode =>
    (latitude?.hashCode ?? 0) ^
    (longitude?.hashCode ?? 0);
}

///////////////////////////
// MTDDeparture

class MTDDeparture {
  final String? stopId;
  final String? headsign;
  final String? vehicleId;

  final bool? isMonitored;
  final bool? isScheduled;
  final bool? isIStop;

  final String? scheduledString;
  final String? expectdString;
  final int? expectedMins;

  final MTDRoute? route;
  final MTDTrip? trip;
  final MTDOrgDest? origin;
  final MTDOrgDest? destination;
  final MTDLocation? location;

  MTDDeparture({this.stopId, this.headsign, this.vehicleId,
    this.isMonitored, this.isScheduled, this.isIStop,
    this.scheduledString, this.expectdString, this.expectedMins,
    this.route, this.trip, this.origin, this.destination, this.location});

  // JSON serialization

  static MTDDeparture? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDDeparture(
      stopId: JsonUtils.stringValue(json['stop_id']),
      headsign: JsonUtils.stringValue(json['headsign']),
      vehicleId: JsonUtils.stringValue(json['vehicle_id']),

      isMonitored: JsonUtils.boolValue(json['is_monitored']),
      isScheduled: JsonUtils.boolValue(json['is_scheduled']),
      isIStop: JsonUtils.boolValue(json['is_istop']),

      scheduledString: JsonUtils.stringValue(json['scheduled']),
      expectdString: JsonUtils.stringValue(json['expected']),
      expectedMins: JsonUtils.intValue(json['expected_mins']),

      route: MTDRoute.fromJson(JsonUtils.mapValue(json['route'])),
      trip: MTDTrip.fromJson(JsonUtils.mapValue(json['trip'])),
      origin: MTDOrgDest.fromJson(JsonUtils.mapValue(json['origin'])),
      destination: MTDOrgDest.fromJson(JsonUtils.mapValue(json['destination'])),
      location: MTDLocation.fromJson(JsonUtils.mapValue(json['location'])),
    ) : null;
  }

  toJson() => {
    'stop_id': stopId,
    'headsign': headsign,
    'vehicle_id': vehicleId,

    'is_monitored': isMonitored,
    'is_scheduled':isScheduled,
    'is_istop': isIStop,

    'scheduled': scheduledString,
    'expected': expectdString,
    'expected_mins': expectedMins,

    'route': route?.toJson(),
    'trip': trip?.toJson(),
    'origin': origin?.toJson(),
    'destination': destination?.toJson(),
    'location': location?.toJson(),
  };

  // Operations

  DateTime? get scheduledTime =>
    DateTimeUtils.dateTimeFromString(scheduledString, format: 'yyyy-MM-ddTHH:mmZ');

  DateTime? get expectedTime =>
    DateTimeUtils.dateTimeFromString(expectdString, format: 'yyyy-MM-ddTHH:mmZ');

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDDeparture) &&
    
    (stopId == other.stopId) &&
    (headsign == other.headsign) &&
    (vehicleId == other.vehicleId) &&
    
    (isMonitored == other.isMonitored) &&
    (isScheduled == other.isScheduled) &&
    (isIStop == other.isIStop) &&

    (scheduledString == other.scheduledString) &&
    (expectdString == other.expectdString) &&
    (expectedMins == other.expectedMins) &&

    (route == other.route) &&
    (trip == other.trip) &&
    (origin == other.origin) &&
    (destination == other.destination) &&
    (location == other.location);

  @override
  int get hashCode =>
    (stopId?.hashCode ?? 0) ^
    (headsign?.hashCode ?? 0) ^
    (vehicleId?.hashCode ?? 0) ^
    
    (isMonitored?.hashCode ?? 0) ^
    (isScheduled?.hashCode ?? 0) ^
    (isIStop?.hashCode ?? 0) ^

    (scheduledString?.hashCode ?? 0) ^
    (expectdString?.hashCode ?? 0) ^
    (expectedMins?.hashCode ?? 0) ^

    (route?.hashCode ?? 0) ^
    (trip?.hashCode ?? 0) ^
    (origin?.hashCode ?? 0) ^
    (destination?.hashCode ?? 0) ^
    (location?.hashCode ?? 0);

  // JSON List Serialization

  static List<MTDDeparture>? listFromJson(List<dynamic>? jsonList) {
    List<MTDDeparture>? values;
    if (jsonList != null) {
      values = <MTDDeparture>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, MTDDeparture.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<MTDDeparture>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (MTDDeparture value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}