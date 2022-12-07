
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

//////////////////////////////
/// ExplorePOI

class ExplorePOI with Explore {
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

  @override
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

  // Explore
  @override String?   get exploreId               => toString();
  @override String?   get exploreTitle            => StringUtils.isNotEmpty(name) ? name : Localization().getStringEx("panel.explore.item.location.name", "Location");
  @override String?   get exploreSubTitle         => null;
  @override String?   get exploreShortDescription => null;
  @override String?   get exploreLongDescription  => null;
  @override DateTime? get exploreStartDateUtc     => null;
  @override String?   get exploreImageURL         => null;
  @override String?   get explorePlaceId          => null;
  @override ExploreLocation? get exploreLocation  => location;
  @override String?   get exploreLocationDescription => location?.displayCoordinates;

  // ExploreJsonHandler
  static bool canJson(Map<String, dynamic>? json) {
    return (json != null) &&
      json.containsKey('placeId') &&
      json.containsKey('name') &&
      ExploreLocation.canJson(JsonUtils.mapValue(json['location']));
  }
}

class ExplorePOIJsonHandler implements ExploreJsonHandler {
  @override bool exploreCanJson(Map<String, dynamic>? json) => ExplorePOI.canJson(json);
  @override Explore? exploreFromJson(Map<String, dynamic>? json) => ExplorePOI.fromJson(json);
}
