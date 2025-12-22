
// Building

import 'package:collection/collection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Building with Explore implements Favorite {
  final String? id;
  final String? name;
  final String? number;

  final String? fullAddress;
  final String? address1;
  final String? address2;

  final String? city;
  final String? state;
  final String? zipCode;

  final String? imageURL;
  final String? mailCode;
  final String? shortName;

  final double? latitude;
  final double? longitude;

  List<BuildingFeature>? features;
  List<BuildingEntrance>? entrances;
  List<String>? floors;

  Building({
    this.id, this.name, this.number,
    this.fullAddress, this.address1, this.address2,
    this.city, this.state, this.zipCode,
    this.imageURL, this.mailCode, this.shortName,
    this.latitude, this.longitude,
    this.features, this.entrances, this.floors,
  });

  static Building? fromJson(Map<String, dynamic>? json) {
    String? rawName = JsonUtils.stringValue(MapUtils.get2(json, ['name', 'Name']));
    String? shortName = JsonUtils.stringValue(MapUtils.get2(json, ['shortName', 'ShortName']));
    String? name = (rawName != null && shortName != null) ? '$rawName ($shortName)' : rawName ?? shortName;
    return (json != null) ? Building(
      id: JsonUtils.stringValue(MapUtils.get2(json, ['id', 'ID'])),
      name: name,
      number: JsonUtils.stringValue(MapUtils.get2(json, ['number', 'Number'])),

      fullAddress: JsonUtils.stringValue(MapUtils.get2(json, ['fullAddress', 'FullAddress'])),
      address1: JsonUtils.stringValue(MapUtils.get2(json, ['address1', 'Address1'])),
      address2: JsonUtils.stringValue(MapUtils.get2(json, ['address2', 'Address2'])),

      city: JsonUtils.stringValue(MapUtils.get2(json, ['city', 'ZipCode'])),
      state: JsonUtils.stringValue(MapUtils.get2(json, ['state', 'State'])),
      zipCode: JsonUtils.stringValue(MapUtils.get2(json, ['zipCode', 'Address2'])),

      imageURL: JsonUtils.stringValue(MapUtils.get2(json, ['imageURL', 'ImageURL'])),
      mailCode: JsonUtils.stringValue(MapUtils.get2(json, ['mailCode', 'MailCode'])),
      shortName: JsonUtils.stringValue(MapUtils.get2(json, ['shortName', 'ShortName'])),

      latitude: JsonUtils.doubleValue(MapUtils.get2(json, ['latitude', 'Latitude'])),
      longitude: JsonUtils.doubleValue(MapUtils.get2(json, ['longitude', 'Longitude'])),

      features: BuildingFeature.listFromJson(JsonUtils.listValue(MapUtils.get2(json, ['Features']))),
      entrances: BuildingEntrance.listFromJson(JsonUtils.listValue(MapUtils.get2(json, ['entrances', 'Entrances']))),
      floors: JsonUtils.listStringsValue(MapUtils.get2(json, ['floors', 'Floors'])),
    ) : null;
  }

  toJson() => {
    'id': id,
    'name': name,
    'number': number,

    'fullAddress': fullAddress,
    'address1': address1,
    'address2': address2,

    'city': city,
    'state': state,
    'zipCode': zipCode,

    'imageURL': imageURL,
    'mailCode': mailCode,
    'shortName': shortName,

    'latitude': latitude,
    'longitude': longitude,

    'features': BuildingFeature.listToJson(features),
    'entrances': BuildingEntrance.listToJson(entrances),
    'floors': floors,
  };

  bool get hasValidLocation => (latitude != null) && (latitude != 0) && (longitude != null) && (longitude != 0);

  @override
  bool operator==(Object other) =>
    (other is Building) &&

    (id == other.id) &&
    (name == other.name) &&
    (number == other.number) &&

    (fullAddress == other.fullAddress) &&
    (address1 == other.address1) &&
    (address2 == other.address2) &&

    (city == other.city) &&
    (state == other.state) &&
    (mailCode == other.mailCode) &&
    (shortName == other.shortName) &&

    (imageURL == other.imageURL) &&
    (zipCode == other.zipCode) &&

    (latitude == other.latitude) &&
    (longitude == other.longitude) &&

    DeepCollectionEquality().equals(features, other.features) &&
    DeepCollectionEquality().equals(entrances, other.entrances) &&
    DeepCollectionEquality().equals(floors, other.floors);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (number?.hashCode ?? 0) ^

    (fullAddress?.hashCode ?? 0) ^
    (address1?.hashCode ?? 0) ^
    (address2?.hashCode ?? 0) ^

    (city?.hashCode ?? 0) ^
    (state?.hashCode ?? 0) ^
    (zipCode?.hashCode ?? 0) ^

    (imageURL?.hashCode ?? 0) ^
    (mailCode?.hashCode ?? 0) ^
    (shortName?.hashCode ?? 0) ^

    (latitude?.hashCode ?? 0) ^
    (longitude?.hashCode ?? 0) ^

    DeepCollectionEquality().hash(features) ^
    DeepCollectionEquality().hash(entrances) ^
    DeepCollectionEquality().hash(floors);

  // Accessories
  BuildingEntrance? nearstEntrance(Position? position, {bool requireAda = false}) =>
    BuildingEntrance.nearstEntrance(entrances, position, requireAda: requireAda);

  // Explore implementation

  @override String? get exploreId => id;
  @override String? get exploreTitle => name;
  @override String? get exploreDescription => null;
  @override DateTime? get exploreDateTimeUtc => null;
  @override String? get exploreImageURL => imageURL;
  @override ExploreLocation? get exploreLocation => ExploreLocation(
    building : name,
    fullAddress: fullAddress,
    address : address1,
    city : city,
    state : state,
    zip : zipCode,
    latitude : latitude,
    longitude : longitude,
  );

  // Favorite implementation
  static const String favoriteKeyName = "campusBuildings";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => id;

  // List<Building>

  static List<Building>? listFromJson(List<dynamic>? jsonList) {
    List<Building>? values;
    if (jsonList != null) {
      values = <Building>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, Building.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<Building>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (Building value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  static List<Building>? listFromJsonMap(Map<String, dynamic>? jsonMap) {
    List<Building>? values;
    if (jsonMap != null) {
      values = <Building>[];
      for (dynamic jsonEntry in jsonMap.values) {
        ListUtils.add(values, Building.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static Building? findInList(List<Building>? values, { String? id, String? number }) {
    if (values != null) {
      for (Building value in values) {
        if (((id != null) && (value.id == id)) || ((number != null) && (value.number == number))) {
          return value;
        }
      }
    }
    return null;
  }
}
// BuildingFeature

class BuildingFeatureValue {

  final String? name;
  List<String>? floors;

  BuildingFeatureValue({this.name, this.floors});

  static BuildingFeatureValue? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? BuildingFeatureValue(
      name: JsonUtils.stringValue(MapUtils.get2(json, ['name'])),
      floors: JsonUtils.listStringsValue(MapUtils.get2(json, ['floors'])),
    ) : null;
  }

  toJson () => {
    "name": name,
    "floors": floors,
  };

  @override
  bool operator==(Object other) =>
    (other is BuildingFeatureValue) &&

    (name == other.name) &&
    DeepCollectionEquality().equals(floors, other.floors);

  @override
  int get hashCode =>
    (name?.hashCode ?? 0) ^
    DeepCollectionEquality().hash(floors);
}

class BuildingFeature {

  final String? key;
  final BuildingFeatureValue? value;

  BuildingFeature({this.key, this.value});

  static BuildingFeature? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? BuildingFeature(
      key: JsonUtils.stringValue(MapUtils.get2(json, ['key'])),
      value: BuildingFeatureValue.fromJson(JsonUtils.mapValue(json['value'])),
    ) : null;
  }

  toJson () => {
    "key": key,
    "value": value?.toJson(),
  };

  @override
  bool operator==(Object other) =>
    (other is BuildingFeature) &&

    (key == other.key) &&
    (value == other.value);

  @override
  int get hashCode =>
    (key?.hashCode ?? 0) ^
    (value?.hashCode ?? 0);

  static List<BuildingFeature>? listFromJson(List<dynamic>? jsonList) {
    List<BuildingFeature>? values = [];
    if (jsonList != null) {
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, BuildingFeature.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<BuildingFeature>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (BuildingFeature value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

// BuildingEntrance

class BuildingEntrance {
  final String? id;
  final String? name;
  final bool? adaCompliant;
  final bool? available;
  final String? imageURL;
  final double? latitude;
  final double? longitude;

  BuildingEntrance({this.id, this.name, this.adaCompliant, this.available, this.imageURL, this.latitude, this.longitude});

  static BuildingEntrance? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? BuildingEntrance(
      id: JsonUtils.stringValue(MapUtils.get2(json, ['id', 'ID'])),
      name: JsonUtils.stringValue(MapUtils.get2(json, ['name', 'Name'])),
      adaCompliant: JsonUtils.boolValue(MapUtils.get2(json, ['adaCompliant', 'adacompliant', 'ADACompliant'])),
      available: JsonUtils.boolValue(MapUtils.get2(json, ['available', 'Available'])),
      imageURL: JsonUtils.stringValue(MapUtils.get2(json, ['imageURL', 'ImageURL'])),
      latitude: JsonUtils.doubleValue(MapUtils.get2(json, ['latitude', 'Latitude'])),
      longitude: JsonUtils.doubleValue(MapUtils.get2(json, ['longitude', 'Longitude'])),
    ) : null;
  }

  toJson() => {
    'id': id,
    'name': name,
    'adaCompliant': adaCompliant,
    'available': available,
    'imageURL': imageURL,
    'latitude': latitude,
    'longitude': longitude,
  };

  bool get hasValidLocation => (latitude != null) && (latitude != 0) && (longitude != null) && (longitude != 0);

  @override
  bool operator==(Object other) =>
    (other is BuildingEntrance) &&
    (id == other.id) &&
    (name == other.name) &&
    (adaCompliant == other.adaCompliant) &&
    (available == other.available) &&
    (imageURL == other.imageURL) &&
    (latitude == other.latitude) &&
    (longitude == other.longitude);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (adaCompliant?.hashCode ?? 0) ^
    (available?.hashCode ?? 0) ^
    (imageURL?.hashCode ?? 0) ^
    (latitude?.hashCode ?? 0) ^
    (longitude?.hashCode ?? 0);

  static List<BuildingEntrance>? listFromJson(List<dynamic>? jsonList) {
    List<BuildingEntrance>? values;
    if (jsonList != null) {
      values = <BuildingEntrance>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, BuildingEntrance.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<BuildingEntrance>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (BuildingEntrance value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  // Accessories
  static BuildingEntrance? nearstEntrance(List<BuildingEntrance>?entrances, Position? position, {bool requireAda = false}) {
    if ((entrances != null) && (position != null)) {
      double? minDistance, minAdaDistance;
      BuildingEntrance? minEntrance, minAdaEntrance;
      for (BuildingEntrance entrance in entrances) {
        if (entrance.hasValidLocation) {
          double distance = GeoMapUtils.getDistance(entrance.latitude!, entrance.longitude!, position.latitude, position.longitude);
          if ((minDistance == null) || (distance < minDistance)) {
            minDistance = distance;
            minEntrance = entrance;
          }
          if (requireAda && (entrance.adaCompliant == true) && ((minAdaDistance == null) || (distance < minAdaDistance))) {
            minAdaDistance = distance;
            minAdaEntrance = entrance;
          }
        }
      }
      return (requireAda && (minAdaEntrance != null)) ? minAdaEntrance : minEntrance;
    }
    return null;
  }
}

