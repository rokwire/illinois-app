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

import 'package:flutter/material.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessToDoItem {
  static final String _dateTimeFormat = 'yyyy-MM-ddTHH:mm:sssZ';

  final String? id;
  final String? name;
  final WellnessToDoCategory? category;
  DateTime? dueDateTimeUtc;
  final bool? hasDueTime;
  DateTime? endDateTimeUtc;
  WellnessToDoReminderType? reminderType;
  DateTime? reminderDateTimeUtc;
  final List<String>? workDays;
  final String? location;
  final String? description;
  bool isCompleted;
  final String? recurrenceType;
  final String? recurrenceId;

  WellnessToDoItem(
      {this.id,
      this.name,
      this.category,
      this.dueDateTimeUtc,
      this.hasDueTime,
      this.endDateTimeUtc,
      this.reminderType,
      this.reminderDateTimeUtc,
      this.workDays,
      this.location,
      this.description,
      this.isCompleted = false,
      this.recurrenceType,
      this.recurrenceId});

  static WellnessToDoItem? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return WellnessToDoItem(
        id: JsonUtils.stringValue(json['id']),
        name: JsonUtils.stringValue(json['title']),
        category: WellnessToDoCategory.fromJson(JsonUtils.mapValue(json['category'])),
        dueDateTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['due_date_time']), format: _dateTimeFormat, isUtc: true),
        hasDueTime: JsonUtils.boolValue(json['has_due_time']),
        endDateTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['end_date_time']), format: _dateTimeFormat, isUtc: true),
        reminderType: reminderTypeFromString(JsonUtils.stringValue(json['reminder_type'])),
        reminderDateTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['reminder_date_time']), format: _dateTimeFormat, isUtc: true),
        workDays: JsonUtils.listStringsValue(json['work_days']),
        location: JsonUtils.stringValue(json['location']),
        description: JsonUtils.stringValue(json['description']),
        recurrenceType: JsonUtils.stringValue(json['recurrence_type']),
        recurrenceId: JsonUtils.stringValue(json['recurrence_id']),
        isCompleted: JsonUtils.boolValue(json['completed']) ?? false);

  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'id': id,
      'title': name,
      'category': category?.toJson(),
      'due_date_time': DateTimeUtils.utcDateTimeToString(dueDateTimeUtc),
      'has_due_time': hasDueTime,
      'end_date_time': DateTimeUtils.utcDateTimeToString(endDateTimeUtc),
      'reminder_type': reminderTypeToKeyString(reminderType),
      'reminder_date_time': DateTimeUtils.utcDateTimeToString(reminderDateTimeUtc),
      'work_days': workDays,
      'location': location,
      'description': description,
      'completed': isCompleted,
      'recurrence_type' : recurrenceType,
      'recurrence_id' : recurrenceId,
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  DateTime? get dueDateTime {
    return AppDateTime().getDeviceTimeFromUtcTime(dueDateTimeUtc);
  }

  String? get displayDueDate {
    if (dueDateTime == null) {
      return null;
    }
    return AppDateTime().formatDateTime(dueDateTime, format: 'EEEE, MM/dd', ignoreTimeZone: true);
  }

  DateTime? get reminderDateTime {
    return AppDateTime().getDeviceTimeFromUtcTime(reminderDateTimeUtc);
  }

  Color get color {
    return category?.color ?? Styles().colors.fillColorPrimary;
  }

  static List<WellnessToDoItem>? listFromJson(List<dynamic>? jsonList) {
    List<WellnessToDoItem>? items;
    if (jsonList != null) {
      items = <WellnessToDoItem>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, WellnessToDoItem.fromJson(jsonEntry));
      }
    }
    return items;
  }

  static WellnessToDoReminderType? reminderTypeFromString(String? typeValue) {
    switch (typeValue) {
      case 'night_before':
        return WellnessToDoReminderType.night_before;
      case 'morning_of':
        return WellnessToDoReminderType.morning_of;
      case 'specific_time':
        return WellnessToDoReminderType.specific_time;
      case 'none':
        return WellnessToDoReminderType.none;
      default:
        return null;
    }
  }

  static String? reminderTypeToKeyString(WellnessToDoReminderType? type) {
    switch (type) {
      case WellnessToDoReminderType.night_before:
        return 'night_before';
      case WellnessToDoReminderType.morning_of:
        return 'morning_of';
      case WellnessToDoReminderType.specific_time:
        return 'specific_time';
      case WellnessToDoReminderType.none:
        return 'none';
      default:
        return null;
    }
  }

  static String? reminderTypeToDisplayString(WellnessToDoReminderType? type) {
    switch (type) {
      case WellnessToDoReminderType.none:
        return Localization().getStringEx('model.wellness.todo.category.reminder.type.none.label', 'None');
      case WellnessToDoReminderType.morning_of:
        return Localization().getStringEx('model.wellness.todo.category.reminder.type.morning_of.label', 'Morning Of (8:00 AM)');
      case WellnessToDoReminderType.night_before:
        return Localization().getStringEx('model.wellness.todo.category.reminder.type.night_before.label', 'Night Before (9:00 PM)');
      case WellnessToDoReminderType.specific_time:
        return Localization().getStringEx('model.wellness.todo.category.reminder.type.specific_time.label', 'Specific Time');
      default:
        return null;
    }
  }
}

enum WellnessToDoReminderType { morning_of, night_before, specific_time, none }

class WellnessToDoCategory {
  final String? id;
  String? name;
  String? colorHex;

  WellnessToDoCategory({this.id, this.name, this.colorHex});

  static WellnessToDoCategory? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return WellnessToDoCategory(
        id: JsonUtils.stringValue(json['id']),
        name: JsonUtils.stringValue(json['name']),
        colorHex: JsonUtils.stringValue(json['color']));
  }

  Color get color {
    Color? color;
    // Handle already created categories with transparent color - transparent color is not a valid color.
    if ((colorHex != null) && (colorHex != '#00000000')) {
      color = UiColors.fromHex(colorHex);
    }
    return color ?? Styles().colors.fillColorPrimary;
  }

  static List<WellnessToDoCategory>? listFromJson(List<dynamic>? jsonList) {
    List<WellnessToDoCategory>? categories;
    if (jsonList != null) {
      categories = <WellnessToDoCategory>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(categories, WellnessToDoCategory.fromJson(jsonEntry));
      }
    }
    return categories;
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': colorHex};
  }
}
