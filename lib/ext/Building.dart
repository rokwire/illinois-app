
import 'package:collection/collection.dart';
import 'package:illinois/model/Building.dart';

extension BuildingFilter on Building {

  bool matchSearchTextLowerCase(String searchLowerCase) =>
    (searchLowerCase.isNotEmpty && (
      (name?.toLowerCase().contains(searchLowerCase) == true) ||
      (fullAddress?.toLowerCase().contains(searchLowerCase) == true) ||
      (address1?.toLowerCase().contains(searchLowerCase) == true) ||
      (address2?.toLowerCase().contains(searchLowerCase) == true) ||
      (city?.toLowerCase().contains(searchLowerCase) == true) ||
      (state?.toLowerCase().contains(searchLowerCase) == true) ||
      (zipCode?.toLowerCase().contains(searchLowerCase) == true) ||
      (mailCode?.toLowerCase().contains(searchLowerCase) == true) ||
      (features?.firstWhereOrNull((BuildingFeature feature) => feature.matchSearchTextLowerCase(searchLowerCase)) != null) ||
      (entrances?.firstWhereOrNull((BuildingEntrance entrance) => entrance.matchSearchTextLowerCase(searchLowerCase)) != null) ||
      (floors?.firstWhereOrNull((String floor) => floor.toLowerCase().contains(searchLowerCase)) != null)
    ));

  bool matchAmenityIds(Set<String> amenityIds) =>
    (amenityIds.isNotEmpty && (
      (features?.firstWhereOrNull((BuildingFeature feature) => feature.matchAmenityIds(amenityIds)) != null)
    ));

  Map<String, String?> get featureNames {
    Map<String, String?> featuresMap = <String, String?>{};
    if (features != null) {
      for (BuildingFeature feature in features!) {
        if (feature.key != null) {
          featuresMap[feature.key!] = feature.value?.name;
        }
      }
    }
    return featuresMap;
  }
}

extension BuildingsSearch on Iterable<Building>  {

  Map<String, String?> get featureNames {
    Map<String, String?> featuresMap = <String, String?>{};
    for (Building building in this) {
      featuresMap.addAll(building.featureNames);
    }
    return featuresMap;
  }
}

extension BuildingEntranceSearch on BuildingEntrance {
  bool matchSearchTextLowerCase(String searchLowerCase) => searchLowerCase.isNotEmpty &&
    (name?.toLowerCase().contains(searchLowerCase.toLowerCase()) == true);
}

extension BuildingFeatureSearch on BuildingFeature {
  bool matchSearchTextLowerCase(String searchLowerCase) => value?.matchSearchTextLowerCase(searchLowerCase) == true;
  bool matchAmenityIds(Set<String> amenityIds) => amenityIds.contains(key);
}

extension BuildingFeatureValueSearch on BuildingFeatureValue {
  bool matchSearchTextLowerCase(String searchLowerCase) =>
    searchLowerCase.isNotEmpty && (
      (name?.toLowerCase().contains(searchLowerCase) == true) ||
      (floors?.firstWhereOrNull((String floor) => floor.toLowerCase().contains(searchLowerCase)) != null)
    );
}


