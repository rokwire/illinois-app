/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'package:illinois/service/Styles.dart';
import 'package:path/path.dart' as Path;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Log.dart';

class AppString {

  static bool isStringEmpty(String stringToCheck) {
    return (stringToCheck == null || stringToCheck.isEmpty);
  }

  static bool isStringNotEmpty(String stringToCheck) {
    return !isStringEmpty(stringToCheck);
  }

  static String getDefaultEmptyString({String value, String defaultValue = ''}) {
    if (isStringEmpty(value)) {
      return defaultValue;
    }
    return value;
  }

  static String wrapRange(String s, String firstValue, String secondValue, int startPosition, int endPosition) {
    if ((s == null) || (firstValue == null) || (secondValue == null) || (startPosition < 0) || (endPosition < 0)) {
      return s;
    }
    String word = s.substring(startPosition, endPosition);
    String wrappedWord = firstValue + word + secondValue;
    String updatedString = s.replaceRange(startPosition, endPosition, wrappedWord);
    return updatedString;
  }

  static String getMaskedPhoneNumber(String phoneNumber) {
    if(AppString.isStringEmpty(phoneNumber)) {
      return "*********";
    }
    int phoneNumberLength = phoneNumber.length;
    int lastXNumbers = min(phoneNumberLength, 4);
    int starsCount = (phoneNumberLength - lastXNumbers);
    String replacement = "*" * starsCount;
    String maskedPhoneNumber = phoneNumber.replaceRange(0, starsCount, replacement);
    return maskedPhoneNumber;
  }

  static String capitalize(String value) {
    if (value == null) {
      return null;
    }
    else if (value.length == 0) {
      return '';
    }
    else if (value.length == 1) {
      return value[0].toUpperCase();
    }
    else {
      return "${value[0].toUpperCase()}${value.substring(1).toLowerCase()}";
    }
  }

  static String stripHtmlTags(String value) {
    return value?.replaceAll(RegExp(r'<[^>]*>'), '')?.replaceAll(RegExp(r'&[^;]+;'), ' ');
  }

  static String fullName(List<String> names) {
    String fullName;
    if (names != null) {
      for (String name in names) {
        if ((name != null) && (0 < name.length)) {
          if (fullName == null) {
            fullName = '$name';
          }
          else {
            fullName += ' $name';
          }
        }
      }
    }
    return fullName;
  }

  /// US Phone validation  https://github.com/rokwire/illinois-app/issues/47

  static const String _usPhonePattern1 = "^[2-9][0-9]{9}\$";          // Valid:   23456789120
  static const String _usPhonePattern2 = "^[1][2-9][0-9]{9}\$";       // Valid:  123456789120
  static const String _usPhonePattern3 = "^\\\+[1][2-9][0-9]{9}\$";   // Valid: +123456789120

  static const String _phonePattern = "^((\\+?\\d{1,3})?[\\(\\- ]?\\d{3,5}[\\)\\- ]?)?(\\d[.\\- ]?\\d)+\$";   // Valid: +123456789120


  static bool isUsPhoneValid(String phone){
    if(isStringNotEmpty(phone)){
      return (phone.length == 10 && RegExp(_usPhonePattern1).hasMatch(phone))
          || (phone.length == 11 && RegExp(_usPhonePattern2).hasMatch(phone))
          || (phone.length == 12 && RegExp(_usPhonePattern3).hasMatch(phone));
    }
    return false;
  }

  static bool isUsPhoneNotValid(String phone){
    return !isUsPhoneValid(phone);
  }

  static bool isPhoneValid(String phone) {
    return isStringNotEmpty(phone) && RegExp(_phonePattern).hasMatch(phone);
  }

  /// US Phone construction

  static String constructUsPhone(String phone){
    if(isUsPhoneValid(phone)){
      if(phone.length == 10 && RegExp(_usPhonePattern1).hasMatch(phone)){
        return "+1$phone";
      }
      else if (phone.length == 11 && RegExp(_usPhonePattern2).hasMatch(phone)){
        return "+$phone";
      }
      else if (phone.length == 12 && RegExp(_usPhonePattern3).hasMatch(phone)){
        return phone;
      }
    }
    return null;
  }

