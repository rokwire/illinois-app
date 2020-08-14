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

import 'package:illinois/model/Voter.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Assets.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/utils/Utils.dart';

import 'Service.dart';

class Voter with Service implements NotificationsListener {
  static final Voter _service = Voter._internal();

  factory Voter() {
    return _service;
  }

  Voter._internal();

  List<VoterRule> _voterRules;

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
    _loadVoterRules();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Assets()]);
  }

  VoterRule getVoterRuleForToday() {
    if (AppCollection.isCollectionEmpty(_voterRules)) {
      return null;
    }
    DateTime now = AppDateTime().now;
    DateTime uniLocalTime = AppDateTime().getUniLocalTimeFromUtcTime(now.toUtc());
    for (VoterRule rule in _voterRules) {
      bool afterStartDate = true;
      bool beforeEndDate = true;
      if (rule.startDate != null) {
        bool isSameStartDay = (uniLocalTime.year == rule.startDate.year) && (uniLocalTime.month == rule.startDate.month) &&
            (uniLocalTime.day == rule.startDate.day);
        afterStartDate = (rule.startDate.isBefore(uniLocalTime)) || isSameStartDay;
      }
      if (rule.endDate != null) {
        bool isSameEndDay = (uniLocalTime.year == rule.endDate.year) && (uniLocalTime.month == rule.endDate.month) && (uniLocalTime.day == rule.endDate.day);
        beforeEndDate = (rule.endDate.isAfter(uniLocalTime)) || isSameEndDay;
      }
      if (afterStartDate && beforeEndDate) {
        return rule;
      }
    }
    return null;
  }

  void _loadVoterRules() {
    List<dynamic> rulesJson = Assets()['voter.rules'];
    if (AppCollection.isCollectionNotEmpty(rulesJson)) {
      _voterRules = List();
      for (dynamic rule in rulesJson) {
        _voterRules.add(VoterRule.fromJson(rule));
      }
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Assets.notifyChanged) {
      _loadVoterRules();
    }
  }
}
