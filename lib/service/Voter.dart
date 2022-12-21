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
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/service.dart';

class Voter with Service implements NotificationsListener {
  static final Voter _service = Voter._internal();

  factory Voter() {
    return _service;
  }

  Voter._internal();

  List<VoterRule>? _voterRules;

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
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Assets()]);
  }

  VoterRule? getVoterRuleForToday() {
    DateTime? uniLocalTime = AppDateTime().getUniLocalTimeFromUtcTime(AppDateTime().now.toUtc());
    if (CollectionUtils.isNotEmpty(_voterRules) && (uniLocalTime != null)) {
      for (VoterRule rule in _voterRules!) {
        bool afterStartDate = true;
        bool beforeEndDate = true;
        if (rule.startDate != null) {
          bool isSameStartDay = (uniLocalTime.year == rule.startDate?.year) && (uniLocalTime.month == rule.startDate?.month) &&
              (uniLocalTime.day == rule.startDate?.day);
          afterStartDate = (rule.startDate?.isBefore(uniLocalTime) ?? false) || isSameStartDay;
        }
        if (rule.endDate != null) {
          bool isSameEndDay = (uniLocalTime.year == rule.endDate?.year) && (uniLocalTime.month == rule.endDate?.month) && (uniLocalTime.day == rule.endDate?.day);
          beforeEndDate = (rule.endDate?.isAfter(uniLocalTime) ?? false) || isSameEndDay;
        }
        if (afterStartDate && beforeEndDate) {
          return rule;
        }
      }
    }
    return null;
  }

  void _loadVoterRules() {
    _voterRules = VoterRule.listFromJson(JsonUtils.listValue(Assets()['voter.rules']));
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Assets.notifyChanged) {
      _loadVoterRules();
    }
  }
}