  /// Email validation  https://github.com/rokwire/illinois-app/issues/47

  static const String _emailPattern = "^[a-zA-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*\$" ;

  static bool isEmailValid(String email){
    return isStringNotEmpty(email) && RegExp(_emailPattern).hasMatch(email);
  }
}

class AppCollection {
  static bool isCollectionNotEmpty(Iterable<Object> collection) {
    return collection != null && collection.isNotEmpty;
  }

  static bool isCollectionEmpty(Iterable<Object> collection) {
    return !isCollectionNotEmpty(collection);
  }
}

class AppColor {
  static Color fromHex(String strValue) {
    if (strValue != null) {
      if (strValue.startsWith("#")) {
        strValue = strValue.substring(1);
      }
      
      int intValue = int.tryParse(strValue, radix: 16);
      if (intValue != null) {
        if (strValue.length <= 6) {
          intValue += 0xFF000000;
        }
        
        return Color(intValue);
      }
    }
    return null;
  }

  static String toHex(Color value) {
    if (value == null) {
      return null;
    }
    else if (value.alpha < 0xFF) {
      return "#${value.alpha.toRadixString(16)}${value.red.toRadixString(16)}${value.green.toRadixString(16)}${value.blue.toRadixString(16)}";
    }
    else {
      return "#${value.red.toRadixString(16)}${value.green.toRadixString(16)}${value.blue.toRadixString(16)}";
    }
  }
}

class AppVersion {

  static int compareVersions(String versionString1, String versionString2) {
    List<String> versionList1 = (versionString1 is String) ? versionString1.split('.') : [];
    List<String> versionList2 = (versionString2 is String) ? versionString2.split('.') : [];
    int minLen = min(versionList1.length, versionList2.length);
    for (int index = 0; index < minLen; index++) {
      String s1 = versionList1[index], s2 = versionList2[index];
      int n1 = int.tryParse(s1), n2 = int.tryParse(s2);
      int result = ((n1 != null) && (n2 != null)) ? n1.compareTo(n2) : s1.compareTo(s2);
      if (result != 0) {
        return result;
      }
    }
    if (versionList1.length < versionList2.length) {
      return -1;
    }
    else if (versionList1.length > versionList2.length) {
      return 1;
    }
    else {
      return 0;
    }
  }

  static bool matchVersions(String versionString1, String versionString2) {
    List<String> versionList1 = (versionString1 is String) ? versionString1.split('.') : [];
    List<String> versionList2 = (versionString2 is String) ? versionString2.split('.') : [];
    int minLen = min(versionList1.length, versionList2.length);
    for (int index = 0; index < minLen; index++) {
      String s1 = versionList1[index], s2 = versionList2[index];
      int n1 = int.tryParse(s1), n2 = int.tryParse(s2);
      int result = ((n1 != null) && (n2 != null)) ? n1.compareTo(n2) : s1.compareTo(s2);
      if (result != 0) {
        return false;
      }
    }
    return true;
  }

  static String majorVersion(String versionString, int versionsLength) {
    if (versionString is String) {
      List<String> versionList = versionString.split('.');
      if (versionsLength < versionList.length) {
        versionList = versionList.sublist(0, versionsLength);
      }
      return versionList.join('.');
    }
    return null;
  }
}

class AppUrl {
  
  static String getScheme(String url) {
    try {
      Uri uri = (url != null) ? Uri.parse(url) : null;
      return (uri != null) ? uri.scheme : null;
    } catch(e) {}
    return null;
  }

  static String getExt(String url) {
    try {
      Uri uri = (url != null) ? Uri.parse(url) : null;
      String path = (uri != null) ? uri.path : null;
      return (path != null) ? Path.extension(path) : null;
    } catch(e) {}
    return null;
  }

