/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:collection';

import 'package:collection/collection.dart';

class GeoFenceRegion {
  final String? id;
  final Set<String>? types;
  final String? name;
  final bool? enabled;
  final dynamic data;
  
  GeoFenceRegion({this.id, this.types, this.name, this.enabled, this.data});

  static GeoFenceRegion? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GeoFenceRegion(
      id: json['id'],
      types: Set.from(json['types']),
      name: json['name'],
      enabled: json['enabled'],
      data: GeoFenceLocation.fromJson(json['location']) ?? GeoFenceBeacon.fromJson(json['beacon']),
    ) : null;
  }

  toJson({double? locationRadius}) {
    Map<String, dynamic> json = {
      'id': id,
      'types': List.from(types!),
      'name': name,
      'enabled': enabled,
    };
    if (data is GeoFenceLocation) {
      json['location'] = (data as GeoFenceLocation).toJson(radius: locationRadius);
    } 
    else if (data is GeoFenceBeacon) {
      json['beacon'] = (data as GeoFenceBeacon).toJson();
    }
    return json; 
  }

  GeoFenceRegionType? get regionType {
    if (data is GeoFenceLocation) {
      return GeoFenceRegionType.Location;
    }
    else if (data is GeoFenceBeacon) {
      return GeoFenceRegionType.Beacon;
    }
    else {
      return null;
    }
  }

  GeoFenceLocation? get location {
    return (data is GeoFenceLocation) ? (data as GeoFenceLocation?) : null;
  }

  GeoFenceBeacon? get beacon {
    return (data is GeoFenceBeacon) ? (data as GeoFenceBeacon?) : null;
  }

  static LinkedHashMap<String, GeoFenceRegion>? mapFromJsonList(List<dynamic>? values) {
    LinkedHashMap<String, GeoFenceRegion>? regions;
    if (values != null) {
      regions = LinkedHashMap();
      for (dynamic value in values) {
        GeoFenceRegion? region = GeoFenceRegion.fromJson(value);
        if (region?.id != null) {
          regions[region!.id!] = region;
        }
      }
    }
    return regions;
  }

  @override
  bool operator==(dynamic obj) {
    return (obj is GeoFenceRegion) &&
      (id == obj.id) &&
      DeepCollectionEquality().equals(types, obj.types) &&
      (name == obj.name) &&
      (enabled == obj.enabled) &&
      (
        ((data == null) && (obj.data == null)) ||
        ((data != null) && (obj.data != null) && (data == obj.data))
      );
  }

  @override
  int get hashCode {
    return
      (id?.hashCode ?? 0) ^
      (types?.hashCode ?? 0) ^
      (name?.hashCode ?? 0) ^
      (enabled?.hashCode ?? 0) ^
      (data?.hashCode ?? 0);
  }
}

enum GeoFenceRegionType {Location, Beacon}

class GeoFenceLocation {
  final double? latitude;
  final double? longitude;
  final double? radius;

  GeoFenceLocation({this.latitude, this.longitude, this.radius});

  static GeoFenceLocation? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GeoFenceLocation(
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      radius: json['radius']?.toDouble(),
    ) : null;
  }

  toJson({double? radius}) {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius ?? this.radius,
    };
  }

  @override
  bool operator==(dynamic obj) {
    bool value = (obj is GeoFenceLocation) &&
      (latitude == obj.latitude) &&
      (longitude == obj.longitude) &&
      (radius == obj.radius);
      return value;
  }

  @override
  int get hashCode {
    int value =
      (latitude?.hashCode ?? 0) ^
      (longitude?.hashCode ?? 0) ^
      (radius?.hashCode ?? 0);
    return value;
  }
}

class GeoFenceBeacon {
  final String? uuid;
  final int? major;
  final int? minor;

  GeoFenceBeacon({this.uuid, this.major, this.minor});

  static GeoFenceBeacon? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GeoFenceBeacon(
      uuid: json['uuid'],
      major: json['major']?.toInt(),
      minor: json['minor']?.toInt(),
    ) : null;
  }

  toJson() {
    return {
      'uuid': uuid,
      'major': major,
      'minor': minor,
    };
  }

  bool containsBeacon(GeoFenceBeacon? beacon) {
    return (beacon != null) &&
      ((uuid == null) || (uuid == beacon.uuid)) &&
      ((major == null) || (major == beacon.major)) &&
      ((minor == null) || (minor == beacon.minor));
  }

  @override
  bool operator==(dynamic obj) {
    bool value = (obj is GeoFenceBeacon) &&
      (uuid == obj.uuid) &&
      (major == obj.major) &&
      (minor == obj.minor);
      return value;
  }

  @override
  int get hashCode {
    int value =
      (uuid?.hashCode ?? 0) ^
      (major?.hashCode ?? 0) ^
      (minor?.hashCode ?? 0);
    return value;
  }

  static List<GeoFenceBeacon>? listFromJsonList(List? values) {
    List<GeoFenceBeacon>? beacons;
    if (values != null) {
      beacons = [];
      for (dynamic value in values) {
        GeoFenceBeacon? beacon = GeoFenceBeacon.fromJson(value.cast<String, dynamic>());
        if (beacon != null) {
          beacons.add(beacon);
        }
      }
    }
    return beacons;
  }
}
