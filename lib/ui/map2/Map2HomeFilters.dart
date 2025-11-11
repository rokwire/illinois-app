
import 'dart:collection';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Building.dart';
import 'package:illinois/ext/Dining.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/LaundryRoom.dart';
import 'package:illinois/ext/MTD.dart';
import 'package:illinois/ext/Places.dart';
import 'package:illinois/model/Building.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/map2/Map2HomeExts.dart';
import 'package:illinois/ui/map2/Map2HomePanel.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/model/places.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Map2Filter {

  String searchText = '';
  bool starred = false;
  Map2SortType sortType;
  Map2SortOrder sortOrder;

  Map2Filter._({
    this.searchText = '',
    this.starred = false,
    this.sortType = defaultSortType,
    this.sortOrder = defaultSortOrder,
  });

  factory Map2Filter.empty() => Map2Filter._();

  static Map2Filter? defaultFromContentType(Map2ContentType? contentType) {
    switch (contentType) {
      case Map2ContentType.CampusBuildings:      return Map2CampusBuildingsFilter.defaultFilter();
      case Map2ContentType.StudentCourses:       return Map2StudentCoursesFilter.defaultFilter();
      case Map2ContentType.DiningLocations:      return Map2DiningLocationsFilter.defaultFilter();
      case Map2ContentType.Events2:              return Map2Events2Filter.defaultFilter();
      case Map2ContentType.LaundryRooms:         return Map2LaundryRoomsFilter.defaultFilter();
      case Map2ContentType.BusStops:             return Map2BusStopsFilter.defaultFilter();
      case Map2ContentType.Therapists:           return null;
      case Map2ContentType.StoriedSites:         return Map2StoriedSitesFilter.defaultFilter();
      case Map2ContentType.MyLocations:          return Map2MyLocationsFilter.defaultFilter();
      default: return null;
    }
  }

  static Map2Filter? emptyFromContentType(Map2ContentType? contentType) {
    switch (contentType) {
      case Map2ContentType.CampusBuildings:      return Map2CampusBuildingsFilter.emptyFilter();
      case Map2ContentType.StudentCourses:       return Map2StudentCoursesFilter.emptyFilter();
      case Map2ContentType.DiningLocations:      return Map2DiningLocationsFilter.emptyFilter();
      case Map2ContentType.Events2:              return Map2Events2Filter.emptyFilter();
      case Map2ContentType.LaundryRooms:         return Map2LaundryRoomsFilter.emptyFilter();
      case Map2ContentType.BusStops:             return Map2BusStopsFilter.emptyFilter();
      case Map2ContentType.Therapists:           return null;
      case Map2ContentType.StoriedSites:         return Map2StoriedSitesFilter.emptyFilter();
      case Map2ContentType.MyLocations:          return Map2MyLocationsFilter.emptyFilter();
      default: return null;
    }
  }


  static Map2Filter? fromJson(Map<String, dynamic>? json, { Map2ContentType? contentType }) {
    if ((json != null) & (contentType != null)) {
      switch (contentType) {
        case Map2ContentType.CampusBuildings:      return Map2CampusBuildingsFilter._fromJson(json!);
        case Map2ContentType.StudentCourses:       return Map2StudentCoursesFilter._fromJson(json!);
        case Map2ContentType.DiningLocations:      return Map2DiningLocationsFilter._fromJson(json!);
        case Map2ContentType.Events2:              return Map2Events2Filter._fromJson(json!);
        case Map2ContentType.LaundryRooms:         return Map2LaundryRoomsFilter._fromJson(json!);
        case Map2ContentType.BusStops:             return Map2BusStopsFilter._fromJson(json!);
        case Map2ContentType.Therapists:           return null;
        case Map2ContentType.StoriedSites:         return Map2StoriedSitesFilter._fromJson(json!);
        case Map2ContentType.MyLocations:          return Map2MyLocationsFilter._fromJson(json!);
        default: return null;
      }
    }
    else {
      return null;
    }
  }

  Map2Filter._fromJson(Map<String, dynamic> json) :
    searchText = JsonUtils.stringValue(json['search']) ?? '',
    starred = JsonUtils.boolValue(json['starred']) ?? false,
    sortType = Map2SortTypeImpl.fromJson(json['sortType']) ?? defaultSortType,
    sortOrder = Map2SortOrderImpl.fromJson(json['sortOrder']) ?? defaultSortOrder;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'search': searchText,
    'starred': starred,
    'sortType': sortType.toJson(),
    'sortOrder': sortOrder.toJson(),
  };

  // Filter

  bool get hasFilter => searchText.isNotEmpty || (starred == true);

  List<Explore> filter(List<Explore> explores) =>
    (explores.isNotEmpty && _needsFilter) ? _filter(explores) : explores;

  bool get _needsFilter => false;

  List<Explore> _filter(List<Explore> explores) => explores;

  // Sort

  static const Map2SortType defaultSortType = Map2SortType.alphabetical;
  static const Map2SortOrder defaultSortOrder = Map2SortOrder.ascending;

  Map2SortOrder expectedSortOrder(Map2SortType sortType) => Map2Filter.defaultSortOrder;

  List<Explore> sort(Iterable<Explore> explores, { Position? position }) {
    List<Explore> sortedExplores = List<Explore>.from(explores);
    if (explores.isNotEmpty && _needsSort) {
      _sort(sortedExplores, position: position);
    }
    return sortedExplores;
  }

  bool get _needsSort => true;

  void _sort(List<Explore> explores, { Position? position }) {
    switch (sortType) {
      case Map2SortType.dateTime: _sortByDateTime(explores); break;
      case Map2SortType.alphabetical: _sortAlphabeticaly(explores); break;
      case Map2SortType.proximity: _sortByProximity(explores, position: position); break;
    }
  }
  void _sortAlphabeticaly(List<Explore> explores) =>
    explores.sort((Explore explore1, Explore explore2) =>
      SortUtils.compare(explore1.exploreTitle, explore2.exploreTitle, descending: (sortOrder == Map2SortOrder.descending))
    );

  void _sortByProximity(List<Explore> explores, { Position? position }) {
    explores.sort((Explore explore1, Explore explore2) {
      LatLng? location1 = explore1.exploreLocation?.exploreLocationMapCoordinate;
      double? distance1 = ((location1 != null) && (position != null)) ? Geolocator.distanceBetween(location1.latitude, location1.longitude, position.latitude, position.longitude) : 0.0;

      LatLng? location2 = explore2.exploreLocation?.exploreLocationMapCoordinate;
      double? distance2 = ((location2 != null) && (position != null)) ? Geolocator.distanceBetween(location2.latitude, location2.longitude, position.latitude, position.longitude) : 0.0;

      return (sortOrder == Map2SortOrder.descending) ? distance2.compareTo(distance1) : distance1.compareTo(distance2); // SortUtils.compare(distance1, distance2);
    });
  }

  void _sortByDateTime(List<Explore> explores) =>
    explores.sort((Explore explore1, Explore explore2) =>
      SortUtils.compare(explore1.exploreDateTimeUtc, explore2.exploreDateTimeUtc, descending: (sortOrder == Map2SortOrder.descending))
    );

  // Description

  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { bool canSort = false }) =>
    LinkedHashMap<String, List<String>>();

  String descriptionText({ bool canSort = false }) {
    String result = "";
    LinkedHashMap<String, List<String>> data = description(null, canSort: canSort);
    for (String category in data.keys) {
      List<String>? categoryList = data[category];
      if ((categoryList != null) && categoryList.isEmpty) {
        if (result.isNotEmpty) {
          result += "; ";
        }
        result += "$category: ${categoryList.join(',')}";
      }
    }
    return result;
  }

  String get _sortDescriptionValue {
    String sortTypeTitle = sortType.displayTitle;
    String? sortOrderIndicator = sortOrder.displayIndicator(sortType);
    return (sortOrderIndicator != null) ? '$sortTypeTitle $sortOrderIndicator' : sortTypeTitle;
  }
}

