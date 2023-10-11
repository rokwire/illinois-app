import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/model/wellness/WellnessBuilding.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/ui/academics/StudentCourses.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/explore/ExploreBuildingDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/laundry/LaundryRoomDetailPanel.dart';
import 'package:illinois/ui/mtd/MTDStopDeparturesPanel.dart';
import 'package:illinois/ui/appointments/AppointmentDetailPanel.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/ext/Event.dart';
import 'package:illinois/ext/Dining.dart';
import 'package:illinois/ext/LaundryRoom.dart';
import 'package:illinois/ext/Game.dart';
import 'package:illinois/ext/MTD.dart';
import 'package:illinois/ext/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:geolocator/geolocator.dart' as Core;
import 'package:rokwire_plugin/utils/utils.dart';
import 'dart:math' as math;

import 'package:sprintf/sprintf.dart';

extension ExploreExt on Explore {

  String? getShortDisplayLocation(Core.Position? locationData) {
    ExploreLocation? location = exploreLocation;
    if (location != null) {
      if ((locationData != null) && (location.latitude != null) && (location.longitude != null)) {
        double distanceInMeters = Core.Geolocator.distanceBetween(location.latitude!.toDouble(), location.longitude!.toDouble(), locationData.latitude, locationData.longitude);
        double distanceInMiles = distanceInMeters / 1609.344;
        return distanceInMiles.toStringAsFixed(1) + " mi away";
      }
      if ((location.description != null) && location.description!.isNotEmpty) {
        return location.description;
      }
      if ((location.name != null) && (exploreTitle != null) && (location.name == exploreTitle)) {
        if ((location.building != null) && location.building!.isNotEmpty) {
          return location.building;
        }
      }
      else {
        String? displayName = location.displayName;
        if ((displayName != null) && displayName.isNotEmpty) {
          return displayName;
        }
      }
      String? displayAddress = location.displayAddress;
      if ((displayAddress != null) && displayAddress.isNotEmpty) {
        return displayAddress;
      }
    }
    return null;
  }

  String? getLongDisplayLocation(Core.Position? locationData) {
    String displayText = "";
    ExploreLocation? location = exploreLocation;
    if (location != null) {
      if ((locationData != null) && (location.latitude != null) && (location.longitude != null)) {
        double distanceInMeters = Geolocator.distanceBetween(location.latitude!.toDouble(), location.longitude!.toDouble(), locationData.latitude, locationData.longitude);
        double distanceInMiles = distanceInMeters / 1609.344;
        displayText = distanceInMiles.toStringAsFixed(1) + " mi away";
      }
      if ((location.description != null) && location.description!.isNotEmpty) {
        return displayText += (displayText.isNotEmpty ? ", " : "")  + location.description!;
      }
      if ((location.name != null) && (exploreTitle != null) && (location.name == exploreTitle)) {
        if ((location.building != null) && location.building!.isNotEmpty) {
          return displayText += (displayText.isNotEmpty ? ", " : "")  + location.building!;
        }
      }
      else {
        String? displayName = location.displayName;
        if ((displayName != null) && displayName.isNotEmpty) {
          return displayText += (displayText.isNotEmpty ? ", " : "")  + displayName;
        }
      }
      String? displayAddress = location.displayAddress;
      if ((displayAddress != null) && displayAddress.isNotEmpty) {
        return displayText += (displayText.isNotEmpty ? ", " : "")  + displayAddress;
      }
    }
    return null;
  }

