

import 'dart:collection';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/map2/Map2HomeFilters.dart';
import 'package:illinois/ui/map2/Map2HomePanel.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension Map2ContentTypeImpl on Map2ContentType {

  static Map2ContentType? fromJson(String? value) {
    switch (value) {
      case 'buildings':       return Map2ContentType.CampusBuildings;
      case 'student_courses': return Map2ContentType.StudentCourses;
      case 'dining':          return Map2ContentType.DiningLocations;
      case 'events2':         return Map2ContentType.Events2;
      case 'laundry':         return Map2ContentType.LaundryRooms;
      case 'mtd_stops':       return Map2ContentType.BusStops;
      case 'mental_health':   return Map2ContentType.Therapists;
      case 'storied_sites':   return Map2ContentType.StoriedSites;
      case 'my_locations':    return Map2ContentType.MyLocations;
      default:                return null;
    }
  }

  String toJson() {
    switch(this) {
      case Map2ContentType.CampusBuildings:      return 'buildings';
      case Map2ContentType.StudentCourses:       return 'student_courses';
      case Map2ContentType.DiningLocations:      return 'dining';
      case Map2ContentType.Events2:              return 'events2';
      case Map2ContentType.LaundryRooms:         return 'laundry';
      case Map2ContentType.BusStops:             return 'mtd_stops';
      case Map2ContentType.Therapists:           return 'mental_health';
      case Map2ContentType.StoriedSites:         return 'storied_sites';
      case Map2ContentType.MyLocations:          return 'my_locations';
    }
  }

  static Map2ContentType? initialType({ dynamic initialSelectParam, Iterable<Map2ContentType>? availableTypes }) =>
    selectParamType(initialSelectParam)?._ensure(availableTypes: availableTypes);

  static Map2ContentType? selectParamType(dynamic param) {
    if (param is Map2ContentType) {
      return param;
    } else if (param is Map2FilterEvents2Param) {
      return Map2ContentType.Events2;
    } else if (param is Map2FilterDiningsLocationsParam) {
      return Map2ContentType.DiningLocations;
    } else if (param is Map2FilterBusStopsParam) {
      return Map2ContentType.BusStops;
    } else if (param is Map) {
      return Map2FilterDeepLinkParam.contentTypeFromUriParams(JsonUtils.mapCastValue<String, String?>(param));
    } else {
      return null;
    }
  }

  static Set<Map2ContentType> get availableTypes {
    List<dynamic>? codes = FlexUI()['map.types'];
    Set<Map2ContentType> availableTypes = <Map2ContentType>{};
    if (codes != null) {
      for (dynamic code in codes) {
        Map2ContentType? contentType = fromJson(code);
        if (contentType != null) {
          availableTypes.add(contentType);
        }
      }
    }
    return availableTypes;
  }

  Map2ContentType? _ensure({ Iterable<Map2ContentType>? availableTypes }) =>
      (availableTypes?.contains(this) != false) ? this : null;

  static const Set<Map2ContentType> _manualFiltersTypes = <Map2ContentType>{
    Map2ContentType.CampusBuildings, Map2ContentType.DiningLocations,
    Map2ContentType.LaundryRooms, Map2ContentType.BusStops,
    Map2ContentType.StoriedSites, Map2ContentType.MyLocations,
  };
  bool get supportsManualFilters => _manualFiltersTypes.contains(this);

  bool supportsSortType(Map2SortType sortType) =>
    (sortType != Map2SortType.dateTime) || (this == Map2ContentType.Events2);

  String get displayTitle => displayTitleEx();

  String displayTitleEx({String? language}) {
    switch(this) {
      case Map2ContentType.CampusBuildings:      return Localization().getStringEx('panel.explore.button.buildings.title', 'Campus Buildings', language: language);
      case Map2ContentType.StudentCourses:       return Localization().getStringEx('panel.explore.button.student_course.title', 'My Courses', language: language);
      case Map2ContentType.DiningLocations:      return Localization().getStringEx('panel.explore.button.dining.title', 'Residence Hall Dining', language: language);
      case Map2ContentType.Events2:              return Localization().getStringEx('panel.explore.button.events2.title', 'Events', language: language);
      case Map2ContentType.LaundryRooms:         return Localization().getStringEx('panel.explore.button.laundry_room.title', 'Laundry Rooms', language: language);
      case Map2ContentType.BusStops:             return Localization().getStringEx('panel.explore.button.mtd_stops.title', 'MTD Stops', language: language);
      case Map2ContentType.Therapists:           return Localization().getStringEx('panel.explore.button.mental_health.title', 'Find a Therapist', language: language);
      case Map2ContentType.StoriedSites:         return Localization().getStringEx('panel.explore.button.stored_sites.title', 'Storied Sites', language: language);
      case Map2ContentType.MyLocations:          return Localization().getStringEx('panel.explore.button.my_locations.title', 'My Locations', language: language);
    }
  }

  String get displayEmptyContentMessage {
    switch (this) {
      case Map2ContentType.CampusBuildings:      return Localization().getStringEx('panel.explore.state.online.empty.buildings', 'No building locations available.');
      case Map2ContentType.StudentCourses:       return Localization().getStringEx('panel.explore.state.online.empty.student_course', 'You do not appear to be registered for any in-person courses.');
      case Map2ContentType.DiningLocations:      return Localization().getStringEx('panel.explore.state.online.empty.dining', 'No dining locations are currently open.');
      case Map2ContentType.Events2:              return Localization().getStringEx('panel.explore.state.online.empty.events2', 'No events are available.');
      case Map2ContentType.LaundryRooms:         return Localization().getStringEx('panel.explore.state.online.empty.laundry', 'No laundry locations are currently open.');
      case Map2ContentType.BusStops:             return Localization().getStringEx('panel.explore.state.online.empty.mtd_stops', 'No MTD stop locations available.');
      case Map2ContentType.Therapists:           return Localization().getStringEx('panel.explore.state.online.empty.mental_health', 'No therapist locations are available.');
      case Map2ContentType.StoriedSites:         return Localization().getStringEx('panel.explore.state.online.empty.stored_sites', 'No storied sites are available.');
      case Map2ContentType.MyLocations:          return Localization().getStringEx('panel.explore.state.online.empty.my_locations', 'No saved locations available.');
    }
  }

  String get displayFailedContentMessage {
    switch (this) {
      case Map2ContentType.CampusBuildings:      return Localization().getStringEx('panel.explore.state.failed.buildings', 'Failed to load building locations.');
      case Map2ContentType.StudentCourses:       return Localization().getStringEx('panel.explore.state.failed.student_course', 'You do not appear to be registered for any in-person courses.');
      case Map2ContentType.DiningLocations:      return Localization().getStringEx('panel.explore.state.failed.dining', 'Failed to load dining locations.');
      case Map2ContentType.Events2:              return Localization().getStringEx('panel.explore.state.failed.events2', 'Failed to load all events.');
      case Map2ContentType.LaundryRooms:         return Localization().getStringEx('panel.explore.state.failed.laundry', 'Failed to load laundry locations.');
      case Map2ContentType.BusStops:             return Localization().getStringEx('panel.explore.state.failed.mtd_stops', 'Failed to load MTD stop locations.');
      case Map2ContentType.Therapists:           return Localization().getStringEx('panel.explore.state.failed.mental_health', 'Failed to load therapist locations.');
      case Map2ContentType.StoriedSites:         return Localization().getStringEx('panel.explore.state.failed.stored_sites', 'Failed to load storied sites.');
      case Map2ContentType.MyLocations:          return Localization().getStringEx('panel.explore.state.failed.my_locations', 'Failed to load saved locations.');
    }
  }

  AnalyticsFeature get analyticsFeature {
    switch (this) {
      case Map2ContentType.CampusBuildings:      return AnalyticsFeature.MapBuildings;
      case Map2ContentType.StudentCourses:       return AnalyticsFeature.MapStudentCourse;
      case Map2ContentType.DiningLocations:      return AnalyticsFeature.MapDining;
      case Map2ContentType.Events2:              return AnalyticsFeature.MapEvents;
      case Map2ContentType.LaundryRooms:         return AnalyticsFeature.MapLaundry;
      case Map2ContentType.BusStops:             return AnalyticsFeature.MapMTDStops;
      case Map2ContentType.Therapists:           return AnalyticsFeature.MapMentalHealth;
      case Map2ContentType.StoriedSites:         return AnalyticsFeature.StoriedSites;
      case Map2ContentType.MyLocations:          return AnalyticsFeature.MapMyLocations;
    }
  }
}