class Map2CampusBuildingsFilter extends Map2Filter {
  LinkedHashMap<String, Set<String>> amenitiesNameToIds;

  Map2CampusBuildingsFilter._({
    required this.amenitiesNameToIds,

    String searchText = '',
    bool starred = false,
    Map2SortType sortType = Map2SortType.alphabetical,
    Map2SortOrder sortOrder = Map2SortOrder.ascending,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2CampusBuildingsFilter.defaultFilter() => Map2CampusBuildingsFilter._(
    amenitiesNameToIds: LinkedHashMap<String, Set<String>>(),
  );

  factory Map2CampusBuildingsFilter.emptyFilter() => Map2CampusBuildingsFilter._(
    amenitiesNameToIds: LinkedHashMap<String, Set<String>>(),
  );

  Map2CampusBuildingsFilter._fromJson(Map<String, dynamic> json) :
    amenitiesNameToIds = JsonUtils.mapValue(json['amenities'])?.toAmenityNameToIds() ?? LinkedHashMap<String, Set<String>>(),
    super._fromJson(json);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'amenities': amenitiesNameToIds.toJson(),
    ...super.toJson(),
  };

  @override
  bool get hasFilter => amenitiesNameToIds.isNotEmpty || super.hasFilter;

  @override
  bool get _needsFilter => hasFilter;

  @override
  List<Explore> _filter(List<Explore> explores) {
    String? searchLowerCase = searchText.trim().toLowerCase();
    List<Explore> filtered = <Explore>[];
    for (Explore explore in explores) {
      if ((explore is Building) &&
          ((searchLowerCase.isNotEmpty != true) || (explore.matchSearchTextLowerCase(searchLowerCase))) &&
          ((starred != true) || (Auth2().prefs?.isFavorite(explore as Favorite) == true)) &&
          ((amenitiesNameToIds.isNotEmpty != true) || (explore.matchAmenityIds(amenitiesNameToIds.values)))
        ) {
        filtered.add(explore);
      }
    }
    return filtered;
  }

  @override
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { bool canSort = false }) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    if (searchText.isNotEmpty) {
      String searchKey = Localization().getStringEx('panel.map2.filter.search.text', 'Search');
      descriptionMap[searchKey] = <String>[searchText];
    }
    if (amenitiesNameToIds.isNotEmpty) {
      String amenitiesKey = Localization().getStringEx('panel.map2.filter.amenities.text', 'Amenities');
      descriptionMap[amenitiesKey] = List<String>.from(amenitiesNameToIds.keys);
    }
    if (starred) {
      String starredKey = Localization().getStringEx('panel.map2.filter.starred.text', 'Starred');
      descriptionMap[starredKey] = <String>[];
    }
    if (canSort && descriptionMap.isNotEmpty) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      descriptionMap[sortKey] = <String>[_sortDescriptionValue];
    }
    if ((filteredExplores != null) && descriptionMap.isNotEmpty)  {
      String buildingsKey = Localization().getStringEx('panel.map2.filter.buildings.text', 'Buildings');
      String buildingsValue = filteredExplores.length.toString();
      descriptionMap[buildingsKey] = <String>[buildingsValue];
    }
    return descriptionMap;
  }
}

