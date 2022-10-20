/*
 * Copyright 2022 Board of Trustees of the University of Illinois.
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
import 'package:flutter/services.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Appointments with Service implements ExploreJsonHandler {
  static final Appointments _service = Appointments._internal();
  factory Appointments() => _service;
  Appointments._internal();

  // Service
  @override
  void createService() {
    Explore.addJsonHandler(this);
    super.createService();
  }

  @override
  void destroyService() {
    Explore.removeJsonHandler(this);
    super.destroyService();
  }

  Future<List<Appointment>?> loadAppointments({bool? onlyUpcoming, AppointmentType? type}) async {
    List<Appointment>? appointments;
    try {
      appointments = Appointment.listFromJson(JsonUtils.decodeList(await rootBundle.loadString('assets/appointments.json')));
    } catch (e) {
      debugPrint(e.toString());
    }
    List<Appointment>? resultAppointments;
    //TBD: Appointment - do this filtering on the backend
    if (CollectionUtils.isNotEmpty(appointments)) {
      resultAppointments = <Appointment>[];
      for (Appointment appointment in appointments!) {
        if ((onlyUpcoming == true) && !appointment.isUpcoming) {
          continue;
        }
        if ((type != null) && (type != appointment.type)) {
          continue;
        }
        resultAppointments.add(appointment);
      }
      _sortAppointments(resultAppointments);
    }
    return resultAppointments;
  }

  void _sortAppointments(List<Appointment>? appointments) {
    if (CollectionUtils.isNotEmpty(appointments)) {
      appointments!.sort((first, second) {
        if (first.dateTimeUtc == null || second.dateTimeUtc == null) {
          return 0;
        } else {
          return (first.dateTimeUtc!.isBefore(second.dateTimeUtc!)) ? -1 : 1;
        }
      });
    }
  }

  // ExploreJsonHandler
  @override bool exploreCanJson(Map<String, dynamic>? json) => Appointment.canJson(json);
  @override Explore? exploreFromJson(Map<String, dynamic>? json) => Appointment.fromJson(json);
}
