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
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentCard.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessAppointmentsHomeContentWidget extends StatefulWidget {
  WellnessAppointmentsHomeContentWidget();

  @override
  State<WellnessAppointmentsHomeContentWidget> createState() => _WellnessAppointmentsHomeContentWidgetState();
}

class _WellnessAppointmentsHomeContentWidgetState extends State<WellnessAppointmentsHomeContentWidget> {
  List<Appointment>? _upcomingAppointments;
  List<Appointment>? _pastAppointments;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildRescheduleDescription(), _buildUpcomingAppointments(), _buildPastAppointments()]));
  }

  Widget _buildRescheduleDescription() {
    return InkWell(
        child: Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
                Localization()
                    .getStringEx('panel.wellness.appointments.home.reschedule_appointment.label', 'Need to cancel or reschedule?'),
                style: TextStyle(
                    fontSize: 18,
                    color: Styles().colors!.fillColorPrimary,
                    fontFamily: Styles().fontFamilies!.regular,
                    decoration: TextDecoration.underline,
                    decorationThickness: 1,
                    decorationColor: Styles().colors!.fillColorPrimary))),
        onTap: _showRescheduleAppointmentPopup);
  }

  Widget _buildUpcomingAppointments() {
    if (CollectionUtils.isEmpty(_upcomingAppointments)) {
      return _buildEmptyUpcomingAppointments();
    } else {
      return Column(children: _buildAppointmentsWidgetList(_upcomingAppointments));
    }
  }

  Widget _buildEmptyUpcomingAppointments() {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
            Localization().getStringEx('panel.wellness.appointments.home.upcoming.list.empty.msg',
                'You currently have no upcoming appointments linked within the Illinois app.'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.regular)));
  }

  Widget _buildPastAppointments() {
    if (CollectionUtils.isEmpty(_pastAppointments)) {
      return _buildEmptyPastAppointments();
    } else {
      List<Widget> pastAppointmentsWidgetList = <Widget>[];
      pastAppointmentsWidgetList.add(Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            Expanded(
                child: Text(
                    Localization()
                        .getStringEx('panel.wellness.appointments.home.past_appointments.header.label', 'Recent Past Appointments'),
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Styles().colors!.blackTransparent06, fontSize: 22, fontFamily: Styles().fontFamilies!.extraBold)))
          ])));
      pastAppointmentsWidgetList.addAll(_buildAppointmentsWidgetList(_pastAppointments));
      pastAppointmentsWidgetList.add(_buildPastAppointmentsDescription());
      return Column(children: pastAppointmentsWidgetList);
    }
  }

  Widget _buildEmptyPastAppointments() {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
            Localization().getStringEx('panel.wellness.appointments.home.past.list.empty.msg',
                "You don't have recent past appointments linked within the Illinois app."),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.regular)));
  }

  Widget _buildPastAppointmentsDescription() {
    //TBD: appointments - make it clickable and take url from config or external resource
    return Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 16),
        child: Text(
            Localization().getStringEx('panel.wellness.appointments.home.past_appointments.description',
                'Visit MyMcKinley to view a full history of past appointments.'),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                color: Styles().colors!.fillColorPrimary,
                fontFamily: Styles().fontFamilies!.regular,
                decoration: TextDecoration.underline,
                decorationColor: Styles().colors!.fillColorPrimary,
                decorationThickness: 1)));
  }

  List<Widget> _buildAppointmentsWidgetList(List<Appointment>? appointments) {
    List<Widget> widgets = <Widget>[];
    if (CollectionUtils.isNotEmpty(appointments)) {
      for (int i = 0; i < appointments!.length; i++) {
        Appointment appointment = appointments[i];
        widgets.add(Padding(padding: EdgeInsets.only(top: (i == 0 ? 0 : 16)), child: AppointmentCard(appointment: appointment)));
      }
    }
    return widgets;
  }

  void _showRescheduleAppointmentPopup() {
    AppAlert.showCustomDialog(
        context: context,
        contentPadding: EdgeInsets.all(0),
        contentWidget: Container(
            height: 250,
            decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(10.0)),
            child: Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
              Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                    Image.asset('images/block-i-orange.png'),
                    Padding(
                        padding: EdgeInsets.only(top: 20),
                        //TBD: Appointment - load url and phone from the config or other resource. And also apply image and hyperlink
                        child: Text(
                            Localization().getStringEx('panel.wellness.appointments.home.reschedule_appointment.alert.description',
                                'To cancel an appointment, go to MyMcKinley.illinois.edu or call (217-333-2700) during business hours. To avoid a missed appointment charge, you must cancel your appointment at least two hours prior to your scheduled appointment time.'),
                            textAlign: TextAlign.center,
                            style: Styles().textStyles?.getTextStyle("widget.detail.small")))
                  ])),
              Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                      onTap: _onTapCloseReschedulePopup,
                      child: Padding(padding: EdgeInsets.all(16), child: Image.asset('images/icon-x-orange.png'))))
            ])));
  }

  void _onTapCloseReschedulePopup() {
    Analytics().logSelect(target: 'Close reschedule appointment popup');
    Navigator.of(context).pop();
  }

  void _loadAppointments() {
    //TBD: Appointments - load with real data
    _upcomingAppointments = Appointment.listFromJson(JsonUtils.decodeList(
        '[{"id":"08c122e3-2174-438b-94d4-f231198c26ba","uin":"2222","date_time":"2022-12-01T07:30:444Z","type":"InPerson","location":{"id":"555555","title":"McKinley Health Center, East wing, 3rd floor","latitude":0,"longitude":0,"phone":"555-333-777"},"cancelled":false,"instructions":"Some instructions 1 ...","host":{"first_name":"John","last_name":"Doe"}},{"id":"08c122e3-2174-438b-f231198c26ba","uin":"3333","date_time":"2022-12-02T08:22:444Z","type":"Online","online_details":{"url":"https://mymckinley.illinois.edu","meeting_id":"asdasd","meeting_passcode":"passs"},"location":{"id":"6666","title":"McKinley Health Center 2, West wing, 1st floor","latitude":0,"longitude":0,"phone":"555-666-777"},"cancelled":false,"instructions":"Some instructions 2 ...","host":{"first_name":"JoAnn","last_name":"Doe"}}]'));
    _pastAppointments = Appointment.listFromJson(JsonUtils.decodeList(
        '[{"id":"2174-438b-94d4-f231198c26ba","uin":"4444","date_time":"2022-10-01T10:30:444Z","type":"InPerson","location":{"id":"777","title":"McKinley Health Center 8, South wing, 2nd floor","latitude":0,"longitude":0,"phone":"555-444-777"},"cancelled":false,"instructions":"Some instructions 3 ...","host":{"first_name":"Bill","last_name":""}},{"id":"08c122e3","uin":"88888","date_time":"2022-10-05T11:34:444Z","type":"Online","online_details":{"url":"https://mymckinley.illinois.edu","meeting_id":"09jj","meeting_passcode":"dfkj3940"},"location":{"id":"9999","title":"McKinley Health Center 9, North wing, 4th floor","latitude":0,"longitude":0,"phone":"555-5555-777"},"cancelled":false,"instructions":"Some instructions 4 ...","host":{"first_name":"Peter","last_name":"Grow"}}]'));
  }
}
