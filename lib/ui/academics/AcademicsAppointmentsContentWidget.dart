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
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/appointments/AppointmentCard.dart';
import 'package:illinois/ui/appointments/AppointmentSchedulePanel.dart';
import 'package:illinois/ui/appointments/AppointmentScheduleUnitPanel.dart';
import 'package:illinois/ui/widgets/AccessWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AcademicsAppointmentsContentWidget extends StatefulWidget {
  AcademicsAppointmentsContentWidget();

  @override
  State<AcademicsAppointmentsContentWidget> createState() => _AcademicsAppointmentsContentWidgetState();
}

class _AcademicsAppointmentsContentWidgetState extends State<AcademicsAppointmentsContentWidget> implements NotificationsListener {

  List<AppointmentProvider>? _providers;
  bool _isLoadingProviders = false;

  AppointmentProvider? _selectedProvider;
  bool _isProvidersExpanded = false;

  List<Appointment>? _upcomingAppointments;
  List<Appointment>? _pastAppointments;
  Map<String, GlobalKey> _upcomingAppointmentKeys = <String, GlobalKey>{};
  bool _isLoadingAppointments = false;
  Set<void Function()> _didLoadCallbacks = <void Function()>{};

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Appointments.notifyAppointmentsChanged,
      Storage.notifySettingChanged
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
    else if (name == Storage.notifySettingChanged) {
      if (param == Storage.debugUseSampleAppointmentsKey) {
        _initProviders();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? accessWidget = AccessCard.builder(resource: 'academics.appointments', padding: EdgeInsets.zero);
    if (accessWidget != null) {
      return Column(mainAxisSize: MainAxisSize.min, children: [ accessWidget ],);
    }
    else if (_isLoadingProviders) {
      return _buildLoadingContent();
    }
    else if (_providers == null) {
      return _buildMessageContent(Localization().getStringEx('panel.academics.appointments.home.message.providers.failed', 'Failed to load providers.'));
    }
    else if (_providers?.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.academics.appointments.home.message.providers.empty', 'No providers available.'));
    }
    else if (_providers?.length == 1) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.zero, child:
          Text(_providers?.first.name ?? '', style: Styles().textStyles?.getTextStyle('widget.title.large.fat'))
        ),
        _buildAppointmentsContent(),
      ]);
    }
    else {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.only(bottom: 8), child:
          _buildProvidersDropdown(),
        ),
        Expanded(child:
          Stack(children: [
            _buildAppointmentsContent(),
            _buildProvidersDropdownContainer()
          ],)
          
        )
      ],);
    }
  }

  Widget _buildProvidersDropdown() {
    return Semantics(hint: Localization().getStringEx("dropdown.hint", "DropDown"), container: true, child:
      RibbonButton(
        textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.secondary"),
        backgroundColor: Styles().colors!.white,
        borderRadius: BorderRadius.all(Radius.circular(5)),
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconKey: _isProvidersExpanded ? 'chevron-up' : 'chevron-down',
        label: (_selectedProvider != null) ? (_selectedProvider?.name ?? '') : Localization().getStringEx('panel.academics.appointments.home.label.providers.all', 'All Providers'),
        onTap: _onProvidersDropdown
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
        label: Localization().getStringEx('panel.academics.appointments.home.label.providers.all', 'All Providers'),
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
    //  return _buildMessageContent(Localization().getStringEx('panel.academics.appointments.home.message.provider.empty', 'No selected provider.'));
    //}
    if (_isLoadingAppointments) {
      return _buildLoadingContent();
    }
    else {
      return RefreshIndicator(onRefresh: _onPullToRefresh, child:
        SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildScheduleButton(),
            ..._buildAppointmentsList(),
          ])
        )
      );
    }
  }

  List<Widget> _buildAppointmentsList() {
    if ((_upcomingAppointments == null) || (_pastAppointments == null)) {
      return <Widget>[_buildMessageContent(
        Localization().getStringEx('panel.academics.appointments.home.message.appointments.failed', 'Failed to load appointments.'))
      ];
    }
    else  {
      List<Widget> contentList = <Widget>[];

      if (_upcomingAppointments?.length == 0) {
        contentList.add(_buildStatusContent(
          Localization().getStringEx('panel.academics.appointments.home.message.appointments.upcoming.empty', 'You currently have no upcoming appointments linked within the {{app_title}} app. New appointments may take up to 20 minutes to appear in the {{app_title}} app.').
            replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'))
        ));
      }
      else {
        for (Appointment appointment in _upcomingAppointments!) {
          String? appointmentId = appointment.id;
          GlobalKey? appointmentKey = (appointmentId != null) ? (_upcomingAppointmentKeys[appointmentId] ??= GlobalKey()) : null;
          contentList.add(Padding(padding: EdgeInsets.only(bottom: 16), child:
            AppointmentCard(key: appointmentKey, appointment: appointment)
          ));
        }
      }

      contentList.add(_buildHeading(
        Localization().getStringEx('panel.academics.appointments.home.heading.appointments.past', 'Recent Past Appointments'),
      ));

      if (_pastAppointments?.length == 0) {
        contentList.add(_buildStatusContent(
          Localization().getStringEx('panel.academics.appointments.home.message.appointments.past.empty', "You don't have recent past appointments linked within the Illinois app.")
        ));
      }
      else {
        for (Appointment appointment in _pastAppointments!) {
          contentList.add(Padding(padding: EdgeInsets.only(top: 16), child:
            AppointmentCard(appointment: appointment)
          ));
        }
      }

      return contentList;
    }
  }

  Widget _buildHeading(String text) {
    return Padding(padding: EdgeInsets.only(top: 16), child:
      Text(text, textAlign: TextAlign.left, style: Styles().textStyles?.getTextStyle('panel.wellness_appointments.title.large'))
    );
  }

  Widget _buildStatusContent(String text) {
    return Padding(padding: EdgeInsets.only(top: 16), child:
    Row(children: [Expanded(child:
      Text(text, textAlign: TextAlign.left, style:Styles().textStyles?.getTextStyle("widget.message.medium.thin")),
    )],)
    );
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

  Widget _buildScheduleButton() {
    return Visibility(visible: _canScheduleAppointment, child:
      LinkButton(
        title: Localization().getStringEx('panel.wellness.appointments.home.schedule_appointment.label', 'Schedule an Appointment'),
        textStyle: Styles().textStyles?.getTextStyle("widget.button.title.regular.underline"),
        padding: EdgeInsets.only(top: 8, bottom: 16),
        onTap: _onScheduleAppointment,
      ),
    );
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
    String? providerId = _selectedProvider?.id;
    Appointments().loadAppointments(providerId: _selectedProvider?.id).then((List<Appointment>? result) {
      if ((providerId == _selectedProvider?.id) && mounted) {
        setState(() {
          _buildAppointments(result);
          _isLoadingAppointments = false;
          _notifyDidLoadCallbacks();
        });
      }
    });
  }

  void _buildAppointments(List<Appointment>? appointments) {
    _upcomingAppointments = _pastAppointments = null;
    if (appointments != null) {
      _upcomingAppointments = <Appointment>[];
      _pastAppointments = <Appointment>[];

      DateTime nowUtc = DateTime.now().toUtc();
      for (Appointment appointment in appointments) {
        List<Appointment>? targetList = ((appointment.startTimeUtc == null) || nowUtc.isBefore(appointment.startTimeUtc!)) ? _upcomingAppointments : _pastAppointments;
        targetList?.add(appointment);
      }

      _upcomingAppointments?.sort((Appointment appointment1, Appointment appointment2) =>
        SortUtils.compare(appointment1.startTimeUtc, appointment2.startTimeUtc, descending: false)
      );

      _pastAppointments?.sort((Appointment appointment1, Appointment appointment2) =>
        SortUtils.compare(appointment1.startTimeUtc, appointment2.startTimeUtc, descending: true)
      );
    }
  }

  void _notifyDidLoadCallbacks() {
    for (void Function() didLoadCallback in _didLoadCallbacks) {
      didLoadCallback();
    }
    _didLoadCallbacks.clear();
  }

  bool get _canScheduleAppointment {
    return  (_selectedProvider != null) ? (_selectedProvider?.supportsSchedule == true) :
      (AppointmentProvider.findInList(_providers, supportsSchedule: true) != null);
  }

  void _onScheduleAppointment() {
    //AppointmentSchedulePanel.present(context);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentScheduleUnitPanel(
      providers: _providers,
      scheduleParam: AppointmentScheduleParam(
        provider: _selectedProvider,
      ),
      onFinish: (BuildContext context, Appointment? appointment) => _didScheduleAppointment(context, appointment)
    )));
  }

  void _didScheduleAppointment(BuildContext context, Appointment? appointment) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (_isLoadingAppointments) {
      _didLoadCallbacks.add(() {
        _ensureVisibleAppintment(appointment);
      });
    }
    else {
      _ensureVisibleAppintment(appointment);
    }
  }

  void _ensureVisibleAppintment(Appointment? appointment) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BuildContext? appointmentContext = _upcomingAppointmentKeys[appointment?.id]?.currentContext;
      if (appointmentContext != null) {
        Scrollable.ensureVisible(appointmentContext, duration: Duration(milliseconds: 300));
      }
    });
  }

  Future<void> _onPullToRefresh() async {
    _initProviders();
  }
}

class AppointmentsListPanel extends StatelessWidget {
  AppointmentsListPanel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.academics.appointments.home.header.title', 'Appointments')),
      body: Padding(padding: EdgeInsets.all(16), child: AcademicsAppointmentsContentWidget()),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: uiuc.TabBar()
    );
  }
}
