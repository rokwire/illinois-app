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

  // Local Build

  @override
  bool localeIsEntryAvailable(String entry, { String? group, required Map<String, dynamic> rules }) {

    String? pathEntry = (group != null) ? '$group.$entry' : null;

    Map<String, dynamic>? illiniCashRules = rules['illini_cash'];
    dynamic illiniCashRule = (illiniCashRules != null) ? (((pathEntry != null) ? illiniCashRules[pathEntry] : null) ?? illiniCashRules[entry])  : null;
    if ((illiniCashRule != null) && !_localeEvalIlliniCashRule(illiniCashRule)) {
      return false;
    }

    return super.localeIsEntryAvailable(entry, group: group, rules: rules);
  }

  static bool _localeEvalIlliniCashRule(dynamic illiniCashRule) {
    bool result = true;  // allow everything that is not defined or we do not understand
    if (illiniCashRule is Map) {
      illiniCashRule.forEach((dynamic key, dynamic value) {
        if ((key is String) && (key == 'housingResidenceStatus') && (value is bool)) {
           result = result && (IlliniCash().ballance?.housingResidenceStatus ?? false);
        }
        else if ((key is String) && (key == 'firstYearStudent') && (value is bool)) {
           result = result && (IlliniCash().studentClassification?.firstYear ?? false);
        }
      });
    }
    return result;
  }

  @override
  bool localeEvalAuthRule(dynamic authRule) {
    bool result = super.localeEvalAuthRule(authRule);
    if (result && (authRule is Map)) {
      authRule.forEach((dynamic key, dynamic value) {
        if (key is String) {
          if ((key == 'iCard') && (value is bool)) {
            result = result && ((Auth2().authCard != null) == value);
          }
          else if ((key == 'iCardNum') && (value is bool)) {
            result = result && ((0 < (Auth2().authCard?.cardNumber?.length ?? 0)) == value);
          }
          else if ((key == 'iCardLibraryNum') && (value is bool)) {
            result = result && ((0 < (Auth2().authCard?.libraryNumber?.length ?? 0)) == value);
          }
        }
      });
    }

    return result;
  }
}