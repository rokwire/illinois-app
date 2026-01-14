
import 'package:collection/collection.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Building.dart';
import 'package:illinois/service/Guide.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessBuilding with Explore, AnalyticsInfo {
  final Building building;
  final Map<String, dynamic> guideEntry;
  WellnessBuilding({required this.building, required this.guideEntry});

  @override
  bool operator==(Object other) =>
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
    String? resulHtml = JsonUtils.stringValue(Guide().entryValue(guideEntry, 'map_title')) ??
      JsonUtils.stringValue(Guide().entryValue(guideEntry, 'list_title')) ??
      JsonUtils.stringValue(Guide().entryValue(guideEntry, 'detail_title'));
    return (resulHtml != null) ? StringUtils.stripHtmlTags(resulHtml) : null;
  }

  String? get _guideMapDescription {
    String? resulHtml = JsonUtils.stringValue(Guide().entryValue(guideEntry, 'map_description')) ??
      JsonUtils.stringValue(Guide().entryValue(guideEntry, 'list_description')) ??
    JsonUtils.stringValue(Guide().entryValue(guideEntry, 'detail_description'));
    return (resulHtml != null) ? StringUtils.stripHtmlTags(resulHtml) : null;
  }

  //String? get _guideMapImageUrl =>
  //  JsonUtils.stringValue(Guide().entryValue(guideEntry, 'image'));

  String? get id => Guide().entryId(guideEntry);
  String? get title => _guideMapTitle ?? building.displayName;
  String? get detail => _guideMapDescription ?? building.address1;
  String? get imageUrl => /* _guideMapImageUrl ?? */ building.imageURL;

  // Explore implementation

  @override String? get exploreId => id;
  @override String? get exploreTitle => title;
  @override String? get exploreDescription => null;
  @override DateTime? get exploreDateTimeUtc => null;
  @override String? get exploreImageURL => imageUrl;
  @override ExploreLocation? get exploreLocation => building.exploreLocation;

  // AnaoyticsInfo implementation
  @override AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Wellness;

}