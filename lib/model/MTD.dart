import 'dart:collection';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/model/Location.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

///////////////////////////
// MTDStop

class MTDStop with Explore implements Favorite {
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

  // Copy
  
  factory MTDStop.fromOther(MTDStop? other, { String? id, String? name, String? code, double? distance, double? latitude, double? longitude, List<MTDStop>? points}) {
    return MTDStop(
      id: id ?? other?.id,
      name: name ?? other?.name,
      code: code ?? other?.code,
      distance: distance ?? other?.distance,
      latitude: latitude ?? other?.latitude,
      longitude: longitude ?? other?.longitude,
      points: points ?? other?.points,
    );
  }

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

  static List<MTDStop>? stopsInList(List<MTDStop>? stops, { String? name, LatLng? location, double locationThresholdDistance = 1 /* in meters */ }) {
    List<MTDStop>? result;
    if (stops != null) {
      for (MTDStop stop in stops) {
        List<MTDStop>? pointsResult = stopsInList(stop.points, name: name, location: location, locationThresholdDistance: locationThresholdDistance);
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

  static List<MTDStop>? searchInList(List<MTDStop>? stops, { String? search } ) {
    List<MTDStop>? result;
    if ((stops != null) && (search != null)) {
      for (MTDStop stop in stops) {
        MTDStop? foundStop;
        List<MTDStop>? foundPoints = searchInList(stop.points, search: search);
        if ((foundPoints != null) && foundPoints.isNotEmpty) {
          foundStop = MTDStop.fromOther(stop, points: foundPoints);
        }
        else if (stop._matchSearch(search)) {
          foundStop = stop;
        }

        if (foundStop != null) {
          if (result != null) {
            result.add(foundStop);
          }
          else {
            result = <MTDStop>[foundStop];
          }
        }
      }
    }
    return result;
  }

  bool match({ String? search, String? name, LatLng? location, double locationThresholdDistance = 1 /* in meters */ }) {
    
    if ((name != null) && (name != this.name)) {
      return false;
    }
    
    if ((location != null) && (location.latitude != null) && (location.longitude != null) && !_matchLocation(location, thresholdDistance: locationThresholdDistance)) {
      return false;
    }

    if ((search != null) && !_matchSearch(search)) {
      return false;
    }
    
    return true;
  }

  bool _matchLocation(LatLng location, { double thresholdDistance = 1 /* in meters */ }) =>
    (location.latitude != null) && (location.longitude != null) &&
    (this.latitude != null) && (this.longitude != null) &&
    (Geolocator.distanceBetween(location.latitude!, location.longitude!, this.latitude!, this.longitude!) < thresholdDistance);

  bool _matchSearch(String search) =>
    (id?.toLowerCase().contains(search) ?? false) ||
    (name?.toLowerCase().contains(search) ?? false) ||
    (code?.toLowerCase().contains(search) ?? false);

  // List Retrieval

  static List<MTDStop>? stopsInList2(List<MTDStop>? stops, { LinkedHashSet<String>? stopIds }) {
    if ((stops != null) && (stopIds != null)) {
      Map<String, MTDStop> stopsMap = <String, MTDStop>{};
      _mapStops(stopsMap, stops: stops, stopIds: stopIds);

      List<MTDStop> result = <MTDStop>[];
      if (stopsMap.isNotEmpty) {
        for (String stopId in stopIds) {
          MTDStop? stop = stopsMap[stopId];
          if (stop != null) {
            result.add(stop);
          }
        }
      }
      
      return result;
    }
    return null;
  }

  static void _mapStops(Map<String, MTDStop> stopsMap, { List<MTDStop>? stops, Set<String>? stopIds}) {
    if ((stops != null) && (stopIds != null)) {
      for(MTDStop stop in stops) {
        String? stopId = stop.id;
        if ((stopId != null) && stopIds.contains(stopId)) {
          stopsMap[stopId] = stop;
        }
        if (stop.points != null) {
          _mapStops(stopsMap, stops: stop.points, stopIds: stopIds);
        }
      }
    }
  }

  static MTDStop? stopInList(List<MTDStop>? stops, { String? stopId }) {
    return _mapStop(stops: stops, stopId: stopId);
  }

  static MTDStop? _mapStop({ List<MTDStop>? stops, String? stopId}) {
    if ((stops != null) && (stopId != null)) {
      for(MTDStop stop in stops) {
        String? stopEntryId = stop.id;
        if ((stopEntryId != null) && (stopId == stopEntryId)) {
          return stop;
        }
        if (stop.points != null) {
          MTDStop? result = _mapStop(stops: stop.points, stopId: stopId);
          if (result != null) {
            return result;
          }
        }
      }
    }
    return null;
  }

  // Center location

  LatLng? get position => ((latitude != null) && (longitude != null)) ? LatLng(latitude: latitude, longitude: longitude) : null;

  LatLng? get anyPosition => position ?? (CollectionUtils.isNotEmpty(points) ? points?.first.anyPosition : null);

  LatLng? get centerPoint {
    double pi = math.pi / 180;
    double xpi = 180 / math.pi;
    double x = 0, y = 0, z = 0;
    int total = 0;
    LatLng? position;

    if (points != null) {
      for (MTDStop stop in points!) {
        LatLng? stopPosition = stop.position ?? stop.centerPoint;
        double? stopLatitude = stopPosition?.latitude;
        double? stopLongitude = stopPosition?.longitude;
        if ((stopLatitude != null) && (stopLongitude != null)) {
          double latitude = stopLatitude * pi;
          double longitude = stopLongitude * pi;
          double c1 = math.cos(latitude);
          x = x + c1 * math.cos(longitude);
          y = y + c1 * math.sin(longitude);
          z = z + math.sin(latitude);
          position = stopPosition;
          total++;
        }
      }
    }

    if (total == 0) {
      return null;
    }
    else if (total == 1) {
      return position;
    }
    else {
      x = x / total;
      y = y / total;
      z = z / total;

      double centralLongitude = math.atan2(y, x);
      double centralSquareRoot = math.sqrt(x * x + y * y);
      double centralLatitude = math.atan2(z, centralSquareRoot);

      return LatLng(latitude: centralLatitude * xpi, longitude: centralLongitude * xpi);
    }
  }

  bool get hasLocation => (latitude != null) && (longitude != null);

  // Explore implementation

  @override String? get exploreId => id;
  @override String? get exploreTitle => name;
  @override String? get exploreDescription => null;
  @override DateTime? get exploreDateTimeUtc => null;
  @override String? get exploreImageURL => null;
  @override ExploreLocation? get exploreLocation => ExploreLocation(
    building : name,
    latitude : latitude,
    longitude : longitude,
  );

  // Favorite implementation
  static const String favoriteKeyName = "mtdBusStopIds";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => id;
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
    List<MTDStop>? result = MTDStop.stopsInList(stops, name: name, location: location, locationThresholdDistance: locationThresholdDistance);
    if ((result != null) && result.isNotEmpty) {
      MTDStop? nearestStop = (1 < result.length) ? MTDStop.nearestStopInList(result, location: location) : null;
      return nearestStop ?? result.first;
    }
    return null;
  }

  List<MTDStop>? searchStop(String? search) {
    return MTDStop.searchInList(stops, search: search?.toLowerCase());
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
// MTDDepartureEdge

class MTDDepartureEdge {
  final String? stopId;
  
  MTDDepartureEdge({this.stopId});

  // JSON serialization

  static MTDDepartureEdge? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDDepartureEdge(
      stopId: JsonUtils.stringValue(json['stop_id']),
    ) : null;
  }

  toJson() => {
    'stop_id': stopId,
 };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDDepartureEdge) &&
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
  final MTDDepartureEdge? origin;
  final MTDDepartureEdge? destination;
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
      origin: MTDDepartureEdge.fromJson(JsonUtils.mapValue(json['origin'])),
      destination: MTDDepartureEdge.fromJson(JsonUtils.mapValue(json['destination'])),
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

///////////////////////////
// MTDShape

class MTDShape {
  final double? distance;
  final double? latitude;
  final double? longitude;
  final int? sequence;
  final String? stopId;

  MTDShape({this.distance, this.latitude, this.longitude, this.sequence, this.stopId});

  // JSON serialization

  static MTDShape? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDShape(
      distance: JsonUtils.doubleValue(json['shape_dist_traveled']),
      latitude: JsonUtils.doubleValue(json['shape_pt_lat']),
      longitude: JsonUtils.doubleValue(json['shape_pt_lon']),
      sequence: JsonUtils.intValue(json['shape_pt_sequence']),
      stopId: JsonUtils.stringValue(json['stop_id']),
    ) : null;
  }

  toJson() => {
    'shape_dist_traveled': distance,
    'shape_pt_lat': latitude,
    'shape_pt_lon': longitude,
    'shape_pt_sequence': sequence,
    'stop_id': stopId,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDShape) &&
    (distance == other.distance) &&
    (latitude == other.latitude) &&
    (longitude == other.longitude) &&
    (sequence == other.sequence) &&
    (stopId == other.stopId);

  @override
  int get hashCode =>
    (distance?.hashCode ?? 0) ^
    (latitude?.hashCode ?? 0) ^
    (longitude?.hashCode ?? 0) ^
    (sequence?.hashCode ?? 0) ^
    (stopId?.hashCode ?? 0);

  // JSON List Serialization

  static List<MTDShape>? listFromJson(List<dynamic>? jsonList) {
    List<MTDShape>? values;
    if (jsonList != null) {
      values = <MTDShape>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, MTDShape.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<MTDShape>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (MTDShape value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

///////////////////////////
// MTDVehicle

class MTDVehicle {
  final String? id;
  final MTDTrip? trip;
  final MTDLocation? location;
  final String? prevStopId;
  final String? nextStopId;
  final String? orgStopId;
  final String? destStopId;

  MTDVehicle({this.id, this.trip, this.location, this.prevStopId, this.nextStopId, this.orgStopId, this.destStopId});

  // JSON serialization

  static MTDVehicle? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDVehicle(
      id: JsonUtils.stringValue(json['vehicle_id']),
      trip: MTDTrip.fromJson(JsonUtils.mapValue(json['trip'])) ,
      location: MTDLocation.fromJson(JsonUtils.mapValue(json['location'])) ,
      prevStopId: JsonUtils.stringValue(json['previous_stop_id']),
      nextStopId: JsonUtils.stringValue(json['next_stop_id']),
      orgStopId: JsonUtils.stringValue(json['origin_stop_id']),
      destStopId: JsonUtils.stringValue(json['destination_stop_id']),
    ) : null;
  }

  toJson() => {
    'vehicle_id': id,
    'trip': trip?.toJson(),
    'location': location?.toJson(),
    'previous_stop_id': prevStopId,
    'next_stop_id': nextStopId,
    'origin_stop_id': orgStopId,
    'destination_stop_id': destStopId,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDVehicle) &&
    (id == other.id) &&
    (trip == other.trip) &&
    (location == other.location) &&
    (prevStopId == other.prevStopId) &&
    (nextStopId == other.nextStopId) &&
    (orgStopId == other.orgStopId) &&
    (destStopId == other.destStopId);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (trip?.hashCode ?? 0) ^
    (location?.hashCode ?? 0) ^
    (prevStopId?.hashCode ?? 0) ^
    (nextStopId?.hashCode ?? 0) ^
    (orgStopId?.hashCode ?? 0) ^
    (destStopId?.hashCode ?? 0);

  // JSON List Serialization

  static List<MTDVehicle>? listFromJson(List<dynamic>? jsonList) {
    List<MTDVehicle>? values;
    if (jsonList != null) {
      values = <MTDVehicle>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, MTDVehicle.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<MTDVehicle>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (MTDVehicle value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

///////////////////////////
// MTDLegEdge

class MTDLegEdge {
  final double? latitude;
  final double? longitude;
  final String? name;
  final String? timeString;
  final String? stopId;

  MTDLegEdge({this.latitude, this.longitude, this.name, this.timeString, this.stopId});

  // JSON serialization

  static MTDLegEdge? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDLegEdge(
      latitude: JsonUtils.doubleValue(json['lat']),
      longitude: JsonUtils.doubleValue(json['lon']),
      name: JsonUtils.stringValue(json['name']),
      timeString: JsonUtils.stringValue(json['time']),
      stopId: JsonUtils.stringValue(json['stop_id']),
    ) : null;
  }

  toJson() => {
    'lat': latitude,
    'lon': longitude,
    'name': name,
    'time': timeString,
    'stop_id': stopId,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDLegEdge) &&
    (latitude == other.latitude) &&
    (longitude == other.longitude) &&
    (name == other.name) &&
    (timeString == other.timeString) &&
    (stopId == other.stopId);

  @override
  int get hashCode =>
    (latitude?.hashCode ?? 0) ^
    (longitude?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (timeString?.hashCode ?? 0) ^
    (stopId?.hashCode ?? 0);
}

///////////////////////////
// MTDLegAtom

class MTDLegAtom {
  final MTDLegEdge? begin;
  final MTDLegEdge? end;

  MTDLegAtom({MTDLegEdge? begin, MTDLegEdge? end, MTDLegAtom? other}) :
    this.begin = (other != null) ? other.begin : begin,
    this.end = (other != null) ? other.end : end;

 // JSON serialization

  static MTDLegAtom? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDLegAtom(
      begin: MTDLegEdge.fromJson(JsonUtils.mapValue(json['begin'])),
      end: MTDLegEdge.fromJson(JsonUtils.mapValue(json['end'])),
    ) : null;
  }

  static MTDLegAtom? fromOther(MTDLegAtom? other) {
    return (other != null) ? MTDLegAtom(
      begin: other.begin,
      end: other.end,
    ) : null;
  }

  toJson() => {
    'begin': begin,
    'lon': end,
 };
}

///////////////////////////
// MTDWalkLegAtom

class MTDWalkLegAtom extends MTDLegAtom {
  final String? direction;
  final double? distance;

  MTDWalkLegAtom({this.direction, this.distance, MTDLegAtom? leg}) :
    super(other: leg);

  // JSON serialization

  static MTDWalkLegAtom? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDWalkLegAtom(
      direction: JsonUtils.stringValue(json['direction']),
      distance: JsonUtils.doubleValue(json['distance']),
      leg: MTDLegAtom.fromJson(json)
    ) : null;
  }

  toJson() => MapUtils.combine(super.toJson(), {
    'direction': direction,
    'distance': distance,
  });

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDWalkLegAtom) &&
    (direction == other.direction) &&
    (distance == other.distance) &&
    (super == other);

  @override
  int get hashCode =>
    (direction?.hashCode ?? 0) ^
    (distance?.hashCode ?? 0) ^
    (super.hashCode);
}

///////////////////////////
// MTDServiceLegAtom

class MTDServiceLegAtom extends MTDLegAtom {
  final MTDRoute? route;
  final MTDTrip? trip;

  MTDServiceLegAtom({this.route, this.trip, MTDLegAtom? leg}) :
    super(other: leg);

  // JSON serialization

  static MTDServiceLegAtom? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDServiceLegAtom(
      route: MTDRoute.fromJson(JsonUtils.mapValue(json['route'])),
      trip: MTDTrip.fromJson(JsonUtils.mapValue(json['trip'])),
      leg: MTDLegAtom.fromJson(json)
    ) : null;
  }

  toJson() => MapUtils.combine(super.toJson(), {
    'route': route?.toJson(),
    'trip': trip?.toJson(),
  });

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDServiceLegAtom) &&
    (route == other.route) &&
    (trip == other.trip) &&
    (super == other);

  @override
  int get hashCode =>
    (route?.hashCode ?? 0) ^
    (trip?.hashCode ?? 0) ^
    (super.hashCode);

  // JSON List Serialization

  static List<MTDServiceLegAtom>? listFromJson(List<dynamic>? jsonList) {
    List<MTDServiceLegAtom>? values;
    if (jsonList != null) {
      values = <MTDServiceLegAtom>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, MTDServiceLegAtom.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<MTDServiceLegAtom>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (MTDServiceLegAtom value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

///////////////////////////
// MTDLeg

abstract class MTDLeg {

  toJson();

  static MTDLeg? fromJson(Map<String, dynamic>? json) {
    String? type = (json != null) ? JsonUtils.stringValue(json['type']) : null;
    if (type == MTDWalkLeg.Type) {
      return MTDWalkLeg.fromJson(json);
    }
    else if (type == MTDServiceLeg.Type) {
      return MTDServiceLeg.fromJson(json);
    }
    else {
      return null;
    }
  }

  // JSON List Serialization

  static List<MTDLeg>? listFromJson(List<dynamic>? jsonList) {
    List<MTDLeg>? values;
    if (jsonList != null) {
      values = <MTDLeg>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, MTDLeg.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<MTDLeg>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (MTDLeg value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

///////////////////////////
// MTDWalkLeg

class MTDWalkLeg extends MTDLeg {
  static const String Type = 'Walk';

  final String? type;
  final MTDWalkLegAtom? walk;
  
  MTDWalkLeg({this.type, this.walk});

  // JSON serialization

  static MTDWalkLeg? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDWalkLeg(
      type: JsonUtils.stringValue(json['type']),
      walk: MTDWalkLegAtom.fromJson(JsonUtils.mapValue(json['walk'])),
    ) : null;
  }

  @override
  toJson() => {
    'type': type,
    'walk': walk?.toJson(),
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDWalkLeg) &&
    (type == other.type) &&
    (walk == other.walk);

  @override
  int get hashCode =>
    (type?.hashCode ?? 0) ^
    (walk?.hashCode ?? 0);
}

///////////////////////////
// MTDServiceLeg

class MTDServiceLeg extends MTDLeg {
  static const String Type = 'Service';

  final String? type;
  final List<MTDServiceLegAtom>? services;
  
  MTDServiceLeg({this.type, this.services});

  // JSON serialization

  static MTDServiceLeg? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDServiceLeg(
      type: JsonUtils.stringValue(json['type']),
      services: MTDServiceLegAtom.listFromJson(JsonUtils.listValue(json['services'])),
    ) : null;
  }

  @override
  toJson() => {
    'type': type,
    'services': MTDServiceLegAtom.listToJson(services),
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDServiceLeg) &&
    (type == other.type) &&
    (DeepCollectionEquality().equals(services, other.services));

  @override
  int get hashCode =>
    (type?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(services));
}

///////////////////////////
// MTDItinerary

class MTDItinerary {
  final String? startTimeString;
  final String? endTimeString;
  final int? travelTime;
  final List<MTDLeg>? legs;
  
  MTDItinerary({this.startTimeString, this.endTimeString, this.travelTime, this.legs});

  // JSON serialization

  static MTDItinerary? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? MTDItinerary(
      startTimeString: JsonUtils.stringValue(json['start_time']),
      endTimeString: JsonUtils.stringValue(json['end_time']),
      travelTime: JsonUtils.intValue(json['travel_time']),
      legs: MTDLeg.listFromJson(JsonUtils.listValue(json['legs'])),
    ) : null;
  }

  toJson() => {
    'start_time': startTimeString,
    'end_time': endTimeString,
    'travel_time': travelTime,
    'legs': MTDLeg.listToJson(legs),
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is MTDItinerary) &&
    (startTimeString == other.startTimeString) &&
    (endTimeString == other.endTimeString) &&
    (travelTime == other.travelTime) &&
    (DeepCollectionEquality().equals(legs, other.legs));

  @override
  int get hashCode =>
    (startTimeString?.hashCode ?? 0) ^
    (endTimeString?.hashCode ?? 0) ^
    (travelTime?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(legs));

  // JSON List Serialization

  static List<MTDItinerary>? listFromJson(List<dynamic>? jsonList) {
    List<MTDItinerary>? values;
    if (jsonList != null) {
      values = <MTDItinerary>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, MTDItinerary.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<MTDItinerary>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (MTDItinerary value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}
