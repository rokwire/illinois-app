import 'package:geolocator/geolocator.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/localization.dart';

extension PositionUtils on Position {
  String? displayDistance(ExploreLocation? location) {
    double? locationLatitude = location?.latitude;
    double? locationLongitude = location?.longitude;
    if ((locationLatitude != null) && (locationLatitude != 0) && (locationLongitude != null) && (locationLongitude != 0)) {
      double distanceInMeters = Geolocator.distanceBetween(locationLatitude, locationLongitude, latitude, longitude);
      double distanceInMiles = distanceInMeters / 1609.344;
      //int whole = (((distanceInMiles * 10) + 0.5).toInt() % 10);
      int displayPrecision = ((distanceInMiles < 10) && ((((distanceInMiles * 10) + 0.5).toInt() % 10) != 0)) ? 1 : 0;
      return Localization().getStringEx('model.explore.distance.format', '{{distance}} mi away').
        replaceAll('{{distance}}', distanceInMiles.toStringAsFixed(displayPrecision));
    }
    else {
      return null;
    }
  }
}