  static bool isPdf(String url) {
    return (getExt(url) == '.pdf');
  }

  static bool isWebScheme(String url) {
    String scheme = getScheme(url);
    return (scheme == 'http') || (scheme == 'https');
  }

  static bool launchInternal(String url) {
    return AppUrl.isWebScheme(url) && !(Platform.isAndroid && AppUrl.isPdf(url));
  }

  static String getGameDayGuideUrl(String sportKey) {
    if (sportKey == "football") {
      return Config().gameDayFootballUrl;
    } else if ((sportKey == "mbball") || (sportKey == "wbball")) {
      return Config().gameDayBasketballUrl;
    } else if ((sportKey == "mten") || (sportKey == "wten")) {
      return Config().gameDayTennisUrl;
    } else if (sportKey == "wvball") {
      return Config().gameDayVolleyballUrl;
    } else if (sportKey == "softball") {
      return Config().gameDaySoftballUrl;
    } else if (sportKey == "wswim") {
      return Config().gameDaySwimDiveUrl;
    } else if ((sportKey == "mcross") || (sportKey == "wcross")) {
      return Config().gameDayCrossCountryUrl;
    } else if (sportKey == "baseball") {
      return Config().gameDayBaseballUrl;
    } else if ((sportKey == "mgym") || (sportKey == "wgym")) {
      return Config().gameDayGymnasticsUrl;
    } else if (sportKey == "wrestling") {
      return Config().gameDayWrestlingUrl;
    } else if (sportKey == "wsoc") {
      return Config().gameDaySoccerUrl;
    } else if ((sportKey == "mtrack") || (sportKey == "wtrack")) {
      return Config().gameDayTrackFieldUrl;
    } else {
      return Config().gameDayAllUrl;
    }
  }

  static String getDeepLinkRedirectUrl(String deepLink) {
    Uri assetsUri = AppString.isStringNotEmpty(Config().assetsUrl) ? Uri.tryParse(Config().assetsUrl) : null;
    String redirectUrl = assetsUri != null ? "${assetsUri.scheme}://${assetsUri.host}/html/redirect.html" : null;
    return AppString.isStringNotEmpty(redirectUrl) ? "$redirectUrl?target=$deepLink" : deepLink;
  }
}

class AppLocation {
  static final double defaultLocationLat = 40.096230;
  static final double defaultLocationLng = -88.235899;
  static final int defaultLocationRadiusInMeters = 1000;

  static double distance(double lat1, double lon1, double lat2, double lon2) {
    double theta = lon1 - lon2;
    double dist = sin(deg2rad(lat1)) 
                    * sin(deg2rad(lat2))
                    + cos(deg2rad(lat1))
                    * cos(deg2rad(lat2))
                    * cos(deg2rad(theta));
    dist = acos(dist);
    dist = rad2deg(dist);
    dist = dist * 60 * 1.1515;
    return (dist);
  }

  static double deg2rad(double deg) {
      return (deg * pi / 180.0);
  }

  static double rad2deg(double rad) {
      return (rad * 180.0 / pi);
  }  
}

class AppJson {

  static List<dynamic> encodeList(List items) {
    List<dynamic> result =  [];
    if (items != null && items.isNotEmpty) {
      items.forEach((item) {
        result.add(item.toJson());
      });
    }

    return result;
  }

  static List<String> castToStringList(List<dynamic> items) {
    if (items == null)
      return null;

    List<String> result =  [];
    if (items != null && items.isNotEmpty) {
      items.forEach((item) {
        result.add(item is String ? item : item.toString());
      });
    }

    return result;
  }

  static String encode(dynamic value, { bool prettify }) {
    String result;
    if (value != null) {
      try {
        if (prettify == true) {
          result = JsonEncoder.withIndent("  ").convert(value);
        }
        else {
          result = json.encode(value);
        }
      } catch (e) {
        Log.e(e?.toString());
      }
    }
    return result;
  }