class Map2StudentCoursesFilter extends Map2Filter {

  String? get termName => StudentCourses().displayTerm?.name;

  String? get termId => StudentCourses().displayTermId;
  set termId(String? value) => StudentCourses().selectedTermId = value;

  Map2StudentCoursesFilter._({
    String searchText = '',
    bool starred = false,
    Map2SortType sortType = Map2SortType.alphabetical,
    Map2SortOrder sortOrder = Map2SortOrder.ascending,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2StudentCoursesFilter.defaultFilter() => Map2StudentCoursesFilter._();
  factory Map2StudentCoursesFilter.emptyFilter() => Map2StudentCoursesFilter._();

  Map2StudentCoursesFilter._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    String? termId = JsonUtils.stringValue(json['termId']);
    if (termId != null) {
      this.termId = termId;
    }
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'termId': termId,
    ...super.toJson(),
  };

  @override
  bool get hasFilter => (termId?.isNotEmpty == true) || super.hasFilter;

  /* No description bar for Student Courses
  @override
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { bool canSort = false }) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    String? selectedTerm = termName;
    if ((selectedTerm != null) && selectedTerm.isNotEmpty) {
      String termKey = Localization().getStringEx('panel.map2.filter.term.text', 'Term');
      descriptionMap[termKey] = <String>[selectedTerm];
    }
    if (canSort) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      descriptionMap[sortKey] = <String>[_sortDescriptionValue];
    }
    if ((filteredExplores != null) && descriptionMap.isNotEmpty)  {
      String buildingsKey = Localization().getStringEx('panel.map2.filter.student_courses.text', 'Courses');
      String buildingsValue = filteredExplores.length.toString();
      descriptionMap[buildingsKey] = <String>[buildingsValue];
    }
    return descriptionMap;
  }*/
}

class Map2DiningLocationsFilter extends Map2Filter {
  bool onlyOpened;
  PaymentType? paymentType;

