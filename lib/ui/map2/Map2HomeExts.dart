

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/map2/Map2HomePanel.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/localization.dart';

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

  static const Map2ContentType _defaultType = Map2ContentType.CampusBuildings;

  static Map2ContentType? initialType({ dynamic initialSelectParam, Iterable<Map2ContentType>? availableTypes }) => (
    (selectParamType(initialSelectParam)?._ensure(availableTypes: availableTypes)) ??
    (Storage().storedMap2ContentType?._ensure(availableTypes: availableTypes)) ??
    (_defaultType._ensure(availableTypes: availableTypes)) ??
    ((availableTypes?.isNotEmpty == true) ? availableTypes?.first : null)
  );

  static Map2ContentType? selectParamType(dynamic param) {
    if (param is Map2ContentType) {
      return param;
    } else if (param is Map2FilterEvents2Param) {
      return Map2ContentType.Events2;
    } else if (param is Map2FilterBusStopsParam) {
      return Map2ContentType.BusStops;
    } else {
      return null;
    }
  }

  static Set<Map2ContentType> get availableTypes {
    List<dynamic>? codes = FlexUI()['map2.types'];
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
      case Map2ContentType.StudentCourses:       return Localization().getStringEx('panel.explore.state.online.empty.student_course', 'No student courses registered.');
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
      case Map2ContentType.StudentCourses:       return Localization().getStringEx('panel.explore.state.failed.student_course', 'Failed to load student courses.');
      case Map2ContentType.DiningLocations:      return Localization().getStringEx('panel.explore.state.failed.dining', 'Failed to load dining locations.');
      case Map2ContentType.Events2:              return Localization().getStringEx('panel.explore.state.failed.events2', 'Failed to load all events.');
      case Map2ContentType.LaundryRooms:         return Localization().getStringEx('panel.explore.state.failed.laundry', 'Failed to load laundry locations.');
      case Map2ContentType.BusStops:             return Localization().getStringEx('panel.explore.state.failed.mtd_stops', 'Failed to load MTD stop locations.');
      case Map2ContentType.Therapists:           return Localization().getStringEx('panel.explore.state.failed.mental_health', 'Failed to load therapist locations.');
      case Map2ContentType.StoriedSites:         return Localization().getStringEx('panel.explore.state.failed.stored_sites', 'Failed to load storied sites.');
      case Map2ContentType.MyLocations:          return Localization().getStringEx('panel.explore.state.failed.my_locations', 'Failed to load saved locations.');
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

  String get displayTitle {
    switch (this) {
      case Map2SortOrder.ascending: return Localization().getStringEx('model.map2.sort_order.ascending', 'Ascending');
      case Map2SortOrder.descending: return Localization().getStringEx('model.map2.sort_order.descending', 'Descending');
    }
  }

  String get displayMnemo {
    switch (this) {
      case Map2SortOrder.ascending: return Localization().getStringEx('model.map2.sort_order.ascending.mnemo', 'Asc');
      case Map2SortOrder.descending: return Localization().getStringEx('model.map2.sort_order.descending.mnemo', 'Desc');
    }
  }

  String get displayMarker {
    switch (this) {
      case Map2SortOrder.ascending: return Localization().getStringEx('model.map2.sort_order.descending.mark', '↑');
      case Map2SortOrder.descending: return Localization().getStringEx('model.map2.sort_order.ascending.mark', '↓');
    }
  }
}

extension Map2StorageContentType on Storage {
  static const String _nullContentTypeJson = 'null';

  Map2ContentType? get storedMap2ContentType => Map2ContentTypeImpl.fromJson(Storage().selectedMap2ContentType);
  set storedMap2ContentType(Map2ContentType? value) => Storage().selectedMap2ContentType = value?.toJson() ?? _nullContentTypeJson;

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

class Map2FilterEvents2Param {
  final String searchText;
  Map2FilterEvents2Param([this.searchText = '']);
}

class Map2FilterBusStopsParam {
  final String searchText;
  final bool starred;
  Map2FilterBusStopsParam({this.searchText = '', this.starred = false});
}