  // TBD: Use everywhere decodeMap or decodeList to guard type cast
  static dynamic decode(String jsonString) {
    dynamic jsonContent;
    if (AppString.isStringNotEmpty(jsonString)) {
      try {
        jsonContent = json.decode(jsonString);
      } catch (e) {
        Log.e(e?.toString());
      }
    }
    return jsonContent;
  }

  static List<dynamic> decodeList(String jsonString) {
    try {
      return (decode(jsonString) as List)?.cast<dynamic>();
    } catch (e) {
      print(e?.toString());
      return null;
    }
  }

  static Map<String, dynamic> decodeMap(String jsonString) {
    try {
      return (decode(jsonString) as Map)?.cast<String, dynamic>();
    } catch (e) {
      print(e?.toString());
      return null;
    }
  }

  static String stringValue(dynamic value) {
    if (value is String) {
      return value;
    }
    else if (value != null) {
      try { return value.toString(); }
      catch(e) { print(e?.toString()); }
    }
    return null;
  }

  static int intValue(dynamic value) {
    return (value is int) ? value : null;
  }

  static bool boolValue(dynamic value) {
    return (value is bool) ? value : null;
  }

  static double doubleValue(dynamic value) {
    if (value is double) {
      return value;
    }
    else if (value is int) {
      return value.toDouble();
    }
    else if (value is String) {
      return double.tryParse(value);
    }
    else {
      return null;
    }
  }

  static Map<String, dynamic> mapValue(dynamic value) {
    try { return (value is Map) ? value.cast<String, dynamic>() : null; }
    catch(e) { print(e?.toString()); }
    return null;
  }

  static List<dynamic> listValue(dynamic value) {
    try { return (value is List) ? value.cast<dynamic>() : null; }
    catch(e) { print(e?.toString()); }
    return null;
  }

  static List<String> stringListValue(dynamic value) {
    List<String> result;
    if (value is List) {
      result = <String>[];
      for (dynamic entry in value) {
        result.add(entry?.toString());
      }
    }
    return result;
  }

  static Set<String> stringSetValue(dynamic value) {
    Set<String> result;
    if (value is List) {
      result = Set<String>();
      for (dynamic entry in value) {
        result.add(entry?.toString());
      }
    }
    return result;
  }
  
  static List<String> listStringsValue(dynamic value) {
    try { return (value is List) ? value.cast<String>() : null; }
    catch(e) { print(e?.toString()); }
    return null;
  }

  static Set<String> setStringsValue(dynamic value) {
    try { return (value is List) ? Set.from(value.cast<String>()) : null; }
    catch(e) { print(e?.toString()); }
    return null;
  }
}

class AppToast {
  static void show(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
      timeInSecForIosWeb: 3,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Styles().colors.blackTransparent06,
    );
  }
}

class AppAlert {
  static Future<bool> showDialogResult(
      BuildContext builderContext, String message) async {
    if(builderContext != null) {
      bool alertDismissed = await showDialog(
        context: builderContext,
        builder: (context) {
          return AlertDialog(
            content: Text(message),
            actions: <Widget>[
              TextButton(
                  child: Text(Localization().getStringEx("dialog.ok.title", "OK")),
                  onPressed: () {
                    Analytics.instance.logAlert(text: message, selection: "Ok");
                    Navigator.pop(context, true);
                  }
              ) //return dismissed 'true'
            ],
          );
        },
      );
      return alertDismissed;
    }
    return true; // dismissed
  }

  static Future<bool> showCustomDialog(
    {BuildContext context, Widget contentWidget, List<Widget> actions, EdgeInsets contentPadding = const EdgeInsets.all(18), }) async {
    bool alertDismissed = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(content: contentWidget, actions: actions,contentPadding: contentPadding,);
      },
    );
    return alertDismissed;
  }

  static Future<bool> showOfflineMessage(BuildContext context, String message) async {
    return showDialog(context: context, builder: (context) {
      return AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(Localization().getStringEx("app.offline.message.title", "You appear to be offline"), style: TextStyle(fontSize: 18),),
          Container(height:16),
          Text(message, textAlign: TextAlign.center,),
        ],),
        actions: <Widget>[
          TextButton(
              child: Text(Localization().getStringEx("dialog.ok.title", "OK")),
              onPressed: (){
                Analytics.instance.logAlert(text: message, selection: "OK");
                  Navigator.pop(context, true);
              }
          ) //return dismissed 'true'
        ],
      );
    },);

  }
}

