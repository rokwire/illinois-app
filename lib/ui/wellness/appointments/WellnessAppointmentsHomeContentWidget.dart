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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class WellnessAppointmentsHomeContentWidget extends StatefulWidget {
  WellnessAppointmentsHomeContentWidget();

  @override
  State<WellnessAppointmentsHomeContentWidget> createState() => _WellnessAppointmentsHomeContentWidgetState();
}

class _WellnessAppointmentsHomeContentWidgetState extends State<WellnessAppointmentsHomeContentWidget> {
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
    return Column(children: [_buildAppointmentCard(), _buildAppointmentCard()]);
  }

  Widget _buildPastAppointments() {
    return Column(children: [_buildAppointmentCard(), _buildAppointmentCard()]);
  }

  Widget _buildAppointmentCard() {
    return InkWell(
        onTap: _onTapAppointmentCard,
        child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            child: Stack(children: [
              Container(
                  decoration: BoxDecoration(
                      color: Styles().colors!.surface,
                      border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                              child:
                                  //TBD: Appointment - fill with real data
                                  Text('MyMcKinley Appointments'.toUpperCase(),
                                      style: TextStyle(
                                              color: Styles().colors?.textBackground,
                                              fontFamily: Styles().fontFamilies?.semiBold,
                                              fontSize: 14)))
                        ]),
                        Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Row(children: [
                              Expanded(
                                  child:
                                      //TBD: Appointment - fill with real data
                                      Text('MyMcKinley Appointment',
                                          style: TextStyle(
                                          color: Styles().colors?.fillColorPrimary,
                                          fontFamily: Styles().fontFamilies?.extraBold,
                                          fontSize: 20)))
                            ])),
                        Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Row(children: [
                              Padding(padding: EdgeInsets.only(right: 6), child: Image.asset('images/icon-calendar.png')),
                              Expanded(
                                  child:
                                      //TBD: Appointment - fill with real data
                                      Text('Sep 2, 10:00 AM',
                                          style: TextStyle(
                                              color: Styles().colors?.textBackground,
                                              fontFamily: Styles().fontFamilies?.medium,
                                              fontSize: 16)))
                            ])),
                        Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Row(children: [
                              Padding(padding: EdgeInsets.only(right: 6), child: Image.asset('images/icon-location.png')),
                              Expanded(
                                  child:
                                      //TBD: Appointment - fill with real data - telehealth vs in person
                                      Text('In person',
                                          style: TextStyle(
                                              color: Styles().colors?.textBackground,
                                              fontFamily: Styles().fontFamilies?.medium,
                                              fontSize: 16)))
                            ]))
                      ]))),
              //TBD: Appointment - fill with real data - define upcoming vs past and respective color
              Container(color: Styles().colors?.fillColorSecondary, height: 4)
            ])));
  }

  //TBD: DD draw popup
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

  void _onTapAppointmentCard() {
    //TBD: Appointment - implement
  }
}
