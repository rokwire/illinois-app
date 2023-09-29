
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

//////////////////////////////
/// ExplorePOI

class ExplorePOI with Explore implements Favorite {
  final String? placeId;
  final String? name;
  final ExploreLocation? location;

  static const String _stringDelimiter = '|';
  static const String _nullValue = '{null}';

  ExplorePOI({this.placeId, this.name, this.location});

  static ExplorePOI? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ExplorePOI(
      placeId: JsonUtils.stringValue(json['placeId']),
      name: JsonUtils.stringValue(json['name']),
      location: ExploreLocation.fromJson(JsonUtils.mapValue(json['location'])),
    ) : null;
  }

  toJson() {
    return {
      "placeId": placeId,
      "name": name,
      "location": location?.toJson()
    };
  }

  static ExplorePOI? fromString(String? value) {
    if (value != null) {
      List<String> items = value.split(_stringDelimiter);
      if (2 <= items.length) {
        ExploreLocation location = ExploreLocation(
          latitude: (items[0] != _nullValue) ? double.tryParse(items[0]) : null,
          longitude: (items[1] != _nullValue) ? double.tryParse(items[1]) : null,
        );

        String? placeId, name;
        if (4 <= items.length) {
          placeId = (items[2] != _nullValue) ? items[2] : null;
          name = (items[3] != _nullValue) ? items[3] : null;
        }

        return ExplorePOI(placeId: placeId, name: name, location: location);
      }
    }
    return null;
  }

  String toString() {
    num? latitude = location?.latitude;
    num? longitude = location?.longitude;
    String str = "${latitude ?? _nullValue}$_stringDelimiter${longitude ?? _nullValue}";
    if ((placeId != null) || (name != null)) {
      str = str + "$_stringDelimiter${placeId ?? _nullValue}$_stringDelimiter${name ?? _nullValue}";
    }
    return str;
  }

  @override
  bool operator ==(other) => (other is ExplorePOI) &&
    (other.placeId == placeId) &&
    (other.name == name) &&
    (other.location == location);

  @override
  int get hashCode =>
    (placeId?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (location?.hashCode ?? 0);

  static List<ExplorePOI>? listFromJson(List<dynamic>? jsonList) {
    List<ExplorePOI>? values;
    if (jsonList != null) {
      values = <ExplorePOI>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, ExplorePOI.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<ExplorePOI>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (ExplorePOI value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  static List<ExplorePOI>? listFromString(Iterable<String>? stringList) {
    List<ExplorePOI>? values;
    if (stringList != null) {
      values = <ExplorePOI>[];
      for (String stringEntry in stringList) {
        ListUtils.add(values, ExplorePOI.fromString(stringEntry));
      }
    }
    return values;
  }

  static List<String>? listToString(List<ExplorePOI>? values) {
    List<String>? jsonList;
    if (values != null) {
      jsonList = <String>[];
      for (ExplorePOI value in values) {
        ListUtils.add(jsonList, value.toString());
      }
    }
    return jsonList;
  }

  // Explore
  @override String?   get exploreId               => toString();

  @override String?   get exploreTitle {
    if (StringUtils.isNotEmpty(name)) {
      return name;
    }
    else if (StringUtils.isNotEmpty(location?.name)) {
      return location?.name;
    }
    else {
      return Localization().getStringEx("panel.explore.item.location.name", "Location");
    }
  }

  @override String?   get exploreDescription {
    if (StringUtils.isNotEmpty(location?.description)) {
      return location?.description;
    }
    else if (StringUtils.isNotEmpty(location?.fullAddress)) {
      return location?.fullAddress;
    }
    else {
      return Localization().getStringEx("panel.explore.item.location.name", "Location");
    }
  }

  @override DateTime? get exploreDateTimeUtc      => null;
  @override String?   get exploreImageURL         => null;
  @override ExploreLocation? get exploreLocation  => location;

  // Favorite
  static const String favoriteKeyName = "poiLocations";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => toString();
}
