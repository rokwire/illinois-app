
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/model/Building.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/map2/Map2HomeExts.dart';
import 'package:illinois/utils/Utils.dart';

extension BuildingFilter on Building {

  bool matchSearchTextLowerCase(String searchLowerCase) =>
    (searchLowerCase.isNotEmpty && (
      (name?.toLowerCase().contains(searchLowerCase) == true) ||
      (shortName?.toLowerCase().contains(searchLowerCase) == true) ||
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

  bool matchAmenityCategoryToKeys(Map<String, Set<String>> categoryToKeysMap) {
    if (categoryToKeysMap.isNotEmpty) {
      for (String category in categoryToKeysMap.keys) {
        Set<String>? categoryKeys = categoryToKeysMap[category];
        if ((categoryKeys != null) && categoryKeys.isNotEmpty) {
          if (features?.firstWhereOrNull((BuildingFeature feature) => categoryKeys.contains(feature.key)) == null) {
            return false;
          }
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

extension BuildingEntranceDistanceSearch on Building {
  BuildingEntrance? nearstEntrance(Position? position, {bool requireAda = false}) =>
    _nearstEntrance(entrances, position,
        buildingPosition: hasValidLocation ? LatLng(latitude ?? 0, longitude ?? 0) : null,
        requireAda: requireAda
    );

  static BuildingEntrance? _nearstEntrance(List<BuildingEntrance>? entrances, Position? position, { LatLng? buildingPosition, bool requireAda = false }) {
    if ((entrances != null) && (position != null)) {

      double? medianDistance;
      Map<String, double> entranceDistancesFromBuilding = <String, double>{};
      int? excludeThresoldNumber = Config().excludeBuildingEntrancesThresoldNumber;
      double? thresoldDistanceFactor = Config().excludeBuildingEntrancesThresoldDistanceFactor;
      if ((buildingPosition != null) && (excludeThresoldNumber != null) && (thresoldDistanceFactor != null)) {
        for (BuildingEntrance entrance in entrances) {
          if ((entrance.id != null) && entrance.hasValidLocation) {
            entranceDistancesFromBuilding[entrance.id ?? ''] = GeoMapUtils.getDistance(entrance.latitude ?? 0, entrance.longitude ?? 0, buildingPosition.latitude, buildingPosition.longitude);
          }
        }

        List<double> allDistances = entranceDistancesFromBuilding.values.sorted((d1, d2) => d1.compareTo(d2));
        int allDistancesCount = allDistances.length;
        if (excludeThresoldNumber <= allDistancesCount) {
          int middleIndex = allDistancesCount ~/ 2;
          medianDistance = ((allDistancesCount % 2) > 0) ?
            (allDistances[middleIndex]) : // odd - use the middle index
            ((allDistances[middleIndex] + allDistances[middleIndex - 1]) / 2); // even - eval the average value in the middle pair
        }
      }

      double? minDistance, minAdaDistance;
      BuildingEntrance? minEntrance, minAdaEntrance;
      for (BuildingEntrance entrance in entrances) {
        double? entranceDistance = entranceDistancesFromBuilding[entrance.id];
        if (entrance.hasValidLocation && ((medianDistance == null) || (medianDistance == 0.0) || (entranceDistance == null) || (thresoldDistanceFactor == null) || (thresoldDistanceFactor > (entranceDistance / medianDistance)))) {
          double distance = GeoMapUtils.getDistance(entrance.latitude ?? 0, entrance.longitude ?? 0, position.latitude, position.longitude);
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

extension BuildingsEntranceDistanceExclude on Iterable<Building>  {
  void logExcluded() {
    for (Building building in this) {
      Set<BuildingEntrance>? excluded = building.excludedEntrances;
      if ((excluded != null) && excluded.isNotEmpty) {
        for (BuildingEntrance entrance in excluded) {
          double distance = GeoMapUtils.getDistance(entrance.latitude ?? 0, entrance.longitude ?? 0, building.latitude ?? 0, building.longitude ?? 0);
          debugPrint("${building.displayName}\t[${building.latitude?.toStringAsFixed(6)},${building.longitude?.toStringAsFixed(6)}]\tEntrance: ${entrance.id}\t[${entrance.latitude?.toStringAsFixed(6)},${entrance.longitude?.toStringAsFixed(6)}]\t${distance.toInt()}");
        }
      }
    }
  }
}

extension BuildingEntranceDistanceExclude on Building {

  Set<BuildingEntrance>? get excludedEntrances =>
      _excludedEntrances(entrances, hasValidLocation ? LatLng(latitude ?? 0, longitude ?? 0) : null);

  static Set<BuildingEntrance>? _excludedEntrances(List<BuildingEntrance>? entrances, LatLng? buildingPosition) {
    int? excludeThresoldNumber = Config().excludeBuildingEntrancesThresoldNumber;
    double? thresoldDistanceFactor = Config().excludeBuildingEntrancesThresoldDistanceFactor;
    if ((entrances != null) && (buildingPosition != null) && (excludeThresoldNumber != null) && (thresoldDistanceFactor != null)) {

      Map<String, double> entranceDistancesFromBuilding = <String, double>{};
      for (BuildingEntrance entrance in entrances) {
        if ((entrance.id != null) && entrance.hasValidLocation) {
          entranceDistancesFromBuilding[entrance.id ?? ''] = GeoMapUtils.getDistance(entrance.latitude ?? 0, entrance.longitude ?? 0, buildingPosition.latitude, buildingPosition.longitude);
        }
      }

      double? medianDistance;
      List<double> allDistances = entranceDistancesFromBuilding.values.sorted((d1, d2) => d1.compareTo(d2));
      int allDistancesCount = allDistances.length;
      if (excludeThresoldNumber <= allDistancesCount) {
        int middleIndex = allDistancesCount ~/ 2;
        medianDistance = ((allDistancesCount % 2) > 0) ?
          (allDistances[middleIndex]) : // odd - use the middle index
          ((allDistances[middleIndex] + allDistances[middleIndex - 1]) / 2); // even - eval the average value in the middle pair
      }

      Set<BuildingEntrance>? excluded;
      for (BuildingEntrance entrance in entrances) {
        double? entranceDistance = entranceDistancesFromBuilding[entrance.id];
        if (entrance.hasValidLocation && (entranceDistance != null) && (medianDistance != null) && (medianDistance != 0)) {
          double entranceFactor = entranceDistance / medianDistance;
          if (entranceFactor > thresoldDistanceFactor) {
            if (excluded == null) {
              excluded = <BuildingEntrance>{ entrance };
            } else {
              excluded.add(entrance);
            }
          }
        }
      }
      return excluded;
    } else {
      return null;
    }
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

  Map<String, BuildingFeature> get amenitiesMap {
    Map<String, BuildingFeature> amenitiesMap = <String, BuildingFeature>{};
    for (Building building in this) {
      List<BuildingFeature>? features = building.features;
      if (features != null) {
        for (BuildingFeature feature in features) {
          String? featureKey = feature.key;
          if ((featureKey != null) && !amenitiesMap.containsKey(featureKey)) {
            amenitiesMap[featureKey] = feature;
          }
        }
      }
    }
    return amenitiesMap;
  }
}

extension BuildingEntranceSearch on BuildingEntrance {
  bool matchSearchTextLowerCase(String searchLowerCase) => searchLowerCase.isNotEmpty &&
    (name?.toLowerCase().contains(searchLowerCase.toLowerCase()) == true);
}

extension BuildingFeatureSearch on BuildingFeature {
  bool matchSearchTextLowerCase(String searchLowerCase) => value?.matchSearchTextLowerCase(searchLowerCase) == true;

  String? get filterCategory {
    String? category = key;
    while (category != null) {
      String strippedCategory = category;
      if (category.endsWith(_adaSuffix)) {
        strippedCategory = category.substring(0, category.length - _adaSuffix.length);
      }
      else if (category.endsWith(_allSuffix)) {
        strippedCategory = category.substring(0, category.length - _allSuffix.length);
      }
      if (strippedCategory.length < category.length) {
        category = strippedCategory;
      }
      else {
        return category;
      }
    }
    return null;
  }

  static const String _adaSuffix = '-ADA';
  static const String _allSuffix = '-ALL';
}

extension BuildingFeatureValueSearch on BuildingFeatureValue {
  bool matchSearchTextLowerCase(String searchLowerCase) =>
    searchLowerCase.isNotEmpty && (
      (name?.toLowerCase().contains(searchLowerCase) == true) ||
      (floors?.firstWhereOrNull((String floor) => floor.toLowerCase().contains(searchLowerCase)) != null)
    );
}


