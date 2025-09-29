
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gms;

extension PositionExt on Position {
  gms.LatLng get gmsLatLng =>  gms.LatLng(latitude, longitude);
}