extension Map2SortTypeImpl on Map2SortType {

  static Map2SortType? fromJson(dynamic value) {
    if (value == 'date_time') {
      return Map2SortType.dateTime;
    }
    else if (value == 'alphabetical') {
      return Map2SortType.alphabetical;
    }
    else if (value == 'proximity') {
      return Map2SortType.proximity;
    }
    else {
      return null;
    }
  }

  String toJson() {
    switch (this) {
      case Map2SortType.dateTime: return 'date_time';
      case Map2SortType.alphabetical: return 'alphabetical';
      case Map2SortType.proximity: return 'proximity';
    }
  }

  static Map2SortType fromEvent2SortType(Event2SortType value) {
    switch (value) {
      case Event2SortType.dateTime: return Map2SortType.dateTime;
      case Event2SortType.alphabetical: return Map2SortType.alphabetical;
      case Event2SortType.proximity: return Map2SortType.proximity;
    }
  }

  Event2SortType toEvent2SortType() {
    switch(this) {
      case Map2SortType.dateTime: return Event2SortType.dateTime;
      case Map2SortType.alphabetical: return Event2SortType.alphabetical;
      case Map2SortType.proximity: return Event2SortType.proximity;
    }
  }

  String get displayTitle {
    switch (this) {
      case Map2SortType.dateTime: return Localization().getStringEx('model.map2.sort_type.date_time', 'Date & Time');
      case Map2SortType.alphabetical: return Localization().getStringEx('model.map2.sort_type.alphabetical', 'Alphabetical');
      case Map2SortType.proximity: return Localization().getStringEx('model.map2.sort_type.proximity', 'Proximity');
    }
  }