  static String? getExploresListDisplayTitle(List<Explore>? exploresList, {String? language}) {
    String? exploresType;
    if (exploresList != null) {
      for (Explore explore in exploresList) {
        String exploreType = explore.runtimeType.toString().toLowerCase();
        if (exploresType == null) {
          exploresType = exploreType;
        }
        else if (exploresType != exploreType) {
          exploresType = null;
          break;
        }
      }
    }

    if ((exploresType == "event") || (exploresType == "event2")) {
      return Localization().getStringEx('panel.explore.item.events.name', 'Events', language: language);
    }
    else if (exploresType == "dining") {
      return Localization().getStringEx('panel.explore.item.dinings.name', 'Dining Locations', language: language);
    }
    else if (exploresType == "laundryroom") {
      return Localization().getStringEx('panel.explore.item.laundry.name', 'Laundry Rooms', language: language);
    }
    else if (exploresType == "game") {
      return Localization().getStringEx('panel.explore.item.games.name', 'Game Locations', language: language);
    }
    else if (exploresType == "building") {
      return Localization().getStringEx('panel.explore.item.buildings.name', 'Buildings', language: language);
    }
    else if (exploresType == "wellnessbuilding") {
      return Localization().getStringEx('panel.explore.item.wellnessbuildings.name', 'Therapist Locations', language: language);
    }
    else if (exploresType == "mtdstop") {
      return Localization().getStringEx('panel.explore.item.mtd_stops.name', 'Bus Stops', language: language);
    }
    else if (exploresType == "studentcourse") {
      return Localization().getStringEx('panel.explore.item.courses.name', 'Course Locations', language: language);
    }
    else if (exploresType == "appointment") {
      return Localization().getStringEx('panel.explore.item.appointments.name', 'Appointment Locations', language: language);
    }
    else if (exploresType == "explorepoi") {
      return Localization().getStringEx('panel.explore.item.pois.name', 'MTD Destinations', language: language);
    }
    else {
      return Localization().getStringEx('panel.explore.item.unknown.name', 'Explores');
    }
  }

  String? get typeDisplayString {
    if (this is Event) {
      return (this as Event).typeDisplayString;
    } else if (this is Game) {
      return (this as Game).typeDisplayString;
    }
    else {
      return null;
    }
  }

  bool get isFavorite {
    if (this is Favorite) {
      return (this is Event)
        ? (this as Event).isFavorite
        : Auth2().isFavorite(this as Favorite);
    }
    return false;
  }

  void toggleFavorite() {
    if (this is Favorite) {
      if (this is Event) {
        (this as Event).toggleFavorite();
      }
      else {
        Auth2().prefs?.toggleFavorite(this as Favorite);
      }
    }
  }

  Map<String, dynamic>? get analyticsAttributes {
    if (this is Event) {
      return (this as Event).analyticsAttributes;
    }
    else if (this is Event2) {
      return (this as Event2).analyticsAttributes;
    }
    else if (this is Dining) {
      return (this as Dining).analyticsAttributes;
    }
    else if (this is Game) {
      return (this as Game).analyticsAttributes;
    }
    else {
      return {
        Analytics.LogAttributeLocation : exploreLocation?.analyticsValue,
      };
    }
  }

  Color? get uiColor {
    // Event         eventColor       E54B30
    // Dining        diningColor      F09842
    // LaundryRoom   accentColor2     5FA7A3
    // Game          fillColorPrimary 002855
    // MTDStop       mtdColor         2376E5
    // StudentCourse eventColor       E54B30
    // ExplorePOI    accentColor3     5182CF

    if (this is Event) {
      return (this as Event).uiColor;
    }
    else if (this is Event2) {
      return (this as Event2).uiColor;
    }
    else if (this is Dining) {
      return (this as Dining).uiColor;
    }
    else if (this is LaundryRoom) {
      return (this as LaundryRoom).uiColor;
    }
    else if (this is Game) {
      return (this as Game).uiColor;
    }
    else if (this is MTDStop) {
      return (this as MTDStop).uiColor;
    }
    else if (this is StudentCourse) {
      return (this as StudentCourse).uiColor;
    }
    else if (this is ExplorePOI) {
      return (this as ExplorePOI).uiColor;
    }
    //else if (this is Building) {}
    //else if (this is WellnessBuilding) {}
    //else if (this is Appointment) {}
    else {
      return Styles().colors?.accentColor2;
    }
  }

  String? get exploreImageUrl {
    if (this is Event) {
      return (this as Event).eventImageUrl;
    }
    else if (this is Event2) {
      return (this as Event2).displayImageUrl;
    }
    else {
      return exploreImageURL;
    }

  }

