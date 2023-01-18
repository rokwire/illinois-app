// XmlUtils

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';
import 'dart:math' as math;

class XmlUtils {
  
  static XmlDocument? parse(String? xmlString) {
    try { return (xmlString != null) ? XmlDocument.parse(xmlString) : null; }
    catch(e) { print(e.toString()); }
    return null;
  }

  static Future<XmlDocument?> parseAsync(String? xmlString) async {
    return (xmlString != null) ? compute(parse, xmlString) : null;
  }

  static Iterable<XmlElement>? children(XmlNode? xmlNode, String name, {String? namespace}) {
    return xmlNode?.findElements(name, namespace: namespace);
  }

  static XmlElement? child(XmlNode? xmlNode, String name, {String? namespace}) {
    Iterable<XmlElement>? list = children(xmlNode, name, namespace: namespace);
    return (list != null) && list.isNotEmpty ? list.first : null;
  }

  static String? childText(XmlNode? xmlNode, String name, {String? namespace}) {
    XmlElement? childElement = child(xmlNode, name, namespace: namespace);
    XmlNode? childElementNode = (childElement?.children.length == 1) ? childElement?.children.first : null;
    return (childElementNode?.nodeType == XmlNodeType.TEXT) ? childElementNode?.text : null;
  }

  static String? childCdata(XmlNode? xmlNode, String name, {String? namespace}) {
    XmlElement? childElement = child(xmlNode, name, namespace: namespace);
    XmlNode? childElementNode = (childElement?.children.length == 1) ? childElement?.children.first : null;
    return (childElementNode?.nodeType == XmlNodeType.CDATA) ? childElementNode?.text : null;
  }
}

class GoogleMapUtils {

  static double latRad(double lat) {
    final double sin = math.sin(lat * math.pi / 180);
    final double radX2 = math.log((1 + sin) / (1 - sin)) / 2;
    return math.max(math.min(radX2, math.pi), -math.pi) / 2;
  }

  static double getMapBoundZoom(LatLngBounds bounds, double mapWidth, double mapHeight) {
    final LatLng northEast = bounds.northeast;
    final LatLng southWest = bounds.southwest;

    final double latFraction = (latRad(northEast.latitude) - latRad(southWest.latitude)) / math.pi;

    final double lngDiff = northEast.longitude - southWest.longitude;
    final double lngFraction = ((lngDiff < 0) ? (lngDiff + 360) : lngDiff) / 360;

    final double latZoom = (math.log(mapHeight / 256 / latFraction) / math.ln2).floorToDouble();
    final double lngZoom = (math.log(mapWidth / 256 / lngFraction) / math.ln2).floorToDouble();

    return math.min(latZoom, lngZoom);
  }

  // Distance in meters
  static double getDistance(double lat1, double lng1, double lat2, double  lng2) {
    double p = 0.017453292519943295;
    double a = 0.5 - math.cos((lat2 - lat1) * p)/2 + 
               math.cos(lat1 * p) * math.cos(lat2 * p) * 
               (1 - math.cos((lng2 - lng1) * p))/2;
    return 12742 * 1000 * math.asin(math.sqrt(a));
  }

  static const String traveModeWalking   = 'walking';
  static const String traveModeBycycling = 'bicycling';
  static const String traveModeDriving   = 'driving';
  static const String traveModeTransit   = 'transit';

  static Future<bool> launchDirections({ LatLng? origin, LatLng? destination, String? travelMode }) async {
    Uri? googleMapsUri = Uri.tryParse(_googleMapsUrl(origin: origin, destination: destination, travelMode: travelMode));
    if ((googleMapsUri != null) && await canLaunchUrl(googleMapsUri) && await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    Uri? wazeMapsUri = Uri.tryParse(_wazeMapsUrl(origin: origin, destination: destination, travelMode: travelMode));
    if ((wazeMapsUri != null) && await canLaunchUrl(wazeMapsUri) && await launchUrl(wazeMapsUri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    return false;
  }

  static String _googleMapsUrl({ LatLng? origin, LatLng? destination, String? travelMode }) {
    // https://developers.google.com/maps/documentation/urls/get-started#directions-action
    String url = "https://www.google.com/maps/dir/?api=1"; //TBD: app config
    if (origin != null) {
      url += "&origin=${origin.latitude.toStringAsFixed(6)},${origin.longitude.toStringAsFixed(6)}";
    }
    if (destination != null) {
      url += "&destination=${destination.latitude.toStringAsFixed(6)},${destination.longitude.toStringAsFixed(6)}";
    }
    if (travelMode != null) {
      url += "&travelmode=$travelMode";
    }
    return url;
  }

  static String _wazeMapsUrl({ LatLng? origin, LatLng? destination, String? travelMode }) {
    // https://developers.google.com/waze/deeplinks
    String url = "https://waze.com/ul?navigate=yes"; //TBD: app config
    if (destination != null) {
      url += "&ll=${destination.latitude.toStringAsFixed(6)},${destination.longitude.toStringAsFixed(6)}";
    }
    return url;
  }
}
