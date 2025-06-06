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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:illinois/ui/appointments/AppointmentCard.dart';
import 'package:illinois/ui/widgets/AccessWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/flex_ui.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessAppointmentsContentWidget extends StatefulWidget {
  WellnessAppointmentsContentWidget();

  @override
  State<WellnessAppointmentsContentWidget> createState() => _WellnessAppointmentsContentWidgetState();
}

class _WellnessAppointmentsContentWidgetState extends State<WellnessAppointmentsContentWidget> with NotificationsListener {
  List<Appointment>? _upcomingAppointments;
  List<Appointment>? _pastAppointments;
  late bool _appointmentsCanDisplay;
  int _loadingProgress = 0;

  @override
  void initState() {
    NotificationService().subscribe(this, [Storage.notifySettingChanged, FlexUI.notifyChanged, Appointments.notifyUpcomingAppointmentsChanged, Appointments.notifyPastAppointmentsChanged]);
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
      return Column(mainAxisSize: MainAxisSize.min, children: [ accessWidget ],);
    }
    else if (!_appointmentsCanDisplay) {
      return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildRescheduleDescription(), _buildNothingToDisplayMsg(), _buildDisplayAppointmentsSettings()]));
    } else if (_isLoading) {
      return _buildLoadingContent();
    } else {
      return RefreshIndicator(
          onRefresh: _onPullToRefresh,
          child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  style: Styles().textStyles.getTextStyle( "panel.wellness_appointments.button.title.underline"),
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
    String emptyUpcommingContentHtml = Localization().getStringEx("panel.wellness.appointments.home.upcoming.list.empty.msg", //localize
        "<p>You currently have no upcoming appointments linked within the Illinois app.<p> New appointments made via <a href='{{mckinley_url}}'>{{mckinley_url_label}}</a>&nbsp;<img src='asset:{{external_link_icon}}' alt=''/> may take up to 20 minutes to appear in the {{app_title}} app.");
    emptyUpcommingContentHtml = emptyUpcommingContentHtml.replaceAll(urlMacro, Config().saferMcKinleyUrl ?? '');
    emptyUpcommingContentHtml = emptyUpcommingContentHtml.replaceAll(urlLabelMacro, Config().saferMcKinleyUrlLabel ?? '');
    emptyUpcommingContentHtml = emptyUpcommingContentHtml.replaceAll(externalLinkIconMacro, 'images/external-link.png');
    emptyUpcommingContentHtml = emptyUpcommingContentHtml.replaceAll(appTitleMacro, Localization().getStringEx('app.title', 'Illinois'));
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child:
        HtmlWidget(
            "<div style=text-align:left> $emptyUpcommingContentHtml </div>",
            onTapUrl : (url) {_onTapSaferMcKinleyUrl(url); return true;},
            textStyle:  Styles().textStyles.getTextStyle("widget.title.medium"),
            customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorPrimary)} : null
        )
    );
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
                      style: Styles().textStyles.getTextStyle( "panel.wellness_appointments.title.large"),
                     ))
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
            textAlign: TextAlign.left,
            style:Styles().textStyles.getTextStyle("widget.message.medium.thin")));
  }

  Widget _buildPastAppointmentsDescription() {
    String descriptionText = Localization().getStringEx("panel.wellness.appointments.home.past_appointments.footer.description",
      "View a full history of past appointments at {{mckinley_url_label}}.").
        replaceAll('{{mckinley_url_label}}', Config().saferMcKinleyUrlLabel ?? '');
    return Padding(padding: EdgeInsets.only(top: 8), child:
      _buildLinkDetail(descriptionText,
        iconKey: 'external-link',
        onTap: () => _onTapSaferMcKinleyUrl(Config().saferMcKinleyUrl)
      ),
    );
  }

  List<Widget> _buildAppointmentsWidgetList(List<Appointment>? appointments) {
    List<Widget> widgets = <Widget>[];
    if (CollectionUtils.isNotEmpty(appointments)) {
      for (int i = 0; i < appointments!.length; i++) {
        Appointment appointment = appointments[i];
        widgets.add(Padding(padding: EdgeInsets.only(top: 16), child: AppointmentCard(appointment: appointment, analyticsFeature: AnalyticsFeature.WellnessAppointments,)));
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
            style:  Styles().textStyles.getTextStyle("widget.message.medium.semi_thin")));
  }

  Widget _buildDisplayAppointmentsSettings() {
    String buttonTitle = _appointmentsCanDisplay
        ? Localization().getStringEx('panel.wellness.appointments.home.display.settings.off.label', "Don't Display My Appointments")
        : Localization().getStringEx('panel.wellness.appointments.home.display.settings.on.label', 'Display My Appointments');
    return _buildLinkDetail(buttonTitle, iconKey: 'settings', onTap: _onTapDisplaySettings);
  }

  Widget _buildLinkDetail(String? text, { String? iconKey, void Function()? onTap, String? semanticsLabel, String? semanticsHint, }) =>
    Semantics(label: semanticsLabel ?? text, hint: semanticsHint, button: true, child:
      InkWell(onTap: onTap, child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (iconKey != null)
            Padding(padding: EdgeInsets.only(right: 5, top: 12, bottom: 12), child:
              Styles().images.getImage(iconKey, excludeFromSemantics: true)),
          Expanded(child:
            Padding(padding: EdgeInsets.only(top: 8), child:
              Text(text ?? '', style: Styles().textStyles.getTextStyle('widget.button.title.medium.underline'), semanticsLabel: "",)
            )
          )
        ])
      ),
    );

  void _showRescheduleAppointmentPopup() =>
      showDialog(
      context: context,
      builder: _buildRescheduleAppointmentPopup,
    );

  Widget _buildRescheduleAppointmentPopup(BuildContext context) {
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


    return ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child:
      Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),), backgroundColor: Styles().colors.white, child:
        Column(mainAxisSize: MainAxisSize.min, children: [
          Align(alignment: Alignment.centerRight, child:
            InkWell(onTap: _onTapCloseReschedulePopup, child:
              Padding(padding: EdgeInsets.all(16), child:
                Styles().images.getImage('close-circle', excludeFromSemantics: true),
              )
            )
          ),
          Styles().images.getImage('university-logo') ?? Container(),
          Padding(padding: EdgeInsets.all(24), child:
            HtmlWidget(
              rescheduleContentHtml,
              onTapUrl : (url) {_onTapSaferMcKinleyUrl(url); return true;},
              textStyle:  Styles().textStyles.getTextStyle("widget.message.small"),
              customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorPrimary)} : null
            )
          )
        ])
      ),
    );
  }

  Future<void> _onPullToRefresh() async {
    await Appointments().refreshAppointments();
  }

  void _onTapCloseReschedulePopup() {
    Analytics().logSelect(target: 'Close reschedule appointment popup');
    Navigator.of(context).pop();
  }

  void _onTapSaferMcKinleyUrl(String? url) async {
    Analytics().logSelect(target: Config().saferMcKinleyUrlLabel ?? 'Url: $url');
    if (StringUtils.isNotEmpty(url)) {
      Uri? uri = Uri.tryParse(url!);
      if ((uri != null) && (await canLaunchUrl(uri))) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _onTapDisplaySettings() {
    Analytics().logSelect(target: 'Appointments display settings');
    SettingsHomePanel.present(context, content: SettingsContentType.appointments);
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
    _loadPastAppointments();
    _loadUpcomingAppointments();
  }

  void _loadUpcomingAppointments() {
    if (_appointmentsCanDisplay) {
      _increaseProgress();
      _upcomingAppointments = Appointments().getAppointments(timeSource: AppointmentsTimeSource.upcoming);
      _decreaseProgress();
    }
  }

  void _loadPastAppointments() {
    if (_appointmentsCanDisplay) {
      _increaseProgress();
      _pastAppointments = Appointments().getAppointments(timeSource: AppointmentsTimeSource.past);
      _decreaseProgress();
    }
  }

  bool get _isLoading {
    return (_loadingProgress > 0);
  }

  void _increaseProgress() {
    setStateIfMounted(() {
      _loadingProgress++;
    });
  }

  void _decreaseProgress() {
    setStateIfMounted(() {
      _loadingProgress--;
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
    } else if (name == Appointments.notifyUpcomingAppointmentsChanged) {
      _loadUpcomingAppointments();
    } else if (name == Appointments.notifyPastAppointmentsChanged) {
      _loadPastAppointments();
    }
  }
}