  void exploreLaunchDetail(BuildContext context, { Core.Position? initialLocationData }) {
    Route? route;
    if (this is Event) {
      if ((this as Event).isGameEvent) {
        route = CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(gameId: (this as Event).speaker, sportName: (this as Event).registrationLabel,),);
      }
      else if ((this as Event).isComposite) {
        route = CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: this as Event),);
      }
      else {
        route = CupertinoPageRoute(builder: (context) => ExploreEventDetailPanel(event: this as Event, initialLocationData: initialLocationData),);
      }
    }
    else if (this is Event2) {
        Event2 event2 = (this as Event2);
        if (event2.hasGame) {
          route = CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: event2.game));
        } else {
          route = CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event2, userLocation: initialLocationData,));
        }
    }
    else if (this is Dining) {
      route = CupertinoPageRoute(builder: (context) => ExploreDiningDetailPanel(dining: this as Dining, initialLocationData: initialLocationData),);
    }
    else if (this is LaundryRoom) {
      route = CupertinoPageRoute(builder: (context) => LaundryRoomDetailPanel(room: this as LaundryRoom),);
    }
    else if (this is Game) {
      route = CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: this as Game),);
    }
    else if (this is Building) {
      route = CupertinoPageRoute(builder: (context) => ExploreBuildingDetailPanel(building: this as Building),);
    }
    else if (this is WellnessBuilding) {
      route = CupertinoPageRoute(builder: (context) => GuideDetailPanel(guideEntryId: (this as WellnessBuilding).guideId),);
    }
    else if (this is MTDStop) {
      route = CupertinoPageRoute(builder: (context) => MTDStopDeparturesPanel(stop: this as MTDStop,),);
    }
    else if (this is StudentCourse) {
      route = CupertinoPageRoute(builder: (context) => StudentCourseDetailPanel(course: this as StudentCourse,),);
    }
    else if (this is Appointment) {
      route = CupertinoPageRoute(builder: (context) => AppointmentDetailPanel(appointment: this as Appointment),);
    }
    else if (this is ExplorePOI) {
      // Not supported
    }
    else {
      route = CupertinoPageRoute(builder: (context) => ExploreDetailPanel(explore: this, initialLocationData: initialLocationData,),);
    }

    if (route != null) {
      Navigator.push(context, route);
    }
  }
}

extension ExploreMap on Explore {

  Color? get mapMarkerColor => uiColor ?? unknownMarkerColor;
  static Color? get unknownMarkerColor => Styles().colors?.accentColor2;

  Color? get mapMarkerBorderColor => unknownMarkerBorderColor;
  static Color? get unknownMarkerBorderColor => Styles().colors?.fillColorPrimary;

  Color? get mapMarkerTextColor => unknownMarkerTextColor;
  static Color? get unknownMarkerTextColor => Styles().colors?.background;

  String? get mapMarkerTitle {
    return exploreTitle;
  }

  String? get mapMarkerSnippet {
    if (this is Event) {
      return (this as Event).displayDate;
    }
    else if (this is Event2) {
      return (this as Event2).shortDisplayDateAndTime;
    }
    else if (this is Dining) {
      return (this as Dining).diningType;
    }
    else if (this is LaundryRoom) {
      return (this as LaundryRoom).displayStatus;
    }
    else if (this is Game) {
      return (this as Game).description;
    }
    else if (this is MTDStop) {
      return (this as MTDStop).code;
    }
    else if (this is StudentCourse) {
      return (this as StudentCourse).section?.displayLocation;
    }
    else if (this is ExplorePOI) {
      return (this as ExplorePOI).location?.description ??
        (this as ExplorePOI).location?.fullAddress ??
        (this as ExplorePOI).location?.displayCoordinates;
    }
    else if (this is Building) {
      return (this as Building).address1;
    }
    else if (this is WellnessBuilding) {
      return (this as WellnessBuilding).detail;
    }
    else if (this is Appointment) {
      return (this as Appointment).location?.title;
    }
    else {
      return null;
    }
  }

