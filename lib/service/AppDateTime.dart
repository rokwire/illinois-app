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


import 'package:flutter/services.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as timezone;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class AppDateTime with Service {
  static final AppDateTime _instance = new AppDateTime._internal();

  static final iso8601DateTimeFormat = 'yyyy-MM-ddTHH:mm:ss';
  static final eventsServerCreateDateTimeFormat =  'yyyy/MM/ddTHH:mm:ss';
  static final scheduleServerQueryDateTimeFormat = 'MM/dd/yyyy';
  static final serverResponseDateTimeFormat = 'E, dd MMM yyyy HH:mm:ss v';
  static final gameResponseDateTimeFormat = 'yyyy-MM-ddTHH:mm:ssZ';
  static final gameResponseDateTimeFormat2 = 'MM/dd/yyyy HH:mm:ss a';
  static final illiniCashTransactionHistoryDateFormat = 'MM-dd-yyyy';
  static final eventFilterDisplayDateFormat = 'MM/dd';
  static final voterDateFormat = "yyyy/MM/dd";
  static final parkingEventDateFormat = "yyyy-MM-ddTHH:mm:ssZ";
  static final groupPostDateTimeFormat = "MMM dd, HH:mm a";

  factory AppDateTime() {
    return _instance;
  }

  AppDateTime._internal();

  timezone.Location _universityLocation;
  String _localTimeZone;

  DateTime get now {
    DateTime now = Storage().offsetDate;
    return now != null ? now : DateTime.now();
  }


  @override
  Future<void> initService() async {
    _init();
  }

  _init() async {
    _loadDefaultData().then((rawData) {
      timezone.initializeDatabase(rawData);
      timezone.Location deviceLocation = timezone.getLocation(_localTimeZone);
      timezone.setLocalLocation(deviceLocation);
      _universityLocation = timezone.getLocation('America/Chicago');
    });
  }

  Future<List<int>> _loadDefaultData() async {
    _localTimeZone = await FlutterNativeTimezone.getLocalTimezone();
    var byteData = await rootBundle.load('assets/timezone2019a.tzf');
    return byteData.buffer.asUint8List();
  }

  DateTime dateTimeFromString(String dateTimeString, {String format, bool isUtc = false}) {
    if (AppString.isStringEmpty(dateTimeString)) {
      return null;
    }
    DateTime dateTime;
    try {
      dateTime = AppString.isStringNotEmpty(format) ?
        DateFormat(format).parse(dateTimeString, isUtc) :
        DateTime.tryParse(dateTimeString);
    }
    on Exception catch (e) {
      Log.e(e.toString());
    }
    return dateTime;
  }

  String utcDateTimeToString(DateTime dateTime, { String format  = 'yyyy-MM-ddTHH:mm:ss.SSS'  }) {
    return (dateTime != null) ? (DateFormat(format).format(dateTime.isUtc ? dateTime : dateTime.toUtc()) + 'Z') : null;
  }

  DateTime getUtcTimeFromDeviceTime(DateTime dateTime) {
    if (dateTime == null) {
      return null;
    }
    DateTime dtUtc = dateTime.toUtc();
    return dtUtc;
  }

  DateTime getDeviceTimeFromUtcTime(DateTime dateTimeUtc) {
    if (dateTimeUtc == null) {
      return null;
    }
    timezone.TZDateTime deviceDateTime = timezone.TZDateTime.from(dateTimeUtc, timezone.local);
    return deviceDateTime;
  }

  DateTime getUniLocalTimeFromUtcTime(DateTime dateTimeUtc) {
    if (dateTimeUtc == null) {
      return null;
    }
    timezone.TZDateTime tzDateTimeUni = timezone.TZDateTime.from(dateTimeUtc, _universityLocation);
    return tzDateTimeUni;
  }

  String formatUniLocalTimeFromUtcTime(DateTime dateTimeUtc, String format) {
    if(dateTimeUtc != null && format != null){
      DateTime uniTime = getUniLocalTimeFromUtcTime(dateTimeUtc);
      return DateFormat(format).format(uniTime);
    }
    return null;
  }

  String formatDateTime(DateTime dateTime,
      {String format, String locale, bool ignoreTimeZone = false, bool showTzSuffix = false}) {
    if (dateTime == null) {
      return null;
    }
    if (AppString.isStringEmpty(format)) {
      format = iso8601DateTimeFormat;
    }
    bool useDeviceLocalTimeZone = Storage().useDeviceLocalTimeZone;
    String formattedDateTime;
    DateFormat dateFormat = DateFormat(format, locale);
    if (ignoreTimeZone || useDeviceLocalTimeZone) {
      try { formattedDateTime = dateFormat.format(dateTime); }
      catch (e) { print(e?.toString()); }
    } else {
      timezone.TZDateTime tzDateTime = timezone.TZDateTime.from(
          dateTime, _universityLocation);
      try { formattedDateTime = dateFormat.format(tzDateTime); }
      catch(e) { print(e?.toString()); } 
    }
    if (showTzSuffix) {
      formattedDateTime += ' CT';
    }
    return formattedDateTime;
  }

  String getDisplayDateTime(DateTime dateTimeUtc, {bool allDay = false, bool considerSettingsDisplayTime = true}) {
    String timePrefix = getDisplayDay(dateTimeUtc: dateTimeUtc, allDay: allDay, considerSettingsDisplayTime: considerSettingsDisplayTime, includeAtSuffix: true);
    String timeSuffix = getDisplayTime(dateTimeUtc: dateTimeUtc, allDay: allDay, considerSettingsDisplayTime: considerSettingsDisplayTime);
    return '$timePrefix $timeSuffix';
  }

  String getDisplayDay({DateTime dateTimeUtc, bool allDay = false, bool considerSettingsDisplayTime = true, bool includeAtSuffix = false}) {
    String displayDay = '';
    if(dateTimeUtc != null) {
      bool useDeviceLocalTime = Storage().useDeviceLocalTimeZone;
      DateTime dateTimeToCompare = _getDateTimeToCompare(dateTimeUtc: dateTimeUtc, considerSettingsDisplayTime: considerSettingsDisplayTime);
      DateTime nowDevice = DateTime.now();
      DateTime nowUtc = nowDevice.toUtc();
      DateTime nowUniLocal = getUniLocalTimeFromUtcTime(nowUtc);
      DateTime nowToCompare = useDeviceLocalTime ? nowDevice : nowUniLocal;
      int calendarDaysDiff = dateTimeToCompare.day - nowToCompare.day;
      int timeDaysDiff = dateTimeToCompare.difference(nowToCompare).inDays;
      if ((calendarDaysDiff != 0) && (calendarDaysDiff > timeDaysDiff)) {
        timeDaysDiff += 1;
      }
      if (timeDaysDiff == 0) {
        displayDay = Localization().getStringEx('model.explore.time.today', 'Today');
        if (!allDay && includeAtSuffix) {
          displayDay += " ${Localization().getStringEx('model.explore.time.at', 'at')}";
        }
      }
      else if (timeDaysDiff == 1) {
        displayDay = Localization().getStringEx('model.explore.time.tomorrow', 'Tomorrow');
        if (!allDay && includeAtSuffix) {
          displayDay += " ${Localization().getStringEx('model.explore.time.at', 'at')}";
        }
      }
      else {
        displayDay = formatDateTime(dateTimeToCompare, format: "MMM dd", ignoreTimeZone: true, showTzSuffix: false);
      }
    }
    return displayDay;
  }

  String getDisplayTime({DateTime dateTimeUtc, bool allDay = false, bool considerSettingsDisplayTime = true}) {
    String timeToString = '';
    if (dateTimeUtc != null && !allDay) {
      bool useDeviceLocalTime = Storage().useDeviceLocalTimeZone;
      DateTime dateTimeToCompare = _getDateTimeToCompare(dateTimeUtc: dateTimeUtc, considerSettingsDisplayTime: considerSettingsDisplayTime);
      String format = (dateTimeToCompare.minute == 0) ? 'ha' : 'h:mma';
      timeToString = formatDateTime(dateTimeToCompare, format: format, ignoreTimeZone: true, showTzSuffix: !useDeviceLocalTime);
    }
    return timeToString;
  }

  String getDayGreeting() {
    int currentHour = DateTime.now().hour;
    if (currentHour > 7 && currentHour < 12) {
      return Localization().getStringEx("logic.date_time.greeting.morning", "Good morning");
    }
    else if (currentHour >= 12 && currentHour < 19) {
      return Localization().getStringEx("logic.date_time.greeting.afternoon", "Good afternoon");
    }
    else {
      return Localization().getStringEx("logic.date_time.greeting.evening", "Good evening");
    }
  }

  DateTime _getDateTimeToCompare({DateTime dateTimeUtc, bool considerSettingsDisplayTime = true}) {
    if (dateTimeUtc == null) {
      return null;
    }
    DateTime dateTimeToCompare;
    bool useDeviceLocalTime = Storage().useDeviceLocalTimeZone;
    //workaround for receiving incorrect date times from server for games: http://fightingillini.com/services/schedule_xml_2.aspx
    if (useDeviceLocalTime && considerSettingsDisplayTime) {
      dateTimeToCompare = getDeviceTimeFromUtcTime(dateTimeUtc);
    } else {
      dateTimeToCompare = getUniLocalTimeFromUtcTime(dateTimeUtc);
    }
    return dateTimeToCompare;
  }

  static int getWeekDayFromString(String weekDayName){
    switch (weekDayName){
      case "monday"   : return 1;
      case "tuesday"  : return 2;
      case "wednesday": return 3;
      case "thursday" : return 4;
      case "friday"   : return 5;
      case "saturday" : return 6;
      case "sunday"   : return 7;
      default: return 0;
    }
  }

  static String timeAgoSinceDate(DateTime date, {bool numericDates = true}) {
    final date2 = DateTime.now();
    final difference = date2.difference(date);

    if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays >= 1) {
      return (numericDates) ? '1 day ago' : 'Yesterday';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours >= 1) {
      return (numericDates) ? '1 hour ago' : 'An hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inMinutes >= 1) {
      return (numericDates) ? '1 minute ago' : 'A minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'Just now';
    }
  }

  static DateTime midnight(DateTime date) {
    return (date != null) ? DateTime(date.year, date.month, date.day) : null;
  }

  timezone.TZDateTime changeTimeZoneToDate(DateTime time, timezone.Location location){
    try{
     return timezone.TZDateTime(location,time.year,time.month,time.day, time.hour, time.minute);
    } catch(e){
      print(e);
    }
    return null;
  }

  DateTime copyDateTime(DateTime date){
    return DateTime(date.year, date.month, date.day, date.hour, date.minute, date.second);
  }

  DateTime localEndOfDay(DateTime date){
    if(date == null)
      return null;
    try{
      return timezone.TZDateTime(_universityLocation ,date.year,date.month,date.day,24);
    } catch(e){
      print(e);
    }
    return null;
  }

  static DateTime parseDateTime(String dateTimeString, {String format, bool isUtc = false}) {
    if (AppString.isStringNotEmpty(dateTimeString)) {
      if (AppString.isStringNotEmpty(format)) {
        try { return DateFormat(format).parse(dateTimeString, isUtc); }
        catch (e) { print(e?.toString()); }
      }
      else {
        return DateTime.tryParse(dateTimeString);
      }
    }
    return null;
  }
}