  bool isDropdownListEntry(Map2SortOrder? sortOrder) {
    switch(this) {
      case Map2SortType.alphabetical: return (sortOrder != null);
      case Map2SortType.proximity: return (sortOrder == Map2SortOrder.ascending);
      case Map2SortType.dateTime: return (sortOrder == null);
    }
  }

  String? dropdownSortOrderIndicator(Map2SortOrder? sortOrder) => (this == Map2SortType.alphabetical) ?
    sortOrder?.displayAlphabeticalAbbr : null;

  bool? isDropdownListEntrySelected(Map2SortOrder? sortOrder) {
    switch(this) {
      case Map2SortType.alphabetical: return null;
      case Map2SortType.proximity: return (sortOrder == Map2SortOrder.ascending);
      case Map2SortType.dateTime: return (sortOrder == null);
    }
  }
}

extension Map2SortOrderImpl on Map2SortOrder {

  static Map2SortOrder? fromJson(dynamic value) {
    if (value == 'ascending') {
      return Map2SortOrder.ascending;
    }
    else if (value == 'descending') {
      return Map2SortOrder.descending;
    }
    else {
      return null;
    }
  }

  String toJson() {
    switch (this) {
      case Map2SortOrder.ascending: return 'ascending';
      case Map2SortOrder.descending: return 'descending';
    }
  }

  static Map2SortOrder fromEvent2SortOrder(Event2SortOrder value) {
    switch (value) {
      case Event2SortOrder.ascending: return Map2SortOrder.ascending;
      case Event2SortOrder.descending: return Map2SortOrder.descending;
    }
  }

  Event2SortOrder toEvent2SortOrder() {
    switch(this) {
      case Map2SortOrder.ascending: return Event2SortOrder.ascending;
      case Map2SortOrder.descending: return Event2SortOrder.descending;
    }
  }

  String? displayIndicator(Map2SortType sortType) {
    switch(sortType) {
      case Map2SortType.alphabetical: return displayAlphabeticalAbbr;
      case Map2SortType.dateTime: return (this == Map2SortOrder.descending) ? displayAbbr : null;
      case Map2SortType.proximity: return null;
    }
  }

  String get displayTitle {
    switch (this) {
      case Map2SortOrder.ascending: return Localization().getStringEx('model.map2.sort_order.ascending', 'Ascending');
      case Map2SortOrder.descending: return Localization().getStringEx('model.map2.sort_order.descending', 'Descending');
    }
  }

  String get displayAbbr {
    switch (this) {
      case Map2SortOrder.ascending: return Localization().getStringEx('model.map2.sort_order.ascending.abbr', 'Asc');
      case Map2SortOrder.descending: return Localization().getStringEx('model.map2.sort_order.descending.abbr', 'Desc');
    }
  }

  String get displayAlphabeticalAbbr {
    switch (this) {
      case Map2SortOrder.ascending: return Localization().getStringEx('model.map2.sort_order.ascending.alphabetical.abbr', 'A-Z');
      case Map2SortOrder.descending: return Localization().getStringEx('model.map2.sort_order.descending.alphabetical.abbr', 'Z-A');
    }
  }

  String get displayMark {
    switch (this) {
      case Map2SortOrder.ascending: return Localization().getStringEx('model.map2.sort_order.descending.mark', '↑');
      case Map2SortOrder.descending: return Localization().getStringEx('model.map2.sort_order.ascending.mark', '↓');
    }
  }
}

extension ExplorePOIImpl on ExplorePOI {

  static ExplorePOI fromMapPOI(PointOfInterest poi) =>
    ExplorePOI(
      placeId: poi.placeId,
      name: poi.name.replaceAll('\n', ' '),
      location: ExploreLocation(
        latitude: poi.position.latitude,
        longitude: poi.position.longitude
      )
    );

  static ExplorePOI fromMapCoordinate(LatLng coordinate) =>
    ExplorePOI(
      placeId: null,
      name: Localization().getStringEx('panel.explore.item.location.name','Location'),
      location: ExploreLocation(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude
      )
    );
}

extension Map2BuildingDisplayAmenities on Map<String, String> {