  String? getMapGroupMarkerTitle(int count) {
    if ((this is Event) || (this is Event2)) {
      return sprintf(Localization().getStringEx('panel.explore.item.events.count', '%s Events'), [count]);
    }
    else if (this is Dining) {
      return sprintf(Localization().getStringEx('panel.explore.item.dinings.count', '%s Dining Locations'), [count]);
    }
    else if (this is LaundryRoom) {
      return sprintf(Localization().getStringEx('panel.explore.item.laundry.count', '%s Laundry Rooms'), [count]);
    }
    else if (this is Game) {
      return sprintf(Localization().getStringEx('panel.explore.item.games.count', '%s Game Locations'), [count]);
    }
    else if (this is MTDStop) {
      return sprintf(Localization().getStringEx('panel.explore.item.mtd_stops.count', '%s MTD Stops'), [count]);
    }
    else if (this is StudentCourse) {
      return sprintf(Localization().getStringEx('panel.explore.item.courses.count', '%s Course Locations'), [count]);
    }
    else if (this is ExplorePOI) {
      return sprintf(Localization().getStringEx('panel.explore.item.pois.count', '%s MTD Destinations'), [count]);
    }
    else if (this is Building) {
      return sprintf(Localization().getStringEx('panel.explore.item.buildings.count', '%s Buildings'), [count]);
    }
    else if (this is WellnessBuilding) {
      return sprintf(Localization().getStringEx('panel.explore.item.wellnessbuildings.count', '%s Therapist Locations'), [count]);
    }
    else if (this is Appointment) {
      return sprintf(Localization().getStringEx('panel.explore.item.appointments.count', '%s Appointment Locations'), [count]);
    }
    else {
      return sprintf(Localization().getStringEx('panel.explore.item.explores.count', '%s Explores'), [count]);
    }
  }

  Future<bool> launchDirections() async {
    LatLng? targetLocation = await _targetLocation;
    return (targetLocation != null) ? await GeoMapUtils.launchDirections(
      destination: targetLocation,
      travelMode: _defaultTravelMode
    ) : false;
  }

  Future<LatLng?> get _targetLocation async {
    Building? building;
    if (this is Building) {
      building = this as Building;
    }
    else if (this is WellnessBuilding) {
      building = (this as WellnessBuilding).building;
    }
    else if (this is StudentCourse) {
      building = (this as StudentCourse).section?.building;
    }

    if (building != null) {
      Position? userLocation = await LocationServices().location;
      BuildingEntrance? buildingEntrance = building.nearstEntrance(userLocation, requireAda: StudentCourses().requireAda);
      if ((buildingEntrance != null) && buildingEntrance.hasValidLocation) {
        return LatLng(buildingEntrance.latitude!, buildingEntrance.longitude!);
      }
    }

    ExploreLocation? location = exploreLocation;
    return (location?.isLocationCoordinateValid ?? false) ? LatLng(
      location?.latitude?.toDouble() ?? 0,
      location?.longitude?.toDouble() ?? 0
    ) : null;
  }

  String get _defaultTravelMode => ((this is MTDStop) || (this is ExplorePOI)) ?
    GeoMapUtils.traveModeTransit : GeoMapUtils.traveModeWalking;

  static Explore? mapGroupSameExploreForList(List<Explore>? explores) {
    Explore? sameExplore;
    if (explores != null) {
      for (Explore explore in explores) {
        if (sameExplore == null) {
          sameExplore = explore;
        }
        else if (sameExplore.runtimeType != explore.runtimeType) {
          return null;
        }
      }
    }
    return sameExplore;
  }

