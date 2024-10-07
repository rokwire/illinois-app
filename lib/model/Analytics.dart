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
  static const AnalyticsFeature   Academics                      = AnalyticsFeature("Academics");
  static const AnalyticsFeature   AcademicsEvents                = AnalyticsFeature("Academics: Speakers & Seminars", key: {"AcademicsEvents"}, priority: 1);
  static const AnalyticsFeature   AcademicsChecklist             = AnalyticsFeature("Academics: New Student Checklist", priority: -1);
  static const AnalyticsFeature   AcademicsGiesChecklist         = AnalyticsFeature("Academics: iDegrees New Student Checklist", priority: -1);
  static const AnalyticsFeature   AcademicsCanvasCourses         = AnalyticsFeature("Academics: Canvas Courses", key: {"CanvasCourse"}, priority: 1);
  static const AnalyticsFeature   AcademicsGiesCanvasCourses     = AnalyticsFeature("Academics: Gies Canvas Courses", key: {"GiesCanvasCours"}, priority: 2);
  static const AnalyticsFeature   AcademicsMedicineCourses       = AnalyticsFeature("Academics: College of Medicine Compliance", key: {"MedicineCourse"}, priority: 1);
  static const AnalyticsFeature   AcademicsStudentCourses        = AnalyticsFeature("Academics: Courses", key: {"StudentCourse"}, priority: 1);
  static const AnalyticsFeature   AcademicsSkillsSelfEvaluation  = AnalyticsFeature("Academics: Skills Self-Evaluation", key: {"SkillsSelfEvaluation"}, priority: 1);
  static const AnalyticsFeature   AcademicsEssentialSkillsCoach  = AnalyticsFeature("Academics: Essential Skills Coach", key: {"EssentialSkillsCoach"}, priority: 1);
  static const AnalyticsFeature   AcademicsToDoList              = AnalyticsFeature("Academics: To-Do List", priority: -1);
  static const AnalyticsFeature   AcademicsDueDateCatalog        = AnalyticsFeature("Academics: Due Date Catalog", priority: -1);
  static const AnalyticsFeature   AcademicsMyIllini              = AnalyticsFeature("Academics: myIllini", priority: -1);
  static const AnalyticsFeature   AcademicsCampusReminders       = AnalyticsFeature("Academics: Campus Reminders", priority: -1);
  static const AnalyticsFeature   AcademicsAppointments          = AnalyticsFeature("Academics: Appointments", priority: -1);

  static const AnalyticsFeature   AppHelp                        = AnalyticsFeature("App Help");
  static const AnalyticsFeature   Athletics                      = AnalyticsFeature("Athletics", key: {"Athletic", "Sport"});
  static const AnalyticsFeature   Appointments                   = AnalyticsFeature("Appointments");
  static const AnalyticsFeature   Assistant                      = AnalyticsFeature("Assistant");
  static const AnalyticsFeature   Browse                         = AnalyticsFeature("Sections", key: "Browse");
  static const AnalyticsFeature   Buildings                      = AnalyticsFeature("Buildings", key: "Building", priority: -1); // e.g. WellnessBuilding => Wellness
  static const AnalyticsFeature   Guide                          = AnalyticsFeature("Campus Guide", key: {"Campus", "Guide", "For Students"});
  static const AnalyticsFeature   Debug                          = AnalyticsFeature("Debug", priority: 1);
  static const AnalyticsFeature   Dining                         = AnalyticsFeature("Dining", key: {"Dining", "Food"});
  static const AnalyticsFeature   Events                         = AnalyticsFeature("Events", key: "Event");
  static const AnalyticsFeature   Favorites                      = AnalyticsFeature("Favorites");
  static const AnalyticsFeature   Groups                         = AnalyticsFeature("Groups", key: "Group", priority: 1);
  static const AnalyticsFeature   Home                           = AnalyticsFeature("Home", priority: -1); // e.g. Event2HomePanel => Event
  static const AnalyticsFeature   Laundry                        = AnalyticsFeature("Laundry");
  static const AnalyticsFeature   Map                            = AnalyticsFeature("Map");
  static const AnalyticsFeature   Messages                       = AnalyticsFeature("Messages");
  static const AnalyticsFeature   MTD                            = AnalyticsFeature("MTD", key: {"MTD", "POI"});
  static const AnalyticsFeature   News                           = AnalyticsFeature("Illini News", key: {"DailyIllini", "Twitter"});
  static const AnalyticsFeature   Notifications                  = AnalyticsFeature("Notifications");
  static const AnalyticsFeature   Onboarding                     = AnalyticsFeature("Onboarding");
  static const AnalyticsFeature   Polls                          = AnalyticsFeature("Polls", key: "Poll", priority: -1);
  static const AnalyticsFeature   Profile                        = AnalyticsFeature("Profile");
  static const AnalyticsFeature   Radio                          = AnalyticsFeature("Radio Stations", key: "Radio");
  static const AnalyticsFeature   Recent                         = AnalyticsFeature("Recent");
  static const AnalyticsFeature   ResearchProject                = AnalyticsFeature("Research at Illinois", key: "ResearchProject", priority: 1);
  static const AnalyticsFeature   Safety                         = AnalyticsFeature("Safety");
  static const AnalyticsFeature   Settings                       = AnalyticsFeature("Settings", priority: -1);
  static const AnalyticsFeature   StateFarmCenter                = AnalyticsFeature("StateFarm Center", key: {"StateFarm", "Parking", "StadiumPoll"});

  static const AnalyticsFeature   Wallet                         = AnalyticsFeature("Wallet");
  static const AnalyticsFeature   WalletBusPass                  = AnalyticsFeature("Wallet: Bus Pass", key: "BusPass", priority: 1);
  static const AnalyticsFeature   WalletIlliniCash               = AnalyticsFeature("Wallet: Illini Cash", key: "IlliniCash", priority: 1);
  static const AnalyticsFeature   WalletIlliniID                 = AnalyticsFeature("Wallet: Illini ID", key: "ICard", priority: 1);
  static const AnalyticsFeature   WalletMealPlan                 = AnalyticsFeature("Wallet: Meal Plan", key: "MealPlan", priority: 1);

  static const AnalyticsFeature   Wellness                       = AnalyticsFeature("Wellness");
  static const AnalyticsFeature   WellnessDailyTips              = AnalyticsFeature("Wellness: Tips", key: {"WellnessDailyTip"}, priority: 1);
  static const AnalyticsFeature   WellnessRings                  = AnalyticsFeature("Wellness: Rings", key: {"WellnessRing"}, priority: 1);
  static const AnalyticsFeature   WellnessToDo                   = AnalyticsFeature("Wellness: To Do", key: {"WellnessToDo"}, priority: 1);
  static const AnalyticsFeature   WellnessAppointments           = AnalyticsFeature("Wellness: Appointments", key: {"WellnessAppointments"}, priority: 1);
  static const AnalyticsFeature   WellnessHealthScreener         = AnalyticsFeature("Wellness: Health Screener", key: {"WellnessHealthScreener"}, priority: 1);
  static const AnalyticsFeature   WellnessResources              = AnalyticsFeature("Wellness: Resources", key: {"WellnessResources"}, priority: 1);
  static const AnalyticsFeature   WellnessMentalHealth           = AnalyticsFeature("Wellness: Mental Health", key: {"WellnessMentalHealth"}, priority: 1);
  static const AnalyticsFeature   WellnessSuccessTeam            = AnalyticsFeature("Wellness: Success Team", key: {"WellnessSuccessTeam"}, priority: 1);
  static const AnalyticsFeature   WellnessPodcast                = AnalyticsFeature("Wellness: Podcast", priority: -1);
  static const AnalyticsFeature   WellnessStruggling             = AnalyticsFeature("Wellness: Struggling", priority: -1);

  static const AnalyticsFeature   Unknown                        = AnalyticsFeature("Unknown");

  static const List<AnalyticsFeature> _features = <AnalyticsFeature>[
    Favorites,
    Browse,
    Map,

    Academics,
    AcademicsEvents,
    AcademicsChecklist,
    AcademicsGiesChecklist,
    AcademicsCanvasCourses,
    AcademicsGiesCanvasCourses,
    AcademicsMedicineCourses,
    AcademicsStudentCourses,
    AcademicsSkillsSelfEvaluation,
    AcademicsEssentialSkillsCoach,
    AcademicsToDoList,
    AcademicsDueDateCatalog,
    AcademicsMyIllini,
    AcademicsAppointments,

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
    MTD,
    Messages,
    News,
    Polls,
    Laundry,
    Recent,
    Debug,
    ResearchProject,
    Radio,
    StateFarmCenter,
    Onboarding,

    Wellness,
    WellnessDailyTips,
    WellnessRings,
    WellnessToDo,
    WellnessAppointments,
    WellnessHealthScreener,
    WellnessResources,
    WellnessMentalHealth,
    WellnessSuccessTeam,
    WellnessPodcast,
    WellnessStruggling,

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

  @override
  String toString() => name;

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

