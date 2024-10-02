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
  static const AnalyticsFeature   Academics                = AnalyticsFeature("Academics", key: {"Academic", "Course", "Assignment", "Canvas", "Gies", "Essential", "Skill"});
  static const AnalyticsFeature   AppHelp                  = AnalyticsFeature("App Help");
  static const AnalyticsFeature   Appointments             = AnalyticsFeature("Appointments", key: "Appointment");
  static const AnalyticsFeature   Athletics                = AnalyticsFeature("Athletics", key: {"Athletic", "Sport"});
  static const AnalyticsFeature   Assistant                = AnalyticsFeature("Assistant");
  static const AnalyticsFeature   Browse                   = AnalyticsFeature("Browse");
  static const AnalyticsFeature   Buildings                = AnalyticsFeature("Buildings", key: "Building", priority: -1); // e.g. WellnessBuilding => Wellness
  static const AnalyticsFeature   Guide                    = AnalyticsFeature("Campus Guide", key: {"Campus", "Guide", "For Students"});
  static const AnalyticsFeature   Debug                    = AnalyticsFeature("Debug", priority: 1);
  static const AnalyticsFeature   Dining                   = AnalyticsFeature("Dining", key: {"Dining", "Food"});
  static const AnalyticsFeature   Events                   = AnalyticsFeature("Events", key: "Event");
  static const AnalyticsFeature   Favorites                = AnalyticsFeature("Favorites");
  static const AnalyticsFeature   Feeds                    = AnalyticsFeature("Feeds");
  static const AnalyticsFeature   Groups                   = AnalyticsFeature("Groups", key: "Group", priority: 1);
  static const AnalyticsFeature   Home                     = AnalyticsFeature("Home", priority: -1); // e.g. Event2HomePanel => Event
  static const AnalyticsFeature   Laundry                  = AnalyticsFeature("Laundry");
  static const AnalyticsFeature   Map                      = AnalyticsFeature("Map");
  static const AnalyticsFeature   Messages                 = AnalyticsFeature("Messages");
  static const AnalyticsFeature   MTD                      = AnalyticsFeature("MTD", key: {"MTD", "POI"});
  static const AnalyticsFeature   Notifications            = AnalyticsFeature("Notifications");
  static const AnalyticsFeature   Onboarding               = AnalyticsFeature("Onboarding");
  static const AnalyticsFeature   Polls                    = AnalyticsFeature("Polls", key: "Poll", priority: -1);
  static const AnalyticsFeature   Profile                  = AnalyticsFeature("Profile");
  static const AnalyticsFeature   Recent                   = AnalyticsFeature("Recent");
  static const AnalyticsFeature   ResearchProject          = AnalyticsFeature("Research at Illinois", key: "ResearchProject", priority: 1);
  static const AnalyticsFeature   Settings                 = AnalyticsFeature("Settings", priority: -1);
  static const AnalyticsFeature   StateFarmCenter          = AnalyticsFeature("StateFarm Center", key: {"StateFarm", "Parking", "StadiumPoll"});
  static const AnalyticsFeature   Unknown                  = AnalyticsFeature("Unknown");
  static const AnalyticsFeature   Wallet                   = AnalyticsFeature("Wallet");
  static const AnalyticsFeature   WalletBusPass            = AnalyticsFeature("Wallet: Bus Pass", key: "BusPass", priority: 1);
  static const AnalyticsFeature   WalletIlliniCash         = AnalyticsFeature("Wallet: Illini Cash", key: "IlliniCash", priority: 1);
  static const AnalyticsFeature   WalletIlliniID           = AnalyticsFeature("Wallet: Illini ID", key: "ICard", priority: 1);
  static const AnalyticsFeature   WalletMealPlan           = AnalyticsFeature("Wallet: Meal Plan", key: "MealPlan", priority: 1);
  static const AnalyticsFeature   Wellness                 = AnalyticsFeature("Wellness");

  static const List<AnalyticsFeature> _features = <AnalyticsFeature>[
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
    Laundry,
    Recent,
    Debug,
    ResearchProject,
    StateFarmCenter,
    Onboarding,
    Wallet,
    WalletBusPass,
    WalletIlliniCash,
    WalletIlliniID,
    WalletMealPlan,
  ];

  final String name;
  final int priority;
  final dynamic key;

  const AnalyticsFeature(this.name, { this.key, this.priority = 0 });

  @override
  bool operator==(Object other) =>
    (other is AnalyticsFeature) &&
    (name == other.name) &&
    (priority == other.priority) &&
    (DeepCollectionEquality().equals(key, other.key));

  @override
  int get hashCode =>
    name.hashCode ^
    priority.hashCode ^
    DeepCollectionEquality().hash(key);

  static AnalyticsFeature? fromClass(dynamic classInstance) {
    AnalyticsFeature? feature;
    if (classInstance is AnalyticsInfo) {
      feature = classInstance.analyticsFeature;
    }
    if ((feature == null) && (classInstance != null)) {
      feature = fromName(classInstance.runtimeType.toString());
    }
    return feature;
  }

  static AnalyticsFeature? fromName(String? className) {
    AnalyticsFeature? result;
    if (className != null) {
      for (AnalyticsFeature feature in _features) {
        if (feature.matchKey(className)) {
          if ((result == null) || (result.priority < feature.priority)) {
            result = feature;
          }
        }
      }
    }
    return result;
  }

  bool matchKey(String className) {
    dynamic useKey = this.key ?? name;
    if (useKey is String) {
      return className.contains(RegExp(useKey, caseSensitive: false));
    }
    else if ((useKey is List) || (useKey is Set)) {
      for (dynamic keyEntry in useKey) {
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