class AppMapPathKey {
  static dynamic entry(Map<String, dynamic> map, dynamic key) {
    if ((map != null) && (key != null)) {
      if (key is String) {
        return _pathKeyEntry(map, key);
      }
      else if (key is List) {
        return _listKeyEntry(map, key);
      }
    }
    return null;
  }
  
  static dynamic _pathKeyEntry(Map<String, dynamic> map, String key) {
    String field;
    dynamic entry;
    int position, start = 0;
    Map<String, dynamic> source = map;

    while (0 <= (position = key.indexOf('.', start))) {
      field = key.substring(start, position);
      entry = source[field];
      if ((entry != null) && (entry is Map)) {
        source = entry;
        start = position + 1;
      }
      else {
        break;
      }
    }

    if (0 < start) {
      field = key.substring(start);
      return source[field];
    }
    else {
      return source[key];
    }
  }

  static dynamic _listKeyEntry(Map<String, dynamic> map, List keys) {
    dynamic entry;
    Map<String, dynamic> source = map;
    for (dynamic key in keys) {
      if (source == null) {
        return null;
      }

      entry = source[key];

      if (entry != null) {
        source = (entry is Map) ? entry : null;
      }
      else {
        return null;
      }
    }

    return source ?? entry;
  }

}

class AppSemantics {
    static void announceCheckBoxStateChange(BuildContext context, bool checked, String name){
      String message = (AppString.isStringNotEmpty(name)?name+", " :"")+
          (checked ?
            Localization().getStringEx("toggle_button.status.checked", "checked",) :
            Localization().getStringEx("toggle_button.status.unchecked", "unchecked")); // !toggled because we announce before it got changed
      announceMessage(context, message);
    }

    static Semantics buildCheckBoxSemantics({Widget child, String title, bool selected = false, double sortOrder}){
      return Semantics(label: title, button: true ,excludeSemantics: true, sortKey: sortOrder!=null?OrdinalSortKey(sortOrder) : null,
      value: (selected?Localization().getStringEx("toggle_button.status.checked", "checked",) :
      Localization().getStringEx("toggle_button.status.unchecked", "unchecked")) +
      ", "+ Localization().getStringEx("toggle_button.status.checkbox", "checkbox"),
      child: child );
    }

    static void announceMessage(BuildContext context, String message){
        if(context != null){
          context.findRenderObject().sendSemanticsEvent(AnnounceSemanticsEvent(message,TextDirection.ltr));
        }
    }
}

class AppSort {
  static int compareIntegers(int v1, int v2) {
    if (v1 != null) {
      if (v2 != null) {
        return v1.compareTo(v2);
      }
      else {
        return -1;
      }
    }
    else if (v2 != null) {
      return 1;
    }
    else {
      return 0;
    }
  }

  static int compareDateTimes(DateTime v1, DateTime v2) {
    if (v1 != null) {
      if (v2 != null) {
        return v1.compareTo(v2);
      }
      else {
        return -1;
      }
    }
    else if (v2 != null) {
      return 1;
    }
    else {
      return 0;
    }
  }
}

class AppDeviceOrientation {
  
  static DeviceOrientation fromStr(String value) {
    switch (value) {
      case 'portraitUp': return DeviceOrientation.portraitUp;
      case 'portraitDown': return DeviceOrientation.portraitDown;
      case 'landscapeLeft': return DeviceOrientation.landscapeLeft;
      case 'landscapeRight': return DeviceOrientation.landscapeRight;
    }
    return null;
  }

