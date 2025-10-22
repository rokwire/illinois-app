// XmlUtils

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';
import 'package:mime/mime.dart';

class FileUtils {
  static bool isImage(String? path) => (mimeTypeExt(path)?.startsWith('image/') == true);
  static bool isGif(String? path) => (mimeTypeExt(path) == 'image/gif');
  static bool isVideo(String? path) => (mimeTypeExt(path)?.startsWith('video/') == true);
  static bool isAudio(String? path) => (mimeTypeExt(path)?.startsWith('audio/') == true);

  static String? mimeTypeExt(String? path) => path != null ? lookupMimeType(path) : null;
}

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
    return (childElementNode?.nodeType == XmlNodeType.TEXT) ? childElementNode?.value /*childElementNode?.innerText*/ : null;
  }

  static String? childCdata(XmlNode? xmlNode, String name, {String? namespace}) {
    XmlElement? childElement = child(xmlNode, name, namespace: namespace);
    XmlNode? childElementNode = (childElement?.children.length == 1) ? childElement?.children.first : null;
    return (childElementNode?.nodeType == XmlNodeType.CDATA) ? childElementNode?.value /*childElementNode?.innerText*/ : null;
  }
}

class GeoMapUtils {

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
  static double getDistance(double lat1, double lng1, double lat2, double lng2) {
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

  static Future<bool> launchDirections({ dynamic origin, dynamic destination, String? travelMode }) async {

    Uri? googleMapsUri = Uri.tryParse(_googleMapsDirectionsUrl(origin: origin, destination: destination, travelMode: travelMode));
    if ((googleMapsUri != null) && await canLaunchUrl(googleMapsUri) && await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication)) {
      debugPrint("Map directions: $googleMapsUri");
      return true;
    }

    Uri? wazeMapsUri = Uri.tryParse(_wazeMapsDirectionsUrl(origin: origin, destination: destination, travelMode: travelMode));
    if ((wazeMapsUri != null) && await canLaunchUrl(wazeMapsUri) && await launchUrl(wazeMapsUri, mode: LaunchMode.externalApplication)) {
      debugPrint("Map directions: $wazeMapsUri");
      return true;
    }

    return false;
  }

  static Future<String?> directionsUrl({ dynamic origin, dynamic destination, String? travelMode }) async {

    String? googleMapsUrl = _googleMapsDirectionsUrl(origin: origin, destination: destination, travelMode: travelMode);
    Uri? googleMapsUri = Uri.tryParse(googleMapsUrl);
    if ((googleMapsUri != null) && await canLaunchUrl(googleMapsUri)) {
      return googleMapsUrl;
    }

    String? wazeMapsUrl = _wazeMapsDirectionsUrl(origin: origin, destination: destination, travelMode: travelMode);
    Uri? wazeMapsUri = Uri.tryParse(wazeMapsUrl);
    if ((wazeMapsUri != null) && await canLaunchUrl(wazeMapsUri)) {
      return wazeMapsUrl;
    }

    return null;
  }

  // https://developers.google.com/maps/documentation/urls/get-started#directions-action
  static String _googleMapsDirectionsUrl({ dynamic origin, dynamic destination, String? travelMode }) {

    String url = "https://www.google.com/maps/dir/?api=1"; //TBD: app config
    if (origin is LatLng) {
      url += "&origin=${origin.latitude.toStringAsFixed(6)},${origin.longitude.toStringAsFixed(6)}";
    }
    else if (origin != null) {
      url += "&origin=${Uri.encodeComponent(origin.toString())}";
    }

    if (destination is LatLng) {
      url += "&destination=${destination.latitude.toStringAsFixed(6)},${destination.longitude.toStringAsFixed(6)}";
    }
    else if (destination != null) {
      url += "&destination=${Uri.encodeComponent(destination.toString())}";
    }

    if (travelMode != null) {
      url += "&travelmode=$travelMode";
    }
    return url;
  }

