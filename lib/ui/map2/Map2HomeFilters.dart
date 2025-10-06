
import 'dart:collection';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Building.dart';
import 'package:illinois/ext/Dining.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/LaundryRoom.dart';
import 'package:illinois/ext/MTD.dart';
import 'package:illinois/model/Building.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/map2/Map2HomePanel.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Map2Filter {

  String searchText = '';
  bool starred = false;
  Map2SortType? sortType;
  Map2SortOrder? sortOrder;

  Map2Filter._({
    this.searchText = '',
    this.starred = false,
    this.sortType,
    this.sortOrder,
  });

  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { List<Explore>? explores }) =>
    LinkedHashMap<String, List<String>>();

  static Map2Filter? fromContentType(Map2ContentType? contentType) {
    switch (contentType) {
      case Map2ContentType.CampusBuildings:      return Map2CampusBuildingsFilter.defaultFilter();
      case Map2ContentType.StudentCourses:       return Map2StudentCoursesFilter.defaultFilter();
      case Map2ContentType.DiningLocations:      return Map2DiningLocationsFilter.defaultFilter();
      case Map2ContentType.Events2:              return Map2Events2Filter.defaultFilter();
      case Map2ContentType.LaundryRooms:         return Map2LaundryRoomsFilter.defaultFilter();
      case Map2ContentType.BusStops:             return Map2BusStopsFilter.defaultFilter();
      case Map2ContentType.Therapists:           return null;
      case Map2ContentType.MyLocations:          return Map2MyLocationsFilter.defaultFilter();
      default: return null;
    }
  }

  // Filter

  List<Explore> filter(List<Explore> explores) =>
    (explores.isNotEmpty && _hasFilter) ? _filter(explores) : explores;

  bool get _hasFilter => false;

  List<Explore> _filter(List<Explore> explores) => explores;

  // Sort

  List<Explore> sort(Iterable<Explore> explores, { Position? position }) {
    List<Explore> sortedExplores = List<Explore>.from(explores);
    if (explores.isNotEmpty && _hasSort) {
      _sort(sortedExplores, position: position);
    }
    return sortedExplores;
  }

  bool get _hasSort => (sortType != null);

  void _sort(List<Explore> explores, { Position? position }) {
    switch (sortType) {
      case Map2SortType.dateTime: _sortByDateTime(explores); break;
      case Map2SortType.alphabetical: _sortAlphabeticaly(explores); break;
      case Map2SortType.proximity: _sortByProximity(explores, position: position); break;
      default: break;
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
}

class Map2CampusBuildingsFilter extends Map2Filter {
  LinkedHashSet<String> amenityIds = LinkedHashSet<String>();

  Map2CampusBuildingsFilter._({
    required this.amenityIds,

    String searchText = '',
    bool starred = false,
    Map2SortType? sortType,
    Map2SortOrder? sortOrder,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2CampusBuildingsFilter.defaultFilter({ String searchText = '', bool starred = false }) => Map2CampusBuildingsFilter._(
    amenityIds: LinkedHashSet<String>(),
    searchText: searchText,
    starred: starred,
  );

  @override
  bool get _hasFilter => ((searchText.isNotEmpty == true) || (starred == true) || (amenityIds.isNotEmpty == true));

  @override
  List<Explore> _filter(List<Explore> explores) {
    String? searchLowerCase = searchText.toLowerCase();
    List<Explore> filtered = <Explore>[];
    for (Explore explore in explores) {
      if ((explore is Building) &&
          ((searchLowerCase.isNotEmpty != true) || (explore.matchSearchTextLowerCase(searchLowerCase))) &&
          ((starred != true) || (Auth2().prefs?.isFavorite(explore as Favorite) == true)) &&
          ((amenityIds.isNotEmpty != true) || (explore.matchAmenityIds(amenityIds)))
        ) {
        filtered.add(explore);
      }
    }
    return filtered;
  }

  @override
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { List<Explore>? explores }) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    if (searchText.isNotEmpty) {
      String searchKey = Localization().getStringEx('panel.map2.filter.search.text', 'Search');
      descriptionMap[searchKey] = <String>[searchText];
    }
    if (amenityIds.isNotEmpty) {
      String amenitiesKey = Localization().getStringEx('panel.map2.filter.amenities.text', 'Amenities');
      Map<String, String?> amenities = JsonUtils.cast<List<Building>>(explores ?? filteredExplores)?.featureNames ?? <String, String>{};
      List<String> amenityValues = List<String>.from(amenityIds.map<String>((String amenityId) => amenities[amenityId] ?? amenityId));
      descriptionMap[amenitiesKey] = amenityValues;
    }
    if (starred) {
      String starredKey = Localization().getStringEx('panel.map2.filter.starred.text', 'Starred');
      descriptionMap[starredKey] = <String>[];
    }
    if (sortType != null) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      String sortValue = sortType?.displayTitle ?? '';
      if (sortValue.isNotEmpty && (sortOrder != null)) {
        String? sortOrderValue = sortOrder?.displayMnemo;
        if ((sortOrderValue != null) && sortOrderValue.isNotEmpty) {
          sortValue += " $sortOrderValue";
        }
      }
      descriptionMap[sortKey] = <String>[sortValue];
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

  Map2StudentCoursesFilter._({
    String searchText = '',
    bool starred = false,
    Map2SortType? sortType,
    Map2SortOrder? sortOrder,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2StudentCoursesFilter.defaultFilter() => Map2StudentCoursesFilter._();

  @override
  bool get _hasFilter => true;

  @override
  List<Explore> _filter(List<Explore> explores) {
    List<Explore> filtered = <Explore>[];
    for (Explore explore in explores) {
      if (explore.exploreLocation?.isLocationCoordinateValid == true) {
        filtered.add(explore);
      }
    }
    return filtered;
  }
}

class Map2DiningLocationsFilter extends Map2Filter {
  bool onlyOpened = false;
  PaymentType? paymentType = null;

  Map2DiningLocationsFilter._({
    this.onlyOpened = false,
    this.paymentType,

    String searchText = '',
    bool starred = false,
    Map2SortType? sortType,
    Map2SortOrder? sortOrder,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2DiningLocationsFilter.defaultFilter({bool onlyOpened = false, PaymentType? paymentType}) => Map2DiningLocationsFilter._(
    onlyOpened: onlyOpened,
    paymentType: paymentType,
  );

  @override
  bool get _hasFilter => ((searchText.isNotEmpty == true) || (starred == true) || (onlyOpened != false) || (paymentType != null));

  @override
  List<Explore> _filter(List<Explore> explores) {
    String? searchLowerCase = searchText.toLowerCase();
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
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { List<Explore>? explores }) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    if (searchText.isNotEmpty) {
      String searchKey = Localization().getStringEx('panel.map2.filter.search.text', 'Search');
      descriptionMap[searchKey] = <String>[searchText];
    }
    if (paymentType != null) {
      String? paymentTypeValue = PaymentTypeHelper.paymentTypeToDisplayString(paymentType);
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
    if (sortType != null) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      String sortValue = sortType?.displayTitle ?? '';
      if (sortValue.isNotEmpty && (sortOrder != null)) {
        String? sortOrderValue = sortOrder?.displayMnemo;
        if ((sortOrderValue != null) && sortOrderValue.isNotEmpty) {
          sortValue += " $sortOrderValue";
        }
      }
      descriptionMap[sortKey] = <String>[sortValue];
    }
    if ((filteredExplores != null) && descriptionMap.isNotEmpty)  {
      String buildingsKey = Localization().getStringEx('panel.map2.filter.dinings.text', 'Dining Locations');
      String buildingsValue = filteredExplores.length.toString();
      descriptionMap[buildingsKey] = <String>[buildingsValue];
    }
    return descriptionMap;
  }
}

class Map2Events2Filter extends Map2Filter {
  Event2FilterParam event2Filter = Event2FilterParam.fromStorage();

  Map2Events2Filter._({
    required this.event2Filter,

    String searchText = '',
    bool starred = false,
    Map2SortType? sortType,
    Map2SortOrder? sortOrder,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2Events2Filter.defaultFilter({ String searchText = '' }) => Map2Events2Filter._(
    event2Filter: Event2FilterParam.fromStorage(),
    sortType: Map2SortTypeImpl.fromEvent2SortType(Event2SortTypeImpl.fromJson(Storage().events2SortType)),
    searchText: searchText,
  );

  @override
  bool get _hasFilter => true;

  @override
  List<Explore> _filter(List<Explore> explores) {
    List<Explore> filtered = <Explore>[];
    for (Explore explore in explores) {
      if (explore.exploreLocation?.isLocationCoordinateValid == true) {
        filtered.add(explore);
      }
    }
    return filtered;
  }

  @override
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { List<Explore>? explores }) {
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

    if (sortType != null) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      String sortValue = sortType?.displayTitle ?? '';
      descriptionMap[sortKey] = <String>[sortValue];
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
    Map2SortType? sortType,
    Map2SortOrder? sortOrder,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2LaundryRoomsFilter.defaultFilter() => Map2LaundryRoomsFilter._();

  @override
  bool get _hasFilter => ((searchText.isNotEmpty == true) || (starred == true));

  @override
  List<Explore> _filter(List<Explore> explores) {
    String? searchLowerCase = searchText.toLowerCase();
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
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { List<Explore>? explores }) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    if (searchText.isNotEmpty) {
      String searchKey = Localization().getStringEx('panel.map2.filter.search.text', 'Search');
      descriptionMap[searchKey] = <String>[searchText];
    }
    if (starred) {
      String starredKey = Localization().getStringEx('panel.map2.filter.starred.text', 'Starred');
      descriptionMap[starredKey] = <String>[];
    }
    if (sortType != null) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      String sortValue = sortType?.displayTitle ?? '';
      if (sortValue.isNotEmpty && (sortOrder != null)) {
        String? sortOrderValue = sortOrder?.displayMnemo;
        if ((sortOrderValue != null) && sortOrderValue.isNotEmpty) {
          sortValue += " $sortOrderValue";
        }
      }
      descriptionMap[sortKey] = <String>[sortValue];
    }
    if ((filteredExplores != null) && descriptionMap.isNotEmpty)  {
      String buildingsKey = Localization().getStringEx('panel.map2.filter.laundry_rooms.text', 'Laundry Rooms');
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
    Map2SortType? sortType,
    Map2SortOrder? sortOrder,
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

  @override
  bool get _hasFilter => ((searchText.isNotEmpty == true) || (starred == true));

  @override
  List<Explore> _filter(List<Explore> explores) {
    String? searchLowerCase = searchText.toLowerCase();
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
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { List<Explore>? explores }) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    if (searchText.isNotEmpty) {
      String searchKey = Localization().getStringEx('panel.map2.filter.search.text', 'Search');
      descriptionMap[searchKey] = <String>[searchText];
    }
    if (starred) {
      String starredKey = Localization().getStringEx('panel.map2.filter.starred.text', 'Starred');
      descriptionMap[starredKey] = <String>[];
    }
    if (sortType != null) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      String sortValue = sortType?.displayTitle ?? '';
      if (sortValue.isNotEmpty && (sortOrder != null)) {
        String? sortOrderValue = sortOrder?.displayMnemo;
        if ((sortOrderValue != null) && sortOrderValue.isNotEmpty) {
          sortValue += " $sortOrderValue";
        }
      }
      descriptionMap[sortKey] = <String>[sortValue];
    }
    if ((filteredExplores != null) && descriptionMap.isNotEmpty)  {
      String buildingsKey = Localization().getStringEx('panel.map2.filter.bus_stops.text', 'Bus Stops');
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
    Map2SortType? sortType,
    Map2SortOrder? sortOrder,
  }) : super._(
    searchText: searchText,
    starred: starred,
    sortType: sortType,
    sortOrder: sortOrder,
  );

  factory Map2MyLocationsFilter.defaultFilter() => Map2MyLocationsFilter._();

  @override
  bool get _hasFilter => (searchText.isNotEmpty == true);

  @override
  List<Explore> _filter(List<Explore> explores) {
    String? searchLowerCase = searchText.toLowerCase();
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
  LinkedHashMap<String, List<String>> description(List<Explore>? filteredExplores, { List<Explore>? explores }) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    if (searchText.isNotEmpty) {
      String searchKey = Localization().getStringEx('panel.map2.filter.search.text', 'Search');
      descriptionMap[searchKey] = <String>[searchText];
    }
    if (sortType != null) {
      String sortKey = Localization().getStringEx('panel.map2.filter.sort.text', 'Sort');
      String sortValue = sortType?.displayTitle ?? '';
      if (sortValue.isNotEmpty && (sortOrder != null)) {
        String? sortOrderValue = sortOrder?.displayMnemo;
        if ((sortOrderValue != null) && sortOrderValue.isNotEmpty) {
          sortValue += " $sortOrderValue";
        }
      }
      descriptionMap[sortKey] = <String>[sortValue];
    }
    if ((filteredExplores != null) && descriptionMap.isNotEmpty)  {
      String buildingsKey = Localization().getStringEx('panel.map2.filter.my_locations.text', 'My Locations');
      String buildingsValue = filteredExplores.length.toString();
      descriptionMap[buildingsKey] = <String>[buildingsValue];
    }
    return descriptionMap;
  }
}