  Map<String, Set<String>> get amenitiesNameToIds {
    Map<String, Set<String>> result = <String, Set<String>>{};
    forEach((String amenityId, String amenityName) {
      Set<String> amenityIds = result[amenityName] ??= <String>{};
      amenityIds.add(amenityId);
    });
    return result;
  }

}


extension Map2BuildingSelectedAmenities on LinkedHashSet<String> {

  LinkedHashMap<String, String> selectedAmenitiesIdToName(Map<String, String> amenitiesIdToName) {
    LinkedHashMap<String, String> selectedAmenities = LinkedHashMap<String, String>();
    for (String amenityId in this) {
      String? amenuityName = amenitiesIdToName[amenityId];
      if (amenuityName != null) {
        selectedAmenities[amenityId] = amenuityName;
      }
    }
    return selectedAmenities;
  }

}

extension Map2BuildingFilterAmenitiesFromJson on Map<String, dynamic> {

  LinkedHashMap<String, Set<String>> toAmenityNameToIds() {
    LinkedHashMap<String, Set<String>> nameToIds = LinkedHashMap<String, Set<String>>();
    for (String amenityName in keys) {
      Set<String>? amenityIds = SetUtils.from(JsonUtils.listStringsValue(this[amenityName]));
      if (amenityIds != null) {
        nameToIds[amenityName] = amenityIds;
      }
    }
    return nameToIds;
  }

}

extension Map2BuildingFilterAmenitiesToJson on LinkedHashMap<String, Set<String>> {
  Map<String, dynamic> toJson() => map((String key, Set<String> value) => MapEntry(key, value.toList()));
}

class Map2FilterEvents2Param {
  final String searchText;
  Map2FilterEvents2Param([this.searchText = '']);
}

class Map2FilterDiningsLocationsParam {
  final PaymentType? paymentType;
  final String searchText;
  final bool openNow;
  final bool starred;
  final Map2SortType sortType;
  final Map2SortOrder sortOrder;

  Map2FilterDiningsLocationsParam({
    this.paymentType,
    this.searchText = '',
    this.openNow = false,
    this.starred = false,
    this.sortType = Map2SortType.alphabetical,
    this.sortOrder = Map2SortOrder.ascending,
  });
}

class Map2FilterBusStopsParam {
  final String searchText;
  final bool starred;
  Map2FilterBusStopsParam({this.searchText = '', this.starred = false});
}

class Map2FilterDeepLinkParam {
  Map2ContentType contentType;
  Map2Filter? filter;

  Map2FilterDeepLinkParam({required this.contentType, this.filter});

  static Map2FilterDeepLinkParam? fromUriParams(Map<String, String?>? uriParams) {
    Map2ContentType? contentType = contentTypeFromUriParams(uriParams);
    return (contentType != null) ? Map2FilterDeepLinkParam(
      contentType: contentType,
      filter: Map2Filter.fromJson(JsonUtils.decodeMap(uriParams?['filter']), contentType: contentType),
    ) : null;
  }

  static Map2ContentType? contentTypeFromUriParams(Map<String, String?>? uriParams) =>
    Map2ContentTypeImpl.fromJson(JsonUtils.stringValue(uriParams?['contentType']));

  Map<String, String?> toUriParams() => <String, String?> {
    'contentType': contentType.toJson(),
    'filter': JsonUtils.encode(filter?.toJson()),
  };
}

extension Map2AppConfig on Config {

  CameraPosition? get defaultCameraPosition {
    LatLng? target = defaultCameraTarget;
    return (target != null) ? CameraPosition(
      target: target,
      bearing: defaultCameraBearing ?? 0,
      tilt: defaultCameraTilt ?? 0,
      zoom: defaultCameraZoom ?? 0,
    ) : null;
  }

  LatLng? get defaultCameraTarget =>
    _LatLngAppConfig.fromConfigJson(JsonUtils.mapValue(_initialCameraPosition?['target']));

  double? get defaultCameraBearing => JsonUtils.doubleValue(_initialCameraPosition?['bearing']);
  double? get defaultCameraTilt => JsonUtils.doubleValue(_initialCameraPosition?['tilt']);
  double? get defaultCameraZoom => JsonUtils.doubleValue(_initialCameraPosition?['zoom']);

  double? get markersUpdateZoomDelta => JsonUtils.doubleValue(map2Settings?['markers_update_zoom_delta']);
  Map<String, dynamic>? get _initialCameraPosition => JsonUtils.mapValue(map2Settings?['initial_camera_position']);
}

extension _LatLngAppConfig on LatLng {
  static LatLng? fromConfigJson(Map<String, dynamic>? json) {
    double? latitude = JsonUtils.doubleValue(json?['latitude']);
    double? longitude = JsonUtils.doubleValue(json?['longitude']);
    return ((latitude != null) && (longitude != null)) ? LatLng(latitude, longitude) : null;
  }
}