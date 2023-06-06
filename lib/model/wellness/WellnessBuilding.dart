
import 'package:collection/collection.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Guide.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessBuilding with Explore {
  final Building building;
  final Map<String, dynamic> guideEntry;
  WellnessBuilding({required this.building, required this.guideEntry});

  @override
  bool operator==(dynamic other) =>
    (other is WellnessBuilding) &&
    (building == other.building) &&
    (DeepCollectionEquality().equals(guideEntry, other.guideEntry));

  @override
  int get hashCode =>
    building.hashCode ^
    DeepCollectionEquality().hash(guideEntry);

  // Accessories

  String? get guideId =>
    Guide().entryId(guideEntry);

  String? get _guideMapTitle {
    String? resulHtml = JsonUtils.stringValue(Guide().entryValue(guideEntry, 'map_title'));
    return (resulHtml != null) ? StringUtils.stripHtmlTags(resulHtml) : null;
  }

  String? get _guideMapDescription {
    String? resulHtml = JsonUtils.stringValue(Guide().entryValue(guideEntry, 'map_description'));
    return (resulHtml != null) ? StringUtils.stripHtmlTags(resulHtml) : null;
  }

  String? get id => Guide().entryId(guideEntry);
  String? get title => _guideMapTitle ?? building.name;
  String? get detail => _guideMapDescription ?? building.address1;

  // Explore implementation

  @override String? get exploreId => id;
  @override String? get exploreTitle => title;
  @override String? get exploreDescription => null;
  @override DateTime? get exploreDateTimeUtc => null;
  @override String? get exploreImageURL => null; //TMP: imageURL;
  @override ExploreLocation? get exploreLocation => ExploreLocation(
    building : _guideMapTitle ?? building.name,
    description: _guideMapDescription ?? building.fullAddress,
    address : building.address1,
    city : building.city,
    state : building.state,
    zip : building.zipCode,
    latitude : building.latitude,
    longitude : building.longitude,
  );
}