
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

  bool matchAmenityIds(Iterable<Set<String>> amenityIdsList) {
    if (amenityIdsList.isNotEmpty) {
      for (Set<String> amenityIds in amenityIdsList) {
        if (features?.firstWhereOrNull((BuildingFeature feature) => amenityIds.contains(feature.key)) == null) {
          return false; // No feature matches this set of amenities
        }
      }
    }
    return true;
  }

  Map<String, String> get featureNames {
    Map<String, String> featuresMap = <String, String>{};
    if (features != null) {
      for (BuildingFeature feature in features!) {
        String? featureKey = feature.key;
        String? featureName = feature.value?.name;
        if ((featureKey != null) && (featureName != null)) {
          featuresMap[featureKey] = featureName;
        }
      }
    }
    return featuresMap;
  }
}

extension BuildingsListSearch on Iterable<Building>  {

  Map<String, Set<String>> get amenitiesNameToIds {
    Map<String, Set<String>> nameToIds = <String, Set<String>>{};
    for (Building building in this) {
      if (building.features != null) {
        for (BuildingFeature feature in building.features!) {
          String? featureKey = feature.key;
          String? featureName = feature.value?.name;
          if ((featureKey != null) && (featureName != null)) {
            Set<String> ids = nameToIds[featureName] ??= <String>{};
            ids.add(featureKey);
          }
        }
      }
    }
    return nameToIds;
  }
}

extension BuildingEntranceSearch on BuildingEntrance {
  bool matchSearchTextLowerCase(String searchLowerCase) => searchLowerCase.isNotEmpty &&
    (name?.toLowerCase().contains(searchLowerCase.toLowerCase()) == true);
}

extension BuildingFeatureSearch on BuildingFeature {
  bool matchSearchTextLowerCase(String searchLowerCase) => value?.matchSearchTextLowerCase(searchLowerCase) == true;
}

extension BuildingFeatureValueSearch on BuildingFeatureValue {
  bool matchSearchTextLowerCase(String searchLowerCase) =>
    searchLowerCase.isNotEmpty && (
      (name?.toLowerCase().contains(searchLowerCase) == true) ||
      (floors?.firstWhereOrNull((String floor) => floor.toLowerCase().contains(searchLowerCase)) != null)
    );
}


