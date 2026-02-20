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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:rokwire_plugin/service/flex_ui.dart' as rokwire;
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class FlexUI extends rokwire.FlexUI {

  static String get notifyChanged => rokwire.FlexUI.notifyChanged;

  // Singletone Factory

  @protected
  FlexUI.internal() : super.internal();

  factory FlexUI() => ((rokwire.FlexUI.instance is FlexUI) ? (rokwire.FlexUI.instance as FlexUI) : (rokwire.FlexUI.instance = FlexUI.internal()));

  // Service

  @override
  void createService() {
    super.createService();
    NotificationService().subscribe(this,[
      Auth2.notifyCardChanged,
      IlliniCash.notifyBallanceUpdated,
      IlliniCash.notifyStudentClassificationUpdated,
    ]);
  }

  @override
  void destroyService() {
    super.destroyService();
    NotificationService().unsubscribe(this);
  }

  @override
  Set<Service> get serviceDependsOn {
    Set<Service> services = super.serviceDependsOn;
    services.add(IlliniCash());
    return services;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    super.onNotification(name, param);
    if ((name == Auth2.notifyCardChanged) ||
        (name == IlliniCash.notifyBallanceUpdated) ||
        (name == IlliniCash.notifyStudentClassificationUpdated))
    {
      updateContent();
    }
  }

  // Feature
  bool get isAnalyticsAvailable => hasFeature('analytics');
  bool get isLocationServicesAvailable => hasFeature('location_services');
  bool get isPersonalizationAvailable => hasFeature('personalization');
  bool get isAuthenticationAvailable => hasFeature('authentication');
  bool get isNotificationsAvailable => hasFeature('notifications');
  bool get isPaymentInfornationAvailable => hasFeature('payment_information');
  bool get isSharingAvailable => hasFeature('sharing');
  bool get isPrivacyAvailable => hasFeature('privacy');

  bool get isGiesAvailable => hasFeature('gies');
  bool get isNewStudentAvailable => hasFeature('new_student');
  bool get isCanvasAvailable => hasFeature('canvas');

  bool get isIlliniCashAvailable => hasFeature('illini_cash');
  bool get isAddIlliniCashAvailable => hasFeature('add_illini_cash');
  bool get isMTDBusPassAvailable => hasFeature('mtd_bus_pass');
  bool get isSafeWalkAvailable => hasFeature('safewalk_request');
  bool get isMessagesAvailable => hasFeature('messages');

  bool get isAllAssistantsAvailable => hasFeature('all_assistants');
  bool get isAssistantFaqsAvailable => hasFeature('assistant_faqs');

  // Local Build

  @override
  bool localeIsEntryAvailable(String entry, { String? group, required Map<String, dynamic> rules, rokwire.FlexUiBuildContext? buildContext }) {

    String? pathEntry = (group != null) ? '$group.$entry' : null;

    Map<String, dynamic>? illiniCashRules = rules['illini_cash'];
    dynamic illiniCashRule = (illiniCashRules != null) ? (((pathEntry != null) ? illiniCashRules[pathEntry] : null) ?? illiniCashRules[entry])  : null;
    if ((illiniCashRule != null) && !_localeEvalIlliniCashRule(illiniCashRule, buildContext: buildContext)) {
      return false;
    }

    return super.localeIsEntryAvailable(entry, group: group, rules: rules, buildContext: buildContext);
  }

  static const String _studentClassificationPrefix = 'StudentClassification:';
  static const String _ballancePrefix = 'Ballance:';

  bool _localeEvalIlliniCashRule(dynamic illiniCashRule, { rokwire.FlexUiBuildContext? buildContext }) {
    bool result = true;  // allow everything that is not defined or we do not understand
    if (illiniCashRule is Map) {
      illiniCashRule.forEach((dynamic key, dynamic value) {
        if (key is String) {
          if (key == 'housingResidenceStatus') {
            bool? ruleValue = JsonUtils.boolValue(localeEvalParam(value));
            if (ruleValue != null) {
              bool housingResidenceStatus = IlliniCash().ballance?.housingResidenceStatus ?? false;
              result = result && (housingResidenceStatus == ruleValue);
            }
          }
          else if (key == 'firstYearStudent') {
            bool? ruleValue = JsonUtils.boolValue(localeEvalParam(value));
            if (ruleValue != null) {
              bool firstYearStudent = IlliniCash().studentClassification?.firstYear ?? false;
              result = result && (firstYearStudent == ruleValue);
            }
          }
          else if (key.startsWith(_studentClassificationPrefix)) {
            String fieldName = key.substring(_studentClassificationPrefix.length);
            dynamic fieldValue = IlliniCash().studentClassification?.fieldValue(fieldName);
            if (fieldValue != null) {
              dynamic ruleValue = localeEvalParam(value);
              if (ruleValue != null) {
                result = result && (fieldValue == ruleValue);
              }
            }
          }
          else if (key.startsWith(_ballancePrefix)) {
            String fieldName = key.substring(_ballancePrefix.length);
            dynamic fieldValue = IlliniCash().ballance?.fieldValue(fieldName);
            if (fieldValue != null) {
              dynamic ruleValue = localeEvalParam(value);
              if (ruleValue != null) {
                result = result && (fieldValue == ruleValue);
              }
            }
          }
        }
      });
    }
    return result;
  }

  @override
  bool localeEvalAuthRule(dynamic authRule, { rokwire.FlexUiBuildContext? buildContext }) {
    bool result = super.localeEvalAuthRule(authRule, buildContext: buildContext);
    if (result && (authRule is Map)) {
      authRule.forEach((dynamic key, dynamic value) {
        if (key is String) {
          if ((key == 'iCard') && (value is bool)) {
            result = result && ((Auth2().iCard != null) == value);
          }
          else if ((key == 'iCardNum') && (value is bool)) {
            result = result && ((0 < (Auth2().iCard?.cardNumber?.length ?? 0)) == value);
          }
          else if ((key == 'iCardLibraryNum') && (value is bool)) {
            result = result && ((0 < (Auth2().iCard?.libraryNumber?.length ?? 0)) == value);
          }
        }
      });
    }

    return result;
  }
}