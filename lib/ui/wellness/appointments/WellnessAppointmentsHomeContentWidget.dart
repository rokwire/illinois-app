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
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentCard.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessAppointmentsHomeContentWidget extends StatefulWidget {
  WellnessAppointmentsHomeContentWidget();

  @override
  State<WellnessAppointmentsHomeContentWidget> createState() => _WellnessAppointmentsHomeContentWidgetState();
}

class _WellnessAppointmentsHomeContentWidgetState extends State<WellnessAppointmentsHomeContentWidget> {
  List<Appointment>? _upcomingAppointments;
  List<Appointment>? _pastAppointments;
  bool _loading = false;

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
    if (_loading) {
      return _buildLoadingContent();
    } else {
      return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildRescheduleDescription(), _buildUpcomingAppointments(), _buildPastAppointments()]));
    }
  }

  Widget _buildLoadingContent() {
    return Center(
        child: Column(children: <Widget>[
      Container(height: MediaQuery.of(context).size.height / 5),
      CircularProgressIndicator(),
      Container(height: MediaQuery.of(context).size.height / 5 * 3)
    ]));
  }

  Widget _buildRescheduleDescription() {
    String? label =  Localization().getStringEx('panel.wellness.appointments.home.reschedule_appointment.label', 'Need to cancel or reschedule?');
    return Semantics(
        label: label,
        button: true,
        child:InkWell(
        child: Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
                label,
                style: TextStyle(
                    fontSize: 18,
                    color: Styles().colors!.fillColorPrimary,
                    fontFamily: Styles().fontFamilies!.regular,
                    decoration: TextDecoration.underline,
                    decorationThickness: 1,
                    decorationColor: Styles().colors!.fillColorPrimary),
                  semanticsLabel: "",
            )),
        onTap: _showRescheduleAppointmentPopup));
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
          child: Semantics(
              header: true,
              child:Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            Expanded(
                child: Text(
                    Localization()
                        .getStringEx('panel.wellness.appointments.home.past_appointments.header.label', 'Recent Past Appointments'),
                    textAlign: TextAlign.left,
                    style:
                        TextStyle(color: Styles().colors!.blackTransparent06, fontSize: 22, fontFamily: Styles().fontFamilies!.extraBold)))
          ]))));
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
    final String urlLabelMacro = '{{mckinley_url_label}}';
    final String urlMacro = '{{mckinley_url}}';
    final String externalLinkIconMacro = '{{external_link_icon}}';
    String descriptionHtml = Localization().getStringEx("panel.wellness.appointments.home.past_appointments.footer.description",
        "<a href='{{mckinley_url}}'>Visit {{mckinley_url_label}} to view a full history of past appointments.</a>&nbsp;<img src='asset:{{external_link_icon}}' alt=''/>");
    descriptionHtml = descriptionHtml.replaceAll(urlMacro, Config().saferMcKinleyUrl ?? '');
    descriptionHtml = descriptionHtml.replaceAll(urlLabelMacro, Config().saferMcKinleyUrlLabel ?? '');
    descriptionHtml = descriptionHtml.replaceAll(externalLinkIconMacro, 'images/external-link.png');
    return Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 16),
        child: Html(data: descriptionHtml, onLinkTap: (url, renderContext, attributes, element) => _onTapMcKinleyUrl(url), style: {
          "body": Style(
              textAlign: TextAlign.center,
              color: Styles().colors!.fillColorPrimary,
              fontFamily: Styles().fontFamilies!.regular,
              fontSize: FontSize(16),
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero),
          "a": Style(color: Styles().colors?.fillColorPrimary)
        }));
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
    final String urlLabelMacro = '{{mckinley_url_label}}';
    final String urlMacro = '{{mckinley_url}}';
    final String externalLinkIconMacro = '{{external_link_icon}}';
    final String phoneMacro = '{{mckinley_phone}}';
    String rescheduleContentHtml = Localization().getStringEx("panel.wellness.appointments.home.reschedule_appointment.alert.description",
        "To cancel an appointment, go to  <a href='{{mckinley_url}}'>{{mckinley_url_label}}</a>&nbsp;<img src='asset:{{external_link_icon}}' alt=''/> or call (<u>{{mckinley_phone}}</u>) during business hours. To avoid a missed appointment charge, you must cancel your appointment at least two hours prior to your scheduled appointment time.");
    rescheduleContentHtml = rescheduleContentHtml.replaceAll(urlMacro, Config().saferMcKinleyUrl ?? '');
    rescheduleContentHtml = rescheduleContentHtml.replaceAll(urlLabelMacro, Config().saferMcKinleyUrlLabel ?? '');
    rescheduleContentHtml = rescheduleContentHtml.replaceAll(externalLinkIconMacro, 'images/external-link.png');
    rescheduleContentHtml = rescheduleContentHtml.replaceAll(phoneMacro, Config().saferMcKinleyPhone ?? '');
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
                        child:
                            Html(data: rescheduleContentHtml, onLinkTap: (url, renderContext, attributes, element) => _onTapMcKinleyUrl(url), style: {
                          "body": Style(
                              color: Styles().colors!.fillColorPrimary,
                              fontFamily: Styles().fontFamilies!.regular,
                              fontSize: FontSize(14),
                              padding: EdgeInsets.zero,
                              margin: EdgeInsets.zero),
                          "a": Style(color: Styles().colors?.fillColorPrimary)
                        }))
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

  void _onTapMcKinleyUrl(String? url) {
    Analytics().logSelect(target: 'McKinley Url');
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri);
        }
      }
    }
  }

  void _loadAppointments() {
    _setLoading(true);
    Appointments().loadAppointments().then((appointments) {
      if (CollectionUtils.isNotEmpty(appointments)) {
        _upcomingAppointments = <Appointment>[];
        _pastAppointments = <Appointment>[];
        for (Appointment appointment in appointments!) {
          if (appointment.isUpcoming) {
            _upcomingAppointments!.add(appointment);
          } else {
            _pastAppointments!.add(appointment);
          }
        }
      } else {
        _upcomingAppointments = _pastAppointments = null;
      }
      _setLoading(false);
    });
  }

  void _setLoading(bool loading) {
    setState(() {
      _loading = loading;
    });
  }
}
