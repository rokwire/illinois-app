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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentScheduleTimePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

class AppointmentSchedulePanel extends StatefulWidget {

  final DateTime scheduleDateTime;
  AppointmentSchedulePanel({ Key? key, required this.scheduleDateTime }) : super(key: key);

  static void present(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentScheduleTimePanel(onContinue: (BuildContext context, DateTime result) {
      Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => AppointmentSchedulePanel(scheduleDateTime: result)));
    })));
  }

  @override
  State<StatefulWidget> createState() => _AppointmentSchedulePanelState();
}

class _AppointmentSchedulePanelState extends State<AppointmentSchedulePanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.appointment.schedule.header.title', 'Schedule Appointment')),
      body: Container(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar()
    );
  }
}