  static String toStr(DeviceOrientation value) {
      switch(value) {
        case DeviceOrientation.portraitUp: return "portraitUp";
        case DeviceOrientation.portraitDown: return "portraitDown";
        case DeviceOrientation.landscapeLeft: return "landscapeLeft";
        case DeviceOrientation.landscapeRight: return "landscapeRight";
      }
      return null;
  }

  static List<DeviceOrientation> fromStrList(List<dynamic> stringsList) {
    
    List<DeviceOrientation> orientationsList;
    if (stringsList != null) {
      orientationsList = [];
      for (dynamic string in stringsList) {
        if (string is String) {
          DeviceOrientation orientation = fromStr(string);
          if (orientation != null) {
            orientationsList.add(orientation);
          }
        }
      }
    }
    return orientationsList;
  }

  static List<String> toStrList(List<DeviceOrientation> orientationsList) {
    
    List<String> stringsList;
    if (orientationsList != null) {
      stringsList = [];
      for (DeviceOrientation orientation in orientationsList) {
        String orientationString = toStr(orientation);
        if (orientationString != null) {
          stringsList.add(orientationString);
        }
      }
    }
    return stringsList;
  }

}

class AppGeometry {

  static Size scaleSizeToFit(Size size, Size boundsSize) {
    double fitW = boundsSize.width;
    double fitH = boundsSize.height;
    double ratioW = (0.0 < boundsSize.width) ? (size.width / boundsSize.width) : double.maxFinite;
    double ratioH = (0.0 < boundsSize.height) ? (size.height / boundsSize.height) : double.maxFinite;
    if(ratioW < ratioH)
      fitW = (0.0 < size.height) ? (size.width * boundsSize.height / size.height) : boundsSize.width;
    else if(ratioH < ratioW)
      fitH = (0.0 < size.width) ? (size.height * boundsSize.width / size.width) : boundsSize.height;
    return Size(fitW, fitH);
  }

  static Size scaleSizeToFill(Size size, Size boundsSize) {
    double fitW = boundsSize.width;
    double fitH = boundsSize.height;
    double ratioW = (0.0 < boundsSize.width) ? (size.width / boundsSize.width) : double.maxFinite;
    double ratioH = (0.0 < boundsSize.height) ? (size.height / boundsSize.height) : double.maxFinite;
    if(ratioW < ratioH)
  		fitH = (0.0 < size.width) ? (size.height * boundsSize.width / size.width) : boundsSize.height;
    else if(ratioH < ratioW)
  		fitW = (0.0 < size.height) ? (size.width * boundsSize.height / size.height) : boundsSize.width;
    return Size(fitW, fitH);
  }
}

class AppBoolExpr {
  
  static bool eval(dynamic expr, bool Function(String) evalArg) {
    
    if (expr is String) {

      if (expr == 'TRUE') {
        return true;
      }
      if (expr == 'FALSE') {
        return false;
      }

      bool argValue = (evalArg != null) ? evalArg(expr) : null;
      return argValue ?? true; // allow everything that is not defined or we do not understand
    }
    
    else if (expr is List) {
      
      if (expr.length == 1) {
        return eval(expr[0], evalArg);
      }
      
      if (expr.length == 2) {
        dynamic operation = expr[0];
        dynamic argument = expr[1];
        if (operation is String) {
          if (operation == 'NOT') {
            return !eval(argument, evalArg);
          }
        }
      }

      if (expr.length > 2) {
        bool result = eval(expr[0], evalArg);
        for (int index = 1; (index + 1) < expr.length; index += 2) {
          dynamic operation = expr[index];
          dynamic argument = expr[index + 1];
          if (operation is String) {
            if (operation == 'AND') {
              result = result && eval(argument, evalArg);
            }
            else if (operation == 'OR') {
              result = result || eval(argument, evalArg);
            }
          }
        }
        return result;
      }
    }
    
    return true; // allow everything that is not defined or we do not understand
  }
}