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

class ToDoItem {
  static final String _dateTimeFormat = 'yyyy-MM-ddTHH:mm:sssZ';

  final String? id;
  final String? name;
  final ToDoCategory? category;
  final DateTime? dueDateTimeUtc;
  final bool? hasDueTime;
  ToDoReminderType? reminderType;
  DateTime? reminderDateTimeUtc;
  final List<String>? workDays;
  final String? location;
  final String? description;
  bool isCompleted;

  ToDoItem(
      {this.id,
      this.name,
      this.category,
      this.dueDateTimeUtc,
      this.hasDueTime,
      this.reminderType,
      this.reminderDateTimeUtc,
      this.workDays,
      this.location,
      this.description,
      this.isCompleted = false});

  static ToDoItem? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ToDoItem(
        id: JsonUtils.stringValue(json['id']),
        name: JsonUtils.stringValue(json['title']),
        category: ToDoCategory.fromJson(JsonUtils.mapValue(json['category'])),
        dueDateTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['due_date_time']), format: _dateTimeFormat, isUtc: true),
        hasDueTime: JsonUtils.boolValue(json['has_due_time']),
        reminderType: reminderTypeFromString(JsonUtils.stringValue(json['reminder_type'])),
        reminderDateTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['reminder_date_time']), format: _dateTimeFormat, isUtc: true),
        workDays: JsonUtils.listStringsValue(json['work_days']),
        location: JsonUtils.stringValue(json['location']),
        description: JsonUtils.stringValue(json['description']),
        isCompleted: JsonUtils.boolValue(json['completed']) ?? false);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'id': id,
      'title': name,
      'category': category?.toJson(),
      'due_date_time': DateTimeUtils.utcDateTimeToString(dueDateTimeUtc),
      'has_due_time': hasDueTime,
      'reminder_type': reminderTypeToKeyString(reminderType),
      'reminder_date_time': DateTimeUtils.utcDateTimeToString(reminderDateTimeUtc),
      'work_days': workDays,
      'location': location,
      'description': description,
      'completed': isCompleted
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
    return category?.color ?? Styles().colors!.fillColorPrimary!;
  }

  static List<ToDoItem>? listFromJson(List<dynamic>? jsonList) {
    List<ToDoItem>? items;
    if (jsonList != null) {
      items = <ToDoItem>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, ToDoItem.fromJson(jsonEntry));
      }
    }
    return items;
  }

  static ToDoReminderType? reminderTypeFromString(String? typeValue) {
    switch (typeValue) {
      case 'night_before':
        return ToDoReminderType.night_before;
      case 'morning_of':
        return ToDoReminderType.morning_of;
      case 'specific_time':
        return ToDoReminderType.specific_time;
      case 'none':
        return ToDoReminderType.none;
      default:
        return null;
    }
  }

  static String? reminderTypeToKeyString(ToDoReminderType? type) {
    switch (type) {
      case ToDoReminderType.night_before:
        return 'night_before';
      case ToDoReminderType.morning_of:
        return 'morning_of';
      case ToDoReminderType.specific_time:
        return 'specific_time';
      case ToDoReminderType.none:
        return 'none';
      default:
        return null;
    }
  }

  static String? reminderTypeToDisplayString(ToDoReminderType? type) {
    switch (type) {
      case ToDoReminderType.none:
        return Localization().getStringEx('model.wellness.todo.category.reminder.type.none.label', 'None');
      case ToDoReminderType.morning_of:
        return Localization().getStringEx('model.wellness.todo.category.reminder.type.morning_of.label', 'Morning Of');
      case ToDoReminderType.night_before:
        return Localization().getStringEx('model.wellness.todo.category.reminder.type.night_before.label', 'Night Before');
      case ToDoReminderType.specific_time:
        return Localization().getStringEx('model.wellness.todo.category.reminder.type.specific_time.label', 'Specific Time');
      default:
        return null;
    }
  }
}

enum ToDoReminderType { morning_of, night_before, specific_time, none }

class ToDoCategory {
  final String? id;
  String? name;
  String? colorHex;

  ToDoCategory({this.id, this.name, this.colorHex});

  static ToDoCategory? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ToDoCategory(
        id: JsonUtils.stringValue(json['id']),
        name: JsonUtils.stringValue(json['name']),
        colorHex: JsonUtils.stringValue(json['color']));
  }

  Color get color {
    return UiColors.fromHex(colorHex) ?? Styles().colors!.fillColorPrimary!;
  }

  static List<ToDoCategory>? listFromJson(List<dynamic>? jsonList) {
    List<ToDoCategory>? categories;
    if (jsonList != null) {
      categories = <ToDoCategory>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(categories, ToDoCategory.fromJson(jsonEntry));
      }
    }
    return categories;
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': colorHex};
  }
}