  Map2DiningLocationsFilter._({
    // ignore: unused_element_parameter
    this.onlyOpened = false,
    // ignore: unused_element_parameter
    this.paymentType,

    String searchText = '',
    bool starred = false,
    Map2SortType sortType = Map2SortType.alphabetical,
    Map2SortOrder sortOrder = Map2SortOrder.ascending,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2DiningLocationsFilter.defaultFilter() => Map2DiningLocationsFilter._();
  factory Map2DiningLocationsFilter.emptyFilter() => Map2DiningLocationsFilter._();

  Map2DiningLocationsFilter._fromJson(Map<String, dynamic> json) :
    onlyOpened = JsonUtils.boolValue(json['onlyOpened']) ?? false,
    paymentType = PaymentTypeImpl.fromJsonString(JsonUtils.stringValue(json['paymentType'])),
    super._fromJson(json);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'onlyOpened': onlyOpened,
    'paymentType': paymentType?.toJsonString(),
    ...super.toJson(),
  };

  @override
  bool get hasFilter => (onlyOpened == true) || (paymentType != null) || super.hasFilter;

  @override
  bool get _needsFilter => hasFilter;

  @override
  List<Explore> _filter(List<Explore> explores) {
    String? searchLowerCase = searchText.trim().toLowerCase();
    List<Explore> filtered = <Explore>[];
    for (Explore explore in explores) {
      if ((explore is Dining) &&
          ((searchLowerCase.isNotEmpty != true) || (explore.matchSearchTextLowerCase(searchLowerCase))) &&
          ((starred != true) || (Auth2().prefs?.isFavorite(explore as Favorite) == true)) &&
          ((onlyOpened != true) || (explore.isOpen == true)) &&
          ((paymentType == null) || (explore.paymentTypes?.contains(paymentType) == true))
        ) {
        filtered.add(explore);
      }
    }
    return filtered;
  }

  @override
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { bool canSort = false }) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    if (searchText.isNotEmpty) {
      String searchKey = Localization().getStringEx('panel.map2.filter.search.text', 'Search');
      descriptionMap[searchKey] = <String>[searchText];
    }
    if (paymentType != null) {
      String? paymentTypeValue = paymentType?.displayTitle;
      if ((paymentTypeValue != null) && paymentTypeValue.isNotEmpty) {
        String paymentTypeKey = Localization().getStringEx('panel.map2.filter.payment_type.text', 'Payment Type');
        descriptionMap[paymentTypeKey] = <String>[paymentTypeValue];
      }
    }
    if (starred) {
      String starredKey = Localization().getStringEx('panel.map2.filter.starred.text', 'Starred');
      descriptionMap[starredKey] = <String>[];
    }
    if (onlyOpened) {
      String onlyOpenedKey = Localization().getStringEx('panel.map2.filter.open_now.text', 'Open Now');
      descriptionMap[onlyOpenedKey] = <String>[];
    }
    if (canSort && descriptionMap.isNotEmpty) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      descriptionMap[sortKey] = <String>[_sortDescriptionValue];
    }
    if ((filteredExplores != null) && descriptionMap.isNotEmpty)  {
      String buildingsKey = Localization().getStringEx('panel.map2.filter.dinings.text', 'Locations');
      String buildingsValue = filteredExplores.length.toString();
      descriptionMap[buildingsKey] = <String>[buildingsValue];
    }
    return descriptionMap;
  }
}

class Map2Events2Filter extends Map2Filter {
  Event2FilterParam event2Filter;

