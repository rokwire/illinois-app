
import 'package:collection/collection.dart';
import 'package:illinois/model/StudentCourse.dart';

extension BuildingSearch on Building {

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

  bool matchAmenitiesLowerCase(Iterable<String> amenitiesLowerCase) =>
    (amenitiesLowerCase.isNotEmpty && (
      (features?.firstWhereOrNull((BuildingFeature feature) => feature.matchAmenitiesLowerCase(amenitiesLowerCase)) != null)
    ));
}

extension BuildingEntranceSearch on BuildingEntrance {
  bool matchSearchTextLowerCase(String searchLowerCase) => searchLowerCase.isNotEmpty &&
    (name?.toLowerCase().contains(searchLowerCase.toLowerCase()) == true);
}

extension BuildingFeatureSearch on BuildingFeature {
  bool matchSearchTextLowerCase(String searchLowerCase) => value?.matchSearchTextLowerCase(searchLowerCase) == true;
  bool matchAmenitiesLowerCase(Iterable<String> amenitiesLowerCase) => value?.matchAmenitiesLowerCase(amenitiesLowerCase) == true;
}

extension BuildingFeatureValueSearch on BuildingFeatureValue {
  bool matchSearchTextLowerCase(String searchLowerCase) =>
    searchLowerCase.isNotEmpty && (
      (name?.toLowerCase().contains(searchLowerCase) == true) ||
      (floors?.firstWhereOrNull((String floor) => floor.toLowerCase().contains(searchLowerCase)) != null)
    );

  bool matchAmenitiesLowerCase(Iterable<String> amenitiesLowerCase) =>
    (name != null) && amenitiesLowerCase.contains(name?.toLowerCase());
}


