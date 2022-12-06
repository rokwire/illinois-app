import 'dart:ui';

import 'package:geolocator/geolocator.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/ext/Event.dart';
import 'package:illinois/ext/Dining.dart';
import 'package:illinois/ext/LaundryRoom.dart';
import 'package:illinois/ext/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:geolocator/geolocator.dart' as Core;

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
    else {
      return Styles().colors?.eventColor;
    }
  }

  String? get exploreImageUrl => (this is Event) ? (this as Event).eventImageUrl : exploreImageURL;
}