  Map2Events2Filter._({
    required this.event2Filter,

    String searchText = '',
    bool starred = false,
    required Map2SortType sortType,
    required Map2SortOrder sortOrder,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2Events2Filter.defaultFilter({ String searchText = '' }) {
    Event2FilterParam eventFilter = Event2FilterParam.fromStorage();
    Event2SortType sortType = Event2SortTypeAppImpl.fromStorage() ??  Event2SortTypeAppImpl.defaultSortType;
    Event2SortOrder sortOrder = Event2SortOrderImpl.defaultFrom(sortType: sortType, timeFilter: eventFilter.timeFilter);
    return Map2Events2Filter._(
      event2Filter: eventFilter,
      searchText: searchText,
      sortType: Map2SortTypeImpl.fromEvent2SortType(sortType),
      sortOrder: Map2SortOrderImpl.fromEvent2SortOrder(sortOrder),
    );
  }

  factory Map2Events2Filter.emptyFilter() {
    Event2FilterParam eventFilter = Event2FilterParam.defaultFilterParam;
    Event2SortType sortType = Event2SortType.dateTime;
    Event2SortOrder sortOrder = Event2SortOrderImpl.defaultFrom(sortType: sortType, timeFilter: eventFilter.timeFilter);
    return Map2Events2Filter._(
      event2Filter: eventFilter,
      sortType: Map2SortTypeImpl.fromEvent2SortType(sortType),
      sortOrder: Map2SortOrderImpl.fromEvent2SortOrder(sortOrder),
    );
  }

  Map2Events2Filter._fromJson(Map<String, dynamic> json) :
    event2Filter = Event2FilterParam.fromJson(JsonUtils.mapValue(json['event2Filter'])) ?? Event2FilterParam.defaultFilterParam,
    super._fromJson(json);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'event2Filter': event2Filter.toJson(),
    ...super.toJson(),
  };

  @override
  bool get hasFilter => event2Filter.isNotEmpty || super.hasFilter;

  void applyEvent2Filter(Event2FilterParam event2FilterParam) {
    event2Filter = event2FilterParam;
    if (sortType == Map2SortType.dateTime) {
      sortOrder = expectedSortOrder(sortType);
    }
  }

  @override
  Map2SortOrder expectedSortOrder(Map2SortType sortType) =>
    Map2SortOrderImpl.fromEvent2SortOrder(Event2SortOrderImpl.defaultFrom(sortType: sortType.toEvent2SortType(), timeFilter: event2Filter.timeFilter));

  @override
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { bool canSort = false }) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    if (searchText.isNotEmpty) {
      String searchKey = Localization().getStringEx('panel.map2.filter.search.text', 'Search');
      descriptionMap[searchKey] = <String>[searchText];
    }

    List<String> filters = event2Filter.rawDescription;
    if (filters.isNotEmpty) {
      String filterKey = Localization().getStringEx('panel.map2.filter.filter.text', 'Filter');
      descriptionMap[filterKey] = filters;
    }

    if (canSort && descriptionMap.isNotEmpty) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      descriptionMap[sortKey] = <String>[_sortDescriptionValue];
    }
    if ((filteredExplores != null) && descriptionMap.isNotEmpty)  {
      String eventsKey = Localization().getStringEx('panel.map2.filter.events.text', 'Events');
      String eventsValue = filteredExplores.length.toString();
      descriptionMap[eventsKey] = <String>[eventsValue];
    }
    return descriptionMap;
  }

}

class Map2LaundryRoomsFilter extends Map2Filter {

  Map2LaundryRoomsFilter._({
    String searchText = '',
    bool starred = false,
    Map2SortType sortType = Map2SortType.alphabetical,
    Map2SortOrder sortOrder = Map2SortOrder.ascending,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2LaundryRoomsFilter.defaultFilter() => Map2LaundryRoomsFilter._();
  factory Map2LaundryRoomsFilter.emptyFilter() => Map2LaundryRoomsFilter._();

  Map2LaundryRoomsFilter._fromJson(Map<String, dynamic> json) : super._fromJson(json);

  @override
  bool get _needsFilter => hasFilter;

  @override
  List<Explore> _filter(List<Explore> explores) {
    String? searchLowerCase = searchText.trim().toLowerCase();
    List<Explore> filtered = <Explore>[];
    for (Explore explore in explores) {
      if ((explore is LaundryRoom) &&
          ((searchLowerCase.isNotEmpty != true) || (explore.matchSearchTextLowerCase(searchLowerCase))) &&
          ((starred != true) || (Auth2().prefs?.isFavorite(explore as Favorite) == true))
        ) {
        filtered.add(explore);
      }
    }
    return filtered;
  }

  @override
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { bool canSort = false }) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    if (searchText.isNotEmpty) {
      String searchKey = Localization().getStringEx('panel.map2.filter.search.text', 'Search');
      descriptionMap[searchKey] = <String>[searchText];
    }
    if (starred) {
      String starredKey = Localization().getStringEx('panel.map2.filter.starred.text', 'Starred');
      descriptionMap[starredKey] = <String>[];
    }
    if (canSort && descriptionMap.isNotEmpty) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      descriptionMap[sortKey] = <String>[_sortDescriptionValue];
    }
    if ((filteredExplores != null) && descriptionMap.isNotEmpty)  {
      String buildingsKey = Localization().getStringEx('panel.map2.filter.laundry_rooms.text', 'Laundries');
      String buildingsValue = filteredExplores.length.toString();
      descriptionMap[buildingsKey] = <String>[buildingsValue];
    }
    return descriptionMap;
  }
}

