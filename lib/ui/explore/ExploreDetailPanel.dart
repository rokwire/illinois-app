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
import 'package:geolocator/geolocator.dart';
import 'package:neom/model/Analytics.dart';
import 'package:neom/model/Laundry.dart';
import 'package:neom/model/MTD.dart';
import 'package:neom/model/StudentCourse.dart';
import 'package:neom/model/sport/Game.dart';
import 'package:neom/model/Appointment.dart';
import 'package:neom/ui/academics/StudentCourses.dart';
import 'package:neom/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:neom/ui/explore/ExploreBuildingDetailPanel.dart';
import 'package:neom/ui/laundry/LaundryRoomDetailPanel.dart';
import 'package:neom/ui/mtd/MTDStopDeparturesPanel.dart';
import 'package:neom/ui/appointments/AppointmentDetailPanel.dart';
import 'package:neom/ui/explore/ExploreDiningDetailPanel.dart';

import 'package:rokwire_plugin/model/explore.dart';
import 'package:neom/model/Dining.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/ext/Explore.dart';
import 'package:rokwire_plugin/model/group.dart';

class ExploreDetailPanel extends StatelessWidget with AnalyticsInfo {
  final Explore? explore;
  final Position? initialLocationData;
  final Group? browseGroup;

  ExploreDetailPanel({this.explore, this.initialLocationData, this.browseGroup});

  static Widget? contentPanel({Explore? explore, Position? initialLocationData, Group? browseGroup}) {
    if (explore is Dining) {
      return ExploreDiningDetailPanel(dining: explore, initialLocationData: initialLocationData);
    }
    else if (explore is LaundryRoom) {
      return LaundryRoomDetailPanel(room: explore);
    }
    else if (explore is Game) {
      return AthleticsGameDetailPanel(game: explore);
    }
    else if (explore is Building) {
      return ExploreBuildingDetailPanel(building: explore);
    }
    else if (explore is MTDStop) {
      return MTDStopDeparturesPanel(stop: explore,);
    }
    else if (explore is StudentCourse) {
      return StudentCourseDetailPanel(course: explore,);
    }
    else if (explore is Appointment) {
      return AppointmentDetailPanel(appointment: explore);
    }
    else { // Default for unexpected type
      return null;
    }
  }

  @override
  AnalyticsFeature? get analyticsFeature => explore?.analyticsFeature;

  @override
  Map<String, dynamic>? get analyticsPageAttributes => explore?.analyticsAttributes;

  @override
  Widget build(BuildContext context) {
    return contentPanel(explore: explore, initialLocationData: initialLocationData, browseGroup: browseGroup) ?? Scaffold(
      appBar: HeaderBar(),
    );
  }
}