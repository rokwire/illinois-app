// XmlUtils

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
}
