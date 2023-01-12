import 'dart:ui';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/model/wellness/Appointment.dart';
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
import 'package:rokwire_plugin/service/styles.dart';
import 'package:geolocator/geolocator.dart' as Core;
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
        String displayName = location.getDisplayName();
        if (displayName.isNotEmpty) {
          return displayName;
        }
      }
      String displayAddress = location.getDisplayAddress();
      if (displayAddress.isNotEmpty) {
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
        String displayName = location.getDisplayName();
        if (displayName.isNotEmpty) {
          return displayText += (displayText.isNotEmpty ? ", " : "")  + displayName;
        }
      }
      String displayAddress = location.getDisplayAddress();
      if ( displayAddress.isNotEmpty) {
        return displayText += (displayText.isNotEmpty ? ", " : "")  + displayAddress;
      }
    }
    return null;
  }

  static String? getExploresListDisplayTitle(List<Explore>? exploresList) {
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

    if (exploresType == "event") {
      return Localization().getStringEx('panel.explore.item.events.name', 'Events');
    }
    else if (exploresType == "dining") {
      return Localization().getStringEx('panel.explore.item.dinings.name', 'Dinings');
    }
    else if (exploresType == "laundryroom") {
      return Localization().getStringEx('panel.explore.item.laundry.name', 'Laundry');
    }
    else if (exploresType == "game") {
      return Localization().getStringEx('panel.explore.item.games.name', 'Games');
    }
    else if (exploresType == "place") {
      return Localization().getStringEx('panel.explore.item.places.name', 'Places');
    }
    else if (exploresType == "building") {
      return Localization().getStringEx('panel.explore.item.buildings.name', 'Buildings');
    }
    else if (exploresType == "mtdstop") {
      return Localization().getStringEx('panel.explore.item.mtd_stops.name', 'MTD Stops');
    }
    else if (exploresType == "studentcourse") {
      return Localization().getStringEx('panel.explore.item.courses.name', 'Courses');
    }
    else if (exploresType == "appointment") {
      return Localization().getStringEx('panel.explore.item.appointments.name', 'Appointments');
    }
    else if (exploresType == "explorepoi") {
      return Localization().getStringEx('panel.explore.item.pois.name', 'POIs');
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
    //else if (this is Appointment) {}
    else {
      return Styles().colors?.accentColor2;
    }
  }

  String? get exploreImageUrl => (this is Event) ? (this as Event).eventImageUrl : exploreImageURL;
}

extension ExploreMap on Explore {

  String? get mapMarkerAssetName {
    if (this is Event) {
      return 'images/map-marker-group-event.png';
    }
    else if (this is Dining) {
      return 'images/map-marker-group-dining.png';
    }
    else if (this is LaundryRoom) {
      return 'images/map-marker-group-laundry.png';
    }
    else if (this is Game) {
      return 'images/map-marker-group-game.png';
    }
    else if (this is MTDStop) {
      return 'images/map-marker-group-mtd-stop';
    }
    else if (this is StudentCourse) {
      return 'images/map-marker-group-event.png';
    }
    else if (this is ExplorePOI) {
      return 'images/map-marker-group-poi.png';
    }
    //else if (this is Building) {}
    //else if (this is Appointment) {}
    else {
      return 'images/map-marker-group-laundry.png';
    }
  }

  String? get mapMarkerTitle {
    return exploreTitle;
  }

  String? get mapMarkerSnippet {
    if (this is Event) {
      return (this as Event).displayDate;
    }
    else if (this is Dining) {
      return exploreShortDescription;
    }
    else if (this is LaundryRoom) {
      return exploreSubTitle;
    }
    else if (this is Game) {
      return exploreShortDescription;
    }
    else if (this is MTDStop) {
      return exploreSubTitle;
    }
    else if (this is StudentCourse) {
      return (this as StudentCourse).section?.displayLocation;
    }
    else if (this is ExplorePOI) {
      return exploreLocationDescription;
    }
    else if (this is Building) {
      return (this as Building).address1;
    }
    else if (this is Appointment) {
      return (this as Appointment).location?.title;
    }
    else {
      return null;
    }
  }

  String? getMapGroupMarkerTitle(int count) {
    if (this is Event) {
      return sprintf('%s Events', [count]);
    }
    else if (this is Dining) {
      return sprintf('%s Dining Locations', [count]);
    }
    else if (this is LaundryRoom) {
      return sprintf('%s Laundry Rooms', [count]);
    }
    else if (this is Game) {
      return sprintf('%s Games', [count]);
    }
    else if (this is MTDStop) {
      return sprintf('%s MTD Stops', [count]);
    }
    else if (this is StudentCourse) {
      return sprintf('%s Courses', [count]);
    }
    else if (this is ExplorePOI) {
      return sprintf('%s MTD Destinations', [count]);
    }
    else if (this is Building) {
      return sprintf('%s Buildings', [count]);
    }
    else if (this is Appointment) {
      return sprintf('%s Appointments', [count]);
    }
    else {
      return sprintf('%s Explores', [count]);
    }
  }

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

extension ExplorePOIExt on ExplorePOI {
  Color? get uiColor => Styles().colors?.accentColor3;
}