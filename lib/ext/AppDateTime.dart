/*
 * Copyright 2026 Board of Trustees of the University of Illinois.
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

import 'package:flutter/cupertino.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/utils/datetime_utils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart' as timezone;

extension AppDateTimeExt on AppDateTime {

  String? formatDateTime(DateTime? dateTime,
      {String? format, String? locale, bool? ignoreTimeZone = false, bool showTzSuffix = false}) {
    if (dateTime == null) {
      return null;
    }
    String? formattedDateTime;
    try {
      if (StringUtils.isEmpty(format)) {
        format = DateTimeUtils.iso8601DateTimeFormat;
      }
      DateFormat dateFormat = DateFormat(format, locale);
      if (ignoreTimeZone!) {
        formattedDateTime = dateFormat.format(dateTime);
      } else if (useUniversityTimeZone) {
        timezone.Location? uniLocation = universityLocation;
        timezone.TZDateTime? tzDateTime = (uniLocation != null) ? timezone.TZDateTime.from(dateTime, uniLocation) : null;
        formattedDateTime = (tzDateTime != null) ? dateFormat.format(tzDateTime) : null;
      } else {
        DateTime? dt = (dateTime.isUtc) ? getDeviceTimeFromUtc(dateTime) : dateTime;
        formattedDateTime = (dt != null) ? dateFormat.format(dt) : null;
      }
      if (showTzSuffix && (formattedDateTime != null) && (timeZoneSuffix != null)) {
        formattedDateTime = '$formattedDateTime $timeZoneSuffix';
      }
    }
    catch (e) {
      debugPrint(e.toString());
    }
    return formattedDateTime;
  }

  String formatDisplayDateTime(DateTime dateTimeUtc, {String? format, bool allDay = false, bool includeAtSuffix = false}) {
    DateTime zonedDateTime = getZonedTimeFromUtc(dateTimeUtc: dateTimeUtc)!;
    if (format != null) {
      return formatDateTime(zonedDateTime, format: format, ignoreTimeZone: false, showTzSuffix: true) ?? '';
    }

    String? timePrefix = AppRelativeTime.relativeDaySinceDate(dateTime: zonedDateTime, location: zonedLocation, allDay: allDay, includeAtSuffix: includeAtSuffix);
    String? timeSuffix = allDay ? '' : DateTimeUtils.utcTimeToString(dateTimeUtc, zonedLocation, timeZoneSuffix: timeZoneSuffix);
    return '$timePrefix $timeSuffix';
  }

}