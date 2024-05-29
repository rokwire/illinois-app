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

import 'package:collection/collection.dart';

/////////////////////////
// AnalyticsFeature

class AnalyticsFeature {

  // Predefined Features
  static const AnalyticsFeature   Academics                = AnalyticsFeature("Academics", key: {"Academic", "Course"});
  static const AnalyticsFeature   AppHelp                  = AnalyticsFeature("App Help");
  static const AnalyticsFeature   Appointments             = AnalyticsFeature("Appointments", key: "Appointment");
  static const AnalyticsFeature   Athletics                = AnalyticsFeature("Athletics", key: {"Athletic", "Sport"});
  static const AnalyticsFeature   Browse                   = AnalyticsFeature("Browse");
  static const AnalyticsFeature   Buildings                = AnalyticsFeature("Buildings", key: "Building");
  static const AnalyticsFeature   Guide                    = AnalyticsFeature("Campus Guide", key: "Guide");
  static const AnalyticsFeature   Dining                   = AnalyticsFeature("Dining");
  static const AnalyticsFeature   Events                   = AnalyticsFeature("Events", key: "Event");
  static const AnalyticsFeature   Favorites                = AnalyticsFeature("Favorites", key: "Home");
  static const AnalyticsFeature   Feeds                    = AnalyticsFeature("Feeds");
  static const AnalyticsFeature   Groups                   = AnalyticsFeature("Groups", key: "Group");
  static const AnalyticsFeature   Laundry                  = AnalyticsFeature("Laundry");
  static const AnalyticsFeature   Map                      = AnalyticsFeature("Map");
  static const AnalyticsFeature   MTD                      = AnalyticsFeature("MTD", key: {"MTD", "POI"});
  static const AnalyticsFeature   Notifications            = AnalyticsFeature("Notifications");
  static const AnalyticsFeature   Polls                    = AnalyticsFeature("Polls", key: "Poll");
  static const AnalyticsFeature   Profile                  = AnalyticsFeature("Profile");
  static const AnalyticsFeature   ResearchProject          = AnalyticsFeature("Research at Illinois");
  static const AnalyticsFeature   Settings                 = AnalyticsFeature("Settings");
  static const AnalyticsFeature   Wallet                   = AnalyticsFeature("Wallet");
  static const AnalyticsFeature   WalletBusPass            = AnalyticsFeature("Wallet: Bus Pass");
  static const AnalyticsFeature   WalletIlliniCash         = AnalyticsFeature("Wallet: Illini Cash");
  static const AnalyticsFeature   WalletIlliniID           = AnalyticsFeature("Wallet: Illini ID");
  static const AnalyticsFeature   WalletMealPlan           = AnalyticsFeature("Wallet: Meal Plan");
  static const AnalyticsFeature   Wellness                 = AnalyticsFeature("Wellness");

  static const List<AnalyticsFeature> _features = <AnalyticsFeature>[
    // Sort Order is significant, e.g. we should match WellnessBuilding as Wellness feature, not Building
    Favorites,
    Browse,
    Map,
    Academics,
    Wellness,
    Appointments,
    Athletics,
    Events,
    Groups,
    Guide,
    Settings,
    Profile,
    Notifications,

    AppHelp,
    Dining,
    Buildings,
    Feeds,
    MTD,
    Polls,
    ResearchProject,
    Wallet,
    WalletBusPass,
    WalletIlliniCash,
    WalletIlliniID,
    WalletMealPlan,
  ];

  final String name;
  final dynamic _key;

  const AnalyticsFeature(this.name, { dynamic key}) :
    _key = key;

  @override
  bool operator==(Object other) =>
    (other is AnalyticsFeature) &&
    (name == other.name) &&
    (DeepCollectionEquality().equals(_key, other._key));

  @override
  int get hashCode =>
    name.hashCode ^
    DeepCollectionEquality().hash(_key);

  static AnalyticsFeature? fromClass(dynamic classInstance) {
    AnalyticsFeature? feature;
    if (classInstance is AnalyticsInfo) {
      feature = classInstance.analyticsFeature;
    }
    if ((feature == null) && (classInstance != null)) {
      feature = fromClassName(classInstance.runtimeType.toString());
    }
    return feature;
  }

  static AnalyticsFeature? fromClassName(String? className) {
    if (className != null) {
      for (AnalyticsFeature feature in _features) {
        if (feature.matchKey(className)) {
          return feature;
        }
      }
    }
    return null;
  }

  bool matchKey(String className) {
    dynamic key = _key ?? name;
    if (key is String) {
      return className.contains(RegExp(key, caseSensitive: false));
    }
    else if ((key is List) || (key is Set)) {
      for (dynamic keyEntry in key) {
        if ((keyEntry is String) &&  className.contains(RegExp(keyEntry, caseSensitive: false))) {
          return true;
        }
      }
    }
    return false;
  }
}

/////////////////////////
// AnalyticsPage

abstract class AnalyticsInfo {
  String? get analyticsPageName => null;
  Map<String, dynamic>? get analyticsPageAttributes => null;
  AnalyticsFeature? get analyticsFeature => null;
}

