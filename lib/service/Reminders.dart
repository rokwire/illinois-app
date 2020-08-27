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

import 'package:illinois/service/Assets.dart';
import 'package:illinois/model/Reminder.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';

class Reminders with Service implements NotificationsListener {
  
  static const String notifyChanged  = "edu.illinois.rokwire.reminders.changed";

  static final Reminders _logic = Reminders._internal();
  static final int _showNextRemindersDaysCount = 14; //two weeks

  factory Reminders() {
    return _logic;
  }

  Reminders._internal();

  List<Reminder> _reminders;

  @override
  void createService() {
    NotificationService().subscribe(this, Assets.notifyChanged);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
  }

  @override
  Set<Service> get serviceDependsOn {
    return null;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Assets.notifyChanged) {
      _reminders = null;
      NotificationService().notify(notifyChanged, null);
    }
  }

  List<Reminder> getReminders() {
    if (_reminders == null) {
      _reminders = _buildReminders();
    }
    List<Reminder> visibleReminders = _getVisibleReminders();
    return visibleReminders;
  }

  List<Reminder> getAllReminders() {
    if (_reminders == null) {
      _reminders = _buildReminders();
    }
    return _reminders;
  }

  List<Reminder> getAllUpcomingReminders(){
    if (_reminders == null) {
      _reminders = _buildReminders();
    }

    return _reminders.where(
            (Reminder reminder){
              return _reminderIsUpcoming(reminder?.dateUtc, DateTime.now().toUtc());
            })?.toList();
  }

  List<Reminder> _buildReminders() {
    List<Reminder> reminders;
    List<dynamic> jsonList = Assets()['reminders.content'];
    if (jsonList != null) {
      reminders = new List();
      for (dynamic jsonEntry in jsonList) {
        Reminder reminder = Reminder.fromJson(jsonEntry);
        if (reminder != null) {
          reminders.add(reminder);
        }
      }
    }
    return reminders;
  }

  List<Reminder> _getVisibleReminders() {
    if (_reminders == null || _reminders.length == 0) {
      return null;
    }
    List<Reminder> visibleReminders = List();
    DateTime nowUtc = DateTime.now().toUtc();
    for (Reminder reminder in _reminders) {
      bool showReminder = _reminderVisible(reminder.dateUtc, nowUtc);
      if (showReminder) {
        visibleReminders.add(reminder);
      }
    }
    return visibleReminders;
  }

  bool _reminderVisible(DateTime reminderDate, DateTime dateToCompare) {
    return (reminderDate != null) &&
        reminderDate.isAfter(dateToCompare) &&
        reminderDate
            .difference(dateToCompare)
            .inDays <= _showNextRemindersDaysCount;
  }

  bool _reminderIsUpcoming(DateTime reminderDate, DateTime dateToCompare) {
    return (reminderDate != null) &&
        reminderDate.isAfter(dateToCompare);
  }
}