  static LatLngBounds? boundsOfList(List<Explore>? explores) {
    double? minLat, minLng, maxLat, maxLng;
    if (explores != null) {
      for (Explore explore in explores) {
        ExploreLocation? exploreLocation = explore.exploreLocation;
        if ((exploreLocation != null) && exploreLocation.isLocationCoordinateValid) {
          double exploreLat = exploreLocation.latitude?.toDouble() ?? 0;
          double exploreLng = exploreLocation.longitude?.toDouble() ?? 0;
          if ((minLat != null) && (minLng != null) && (maxLat != null) && (maxLng != null)) {
            if (exploreLat < minLat)
              minLat = exploreLat;
            else if (maxLat < exploreLat)
              maxLat = exploreLat;

            if (exploreLng < minLng)
              minLng = exploreLng;
            else if (maxLng < exploreLng)
              maxLng = exploreLng;
          }
          else {
            minLat = maxLat = exploreLat;
            minLng = maxLng = exploreLng;
          }
        }
      }
    }
    return ((minLat != null) && (minLng != null) && (maxLat != null) && (maxLng != null)) ? LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)) : null;
  }

  static LatLng? centerOfList(List<Explore>? explores) {
    if (explores != null) {
      int count = 0;
      double x = 0, y = 0, z = 0;
      double pi = 3.14159265358979323846264338327950288;
      for (Explore explore in explores) {
        ExploreLocation? exploreLocation = explore.exploreLocation;
        if ((exploreLocation != null) && exploreLocation.isLocationCoordinateValid) {
          double exploreLat = exploreLocation.latitude?.toDouble() ?? 0;
          double exploreLng = exploreLocation.longitude?.toDouble() ?? 0;
  	      
          // https://stackoverflow.com/a/60163851/3759472
          double latitude = exploreLat * pi / 180;
          double longitude = exploreLng * pi / 180;
          double c1 = math.cos(latitude);
          x = x + c1 * math.cos(longitude);
          y = y + c1 * math.sin(longitude);
          z = z + math.sin(latitude);
          count++;
        }
      }

      if (0 < count) {
        x = x / count.toDouble();
        y = y / count.toDouble();
        z = z / count.toDouble();

        double centralLongitude = math.atan2(y, x);
        double centralSquareRoot = math.sqrt(x * x + y * y);
        double centralLatitude = math.atan2(z, centralSquareRoot);
        return LatLng(centralLatitude * 180 / pi, centralLongitude * 180 / pi);
      }
    }
    return null;
  }
}

extension ExploreLocationExp on ExploreLocation {

  String? get displayName {
    if ((name != null) && name!.isNotEmpty) {
      return name;
    }
    else if ((building != null) && building!.isNotEmpty) {
      return building;
    }
    else {
      return null;
    }
  }

  String? get displayAddress {
    return fullAddress ?? buildDisplayAddress();
  }

  String? buildDisplayAddress() {
    String? displayText;
    String delimiter = ", ";

    if ((address != null) && address!.isNotEmpty) {
      // ignore: unnecessary_null_comparison
      displayText = (displayText != null) ? "$displayText$delimiter$address" : address;
    }

    if ((city != null) && city!.isNotEmpty) {
      displayText = (displayText != null) ? "$displayText$delimiter$city" : city;
    }

    if ((state != null) && state!.isNotEmpty) {
      displayText = (displayText != null) ? "$displayText$delimiter$state" : state;
      delimiter = " ";
    }

    if ((zip != null) && zip!.isNotEmpty) {
      displayText = (displayText != null) ? "$displayText$delimiter$zip" : city;
    }

    return displayText;
  }

  String? get displayDescription => StringUtils.isNotEmpty(description) ? description : null;

  String? get displayCoordinates =>
    isLocationCoordinateValid ? "[${latitude?.toStringAsFixed(6)}, ${longitude?.toStringAsFixed(6)}]" : null;
}

extension ExploreLocationMap on ExploreLocation {
  LatLng? get exploreLocationMapCoordinate => (isLocationCoordinateValid == true) ? LatLng(latitude?.toDouble() ?? 0, longitude?.toDouble() ?? 0) : null;
}

extension ExplorePOIExt on ExplorePOI {
  Color? get uiColor => Styles().colors?.accentColor3;
}