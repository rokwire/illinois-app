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
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentCard.dart';
import 'package:illinois/ui/widgets/AccessWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/flex_ui.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessAppointmentsHomeContentWidget extends StatefulWidget {
  WellnessAppointmentsHomeContentWidget();

  @override
  State<WellnessAppointmentsHomeContentWidget> createState() => _WellnessAppointmentsHomeContentWidgetState();
}

class _WellnessAppointmentsHomeContentWidgetState extends State<WellnessAppointmentsHomeContentWidget> implements NotificationsListener {
  List<Appointment>? _upcomingAppointments;
  List<Appointment>? _pastAppointments;
  late bool _appointmentsCanDisplay;
  bool _loading = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [Storage.notifySettingChanged, FlexUI.notifyChanged, Appointments.notifyAppointmentsChanged]);
    _initAppointments();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    Widget? accessWidget = AccessCard.builder(resource: 'wellness.appointments');
    if (accessWidget != null) {
      return accessWidget;
    }
    else if (!_appointmentsCanDisplay) {
      return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildRescheduleDescription(), _buildNothingToDisplayMsg(), _buildDisplayAppointmentsSettings()]));
    } else if (_loading) {
      return _buildLoadingContent();
    } else {
      return RefreshIndicator(onRefresh: _onPullToRefresh, child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ListView(physics: AlwaysScrollableScrollPhysics(), shrinkWrap: true, children: [
            _buildRescheduleDescription(),
            _buildUpcomingAppointments(),
            _buildPastAppointments(),
            _buildDisplayAppointmentsSettings()
          ])));
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
    String? label =
        Localization().getStringEx('panel.wellness.appointments.home.reschedule_appointment.label', 'Need to cancel or reschedule?');
    return Semantics(
        label: label,
        button: true,
        child: InkWell(
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
    final String urlLabelMacro = '{{mckinley_url_label}}';
    final String urlMacro = '{{mckinley_url}}';
    final String externalLinkIconMacro = '{{external_link_icon}}';
    final String appTitleMacro = '{{app_title}}';
    String emptyUpcommingContentHtml = Localization().getStringEx("panel.wellness.appointments.home.upcoming.list.empty.msg",
        "You currently have no upcoming appointments linked within the Illinois app. New appointments made via <a href='{{mckinley_url}}'>{{mckinley_url_label}}</a>&nbsp;<img src='asset:{{external_link_icon}}' alt=''/> may take up to 20 minutes to appear in the {{app_title}} app.");
    emptyUpcommingContentHtml = emptyUpcommingContentHtml.replaceAll(urlMacro, Config().saferMcKinleyUrl ?? '');
    emptyUpcommingContentHtml = emptyUpcommingContentHtml.replaceAll(urlLabelMacro, Config().saferMcKinleyUrlLabel ?? '');
    emptyUpcommingContentHtml = emptyUpcommingContentHtml.replaceAll(externalLinkIconMacro, 'images/external-link.png');
    emptyUpcommingContentHtml = emptyUpcommingContentHtml.replaceAll(appTitleMacro, Localization().getStringEx('app.title', 'Illinois'));
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Html(data: emptyUpcommingContentHtml, onLinkTap: (url, renderContext, attributes, element) => _onTapMcKinleyUrl(url), style: {
          "body": Style(
              textAlign: TextAlign.center,
              color: Styles().colors!.fillColorPrimary,
              fontFamily: Styles().fontFamilies!.regular,
              fontSize: FontSize(18),
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero),
          "a": Style(color: Styles().colors?.fillColorPrimary)
        }));
  }

  Widget _buildPastAppointments() {
    List<Widget> pastAppointmentsWidgetList = <Widget>[];
    pastAppointmentsWidgetList.add(Padding(
        padding: EdgeInsets.only(top: 16),
        child: Semantics(
            header: true,
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Expanded(
                  child: Text(
                      Localization()
                          .getStringEx('panel.wellness.appointments.home.past_appointments.header.label', 'Recent Past Appointments'),
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: Styles().colors!.blackTransparent06, fontSize: 22, fontFamily: Styles().fontFamilies!.extraBold)))
            ]))));
    if (CollectionUtils.isEmpty(_pastAppointments)) {
      pastAppointmentsWidgetList.add(_buildEmptyPastAppointments());
    } else {
      pastAppointmentsWidgetList.addAll(_buildAppointmentsWidgetList(_pastAppointments));
      pastAppointmentsWidgetList.add(_buildPastAppointmentsDescription());
    }
    return Column(children: pastAppointmentsWidgetList);
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
        widgets.add(Padding(padding: EdgeInsets.only(top: 16), child: AppointmentCard(appointment: appointment)));
      }
    }
    return widgets;
  }

  Widget _buildNothingToDisplayMsg() {
    return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text(
            Localization().getStringEx('panel.wellness.appointments.home.display.nothing.msg',
                'There is nothing to display as you have chosen not to display any past or future appointments.'),
            textAlign: TextAlign.start,
            style: TextStyle(fontSize: 18, color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.medium)));
  }

  Widget _buildDisplayAppointmentsSettings() {
    String buttonTitle = _appointmentsCanDisplay
        ? Localization().getStringEx('panel.wellness.appointments.home.display.settings.off.label', "Don't Display My Appointments")
        : Localization().getStringEx('panel.wellness.appointments.home.display.settings.on.label', 'Display My Appointments');
    return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: InkWell(
            onTap: _onTapDisplaySettings,
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.start, children: [
              Padding(padding: EdgeInsets.only(right: 5), child: Styles().images?.getImage('settings', excludeFromSemantics: true)),
              LinkButton(title: buttonTitle, padding: EdgeInsets.zero)
            ])));
  }

  void _showRescheduleAppointmentPopup() {
    final String urlLabelMacro = '{{mckinley_url_label}}';
    final String urlMacro = '{{mckinley_url}}';
    final String externalLinkIconMacro = '{{external_link_icon}}';
    final String phoneMacro = '{{mckinley_phone}}';
    String rescheduleContentHtml = Localization().getStringEx("panel.wellness.appointments.home.reschedule_appointment.alert.description",
        "<p>To cancel an appointment, go to  <a href='{{mckinley_url}}'>{{mckinley_url_label}}</a>&nbsp;<img src='asset:{{external_link_icon}}' alt=''/> or call <a href='tel:{{mckinley_phone}}'>(<u>{{mckinley_phone}}</u>)</a> during business hours. To avoid a missed appointment charge, you must cancel your appointment at least two hours prior to your scheduled appointment time.</p><p>Cancellations and appointment changes may take up to 20 minutes to appear in the Illinois app. The two-hour cancellation fee will be based on the time you cancel via  <a href='{{mckinley_url}}'>{{mckinley_url_label}}</a>&nbsp;<img src='asset:{{external_link_icon}}' alt=''/>.</p>");
    rescheduleContentHtml = rescheduleContentHtml.replaceAll(urlMacro, Config().saferMcKinleyUrl ?? '');
    rescheduleContentHtml = rescheduleContentHtml.replaceAll(urlLabelMacro, Config().saferMcKinleyUrlLabel ?? '');
    rescheduleContentHtml = rescheduleContentHtml.replaceAll(externalLinkIconMacro, 'images/external-link.png');
    rescheduleContentHtml = rescheduleContentHtml.replaceAll(phoneMacro, Config().saferMcKinleyPhone ?? '');
    AppAlert.showCustomDialog(
        context: context,
        contentPadding: EdgeInsets.all(0),
        contentWidget: Container(
            decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(10.0)),
            child: Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
              Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                    Styles().images?.getImage('university-logo') ?? Container(),
                    Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Html(
                            data: rescheduleContentHtml,
                            onLinkTap: (url, renderContext, attributes, element) => _onTapMcKinleyUrl(url),
                            style: {
                              "body": Style(
                                  color: Styles().colors!.fillColorPrimary,
                                  fontFamily: Styles().fontFamilies!.regular,
                                  fontSize: FontSize(14),
                                  padding: EdgeInsets.zero,
                                  margin: EdgeInsets.zero),
                              "a": Style(color: Styles().colors?.fillColorPrimary)
                            }))
                  ])),
              Positioned.fill(child: Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                      onTap: _onTapCloseReschedulePopup,
                      child: Padding(padding: EdgeInsets.all(16), child: Styles().images?.getImage('close', excludeFromSemantics: true)))))
            ])));
  }

  Future<void> _onPullToRefresh() async {
    await Appointments().refreshAppointments();
  }

  void _onTapCloseReschedulePopup() {
    Analytics().logSelect(target: 'Close reschedule appointment popup');
    Navigator.of(context).pop();
  }

  void _onTapMcKinleyUrl(String? url) async {
    Analytics().logSelect(target: 'McKinley Url');
    if (StringUtils.isNotEmpty(url)) {
      Uri? uri = Uri.tryParse(url!);
      if ((uri != null) && (await canLaunchUrl(uri))) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _onTapDisplaySettings() {
    Analytics().logSelect(target: 'Appointments display settings');
    SettingsHomeContentPanel.present(context, content: SettingsContent.appointments);
  }

  void _initAppointments() {
    _appointmentsCanDisplay = Storage().appointmentsCanDisplay ?? false;
    if (_appointmentsCanDisplay) {
      _loadAppointments();
    } else {
      setStateIfMounted(() {});
    }
  }

  void _loadAppointments() {
    if (_appointmentsCanDisplay) {
      _setLoading(true);
      Appointments().refreshAppointments().then((_) {
        List<Appointment>? appointments = Appointments().getAppointments();
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
  }

  void _setLoading(bool loading) {
    setStateIfMounted(() {
      _loading = loading;
    });
  }

  @override
  void onNotification(String name, param) {
    if (name == Storage.notifySettingChanged) {
      if (param == Storage().appointmentsDisplayEnabledKey) {
        _initAppointments();
      }
    } else if (name == FlexUI.notifyChanged) {
      if (mounted) {
        setState(() {});
      }
    } else if (name == Appointments.notifyAppointmentsChanged) {
      _loadAppointments();
    }
  }
}