class Map2BusStopsFilter extends Map2Filter {

  Map2BusStopsFilter._({
    String searchText = '',
    bool starred = false,
    Map2SortType sortType = Map2SortType.alphabetical,
    Map2SortOrder sortOrder = Map2SortOrder.ascending,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2BusStopsFilter.defaultFilter({String searchText = '', bool starred = false }) => Map2BusStopsFilter._(
    searchText: searchText,
    starred: starred,
  );
  factory Map2BusStopsFilter.emptyFilter() => Map2BusStopsFilter._();

  Map2BusStopsFilter._fromJson(Map<String, dynamic> json) : super._fromJson(json);

  @override
  bool get _needsFilter => hasFilter;

  @override
  List<Explore> _filter(List<Explore> explores) {
    String? searchLowerCase = searchText.trim().toLowerCase();
    List<Explore> filtered = <Explore>[];
    for (Explore explore in explores) {
      if ((explore is MTDStop) &&
          ((searchLowerCase.isNotEmpty != true) || (explore.matchSearchTextLowerCase(searchLowerCase))) &&
          ((starred != true) || (Auth2().prefs?.isFavorite(explore as Favorite) == true))
        ) {
        filtered.add(explore);
      }
    }
    return filtered;
  }

  @override
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { bool canSort = false }) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    if (searchText.isNotEmpty) {
      String searchKey = Localization().getStringEx('panel.map2.filter.search.text', 'Search');
      descriptionMap[searchKey] = <String>[searchText];
    }
    if (starred) {
      String starredKey = Localization().getStringEx('panel.map2.filter.starred.text', 'Starred');
      descriptionMap[starredKey] = <String>[];
    }
    if (canSort && descriptionMap.isNotEmpty) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      descriptionMap[sortKey] = <String>[_sortDescriptionValue];
    }
    if ((filteredExplores != null) && descriptionMap.isNotEmpty)  {
      String buildingsKey = Localization().getStringEx('panel.map2.filter.bus_stops.text', 'Stops');
      String buildingsValue = filteredExplores.length.toString();
      descriptionMap[buildingsKey] = <String>[buildingsValue];
    }
    return descriptionMap;
  }
}

class Map2StoriedSitesFilter extends Map2Filter {
  LinkedHashSet<String> tags;
  bool onlyVisited;

