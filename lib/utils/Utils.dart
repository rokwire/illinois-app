// XmlUtils

import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

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
}