  // https://developers.google.com/waze/deeplinks
  static String _wazeMapsDirectionsUrl({ dynamic origin, dynamic destination, String? travelMode }) {
    String url = "https://waze.com/ul?navigate=yes"; //TBD: app config
    if (destination is LatLng) {
      url += "&ll=${destination.latitude.toStringAsFixed(6)},${destination.longitude.toStringAsFixed(6)}";
    }
    else if (destination != null) {
      url += "&q=${Uri.encodeComponent(destination.toString())}";
    }
    return url;
  }

  static Future<bool> launchLocation(dynamic position) async {

    String? googleMapsUrl = _googleMapsLocationUrl(position);
    Uri? googleMapsUri = (googleMapsUrl != null) ? Uri.tryParse(googleMapsUrl) : null;
    if ((googleMapsUri != null) && await canLaunchUrl(googleMapsUri) && await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication)) {
      debugPrint("Map directions: $googleMapsUrl");
      return true;
    }

    String? wazeMapsUrl = _wazeMapsLocationUrl(position);
    Uri? wazeMapsUri = (wazeMapsUrl != null) ? Uri.tryParse(wazeMapsUrl) : null;
    if ((wazeMapsUri != null) && await canLaunchUrl(wazeMapsUri) && await launchUrl(wazeMapsUri, mode: LaunchMode.externalApplication)) {
      debugPrint("Map directions: $wazeMapsUrl");
      return true;
    }

    return false;
  }

  static Future<String?> locationUrl(dynamic position) async {

    String? googleMapsUrl = _googleMapsLocationUrl(position);
    Uri? googleMapsUri = (googleMapsUrl != null) ? Uri.tryParse(googleMapsUrl) : null;
    if ((googleMapsUri != null) && await canLaunchUrl(googleMapsUri)) {
      return googleMapsUrl;
    }

    String? wazeMapsUrl = _wazeMapsLocationUrl(position);
    Uri? wazeMapsUri = (wazeMapsUrl != null) ? Uri.tryParse(wazeMapsUrl) : null;
    if ((wazeMapsUri != null) && await canLaunchUrl(wazeMapsUri) && await launchUrl(wazeMapsUri, mode: LaunchMode.externalApplication)) {
      return wazeMapsUrl;
    }

    return null;
  }

  // https://developers.google.com/maps/documentation/urls/get-started#search-action
  static String? _googleMapsLocationUrl(dynamic position) {
    final String baseUrl = "https://www.google.com/maps/search/?api=1"; //TBD: app config
    if (position is LatLng) {
      return "$baseUrl&query=${position.latitude.toStringAsFixed(6)},${position.longitude.toStringAsFixed(6)}";
    }
    else if (position != null) {
      return "$baseUrl&query=${Uri.encodeComponent(position.toString())}";
    }
    else {
      return null;
    }
  }

  // https://developers.google.com/waze/deeplinks
  static String? _wazeMapsLocationUrl(dynamic position) {
    final String baseUrl = "https://waze.com/ul"; //TBD: app config
    if (position is LatLng) {
      return "$baseUrl?ll=${position.latitude.toStringAsFixed(6)},${position.longitude.toStringAsFixed(6)}";
    }
    else if (position != null) {
      return "baseUrl?q=${Uri.encodeComponent(position.toString())}";
    }
    else {
      return null;
    }
  }
}

// TODO: Might be better in the plugin rather than the app
class LinearProgressColorUtils {
  static Color linearProgressIndicatorColor(double percentage) {
    return Color.lerp(
      Colors.red,
      Colors.green,
      percentage,
    )!;
  }

  static Color linearProgressIndicatorBackgroundColor(double percentage) {
    return Color.lerp(
      Colors.red[100],
      Colors.green[100],
      percentage,
    )!;
  }
}

class NullableValue<T> {
  final T? value;
  NullableValue(this.value);

  factory  NullableValue.empty() => NullableValue(null);
}