  Map2StoriedSitesFilter._({
    required this.tags,
    // ignore: unused_element_parameter
    this.onlyVisited = false,

    String searchText = '',
    bool starred = false,
    Map2SortType sortType = Map2SortType.alphabetical,
    Map2SortOrder sortOrder = Map2SortOrder.ascending,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2StoriedSitesFilter.defaultFilter() => Map2StoriedSitesFilter._(
    tags: LinkedHashSet<String>()
  );

  factory Map2StoriedSitesFilter.emptyFilter() => Map2StoriedSitesFilter._(
    tags: LinkedHashSet<String>()
  );

  Map2StoriedSitesFilter._fromJson(Map<String, dynamic> json) :
    tags = LinkedHashSetUtils.from(JsonUtils.listStringsValue(json['tags'])) ?? LinkedHashSet<String>(),
    onlyVisited = JsonUtils.boolValue(json['onlyVisited']) ?? false,
    super._fromJson(json);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'tags': tags.toList(growable: false),
    'onlyVisited': onlyVisited,
    ...super.toJson(),
  };

  @override
  bool get hasFilter => tags.isNotEmpty || (onlyVisited == true) || super.hasFilter;

  @override
  bool get _needsFilter => hasFilter;

  @override
  List<Explore> _filter(List<Explore> explores) {
    String? searchLowerCase = searchText.trim().toLowerCase();
    List<Explore> filtered = <Explore>[];
    for (Explore explore in explores) {
      if ((explore is Place) &&
          ((searchLowerCase.isNotEmpty != true) || (explore.matchSearchTextLowerCase(searchLowerCase))) &&
          ((onlyVisited != true) || (explore.isVisited == true)) &&
          ((tags.isNotEmpty != true) || (explore.matchTags(tags)))
        ) {
        filtered.add(explore);
      }
    }
    return filtered;
  }

  @override
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { bool canSort = false }) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    if (searchText.isNotEmpty) {
      String searchKey = Localization().getStringEx('panel.map2.filter.search.text', 'Search');
      descriptionMap[searchKey] = <String>[searchText];
    }
    if (tags.isNotEmpty) {
      LinkedHashMap<String, LinkedHashSet<String>> displayTags = tags.displayTags;
      for (String tagCategory in displayTags.keys) {
        LinkedHashSet<String>? tagCategoryValues = displayTags[tagCategory];
        if ((tagCategoryValues != null) && tagCategoryValues.isNotEmpty) {
          String displayCategory = tagCategory.isNotEmpty ? tagCategory : Localization().getStringEx('panel.map2.filter.tags.text', 'Tags');
          descriptionMap[displayCategory] = tagCategoryValues.toList();
        }
      }
    }
    if (onlyVisited) {
      String visitedKey = Localization().getStringEx('panel.map2.filter.visited.text', 'Visited');
      descriptionMap[visitedKey] = <String>[];
    }
    if (canSort && descriptionMap.isNotEmpty) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      descriptionMap[sortKey] = <String>[_sortDescriptionValue];
    }
    if ((filteredExplores != null) && descriptionMap.isNotEmpty)  {
      String buildingsKey = Localization().getStringEx('panel.map2.filter.storied_sites.text', 'Sites');
      String buildingsValue = filteredExplores.length.toString();
      descriptionMap[buildingsKey] = <String>[buildingsValue];
    }
    return descriptionMap;
  }
}

class Map2MyLocationsFilter extends Map2Filter {

  Map2MyLocationsFilter._({
    String searchText = '',
    bool starred = false,
    Map2SortType sortType = Map2SortType.alphabetical,
    Map2SortOrder sortOrder = Map2SortOrder.ascending,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2MyLocationsFilter.defaultFilter() => Map2MyLocationsFilter._();
  factory Map2MyLocationsFilter.emptyFilter() => Map2MyLocationsFilter._();

  Map2MyLocationsFilter._fromJson(Map<String, dynamic> json) : super._fromJson(json);

  @override
  bool get _needsFilter => hasFilter;

  @override
  List<Explore> _filter(List<Explore> explores) {
    String? searchLowerCase = searchText.trim().toLowerCase();
    List<Explore> filtered = <Explore>[];
    for (Explore explore in explores) {
      if ((explore is ExplorePOI) &&
          ((searchLowerCase.isNotEmpty != true) || (explore.matchSearchTextLowerCase(searchLowerCase)))
        ) {
        filtered.add(explore);
      }
    }
    return filtered;
  }

  @override
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { bool canSort = false }) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    if (searchText.isNotEmpty) {
      String searchKey = Localization().getStringEx('panel.map2.filter.search.text', 'Search');
      descriptionMap[searchKey] = <String>[searchText];
    }
    if (canSort && descriptionMap.isNotEmpty) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      descriptionMap[sortKey] = <String>[_sortDescriptionValue];
    }
    if ((filteredExplores != null) && descriptionMap.isNotEmpty)  {
      String buildingsKey = Localization().getStringEx('panel.map2.filter.my_locations.text', 'Locations');
      String buildingsValue = filteredExplores.length.toString();
      descriptionMap[buildingsKey] = <String>[buildingsValue];
    }
    return descriptionMap;
  }
}
