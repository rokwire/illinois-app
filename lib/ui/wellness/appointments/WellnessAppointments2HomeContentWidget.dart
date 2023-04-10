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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentCard.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentSchedulePanel.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentScheduleUnitPanel.dart';
import 'package:illinois/ui/widgets/AccessWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessAppointments2HomeContentWidget extends StatefulWidget {
  WellnessAppointments2HomeContentWidget();

  @override
  State<WellnessAppointments2HomeContentWidget> createState() => _WellnessAppointments2HomeContentWidgetState();
}

class _WellnessAppointments2HomeContentWidgetState extends State<WellnessAppointments2HomeContentWidget> implements NotificationsListener {

  List<AppointmentProvider>? _providers;
  bool _isLoadingProviders = false;

  AppointmentProvider? _selectedProvider;
  bool _isProvidersExpanded = false;

  List<Appointment>? _upcomingAppointments;
  List<Appointment>? _pastAppointments;
  bool _isLoadingAppointments = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Appointments.notifyAppointmentsChanged
    ]);
    _initProviders();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener
  @override
  void onNotification(String name, param) {
    if (name == Appointments.notifyAppointmentsChanged) {
      _loadAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? accessWidget = AccessCard.builder(resource: 'wellness.appointments');
    if (accessWidget != null) {
      return accessWidget;
    }
    else if (_isLoadingProviders) {
      return _buildLoadingContent();
    }
    else if (_providers == null) {
      return _buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.providers.failed', 'Failed to load providers'));
    }
    else if (_providers?.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.providers.empty', 'No providers available'));
    }
    else if (_providers?.length == 1) {
      return Column(children: [
        Padding(padding: EdgeInsets.only(bottom: 2), child:
          Text(_providers?.first.name ?? '', style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'))
        ),
        _buildAppointmentsContent(),
      ]);
    }
    else {
      return Column(children: [
        _buildProvidersDropdown(),
        Expanded(child:
          Stack(children: [
            Padding(padding: EdgeInsets.only(top: 16), child:
              _buildAppointmentsContent()
            ),
            _buildProvidersDropdownContainer()
          ],)
          
        )
      ],);
    }
  }

  Widget _buildProvidersDropdown() {
    return Padding(padding: EdgeInsets.only(left: 16, right: 16), child:
      Semantics(hint: Localization().getStringEx("dropdown.hint", "DropDown"), container: true, child:
        RibbonButton(
          textColor: Styles().colors!.fillColorSecondary,
          backgroundColor: Styles().colors!.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
          border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
          rightIconKey: _isProvidersExpanded ? 'chevron-up' : 'chevron-down',
          label: (_selectedProvider != null) ? (_selectedProvider?.name ?? '') : Localization().getStringEx('panel.wellness.appointments2.home.label.providers.all', 'All Providers'),
          onTap: _onProvidersDropdown
        )
      )
    );
  }

  Widget _buildProvidersDropdownContainer() {
    return Visibility(visible: _isProvidersExpanded, child:
      Positioned.fill(child:
        Stack(children: <Widget>[
          _buildProvidersDropdownDismissLayer(),
          _buildProvidersDropdownItems()
        ])
      )
    );
  }

  Widget _buildProvidersDropdownDismissLayer() {
    return Positioned.fill(child:
      BlockSemantics(child:
        GestureDetector(onTap: _onDismissProvidersDropdown, child:
          Container(color: Styles().colors!.blackTransparent06)
        )
      )
    );
  }

  Widget _buildProvidersDropdownItems() {
    List<Widget> items = <Widget>[];
    items.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));

    if (_providers != null) {
      items.add(RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconKey: null,
        label: Localization().getStringEx('panel.wellness.appointments2.home.label.providers.all', 'All Providers'),
        onTap: () => _onTapProvider(null)
      ));

      for (AppointmentProvider provider in _providers!) {
        items.add(RibbonButton(
          backgroundColor: Styles().colors!.white,
          border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
          rightIconKey: null,
          label: provider.name,
          onTap: () => _onTapProvider(provider)
        ));
      }
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: items)
      )
    );
  }

  void _onProvidersDropdown() {
    setStateIfMounted(() {
      _isProvidersExpanded = !_isProvidersExpanded;
    });
  }

  void _onDismissProvidersDropdown() {
    setStateIfMounted(() {
      _isProvidersExpanded = false;
    });
  }

  void _onTapProvider(AppointmentProvider? provider) {
    Analytics().logSelect(target: (provider != null) ? provider.name : 'All Providers');
    setStateIfMounted(() {
      _isProvidersExpanded = false;
      _selectedProvider = provider;
      Storage().selectedAppointmentProviderId = provider?.id;
    });
    _loadAppointments();
  }

  Widget _buildAppointmentsContent() {
    //if (_selectedProvider == null) {
    //  return _buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.provider.empty', 'No selected provider'));
    //}
    if (_isLoadingAppointments) {
      return _buildLoadingContent();
    }
    else {
      return RefreshIndicator(onRefresh: _onPullToRefresh, child:
        SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), padding: EdgeInsets.symmetric(horizontal: 16), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildScheduleDescription(),
            ..._buildAppointmentsList(),
            Container(height: 24) // Ensures width for providers dropdown container
          ])
        )
      );
    }
  }

  List<Widget> _buildAppointmentsList() {
    if ((_upcomingAppointments == null) || (_pastAppointments == null)) {
      return <Widget>[_buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.appointments.failed', 'Failed to load appointments'))];
    }
    else  {
      List<Widget> contentList = <Widget>[];

      if (_upcomingAppointments?.length == 0) {
        contentList.add(_buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.appointments.upcoming.empty', 'No upcoming appointments for selected provider(s)')));
      }
      else {
        for (Appointment appointment in _upcomingAppointments!) {
          contentList.add(Padding(padding: EdgeInsets.only(top: 16), child:
            AppointmentCard(appointment: appointment)
          ));
        }
      }

          

      if (_upcomingAppointments?.length == 0) {
        contentList.add(_buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.appointments.past.empty', 'No past appointments for selected provider(s)')));
      }
      if (_pastAppointments?.length != 0) {
        contentList.add(Padding(padding: EdgeInsets.only(top: 16), child:
          Text(Localization().getStringEx('panel.wellness.appointments.home.past_appointments.header.label', 'Recent Past Appointments'), textAlign: TextAlign.left, style: Styles().textStyles?.getTextStyle( "panel.wellness_appointments.title.large"),)
        ),);

        for (Appointment appointment in _pastAppointments!) {
          contentList.add(Padding(padding: EdgeInsets.only(top: 16), child:
            AppointmentCard(appointment: appointment)
          ));
        }
      }

      return contentList;
    }
  }

  Widget _buildLoadingContent() {
    return Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3,),
      )
    );
  }

  Widget _buildMessageContent(String message) {
    return Center(child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32), child:
        Text(message, style: Styles().textStyles?.getTextStyle('widget.item.medium.fat'),)
      )
    );
  }

  Widget _buildScheduleDescription() {
    String descriptionHtml = Localization().getStringEx('panel.wellness.appointments.home.schedule_appointment.label', '<a href={{schedule_url}}>Schedule an appointment</a>');
    return HtmlWidget(descriptionHtml,
      onTapUrl : _onDesciptionLink,
      textStyle:  Styles().textStyles?.getTextStyle("widget.message.medium"),
      customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors!.fillColorSecondary!) } : null
    );
  }

  bool _onDesciptionLink(String url) {
    if (url == '{{schedule_url}}') {
      _onScheduleAppointment();
    }
    return true;
  }

  void _initProviders() {
    setStateIfMounted(() {
      _isLoadingProviders = true;
    });
    Appointments().loadProviders().then((List<AppointmentProvider>? result) {
      setStateIfMounted(() {
        _providers = result;
        _isLoadingProviders = false;
        _updateSelectedProvder();
      });
      _loadAppointments();
    });
  }

  void _updateSelectedProvder() {
    if ((_providers == null) || _providers!.isEmpty) {
      _selectedProvider = null;  
    }
    else if (_providers!.length == 1) {
      _selectedProvider = _providers!.first;  
    }
    else {
      _selectedProvider = AppointmentProvider.findInList(_providers, id: Storage().selectedAppointmentProviderId);
    }
  }

  void _loadAppointments() {
    setStateIfMounted(() {
      _isLoadingAppointments = true;
    });
    Appointments().loadAppointments(providerId: _selectedProvider?.id, tmpProviders: _providers).then((List<Appointment>? result) {
      setStateIfMounted(() {
        _buildAppointments(result);
        _isLoadingAppointments = false;
      });
    });
  }

  void _buildAppointments(List<Appointment>? appointments) {
    _upcomingAppointments = _pastAppointments = null;
    if (appointments != null) {
      _upcomingAppointments = <Appointment>[];
      _pastAppointments = <Appointment>[];

      DateTime nowUtc = DateTime.now().toUtc();
      for (Appointment appointment in appointments) {
        List<Appointment>? targetList = ((appointment.dateTimeUtc == null) || nowUtc.isBefore(appointment.dateTimeUtc!)) ? _upcomingAppointments : _pastAppointments;
        targetList?.add(appointment);
      }

      _upcomingAppointments?.sort((Appointment appointment1, Appointment appointment2) =>
        SortUtils.compare(appointment1.dateTimeUtc, appointment2.dateTimeUtc, descending: false)
      );

      _pastAppointments?.sort((Appointment appointment1, Appointment appointment2) =>
        SortUtils.compare(appointment1.dateTimeUtc, appointment2.dateTimeUtc, descending: true)
      );
    }
  }

  void _onScheduleAppointment() {
    //AppointmentSchedulePanel.present(context);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentScheduleUnitPanel(
      scheduleParam: AppointmentScheduleParam(
        providers: _providers,
        provider: _selectedProvider,
      ),
      onFinish: (BuildContext context, Appointment? appointment) => Navigator.of(context).popUntil((route) => route.isFirst),
    )));
  }

  Future<void> _onPullToRefresh() async {
    _initProviders();
  }


}
